import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "currentIndex", "zoomModal", "zoomImageCard", "thumbnailContainer", "upArrow", "downArrow"]

  static values = {
    currentIndex: { type: Number, default: 0 },
    totalImages: { type: Number, default: 1 },
    thumbnailScrollOffset: { type: Number, default: 0 }
  }

  static classes = ["loading", "error"]

  connect() {
    try {
      this.setupVariantListener()
      this.setupKeyboardNavigation()
      this.images = this.loadInitialImages()
      this.announceImageChange()
      
      // Notify thumbnails controller of initial images (with slight delay to ensure other controllers are ready)
      if (this.images && this.images.length > 0) {
        setTimeout(() => {
          this.dispatch('variantChanged', {
            detail: {
              images: this.images,
              currentIndex: this.currentIndexValue,
              totalImages: this.totalImagesValue
            },
            prefix: 'gallery'
          })
        }, 100)
      }
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
    if (this.thumbnailSelectHandler) {
      document.removeEventListener('gallery:selectImage', this.thumbnailSelectHandler)
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

  // Zoom functionality - opens modal directly
  zoomImage(event) {
    event?.stopPropagation()
    
    if (this.hasZoomModalTarget) {
      // Remove hidden class instead of setting hidden attribute
      this.zoomModalTarget.classList.remove('hidden')
      document.body.classList.add('gallery-modal-open')
      
      // Scroll to current image in modal
      this.scrollToCurrentImageInModal()
    }
  }

  closeZoom(event) {
    event?.stopPropagation()
    
    if (this.hasZoomModalTarget) {
      // Add hidden class instead of setting hidden attribute
      this.zoomModalTarget.classList.add('hidden')
      document.body.classList.remove('gallery-modal-open')
    }
  }

  stopPropagation(event) {
    event?.stopPropagation()
  }

  scrollToCurrentImageInModal() {
    const currentImageCard = document.getElementById(`zoom-image-${this.currentIndexValue}`)
    if (currentImageCard) {
      currentImageCard.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  // Thumbnail scrolling methods (for modal context)
  scrollThumbnailsUp(event) {
    event?.preventDefault()
    this.scrollThumbnails(-1)
  }

  scrollThumbnailsDown(event) {
    event?.preventDefault()
    this.scrollThumbnails(1)
  }

  scrollThumbnails(direction) {
    if (!this.hasThumbnailContainerTarget) return

    const container = this.thumbnailContainerTarget
    const thumbnailHeight = 76 // 68px thumbnail + 8px spacing
    const newOffset = this.thumbnailScrollOffsetValue + (direction * thumbnailHeight)
    
    // Calculate bounds
    const maxOffset = Math.max(0, (this.totalImagesValue - 4) * thumbnailHeight)
    const clampedOffset = Math.max(0, Math.min(newOffset, maxOffset))

    // Apply transform
    this.thumbnailScrollOffsetValue = clampedOffset
    const innerContainer = container.children[0]
    if (innerContainer) {
      innerContainer.style.transform = `translateY(-${clampedOffset}px)`
      innerContainer.style.transition = 'transform 0.3s ease'
    }

    // Update arrow visibility
    this.updateArrowStates()
  }

  updateArrowStates() {
    if (!this.hasThumbnailContainerTarget) return

    const maxOffset = Math.max(0, (this.totalImagesValue - 4) * 76)
    
    // Update up arrow
    if (this.hasUpArrowTarget) {
      const upOpacity = this.thumbnailScrollOffsetValue > 0 ? '1' : '0.3'
      this.upArrowTarget.style.opacity = upOpacity
      this.upArrowTarget.disabled = this.thumbnailScrollOffsetValue <= 0
    }

    // Update down arrow
    if (this.hasDownArrowTarget) {
      const downOpacity = this.thumbnailScrollOffsetValue < maxOffset ? '1' : '0.3'
      this.downArrowTarget.style.opacity = downOpacity
      this.downArrowTarget.disabled = this.thumbnailScrollOffsetValue >= maxOffset
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
      },
      prefix: 'gallery'
    })
  }

  // Variant handling
  setupVariantListener() {
    this.variantChangeHandler = this.handleVariantChange.bind(this)
    this.thumbnailSelectHandler = this.handleThumbnailSelect.bind(this)
    
    document.addEventListener('variant:changed', this.variantChangeHandler)
    document.addEventListener('gallery:selectImage', this.thumbnailSelectHandler)
  }

  handleThumbnailSelect(event) {
    const { index } = event.detail
    if (this.isValidIndex(index)) {
      this.setCurrentImage(index)
    }
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
      },
      prefix: 'gallery'
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
        // Failed to parse gallery data, continue with fallback
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
