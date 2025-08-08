import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submit() {
    // Preserve existing URL parameters when submitting the form
    const form = this.formTarget
    const currentUrl = new URL(window.location)

    const formData = new FormData(form)

    const newParams = new URLSearchParams(currentUrl.search)

    // Update only the form parameters, preserving existing ones
    for (const [key, value] of formData) {
      if (key === 'sort_by') {
        newParams.set(key, value)
      }
    }

    // Build the new URL
    const newUrl = `${currentUrl.pathname}?${newParams.toString()}`

    // Update the form action to include all parameters
    form.action = newUrl

    this.formTarget.requestSubmit()
  }
}
