import { Controller } from "@hotwired/stimulus"
import { EventHandlerMixin } from "mixins/event_handler_mixin"

export default class extends Controller {
  static targets = ["wishlistButton"]

  connect() {
    Object.assign(this, EventHandlerMixin)

    document.addEventListener('variant:changed', this.handleVariantChange.bind(this))
  }

  disconnect() {
    document.removeEventListener('variant:changed', this.handleVariantChange.bind(this))
  }

  toggleWishlist(event) {
    this.handleEventSafely(event, () => {
      this.dispatch("wishlist-toggle", {
        detail: {
          productId: this.data.get("productId"),
          action: "toggle"
        }
      })
    })
  }

  handleVariantChange(event) {
    const { variant } = event.detail

    if (variant && variant.product_id) {
      this.data.set("productId", variant.product_id)
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
