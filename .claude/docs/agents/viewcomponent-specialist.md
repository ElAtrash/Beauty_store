# ViewComponent Specialist Guide

## 🔲 ViewComponent v4 Expertise

This guide provides comprehensive patterns and best practices for ViewComponent development in Rails 8 applications.

## 🎯 Modern ViewComponent v4 Patterns

### Slot-Based Architecture

**Modern approach using `renders_one` and `renders_many`:**

```ruby
class Modal::BaseComponent < ViewComponent::Base
  renders_one :body
  renders_one :header_action
  renders_one :footer
  renders_many :actions
end
```

**Usage with Slots:**
```erb
<%= render Modal::BaseComponent.new(id: "example", title: "Example") do |modal| %>
  <% modal.with_body do %>
    <div class="p-4">
      <p>Your modal content here</p>
    </div>
  <% end %>

  <% modal.with_header_action do %>
    <button class="btn-secondary">Action</button>
  <% end %>

  <% modal.with_footer do %>
    <button class="btn-primary">Save</button>
  <% end %>
<% end %>
```

### Rails 8 Integration

**Use `class_names` helper instead of manual string concatenation:**
```ruby
def container_classes
  class_names(
    "fixed", "inset-y-0", "z-[120]",
    position_classes,
    size_classes,
    options[:class]
  )
end
```

**Proper data attribute handling:**
```ruby
def data_attributes
  {
    data: {
      controller: "modal",
      modal_id_value: id,
      action: "keydown@window->modal#handleKeydown"
    }
  }
end
```

### Dual Compatibility Pattern

**Support both slot-based and method-based approaches:**
```ruby
def content
  # Try slot first (new approach)
  return body if body.present?

  # Fall back to method override (backward compatibility)
  super if defined?(super)
end

def has_header_action?
  header_action.present? || header_actions.present?
end
```

### Configuration-Driven Approach

**Eliminate duplication with centralized configuration:**
```ruby
POSITION_CONFIG = {
  left: {
    container: "left-0",
    panel_base: "left-0",
    panel_closed: "translate-x-[-100%]",
    panel_open: "translate-x-0"
  },
  right: {
    container: "right-0",
    panel_base: "right-0",
    panel_closed: "translate-x-full",
    panel_open: "translate-x-0"
  }
}.freeze

def position_classes
  POSITION_CONFIG[position][:container]
end
```

## 📋 ViewComponent Guidelines

### Component Structure

```ruby
class ComponentName < ViewComponent::Base
  # 1. Use renders_one/renders_many for flexible content areas
  renders_one :header
  renders_one :body
  renders_many :actions

  # 2. Validate required parameters in initialize
  def initialize(required_param:, optional_param: nil, **options)
    @required_param = validate_required_param(required_param)
    @optional_param = optional_param
    @options = options
  end

  # 3. Use Rails 8 class_names helper
  def wrapper_classes
    class_names(
      "base-classes",
      conditional_classes,
      options[:class]
    )
  end

  # 4. Proper data attribute handling
  def data_attributes
    {
      data: {
        controller: "component-name",
        "component-name-param-value": required_param
      }.merge(additional_data_attributes)
    }
  end

  private

  attr_reader :required_param, :optional_param, :options

  # 5. Clear validation with helpful error messages
  def validate_required_param(param)
    return param if param.present?
    raise ArgumentError, "ComponentName requires a valid parameter"
  end
end
```

### Template Best Practices

```erb
<%# Use proper semantic HTML %>
<div class="<%= wrapper_classes %>" <%= tag.attributes(data_attributes) %>>
  <%# Render slots with fallbacks %>
  <% if header %>
    <header class="component-header">
      <%= header %>
    </header>
  <% end %>

  <main class="component-body">
    <%= body || content %>
  </main>

  <%# Handle multiple actions %>
  <% if actions.any? %>
    <footer class="component-actions">
      <% actions.each do |action| %>
        <%= action %>
      <% end %>
    </footer>
  <% end %>
</div>
```

### Testing Requirements

