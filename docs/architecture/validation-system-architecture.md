# Validation System Architecture

## Overview

The application implements a comprehensive client-side validation system using a single `form_validation_controller.js` Stimulus controller combined with server-side validation via Rails models and form objects. This document details the complete validation architecture implemented during the checkout flow development.

## Architecture Components

### 1. Client-Side Validation (Stimulus)

**Location**: `app/javascript/controllers/form_validation_controller.js`

**Purpose**: Real-time validation feedback with conditional logic based on delivery method

**Key Features**:

- Single controller instance per form (no conflicts)
- Immediate validation on user input
- Conditional validation rules based on delivery method
- Dynamic error display/clearing
- Submit button state management

### 2. Server-Side Validation

**Form Objects**: `app/forms/checkout_form.rb`
**Models**: Various models with ActiveRecord validations

**Purpose**: Final validation before data persistence

### 3. Unified Form Components

**Component**: `app/components/form_field_component.rb`
**Template**: `app/components/form_field_component.html.erb`

**Purpose**: Consistent form field rendering with built-in validation support

## How Validation Works

### 1. Form Field Setup

Each form field is rendered using `FormFieldComponent` with validation rules:

```erb
<%= render FormFieldComponent.new(
  form: f,
  field: :email,
  type: :email,
  required: true,
  validation_rules: "email",
  options: { helper_text: "We'll send order confirmation here" }
) %>
```

### 2. Data Attributes

The component automatically adds validation rules as data attributes to input fields:

```html
<input
  type="email"
  name="checkout_form[email]"
  data-validation-rules="email"
  class="form-input"
/>
```

### 3. Controller Registration

The main form registers the validation controller:

```erb
<%= form_with model: checkout_form,
    data: { controller: "form-validation" } do |f| %>
```

### 4. Field Discovery

The controller automatically discovers and sets up validation for all fields with `data-validation-rules`:

```javascript
get validationFields() {
  return this.element.querySelectorAll('[data-validation-rules]')
}
```

### 5. Event Handling

The controller uses event delegation with three main event handlers:

```javascript
// Mark field as focused
handleFieldFocus(event) {
  const field = event.target
  if (!field.hasAttribute('data-validation-rules')) return

  field.dataset.recentlyFocused = 'true'
}

// Validate on blur (if recently focused)
handleFieldBlur(event) {
  const field = event.target
  if (!field.hasAttribute('data-validation-rules')) return

  const fieldName = field.name || field.id
  if (!fieldName) return

  if (this.wasRecentlyFocused(field)) {
    this.interacted.add(fieldName)
    this.validateField(field)
  }
}

// Immediate validation on input (with debouncing)
handleFieldInput(event) {
  const field = event.target
  if (!field.hasAttribute('data-validation-rules')) return

  const fieldName = field.name || field.id
  if (!fieldName) return

  this.interacted.add(fieldName)
  this.debouncedValidateField(field, fieldName)
}
```

### 6. Validation Rules

Predefined validation rules support various field types:

```javascript
const predefinedRules = {
  required: [
    { test: (value) => !!(value && value.trim()), message: "field_required" }
  ],
  first_name: [
    { test: (value) => !!(value && value.trim()), message: "first_name_required" }
  ],
  last_name: [
    { test: (value) => !!(value && value.trim()), message: "last_name_required" }
  ],
  email: [
    { test: (value) => !!(value && value.trim()), message: "email_required" },
    {
      test: (value) => value && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value),
      message: "email_invalid",
    },
  ],
  phone: [
    { test: (value) => !!(value && value.trim()), message: "phone_required" },
    {
      test: (value) =>
        value &&
        /^(\+961|961)?(70|71|03|76|81)\d{6}$/.test(
          value.replace(/\s+/g, "")
        ),
      message: "phone_lebanon_invalid",
    },
  ],
  password: [
    { test: (value) => !!(value && value.trim()), message: "password_required" },
    { test: (value) => value && value.length >= 8, message: "password_too_short" }
  ],
  passwordConfirmation: [
    { test: (value) => !!(value && value.trim()), message: "password_confirmation_required" },
    { test: (value) => this.passwordsMatch(value), message: "passwords_dont_match" }
  ],
  address: [
    { test: (value) => !!(value && value.trim()), message: "address_required" },
    { test: (value) => value && value.trim().length >= 5, message: "address_too_short" }
  ],
  deliveryDate: [
    { test: (value) => !!(value && value.trim()), message: "delivery_date_required" }
  ],
  courier_required: [
    { test: (value) => this.isPickupMethod() || !!(value && value.trim()), message: 'field_required' }
  ],
  courier_address: [
    { test: (value) => this.isPickupMethod() || !!(value && value.trim()), message: 'address_required' },
    { test: (value) => this.isPickupMethod() || (value && value.trim().length >= 5), message: 'address_too_short' }
  ],
  pickup_required: [
    { test: (value) => this.isCourierMethod() || !!(value && value.trim()), message: 'field_required' }
  ]
};
```

