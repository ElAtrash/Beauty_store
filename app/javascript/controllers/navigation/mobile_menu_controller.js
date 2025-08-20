import { Controller } from "@hotwired/stimulus"
import { KeyboardHandlerMixin } from "utilities"

export default class extends Controller {
  static targets = ["toggle", "overlay", "panel"]

  connect() {
    this.isOpen = false
    this.updateMenuState()
    KeyboardHandlerMixin.setupKeyboardListener.call(this)
  }

  disconnect() {
    KeyboardHandlerMixin.removeKeyboardListener.call(this)
  }

  handleKeydown(event) {
    KeyboardHandlerMixin.handleKeydown.call(this, event)
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen = !this.isOpen
    this.updateMenuState()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.isOpen = false
    this.updateMenuState()
  }

  open(event) {
    if (event) {
      event.preventDefault()
    }
    this.isOpen = true
    this.updateMenuState()
  }

  updateMenuState() {
    const state = this.isOpen ? 'open' : 'closed'

    const headerWrapper = document.querySelector('.header-wrapper') || document.body
    headerWrapper.dataset.mobileMenu = state

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-expanded', this.isOpen.toString())
    }

    this.dispatch('stateChanged', {
      detail: {
        isOpen: this.isOpen,
        state: state
      }
    })
  }

  toggleMenu(event) {
    this.toggle(event)
  }

  closeMenu(event) {
    this.close(event)
  }

  openMenu(event) {
    this.open(event)
  }
}
