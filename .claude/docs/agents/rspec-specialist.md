# RSpec Specialist Guide

## 🧪 RSpec Testing Expertise

This guide covers RSpec patterns, testing strategies, and best practices for Rails 8 applications with ViewComponents, Stimulus controllers, and modern Rails patterns.

## 🎯 Testing Strategy

### Test Pyramid
- **System/Feature Tests**: User workflows, full-stack integration
- **Controller Tests**: HTTP requests, responses, authentication
- **Model Tests**: Business logic, validations, associations
- **Component Tests**: ViewComponent rendering, behavior
- **Unit Tests**: Service objects, form objects, utility classes

### Test Types by Layer

**Models**: Focus on business logic, validations, scopes
**Controllers**: Focus on routing, authentication, response handling
**ViewComponents**: Focus on rendering, data attributes, CSS classes
**Services**: Focus on business operations, error handling
**JavaScript**: Focus on Stimulus controller behavior

## 🔧 RSpec Configuration

### Recommended spec_helper.rb

```ruby
RSpec.configure do |config|
  # Use expect syntax only
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Use aggregate_failures for related assertions
  config.define_derived_metadata(file_path: %r{/spec/}) do |metadata|
    metadata[:aggregate_failures] = true unless metadata.key?(:aggregate_failures)
  end

  # Improved output formatting
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = false

  # Random order for test independence
  config.order = :random
  Kernel.srand config.seed
end
```

### Rails helper additions

```ruby
# spec/rails_helper.rb
require 'capybara/rspec'

RSpec.configure do |config|
  # ViewComponent testing support
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  # Authentication helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # Database cleaner
  config.use_transactional_fixtures = true
end
```

## 📋 ViewComponent Testing Patterns

### Basic Component Testing

```ruby
RSpec.describe ComponentName, type: :component do
  include ViewComponent::TestHelpers

  it "renders with required parameters" do
    component = described_class.new(required_param: "value")
    rendered = render_inline(component)

    expect(rendered.css(".component")).to be_present
    expect(rendered.text).to include("Expected text")
  end

  it "handles conditional rendering" do
    aggregate_failures do
      # Test with condition true
      component = described_class.new(show_content: true)
      rendered = render_inline(component)
      expect(rendered.css(".content")).to be_present

      # Test with condition false
      component = described_class.new(show_content: false)
      rendered = render_inline(component)
      expect(rendered.css(".content")).not_to be_present
    end
  end
end
```

### Slot-Based Component Testing

```ruby
it "handles slots properly" do
  rendered = render_inline(component) do |c|
    c.with_header { "Header content" }
    c.with_body { "Body content" }
    c.with_footer { "Footer content" }
  end

  aggregate_failures do
    expect(rendered.text).to include("Header content")
    expect(rendered.text).to include("Body content")
    expect(rendered.text).to include("Footer content")
  end
end

it "renders without optional slots" do
  rendered = render_inline(component) do |c|
    c.with_body { "Required content only" }
  end

  aggregate_failures do
    expect(rendered.text).to include("Required content only")
    expect(rendered.css(".header")).not_to be_present
    expect(rendered.css(".footer")).not_to be_present
  end
end
```

### Data Attributes Testing

```ruby
it "includes proper data attributes" do
  component = described_class.new(id: "test", count: 5)
  rendered = render_inline(component)
  element = rendered.css("div").first

  aggregate_failures do
    expect(element.attributes["data-controller"].value).to eq("component-name")
    expect(element.attributes["data-component-name-id-value"].value).to eq("test")
    expect(element.attributes["data-component-name-count-value"].value).to eq("5")
  end
end
```

### CSS Classes Testing

```ruby
it "applies correct CSS classes" do
  component = described_class.new(variant: "primary", size: "large")
  rendered = render_inline(component)

  aggregate_failures do
    expect(rendered.to_html).to include("component--primary")
    expect(rendered.to_html).to include("component--large")
    expect(rendered.to_html).not_to include("component--secondary")
  end
end
```

### Parameter Validation Testing

```ruby
it "validates required parameters" do
  expect {
    described_class.new(invalid_param: "wrong")
  }.to raise_error(ArgumentError, /expected message/)
end

it "accepts valid parameters" do
  %w[option1 option2 option3].each do |option|
    expect {
      described_class.new(valid_param: option)
    }.not_to raise_error
  end
end
```

## 🎮 Controller Testing Patterns

### RESTful Controller Testing

```ruby
RSpec.describe ProductsController, type: :controller do
  let(:product) { create(:product) }
  let(:user) { create(:user) }

  describe "GET #index" do
    it "returns successful response" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns products" do
      product # create product
      get :index
      expect(assigns(:products)).to include(product)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_params) { { product: attributes_for(:product) } }

      it "creates new product" do
        expect {
          post :create, params: valid_params
        }.to change(Product, :count).by(1)
      end

      it "redirects to product" do
        post :create, params: valid_params
        expect(response).to redirect_to(product_path(Product.last))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { product: { name: "" } } }

      it "does not create product" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Product, :count)
      end

      it "renders new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end
end
```

