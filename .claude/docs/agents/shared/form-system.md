# Unified Form System

The application uses a **unified FormFieldComponent system** for consistent form handling across all forms.

## FormFieldComponent

**Location**: `app/components/form_field_component.rb` + `.html.erb`

**Purpose**: Single source of truth for all form fields with built-in validation, asterisk handling, and error display.

## Usage

```erb
<%= render FormFieldComponent.new(
  form: form,
  field: :email,
  type: :email,
  required: true,
  placeholder: "Enter your email",
  validation_rules: "email",
  options: { helper_text: "We'll send order confirmation here" }
) %>
```

## Supported Field Types

- `:text` (default)
- `:email`
- `:phone` / `:tel`
- `:password`
- `:select`
- `:textarea`

## Validation Rules

- `"required"` - Field is required
- `"email"` - Email format validation
- `"phone"` - Lebanon phone number validation
- `"password"` - Password requirements
- `"passwordConfirmation"` - Password confirmation matching

## Features

✅ **Automatic asterisks**: Required fields show gray asterisks, red on errors
✅ **Real-time validation**: Uses `form_validation_controller.js`
✅ **Error handling**: Built-in error containers that toggle with validation
✅ **Helper text**: Optional helper text below fields
✅ **Accessibility**: ARIA labels and screen reader support
✅ **Consistent styling**: Same look across all forms

## CSS Architecture (Tailwind v4 Compatible)

- **Direct utility classes**: No `@apply` directives that break in v4
- **No `!important`**: Use direct utilities for reliable styling
- **Component isolation**: Each component handles its own styling

## FormFieldComponent Implementation

### Ruby Component

```ruby
class FormFieldComponent < ViewComponent::Base
  def initialize(form:, field:, type: :text, required: false, validation_rules: nil, **options)
    @form = form
    @field = field
    @type = type
    @required = required
    @validation_rules = validation_rules
    @options = options
  end

  private

  attr_reader :form, :field, :type, :required, :validation_rules, :options

  def field_classes
    class_names(
      "w-full px-3 py-2 border rounded-md",
      "focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
      error_classes,
      options[:class]
    )
  end

  def error_classes
    return nil unless has_errors?
    "border-red-300 bg-red-50 focus:ring-red-500 focus:border-red-500"
  end

  def label_classes
    class_names(
      "block text-sm font-medium mb-2",
      required? ? "text-gray-700" : "text-gray-600"
    )
  end

  def has_errors?
    form.object&.errors&.key?(field)
  end

  def field_errors
    form.object&.errors&.full_messages_for(field) || []
  end

  def required?
    required
  end

  def asterisk_classes
    class_names(
      "ml-1",
      has_errors? ? "text-red-500" : "text-gray-400"
    )
  end
end
```

### ERB Template

```erb
<div class="form-field" data-controller="form-validation"
     data-form-validation-rules-value="<%= validation_rules %>"
     data-form-validation-required-value="<%= required %>">

  <%= form.label field, class: label_classes do %>
    <%= field.to_s.humanize %>
    <% if required? %>
      <span class="<%= asterisk_classes %>">*</span>
    <% end %>
  <% end %>

  <% case type %>
  <% when :textarea %>
    <%= form.text_area field, class: field_classes, **field_options %>
  <% when :select %>
    <%= form.select field, options[:choices], options[:select_options] || {}, class: field_classes %>
  <% else %>
    <%= form.send("#{type}_field", field, class: field_classes, **field_options) %>
  <% end %>

  <% if options[:helper_text] %>
    <p class="mt-1 text-sm text-gray-600"><%= options[:helper_text] %></p>
  <% end %>

  <div class="error-container mt-1" style="display: <%= has_errors? ? 'block' : 'none' %>">
    <% field_errors.each do |error| %>
      <p class="text-sm text-red-600"><%= error %></p>
    <% end %>
  </div>
</div>
```

## JavaScript Validation Controller

