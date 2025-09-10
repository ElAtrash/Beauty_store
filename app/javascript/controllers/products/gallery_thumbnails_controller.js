import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thumbnail", "container", "thumbnailContainer", "upArrow", "downArrow"]

  static values = {
    currentIndex: { type: Number, default: 0 },
    thumbnailScrollOffset: { type: Number, default: 0 }
  }

  static classes = ["selected"]

  connect() {
    this.setupGalleryListeners()
    this.initializeThumbnails()

    setTimeout(() => {
      if (this.thumbnailTargets.length === 0) {
        this.syncWithGallery()
      }
    }, 200)
  }

  syncWithGallery() {
    const scriptElement = document.getElementById('product-gallery-data')
    if (scriptElement) {
      try {
        const data = JSON.parse(scriptElement.textContent)
        if (data.images && data.images.length > 0) {
          this.handleGalleryVariantChanged({
            detail: {
              currentIndex: 0,
              totalImages: data.images.length
            }
          })
        }
      } catch (error) {
      }
    }
  }

  disconnect() {
    if (this.galleryImageChangedHandler) {
      document.removeEventListener('gallery:imageChanged', this.galleryImageChangedHandler)
    }
    if (this.galleryVariantChangedHandler) {
      document.removeEventListener('gallery:variantChanged', this.galleryVariantChangedHandler)
    }
  }

  selectThumbnail(event) {
    const index = parseInt(event.params.index, 10)
    const imageUrl = event.params.imageUrl

    if (isNaN(index) || index < 0) {
      return
    }

    this.currentIndexValue = index
    this.updateSelection(index)

    this.dispatch('selectImage', {
      detail: { index, imageUrl },
      prefix: 'gallery'
    })
  }

  setupGalleryListeners() {
    this.galleryImageChangedHandler = this.handleGalleryImageChanged.bind(this)
    this.galleryVariantChangedHandler = this.handleGalleryVariantChanged.bind(this)

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
    const { currentIndex } = event.detail
    this.currentIndexValue = currentIndex
    this.updateSelection(currentIndex)
    this.updateArrowStates()
  }

  initializeThumbnails() {
    this.updateSelection(this.currentIndexValue)
    this.setupAccessibility()
    this.updateArrowStates()
  }

  updateSelection(activeIndex) {
    this.thumbnailTargets.forEach((thumbnail, index) => {
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

  scrollToThumbnail(index) {
    const thumbnail = this.thumbnailTargets[index]
    if (thumbnail) {
      thumbnail.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      })
    }
  }

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
    const thumbnailHeight = this.getThumbnailHeight()
    const visibleCount = 4
    const scrollAmount = visibleCount * thumbnailHeight

    const newOffset = this.thumbnailScrollOffsetValue + (direction * scrollAmount)
    const totalImages = this.getTotalImagesCount()
    const maxOffset = Math.max(0, (totalImages - visibleCount) * thumbnailHeight)
    const clampedOffset = Math.max(0, Math.min(newOffset, maxOffset))

    this.thumbnailScrollOffsetValue = clampedOffset

    const innerContainer = container.children[0]
    if (innerContainer) {
      innerContainer.style.transform = `translateY(-${clampedOffset}px)`
    }

    this.updateArrowStates()
  }

  updateArrowStates() {
    if (!this.hasThumbnailContainerTarget) return

    const totalImages = this.getTotalImagesCount()
    const visibleCount = 4
    const maxOffset = Math.max(0, (totalImages - visibleCount) * this.getThumbnailHeight())

    if (this.hasUpArrowTarget) {
      const upOpacity = this.thumbnailScrollOffsetValue > 0 ? '1' : '0.3'
      this.upArrowTarget.style.opacity = upOpacity
      this.upArrowTarget.disabled = this.thumbnailScrollOffsetValue <= 0
    }

    if (this.hasDownArrowTarget) {
      const downOpacity = this.thumbnailScrollOffsetValue < maxOffset ? '1' : '0.3'
      this.downArrowTarget.style.opacity = downOpacity
      this.downArrowTarget.disabled = this.thumbnailScrollOffsetValue >= maxOffset
    }
  }

  getTotalImagesCount() {
    return this.thumbnailTargets.length || 1
  }

  getThumbnailHeight() {
    const styles = getComputedStyle(document.documentElement)
    const thumbSize = parseInt(styles.getPropertyValue('--thumb-size')) || 68
    const thumbGap = parseInt(styles.getPropertyValue('--thumb-gap')) || 8
    return thumbSize + thumbGap
  }

  setupAccessibility() {
    if (this.hasContainerTarget) {
      this.containerTarget.setAttribute('role', 'tablist')
      this.containerTarget.setAttribute('aria-label', 'Product image thumbnails')
    }

    const firstThumbnail = this.thumbnailTargets[0]
    if (firstThumbnail) {
      firstThumbnail.setAttribute('tabindex', '0')
    }
  }

  handleError(message, error = null) {
    console.error(`Gallery Thumbnails Controller: ${message}`, error)
  }
}
