import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "nav"]
  static values = {
    pageType: String,
    bannerUrl: String
  }

  connect() {
    this.isScrolled = false
    this.isHovered = false

    // Ensure DOM elements exist before proceeding
    if (!this.headerTarget || !this.navTarget) {
      console.warn('HeaderStateController: Required targets not found')
      return
    }

    this.setupHoverEffects()
    this.setupScrollListener()
    this.initializeHeaderState()
  }

  disconnect() {
    this.removeHoverEffects()
    this.removeScrollListener()
  }

  setupScrollListener() {
    this.scrollStateChangedHandler = this.handleScrollStateChanged.bind(this)
    this.element.addEventListener('navigation--scroll-detection:scroll-state-changed', this.scrollStateChangedHandler)
  }

  removeScrollListener() {
    if (this.scrollStateChangedHandler) {
      this.element.removeEventListener('navigation--scroll-detection:scroll-state-changed', this.scrollStateChangedHandler)
    }
  }

  handleScrollStateChanged(event) {
    this.isScrolled = event.detail.isScrolled
    this.updateHeaderState()
  }

  setupHoverEffects() {
    if (!this.headerTarget || !this.navTarget) return

    if (this.pageTypeValue === 'product') return

    this.handleMouseEnter = this.handleMouseEnter.bind(this)
    this.handleMouseLeave = this.handleMouseLeave.bind(this)

    this.headerTarget.addEventListener('mouseenter', this.handleMouseEnter)
    this.headerTarget.addEventListener('mouseleave', this.handleMouseLeave)
    this.navTarget.addEventListener('mouseenter', this.handleMouseEnter)
    this.navTarget.addEventListener('mouseleave', this.handleMouseLeave)
  }

  removeHoverEffects() {
    if (this.headerTarget) {
      this.headerTarget.removeEventListener('mouseenter', this.handleMouseEnter)
      this.headerTarget.removeEventListener('mouseleave', this.handleMouseLeave)
    }
    if (this.navTarget) {
      this.navTarget.removeEventListener('mouseenter', this.handleMouseEnter)
      this.navTarget.removeEventListener('mouseleave', this.handleMouseLeave)
    }
  }

  handleMouseEnter() {
    if (!this.isScrolled) {
      this.isHovered = true
      this.updateHeaderState()
    }
  }

  handleMouseLeave() {
    if (!this.isScrolled) {
      this.isHovered = false
      this.updateHeaderState()
    }
  }

  initializeHeaderState() {
    // Set initial scroll state based on current scroll position
    this.isScrolled = window.scrollY > 10

    // Update header state immediately with proper initial values
    this.updateHeaderState()

    // Force a state update after a short delay to ensure CSS has loaded
    setTimeout(() => {
      this.updateHeaderState()
    }, 100)
  }

  updateHeaderState() {
    const state = this.determineHeaderState()
    const context = this.determineHeaderContext()

    this.setHeaderState(state)
    this.setHeaderContext(context)
  }

  determineHeaderState() {
    if (this.pageTypeValue === 'product') {
      return 'white'
    }

    if (this.isScrolled) {
      return 'scrolled'
    }

    if (this.isHovered) {
      return 'hovered'
    }

    return 'transparent'
  }

  determineHeaderContext() {
    if (this.pageTypeValue === 'brand') {
      return this.hasBannerUrlValue && this.bannerUrlValue ? 'brand-image' : 'brand-gradient'
    }
    return 'default'
  }

  setHeaderState(state) {
    if (!state) {
      console.warn('HeaderStateController: Invalid state provided')
      return
    }

    if (this.headerTarget) {
      this.headerTarget.dataset.headerState = state
    }
    if (this.navTarget) {
      this.navTarget.dataset.headerState = state
    }

    // Debug logging for development
    if (this.debug) {
      console.log(`HeaderStateController: Set header state to "${state}"`)
    }
  }

  setHeaderContext(context) {
    if (!context) {
      console.warn('HeaderStateController: Invalid context provided')
      return
    }

    if (this.headerTarget) {
      this.headerTarget.dataset.headerContext = context
    }
    if (this.navTarget) {
      this.navTarget.dataset.headerContext = context
    }

    // Handle brand image context with proper error handling
    if (context === 'brand-image' && this.bannerUrlValue) {
      try {
        const bannerUrl = `url('${this.bannerUrlValue}')`
        if (this.headerTarget) {
          this.headerTarget.style.setProperty('--header-banner-url', bannerUrl)
        }
        if (this.navTarget) {
          this.navTarget.style.setProperty('--header-banner-url', bannerUrl)
        }
      } catch (error) {
        console.warn('HeaderStateController: Error setting banner URL', error)
      }
    } else {
      // Clean up banner URL property when not needed
      if (this.headerTarget) {
        this.headerTarget.style.removeProperty('--header-banner-url')
      }
      if (this.navTarget) {
        this.navTarget.style.removeProperty('--header-banner-url')
      }
    }

    // Debug logging for development
    if (this.debug) {
      console.log(`HeaderStateController: Set header context to "${context}"`)
    }
  }

  // Enable debug mode by adding data-debug="true" to the controller element
  get debug() {
    return this.element.dataset.debug === 'true'
  }
}
