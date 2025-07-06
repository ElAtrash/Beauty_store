import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot"]

  connect() {
    this.currentSlide = 0
    this.totalSlides = this.slideTargets.length
    this.autoplayInterval = null
    this.autoplayDelay = 5000

    this.startAutoplay()
    this.updateDots()
  }

  disconnect() {
    this.stopAutoplay()
  }

  startAutoplay() {
    this.autoplayInterval = setInterval(() => {
      this.nextSlide()
    }, this.autoplayDelay)
  }

  stopAutoplay() {
    if (this.autoplayInterval) {
      clearInterval(this.autoplayInterval)
      this.autoplayInterval = null
    }
  }

  restartAutoplay() {
    this.stopAutoplay()
    this.startAutoplay()
  }

  nextSlide() {
    this.currentSlide = (this.currentSlide + 1) % this.totalSlides
    this.showSlide(this.currentSlide)
  }

  previousSlide() {
    this.currentSlide = (this.currentSlide - 1 + this.totalSlides) % this.totalSlides
    this.showSlide(this.currentSlide)
  }

  goToSlide(event) {
    const slideIndex = parseInt(event.currentTarget.dataset.slideIndex)
    this.currentSlide = slideIndex
    this.showSlide(this.currentSlide)
  }

  showSlide(index) {
    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('opacity-0')
        slide.classList.add('opacity-100')
      } else {
        slide.classList.remove('opacity-100')
        slide.classList.add('opacity-0')
      }
    })

    this.updateDots()

    this.restartAutoplay()
  }

  updateDots() {
    this.dotTargets.forEach((dot, i) => {
      if (i === this.currentSlide) {
        dot.classList.remove('bg-white/30')
        dot.classList.add('bg-white/60')
      } else {
        dot.classList.remove('bg-white/60')
        dot.classList.add('bg-white/30')
      }
    })
  }

  pauseOnHover() {
    this.stopAutoplay()
  }

  resumeOnLeave() {
    this.startAutoplay()
  }
}
