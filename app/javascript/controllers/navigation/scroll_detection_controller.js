import { Controller } from "@hotwired/stimulus"
import { throttle } from "utilities"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 10 }
  }

  connect() {
    this.isScrolled = false
    this.setupScrollListener()
  }

  disconnect() {
    this.removeScrollListener()
  }

  setupScrollListener() {
    this.handleScroll = throttle(this.handleScroll.bind(this), 16) // ~60fps
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  }

  removeScrollListener() {
    if (this.handleScroll) {
      window.removeEventListener('scroll', this.handleScroll)
    }
  }

  handleScroll() {
    const shouldBeScrolled = window.scrollY > this.thresholdValue

    if (shouldBeScrolled !== this.isScrolled) {
      this.isScrolled = shouldBeScrolled

      // Emit custom events for other controllers to listen to
      this.dispatch('scroll-state-changed', {
        detail: {
          isScrolled: this.isScrolled,
          scrollY: window.scrollY,
          threshold: this.thresholdValue
        }
      })

      // Also dispatch specific events
      if (this.isScrolled) {
        this.dispatch('scrolledPastThreshold', {
          detail: { scrollY: window.scrollY }
        })
      } else {
        this.dispatch('scrolledAboveThreshold', {
          detail: { scrollY: window.scrollY }
        })
      }
    }
  }
}
