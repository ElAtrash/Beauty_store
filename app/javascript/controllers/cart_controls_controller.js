import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "productActions",
    "addToCartButton", 
    "buttonText",
    "quantityControls",
    "quantityDisplay",
    "quantityInput",
    "decrementButton",
    "incrementButton"
  ]

  static values = {
    maxQuantity: { type: Number, default: 99 },
    initialState: { type: String, default: "initial" }
  }

  static classes = ["loading", "error"]

  connect() {
    this.cartState = this.initialStateValue || 'initial'
    this.currentQuantity = 1
    
    // Ensure the DOM reflects the initial state
    this.updateCartState()
    this.updateQuantityDisplay()
  }

  // Public API methods
  addToCart(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.cartState === 'initial') {
      this.currentQuantity = 1
      this.cartState = 'quantity'
      this.updateCartState()
      this.updateQuantityDisplay()
    }
  }

  incrementQuantity(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.cartState === 'quantity' && this.currentQuantity < this.maxQuantityValue) {
      this.currentQuantity++
      this.updateQuantityDisplay()
    }
  }

  decrementQuantity(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.cartState === 'quantity') {
      this.currentQuantity--
      if (this.currentQuantity <= 0) {
        this.currentQuantity = 1
        this.cartState = 'initial'
        this.updateCartState()
      } else {
        this.updateQuantityDisplay()
      }
    }
  }

  submitCart(event) {
    if (event) {
      event.preventDefault()
    }

    // Emit cart submission event with quantity data
    const cartData = {
      quantity: this.currentQuantity,
      state: this.cartState
    }

    this.dispatch("submit", { detail: cartData })
    this.showFeedback()
  }

  // Handle stock changes from variant selector
  handleStockChange(event) {
    const { available, quantity, variant } = event.detail
    this.updateButtonForStock(available)
  }

  // Update button text and action based on stock availability
  updateButtonForStock(available, buttonText = null) {
    if (!this.hasButtonTextTarget || !this.hasAddToCartButtonTarget) return

    if (available) {
      this.buttonTextTarget.textContent = buttonText || "ADD TO CART"
      this.addToCartButtonTarget.setAttribute('data-action', 'click->cart-controls#addToCart')
    } else {
      this.buttonTextTarget.textContent = buttonText || "NOTIFY ME" 
      this.addToCartButtonTarget.setAttribute('data-action', 'click->cart-controls#notifyOutOfStock')
    }
  }

  notifyOutOfStock(event) {
    if (event) {
      event.preventDefault()
    }

    // Emit out of stock notification event
    this.dispatch("notify-out-of-stock")
  }

  // Reset to initial state
  reset() {
    this.cartState = this.initialStateValue
    this.currentQuantity = 1
    this.updateCartState()
    this.updateQuantityDisplay()
  }

  // Private methods
  updateCartState() {
    if (this.hasProductActionsTarget) {
      this.productActionsTarget.dataset.cartState = this.cartState
    }
  }

  updateQuantityDisplay() {
    if (this.hasQuantityDisplayTarget) {
      this.quantityDisplayTarget.textContent = this.currentQuantity
    }
    if (this.hasQuantityInputTarget) {
      this.quantityInputTarget.value = this.currentQuantity
    }
  }

  showFeedback() {
    if (this.cartState === 'quantity' && this.hasQuantityControlsTarget && this.hasQuantityDisplayTarget) {
      // Use data attribute for feedback animation
      this.quantityControlsTarget.dataset.feedback = 'added'

      // Temporarily show "Added!" in the quantity display
      const originalQuantity = this.quantityDisplayTarget.textContent
      this.quantityDisplayTarget.textContent = "Added!"

      setTimeout(() => {
        delete this.quantityControlsTarget.dataset.feedback
        this.quantityDisplayTarget.textContent = originalQuantity
      }, 1500)
    }
  }

  // Error handling methods
  handleError(message, error = null) {
    console.error(`Cart Controls: ${message}`, error)
    
    // Add error state to element
    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    // Dispatch error event for external handling
    this.dispatch('error', { 
      detail: { 
        message, 
        error: error?.message || error,
        controller: 'cart-controls'
      } 
    })
  }

  clearErrors() {
    if (this.hasErrorClass) {
      this.element.classList.remove(this.errorClass)
    }
  }

  // Getters for external access
  get quantity() {
    return this.currentQuantity
  }

  get state() {
    return this.cartState
  }

  // Disconnect cleanup
  disconnect() {
    this.clearErrors()
  }
}