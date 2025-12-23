# Address Modal Workflow Documentation

## Overview

The address modal provides a simple, effective way for users to enter their delivery address during the checkout process. This implementation follows **Rails conventions** with direct form submission to the server, avoiding complex JavaScript event orchestration in favor of proven Rails patterns.

**Key Principle**: Simple Rails form submission → Server processing → Turbo Stream response

## Architecture

### Design Philosophy
- **Rails-First**: Leverage Rails' form handling, validation, and Turbo Stream capabilities
- **Progressive Enhancement**: Works without JavaScript, enhanced with Stimulus
- **Server-Side Processing**: Business logic handled on the server, not in client-side JavaScript
- **Avoid Over-Engineering**: No complex event systems or client-side state synchronization

### Integration Points
- **Modal System**: Uses `Modal::BaseComponent` for consistent modal behavior
- **Form Validation**: Integrates with `form_validation_controller.js` for real-time validation
- **Checkout Flow**: Updates delivery summary via Turbo Stream responses

## Implementation Details

### Frontend Components

#### 1. AddressModalController (`app/javascript/controllers/address_modal_controller.js`)
**Purpose**: Handles address modal interactions and form submission

**Key Methods**:
- `open()` - Opens modal and sets up validation context
- `submitAddress(event)` - Validates and submits form data
- `submitToServer()` - Direct submission to `/checkout/delivery_summary`
- `getAddressData()` - Extracts form data for submission

**Integration**:
- Uses Stimulus outlets to connect with `modal` and `form-validation` controllers
- Validates form before submission using connected form validation controller
- Submits directly to server endpoint with proper CSRF handling

#### 2. CheckoutFormController (`app/javascript/controllers/checkout_form_controller.js`)
**Purpose**: Manages main checkout form and delivery method changes

**Key Methods**:
- `handleDeliveryMethodChange(event)` - Responds to delivery method selection
- `updateDeliverySummary(method)` - Updates delivery summary via Turbo Stream
- `persistDeliveryMethod(method)` - Saves delivery method to server session
- `openAddressModal()` - Auto-opens address modal when courier is selected

**Simplified Approach**:
- Removed complex event handling between controllers
- Direct HTTP requests to server endpoints
- Relies on server-side Turbo Stream responses for UI updates

#### 3. Form Validation Integration
**Purpose**: Real-time validation of address fields

**Integration**:
- Modal's form validation controller receives delivery method context
- Validates address fields based on delivery method requirements
- Provides immediate feedback to users

### Backend Components

#### 1. CheckoutController#delivery_summary (`app/controllers/checkout_controller.rb`)
**Purpose**: Processes address updates and returns Turbo Stream response

**Flow**:
```ruby
def delivery_summary
  @checkout_form = Checkout::FormStateService.restore_from_session(session)
  @delivery_method = params[:delivery_method] || @checkout_form.delivery_method

  Checkout::DeliveryMethodHandler.call(
    form: @checkout_form,
    delivery_method: @delivery_method,
    address_params: address_update_params
  )

  Checkout::FormStateService.persist_if_valid(@checkout_form, session)

  respond_to do |format|
    format.turbo_stream
  end
end
```

**Parameters**:
- `delivery_method` - Current delivery method (courier/pickup)
- Address parameters: `address_line_1`, `address_line_2`, `landmarks`

#### 2. DeliveryMethodHandler (`app/services/checkout/delivery_method_handler.rb`)
**Purpose**: Handles delivery method and address data updates

**Responsibilities**:
- Normalizes delivery method values
- Updates checkout form with new address data
- Maintains consistency between delivery method and address requirements

#### 3. FormStateService (`app/services/checkout/form_state_service.rb`)
**Purpose**: Manages checkout form state persistence in session

**Key Methods**:
- `restore_from_session(session)` - Restores form state from session
- `persist_if_valid(form, session)` - Saves valid form data to session
- `update_and_persist(form, params, session)` - Updates and saves form data

## Data Flow

### Complete Workflow

1. **Modal Trigger**
   - User selects "courier" delivery method
   - Checkout form controller auto-opens address modal if address is empty
   - Or user manually clicks "Set delivery address" button

2. **Modal Opening**
   ```javascript
   open() {
     if (this.hasModalOutlet) {
       this.modalOutlet.open()
       this.setupModalValidation()
     }
   }
   ```

