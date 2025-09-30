import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openProfile(event) {
    if (event) {
      event.preventDefault()
    }

    const authModal = document.querySelector('#auth[data-controller~="modal"]')
    if (authModal) {
      const controller = this.application.getControllerForElementAndIdentifier(authModal, 'modal')
      if (controller) {
        controller.open()
        return
      }
    }
  }
}
