import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "currentIndex", "zoomModal", "zoomImageCard", "modalThumbnail"]

  static values = {
    currentIndex: { type: Number, default: 0 },
    totalImages: { type: Number, default: 1 }
  }

  static classes = []

  connect() {
    this.setupVariantListener()
    this.setupKeyboardNavigation()
    this.images = this.loadInitialImages()
    this.announceImageChange()

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
    document.body.classList.remove('gallery-modal-open')
  }

  previousImage(event) {
    event?.stopPropagation()
    this.navigateToImage(-1)
  }

  nextImage(event) {
    event?.stopPropagation()
    this.navigateToImage(1)
  }

  selectImage(event) {
    const index = parseInt(event.params.index, 10)
    if (this.isValidIndex(index)) {
      this.setCurrentImage(index)
    }
  }

  zoomImage(event) {
    event?.stopPropagation()

    if (this.hasZoomModalTarget) {
      this.zoomModalTarget.classList.remove('hidden')
      document.body.classList.add('gallery-modal-open')

      this.scrollToCurrentImageInModal()
      this.focusModal()
    }
  }

  closeZoom(event) {
    event?.stopPropagation()

    if (this.hasZoomModalTarget) {
      this.zoomModalTarget.classList.add('hidden')
      document.body.classList.remove('gallery-modal-open')
      this.returnFocus(event)
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
    this.updateModalThumbnails()
    
    // If modal is open, scroll to the corresponding image
    if (this.hasZoomModalTarget && !this.zoomModalTarget.classList.contains('hidden')) {
      this.scrollToCurrentImageInModal()
    }
    
    this.announceImageChange()

    this.dispatch('imageChanged', {
      detail: {
        index,
        imageUrl: this.getCurrentImageUrl(),
        totalImages: this.totalImagesValue
      },
      prefix: 'gallery'
    })
  }

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
      return
    }

    this.images = images
    this.totalImagesValue = images.length
    this.currentIndexValue = 0
    this.updateMainImage()
    this.updateCounter()
    this.announceImageChange()

    this.dispatch('variantChanged', {
      detail: {
        images,
        currentIndex: 0,
        totalImages: images.length
      },
      prefix: 'gallery'
    })
  }

  setupKeyboardNavigation() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  handleKeydown(event) {
    if (['INPUT', 'TEXTAREA'].includes(event.target.tagName)) return

    switch (event.key) {
      case 'Escape':
        if (this.hasZoomModalTarget && !this.zoomModalTarget.classList.contains('hidden')) {
          this.closeZoom()
          event.preventDefault()
        }
        break
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

  loadInitialImages() {
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

  updateModalThumbnails() {
    this.modalThumbnailTargets.forEach((thumbnail, index) => {
      if (index === this.currentIndexValue) {
        thumbnail.dataset.selected = 'true'
        thumbnail.setAttribute('aria-current', 'true')
      } else {
        thumbnail.dataset.selected = 'false'
        thumbnail.removeAttribute('aria-current')
      }
    })
  }

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

  isValidIndex(index) {
    return index >= 0 && index < this.totalImagesValue && !isNaN(index)
  }

  handleError(message, error = null) {
    console.error(`Gallery Controller: ${message}`, error)
  }

  focusModal() {
    if (this.hasZoomModalTarget) {
      this.zoomModalTarget.focus()
    }
  }

  returnFocus(event) {
    if (event && event.target) {
      const opener = document.querySelector('[data-action*="zoomImage"]')
      if (opener) {
        opener.focus()
      }
    }
  }
}
