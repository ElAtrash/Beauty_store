import { Controller } from "@hotwired/stimulus"
import { TimeoutMixin } from "mixins/timeout_mixin"

export default class extends Controller {
  static values = {
    translations: Object,
    rules: Object
  }

  disconnect() {
    this.clearCurrentTimeout()
  }

  connect() {
    Object.assign(this, TimeoutMixin)
    this.initializeTimeout()
    
    this.interacted = new Set()
    this.fieldsCache = null
    this.errorContainers = new WeakMap()
    this.setupValidation()
  }

  setupValidation() {
    this.fieldsCache = this.element.querySelectorAll('[data-validation-rules]')

    this.fieldsCache.forEach(field => {
      this.setupFieldValidation(field)
    })
  }

  setupFieldValidation(field) {
    const fieldName = field.name || field.id
    if (!fieldName) return

    // Add validation delay to prevent immediate validation
    let validationEnabled = false
    this.setTimeoutWithCleanup(() => { validationEnabled = true }, 300)

    field.addEventListener('blur', () => {
      if (validationEnabled && this.wasRecentlyFocused(field)) {
        this.interacted.add(fieldName)
        this.validateField(field)
      }
    })

    field.addEventListener('focus', () => {
      field.dataset.recentlyFocused = 'true'
    })

    field.addEventListener('input', () => {
      if (validationEnabled && this.interacted.has(fieldName)) {
        this.validateField(field)
      }
    })
  }

  validateField(field) {
    const fieldName = field.name || field.id
    const rules = this.getValidationRules(field)
    const errorContainer = this.findErrorContainer(field)

    if (!this.interacted.has(fieldName)) {
      this.clearFieldError(field, errorContainer)
      return true
    }

    for (const rule of rules) {
      if (!rule.test(field.value)) {
        const message = this.translationsValue[rule.message] || rule.message
        this.showFieldError(field, errorContainer, message)
        return false
      }
    }

    this.clearFieldError(field, errorContainer)
    return true
  }

  getValidationRules(field) {
    const rulesAttr = field.dataset.validationRules
    if (!rulesAttr) return []

    try {
      return JSON.parse(rulesAttr)
    } catch {
      return this.getPredefinedRules(rulesAttr)
    }
  }

  getPredefinedRules(ruleNames) {
    const predefinedRules = {
      email: [
        { test: (value) => !!value.trim(), message: 'email_required' },
        { test: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value), message: 'email_invalid' }
      ],
      password: [
        { test: (value) => !!value.trim(), message: 'password_required' },
        { test: (value) => value.length >= 8, message: 'password_too_short' }
      ],
      passwordConfirmation: [
        { test: (value) => !!value.trim(), message: 'password_confirmation_required' },
        { test: (value) => this.passwordsMatch(value), message: 'passwords_dont_match' }
      ]
    }

    return ruleNames.split(',').flatMap(name => predefinedRules[name.trim()] || [])
  }

  passwordsMatch(confirmationValue) {
    const form = this.element.closest('form')
    const passwordField = form?.querySelector('[name*="password"]:not([name*="confirmation"])')
    return passwordField ? confirmationValue === passwordField.value : true
  }

  findErrorContainer(field) {
    if (this.errorContainers.has(field)) {
      return this.errorContainers.get(field)
    }

    const container = field.closest('div')
    let errorContainer = container?.querySelector('.field-error')

    if (!errorContainer) {
      const parentContainer = container?.parentElement
      errorContainer = parentContainer?.querySelector('.field-error')
    }

    if (errorContainer) {
      this.errorContainers.set(field, errorContainer)
    }

    return errorContainer
  }

  showFieldError(field, errorContainer, message) {
    if (!errorContainer || !field) return

    if (this.isInputField(field)) {
      field.classList.remove('border-gray-300')
      field.classList.add('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
    }

    errorContainer.classList.remove('hidden')
    errorContainer.classList.add('flex', 'items-center', 'gap-1')

    const messageSpan = errorContainer.querySelector('span')
    if (messageSpan) {
      messageSpan.textContent = message || 'Validation error'
    }
  }

  clearFieldError(field, errorContainer) {
    if (!errorContainer || !field) return

    if (this.isInputField(field)) {
      field.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
      field.classList.add('border-gray-300')
    }

    errorContainer.classList.add('hidden')
    errorContainer.classList.remove('flex', 'items-center', 'gap-1')

    const messageSpan = errorContainer.querySelector('span')
    if (messageSpan) {
      messageSpan.textContent = ''
    }
  }

  wasRecentlyFocused(field) {
    const wasFocused = field.dataset.recentlyFocused === 'true'
    field.removeAttribute('data-recently-focused')
    return wasFocused
  }

  isInputField(field) {
    const inputTypes = ['input', 'textarea', 'select']
    return inputTypes.includes(field.tagName.toLowerCase())
  }

  clearAllErrors() {
    this.interacted.clear()

    const fields = this.fieldsCache || this.element.querySelectorAll('[data-validation-rules]')
    fields.forEach(field => {
      const errorContainer = this.findErrorContainer(field)
      this.clearFieldError(field, errorContainer)
    })
  }

  validateForm() {
    const fields = this.fieldsCache || this.element.querySelectorAll('[data-validation-rules]')
    let allValid = true

    fields.forEach(field => {
      const fieldName = field.name || field.id
      if (fieldName) {
        this.interacted.add(fieldName)
        if (!this.validateField(field)) {
          allValid = false
        }
      }
    })

    return allValid
  }
}
