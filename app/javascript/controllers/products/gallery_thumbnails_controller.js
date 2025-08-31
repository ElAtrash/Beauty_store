import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thumbnail", "mobileThumbnail", "container"]

  static values = {
    currentIndex: { type: Number, default: 0 }
  }

  static classes = ["selected", "loading", "error"]

  connect() {
    try {
      this.setupGalleryListeners()
      this.initializeThumbnails()
    } catch (error) {
      this.handleError('Failed to initialize thumbnails', error)
    }
  }

  disconnect() {
    if (this.galleryImageChangedHandler) {
      this.element.removeEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    }
    if (this.galleryVariantChangedHandler) {
      this.element.removeEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
    }
  }

  // Thumbnail selection
  selectThumbnail(event) {
    const index = parseInt(event.params.index, 10)
    const imageUrl = event.params.imageUrl

    if (isNaN(index) || index < 0) {
      console.warn('Invalid thumbnail index:', index)
      return
    }

    // Update local state
    this.currentIndexValue = index
    this.updateSelection(index)

    // Notify main gallery controller
    this.dispatch('selectImage', {
      detail: { index, imageUrl }
    })
  }

  // Listen to gallery events
  setupGalleryListeners() {
    this.galleryImageChangedHandler = this.handleGalleryImageChanged.bind(this)
    this.galleryVariantChangedHandler = this.handleGalleryVariantChanged.bind(this)

    // Listen to events from gallery controller
    document.addEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    document.addEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
  }

  handleGalleryImageChanged(event) {
    const { index } = event.detail
    this.currentIndexValue = index
    this.updateSelection(index)
    this.scrollToThumbnail(index)
  }

  handleGalleryVariantChanged(event) {
    const { images, currentIndex } = event.detail
    this.currentIndexValue = currentIndex
    this.rebuildThumbnails(images)
    this.updateSelection(currentIndex)
  }

  // Thumbnail state management
  initializeThumbnails() {
    this.updateSelection(this.currentIndexValue)
    this.setupAccessibility()
  }

  updateSelection(activeIndex) {
    // Update desktop thumbnails
    this.thumbnailTargets.forEach((thumbnail, index) => {
      this.setThumbnailState(thumbnail, index === activeIndex)
    })

    // Update mobile thumbnails
    this.mobileThumbnailTargets?.forEach((thumbnail, index) => {
      this.setThumbnailState(thumbnail, index === activeIndex)
    })
  }

  setThumbnailState(thumbnail, isSelected) {
    if (isSelected) {
      thumbnail.dataset.selected = 'true'
      thumbnail.setAttribute('aria-current', 'true')
      thumbnail.setAttribute('tabindex', '0')
    } else {
      thumbnail.dataset.selected = 'false'
      thumbnail.removeAttribute('aria-current')
      thumbnail.setAttribute('tabindex', '-1')
    }
  }

  // Scroll to ensure thumbnail is visible (using native browser scrolling)
  scrollToThumbnail(index) {
    const thumbnail = this.thumbnailTargets[index] || this.mobileThumbnailTargets?.[index]
    if (thumbnail) {
      thumbnail.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      })
    }
  }

  // Dynamic thumbnail rebuilding for variants
  rebuildThumbnails(images) {
    if (!images || images.length === 0) return

    // Clear existing thumbnails
    this.clearThumbnails()

    // Create new thumbnails
    images.forEach((image, index) => {
      this.createThumbnail(image, index)
    })
  }

  clearThumbnails() {
    // Find containers and clear them
    const desktopContainer = this.element.querySelector('[data-thumbnail-type="desktop"]')
    const mobileContainer = this.element.querySelector('[data-thumbnail-type="mobile"]')

    if (desktopContainer) {
      desktopContainer.innerHTML = ''
    }
    if (mobileContainer) {
      mobileContainer.innerHTML = ''
    }
  }

  createThumbnail(image, index) {
    // Create for desktop
    const desktopContainer = this.element.querySelector('[data-thumbnail-type="desktop"]')
    if (desktopContainer) {
      const desktopThumbnail = this.buildThumbnailElement(image, index, 'desktop')
      desktopContainer.appendChild(desktopThumbnail)
    }

    // Create for mobile
    const mobileContainer = this.element.querySelector('[data-thumbnail-type="mobile"]')
    if (mobileContainer) {
      const mobileThumbnail = this.buildThumbnailElement(image, index, 'mobile')
      mobileContainer.appendChild(mobileThumbnail)
    }
  }

  buildThumbnailElement(image, index, type) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = type === 'mobile'
      ? 'thumbnail-mobile'
      : 'thumbnail-desktop'

    // Stimulus attributes
    button.setAttribute('data-products--gallery-thumbnails-target', type === 'mobile' ? 'mobileThumbnail' : 'thumbnail')
    button.setAttribute('data-action', 'click->products--gallery-thumbnails#selectThumbnail')
    button.setAttribute('data-products--gallery-thumbnails-index-param', index.toString())
    button.setAttribute('data-products--gallery-thumbnails-image-url-param', image.large_url || image.url)
    button.setAttribute('data-selected', 'false')

    // Accessibility
    button.setAttribute('role', 'button')
    button.setAttribute('aria-label', `View image ${index + 1}`)
    button.setAttribute('tabindex', index === 0 ? '0' : '-1')

    const img = document.createElement('img')
    img.src = image.thumbnail_url || image.url
    img.alt = image.alt || `Product thumbnail ${index + 1}`
    img.className = 'thumbnail-image'
    img.loading = 'lazy'

    // Error handling
    img.onerror = () => {
      console.warn('Failed to load thumbnail:', image.thumbnail_url || image.url)
      // Could add placeholder logic here
    }

    button.appendChild(img)
    return button
  }

  // Accessibility
  setupAccessibility() {
    // Add role to container
    if (this.hasContainerTarget) {
      this.containerTarget.setAttribute('role', 'tablist')
      this.containerTarget.setAttribute('aria-label', 'Product image thumbnails')
    }

    // Set up initial focus management
    const firstThumbnail = this.thumbnailTargets[0] || this.mobileThumbnailTargets?.[0]
    if (firstThumbnail) {
      firstThumbnail.setAttribute('tabindex', '0')
    }
  }

  // Error handling
  handleError(message, error = null) {
    console.error(`Gallery Thumbnails Controller: ${message}`, error)

    if (this.hasErrorClass) {
      this.element.classList.add(this.errorClass)
    }

    this.dispatch('error', {
      detail: {
        message,
        error: error?.message || error,
        controller: 'gallery-thumbnails'
      }
    })
  }
}
