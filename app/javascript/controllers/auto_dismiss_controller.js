import { Controller } from "@hotwired/stimulus"
import { TimeoutMixin } from "mixins/timeout_mixin"

export default class extends Controller {
  static values = { delay: { type: Number, default: 3000 } }

  connect() {
    Object.assign(this, TimeoutMixin)

    this.initializeTimeout()
    this.setTimeoutWithCleanup(() => {
      this.dismiss()
    }, this.delayValue)
  }

  dismiss() {
    this.element.dataset.autoDismissActive = ""

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  disconnect() {
    this.cleanupOnDisconnect()
  }
}
