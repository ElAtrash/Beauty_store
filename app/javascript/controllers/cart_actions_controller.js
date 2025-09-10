import { Controller } from "@hotwired/stimulus"
import { EventHandlerMixin } from "mixins/event_handler_mixin"

export default class extends Controller {
  static targets = ["wishlistButton"]
  static values = { productId: Number }
  static actions = [
    "variant:changed@document->handleVariantChange",
    "variant:stock-changed@document->handleStockChange"
  ]

  connect() {
    Object.assign(this, EventHandlerMixin)
    this.setupEventListeners()
  }

  disconnect() {
    this.teardownEventListeners()
  }

  setupEventListeners() {
    this.constructor.actions.forEach(action => {
      const [eventName, handler] = action.split('->')
      const method = handler.split('#')[1] || handler

      if (eventName.includes('@document')) {
        const event = eventName.replace('@document', '')
        this[`_${method}Handler`] = this[method].bind(this)
        document.addEventListener(event, this[`_${method}Handler`])
      }
    })
  }

  teardownEventListeners() {
    this.constructor.actions.forEach(action => {
      const [eventName, handler] = action.split('->')
      const method = handler.split('#')[1] || handler

      if (eventName.includes('@document')) {
        const event = eventName.replace('@document', '')
        if (this[`_${method}Handler`]) {
          document.removeEventListener(event, this[`_${method}Handler`])
          delete this[`_${method}Handler`]
        }
      }
    })
  }

  toggleWishlist(event) {
    this.handleEventSafely(event, () => {
      this.dispatch("wishlist-toggle", {
        detail: {
          productId: this.productIdValue,
          action: "toggle"
        }
      })
    })
  }

  handleVariantChange(event) {
    const { variant } = event.detail

    if (variant && variant.product_id) {
      this.productIdValue = variant.product_id
    }
  }

  handleStockChange(event) {
    const { available } = event.detail

    if (!available) {
      this.dispatch("stock-unavailable", {
        detail: { message: "This item is currently out of stock" }
      })
    }
  }
}
