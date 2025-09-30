import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.modalController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "modal"
    )
  }

  open() {
    if (this.modalController) {
      this.modalController.open()
    }
  }

  close() {
    if (this.modalController) {
      this.modalController.close()
    }
  }
}
