import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
  }

  openCart(event) {
    if (event) {
      event.preventDefault()
    }

    const cartPopup = document.querySelector('[data-controller~="cart-popup"]')
    if (cartPopup) {
      const controller = this.application.getControllerForElementAndIdentifier(cartPopup, 'cart-popup')
      if (controller) {
        controller.open()
      }
    }
  }
}
