# Service Patterns Guide

## Overview

This guide provides comprehensive patterns and best practices for implementing service objects in the Beauty Store application. All services follow standardized patterns for consistency, maintainability, and testability.

## BaseService Pattern

### Core Implementation

Every service should include the BaseService concern to ensure consistent patterns:

```ruby
# app/services/my_namespace/my_service.rb
class MyNamespace::MyService
  include BaseService

  def self.call(**args)
    new(**args).call
  end

  def initialize(required_param:, optional_param: nil)
    @required_param = required_param
    @optional_param = optional_param
  end

  def call
    # 1. Validate required parameters
    validate_required_params(required_param: required_param)
    return last_result if last_result.failure?

    # 2. Business logic validation
    custom_validation_logic
    return last_result if last_result.failure?

    # 3. Main operation (with transaction if needed)
    with_transaction do
      result = perform_operation
      success(resource: result, additional_data: extra_info)
    end
  rescue StandardError => e
    log_error("operation description", e)
    failure(errors: [I18n.t("services.errors.something_went_wrong")])
  end

  private

  attr_reader :required_param, :optional_param

  def custom_validation_logic
    if invalid_condition?
      @last_result = failure(errors: [I18n.t("services.errors.validation_failed")])
    end
  end

  def perform_operation
    # Main business logic here
  end
end
```

### BaseService Methods

#### Result Creation
```ruby
# Success result
success(resource: created_object, **additional_metadata)

# Failure result
failure(errors: ["Error message"], **context_metadata)
```

#### Validation
```ruby
# Validates that all specified parameters are present and not nil
validate_required_params(param1: value1, param2: value2)

# Check if last validation failed
return last_result if last_result.failure?
```

#### Transaction Management
```ruby
# Wraps operation in ActiveRecord transaction
with_transaction do
  # database operations
  success(resource: result)
end
```

#### Logging
```ruby
# Standardized error logging with service context
log_error("operation description", exception)
# Outputs: "ServiceName operation description: ExceptionClass - message"
```

## Service Naming Conventions

### Namespace Organization
```
app/services/
├── carts/           # Cart-related operations
│   ├── add_item_service.rb
│   ├── clear_service.rb
│   └── item_update_service.rb
├── orders/          # Order-related operations
│   ├── create_service.rb
│   └── reorder_service.rb
├── checkout/        # Checkout flow operations
│   ├── process_order_service.rb
│   └── form_state_service.rb
└── concerns/        # Shared service behaviors
    ├── base_service.rb
    └── cart_item_finder.rb
```

### Service Naming Rules
1. **Action-based**: `VerbNounService` (e.g., `CreateOrderService`, `AddItemService`)
2. **Namespace**: Use module namespacing for logical grouping
3. **Specificity**: Be specific about what the service does

### File Structure
```ruby
# File: app/services/orders/create_service.rb
class Orders::CreateService
  include BaseService
  # ... implementation
end
```

## Common Patterns

### 1. CRUD Operations

#### Create Pattern
```ruby
class Resources::CreateService
  include BaseService

  def call
    validate_required_params(resource_params: resource_params)
    return last_result if last_result.failure?

    with_transaction do
      resource = Resource.create!(resource_params)
      success(resource: resource)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("creation failed", e)
    failure(errors: extract_validation_errors(e))
  end

  private

  def extract_validation_errors(exception)
    exception.record.errors.full_messages
  end
end
```

#### Update Pattern
```ruby
class Resources::UpdateService
  include BaseService

  def call
    validate_required_params(resource: resource, update_params: update_params)
    return last_result if last_result.failure?

    with_transaction do
      resource.update!(update_params)
      success(resource: resource)
    end
  rescue ActiveRecord::RecordInvalid => e
    log_error("update failed", e)
    failure(errors: extract_validation_errors(e))
  end
end
```

### 2. Complex Business Logic

#### Multi-Step Operations
```ruby
class ComplexBusinessOperation
  include BaseService

  def call
    validate_inputs
    return last_result if last_result.failure?

    with_transaction do
      step_one_result = perform_step_one
      step_two_result = perform_step_two(step_one_result)
      step_three_result = perform_step_three(step_two_result)

      success(resource: step_three_result, intermediate_data: step_one_result)
    end
  end

  private

  def validate_inputs
    # Custom validation logic
    unless valid_input?
      @last_result = failure(errors: [I18n.t("custom.validation.error")])
    end
  end

  def perform_step_one
    # Step implementation
  end

  def perform_step_two(previous_result)
    # Step implementation using previous result
  end

  def perform_step_three(previous_result)
    # Final step implementation
  end
end
```

### 3. External Service Integration

