import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deliverySummary", "deliverySchedule", "modals"]

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  connect() {
    const checkedRadio = this.element.querySelector('input[name*="delivery_method"]:checked')
    const method = checkedRadio ? checkedRadio.value : 'pickup'
    this.updateDeliverySchedule(method)
    this.notifyValidationController(method)
  }

  handleDeliveryMethodChange(event) {
    const selectedMethod = event.target.value
    this.notifyValidationController(selectedMethod)

    this.persistDeliveryMethod(selectedMethod).then(() => {
      this.updateDeliverySchedule(selectedMethod)
      this.updateDeliverySummary(selectedMethod)
    })

    if (selectedMethod === 'courier' && !this.isAddressFilled()) {
      this.openAddressModal()
    }
  }

  updateDeliverySummary(method) {
    this.turboStreamFetch('/checkout/delivery_summary', method)
  }

  updateDeliverySchedule(method) {
    if (!this.hasDeliveryScheduleTarget) return

    this.turboStreamFetch('/checkout/delivery_schedule', method, {
      onError: () => this.fallbackDeliveryScheduleUpdate(method)
    })
  }

  turboStreamFetch(url, deliveryMethod, options = {}) {
    const formData = new FormData()
    formData.append('delivery_method', deliveryMethod)

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      if (html.includes('turbo-stream')) {
        Turbo.renderStreamMessage(html)
      }
    })
    .catch(error => {
      console.error(`Error fetching ${url}:`, error)
      if (options.onError) options.onError(error)
    })
  }

  fallbackDeliveryScheduleUpdate(method) {
    // Simple fallback for when Turbo Stream fails
    const deliveryScheduleElement = this.deliveryScheduleTarget
    if (method === 'pickup') {
      const existingPickup = deliveryScheduleElement.querySelector('.delivery-card--pickup')
      if (existingPickup) {
        existingPickup.style.display = 'block'
      }
    }
  }

  isAddressFilled() {
    const addressLine1 = this.element.querySelector('[name*="address_line_1"]')
    return addressLine1 && addressLine1.value.trim() !== ""
  }

  openAddressModal() {
    const modal = document.querySelector('#address-modal[data-controller~="modal"]')
    if (modal) {
      const controller = this.application.getControllerForElementAndIdentifier(modal, "modal")
      if (controller) {
        controller.open()
      }
    }
  }

  persistDeliveryMethod(method) {
    const formData = new FormData()
    formData.append('checkout_form[delivery_method]', method)

    return fetch('/checkout', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Accept': 'application/json'
      },
      body: formData
    }).catch(error => {
      console.error('Error persisting delivery method:', error)
      return Promise.resolve()
    })
  }

  notifyValidationController(method) {
    const validationController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "form-validation"
    )

    if (validationController && validationController.updateDeliveryMethod) {
      validationController.updateDeliveryMethod(method)
    }
  }
}
