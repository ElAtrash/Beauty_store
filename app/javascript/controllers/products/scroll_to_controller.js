import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  smoothScroll(event) {
    event.preventDefault()

    const href = event.currentTarget.getAttribute('href')
    const targetId = href.substring(1) // Remove the # symbol
    const targetElement = document.getElementById(targetId)

    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }
  }
}