3. **Form Validation Setup**
   - Address modal gets delivery method from main checkout form
   - Sets up form validation controller with correct delivery method context
   - Enables real-time validation for address fields

4. **User Input**
   - User fills in address fields (address_line_1, address_line_2, landmarks)
   - Real-time validation provides immediate feedback
   - Required field validation based on delivery method

5. **Form Submission**
   ```javascript
   submitToServer() {
     const addressData = this.getAddressData()
     const formData = new FormData()

     formData.append('delivery_method', 'courier')
     Object.entries(addressData).forEach(([key, value]) => {
       if (value) {
         formData.append(key, value)
       }
     })

     fetch('/checkout/delivery_summary', {
       method: 'POST',
       headers: {
         'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
         'Accept': 'text/vnd.turbo-stream.html'
       },
       body: formData
     })
   }
   ```

6. **Server Processing**
   - Controller receives address data and delivery method
   - `DeliveryMethodHandler` updates checkout form with new address
   - `FormStateService` persists updated form to session
   - Server renders Turbo Stream response

7. **UI Updates**
   - Turbo Stream response updates delivery summary component
   - Address container shows filled address instead of "Set delivery address"
   - Modal closes automatically
   - User sees updated checkout form with their address

### Data Structure

**Request Payload**:
```javascript
{
  delivery_method: 'courier',
  address_line_1: 'Main Street 123',
  address_line_2: 'Apt 4B',
  landmarks: 'Near the blue building'
}
```

**Server Response**: Turbo Stream that updates delivery summary component

## Key Code Examples

### Address Modal Submission
```javascript
// app/javascript/controllers/address_modal_controller.js
submitToServer() {
  const addressData = this.getAddressData()
  const formData = new FormData()

  // Add delivery method and address data
  formData.append('delivery_method', 'courier')
  Object.entries(addressData).forEach(([key, value]) => {
    if (value) {
      formData.append(key, value)
    }
  })

  // Submit directly to delivery_summary endpoint
  fetch('/checkout/delivery_summary', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'text/vnd.turbo-stream.html'
    },
    body: formData
  })
  .then(response => response.text())
  .then(html => {
    if (html.includes('turbo-stream')) {
      Turbo.renderStreamMessage(html)
    }
    this.close()
  })
}
```

### Server-Side Processing
```ruby
# app/controllers/checkout_controller.rb
def delivery_summary
  @checkout_form = Checkout::FormStateService.restore_from_session(session)
  @delivery_method = params[:delivery_method] || @checkout_form.delivery_method

  Checkout::DeliveryMethodHandler.call(
    form: @checkout_form,
    delivery_method: @delivery_method,
    address_params: address_update_params
  )

  Checkout::FormStateService.persist_if_valid(@checkout_form, session)

  respond_to do |format|
    format.turbo_stream
  end
end

private

def address_update_params
  params.permit(:address_line_1, :address_line_2, :landmarks).to_h.compact_blank
end
```

### Turbo Stream Response
```erb
<!-- app/views/checkout/delivery_summary.turbo_stream.erb -->
<%= turbo_stream.replace "delivery-summary" do %>
  <%= render Checkout::DeliverySummaryComponent.new(
    checkout_form: @checkout_form,
    delivery_method: @delivery_method
  ) %>
<% end %>
```

## Anti-Patterns Avoided

### ❌ Complex Event Systems
**Problem**: Complex JavaScript event orchestration between controllers
```javascript
// AVOIDED: Complex event-driven communication
this.dispatch('addressSubmitted', { detail: { addressData } })
document.addEventListener('addressSubmitted', this.handleAddressUpdate)
```

**Solution**: Direct server submission with Turbo Stream responses

### ❌ Manual Controller Discovery
**Problem**: Manually finding and calling other Stimulus controllers
```javascript
// AVOIDED: Manual controller discovery
const controller = this.application.getControllerForElementAndIdentifier(element, "checkout-form")
controller.updateAddressContainer(addressData)
```

**Solution**: Stimulus outlets for proper controller communication

### ❌ Client-Side State Synchronization
**Problem**: Maintaining state consistency across multiple JavaScript controllers
```javascript
// AVOIDED: Complex client-side state management
this.addressState = { line1: '', line2: '', landmarks: '' }
this.syncStateWithOtherControllers()
```

