import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["truncated", "expanded"]

  connect() {
    this.isExpanded = false
  }

  toggle() {
    this.isExpanded = !this.isExpanded
    
    if (this.isExpanded) {
      // Show full text
      this.truncatedTarget.classList.add("hidden")
      this.expandedTarget.classList.remove("hidden")
    } else {
      // Show truncated text
      this.truncatedTarget.classList.remove("hidden")
      this.expandedTarget.classList.add("hidden")
    }
  }
}