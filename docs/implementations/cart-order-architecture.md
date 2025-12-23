# Cart & Order Architecture Documentation

## Overview

This document describes the refactored cart and order architecture, designed to eliminate code duplication, ensure consistency, and provide maintainable patterns across all cart/order operations.

## Core Principles

### 1. DRY (Don't Repeat Yourself)
- **BaseService**: Provides standardized patterns for all service objects
- **Consistent Error Handling**: All services use i18n for error messages
- **Inline Logic**: Simple cart item queries are inlined directly in services for clarity

### 2. Single Responsibility
- Each service has a clear, single purpose
- Clear separation between cart operations and order operations
- Validation logic centralized in dedicated services

### 3. Consistent Patterns
- All services inherit from BaseService
- Standardized result objects via BaseResult
- Uniform transaction handling and error logging

## Architecture Components

### BaseService (`app/services/concerns/base_service.rb`)

Provides standardized patterns for all service objects:

```ruby
class MyService
  include BaseService

  def call
    validate_required_params(param1: param1, param2: param2)
    return last_result if last_result.failure?

    ActiveRecord::Base.transaction do
      # business logic
      success(resource: result)
    end
  rescue => e
    log_error("operation failed", e)
    failure(errors: ["Something went wrong"])
  end
end
```

**Key Methods:**
- `success(**metadata)` - Creates successful BaseResult
- `failure(errors:, **metadata)` - Creates failed BaseResult
- `validate_required_params(**params)` - Validates required parameters
- `log_error(message, exception)` - Standardized error logging
- `service_failure(errors)` - Creates failed BaseResult with service error type
- `validation_failure(errors)` - Creates failed BaseResult with validation error type

### Cart Item Query Patterns

Common patterns for cart item operations (inlined in services for clarity):

```ruby
# Find or create cart item
cart_item = cart.cart_items.find_or_initialize_by(product_variant: product_variant)

# Get current quantity in cart
current_quantity = cart.cart_items.find_by(product_variant: product_variant)&.quantity || 0

# Check if variant exists in cart
has_variant = cart.cart_items.exists?(product_variant: product_variant)
```

**Rationale**: Simple ActiveRecord queries are more readable when inlined rather than abstracted into concerns for minimal reuse.

## Cart Services

### Core Cart Operations

#### 1. `Carts::AddItemService`
**Purpose**: Add product variants to cart with quantity validation

**Usage**:
```ruby
result = Carts::AddItemService.call(
  cart: current_cart,
  product_variant: variant,
  quantity: 2
)
```

**Key Features**:
- Uses direct ActiveRecord queries for cart item management
- Integrates with QuantityService for validation
- Handles both new items and quantity updates
- Transactional safety

#### 2. `Carts::ItemUpdateService`
**Purpose**: Update cart item quantities, including increment/decrement/set operations

**Usage**:
```ruby
# Increment quantity
result = Carts::ItemUpdateService.call(cart_item, params: { quantity_action: "increment" })

# Set specific quantity
result = Carts::ItemUpdateService.call(cart_item, params: { quantity: 3 })

# Set quantity directly
result = Carts::ItemUpdateService.set_quantity(cart_item, 5)
```

**Key Features**:
- Multiple operation modes (increment, decrement, set_quantity)
- Automatic item removal when quantity reaches 0
- Quantity validation through QuantityService
- Flexible parameter parsing

#### 3. `Carts::ClearService`
**Purpose**: Remove all items from cart

**Usage**:
```ruby
result = Carts::ClearService.call(cart: current_cart)
# Access cleared items: result.metadata[:cleared_variants]
```

**Key Features**:
- Tracks cleared items for UI feedback
- Uses ItemUpdateService for consistent removal logic
- Returns metadata about cleared items

#### 4. `Carts::FindOrCreateService`
**Purpose**: Find existing cart or create new one for user/session

**Usage**:
```ruby
result = Carts::FindOrCreateService.call(
  user: Current.user,
  session: session,
  cart_token: session[:cart_token]
)
```

**Key Features**:
- Handles both authenticated and guest users
- Automatic cart merging for user login
- Session token management

### Validation Services

#### `Carts::QuantityService`
**Purpose**: Centralized quantity validation logic

**Key Methods**:
- `validate_quantity(quantity, product_variant:, existing_quantity:)` - Validates adding quantity
- `can_set_quantity?(cart_item, new_quantity)` - Validates setting absolute quantity
- `can_increment?(cart_item)` - Quick check if item can be incremented

**Validation Rules**:
- Quantity must be positive (> 0)
- Cannot exceed MAX_QUANTITY (99)
- Cannot exceed product stock
- Considers existing cart quantities

## Order Services

### Core Order Operations

#### 1. `Orders::CreateService`
**Purpose**: Create order from cart and customer information

**Usage**:
```ruby
result = Orders::CreateService.call(
  cart: current_cart,
  customer_info: {
    email: "user@example.com",
    phone_number: "+961...",
    delivery_method: "courier",
    # ... other customer data
  }
)
```

**Key Features**:
- Validates cart and customer information
- Creates order with proper associations
- Handles both courier and pickup delivery methods
- Automatic total calculations
- Payment status determination

#### 2. `Orders::ReorderService`
**Purpose**: Add items from previous order back to cart

**Usage**:
```ruby
result = Orders::ReorderService.call(
  order: previous_order,
  user: Current.user,
  session: session,
  cart_token: session[:cart_token]
)
```

**Key Features**:
- Uses direct ActiveRecord queries for cart management
- Handles partial reorders (when some items unavailable)
- Stock and availability validation
- Detailed feedback on success/failure per item
- Automatic cart creation if needed

