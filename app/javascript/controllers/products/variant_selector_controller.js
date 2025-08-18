import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "sizeOption",
    "colorOption",
    "quantityInput",
    "currentPrice",
    "originalPrice",
    "stockStatus",
    "addToCartButton",
    "skuDisplay",
    "buttonText",
    "quantityControls",
    "quantityDisplay",
    "decrementButton",
    "incrementButton"
  ]

  static values = {
    productId: Number,
    variants: { type: Array, default: [] }
  }

  connect() {
    this.cartState = 'initial' // 'initial' or 'quantity'
    this.currentQuantity = 1
    this.updateVariant()
  }

  updateVariant() {
    const selectedVariant = this.getSelectedVariant()

    if (selectedVariant) {
      this.updatePrice(selectedVariant)
      this.updateStock(selectedVariant)
      this.updateAddToCartButton(selectedVariant)
      this.updateSku(selectedVariant)

      this.emitVariantChangeEvent(selectedVariant)
    }
  }

  emitVariantChangeEvent(variant) {
    const event = new CustomEvent('variant:changed', {
      detail: {
        variantId: variant.id,
        variant: variant
      }
    })
    document.dispatchEvent(event)
  }

  addToCart() {
    if (this.cartState === 'initial') {
      this.currentQuantity = 1
      this.cartState = 'quantity'
      this.switchToQuantityMode()
      this.updateQuantityDisplay()
    }
  }

  incrementQuantity() {
    if (this.cartState === 'quantity') {
      const maxValue = 99 // Could be dynamic based on stock
      if (this.currentQuantity < maxValue) {
        this.currentQuantity++
        this.updateQuantityDisplay()
      }
    }
  }

  decrementQuantity() {
    if (this.cartState === 'quantity') {
      this.currentQuantity--
      if (this.currentQuantity <= 0) {
        this.currentQuantity = 1
        this.cartState = 'initial'
        this.switchToInitialMode()
      } else {
        this.updateQuantityDisplay()
      }
    }
  }

  switchToQuantityMode() {
    if (this.hasAddToCartButtonTarget && this.hasQuantityControlsTarget) {
      this.addToCartButtonTarget.classList.add('hidden')
      this.quantityControlsTarget.classList.remove('hidden')
      this.quantityControlsTarget.classList.add('flex')
    }
  }

  switchToInitialMode() {
    if (this.hasAddToCartButtonTarget && this.hasQuantityControlsTarget) {
      this.quantityControlsTarget.classList.add('hidden')
      this.quantityControlsTarget.classList.remove('flex')
      this.addToCartButtonTarget.classList.remove('hidden')
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

  getSelectedVariant() {
    const selectedSize = this.getSelectedSize()
    const selectedColor = this.getSelectedColor()

    // Try to find a real variant that matches the selection
    if (this.variantsValue && this.variantsValue.length > 0) {
      const matchingVariant = this.variantsValue.find(variant => {
        const sizeMatch = !selectedSize || variant.size === selectedSize
        const colorMatch = !selectedColor || variant.color === selectedColor
        return sizeMatch && colorMatch
      })

      if (matchingVariant) {
        return matchingVariant
      }

      return this.variantsValue[0]
    }

    return {
      id: 1,
      price: this.getCurrentPriceValue(),
      originalPrice: this.getOriginalPriceValue(),
      inStock: true,
      stockQuantity: 10,
      size: selectedSize,
      color: selectedColor,
      sku: this.generateMockSku(selectedSize, selectedColor)
    }
  }

  getSelectedSize() {
    if (!this.hasSizeOptionTarget) return null

    const selectedSizeInput = this.sizeOptionTargets.find(input => input.checked)
    if (!selectedSizeInput) return null

    // Return the size_key format: "value:unit:type"
    return selectedSizeInput.value
  }

  parseSizeKey(sizeKey) {
    if (!sizeKey) return null

    const parts = sizeKey.split(':')
    if (parts.length !== 3) return null

    return {
      value: parseFloat(parts[0]),
      unit: parts[1],
      type: parts[2]
    }
  }

  getSelectedColor() {
    if (!this.hasColorOptionTarget) return null

    const selectedColorInput = this.colorOptionTargets.find(input => input.checked)
    return selectedColorInput ? selectedColorInput.value : null
  }

  getCurrentPriceValue() {
    if (!this.hasCurrentPriceTarget) return 0

    // Extract numeric value from price display
    const priceText = this.currentPriceTarget.textContent.replace(/[^\d.,]/g, '')
    return parseFloat(priceText.replace(',', '.')) || 0
  }

  getOriginalPriceValue() {
    if (!this.hasOriginalPriceTarget) return null

    const priceText = this.originalPriceTarget.textContent.replace(/[^\d.,]/g, '')
    return parseFloat(priceText.replace(',', '.')) || null
  }

  generateMockSku(sizeKey, color) {
    const base = "ABH-BROW"
    let sizeCode = ""

    if (sizeKey) {
      const sizeInfo = this.parseSizeKey(sizeKey)
      if (sizeInfo) {
        // Create size code from structured data
        const value = sizeInfo.value.toString().replace('.', '')
        const unit = sizeInfo.unit.toUpperCase()
        sizeCode = `-${value}${unit}`
      }
    }

    const colorCode = color ? `-${color.replace(/\s+/g, '').toUpperCase()}` : ""
    return `${base}${colorCode}${sizeCode}`
  }

  updatePrice(variant) {
    // In a real implementation:
    // 1. Fetch variant data from server or local data
    // 2. Update price displays based on selected variant
    // 3. Show/hide discount information

    // For now, keep the existing prices as they are
    // since no variant-specific pricing implemented
  }

  updateStock(variant) {
    if (!this.hasStockStatusTarget) return

    // In a real implementation, check actual variant stock
    const stockStatus = variant.inStock ? "In stock" : "Out of stock"
    const stockClass = variant.inStock ? "text-green-600" : "text-red-600"

    this.stockStatusTarget.textContent = stockStatus
    this.stockStatusTarget.className = `text-sm ${stockClass}`
  }

  updateAddToCartButton(variant) {
    if (!this.hasAddToCartButtonTarget) return

    const button = this.addToCartButtonTarget

    if (variant.inStock) {
      button.disabled = false
      button.textContent = "Add to Cart"
      button.classList.remove("bg-gray-300", "cursor-not-allowed")
      button.classList.add("bg-black", "hover:bg-interactive")
    } else {
      button.disabled = true
      button.textContent = "Out of Stock"
      button.classList.remove("bg-black", "hover:bg-gray-800")
      button.classList.add("bg-gray-300", "cursor-not-allowed")
    }
  }

  updateSku(variant) {
    if (!this.hasSkuDisplayTarget) return

    // Update the SKU display in the product tabs
    this.skuDisplayTarget.textContent = variant.sku || "N/A"
  }

  // Form submission handling
  submitForm(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const selectedVariant = this.getSelectedVariant()

    // Add selected variant info to form data
    formData.append('variant_id', selectedVariant.id)
    formData.append('quantity', this.currentQuantity)

    // In a real implementation:
    // 1. Submit to add_to_cart endpoint
    // 2. Show success/error feedback
    // 3. Update cart counter

    // Adding to cart with variant, quantity, and form data

    // Show temporary success feedback
    this.showAddToCartFeedback()
  }

  showAddToCartFeedback() {
    // Only show feedback if in quantity mode
    if (this.cartState === 'quantity' && this.hasQuantityControlsTarget) {
      const originalBg = this.quantityControlsTarget.className

      this.quantityControlsTarget.classList.remove('bg-black')
      this.quantityControlsTarget.classList.add('bg-green-600')

      // Temporarily show "Added!" in the quantity display
      const originalQuantity = this.quantityDisplayTarget.textContent
      this.quantityDisplayTarget.textContent = "Added!"

      setTimeout(() => {
        this.quantityControlsTarget.className = originalBg
        this.quantityDisplayTarget.textContent = originalQuantity
      }, 1500)
    }
  }
}
