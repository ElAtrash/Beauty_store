import { Controller } from "@hotwired/stimulus"
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

  toggle(event) {
    event.preventDefault()

    const isAuthenticated = document.body.dataset.authenticated === 'true'
    if (!isAuthenticated && !this.isOpen) {
      sessionStorage.setItem('authReturnUrl', window.location.href)
    }

    this.isOpen = !this.isOpen
    this.updatePopupState()

    if (this.isOpen && !isAuthenticated) {
      this.dispatch('clearErrors', { bubbles: true })
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.isOpen = false
    this.updatePopupState()
  }

  open(event) {
    if (event) {
      event.preventDefault()
    }
    this.isOpen = true
    this.updatePopupState()
  }

  updatePopupState() {
    const state = this.isOpen ? 'open' : 'closed'

    const headerWrapper = document.querySelector('.header-wrapper') || document.body
    headerWrapper.dataset.authPopup = state

    this.dispatch('stateChanged', {
      detail: {
        isOpen: this.isOpen,
        state: state
      }
    })
  }

  openProfile(event) {
    this.toggle(event)
  }

  closePopup(event) {
    this.close(event)
  }
}
