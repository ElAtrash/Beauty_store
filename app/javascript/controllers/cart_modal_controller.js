import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkoutForm", "addressLine1", "addressLine2", "landmarks"]
  static outlets = ["formValidation"]
  static values = {
    deliverySummaryUrl: String,
    defaultDeliveryMethod: { type: String, default: "courier" }
  }

  connect() {
    this.boundHandleAddressSubmit = this.handleAddressSubmit.bind(this)
    document.addEventListener('address:submitted', this.boundHandleAddressSubmit)
  }

  disconnect() {
    if (this.boundHandleAddressSubmit) {
      document.removeEventListener('address:submitted', this.boundHandleAddressSubmit)
    }
  }

  handleAddressSubmit(event) {
    const { addressData } = event.detail

    if (addressData && addressData.address_line_1?.trim()) {
      this.updateCheckoutFormFields(addressData)
      this.sendDeliverySummaryUpdate(addressData)
    } else {
      this.requestFieldValidation()
    }
  }

  updateCheckoutFormFields(addressData) {
    if (!this.hasCheckoutFormTarget) return

    if (this.hasAddressLine1Target) {
      this.addressLine1Target.value = addressData.address_line_1
    }

    if (this.hasAddressLine2Target) {
      this.addressLine2Target.value = addressData.address_line_2
    }

    if (this.hasLandmarksTarget) {
      this.landmarksTarget.value = addressData.landmarks
    }

    this.dispatch('fieldsUpdated', {
      detail: { addressData },
      bubbles: true
    })
  }

  sendDeliverySummaryUpdate(addressData) {
    if (!this.deliverySummaryUrlValue) {
      console.warn('Cart modal: delivery summary URL not configured')
      return
    }

    const formData = new FormData()
    formData.append('delivery_method', this.defaultDeliveryMethodValue)
    formData.append('address_line_1', addressData.address_line_1)
    formData.append('address_line_2', addressData.address_line_2)
    formData.append('landmarks', addressData.landmarks)

    fetch(this.deliverySummaryUrlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`)
        }
        return response.text()
      })
      .then(html => {
        if (html.includes('turbo-stream')) {
          Turbo.renderStreamMessage(html)
        }

        this.dispatch('deliverySummaryUpdated', {
          detail: { addressData },
          bubbles: true
        })
      })
      .catch(error => {
        console.error('Cart modal: Error updating delivery summary:', error)

        this.dispatch('deliverySummaryError', {
          detail: { error: error.message, addressData },
          bubbles: true
        })
      })
  }

  requestFieldValidation() {
    if (this.hasFormValidationOutlet) {
      this.formValidationOutlet.updateDeliveryMethod(this.defaultDeliveryMethodValue)

      this.dispatch('validationRequested', {
        detail: { deliveryMethod: this.defaultDeliveryMethodValue },
        bubbles: true
      })
    } else {
      console.warn('Cart modal: form validation outlet not available')
    }
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ''
  }
}
