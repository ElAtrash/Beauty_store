import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "zoomedImage", "counter"]

  static values = {
    currentIndex: { type: Number, default: 0 }
  }

  static classes = []

  connect() {
    this.images = []
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
    document.body.classList.remove('gallery-modal-open')
  }

  setupEventListeners() {
    this.galleryImageChangedHandler = this.handleGalleryImageChanged.bind(this)
    this.galleryVariantChangedHandler = this.handleGalleryVariantChanged.bind(this)

    document.addEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    document.addEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
  }

  removeEventListeners() {
    if (this.galleryImageChangedHandler) {
      document.removeEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    }
    if (this.galleryVariantChangedHandler) {
      document.removeEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
    }
  }

  handleGalleryImageChanged(event) {
    if (this.hasModalTarget && !this.modalTarget.hidden) {
      const { index } = event.detail
      this.currentIndexValue = index
      this.updateZoomedImage()
      this.updateCounter()
    }
  }

  handleGalleryVariantChanged(event) {
    const { images, currentIndex } = event.detail
    this.images = images || []
    this.currentIndexValue = currentIndex

    if (this.hasModalTarget && !this.modalTarget.hidden) {
      this.updateZoomedImage()
      this.updateCounter()
    }
  }

  updateZoomedImage() {
    if (!this.hasZoomedImageTarget || !this.images.length) return

    const currentImage = this.images[this.currentIndexValue]
    if (!currentImage) return

    const imageUrl = currentImage.large_url || currentImage.url
    if (!imageUrl) return

    const img = new Image()
    img.onload = () => {
      this.zoomedImageTarget.src = imageUrl
      this.zoomedImageTarget.alt = currentImage.alt || `Product image ${this.currentIndexValue + 1}`
    }

    img.onerror = () => {
      console.error('Failed to load zoomed image:', imageUrl)
    }

    img.src = imageUrl
  }

  updateCounter() {
    if (this.hasCounterTarget && this.images.length > 0) {
      this.counterTarget.textContent = `${this.currentIndexValue + 1} / ${this.images.length}`
    }
  }

  isValidIndex(index) {
    return index >= 0 && index < this.images.length && !isNaN(index)
  }

  handleError(message, error = null) {
    console.error(`Gallery Modal Controller: ${message}`, error)
  }
}
