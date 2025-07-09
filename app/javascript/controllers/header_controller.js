import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "nav", "locationSelector", "searchBtn", "favoritesBtn", "profileBtn", "cartBtn", "mobileMenuToggle", "mobileMenuOverlay", "mobileMenuPanel", "authPopupOverlay", "authPopupPanel"]

  connect() {
    this.scrollThreshold = 10
    this.isScrolled = false
    this.isMobileMenuOpen = false
    this.isAuthPopupOpen = false
    this.activeAuthTab = 'signin'
    this.setupScrollListener()
    this.setupHoverEffects()

    this.initializeHeaderState()
  }

  disconnect() {
    this.removeScrollListener()
    this.removeHoverEffects()
  }

  initializeHeaderState() {
    if (this.headerTarget && this.navTarget) {
      this.headerTarget.classList.add('bg-transparent')
      this.navTarget.classList.add('bg-transparent')
      this.headerTarget.classList.remove('bg-white')
      this.navTarget.classList.remove('bg-white')
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

    const isAuthenticated = document.body.dataset.authenticated === 'true'
    if (!isAuthenticated && !this.isAuthPopupOpen) {
      sessionStorage.setItem('authReturnUrl', window.location.href);
    }

    this.isAuthPopupOpen = !this.isAuthPopupOpen
    this.updateAuthPopup()

    if (this.isAuthPopupOpen && !isAuthenticated) {
      this.clearFormErrors();
    }
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
      this.mobileMenuOverlayTarget.classList.remove('opacity-0', 'pointer-events-none')
      this.mobileMenuPanelTarget.classList.remove('-translate-x-full')
      this.mobileMenuToggleTarget.setAttribute('aria-expanded', 'true')
      document.body.style.overflow = 'hidden' // Prevent background scrolling
    } else {
      this.mobileMenuOverlayTarget.classList.add('opacity-0', 'pointer-events-none')
      this.mobileMenuPanelTarget.classList.add('-translate-x-full')
      this.mobileMenuToggleTarget.setAttribute('aria-expanded', 'false')
      document.body.style.overflow = ''
    }
  }

  switchLanguage(event) {
    event.preventDefault()

    const targetLocale = event.target.dataset.locale || this.getLocaleFromText(event.target.textContent.trim())

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (!csrfToken) {
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

    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    const localeInput = document.createElement('input')
    localeInput.type = 'hidden'
    localeInput.name = 'locale'
    localeInput.value = targetLocale
    form.appendChild(localeInput)

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

  closeAuthPopup(event) {
    event.preventDefault()
    this.isAuthPopupOpen = false
    this.updateAuthPopup()
  }

  updateAuthPopup() {
    if (!this.hasAuthPopupOverlayTarget || !this.hasAuthPopupPanelTarget) return

    if (this.isAuthPopupOpen) {
      this.authPopupOverlayTarget.classList.remove('opacity-0', 'pointer-events-none')
      this.authPopupPanelTarget.classList.remove('translate-x-full')
      document.body.style.overflow = 'hidden'
    } else {
      this.authPopupOverlayTarget.classList.add('opacity-0', 'pointer-events-none')
      this.authPopupPanelTarget.classList.add('translate-x-full')
      document.body.style.overflow = ''
    }
  }

  switchAuthTab(event) {
    event.preventDefault()
    const targetTab = event.target.dataset.tab
    if (targetTab === this.activeAuthTab) return

    this.activeAuthTab = targetTab

    const tabButtons = this.element.querySelectorAll('.auth-tab-btn')
    tabButtons.forEach(btn => {
      if (btn.dataset.tab === targetTab) {
        btn.classList.add('active', 'bg-white', 'text-gray-900', 'shadow-sm')
        btn.classList.remove('text-gray-500')
      } else {
        btn.classList.remove('active', 'bg-white', 'text-gray-900', 'shadow-sm')
        btn.classList.add('text-gray-500')
      }
    })

    const formContainers = this.element.querySelectorAll('.auth-form-container')
    formContainers.forEach(container => {
      if (container.dataset.form === targetTab) {
        container.classList.remove('hidden')
      } else {
        container.classList.add('hidden')
      }
    })

    this.clearFormErrors();
  }

  clearFormErrors() {
    const authPopup = this.element.querySelector('[data-header-target="authPopupPanel"]');
    if (!authPopup) return;

    const formContainers = authPopup.querySelectorAll('.auth-form-container');
    formContainers.forEach(container => {
      const errorDivs = container.querySelectorAll('.text-red-600');
      errorDivs.forEach(errorDiv => {
        errorDiv.classList.add('hidden');
        const span = errorDiv.querySelector('span');
        if (span) span.textContent = '';
      });
    });

    const inputs = authPopup.querySelectorAll('input[type="email"], input[type="password"]');
    inputs.forEach(input => {
      input.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500');
      input.classList.add('border-gray-300', 'focus:border-cyan-500', 'focus:ring-cyan-500');
    });

    const forms = authPopup.querySelectorAll('form[data-controller="auth-form"]');
    forms.forEach(form => {
      const controller = this.application.getControllerForElementAndIdentifier(form, 'auth-form');
      if (controller) {
        controller.hasInteracted = {};
      }
    });
  }
}
