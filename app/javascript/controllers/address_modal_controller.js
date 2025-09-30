import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "addressLine1", "addressLine2", "landmarks", "submitButton"]
  static outlets = ["modal", "form-validation"]
  static values = {
    defaultCity: String,
    persistUrl: String,
    deliverySummaryUrl: String
  }

  static DELIVERY_METHOD = 'courier'
  static DISABLED_CLASSES = ['opacity-50', 'cursor-not-allowed']
  static ERROR_SELECTORS = '.border-red-500, .form-field--error'

  connect() {
    this.updateSubmitButtonState()
    this.setupFieldListeners()
  }

  setupFieldListeners() {
    if (this.hasAddressLine1Target) {
      this.addressLine1Target.addEventListener('input', () => {
        setTimeout(() => this.updateSubmitButtonState(), 50)
      })
      this.addressLine1Target.addEventListener('blur', () => {
        this.requestFieldValidation()
      })
    }
  }

  open() {
    if (this.hasModalOutlet) {
      this.modalOutlet.open()
      this.setupModalValidation()
    }
  }

  close() { if (this.hasModalOutlet) { this.modalOutlet.close() } }

  setupModalValidation() {
    const deliveryMethod = this.getDeliveryMethodFromMainForm()

    if (this.hasFormValidationOutlet) {
      this.formValidationOutlet.updateDeliveryMethod(deliveryMethod)
    }
    this.updateSubmitButtonState()
  }

  getDeliveryMethodFromMainForm() {
    const mainForm = document.querySelector('.checkout-form')
    if (mainForm) {
      const deliveryMethodInput = mainForm.querySelector('input[name*="delivery_method"]:checked')
      if (deliveryMethodInput) { return deliveryMethodInput.value }
    }

    return 'courier'
  }

  submitAddress(event) {
    event.preventDefault()

    if (this.hasSubmitButtonTarget && this.submitButtonTarget.disabled) { return }

    const addressData = this.getAddressData()
    const addressValue = addressData.address_line_1?.trim() || ''

    if (addressValue.length < 5) {
      this.updateSubmitButtonState()
      return
    }

    const hasErrors = this.element.querySelectorAll(this.constructor.ERROR_SELECTORS).length > 0
    if (hasErrors) {
      this.updateSubmitButtonState()
      return
    }

    this.submitToServer()
  }

  submitToServer() {
    const addressData = this.getAddressData()
    const formData = new FormData()
    const url = this.deliverySummaryUrlValue

    formData.append('delivery_method', this.constructor.DELIVERY_METHOD)
    Object.entries(addressData).forEach(([key, value]) => {
      formData.append(key, value || '')
    })

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }
        return response.text()
      })
      .then(html => {
        if (html.includes('turbo-stream')) {
          Turbo.renderStreamMessage(html)
        }
        this.close()
      })
      .catch(error => {
        console.error('Error submitting address:', error)
        // Could dispatch custom event for error handling
      })
  }

  getAddressData() {
    return {
      address_line_1: this.hasAddressLine1Target ? this.addressLine1Target.value : '',
      address_line_2: this.hasAddressLine2Target ? this.addressLine2Target.value : '',
      landmarks: this.hasLandmarksTarget ? this.landmarksTarget.value : '',
      city: this.defaultCityValue
    }
  }

  requestFieldValidation() {
    if (this.hasFormValidationOutlet) {
      this.formValidationOutlet.updateDeliveryMethod(this.constructor.DELIVERY_METHOD)

      if (this.hasAddressLine1Target) {
        const fieldName = this.addressLine1Target.name || this.addressLine1Target.id
        if (fieldName && this.formValidationOutlet.interacted) {
          this.formValidationOutlet.interacted.add(fieldName)
          this.formValidationOutlet.validateField(this.addressLine1Target)
        }
      }
    }

    setTimeout(() => this.updateSubmitButtonState(), 50)
  }

  updateSubmitButtonState() {
    if (!this.hasSubmitButtonTarget) return

    const addressValue = this.hasAddressLine1Target ? this.addressLine1Target.value?.trim() || '' : ''
    const isValidLength = addressValue.length >= 5
    const hasVisibleErrors = this.element.querySelectorAll(this.constructor.ERROR_SELECTORS).length > 0
    const buttonShouldBeEnabled = isValidLength && !hasVisibleErrors

    this.submitButtonTarget.disabled = !buttonShouldBeEnabled

    if (buttonShouldBeEnabled) {
      this.submitButtonTarget.classList.remove(...this.constructor.DISABLED_CLASSES)
    } else {
      this.submitButtonTarget.classList.add(...this.constructor.DISABLED_CLASSES)
    }
  }
}
