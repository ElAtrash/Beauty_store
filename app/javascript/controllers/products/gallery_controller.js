import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "mainImage",
    "thumbnail",
    "mobileThumbnail",
    "zoomModal",
    "currentIndex",
    "thumbnailContainer",
    "upArrow",
    "downArrow",
    "zoomThumbnail",
    "zoomImageCard"
  ]

  // Configuration constants
  static maxVisibleThumbnails = 4
  static transitionDuration = 100

  connect() {
    this.currentImageIndex = 0
    this.thumbnailWindowStart = 0
    this.zoomThumbnailWindowStart = 0 // Separate window for zoom thumbnails
    this.maxVisibleThumbnails = this.constructor.maxVisibleThumbnails

    // Debounced methods for performance
    this.debouncedUpdateThumbnailWindow = this.debounce(this.updateThumbnailWindow.bind(this), 50)

    this.selectInitialThumbnail()
    this.setupKeyboardNavigation()
    this.setupTouchSupport()

    // Use requestAnimationFrame for smooth initialization
    requestAnimationFrame(() => this.updateThumbnailWindow('main'))
  }

  disconnect() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }

  // Thumbnail selection
  selectImage(event) {
    const index = this.safeParseInt(event.params.index)
    const imageUrl = event.params.imageUrl

    if (!this.isValidIndex(index, this.thumbnailTargets.length)) {
      return
    }

    this.currentImageIndex = index
    this.updateMainImage(imageUrl)
    this.updateThumbnailSelection(index)
    this.updateImageCounter(index)

    // Ensure the selected thumbnail is visible in the current window
    this.ensureThumbnailVisible(index)
  }


  // Open zoom modal
  zoomImage(event) {
    if (this.hasZoomModalTarget) {
      this.zoomModalTarget.classList.remove('hidden')
      document.body.classList.add('overflow-hidden', 'modal-open', 'gallery-modal-open')

      // Wait for DOM to update and targets to be available
      setTimeout(() => {
        // Reset zoom thumbnail window to start and initialize
        this.zoomThumbnailWindowStart = 0
        this.updateThumbnailWindow('zoom')

        // Highlight current image thumbnail
        this.updateZoomThumbnailSelection(this.currentImageIndex)

        // Ensure current thumbnail is visible in zoom window
        this.ensureZoomThumbnailVisible(this.currentImageIndex)
      }, 50)
    }
  }

  // Close zoom modal
  closeZoom() {
    if (this.hasZoomModalTarget) {
      this.zoomModalTarget.classList.add('hidden')
      document.body.classList.remove('overflow-hidden', 'modal-open', 'gallery-modal-open')
    }
  }

  // Unified thumbnail window navigation
  scrollThumbnailsUp(event) {
    // Prevent action if button is disabled
    if (event.target.closest('button').disabled) return

    const context = this.isZoomModalOpen() ? 'zoom' : 'main'
    const config = this.getThumbnailConfig(context)

    if (config.totalImages <= this.maxVisibleThumbnails) return

    config.setWindowStart(0)
    this.updateThumbnailWindow(context)
  }

  scrollThumbnailsDown(event) {
    // Prevent action if button is disabled
    if (event.target.closest('button').disabled) return

    const context = this.isZoomModalOpen() ? 'zoom' : 'main'
    const config = this.getThumbnailConfig(context)

    if (config.totalImages <= this.maxVisibleThumbnails) return

    const maxWindowStart = config.totalImages - this.maxVisibleThumbnails
    config.setWindowStart(maxWindowStart)
    this.updateThumbnailWindow(context)
  }

  // Helper method to check if zoom modal is open
  isZoomModalOpen() {
    return this.hasZoomModalTarget && !this.zoomModalTarget.classList.contains('hidden')
  }

  // Legacy methods for horizontal scrolling (mobile)
  scrollThumbnailsLeft() {
    this.scrollThumbnailsUp()
  }

  scrollThumbnailsRight() {
    this.scrollThumbnailsDown()
  }

  // Main gallery navigation (click zones and arrows)
  previousImage(event) {
    event.stopPropagation()

    const totalImages = this.thumbnailTargets.length
    if (totalImages <= 1) return

    // Carousel navigation - go to previous image
    const newIndex = this.currentImageIndex > 0 ? this.currentImageIndex - 1 : totalImages - 1
    this.selectImageByIndex(newIndex)
  }

  nextImage(event) {
    event.stopPropagation()

    const totalImages = this.thumbnailTargets.length
    if (totalImages <= 1) return

    // Carousel navigation - go to next image
    const newIndex = this.currentImageIndex < totalImages - 1 ? this.currentImageIndex + 1 : 0
    this.selectImageByIndex(newIndex)
  }

  nextImageOrZoom(event) {
    event.stopPropagation()

    const totalImages = this.thumbnailTargets.length

    // If multiple images, navigate first, zoom on second click
    if (totalImages > 1) {
      const newIndex = this.currentImageIndex < totalImages - 1 ? this.currentImageIndex + 1 : 0
      this.selectImageByIndex(newIndex)
    } else {
      // Single image, zoom immediately
      this.zoomImage(event)
    }
  }

  // Navigation in zoom mode
  previousImageInZoom(event) {
    event.stopPropagation()

    const totalImages = this.thumbnailTargets.length
    this.currentImageIndex = this.currentImageIndex > 0 ? this.currentImageIndex - 1 : totalImages - 1
    this.updateZoomImage()
    this.updateThumbnailSelection(this.currentImageIndex)
  }

  nextImageInZoom(event) {
    event.stopPropagation()

    const totalImages = this.thumbnailTargets.length
    this.currentImageIndex = this.currentImageIndex < totalImages - 1 ? this.currentImageIndex + 1 : 0
    this.updateZoomImage()
    this.updateThumbnailSelection(this.currentImageIndex)
  }

  selectImageByIndex(index) {
    if (this.thumbnailTargets[index]) {
      const thumbnail = this.thumbnailTargets[index]
      const imageUrl = thumbnail.dataset['products-GalleryImageUrlParam']

      this.currentImageIndex = index
      this.updateMainImage(imageUrl)
      this.updateThumbnailSelection(index)
      this.updateImageCounter(index)

      // Ensure the selected thumbnail is visible
      this.ensureThumbnailVisible(index)
    }
  }

  updateZoomImage() {
    if (this.thumbnailTargets[this.currentImageIndex]) {
      const thumbnail = this.thumbnailTargets[this.currentImageIndex]
      const imageUrl = thumbnail.dataset['products-GalleryImageUrlParam']

      if (imageUrl && this.hasZoomedImageTarget) {
        this.showLoadingSpinner()
        this.loadZoomedImage(imageUrl)
        this.updateZoomCounter()
        this.updateZoomThumbnailSelection(this.currentImageIndex)
      }
    }
  }

  // Handle zoom thumbnail clicks - scroll to corresponding image
  selectImageInZoom(event) {
    const index = parseInt(event.params.index)

    // Find and scroll to the image
    const imageCard = document.getElementById(`zoom-image-${index}`)
    if (imageCard) {
      imageCard.scrollIntoView({ behavior: 'smooth', block: 'start' })
      this.updateZoomThumbnailSelection(index)
      this.currentImageIndex = index
    }
  }

  // Update zoom thumbnail selection
  updateZoomThumbnailSelection(activeIndex) {
    if (this.hasZoomThumbnailTargets) {
      this.zoomThumbnailTargets.forEach((thumbnail, index) => {
        if (index === activeIndex) {
          thumbnail.classList.remove("border-transparent", "opacity-70")
          thumbnail.classList.add("border-black", "opacity-100")
        } else {
          thumbnail.classList.remove("border-black", "opacity-100")
          thumbnail.classList.add("border-transparent", "opacity-70")
        }
      })
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // Private methods
  updateMainImage(imageUrl) {
    if (this.hasMainImageTarget && imageUrl) {
      // Add subtle fade transition
      this.mainImageTarget.style.opacity = '0.8'

      setTimeout(() => {
        this.mainImageTarget.src = imageUrl
        this.mainImageTarget.style.opacity = '1'
      }, 100)
    }
  }

  updateThumbnailSelection(activeIndex) {
    // Update desktop thumbnails
    this.thumbnailTargets.forEach((thumbnail, index) => {
      if (index === activeIndex) {
        thumbnail.classList.remove("border-transparent", "opacity-70")
        thumbnail.classList.add("border-black", "opacity-100")
      } else {
        thumbnail.classList.remove("border-black", "opacity-100")
        thumbnail.classList.add("border-transparent", "opacity-70")
      }
    })

    // Update mobile thumbnails
    if (this.hasMobileThumbnailTargets) {
      this.mobileThumbnailTargets.forEach((thumbnail, index) => {
        if (index === activeIndex) {
          thumbnail.classList.remove("border-transparent", "opacity-70")
          thumbnail.classList.add("border-black", "opacity-100")
        } else {
          thumbnail.classList.remove("border-black", "opacity-100")
          thumbnail.classList.add("border-transparent", "opacity-70")
        }
      })
    }
  }

  updateImageCounter(index) {
    if (this.hasCurrentIndexTarget) {
      this.currentIndexTarget.textContent = index + 1
    }
  }

  selectInitialThumbnail() {
    if (this.thumbnailTargets.length > 0) {
      this.updateThumbnailSelection(0)
    }
  }

  setupKeyboardNavigation() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  handleKeydown(event) {
    // Only handle ESC key to close zoom modal
    if (event.key === 'Escape' && this.hasZoomModalTarget && !this.zoomModalTarget.classList.contains('hidden')) {
      this.closeZoom()
      event.preventDefault()
    }
  }


  ensureThumbnailVisible(index) {
    const totalImages = this.thumbnailTargets.length

    if (totalImages <= this.maxVisibleThumbnails) return

    const windowEnd = this.thumbnailWindowStart + this.maxVisibleThumbnails

    if (index < this.thumbnailWindowStart || index >= windowEnd) {
      if (index < this.thumbnailWindowStart) {
        this.thumbnailWindowStart = Math.max(0, index)
      } else {
        this.thumbnailWindowStart = Math.min(totalImages - this.maxVisibleThumbnails, index - this.maxVisibleThumbnails + 1)
      }
      this.updateThumbnailWindow('main')
    }
  }

  setupTouchSupport() {
    if (!this.hasMainImageTarget) return

    let startX, startY, startTime

    this.mainImageTarget.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX
      startY = e.touches[0].clientY
      startTime = Date.now()
    }, { passive: true })

    this.mainImageTarget.addEventListener('touchend', (e) => {
      const endX = e.changedTouches[0].clientX
      const endY = e.changedTouches[0].clientY
      const endTime = Date.now()

      const deltaX = endX - startX
      const deltaY = endY - startY
      const deltaTime = endTime - startTime

      // Detect swipe vs tap
      if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50 && deltaTime < 500) {
        if (deltaX > 0) {
          this.previousImage(e)
        } else {
          this.nextImage(e)
        }
      } else if (Math.abs(deltaX) < 10 && Math.abs(deltaY) < 10 && deltaTime < 300) {
        this.zoomImage(e)
      }
    }, { passive: true })
  }

  // Unified thumbnail configuration
  getThumbnailConfig(context = 'main') {
    if (context === 'zoom') {
      const zoomThumbnails = this.element.querySelectorAll('[data-products--gallery-target="zoomThumbnail"]')
      const upArrow = this.element.querySelector('[data-products--gallery-target="upArrow"]')
      const downArrow = this.element.querySelector('[data-products--gallery-target="downArrow"]')

      return {
        thumbnails: zoomThumbnails,
        totalImages: zoomThumbnails.length,
        windowStart: this.zoomThumbnailWindowStart,
        setWindowStart: (value) => { this.zoomThumbnailWindowStart = value },
        upArrow,
        downArrow,
        context: 'zoom'
      }
    } else {
      return {
        thumbnails: this.thumbnailTargets,
        totalImages: this.thumbnailTargets.length,
        windowStart: this.thumbnailWindowStart,
        setWindowStart: (value) => { this.thumbnailWindowStart = value },
        upArrow: this.hasUpArrowTarget ? this.upArrowTarget : null,
        downArrow: this.hasDownArrowTarget ? this.downArrowTarget : null,
        context: 'main'
      }
    }
  }

  // Unified thumbnail window management
  updateThumbnailWindow(context = 'main') {
    const config = this.getThumbnailConfig(context)

    if (config.totalImages === 0) return

    // If 4 or fewer images, show all thumbnails and hide arrows
    if (config.totalImages <= this.maxVisibleThumbnails) {
      this.showAllThumbnails(config)
      this.hideArrows(config)
      return
    }

    // Show arrows when needed
    this.showArrows(config)

    // Hide all thumbnails first
    this.hideAllThumbnails(config)

    // Show only the current window of thumbnails
    this.showWindowedThumbnails(config)

    // Update arrow states
    this.updateArrowStates(config)
  }

  // Helper methods for unified thumbnail management
  showAllThumbnails(config) {
    config.thumbnails.forEach(thumbnail => {
      thumbnail.style.display = 'block'
    })
  }

  hideAllThumbnails(config) {
    config.thumbnails.forEach(thumbnail => {
      thumbnail.style.display = 'none'
    })
  }

  showWindowedThumbnails(config) {
    const windowEnd = Math.min(config.windowStart + this.maxVisibleThumbnails, config.totalImages)

    for (let i = config.windowStart; i < windowEnd; i++) {
      if (config.thumbnails[i]) {
        config.thumbnails[i].style.display = 'block'
      }
    }
  }

  hideArrows(config) {
    if (config.upArrow) config.upArrow.style.display = 'none'
    if (config.downArrow) config.downArrow.style.display = 'none'
  }

  showArrows(config) {
    if (config.upArrow) config.upArrow.style.display = 'block'
    if (config.downArrow) config.downArrow.style.display = 'block'
  }

  updateArrowStates(config) {
    if (config.totalImages <= this.maxVisibleThumbnails) return

    // Update up arrow state
    if (config.upArrow) {
      if (config.windowStart === 0) {
        config.upArrow.disabled = true
        // Only apply visual styling for product page (main context)
        if (config.context === 'main') {
          config.upArrow.classList.add('opacity-50')
        }
      } else {
        config.upArrow.disabled = false
        if (config.context === 'main') {
          config.upArrow.classList.remove('opacity-50')
        }
      }
    }

    // Update down arrow state
    if (config.downArrow) {
      const maxWindowStart = config.totalImages - this.maxVisibleThumbnails
      if (config.windowStart >= maxWindowStart) {
        config.downArrow.disabled = true
        if (config.context === 'main') {
          config.downArrow.classList.add('opacity-50')
        }
      } else {
        config.downArrow.disabled = false
        if (config.context === 'main') {
          config.downArrow.classList.remove('opacity-50')
        }
      }
    }
  }


  ensureZoomThumbnailVisible(index) {
    const zoomThumbnails = this.element.querySelectorAll('[data-products--professional-gallery-target="zoomThumbnail"]')
    if (zoomThumbnails.length === 0) return

    const totalImages = zoomThumbnails.length

    if (totalImages <= this.maxVisibleThumbnails) return

    const windowEnd = this.zoomThumbnailWindowStart + this.maxVisibleThumbnails

    if (index < this.zoomThumbnailWindowStart || index >= windowEnd) {
      if (index < this.zoomThumbnailWindowStart) {
        this.zoomThumbnailWindowStart = Math.max(0, index)
      } else {
        this.zoomThumbnailWindowStart = Math.min(totalImages - this.maxVisibleThumbnails, index - this.maxVisibleThumbnails + 1)
      }
      this.updateThumbnailWindow('zoom')
    }
  }

  // Utility: Debounce function for performance optimization
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  // Utility: Safe integer parsing with validation
  safeParseInt(value, fallback = 0) {
    const parsed = parseInt(value, 10)
    return isNaN(parsed) ? fallback : parsed
  }

  // Utility: Validate index bounds
  isValidIndex(index, maxLength) {
    return index >= 0 && index < maxLength
  }
}
