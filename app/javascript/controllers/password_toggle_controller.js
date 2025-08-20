import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "button"]
  static values = {
    showIconPath: String,
    hideIconPath: String
  }

  toggle() {
    const field = this.fieldTarget
    const button = this.buttonTarget

    if (field.type === "password") {
      field.type = "text"
      button.innerHTML = this.buildIcon(this.hideIconPathValue)
    } else {
      field.type = "password"
      button.innerHTML = this.buildIcon(this.showIconPathValue)
    }
  }

  buildIcon(path) {
    return `<svg class="w-5 h-5 text-subtle" fill="none" stroke="currentColor" viewBox="0 0 24 24">${path}</svg>`
  }
}
