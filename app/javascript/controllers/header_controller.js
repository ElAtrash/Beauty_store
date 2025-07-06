import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "nav", "locationSelector", "searchBtn", "favoritesBtn", "profileBtn", "cartBtn", "mobileMenuToggle"]

  connect() {
    this.scrollThreshold = 10
    this.isScrolled = false
    this.setupScrollListener()
    this.setupHoverEffects()
  }

  disconnect() {
    this.removeScrollListener()
    this.removeHoverEffects()
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
    if (window.scrollY <= this.scrollThreshold) {
      this.updateHeaderBackground(true)
    }
  }

  handleMouseLeave() {
    if (window.scrollY <= this.scrollThreshold) {
      this.updateHeaderBackground(false)
    }
  }

  handleScroll() {
    const shouldBeScrolled = window.scrollY > this.scrollThreshold

    if (shouldBeScrolled !== this.isScrolled) {
      this.isScrolled = shouldBeScrolled
      this.updateHeaderBackground(shouldBeScrolled)
    }
  }

  updateHeaderBackground(isScrolled) {
    if (!this.headerTarget || !this.navTarget) return

    const method = isScrolled ? 'add' : 'remove'
    const oppositeMethod = isScrolled ? 'remove' : 'add'

    this.headerTarget.classList[method]('bg-white')
    this.navTarget.classList[method]('bg-white')
    this.headerTarget.classList[oppositeMethod]('bg-transparent')
    this.navTarget.classList[oppositeMethod]('bg-transparent')
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
    // TODO: Toggle mobile menu
    console.log('Mobile menu toggled')
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
