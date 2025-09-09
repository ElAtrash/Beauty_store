import { Controller } from "@hotwired/stimulus"
import { TimeoutMixin } from "mixins/timeout_mixin"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 1000 }
  }

  connect() {
    TimeoutMixin.initializeTimeout.call(this)
  }

  disconnect() {
    TimeoutMixin.cleanupOnDisconnect.call(this)
  }

  submit() {
    TimeoutMixin.setTimeoutWithCleanup.call(this, () => {
      this.element.requestSubmit()
    }, this.delayValue)
  }
}