```ruby
RSpec.describe ComponentName, type: :component do
  include ViewComponent::TestHelpers

  # Test all major scenarios
  it "renders with required parameters" do
    component = described_class.new(required_param: "value")
    rendered = render_inline(component)

    expect(rendered.css(".component")).to be_present
  end

  it "handles slots properly" do
    rendered = render_inline(component) do |c|
      c.with_header { "Header content" }
      c.with_body { "Body content" }
    end

    expect(rendered.text).to include("Header content")
    expect(rendered.text).to include("Body content")
  end

  it "includes proper data attributes" do
    rendered = render_inline(component)
    expect(rendered.css("[data-controller='component-name']")).to be_present
  end

  # Use aggregate_failures for multiple related assertions
  it "renders complete component structure" do
    aggregate_failures do
      rendered = render_inline(component)
      expect(rendered.css(".component-header")).to be_present
      expect(rendered.css(".component-body")).to be_present
      expect(rendered.css(".component-footer")).to be_present
    end
  end
end
```

## 🎨 Naming Conventions

### Slot Names
- **Use clear, semantic names**: `body`, `header`, `footer`, `actions`
- **Avoid reserved names**: `content` (reserved by ViewComponent), `form` (conflicts with Rails helpers)
- **Be consistent**: Use same slot names across similar components

### Method Names
- **Use question marks for boolean methods**: `empty?`, `visible?`, `has_header?`
- **Use descriptive names**: `wrapper_classes`, `data_attributes`, `validation_errors`

### CSS Classes
- **Use BEM-style naming**: `component-name`, `component-name__element`, `component-name--modifier`
- **Follow project conventions**: Match existing component patterns

### Data Attributes
- **Follow Stimulus conventions**: `data-controller`, `data-action`, `data-target`
- **Use semantic names**: `data-modal-id-value`, `data-cart-item-count`

## 💡 Advanced Patterns

### Money Object Integration
```ruby
def initialize(title:, item_count:, cart_empty:, total_cents:, currency: "USD")
  @item_count = validate_item_count(item_count)
  @cart_empty = validate_cart_empty(cart_empty)
  @money = create_money_object(total_cents, currency)
  super(id: "cart", title: title, size: :medium, position: :right)
end

def cart_data_attributes
  {
    "cart-modal-target" => "modal",
    "cart-item-count" => item_count,
    "cart-empty" => empty_cart?,
    "cart-total-cents" => money.cents,
    "cart-currency" => money.currency.iso_code
  }
end
```

### Parameter Validation
```ruby
def validate_item_count(count)
  unless count.is_a?(Integer) && count >= 0
    raise ArgumentError, "item_count must be a non-negative integer, got: #{count.inspect}"
  end
  count
end

def validate_currency(currency)
  unless currency.is_a?(String) && !currency.blank?
    raise ArgumentError, "currency must be a non-blank string, got: #{currency.inspect}"
  end

  Money::Currency.new(currency)
rescue Money::Currency::UnknownCurrency => e
  raise ArgumentError, "invalid currency code: #{currency} - #{e.message}"
end
```

## 🔄 Migration Guidelines

### From Partials to Components
1. **Identify reusable partials** that would benefit from encapsulation
2. **Extract logic** from partials into component methods
3. **Add proper parameter validation** and error handling
4. **Create comprehensive tests** for the new component
5. **Update all usage sites** to use the new component

### From Method-Based to Slot-Based
1. **Add slot definitions** with `renders_one`/`renders_many`
2. **Implement compatibility methods** for backward compatibility
3. **Update templates** to support both approaches during transition
4. **Migrate usage sites** gradually to slot-based approach
5. **Remove compatibility methods** after full migration

## 🚀 Best Practices Summary

1. **Always use ViewComponent** for reusable UI elements
2. **Prefer slot-based approach** for new components
3. **Validate all parameters** with clear error messages
4. **Use `class_names` helper** for CSS class management
5. **Follow semantic HTML** principles in templates
6. **Write comprehensive tests** for all component behavior
7. **Use `aggregate_failures`** for related test assertions
8. **Keep components focused** - single responsibility principle
9. **Document complex components** with usage examples
10. **Follow project naming conventions** consistently