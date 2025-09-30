import { Controller } from "@hotwired/stimulus"

/**
 * Handles order-related actions: copy, share, and print functionality
 * Connects to data-controller="order-actions"
 */
export default class extends Controller {
  static targets = ["copyButton", "shareButton"]
  static values = {
    orderNumber: String,
    shareUrl: String,
    shareTitle: String,
    shareText: String,
    reorderUrl: String
  }

  connect() {
    if (!this.hasClipboard) { this.hideCopyButtons() }
    if (!this.hasNativeShare) { this.updateShareButtonsForFallback() }
  }

  // Check if the browser supports:
  get hasClipboard() { return !!navigator.clipboard }
  get hasNativeShare() { return !!navigator.share }

  canShare(shareData) {
    return this.hasNativeShare && navigator.canShare && navigator.canShare(shareData)
  }

  get defaultShareTitle() { return "My Beauty Store Order" }
  get defaultShareText() { return "Check out my order from Beauty Store!" }

  buildShareData() {
    return {
      title: this.shareTitleValue || this.defaultShareTitle,
      text: this.shareTextValue || this.defaultShareText,
      url: this.shareUrlValue || window.location.href
    }
  }

  async copyOrderNumber(event) {
    event.preventDefault()
    await this.copyToClipboard(this.orderNumberValue, event.currentTarget)
  }

  async shareOrder(event) {
    event.preventDefault()

    const shareData = this.buildShareData()

    if (this.canShare(shareData)) {
      try {
        await navigator.share(shareData)
      } catch (error) {
        // User cancelled or error occurred, fallback to clipboard
        await this.copyToClipboard(shareData.url, event.currentTarget)
      }
    } else {
      await this.copyToClipboard(shareData.url, event.currentTarget)
    }
  }

  printOrder(event) {
    event.preventDefault()
    window.print()
  }

  async reorderOrder(event) {
    event.preventDefault()

    if (!this.reorderUrlValue) {
      console.error('Reorder URL not provided')
      return
    }

    // Disable button during request
    const button = event.currentTarget
    const originalText = button.innerHTML
    const isDisabled = button.disabled

    try {
      button.disabled = true
      button.innerHTML = `
        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
        Adding to cart...
      `

      const response = await fetch(this.reorderUrlValue, {
        method: 'POST',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        credentials: 'same-origin'
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        // The cart modal will be opened by the turbo stream response
      } else {
        throw new Error(`Server returned ${response.status}`)
      }

    } catch (error) {
      console.error('Reorder failed:', error)
      this.showMessage('Failed to reorder items. Please try again.', 'error')
    } finally {
      button.disabled = isDisabled
      button.innerHTML = originalText
    }
  }

  async copyToClipboard(text, button = null) {
    if (!this.hasClipboard) {
      this.showMessage("Clipboard not supported", "info")
      return false
    }

    try {
      await navigator.clipboard.writeText(text)
      if (button) {
        this.showCopySuccess(button)
      }
      return true
    } catch (error) {
      this.showMessage("Failed to copy", "error")
      return false
    }
  }

  hideCopyButtons() {
    this.copyButtonTargets.forEach(button => {
      button.classList.add("hidden")
    })
  }

  updateShareButtonsForFallback() {
    this.shareButtonTargets.forEach(button => {
      const textElement = button.querySelector("span:not(.icon)")
      if (textElement && textElement.textContent.includes("Share")) {
        textElement.textContent = textElement.textContent.replace("Share", "Copy Link")
      }
    })
  }

  showCopySuccess(button) {
    const iconElement = button.querySelector('svg')
    if (!iconElement) return

    // Prevent multiple clicks during animation
    if (button.dataset.copying === 'true') return
    button.dataset.copying = 'true'

    // Store original icon state
    const originalHTML = iconElement.outerHTML

    button.style.transition = 'all 0.1s ease-in-out'
    button.style.transform = 'scale(0.95)'
    setTimeout(() => {
      button.style.transform = 'scale(1)'
    }, 100)

    // Replace with checkmark
    iconElement.innerHTML = '<path d="m4.5 12.75 6 6 9-13.5" />'
    iconElement.setAttribute('stroke-width', '2')

    // Restore original icon after 1.5 seconds
    setTimeout(() => {
      const currentIcon = button.querySelector('svg')
      if (currentIcon && button.dataset.copying === 'true') {
        // Replace with original HTML
        currentIcon.outerHTML = originalHTML

        // Clean up button state
        button.style.transition = ''
        button.style.transform = ''
        button.dataset.copying = 'false'
      }
    }, 1500)
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  openCartModal() {
    const cartModal = document.querySelector('#cart[data-controller~="modal"]')
    if (cartModal && cartModal.modal) {
      cartModal.modal.open()
    } else if (cartModal) {
      const application = this.application
      const controller = application.getControllerForElementAndIdentifier(cartModal, 'modal')
      if (controller) {
        controller.open()
      }
    } else {
      console.warn('Cart modal element not found')
    }
  }

  showMessage(message, type = "info") {
    const toast = document.createElement("div")
    toast.className = `fixed top-4 right-4 px-4 py-2 rounded shadow-lg z-50 text-white ${this.getMessageClasses(type)}`
    toast.textContent = message
    toast.style.transition = "all 0.3s ease"

    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.opacity = "0"
      toast.style.transform = "translateY(-20px)"
      setTimeout(() => {
        if (document.body.contains(toast)) {
          document.body.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }

  getMessageClasses(type) {
    switch (type) {
      case "success":
        return "bg-green-500"
      case "error":
        return "bg-red-500"
      case "info":
      default:
        return "bg-blue-500"
    }
  }
}
