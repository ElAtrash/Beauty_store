import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["modal"]

  // TODO: Action methods for header buttons
  openSearch(event) {
    event.preventDefault()
  }

  openFavorites(event) {
    event.preventDefault()
  }

  openCart(event) {
    event.preventDefault()

    const cartModal = document.querySelector('#cart[data-controller~="modal"]')
    if (cartModal && cartModal.modal) {
      cartModal.modal.open()
    } else if (cartModal) {
      const application = this.application
      const controller = application.getControllerForElementAndIdentifier(cartModal, 'modal')
      if (controller) {
        controller.open()
      }
    } else {
      console.warn('Cart modal element not found')
    }
  }

  selectLocation(event) {
    event.preventDefault()
  }
}