**Solution**: Server-side state management with session persistence

### ❌ Over-Engineering
**Problem**: Building complex systems when simple solutions work
- Multiple event listeners and dispatchers
- Custom state management
- Complex controller-to-controller communication

**Solution**: Standard Rails form submission with progressive enhancement

## Troubleshooting Guide

### Common Issues

#### 1. Validation Not Working
**Symptoms**: Address modal doesn't show validation errors
**Check**:
- Form validation controller outlet connection in component
- Delivery method being passed to modal validation controller
- Validation rules data attributes on form fields

#### 2. Address Not Updating
**Symptoms**: Modal closes but delivery summary doesn't show address
**Check**:
- Server endpoint receiving correct parameters
- Turbo Stream response being rendered correctly
- Address data being persisted to session

#### 3. Modal Not Opening
**Symptoms**: Address modal doesn't open when courier is selected
**Check**:
- Modal outlet connection between checkout form and address modal
- Address modal component being rendered in the page
- JavaScript console for any controller connection errors

### Debugging Tips

#### Enable Detailed Logging
```ruby
# Temporarily add to checkout_controller.rb for debugging
Rails.logger.info "Address params: #{address_update_params.inspect}"
Rails.logger.info "Form state: #{@checkout_form.inspect}"
```

#### Check Stimulus Connections
```javascript
// In browser console
document.querySelector('[data-controller~="address-modal"]').addressModalController
document.querySelector('[data-controller~="checkout-form"]').checkoutFormController
```

#### Verify Turbo Stream Response
```javascript
// In browser console, check network tab for delivery_summary request
// Response should contain turbo-stream tags
```

## Testing Strategy

### Component Testing
```ruby
# spec/components/checkout/modals/address_modal_component_spec.rb
RSpec.describe Checkout::Modals::AddressModalComponent, type: :component do
  it "renders address form with validation" do
    rendered = render_inline(component)

    expect(rendered.css("[data-controller~='address-modal']")).to be_present
    expect(rendered.css("[data-validation-rules]")).to be_present
  end
end
```

### Integration Testing
```ruby
# spec/requests/checkout_spec.rb
describe "POST /checkout/delivery_summary" do
  it "updates address and returns turbo stream" do
    post "/checkout/delivery_summary", params: {
      delivery_method: "courier",
      address_line_1: "Test Address"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("turbo-stream")
  end
end
```

### System Testing
```ruby
# spec/system/checkout_flow_spec.rb
scenario "user enters delivery address" do
  visit checkout_path
  choose "Courier delivery"

  # Modal should auto-open
  expect(page).to have_selector("#address-modal", visible: true)

  fill_in "Address", with: "123 Test Street"
  click_button "Confirm Address"

  # Modal should close and summary should update
  expect(page).not_to have_selector("#address-modal", visible: true)
  expect(page).to have_content("123 Test Street")
end
```

## Best Practices

### 1. Follow Rails Conventions
- Use standard form submission patterns
- Leverage Turbo Stream for UI updates
- Keep business logic on the server

### 2. Progressive Enhancement
- Ensure form works without JavaScript
- Use Stimulus for enhancement, not core functionality
- Graceful degradation for older browsers

### 3. Validation Strategy
- Server-side validation as source of truth
- Client-side validation for immediate feedback
- Consistent validation rules between client and server

### 4. Error Handling
- Graceful error handling in JavaScript
- Meaningful error messages to users
- Fallback behavior when requests fail

### 5. Performance
- Minimal JavaScript for modal interactions
- Server-side rendering for complex UI updates
- Efficient use of Turbo Stream responses

## Maintenance Guidelines

### When Making Changes
1. **Preserve Simplicity**: Avoid adding complex JavaScript logic
2. **Test Both Sides**: Verify both client and server behavior
3. **Maintain Integration**: Ensure modal, form validation, and checkout form work together
4. **Document Changes**: Update this documentation when making architectural changes

### Future Enhancements
- Consider adding address validation API integration
- Improve mobile user experience
- Add address auto-completion features
- Implement address book functionality

---

**Implementation Date**: September 2025
**Technologies**: Rails 8, Stimulus, Turbo Streams, ViewComponent
**Status**: ✅ Production Ready
**Last Updated**: September 2025