### 7. Conditional Validation

Special rules adapt to delivery method context:

```javascript
courier_required: [
  { test: (value) => this.isPickupMethod() || !!(value && value.trim()), message: 'field_required' }
],
courier_address: [
  { test: (value) => this.isPickupMethod() || !!(value && value.trim()), message: 'address_required' },
  { test: (value) => this.isPickupMethod() || (value && value.trim().length >= 5), message: 'address_too_short' }
],
pickup_required: [
  { test: (value) => this.isCourierMethod() || !!(value && value.trim()), message: 'field_required' }
]
```

### 8. Error Display

The system automatically finds and manages error containers:

```javascript
findErrorContainer(field) {
  // First try FormFieldComponent structure
  const formField = field.closest('.form-field')
  let errorContainer = formField?.querySelector('.form-error-message')

  // Fallback to auth form structure
  if (!errorContainer) {
    const container = field.closest('div')
    errorContainer = container?.querySelector('.field-error')
  }

  return errorContainer
}
```

### 9. Visual Feedback

The system provides immediate visual feedback:

**Error State**:

- Red border on input field
- Red asterisk for required fields
- Error message displayed
- Submit button disabled

**Valid State**:

- Gray border on input field
- Gray asterisk for required fields
- Error message hidden
- Submit button enabled (if all fields valid)

## Integration with Checkout Flow

### Delivery Method Context

The validation system integrates with the checkout form controller to receive delivery method updates:

```javascript
// In checkout_form_controller.js
notifyValidationController(method) {
  const formValidationController = this.application.getControllerForElementAndIdentifier(
    this.element, "form-validation"
  )

  if (formValidationController && formValidationController.updateDeliveryMethod) {
    formValidationController.updateDeliveryMethod(method)
  }
}
```

### Dynamic Field Management

The system handles dynamically added fields (like modal forms) using a MutationObserver:

```javascript
setupDynamicValidation() {
  const observer = new MutationObserver((mutations) => {
    let shouldRefresh = false

    mutations.forEach((mutation) => {
      if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === 1) {
            const hasValidationFields = node.querySelectorAll &&
              node.querySelectorAll('[data-validation-rules]').length > 0
            if (hasValidationFields) { shouldRefresh = true }
          }
        })
      }
    })

    if (shouldRefresh) { this.updateSubmitButtonState() }
  })

  observer.observe(this.element, { childList: true, subtree: true })
}
```

### Custom Event Integration

The system also supports validation updates via custom events:

```javascript
// Custom event handler for external validation requests
handleValidationRequest(event) {
  const { field } = event.detail

  if (field) {
    const fieldName = field.name || field.id
    if (fieldName) {
      this.interacted.add(fieldName)
      this.validateField(field)
    }
  }
}

// In checkout_form_controller.js
notifyValidationController(method) {
  const formValidationController = this.application.getControllerForElementAndIdentifier(
    this.element, "form-validation"
  )

  if (formValidationController && formValidationController.updateDeliveryMethod) {
    formValidationController.updateDeliveryMethod(method)
  }
}
```

## Supported Field Types

- **Text fields**: Basic required validation
- **Email fields**: Format validation with regex
- **Phone fields**: Lebanese phone number format validation
- **Password fields**: Minimum length requirements
- **Password Confirmation**: Match with original password validation
- **Address fields**: Minimum length validation
- **Delivery Date**: Required field validation
- **Conditional fields**: Based on delivery method context (courier/pickup)

## Error Messages

Default error messages with translation support:

```javascript
const defaultMessages = {
  field_required: "This field is required",
  email_required: "Email is required",
  email_invalid: "Please enter a valid email address",
  phone_required: "Phone number is required",
  phone_invalid: "Please enter a valid phone number",
  address_required: "Address is required",
  address_too_short: "Address must be at least 5 characters",
};
```

## Benefits

1. **Immediate Feedback**: Users see validation errors as they type
2. **Context-Aware**: Validation adapts to delivery method selection
3. **Unified System**: Consistent validation across all forms
4. **Performance**: Single controller instance prevents conflicts
5. **Accessibility**: Proper ARIA labels and error associations
6. **Maintainable**: Centralized validation logic
7. **Extensible**: Easy to add new validation rules

## Usage Examples

### Basic Required Field

```erb
<%= render FormFieldComponent.new(
  form: f,
  field: :first_name,
  required: true,
  validation_rules: "required"
) %>
```

### Email Field with Helper Text

```erb
<%= render FormFieldComponent.new(
  form: f,
  field: :email,
  type: :email,
  required: true,
  validation_rules: "email",
  options: { helper_text: "We'll send order confirmation here" }
) %>
```

### Conditional Address Field

```erb
<%= render FormFieldComponent.new(
  form: f,
  field: :address_line_1,
  required: true,
  validation_rules: "courier_address"
) %>
```

This validation system provides a robust, user-friendly foundation for all form interactions in the application while maintaining clean separation of concerns between client-side UX and server-side data integrity.