#### API Call Pattern
```ruby
class ExternalApi::ProcessPaymentService
  include BaseService

  def call
    validate_required_params(payment_data: payment_data)
    return last_result if last_result.failure?

    response = make_api_call

    if response.success?
      success(
        resource: create_payment_record(response),
        external_id: response.transaction_id
      )
    else
      handle_api_error(response)
    end
  rescue Net::TimeoutError => e
    log_error("API timeout", e)
    failure(errors: [I18n.t("services.external.timeout")])
  rescue StandardError => e
    log_error("API error", e)
    failure(errors: [I18n.t("services.external.unavailable")])
  end

  private

  def make_api_call
    # HTTP client implementation
  end

  def handle_api_error(response)
    failure(
      errors: [I18n.t("services.external.api_error", message: response.error_message)],
      external_error_code: response.error_code
    )
  end
end
```

## Error Handling Patterns

### Error Categories

#### 1. Validation Errors (User Input)
```ruby
# Parameter validation
validate_required_params(email: email, password: password)

# Business rule validation
unless user.eligible_for_action?
  return failure(errors: [I18n.t("services.users.not_eligible")])
end
```

#### 2. Business Logic Errors
```ruby
# Stock validation
unless product.in_stock?
  return failure(
    errors: [I18n.t("services.products.out_of_stock")],
    product: product
  )
end

# Authorization checks
unless user.can_perform_action?
  return failure(errors: [I18n.t("services.authorization.forbidden")])
end
```

#### 3. System Errors
```ruby
rescue ActiveRecord::RecordInvalid => e
  log_error("database validation failed", e)
  failure(errors: [I18n.t("services.errors.validation_failed")])

rescue StandardError => e
  log_error("unexpected system error", e)
  failure(errors: [I18n.t("services.errors.something_went_wrong")])
```

### Error Message Internationalization

All error messages should use i18n keys:

```yaml
# config/locales/en.yml
services:
  errors:
    something_went_wrong: "Something went wrong. Please try again."
    validation_failed: "Validation failed. Please check your input."
    unauthorized: "You are not authorized to perform this action."

  products:
    out_of_stock: "This product is out of stock"
    price_changed: "Product price has changed since adding to cart"

  carts:
    item_not_found: "Cart item not found"
    quantity_exceeded: "Quantity exceeds available stock"
```

## Result Object Patterns

### Success Results

#### Simple Success
```ruby
success(resource: created_object)
```

#### Success with Additional Data
```ruby
success(
  resource: primary_resource,
  count: items_processed,
  summary: operation_summary,
  metadata: additional_context
)
```

#### Success with Relationships
```ruby
success(
  resource: order,
  cart: updated_cart,
  items: order_items,
  total: calculated_total
)
```

### Failure Results

#### Simple Failure
```ruby
failure(errors: ["Something went wrong"])
```

#### Failure with Context
```ruby
failure(
  errors: ["Validation failed"],
  invalid_fields: ["email", "phone"],
  attempted_values: sanitized_input
)
```

#### Failure with Recovery Information
```ruby
failure(
  errors: ["Some items unavailable"],
  successful_items: processed_items,
  failed_items: failed_items,
  suggestions: alternative_products
)
```

## Testing Patterns

### Unit Testing Services

```ruby
# spec/services/orders/create_service_spec.rb
RSpec.describe Orders::CreateService do
  subject(:service) { described_class.new(cart: cart, customer_info: customer_info) }

  let(:cart) { create(:cart, :with_items) }
  let(:customer_info) { build(:customer_info) }

  describe "#call" do
    context "with valid inputs" do
      it "creates order successfully" do
        result = service.call

        expect(result).to be_success
        expect(result.resource).to be_a(Order)
        expect(result.resource.cart_items.count).to eq(cart.cart_items.count)
      end

      it "returns order in metadata" do
        result = service.call

        expect(result.metadata[:order]).to eq(result.resource)
      end
    end

    context "with invalid cart" do
      let(:cart) { nil }

      it "returns failure with appropriate error" do
        result = service.call

        expect(result).to be_failure
        expect(result.errors).to include("Cart is required")
      end
    end

    context "when database error occurs" do
      before do
        allow(Order).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Order.new))
      end

      it "handles error gracefully" do
        result = service.call

        expect(result).to be_failure
        expect(result.errors).to include(/order creation failed/i)
      end
    end
  end
end
```

### Integration Testing

```ruby
# spec/requests/cart_items_spec.rb
RSpec.describe "Cart Items", type: :request do
  describe "POST /cart_items" do
    let(:product_variant) { create(:product_variant, stock_quantity: 10) }
    let(:params) do
      {
        product_variant_id: product_variant.id,
        quantity: 2
      }
    end

    context "when successful" do
      it "adds item to cart" do
        post "/cart_items", params: params

        expect(response).to have_http_status(:success)
        expect(json_response).to include("success" => true)
      end
    end

    context "when quantity exceeds stock" do
      let(:params) { super().merge(quantity: 20) }

      it "returns validation error" do
        post "/cart_items", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include(/stock/i)
      end
    end
  end
end
```

## Performance Patterns

### Database Optimization

