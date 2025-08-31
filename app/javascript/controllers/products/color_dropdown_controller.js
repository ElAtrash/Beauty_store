import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "selectedColor", "selectedText", "hiddenInput", "arrow"]
  static values = {
    selectedValue: String,
    selectedName: String,
    selectedColorHex: String,
    placeholder: String
  }

  static CLASSES = {
    MENU_OPEN: ['opacity-100', 'pointer-events-auto', 'scale-100'],
    MENU_CLOSED: ['opacity-0', 'pointer-events-none', 'scale-95'],
    ARROW_OPEN: 'rotate-180',
    PLACEHOLDER: 'color-circle--placeholder'
  }

  get placeholderText() {
    return this.placeholderValue || 'Select a shade'
  }

  get isOpen() {
    return this.menuTarget.classList.contains(this.constructor.CLASSES.MENU_OPEN[0])
  }

  connect() {
    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)

    document.addEventListener("click", this.handleDocumentClick)
    this.element.addEventListener("keydown", this.handleKeydown)

    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.buttonTarget.setAttribute('aria-haspopup', 'listbox')

    if (this.selectedValueValue) {
      this.selectedColorHexValue = this.selectedColorHexValue || this.selectedValueValue
      this.updateSelection(this.selectedValueValue, this.selectedNameValue, this.selectedColorHexValue)
    }
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove(...this.constructor.CLASSES.MENU_CLOSED)
    this.menuTarget.classList.add(...this.constructor.CLASSES.MENU_OPEN)
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.add(this.constructor.CLASSES.ARROW_OPEN)
    }

    this.buttonTarget.setAttribute('aria-expanded', 'true')
    this.menuTarget.setAttribute('role', 'listbox')

    this.showPlaceholder()
  }

  close() {
    this.menuTarget.classList.add(...this.constructor.CLASSES.MENU_CLOSED)
    this.menuTarget.classList.remove(...this.constructor.CLASSES.MENU_OPEN)
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.remove(this.constructor.CLASSES.ARROW_OPEN)
    }

    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.menuTarget.removeAttribute('role')

    this.restoreSelection()
  }

  selectColor(event) {
    event.preventDefault()
    const { value, name, colorHex } = event.currentTarget.dataset

    this.updateSelection(value, name, colorHex)
    this.close()

    this.buttonTarget.focus()

    this.hiddenInputTarget.dispatchEvent(new Event('input', { bubbles: true }))
    this.hiddenInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  updateSelection(value, name, colorHex = null) {
    this.hiddenInputTarget.value = value
    this.selectedTextTarget.textContent = name

    if (this.hasSelectedColorTarget && (colorHex || value)) {
      const color = colorHex || value
      this.selectedColorTarget.style.setProperty('--selected-color', color.toLowerCase())
    }

    this.selectedValueValue = value
    this.selectedNameValue = name
    this.selectedColorHexValue = colorHex || value
  }

  handleDocumentClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    switch (event.key) {
      case 'Escape':
        if (this.isOpen) {
          event.preventDefault()
          this.close()
        }
        break
      case 'Enter':
      case ' ':
        if (event.target === this.buttonTarget) {
          event.preventDefault()
          this.toggle(event)
        }
        break
    }
  }

  showPlaceholder() {
    this.selectedTextTarget.textContent = this.placeholderText

    if (this.hasSelectedColorTarget) {
      this.selectedColorTarget.classList.add(this.constructor.CLASSES.PLACEHOLDER)
      this.selectedColorTarget.style.removeProperty('--selected-color')
    }
  }

  restoreSelection() {
    if (this.selectedValueValue) {
      this.selectedTextTarget.textContent = this.selectedNameValue

      if (this.hasSelectedColorTarget) {
        this.selectedColorTarget.classList.remove(this.constructor.CLASSES.PLACEHOLDER)
        const color = this.selectedColorHexValue || this.selectedValueValue
        this.selectedColorTarget.style.setProperty('--selected-color', color.toLowerCase())
      }
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    this.element.removeEventListener("keydown", this.handleKeydown)
  }
}
