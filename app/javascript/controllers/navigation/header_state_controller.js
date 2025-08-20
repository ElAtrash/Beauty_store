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
    this.updateHeaderState()
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
    if (this.headerTarget) {
      this.headerTarget.dataset.headerState = state
    }
    if (this.navTarget) {
      this.navTarget.dataset.headerState = state
    }
  }

  setHeaderContext(context) {
    if (this.headerTarget) {
      this.headerTarget.dataset.headerContext = context
    }
    if (this.navTarget) {
      this.navTarget.dataset.headerContext = context
    }

    if (context === 'brand-image' && this.bannerUrlValue) {
      if (this.headerTarget) {
        this.headerTarget.style.setProperty('--header-banner-url', `url('${this.bannerUrlValue}')`)
      }
      if (this.navTarget) {
        this.navTarget.style.setProperty('--header-banner-url', `url('${this.bannerUrlValue}')`)
      }
    } else {
      if (this.headerTarget) {
        this.headerTarget.style.removeProperty('--header-banner-url')
      }
      if (this.navTarget) {
        this.navTarget.style.removeProperty('--header-banner-url')
      }
    }
  }
}
