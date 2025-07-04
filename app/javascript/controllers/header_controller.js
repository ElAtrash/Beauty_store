import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="header"
export default class extends Controller {
  static targets = ["locationSelector", "searchBtn", "favoritesBtn", "profileBtn", "cartBtn", "mobileMenuToggle"]

  connect() {
    console.log("Header controller connected")
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

    const languageText = event.target.textContent.trim()
    let targetLocale = 'en'

    if (languageText === 'العربية') {
      targetLocale = 'ar'
    } else if (languageText === 'EN') {
      targetLocale = 'en'
    }

    console.log('Switching language to:', targetLocale)

    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/set_locale'

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
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
}
