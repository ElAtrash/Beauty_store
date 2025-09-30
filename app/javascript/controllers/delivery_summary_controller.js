import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openAddressModal() {
    const modal = document.querySelector('#address-modal')
    if (modal) {
      const controller = this.application.getControllerForElementAndIdentifier(modal, "modal")
      if (controller) {
        controller.open()
      }
    }
  }

  openPickupModal() {
    const modal = document.querySelector('#pickup-details-modal')
    if (modal) {
      const controller = this.application.getControllerForElementAndIdentifier(modal, "modal")
      if (controller) {
        controller.open()
      }
    }
  }
}
