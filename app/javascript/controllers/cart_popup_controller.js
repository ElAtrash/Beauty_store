import { Controller } from "@hotwired/stimulus"
import { EventHandlerMixin } from "mixins/event_handler_mixin"
import { KeyboardHandlerMixin } from "utilities"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  connect() {
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
    EventHandlerMixin.handleEventSafely.call(this, event, () => {
      this.isOpen = !this.isOpen
      this.updatePopupState()
    })
  }

  close(event) {
    EventHandlerMixin.handleEventSafely.call(this, event, () => {
      this.isOpen = false
      this.updatePopupState()
    })
  }

  open(event) {
    EventHandlerMixin.handleEventSafely.call(this, event, () => {
      this.isOpen = true
      this.updatePopupState()
    })
  }

  updatePopupState() {
    const state = this.isOpen ? 'open' : 'closed'
    this.element.dataset.cartPopup = state
  }
}
