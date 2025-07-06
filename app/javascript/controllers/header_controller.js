import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "nav", "locationSelector", "searchBtn", "favoritesBtn", "profileBtn", "cartBtn", "mobileMenuToggle", "mobileMenuOverlay", "mobileMenuPanel"]

  connect() {
    console.log("Header controller connected")
    this.scrollThreshold = 10
    this.isScrolled = false
    this.isMobileMenuOpen = false
    this.setupScrollListener()
    this.setupHoverEffects()

    // Ensure header starts transparent
    this.initializeHeaderState()
  }

  disconnect() {
    this.removeScrollListener()
    this.removeHoverEffects()
  }

  initializeHeaderState() {
    console.log("Initializing header state")
    // Ensure header starts with transparent background
    if (this.headerTarget && this.navTarget) {
      console.log("Setting initial transparent state")
      this.headerTarget.classList.add('bg-transparent')
      this.navTarget.classList.add('bg-transparent')
      this.headerTarget.classList.remove('bg-white')
      this.navTarget.classList.remove('bg-white')

      console.log("Header classes:", this.headerTarget.className)
      console.log("Nav classes:", this.navTarget.className)
    } else {
      console.error("Header or nav targets not found")
    }
  }

  setupScrollListener() {
    this.handleScroll = this.throttle(this.handleScroll.bind(this), 16) // ~60fps
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  }

  removeScrollListener() {
    if (this.handleScroll) {
      window.removeEventListener('scroll', this.handleScroll)
    }
  }

  setupHoverEffects() {
    if (!this.headerTarget) return

    this.handleMouseEnter = this.handleMouseEnter.bind(this)
    this.handleMouseLeave = this.handleMouseLeave.bind(this)

    this.headerTarget.addEventListener('mouseenter', this.handleMouseEnter)
    this.headerTarget.addEventListener('mouseleave', this.handleMouseLeave)
  }

  removeHoverEffects() {
    if (this.headerTarget) {
      this.headerTarget.removeEventListener('mouseenter', this.handleMouseEnter)
      this.headerTarget.removeEventListener('mouseleave', this.handleMouseLeave)
    }
  }

  handleMouseEnter() {
    console.log("Mouse enter, scrollY:", window.scrollY)
    if (window.scrollY <= this.scrollThreshold) {
      this.updateHeaderBackground(true)
    }
  }

  handleMouseLeave() {
    console.log("Mouse leave, scrollY:", window.scrollY)
    if (window.scrollY <= this.scrollThreshold) {
      this.updateHeaderBackground(false)
    }
  }

  handleScroll() {
    const shouldBeScrolled = window.scrollY > this.scrollThreshold

    if (shouldBeScrolled !== this.isScrolled) {
      console.log("Scroll state changed:", shouldBeScrolled)
      this.isScrolled = shouldBeScrolled
      this.updateHeaderBackground(shouldBeScrolled)
    }
  }

  updateHeaderBackground(isScrolled) {
    if (!this.headerTarget || !this.navTarget) return

    console.log("Updating header background, isScrolled:", isScrolled)
    const method = isScrolled ? 'add' : 'remove'
    const oppositeMethod = isScrolled ? 'remove' : 'add'

    this.headerTarget.classList[method]('bg-white')
    this.navTarget.classList[method]('bg-white')
    this.headerTarget.classList[oppositeMethod]('bg-transparent')
    this.navTarget.classList[oppositeMethod]('bg-transparent')

    console.log("Header classes after update:", this.headerTarget.className)
    console.log("Nav classes after update:", this.navTarget.className)
  }

  throttle(func, limit) {
    let inThrottle
    return function () {
      const args = arguments
      const context = this
      if (!inThrottle) {
        func.apply(context, args)
        inThrottle = true
        setTimeout(() => inThrottle = false, limit)
      }
    }
  }

  selectLocation(event) {
    event.preventDefault()
    // TODO: Open location selection modal
    console.log('Location selector clicked')
  }

  openSearch(event) {
    event.preventDefault()
    // TODO: Open search modal
    console.log('Search clicked')
  }

  openFavorites(event) {
    event.preventDefault()
    // TODO: Open favorites modal
    console.log('Favorites clicked')
  }

  openProfile(event) {
    event.preventDefault()
    // TODO: Open profile modal
    console.log('Profile clicked')
  }

  openCart(event) {
    event.preventDefault()
    // TODO: Open cart modal
    console.log('Cart clicked')
  }

  toggleMobileMenu(event) {
    event.preventDefault()
    this.isMobileMenuOpen = !this.isMobileMenuOpen
    this.updateMobileMenu()
  }

  closeMobileMenu(event) {
    event.preventDefault()
    this.isMobileMenuOpen = false
    this.updateMobileMenu()
  }

  updateMobileMenu() {
    if (!this.hasMobileMenuOverlayTarget || !this.hasMobileMenuPanelTarget || !this.hasMobileMenuToggleTarget) return

    if (this.isMobileMenuOpen) {
      // Open mobile menu
      this.mobileMenuOverlayTarget.classList.remove('opacity-0', 'pointer-events-none')
      this.mobileMenuPanelTarget.classList.remove('-translate-x-full')
      this.mobileMenuToggleTarget.setAttribute('aria-expanded', 'true')
      document.body.style.overflow = 'hidden' // Prevent background scrolling
    } else {
      // Close mobile menu
      this.mobileMenuOverlayTarget.classList.add('opacity-0', 'pointer-events-none')
      this.mobileMenuPanelTarget.classList.add('-translate-x-full')
      this.mobileMenuToggleTarget.setAttribute('aria-expanded', 'false')
      document.body.style.overflow = '' // Restore scrolling
    }
  }

  switchLanguage(event) {
    event.preventDefault()

    // Use data attribute if available, otherwise fall back to text content
    const targetLocale = event.target.dataset.locale || this.getLocaleFromText(event.target.textContent.trim())

    console.log('Switching language to:', targetLocale)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (!csrfToken) {
      console.error('CSRF token not found')
      return
    }

    this.submitLocaleForm(targetLocale, csrfToken)
  }

  getLocaleFromText(languageText) {
    const localeMap = {
      'العربية': 'ar',
      'EN': 'en'
    }
    return localeMap[languageText] || 'en'
  }

  submitLocaleForm(targetLocale, csrfToken) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/set_locale'

    // Add CSRF token
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Add locale
    const localeInput = document.createElement('input')
    localeInput.type = 'hidden'
    localeInput.name = 'locale'
    localeInput.value = targetLocale
    form.appendChild(localeInput)

    // Add return path
    let currentPath = window.location.pathname
    currentPath = currentPath.replace(/^\/(en|ar)\/?/, '/')
    if (currentPath === '') currentPath = '/'

    const returnToInput = document.createElement('input')
    returnToInput.type = 'hidden'
    returnToInput.name = 'return_to'
    returnToInput.value = currentPath + window.location.search
    form.appendChild(returnToInput)

    document.body.appendChild(form)
    form.submit()
  }
}