```javascript
// app/javascript/controllers/form_validation_controller.js
export default class extends Controller {
  static values = {
    rules: String,
    required: Boolean
  }

  connect() {
    this.field = this.element.querySelector('input, textarea, select')
    this.errorContainer = this.element.querySelector('.error-container')
    this.asterisk = this.element.querySelector('.asterisk')

    this.field.addEventListener('blur', this.validate.bind(this))
    this.field.addEventListener('input', this.clearErrors.bind(this))
  }

  validate() {
    const value = this.field.value.trim()
    const rules = this.rulesValue.split(',')

    let isValid = true
    let errors = []

    // Required validation
    if (this.requiredValue && !value) {
      isValid = false
      errors.push(`${this.fieldName} is required`)
    }

    // Email validation
    if (rules.includes('email') && value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(value)) {
        isValid = false
        errors.push('Please enter a valid email address')
      }
    }

    // Phone validation (Lebanon format)
    if (rules.includes('phone') && value) {
      const phoneRegex = /^(\+961|961|0)?[3-9]\d{7}$/
      if (!phoneRegex.test(value.replace(/\s/g, ''))) {
        isValid = false
        errors.push('Please enter a valid Lebanese phone number')
      }
    }

    this.displayErrors(errors)
    this.updateFieldState(isValid)

    return isValid
  }

  displayErrors(errors) {
    this.errorContainer.innerHTML = ''

    if (errors.length > 0) {
      errors.forEach(error => {
        const errorElement = document.createElement('p')
        errorElement.className = 'text-sm text-red-600'
        errorElement.textContent = error
        this.errorContainer.appendChild(errorElement)
      })
      this.errorContainer.style.display = 'block'
    } else {
      this.errorContainer.style.display = 'none'
    }
  }

  updateFieldState(isValid) {
    // Update field styling
    if (isValid) {
      this.field.classList.remove('border-red-300', 'bg-red-50')
      this.field.classList.add('border-gray-300')
    } else {
      this.field.classList.add('border-red-300', 'bg-red-50')
      this.field.classList.remove('border-gray-300')
    }

    // Update asterisk color
    if (this.asterisk) {
      this.asterisk.classList.toggle('text-red-500', !isValid)
      this.asterisk.classList.toggle('text-gray-400', isValid)
    }
  }
}
```

## Migration Pattern

### Old Manual Approach

```erb
<div class="form-field form-field--required">
  <span class="asterisk">*</span>
  <%= form.text_field :name, class: "form-input" %>
  <div class="error-message"></div>
</div>
```

### New Unified Approach

```erb
<%= render FormFieldComponent.new(
  form: form,
  field: :name,
  required: true,
  validation_rules: "required"
) %>
```

## Guidelines

1. **Always use FormFieldComponent** for new forms
2. **Migrate existing forms** when making changes
3. **Use direct Tailwind utilities** instead of custom CSS classes
4. **Avoid `!important`** - use proper CSS specificity instead
5. **Test validation rules** in both success and error states

## Testing Patterns

```ruby
RSpec.describe FormFieldComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:form_builder) do
    ActionView::Helpers::FormBuilder.new(:user, user, template, {})
  end

  it "renders required field with asterisk" do
    component = described_class.new(
      form: form_builder,
      field: :email,
      required: true
    )
    rendered = render_inline(component)

    expect(rendered.css("label")).to include_text("*")
    expect(rendered.css("[data-form-validation-required-value='true']")).to be_present
  end

  it "displays validation errors" do
    user.errors.add(:email, "is invalid")

    rendered = render_inline(component)

    expect(rendered.css(".error-container")).to be_visible
    expect(rendered.text).to include("Email is invalid")
  end
end
```

## Form Integration Examples

### Checkout Form

```erb
<%= form_with model: @checkout_form, local: true do |form| %>
  <%= render FormFieldComponent.new(
    form: form,
    field: :first_name,
    required: true,
    validation_rules: "required"
  ) %>

  <%= render FormFieldComponent.new(
    form: form,
    field: :email,
    type: :email,
    required: true,
    validation_rules: "required,email"
  ) %>

  <%= render FormFieldComponent.new(
    form: form,
    field: :phone,
    type: :tel,
    required: true,
    validation_rules: "required,phone"
  ) %>
<% end %>
```

### Authentication Form

```erb
<%= form_with model: User.new, url: signup_path do |form| %>
  <%= render FormFieldComponent.new(
    form: form,
    field: :password,
    type: :password,
    required: true,
    validation_rules: "required,password",
    options: { helper_text: "Must be at least 8 characters" }
  ) %>

  <%= render FormFieldComponent.new(
    form: form,
    field: :password_confirmation,
    type: :password,
    required: true,
    validation_rules: "required,passwordConfirmation"
  ) %>
<% end %>
```