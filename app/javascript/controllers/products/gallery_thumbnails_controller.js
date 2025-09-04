import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thumbnail", "mobileThumbnail", "container", "thumbnailContainer", "upArrow", "downArrow"]

  static values = {
    currentIndex: { type: Number, default: 0 },
    thumbnailScrollOffset: { type: Number, default: 0 }
  }

  static classes = ["selected", "loading", "error"]

  connect() {
    try {
      this.setupGalleryListeners()
      this.initializeThumbnails()
      
      // Fallback: wait a bit then try to get data from gallery if we haven't received variant event
      setTimeout(() => {
        if (this.thumbnailTargets.length === 0) {
          this.syncWithGallery()
        }
      }, 200)
    } catch (error) {
      this.handleError('Failed to initialize thumbnails', error)
    }
  }

  syncWithGallery() {
    // Try to get gallery data directly
    const scriptElement = document.getElementById('product-gallery-data')
    if (scriptElement) {
      try {
        const data = JSON.parse(scriptElement.textContent)
        if (data.images && data.images.length > 0) {
          this.handleGalleryVariantChanged({
            detail: {
              images: data.images,
              currentIndex: 0,
              totalImages: data.images.length
            }
          })
        }
      } catch (error) {
        // Failed to parse gallery data, continue without thumbnails
      }
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
      return
    }

    // Update local state
    this.currentIndexValue = index
    this.updateSelection(index)

    // Notify main gallery controller
    this.dispatch('selectImage', {
      detail: { index, imageUrl },
      prefix: 'gallery'
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
    this.updateArrowStates()
  }

  // Thumbnail state management
  initializeThumbnails() {
    this.updateSelection(this.currentIndexValue)
    this.setupAccessibility()
    this.updateArrowStates()
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

  // Arrow-controlled scrolling for desktop thumbnails
  scrollThumbnailsUp(event) {
    event?.preventDefault()
    this.scrollThumbnails(-1)
  }

  scrollThumbnailsDown(event) {
    event?.preventDefault()
    this.scrollThumbnails(1)
  }

  scrollThumbnails(direction) {
    if (!this.hasThumbnailContainerTarget) {
      return
    }

    const container = this.thumbnailContainerTarget
    const thumbnailHeight = 76 // 68px thumbnail + 8px spacing
    const visibleCount = 4 // Number of thumbnails visible at once
    const scrollAmount = visibleCount * thumbnailHeight // Scroll by full set
    
    const newOffset = this.thumbnailScrollOffsetValue + (direction * scrollAmount)
    
    // Get total number of images from gallery controller
    const totalImages = this.getTotalImagesCount()
    
    // Calculate bounds - allow scrolling until last set is visible
    const maxOffset = Math.max(0, (totalImages - visibleCount) * thumbnailHeight)
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

    const totalImages = this.getTotalImagesCount()
    const visibleCount = 4
    const maxOffset = Math.max(0, (totalImages - visibleCount) * 76)
    
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

  getTotalImagesCount() {
    // Try to get from thumbnail count first
    const thumbnailCount = this.thumbnailTargets.length
    if (thumbnailCount > 0) return thumbnailCount
    
    // Fallback to mobile thumbnails
    const mobileThumbnailCount = this.mobileThumbnailTargets?.length || 0
    if (mobileThumbnailCount > 0) return mobileThumbnailCount
    
    // Default fallback
    return 1
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
      // Could add placeholder logic here if needed
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
