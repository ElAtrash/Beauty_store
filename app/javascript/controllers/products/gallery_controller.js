import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "currentIndex"]

  static values = {
    currentIndex: { type: Number, default: 0 },
    totalImages: { type: Number, default: 1 }
  }

  static classes = ["loading", "error"]

  connect() {
    try {
      this.setupVariantListener()
      this.setupKeyboardNavigation()
      this.images = this.loadInitialImages()
      this.announceImageChange()
    } catch (error) {
      this.handleError('Failed to initialize gallery', error)
    }
  }

  disconnect() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
    if (this.variantChangeHandler) {
      document.removeEventListener('variant:changed', this.variantChangeHandler)
    }
  }

  // Main navigation actions
  previousImage(event) {
    event?.stopPropagation()
    this.navigateToImage(-1)
  }

  nextImage(event) {
    event?.stopPropagation()
    this.navigateToImage(1)
  }

  // Navigate by index (called from thumbnails controller)
  selectImage(event) {
    const index = parseInt(event.params.index, 10)
    if (this.isValidIndex(index)) {
      this.setCurrentImage(index)
    }
  }

  // Zoom functionality - delegates to modal controller
  zoomImage(event) {
    event?.stopPropagation()
    
    // Find the modal controller and open it
    const modalElement = document.querySelector('[data-controller*="products--gallery-modal"]')
    if (modalElement) {
      const modalController = this.application.getControllerForElementAndIdentifier(
        modalElement, 
        'products--gallery-modal'
      )
      
      if (modalController) {
        modalController.openModal(event)
      } else {
        // Fallback: dispatch event for modal to listen to
        this.dispatch('zoomRequested', {
          detail: {
            currentIndex: this.currentIndexValue,
            images: this.images
          }
        })
      }
    } else {
      console.warn('Gallery modal controller not found')
    }
  }

  // Core navigation logic
  navigateToImage(direction) {
    if (this.totalImagesValue <= 1) return

    let newIndex
    if (direction > 0) {
      newIndex = this.currentIndexValue < this.totalImagesValue - 1
        ? this.currentIndexValue + 1
        : 0
    } else {
      newIndex = this.currentIndexValue > 0
        ? this.currentIndexValue - 1
        : this.totalImagesValue - 1
    }

    this.setCurrentImage(newIndex)
  }

  setCurrentImage(index) {
    if (!this.isValidIndex(index)) return

    this.currentIndexValue = index
    this.updateMainImage()
    this.updateCounter()
    this.announceImageChange()

    // Notify other controllers (thumbnails, modal) of the change
    this.dispatch('imageChanged', {
      detail: {
        index,
        imageUrl: this.getCurrentImageUrl(),
        totalImages: this.totalImagesValue
      }
    })
  }

  // Variant handling
  setupVariantListener() {
    this.variantChangeHandler = this.handleVariantChange.bind(this)
    document.addEventListener('variant:changed', this.variantChangeHandler)
  }

  handleVariantChange(event) {
    const { images } = event.detail

    if (!images || images.length === 0) {
      return // Keep current gallery
    }

    this.images = images
    this.totalImagesValue = images.length
    this.currentIndexValue = 0
    this.updateMainImage()
    this.updateCounter()
    this.announceImageChange()

    // Notify other controllers of variant change
    this.dispatch('variantChanged', {
      detail: {
        images,
        currentIndex: 0,
        totalImages: images.length
      }
    })
  }

  // Keyboard navigation
  setupKeyboardNavigation() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  handleKeydown(event) {
    // Only handle arrow keys when not in input/textarea
    if (['INPUT', 'TEXTAREA'].includes(event.target.tagName)) return

    switch (event.key) {
      case 'ArrowLeft':
        this.previousImage()
        event.preventDefault()
        break
      case 'ArrowRight':
        this.nextImage()
        event.preventDefault()
        break
    }
  }

  // Image management
  loadInitialImages() {
    // Try to get images from script tag or fall back to current main image
    const scriptElement = document.getElementById('product-gallery-data')
    if (scriptElement) {
      try {
        const data = JSON.parse(scriptElement.textContent)
        this.totalImagesValue = data.images?.length || 1
        return data.images || []
      } catch (error) {
        console.warn('Failed to parse gallery data:', error)
      }
    }

    // Fallback to single image
    this.totalImagesValue = 1
    return this.hasMainImageTarget ? [{
      url: this.mainImageTarget.src,
      alt: this.mainImageTarget.alt || 'Product image'
    }] : []
  }

  getCurrentImageUrl() {
    const currentImage = this.images[this.currentIndexValue]
    return currentImage?.large_url || currentImage?.url || ''
  }

  updateMainImage() {
    if (!this.hasMainImageTarget) return

    const imageUrl = this.getCurrentImageUrl()
    if (!imageUrl) return

    // Smooth transition
    this.mainImageTarget.style.opacity = '0.8'

    setTimeout(() => {
      this.mainImageTarget.src = imageUrl
      const currentImage = this.images[this.currentIndexValue]
      this.mainImageTarget.alt = currentImage?.alt || `Product image ${this.currentIndexValue + 1}`
      this.mainImageTarget.style.opacity = '1'
    }, 100)
  }

  updateCounter() {
    if (this.hasCurrentIndexTarget) {
      this.currentIndexTarget.textContent = this.currentIndexValue + 1
    }
  }

  // Accessibility
  announceImageChange() {
    if (this.totalImagesValue <= 1) return

    let liveRegion = document.getElementById('gallery-announcements')
    if (!liveRegion) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'gallery-announcements'
      liveRegion.setAttribute('aria-live', 'polite')
      liveRegion.setAttribute('aria-atomic', 'true')
      liveRegion.className = 'sr-only'
      document.body.appendChild(liveRegion)
    }

    liveRegion.textContent = `Image ${this.currentIndexValue + 1} of ${this.totalImagesValue} selected`
  }

  // Utilities
  isValidIndex(index) {
    return index >= 0 && index < this.totalImagesValue && !isNaN(index)
  }

  // Error handling
  handleError(message, error = null) {
    console.error(`Gallery Controller: ${message}`, error)

    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    this.dispatch('error', {
      detail: {
        message,
        error: error?.message || error,
        controller: 'gallery'
      }
    })
  }

  clearErrors() {
    if (this.hasErrorClass) {
      this.element.classList.remove(this.errorClass)
    }
  }
}
