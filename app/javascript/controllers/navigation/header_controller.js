import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "nav", "locationSelector", "searchBtn", "favoritesBtn", "profileBtn", "cartBtn", "mobileMenuToggle", "mobileMenuOverlay", "mobileMenuPanel", "authPopupOverlay", "authPopupPanel"]
  static values = {
    pageType: String,
    bannerUrl: String
  }

  connect() {
    this.scrollThreshold = 10
    this.isScrolled = false
    this.isHovered = false
    this.isMobileMenuOpen = false
    this.isAuthPopupOpen = false
    this.activeAuthTab = 'signin'

    this.setupScrollListener()
    this.setupHoverEffects()

    if (this.pageTypeValue === 'brand') {
      this.extractBannerImage()
    } else {
      this.initializeHeaderState()
    }
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
    if (!this.headerTarget || !this.navTarget) return

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
    if (window.scrollY <= this.scrollThreshold) {
      this.isHovered = true
      this.updateHeaderBackground(true)
    }
  }

  handleMouseLeave() {
    if (window.scrollY <= this.scrollThreshold) {
      this.isHovered = false
      this.updateHeaderBackground(false)
    }
  }

  handleScroll() {
    const shouldBeScrolled = window.scrollY > this.scrollThreshold

    if (shouldBeScrolled !== this.isScrolled) {
      this.isScrolled = shouldBeScrolled

      if (!this.isHovered || shouldBeScrolled) {
        this.updateHeaderBackground(shouldBeScrolled)
      }
    }
  }

  extractBannerImage() {
    if (this.hasBannerUrlValue && this.bannerUrlValue) {
      this.bannerImageUrl = this.bannerUrlValue
    } else {
      this.bannerImageUrl = null
    }

    this.initializeBrandHeaderState()
  }

  initializeBrandHeaderState() {
    if (this.headerTarget && this.navTarget) {
      if (this.bannerImageUrl) {
        this.setMatchingBackground('image', this.bannerImageUrl)
      } else {
        this.setMatchingBackground('gradient')
      }
    }
  }

  setMatchingBackground(type, imageUrl = null) {
    this.clearElementStyles(this.headerTarget)
    this.clearElementStyles(this.navTarget)

    if (type === 'image' && imageUrl) {
      this.applyImageBackground(this.headerTarget, imageUrl)
      this.applyImageBackground(this.navTarget, imageUrl)
    } else if (type === 'gradient') {
      const gradient = 'linear-gradient(to right, rgb(249, 250, 251), rgb(243, 244, 246))'
      this.headerTarget.style.background = gradient
      this.navTarget.style.background = gradient
    } else {
      this.headerTarget.style.transition = 'none'
      this.navTarget.style.transition = 'none'
      this.headerTarget.classList.add('bg-transparent')
      this.navTarget.classList.add('bg-transparent')
      setTimeout(() => {
        this.headerTarget.style.transition = ''
        this.navTarget.style.transition = ''
      }, 50)
    }
  }

  clearElementStyles(element) {
    element.classList.remove('bg-white', 'bg-transparent', 'bg-black/30')
    element.style.backgroundImage = 'none'
    element.style.background = ''
    element.style.backgroundColor = ''
    element.style.backdropFilter = 'none'
    element.style.webkitBackdropFilter = 'none'
    element.style.opacity = ''
    element.style.filter = ''
  }

  applyImageBackground(element, imageUrl) {
    element.style.backgroundImage = `url('${imageUrl}')`
    element.style.backgroundSize = 'cover'
    element.style.backgroundPosition = 'center center'
    element.style.backgroundRepeat = 'no-repeat'
    element.style.backgroundAttachment = 'fixed'
    element.style.transition = 'none'
  }

  initializeHeaderState() {
    if (this.headerTarget && this.navTarget) {
      this.headerTarget.classList.add('bg-transparent')
      this.navTarget.classList.add('bg-transparent')
      this.headerTarget.classList.remove('bg-white')
      this.navTarget.classList.remove('bg-white')
    }
  }


  updateHeaderBackground(shouldShowWhite) {
    if (!this.headerTarget || !this.navTarget) return

    if (shouldShowWhite) {
      this.headerTarget.style.transition = 'none'
      this.navTarget.style.transition = 'none'
      this.clearElementStyles(this.headerTarget)
      this.clearElementStyles(this.navTarget)
      this.headerTarget.classList.add('bg-white')
      this.navTarget.classList.add('bg-white')
      setTimeout(() => {
        this.headerTarget.style.transition = ''
        this.navTarget.style.transition = ''
      }, 50)
    } else {
      this.headerTarget.classList.remove('bg-white')
      this.navTarget.classList.remove('bg-white')

      if (this.pageTypeValue === 'brand') {
        const backgroundType = this.bannerImageUrl ? 'image' : 'gradient'
        this.setMatchingBackground(backgroundType, this.bannerImageUrl)
      } else {
        this.setMatchingBackground('transparent')
      }
    }
  }

  selectLocation(event) {
    event.preventDefault()
    // TODO: Open location selection modal
  }

  openSearch(event) {
    event.preventDefault()
    // TODO: Open search modal
  }

  openFavorites(event) {
    event.preventDefault()
    // TODO: Open favorites modal
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
}
