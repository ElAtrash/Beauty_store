import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]
  static values = {
    id: String,
    backdropClose: { type: Boolean, default: true },
    position: String,
    animationDuration: { type: Number, default: 300 }
  }

  connect() {
    this.isOpen = false
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleFocusIn = this.handleFocusIn.bind(this)
    this.cachedPosition = this.positionValue || this.detectPosition()
    this.setupInitialState()
    this.element.addEventListener('focusin', this.boundHandleFocusIn)
  }

  disconnect() {
    this.removeBodyScrollLock()
    document.removeEventListener('keydown', this.boundHandleKeydown)
    this.element.removeEventListener('focusin', this.boundHandleFocusIn)
  }

  open(event) {
    if (event) { event.preventDefault() }
    if (this.isOpen) { return }

    this.isOpen = true
    this.updateModalState()
    this.addBodyScrollLock()
    this.setupFocusTrap()

    document.addEventListener('keydown', this.boundHandleKeydown)

    this.dispatch('opened', { detail: { modalId: this.idValue }, bubbles: true })
  }

  close(event) {
    if (event) { event.preventDefault() }

    if (!this.isOpen) return

    this.isOpen = false
    this.updateModalState()
    this.removeBodyScrollLock()

    document.removeEventListener('keydown', this.boundHandleKeydown)

    this.dispatch('closed', {
      detail: { modalId: this.idValue },
      bubbles: true
    })
  }

  toggle(event) {
    if (this.isOpen) {
      this.close(event)
    } else {
      this.open(event)
    }
  }

  closeOnBackdrop(event) {
    if (this.backdropCloseValue && event.target === event.currentTarget) {
      this.close(event)
    }
  }

  handleKeydown(event) {
    if (!this.isOpen) return

    switch (event.key) {
      case 'Escape':
        this.close(event)
        break
      case 'Tab':
        this.handleTabNavigation(event)
        break
    }
  }

  handleFocusIn(event) {
    if (!this.isOpen && this.element.contains(event.target)) {
      if (this.previousFocus && this.previousFocus !== event.target) {
        this.previousFocus.focus()
      } else {
        const safeElement = this.findSafeFocusElement()
        if (safeElement) {
          safeElement.focus()
        }
      }
    }
  }

  findSafeFocusElement() {
    const focusableSelector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    const allFocusable = Array.from(document.querySelectorAll(focusableSelector))

    return allFocusable.find(element =>
      !this.element.contains(element) &&
      !element.disabled &&
      element.offsetParent !== null
    )
  }

  setupInitialState() {
    this.element.dataset.modal = 'closed'
    this.previousFocus = null
    this.element.setAttribute('aria-hidden', 'true')
  }

  updateModalState() {
    if (this.isOpen) {
      this.element.setAttribute('aria-hidden', 'false')
      this.element.classList.remove('modal-closed')
      this.element.classList.add('modal-open')

      this.setPanelPosition(false)

      requestAnimationFrame(() => {
        if (this.hasOverlayTarget) {
          this.overlayTarget.classList.add('opacity-100', 'visible', 'pointer-events-auto')
          this.overlayTarget.classList.remove('opacity-0', 'invisible', 'pointer-events-none')
        }
        this.setPanelPosition(true)
      })
    } else {
      this.clearModalFocus()

      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.remove('opacity-100', 'visible', 'pointer-events-auto')
        this.overlayTarget.classList.add('opacity-0', 'invisible', 'pointer-events-none')
      }

      this.setPanelPosition(false)
      this.element.setAttribute('aria-hidden', 'true')

      setTimeout(() => {
        this.element.classList.remove('modal-open')
        this.element.classList.add('modal-closed')
      }, this.animationDurationValue)
    }
  }

  setupFocusTrap() {
    this.previousFocus = document.activeElement

    const firstFocusable = this.getFirstFocusableElement()
    if (firstFocusable) {
      requestAnimationFrame(() => firstFocusable.focus())
    }
  }

  restoreFocus() {
    if (this.previousFocus && this.previousFocus.focus) {
      this.previousFocus.focus()
      this.previousFocus = null
    }
  }

  clearModalFocus() {
    const activeElement = document.activeElement

    if (activeElement && this.element.contains(activeElement)) {
      activeElement.blur()
    }

    this.restoreFocus()
  }

  addBodyScrollLock() {
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth
    document.body.style.paddingRight = `${scrollbarWidth}px`
    document.body.style.overflow = 'hidden'
    document.body.classList.add('modal-open')
  }

  removeBodyScrollLock() {
    document.body.style.overflow = ''
    document.body.style.paddingRight = ''
    document.body.classList.remove('modal-open')
  }

  handleTabNavigation(event) {
    const focusableElements = this.getFocusableElements()
    if (focusableElements.length === 0) return

    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]

    if (event.shiftKey && document.activeElement === firstElement) {
      event.preventDefault()
      lastElement.focus()
    } else if (!event.shiftKey && document.activeElement === lastElement) {
      event.preventDefault()
      firstElement.focus()
    }
  }

  getFocusableElements() {
    if (!this.hasPanelTarget) return []

    const selector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    return Array.from(this.panelTarget.querySelectorAll(selector)).filter(element => {
      return !element.disabled && element.offsetParent !== null
    })
  }

  getFirstFocusableElement() {
    return this.getFocusableElements()[0]
  }

  getModalPosition() {
    return this.cachedPosition
  }

  detectPosition() {
    if (!this.element) return 'right'

    if (this.element.classList.contains('left-0')) return 'left'
    if (this.element.classList.contains('right-0')) return 'right'
    if (this.element.classList.contains('left-1/2')) return 'center'

    return 'right'
  }

  setPanelPosition(isOpening) {
    if (!this.hasPanelTarget) return

    const position = this.getModalPosition()
    const { openClasses, closedClasses } = this.getPositionClasses(position)

    if (isOpening) {
      this.panelTarget.classList.remove(...closedClasses)
      this.panelTarget.classList.add(...openClasses)
    } else {
      this.panelTarget.classList.remove(...openClasses)
      this.panelTarget.classList.add(...closedClasses)
    }
  }

  getPositionClasses(position) {
    switch (position) {
      case 'left':
        return {
          openClasses: ['translate-x-0'],
          closedClasses: ['-translate-x-full']
        }
      case 'right':
        return {
          openClasses: ['translate-x-0'],
          closedClasses: ['translate-x-full']
        }
      case 'center':
        return {
          openClasses: ['-translate-x-1/2', '-translate-y-1/2', 'scale-100'],
          closedClasses: ['-translate-x-1/2', '-translate-y-1/2', 'scale-95']
        }
      default:
        return {
          openClasses: ['translate-x-0'],
          closedClasses: ['translate-x-full']
        }
    }
  }
}