**Result Types**:
- **Full Success**: All items added successfully
- **Partial Success**: Some items added, others failed (with reasons)
- **Failure**: No items could be added

## Result Patterns

### BaseResult Structure

All services return BaseResult objects with consistent structure:

```ruby
# Success result
result = BaseResult.new(
  success: true,
  resource: created_object,    # Primary resource created/modified
  cart: updated_cart,          # Cart state (for cart operations)
  **additional_metadata        # Operation-specific data
)

# Failure result
result = BaseResult.new(
  success: false,
  errors: ["Error message"],   # Array of error messages
  **context_metadata           # Context for error handling
)
```

### Metadata Access

Access metadata using flat structure:
```ruby
# Correct
message = result.metadata[:message]
cart = result.metadata[:cart]

# Not this (old nested pattern)
result.metadata[:metadata][:message]  # ❌ Deprecated
```

## Integration Patterns

### Controller Integration

```ruby
class CartItemsController < ApplicationController
  def create
    result = Carts::AddItemService.call(
      cart: current_cart,
      product_variant: ProductVariant.find(params[:product_variant_id]),
      quantity: params[:quantity]
    )

    if result.success?
      # Handle success - result.cart contains updated cart
      render json: { success: true }
    else
      # Handle failure - result.errors contains error messages
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end
end
```

### Service Composition

Services can call other services safely:

```ruby
class ComplexCartOperation
  include BaseService

  def call
    # Call another service
    add_result = Carts::AddItemService.call(cart: cart, product_variant: variant, quantity: 1)
    return add_result if add_result.failure?

    # Continue with business logic
    success(cart: add_result.cart)
  end
end
```

## Error Handling

### Internationalization

All error messages use i18n keys for consistency:

```ruby
# In services
failure(errors: [I18n.t("services.errors.cart_required")])

# In locales/en.yml
services:
  errors:
    cart_required: "Cart is required"
    cart_empty: "Cart is empty"
    something_went_wrong: "Something went wrong. Please try again."
  quantity:
    must_be_positive: "Quantity must be greater than 0"
    exceeds_maximum: "Quantity cannot exceed %{max}"
```

### Error Categories

1. **Validation Errors**: User input issues (400-level)
2. **Business Logic Errors**: Rule violations (422-level)
3. **System Errors**: Unexpected failures (500-level)

## Testing Patterns

### Service Testing

```ruby
RSpec.describe Carts::AddItemService do
  describe "#call" do
    let(:cart) { create(:cart) }
    let(:product_variant) { create(:product_variant, stock_quantity: 10) }

    context "when adding valid quantity" do
      it "adds item to cart successfully" do
        result = described_class.call(
          cart: cart,
          product_variant: product_variant,
          quantity: 2
        )

        expect(result).to be_success
        expect(result.cart.cart_items.count).to eq(1)
        expect(result.resource.quantity).to eq(2)
      end
    end

    context "when quantity exceeds stock" do
      it "returns failure with appropriate error" do
        result = described_class.call(
          cart: cart,
          product_variant: product_variant,
          quantity: 20
        )

        expect(result).to be_failure
        expect(result.errors).to include(/cannot add more items/i)
      end
    end
  end
end
```

## Migration Guide

### From Old Patterns

**Before (Manual BaseResult creation)**:
```ruby
def create_order
  # manual validation
  return BaseResult.new(success: false, errors: ["Cart required"]) unless cart

  # manual transaction
  ActiveRecord::Base.transaction do
    order = Order.create!(order_params)
    BaseResult.new(success: true, resource: order)
  end
rescue => e
  Rails.logger.error e.message
  BaseResult.new(success: false, errors: ["Something went wrong"])
end
```

**After (BaseService pattern)**:
```ruby
class Orders::CreateService
  include BaseService

  def call
    validate_required_params(cart: cart)
    return last_result if last_result.failure?

    ActiveRecord::Base.transaction do
      order = Order.create!(order_params)
      success(resource: order)
    end
  rescue => e
    log_error("order creation failed", e)
    failure(errors: [I18n.t("services.errors.something_went_wrong")])
  end
end
```

## Performance Considerations

### Database Optimization

1. **Eager Loading**: Order items include product_variant associations
2. **Batch Operations**: Use `find_each` for large order processing
3. **Transaction Scope**: Keep transactions focused and short-lived

### Caching Strategy

1. **Cart State**: Consider Redis caching for high-traffic scenarios
2. **Product Availability**: Cache stock status checks
3. **Price Snapshots**: Store price at time of cart addition

## Monitoring & Logging

### Service Logging

All services use standardized logging via BaseService:

```ruby
# Automatic logging in BaseService
log_error("operation description", exception)
# => "ServiceName operation description: ExceptionClass - message"
# => Full backtrace in Rails.logger.error
```

### Metrics to Monitor

1. **Cart Abandonment**: Track cart→order conversion
2. **Reorder Success Rate**: Percentage of successful reorders
3. **Stock Validation Failures**: Items becoming unavailable during checkout
4. **Service Error Rates**: Monitor failure patterns across services

## Future Enhancements

### Planned Improvements

1. **Event Sourcing**: Track cart/order state changes
2. **Background Processing**: Move heavy operations to jobs
3. **Inventory Reservations**: Hold stock during checkout process
4. **Advanced Validation**: Business rule engine for complex scenarios

### Extension Points

1. **Custom Validation Rules**: Extend QuantityService for business-specific rules
2. **Cart Decorators**: Add behavior without modifying core services
3. **Order Workflows**: Plugin system for custom order processing
4. **External Integrations**: Standardized interfaces for third-party services