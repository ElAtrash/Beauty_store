import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "current"]
  static values = { max: Number }

  connect() {
    this.enforceMaxLength()
    this.updateCounter()
  }

  inputTargetConnected() {
    this.enforceMaxLength()
    this.updateCounter()
  }

  enforceMaxLength() {
    if (this.hasInputTarget && this.hasMaxValue) {
      this.inputTarget.setAttribute('maxlength', this.maxValue)
    }
  }

  updateCounter() {
    if (!this.hasInputTarget || !this.hasCurrentTarget) return

    const currentLength = this.inputTarget.value.length
    this.currentTarget.textContent = currentLength
  }

  input() {
    this.enforceInputLimit()
    this.updateCounter()
  }

  paste() {
    requestAnimationFrame(() => {
      this.enforceInputLimit()
      this.updateCounter()
    })
  }

  cut() { requestAnimationFrame(() => this.updateCounter()) }

  enforceInputLimit() {
    if (!this.hasInputTarget || !this.hasMaxValue) return

    if (this.inputTarget.value.length > this.maxValue) {
      this.inputTarget.value = this.inputTarget.value.substring(0, this.maxValue)
      this.dispatch('limitReached', {
        detail: {
          maxLength: this.maxValue,
          currentLength: this.inputTarget.value.length
        }
      })
    }
  }
}
