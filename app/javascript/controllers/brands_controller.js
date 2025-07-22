import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput"]

  connect() {
    document.addEventListener('turbo:frame-load', this.handleFrameLoad.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad.bind(this))
  }

  handleFrameLoad(event) {
    if (event.target.id === 'brands-content') {
      const urlParams = new URLSearchParams(window.location.search)
      const letter = urlParams.get('letter')
      if (letter) {
        this.updateActiveStates(letter)
      }
    }
  }

  handleSearchInput(event) {
    const query = event.target.value.trim()

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    this.searchTimeout = setTimeout(() => {
      if (query.length >= 2 || query.length === 0) {
        event.target.closest('form').requestSubmit()
      }
    }, 300)
  }

  handleKeyboardNavigation(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      event.target.click()
    }
  }

  updateActiveStates(activeLetter) {
    const allLetterBtns = document.querySelectorAll('.alphabet-letter-btn')
    allLetterBtns.forEach(btn => {
      btn.classList.remove('active')
    })

    const activeBtn = document.querySelector(`[data-brands-letter-value="${activeLetter}"]`)
    if (activeBtn) {
      activeBtn.classList.add('active')
    }
  }
}
