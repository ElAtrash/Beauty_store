import { Controller } from "@hotwired/stimulus"
import { EventHandlerMixin } from "mixins/event_handler_mixin"
import { KeyboardHandlerMixin } from "utilities"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  connect() {
    Object.assign(this, EventHandlerMixin)

    this.isOpen = false
    this.updatePopupState()
    KeyboardHandlerMixin.setupKeyboardListener.call(this)
  }

  disconnect() {
    KeyboardHandlerMixin.removeKeyboardListener.call(this)
  }

  handleKeydown(event) {
    KeyboardHandlerMixin.handleKeydown.call(this, event)
  }

  handleCartOpen(event) {
    this.open(event)
  }

  toggle(event) {
    this.handleEventSafely(event, () => {
      this.isOpen = !this.isOpen
      this.updatePopupState()
    })
  }

  close(event) {
    this.handleEventSafely(event, () => {
      this.isOpen = false
      this.updatePopupState()
    })
  }

  open(event) {
    this.handleEventSafely(event, () => {
      this.isOpen = true
      this.updatePopupState()
    })
  }

  updatePopupState() {
    const state = this.isOpen ? 'open' : 'closed'
    this.element.dataset.cartPopup = state
  }
}
