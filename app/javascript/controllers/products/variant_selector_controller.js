import { Controller } from "@hotwired/stimulus"
import { EventHandlerMixin } from "mixins/event_handler_mixin"

export default class extends Controller {
  static targets = ["form", "sizeOption", "colorOption"]
  static values = { productId: Number }
  static classes = ["loading", "error"]

  connect() {
    this.clearErrors()
  }

  disconnect() {
    this.clearErrors()
  }

  submitForm() {
    EventHandlerMixin.handleEventSafely.call(this, null, () => {
      this.clearErrors()
      this.formTarget.requestSubmit()
      this.emitVariantChangeEvent()
    })
  }

  sizeOptionTargetConnected(element) {
    element.addEventListener('change', this.handleVariantChange.bind(this))
  }

  colorOptionTargetConnected(element) {
    element.addEventListener('change', this.handleVariantChange.bind(this))
  }

  handleVariantChange() {
    this.submitForm()
  }

  emitVariantChangeEvent() {
    const event = new CustomEvent('variant:changed', {
      detail: {
        productId: this.productIdValue,
        formSubmitted: true
      }
    })

    document.dispatchEvent(event)
  }

  handleOutOfStockNotification() {
    this.dispatch('stock-unavailable', {
      detail: { message: "We'll notify you when it's back in stock." }
    })
  }

  handleError(message, error = null) {
    EventHandlerMixin.dispatchError.call(this, 'variant-selector-error', error || message)

    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }
  }

  clearErrors() {
    if (this.hasErrorClass) {
      this.element.classList.remove(this.errorClass)
    }
  }
}