### Authentication Testing

```ruby
describe "authentication required" do
  it "redirects unauthenticated users" do
    post :create, params: valid_params
    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows authenticated users" do
    sign_in user
    post :create, params: valid_params
    expect(response).to have_http_status(:success)
  end
end
```

## 🗃️ Model Testing Patterns

### Validation Testing

```ruby
RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to validate_length_of(:password).is_at_least(8) }

  describe "email validation" do
    it "accepts valid emails" do
      valid_emails = %w[user@example.com test+tag@domain.co.uk]
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid
      end
    end

    it "rejects invalid emails" do
      invalid_emails = %w[invalid @example.com user@]
      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid
      end
    end
  end
end
```

### Association Testing

```ruby
it { is_expected.to have_many(:orders).dependent(:destroy) }
it { is_expected.to belong_to(:account) }

describe "associations" do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }

  it "destroys associated orders when user is destroyed" do
    order # create order
    expect { user.destroy }.to change(Order, :count).by(-1)
  end
end
```

### Scope Testing

```ruby
describe "scopes" do
  let!(:active_user) { create(:user, active: true) }
  let!(:inactive_user) { create(:user, active: false) }

  describe ".active" do
    it "returns only active users" do
      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end
end
```

### Money Gem Testing

```ruby
describe "money attributes" do
  let(:product) { create(:product, price_cents: 2599, currency: "USD") }

  it "returns proper money object" do
    expect(product.price).to be_a(Money)
    expect(product.price.cents).to eq(2599)
    expect(product.price.currency.iso_code).to eq("USD")
  end

  it "formats price correctly" do
    expect(product.price.format).to eq("$25.99")
  end
end
```

## 🎭 System/Feature Testing

### Capybara System Tests

```ruby
RSpec.describe "Product Browsing", type: :system do
  let!(:product) { create(:product, name: "Ruby Lipstick") }

  it "allows browsing products" do
    visit root_path

    click_link "Products"
    expect(page).to have_content("Ruby Lipstick")

    click_link "Ruby Lipstick"
    expect(page).to have_current_path(product_path(product))
  end

  it "filters products by category" do
    lipstick = create(:product, category: "lipstick")
    foundation = create(:product, category: "foundation")

    visit products_path

    select "Lipstick", from: "Category"
    click_button "Filter"

    expect(page).to have_content(lipstick.name)
    expect(page).not_to have_content(foundation.name)
  end
end
```

### JavaScript Interaction Testing

```ruby
it "opens modal with JavaScript", js: true do
  visit products_path

  click_button "Add to Cart"
  expect(page).to have_css("#cart-modal", visible: true)

  within "#cart-modal" do
    expect(page).to have_content("Added to cart")
  end
end

it "updates cart count dynamically", js: true do
  visit product_path(product)

  expect(page).to have_css("[data-cart-count='0']")

  click_button "Add to Cart"
  expect(page).to have_css("[data-cart-count='1']")
end
```

## 🔧 Factory Patterns

### Factory Bot Setup

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    first_name { "John" }
    last_name { "Doe" }

    trait :admin do
      role { "admin" }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end

# Usage
let(:admin_user) { create(:user, :admin) }
let(:user_with_orders) { create(:user, :with_orders) }
```

### Money Object Factories

```ruby
factory :product do
  name { "Sample Product" }
  price_cents { 2599 }
  currency { "USD" }

  trait :expensive do
    price_cents { 9999 }
  end

  trait :free do
    price_cents { 0 }
  end
end
```

## 📊 Test Doubles and Mocking

### Service Object Testing

```ruby
describe ServiceClass do
  let(:service) { described_class.new(user: user) }

  describe "#call" do
    context "when successful" do
      it "returns success result" do
        result = service.call
        expect(result).to be_success
        expect(result.value).to be_present
      end
    end

    context "when failed" do
      before do
        allow(ExternalService).to receive(:call).and_raise(StandardError)
      end

      it "returns failure result" do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to be_present
      end
    end
  end
end
```

### External API Mocking

```ruby
before do
  stub_request(:post, "https://api.example.com/payments")
    .with(body: hash_including(amount: 2599))
    .to_return(
      status: 200,
      body: { transaction_id: "txn_123" }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end
```

## 🚀 Best Practices Summary

1. **Use `aggregate_failures`** for related assertions
2. **Test happy path first**, then edge cases
3. **Use descriptive test names** that explain behavior
4. **Group related tests** with nested describe blocks
5. **Use let blocks** for test setup, not before blocks when possible
6. **Mock external dependencies** to maintain test speed
7. **Use factories** instead of fixtures for flexible test data
8. **Test error conditions** and edge cases thoroughly
9. **Keep tests focused** - one behavior per test
10. **Use system tests sparingly** for critical user paths only