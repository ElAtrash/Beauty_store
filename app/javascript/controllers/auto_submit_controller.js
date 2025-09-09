import { Controller } from "@hotwired/stimulus"
import { TimeoutMixin } from "mixins/timeout_mixin"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 1000 }
  }

  connect() {
    Object.assign(this, TimeoutMixin)

    this.initializeTimeout()
  }

  disconnect() {
    this.cleanupOnDisconnect()
  }

  submit() {
    this.setTimeoutWithCleanup(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }
}
