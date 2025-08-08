import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "arrow", "selectedText"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const isOpen = this.menuTarget.classList.contains("opacity-100")

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("opacity-0", "pointer-events-none", "scale-95")
    this.menuTarget.classList.add("opacity-100", "pointer-events-auto", "scale-100")
    this.arrowTarget.classList.add("rotate-180")
    document.addEventListener("click", this.closeOnClickOutside)
  }

  close() {
    this.menuTarget.classList.add("opacity-0", "pointer-events-none", "scale-95")
    this.menuTarget.classList.remove("opacity-100", "pointer-events-auto", "scale-100")
    this.arrowTarget.classList.remove("rotate-180")
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  selectOption(event) {
    event.preventDefault()
    const value = event.currentTarget.dataset.value
    const text = event.currentTarget.textContent.trim()

    this.selectedTextTarget.textContent = text
    this.close()

    const currentUrl = new URL(window.location)
    const params = new URLSearchParams(currentUrl.search)
    params.set('sort_by', value)

    const newUrl = `${currentUrl.pathname}?${params.toString()}`

    const turboFrame = document.querySelector(`[id^="brand_products_"]`)
    if (turboFrame) {
      window.history.pushState({}, '', newUrl)
      turboFrame.src = newUrl
    } else {
      window.location.href = newUrl
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }
}
