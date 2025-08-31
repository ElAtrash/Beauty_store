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
      // Form will be submitted via Turbo Stream and server handles all price/stock updates
      this.formTarget.requestSubmit()
      
      // Emit event for any components that need to know variant is changing (like gallery)
      this.emitVariantChangeEvent()
    } catch (error) {
      this.handleError('Failed to submit form', error)
    }
  }

  // Simple event emission for compatibility with gallery controller
  emitVariantChangeEvent() {
    const event = new CustomEvent('variant:changed', {
      detail: {
        formSubmitted: true
      }
    })

    document.dispatchEvent(event)
  }

  // Handle out of stock notifications - simplified
  handleOutOfStockNotification() {
    alert('Thank you for your interest! We\'ll notify you when it\'s back in stock.')
  }

  // Error handling methods
  handleError(message, error = null) {
    console.error(`Variant Selector: ${message}`, error)

    // Add error state to element
    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    // Dispatch error event for external handling
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