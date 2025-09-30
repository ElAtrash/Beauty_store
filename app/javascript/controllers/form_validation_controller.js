import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static ERROR_CLASSES = ['border-red-500', 'focus:border-red-500', 'focus:ring-red-500']
  static NORMAL_CLASSES = ['border-gray-300']
  static DISABLED_CLASSES = ['opacity-50', 'cursor-not-allowed']
  static ASTERISK_ERROR_CLASSES = ['text-red-500']
  static ASTERISK_NORMAL_CLASSES = ['text-gray-400']
  static targets = ["submitButton"]
  static values = {
    translations: Object,
    rules: Object,
    deliveryMethod: String
  }

  connect() {
    this.interacted = new Set()
    this.errorContainers = new WeakMap()
    this.debounceTimers = new Map()
    this.validationResults = new Map()

    if (!this.deliveryMethodValue && this.element.dataset.deliveryMethod) {
      this.deliveryMethodValue = this.element.dataset.deliveryMethod
    }


    this.boundValidationHandler = this.handleValidationRequest.bind(this)
    this.boundFieldBlur = this.handleFieldBlur.bind(this)
    this.boundFieldInput = this.handleFieldInput.bind(this)
    this.boundFieldFocus = this.handleFieldFocus.bind(this)

    this.setupValidation()
    this.updateSubmitButtonState()

    this.element.addEventListener('addressValidationRequested', this.boundValidationHandler)
  }

  disconnect() {
    if (this.mutationObserver) { this.mutationObserver.disconnect() }

    if (this.debounceTimers) {
      this.debounceTimers.forEach(timer => clearTimeout(timer))
      this.debounceTimers.clear()
    }

    this.element.removeEventListener('blur', this.boundFieldBlur, true)
    this.element.removeEventListener('input', this.boundFieldInput)
    this.element.removeEventListener('focus', this.boundFieldFocus)
    this.element.removeEventListener('addressValidationRequested', this.boundValidationHandler)
  }

  setupValidation() {
    this.setupEventDelegation()
    this.setupDynamicValidation()
  }

  setupEventDelegation() {
    this.element.addEventListener('blur', this.boundFieldBlur, true)
    this.element.addEventListener('input', this.boundFieldInput)
    this.element.addEventListener('focus', this.boundFieldFocus)
  }

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
    this.mutationObserver = observer
  }

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

  handleFieldFocus(event) {
    const field = event.target
    if (!field.hasAttribute('data-validation-rules')) return

    field.dataset.recentlyFocused = 'true'
  }

  handleFieldInput(event) {
    const field = event.target
    if (!field.hasAttribute('data-validation-rules')) return

    const fieldName = field.name || field.id
    if (!fieldName) return

    this.interacted.add(fieldName)
    this.debouncedValidateField(field, fieldName)
  }

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

  validateField(field, silent = false) {
    const fieldName = field.name || field.id
    const rules = this.getValidationRules(field)
    let isValid = true

    if (!silent && !this.interacted.has(fieldName)) {
      const errorContainer = this.findErrorContainer(field)
      this.clearFieldError(field, errorContainer)
      this.cacheValidationResult(fieldName, true)
      this.updateSubmitButtonState()
      return true
    }

    for (const rule of rules) {
      if (!rule.test(field.value || '')) {
        isValid = false
        if (!silent) {
          const errorContainer = this.findErrorContainer(field)
          const message = this.getTranslatedMessage(rule.message)
          this.showFieldError(field, errorContainer, message)
        }
        break
      }
    }

    if (!silent) {
      if (isValid) {
        const errorContainer = this.findErrorContainer(field)
        this.clearFieldError(field, errorContainer)
      }
      this.cacheValidationResult(fieldName, isValid)
      this.updateSubmitButtonState()
    }

    return isValid
  }

  debouncedValidateField(field, fieldName, delay = 150) {
    if (this.debounceTimers.has(fieldName)) {
      clearTimeout(this.debounceTimers.get(fieldName))
    }

    const timer = setTimeout(() => {
      this.validateField(field)
      this.debounceTimers.delete(fieldName)
    }, delay)

    this.debounceTimers.set(fieldName, timer)
  }

  validateForm() {
    const fields = this.validationFields
    let allValid = true

    fields.forEach(field => {
      const fieldName = field.name || field.id
      if (fieldName) {
        this.interacted.add(fieldName)
        if (!this.validateField(field)) { allValid = false }
      }
    })

    return allValid
  }

  clearAllErrors() {
    this.interacted.clear()

    const fields = this.validationFields
    fields.forEach(field => {
      const errorContainer = this.findErrorContainer(field)
      this.clearFieldError(field, errorContainer)
    })
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
      required: [{ test: (value) => !!(value && value.trim()), message: 'field_required' }],
      first_name: [{ test: (value) => !!(value && value.trim()), message: 'first_name_required' }],
      last_name: [{ test: (value) => !!(value && value.trim()), message: 'last_name_required' }],
      email: [
        { test: (value) => !!(value && value.trim()), message: 'email_required' },
        { test: (value) => value && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value), message: 'email_invalid' }
      ],
      phone: [
        { test: (value) => !!(value && value.trim()), message: 'phone_required' },
        { test: (value) => value && /^(0?(?:[14-79]\d{6}|3\d{6,7}|7[0169]\d{6}|81[2-8]\d{5}))$/.test(value.replace(/\s+/g, '')), message: 'phone_invalid' }
      ],
      password: [
        { test: (value) => !!(value && value.trim()), message: 'password_required' },
        { test: (value) => value && value.length >= 8, message: 'password_too_short' }
      ],
      passwordConfirmation: [
        { test: (value) => !!(value && value.trim()), message: 'password_confirmation_required' },
        { test: (value) => this.passwordsMatch(value), message: 'passwords_dont_match' }
      ],
      address: [
        { test: (value) => !!(value && value.trim()), message: 'address_required' },
        { test: (value) => value && value.trim().length >= 5, message: 'address_too_short' }
      ],
      deliveryDate: [{ test: (value) => !!(value && value.trim()), message: 'delivery_date_required' }],
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
    }

    return ruleNames.split(',').flatMap(name => predefinedRules[name.trim()] || [])
  }

  getCurrentDeliveryMethod() {
    if (this.hasDeliveryMethodValue) { return this.deliveryMethodValue }

    const form = this.element.querySelector('form') || this.element.closest('form')
    const checkedRadio = form?.querySelector('input[name*="delivery_method"]:checked')
    if (checkedRadio) { return checkedRadio.value }

    const modalElement = this.element.querySelector('[data-delivery-method]')
    if (modalElement) { return modalElement.dataset.deliveryMethod }

    return 'pickup'
  }

  isPickupMethod() { return this.getCurrentDeliveryMethod() === 'pickup' }

  isCourierMethod() { return this.getCurrentDeliveryMethod() === 'courier' }

  updateDeliveryMethod(method) {
    this.deliveryMethodValue = method
    this.clearConditionalErrors(method)
    this.updateSubmitButtonState()
  }

  clearConditionalErrors(method) {
    const fields = this.validationFields

    fields.forEach(field => {
      const rulesAttr = field.dataset.validationRules || ''
      const shouldClear = (
        (method === 'pickup' && rulesAttr.includes('courier')) ||
        (method === 'courier' && rulesAttr.includes('pickup'))
      )

      if (shouldClear) {
        const fieldName = field.name || field.id
        const errorContainer = this.findErrorContainer(field)
        this.clearFieldError(field, errorContainer)

        if (fieldName) {
          this.interacted.delete(fieldName)
          this.validationResults.delete(fieldName)
        }
      }
    })
  }

  applyFieldStyling(field, isError = true) {
    if (!this.isInputField(field)) return

    if (isError) {
      field.classList.remove(...this.constructor.NORMAL_CLASSES)
      field.classList.add(...this.constructor.ERROR_CLASSES)
    } else {
      field.classList.remove(...this.constructor.ERROR_CLASSES)
      field.classList.add(...this.constructor.NORMAL_CLASSES)
    }

    this.handlePhonePrefixStyling(field, isError)
  }

  handlePhonePrefixStyling(field, isError = true) {
    const phonePrefix = field.parentElement?.querySelector('span')
    if (phonePrefix && phonePrefix.textContent === '+961') {
      if (isError) {
        phonePrefix.classList.add('border-red-500')
      } else {
        phonePrefix.classList.remove('border-red-500')
      }
    }
  }

  applyFormFieldStyling(field, isError = true) {
    const formField = field.closest('.form-field')
    if (!formField) return

    if (isError) {
      formField.classList.add('form-field--error')
      this.updateAsteriskStyling(formField, true)
    } else {
      formField.classList.remove('form-field--error')
      this.updateAsteriskStyling(formField, false)
    }
  }

  updateAsteriskStyling(formField, isError = true) {
    const asterisk = formField.querySelector('span.text-gray-400, span.text-red-500')
    if (!asterisk) return

    if (isError) {
      asterisk.classList.remove(...this.constructor.ASTERISK_NORMAL_CLASSES)
      asterisk.classList.add(...this.constructor.ASTERISK_ERROR_CLASSES)
    } else {
      asterisk.classList.remove(...this.constructor.ASTERISK_ERROR_CLASSES)
      asterisk.classList.add(...this.constructor.ASTERISK_NORMAL_CLASSES)
    }
  }

  showFieldError(field, errorContainer, message) {
    if (!errorContainer || !field) return

    this.applyFieldStyling(field, true)
    this.applyFormFieldStyling(field, true)

    errorContainer.classList.remove('hidden')
    errorContainer.classList.add('flex', 'items-center', 'gap-1')

    const messageSpan = errorContainer.querySelector('span')
    if (messageSpan) {
      messageSpan.textContent = message || this.getTranslatedMessage('validation_error')
    }
  }

  clearFieldError(field, errorContainer) {
    if (!errorContainer || !field) return

    this.applyFieldStyling(field, false)
    this.applyFormFieldStyling(field, false)

    errorContainer.classList.add('hidden')
    errorContainer.classList.remove('flex', 'items-center', 'gap-1')

    const messageSpan = errorContainer.querySelector('span')
    if (messageSpan) {
      messageSpan.textContent = ''
    }
  }

  cacheValidationResult(fieldName, isValid) {
    if (fieldName) {
      this.validationResults.set(fieldName, isValid)
    }
  }

  updateSubmitButtonState() {
    if (!this.hasSubmitButtonTarget) return

    const hasVisibleErrors = this.element.querySelector('.border-red-500, .form-field--error') !== null

    const requiredFields = this.validationFields
    const allRequiredValid = Array.from(requiredFields).every(field => {
      const rules = this.getValidationRules(field)
      if (rules.length === 0) return true

      return this.validateField(field, true)
    })

    const allValid = !hasVisibleErrors && allRequiredValid
    this.submitButtonTarget.disabled = !allValid

    if (allValid) {
      this.submitButtonTarget.classList.remove(...this.constructor.DISABLED_CLASSES)
    } else {
      this.submitButtonTarget.classList.add(...this.constructor.DISABLED_CLASSES)
    }
  }

  get validationFields() {
    return this.element.querySelectorAll('[data-validation-rules]')
  }

  findErrorContainer(field) {
    if (this.errorContainers.has(field)) { return this.errorContainers.get(field) }

    const formField = field.closest('.form-field')
    let errorContainer = formField?.querySelector('.form-error-message')

    if (!errorContainer) {
      const container = field.closest('div')
      errorContainer = container?.querySelector('.field-error')

      if (!errorContainer) {
        const parentContainer = container?.parentElement
        errorContainer = parentContainer?.querySelector('.field-error')
      }
    }

    if (errorContainer) { this.errorContainers.set(field, errorContainer) }
    return errorContainer
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

  passwordsMatch(confirmationValue) {
    const form = this.element.closest('form')
    const passwordField = form?.querySelector('[name*="password"]:not([name*="confirmation"])')
    return passwordField ? confirmationValue === passwordField.value : true
  }

  getTranslatedMessage(messageKey) {
    if (!messageKey) {
      console.warn('FormValidation: undefined message key provided')
      return this.getTranslatedMessage('validation_error') || 'Validation error'
    }

    if (this.translationsValue && typeof this.translationsValue === 'object') {
      const translation = this.translationsValue[messageKey]
      if (translation && typeof translation === 'string') {
        return translation
      }
    }

    if (this.hasTranslationsValue) {
      console.warn(`FormValidation: Missing translation for key '${messageKey}'`)
    }

    return messageKey
  }
}
