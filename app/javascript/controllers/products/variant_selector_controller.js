import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "sizeOption",
    "colorOption"
  ]

  static values = {
    productId: Number
  }

  static classes = ["loading", "error"]

  connect() {
    try {
      this.clearErrors()
    } catch (error) {
      this.handleError('Failed to initialize variant selector', error)
    }
  }

  submitForm() {
    try {
      this.clearErrors()
      this.formTarget.requestSubmit()
      this.emitVariantChangeEvent()
    } catch (error) {
      this.handleError('Failed to submit form', error)
    }
  }

  emitVariantChangeEvent() {
    const event = new CustomEvent('variant:changed', {
      detail: {
        formSubmitted: true
      }
    })

    document.dispatchEvent(event)
  }

  handleOutOfStockNotification() {
    alert('We\'ll notify you when it\'s back in stock.')
  }

  handleError(message, error = null) {
    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    this.dispatch('error', {
      detail: {
        message,
        error: error?.message || error,
        controller: 'variant-selector'
      }
    })
  }

  clearErrors() {
    if (this.hasErrorClass) {
      this.element.classList.remove(this.errorClass)
    }
  }

  disconnect() {
    this.clearErrors()
  }
}
