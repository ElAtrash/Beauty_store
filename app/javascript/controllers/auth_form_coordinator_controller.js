import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    this.element.addEventListener('auth-tab:tabChanged', () => {
      this.clearFormErrors()
    })

    this.element.addEventListener('navigation--auth-popup:clear-errors', () => {
      this.clearFormErrors()
    })

    this.element.addEventListener('submit', (event) => {
      const form = event.target
      const validationController = this.application.getControllerForElementAndIdentifier(form, 'form-validation')

      if (validationController && !validationController.validateForm()) {
        event.preventDefault()
      }
    })
  }

  clearFormErrors() {
    const forms = this.element.querySelectorAll('[data-controller*="form-validation"]')

    forms.forEach(form => {
      const controller = this.application.getControllerForElementAndIdentifier(form, 'form-validation')
      if (controller) {
        controller.clearAllErrors()
      }
    })
  }
}