#### Eager Loading
```ruby
def process_order_items
  order.order_items.includes(:product_variant, product_variant: :product).find_each do |item|
    process_item(item)
  end
end
```

#### Batch Operations
```ruby
def bulk_update_items(items_data)
  with_transaction do
    items_data.each_slice(100) do |batch|
      process_batch(batch)
    end
    success(count: items_data.size)
  end
end
```

#### Selective Updates
```ruby
def update_pricing
  updated_items = []

  cart.cart_items.includes(:product_variant).each do |item|
    if item.price_changed?
      item.update_price_snapshot!
      updated_items << item
    end
  end

  success(updated_items: updated_items)
end
```

### Caching Strategies

#### Service-Level Caching
```ruby
class ExpensiveCalculationService
  include BaseService

  def call
    validate_required_params(input: input)
    return last_result if last_result.failure?

    result = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      perform_expensive_calculation
    end

    success(resource: result)
  end

  private

  def cache_key
    "expensive_calc:#{Digest::MD5.hexdigest(input.to_json)}"
  end
end
```

## Advanced Patterns

### Service Composition

#### Orchestrator Pattern
```ruby
class CompleteCheckoutOrchestrator
  include BaseService

  def call
    validate_required_params(cart: cart, customer_info: customer_info)
    return last_result if last_result.failure?

    # Step 1: Validate cart
    validation_result = Checkout::CartValidationService.call(cart)
    return validation_result if validation_result.failure?

    # Step 2: Process payment
    payment_result = Payments::ProcessService.call(payment_params)
    return payment_result if payment_result.failure?

    # Step 3: Create order
    order_result = Orders::CreateService.call(cart: cart, customer_info: customer_info)
    return order_result if order_result.failure?

    # Step 4: Clear cart
    clear_result = Carts::ClearService.call(cart: cart)

    success(
      order: order_result.resource,
      payment: payment_result.resource,
      cleared_items: clear_result.metadata[:cleared_items_count]
    )
  end
end
```

#### Chain of Responsibility
```ruby
class ValidationChain
  include BaseService

  VALIDATORS = [
    CartValidation,
    InventoryValidation,
    PricingValidation,
    AuthorizationValidation
  ].freeze

  def call
    VALIDATORS.each do |validator_class|
      result = validator_class.new(context).validate
      return result if result.failure?
    end

    success(message: "All validations passed")
  end
end
```

### Event-Driven Patterns

#### Service with Events
```ruby
class Orders::CreateService
  include BaseService

  def call
    # ... validation and creation logic

    with_transaction do
      order = create_order
      emit_event(:order_created, order: order, customer: customer_info)
      success(resource: order)
    end
  end

  private

  def emit_event(event_name, **payload)
    # Event system integration
    EventBus.publish(event_name, payload)
  end
end
```

## Common Patterns

### Cart Item Operations

For services that work with cart items, use direct ActiveRecord queries:

```ruby
class Carts::BulkUpdateService
  include BaseService

  def call
    updates.each do |update|
      item = cart.cart_items.find_by(product_variant: update[:product_variant])
      next unless item

      current_quantity = cart.cart_items.find_by(product_variant: update[:product_variant])&.quantity || 0
      new_quantity = current_quantity + update[:quantity]
      # ... update logic
    end

    success(cart: cart)
  end
end
```

### Audit Logging

For services that need audit trails:

```ruby
module AuditLogging
  extend ActiveSupport::Concern

  private

  def log_operation(action, resource, details = {})
    AuditLog.create!(
      user: Current.user,
      action: action,
      resource: resource,
      details: details,
      ip_address: Current.ip_address
    )
  end
end

class SensitiveOperationService
  include BaseService
  include AuditLogging

  def call
    with_transaction do
      result = perform_operation
      log_operation("sensitive_action", result, operation_context)
      success(resource: result)
    end
  end
end
```

## Migration Checklist

When refactoring existing services to use these patterns:

### ✅ BaseService Migration
- [ ] Include BaseService concern
- [ ] Replace manual BaseResult creation with success/failure methods
- [ ] Use validate_required_params for parameter validation
- [ ] Wrap database operations with with_transaction
- [ ] Replace manual logging with log_error method
- [ ] Update error messages to use i18n keys

### ✅ Error Handling
- [ ] Convert hardcoded error messages to i18n keys
- [ ] Standardize error categories (validation, business, system)
- [ ] Add appropriate rescue clauses for different error types
- [ ] Include context in failure results

### ✅ Testing
- [ ] Add unit tests for success paths
- [ ] Add unit tests for validation failures
- [ ] Add unit tests for system error handling
- [ ] Test result metadata structure
- [ ] Add integration tests where appropriate

### ✅ Documentation
- [ ] Document service purpose and usage
- [ ] Document parameters and return values
- [ ] Add examples for common use cases
- [ ] Document error conditions and handling

This guide ensures consistent, maintainable, and testable service objects across the entire Beauty Store application.