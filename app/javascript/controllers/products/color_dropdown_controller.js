import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "selectedColor", "selectedText", "hiddenInput", "arrow"]
  static values = {
    selectedValue: String,
    selectedName: String
  }

  actualSelection = {
    value: null,
    name: null,
    colorHex: null
  }

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)

    // Set initial selection if provided
    if (this.selectedValueValue) {
      this.updateSelection(this.selectedValueValue, this.selectedNameValue)
      // Store the initial selection
      this.actualSelection = {
        value: this.selectedValueValue,
        name: this.selectedNameValue,
        colorHex: this.selectedValueValue
      }
    }
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
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.add("rotate-180")
    }

    this.showPlaceholder()

    document.addEventListener("click", this.closeOnClickOutside)
  }

  close() {
    this.menuTarget.classList.add("opacity-0", "pointer-events-none", "scale-95")
    this.menuTarget.classList.remove("opacity-100", "pointer-events-auto", "scale-100")
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.remove("rotate-180")
    }

    this.restoreSelection()

    document.removeEventListener("click", this.closeOnClickOutside)
  }

  selectColor(event) {
    event.preventDefault()
    const option = event.currentTarget
    const value = option.dataset.value
    const name = option.dataset.name
    const colorHex = option.dataset.colorHex

    this.actualSelection = { value, name, colorHex }

    this.updateSelection(value, name, colorHex)
    this.close()

    this.hiddenInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  updateSelection(value, name, colorHex = null) {
    this.hiddenInputTarget.value = value
    this.selectedTextTarget.textContent = name

    // Update color circle if we have color info
    if (this.hasSelectedColorTarget && (colorHex || value)) {
      const color = colorHex || value
      this.selectedColorTarget.style.backgroundColor = color.toLowerCase()

      // Handle white/light colors with border
      if (color.toLowerCase() === 'white' || color.toLowerCase() === '#ffffff' || color.toLowerCase() === '#fff') {
        this.selectedColorTarget.classList.add('border', 'border-gray-300')
        this.selectedColorTarget.style.backgroundColor = 'white'
      } else {
        this.selectedColorTarget.classList.remove('border', 'border-gray-300')
      }
    }

    // Update selection values
    this.selectedValueValue = value
    this.selectedNameValue = name
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  showPlaceholder() {
    this.selectedTextTarget.textContent = "Select a shade"

    if (this.hasSelectedColorTarget) {
      this.selectedColorTarget.style.backgroundColor = "transparent"
      this.selectedColorTarget.style.border = "2px dashed #d1d5db"
    }
  }

  restoreSelection() {
    if (this.actualSelection.value) {
      this.selectedTextTarget.textContent = this.actualSelection.name

      if (this.hasSelectedColorTarget) {
        const color = this.actualSelection.colorHex || this.actualSelection.value
        this.selectedColorTarget.style.backgroundColor = color.toLowerCase()
        this.selectedColorTarget.style.border = "1px solid rgb(229 231 235)"

        // Handle white/light colors with border
        if (color.toLowerCase() === 'white' || color.toLowerCase() === '#ffffff' || color.toLowerCase() === '#fff') {
          this.selectedColorTarget.style.border = "1px solid #d1d5db"
          this.selectedColorTarget.style.backgroundColor = 'white'
        }
      }
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }
}
