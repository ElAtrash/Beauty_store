import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "zoomedImage", "thumbnailContainer", "counter"]

  static values = {
    currentIndex: { type: Number, default: 0 }
  }

  static classes = ["loading", "error"]

  connect() {
    try {
      this.images = []
      this.setupEventListeners()
    } catch (error) {
      this.handleError('Failed to initialize modal', error)
    }
  }

  disconnect() {
    this.removeEventListeners()
    // Clean up body classes
    document.body.classList.remove('gallery-modal-open')
  }

  // Modal actions
  openModal(event) {
    try {
      if (!this.hasModalTarget) return

      this.modalTarget.hidden = false
      document.body.classList.add('gallery-modal-open')

      // Load current state from gallery
      this.syncWithGallery()

      // Focus management
      this.focusModal()
    } catch (error) {
      this.handleError('Failed to open modal', error)
    }
  }

  closeModal(event) {
    try {
      if (!this.hasModalTarget) return

      this.modalTarget.hidden = true
      document.body.classList.remove('gallery-modal-open')

      // Return focus to trigger element
      this.returnFocus(event)
    } catch (error) {
      this.handleError('Failed to close modal', error)
    }
  }

  // Modal navigation
  previousImage(event) {
    event?.stopPropagation()

    if (this.images.length <= 1) return

    const newIndex = this.currentIndexValue > 0
      ? this.currentIndexValue - 1
      : this.images.length - 1

    this.setCurrentImage(newIndex)
  }

  nextImage(event) {
    event?.stopPropagation()

    if (this.images.length <= 1) return

    const newIndex = this.currentIndexValue < this.images.length - 1
      ? this.currentIndexValue + 1
      : 0

    this.setCurrentImage(newIndex)
  }

  selectImage(event) {
    const index = parseInt(event.params.index, 10)
    if (this.isValidIndex(index)) {
      this.setCurrentImage(index)
    }
  }

  setCurrentImage(index) {
    if (!this.isValidIndex(index)) return

    this.currentIndexValue = index
    this.updateZoomedImage()
    this.updateThumbnailSelection()
    this.updateCounter()
  }

  // Event handling
  setupEventListeners() {
    this.keydownHandler = this.handleKeydown.bind(this)
    this.galleryImageChangedHandler = this.handleGalleryImageChanged.bind(this)
    this.galleryVariantChangedHandler = this.handleGalleryVariantChanged.bind(this)

    document.addEventListener('keydown', this.keydownHandler)
    document.addEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    document.addEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
  }

  removeEventListeners() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
    if (this.galleryImageChangedHandler) {
      document.removeEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    }
    if (this.galleryVariantChangedHandler) {
      document.removeEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
    }
  }

  handleKeydown(event) {
    // Only handle keys when modal is open
    if (this.hasModalTarget && this.modalTarget.hidden) return

    switch (event.key) {
      case 'Escape':
        this.closeModal()
        event.preventDefault()
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

  handleGalleryImageChanged(event) {
    // Sync modal state with gallery when gallery changes externally
    if (this.hasModalTarget && !this.modalTarget.hidden) {
      const { index } = event.detail
      this.currentIndexValue = index
      this.updateZoomedImage()
      this.updateThumbnailSelection()
      this.updateCounter()
    }
  }

  handleGalleryVariantChanged(event) {
    const { images, currentIndex } = event.detail
    this.images = images || []
    this.currentIndexValue = currentIndex

    // If modal is open, update it
    if (this.hasModalTarget && !this.modalTarget.hidden) {
      this.updateZoomedImage()
      this.rebuildModalThumbnails()
      this.updateCounter()
    }
  }

  // Image management
  syncWithGallery() {
    // Get current state from gallery data
    const scriptElement = document.getElementById('product-gallery-data')
    if (scriptElement) {
      try {
        const data = JSON.parse(scriptElement.textContent)
        this.images = data.images || []
      } catch (error) {
        console.warn('Failed to parse gallery data for modal:', error)
      }
    }

    // Get current index from gallery controller if available
    const galleryController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="products--gallery"]'),
      'products--gallery'
    )

    if (galleryController) {
      this.currentIndexValue = galleryController.currentIndexValue || 0
    }

    this.updateZoomedImage()
    this.updateCounter()
    this.rebuildModalThumbnails()
  }

  updateZoomedImage() {
    if (!this.hasZoomedImageTarget || !this.images.length) return

    const currentImage = this.images[this.currentIndexValue]
    if (!currentImage) return

    const imageUrl = currentImage.large_url || currentImage.url
    if (!imageUrl) return

    // Show loading state
    if (this.hasLoadingClass) {
      this.element.classList.add(this.loadingClass)
    }

    // Create new image to preload
    const img = new Image()
    img.onload = () => {
      this.zoomedImageTarget.src = imageUrl
      this.zoomedImageTarget.alt = currentImage.alt || `Product image ${this.currentIndexValue + 1}`

      if (this.hasLoadingClass) {
        this.element.classList.remove(this.loadingClass)
      }
    }

    img.onerror = () => {
      console.error('Failed to load zoomed image:', imageUrl)
      if (this.hasLoadingClass) {
        this.element.classList.remove(this.loadingClass)
      }
    }

    img.src = imageUrl
  }

  updateThumbnailSelection() {
    const thumbnails = this.element.querySelectorAll('[data-modal-thumbnail]')
    thumbnails.forEach((thumbnail, index) => {
      thumbnail.dataset.selected = (index === this.currentIndexValue).toString()
    })
  }

  updateCounter() {
    if (this.hasCounterTarget && this.images.length > 0) {
      this.counterTarget.textContent = `${this.currentIndexValue + 1} / ${this.images.length}`
    }
  }

  rebuildModalThumbnails() {
    if (!this.hasThumbnailContainerTarget) return

    // Clear existing thumbnails
    this.thumbnailContainerTarget.innerHTML = ''

    // Create new thumbnails
    this.images.forEach((image, index) => {
      const thumbnail = this.createModalThumbnail(image, index)
      this.thumbnailContainerTarget.appendChild(thumbnail)
    })
  }

  createModalThumbnail(image, index) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'modal-thumbnail'
    button.setAttribute('data-action', 'click->products--gallery-modal#selectImage')
    button.setAttribute('data-products--gallery-modal-index-param', index.toString())
    button.setAttribute('data-modal-thumbnail', 'true')
    button.setAttribute('data-selected', 'false')

    const img = document.createElement('img')
    img.src = image.thumbnail_url || image.url
    img.alt = `Thumbnail ${index + 1}`
    img.className = 'modal-thumbnail-image'
    img.loading = 'lazy'

    button.appendChild(img)
    return button
  }

  // Focus management
  focusModal() {
    // Focus the modal container for screen readers
    if (this.hasModalTarget) {
      this.modalTarget.focus()
    }
  }

  returnFocus(event) {
    // Return focus to the element that opened the modal
    if (event && event.target) {
      const opener = document.querySelector('[data-action*="openModal"]')
      if (opener) {
        opener.focus()
      }
    }
  }

  // Utilities
  isValidIndex(index) {
    return index >= 0 && index < this.images.length && !isNaN(index)
  }

  // Error handling
  handleError(message, error = null) {
    console.error(`Gallery Modal Controller: ${message}`, error)

    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    this.dispatch('error', {
      detail: {
        message,
        error: error?.message || error,
        controller: 'gallery-modal'
      }
    })
  }
}
