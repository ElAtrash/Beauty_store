import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["signinForm", "signupForm", "tabButton"]
  static classes = ["hidden", "active"]
  static values = {
    activeTab: { type: String, default: "signin" },
    tabs: { type: Array, default: ["signin", "signup"] }
  }

  connect() {
    this.setupInitialState()
    this.updateTabState(this.activeTabValue)
  }

  disconnect() { }

  setupInitialState() {
    if (this.hasTabButtonTarget) {
      this.tabButtonTargets.forEach(button => {
        button.setAttribute('role', 'tab')
        button.setAttribute('aria-selected', 'false')
      })
    }

    if (this.hasSigninFormTarget) {
      this.signinFormTarget.setAttribute('role', 'tabpanel')
      this.signinFormTarget.setAttribute('aria-labelledby', 'signin-tab')
    }
    if (this.hasSignupFormTarget) {
      this.signupFormTarget.setAttribute('role', 'tabpanel')
      this.signupFormTarget.setAttribute('aria-labelledby', 'signup-tab')
    }
  }

  switchTab(event) {
    event.preventDefault()
    const targetTab = event.target.dataset.tab
    if (targetTab === this.activeTabValue) return

    this.activeTabValue = targetTab
    this.updateTabState(targetTab)
    this.dispatch('tabChanged', { detail: { activeTab: targetTab } })
  }

  updateTabState(tabName) {
    this.element.dataset.authTab = tabName

    if (this.hasSigninFormTarget && this.hasSignupFormTarget) {
      const hiddenClass = this.hasHiddenClass ? this.hiddenClass : 'hidden'

      this.signinFormTarget.classList.toggle(hiddenClass, tabName !== 'signin')
      this.signupFormTarget.classList.toggle(hiddenClass, tabName !== 'signup')

      this.signinFormTarget.setAttribute('aria-hidden', (tabName !== 'signin').toString())
      this.signupFormTarget.setAttribute('aria-hidden', (tabName !== 'signup').toString())
    }

    this.updateTabButtonStates(tabName)
    this.manageFocus(tabName)
  }

  updateTabButtonStates(activeTab) {
    if (this.hasTabButtonTarget) {
      const activeClass = this.hasActiveClass ? this.activeClass : 'active'

      this.tabButtonTargets.forEach(button => {
        const buttonTab = button.dataset.tab
        const isActive = buttonTab === activeTab

        button.classList.toggle(activeClass, isActive)
        button.setAttribute('aria-selected', isActive.toString())
        button.setAttribute('tabindex', isActive ? '0' : '-1')
      })
    }
  }

  manageFocus(tabName) {
    const activeForm = tabName === 'signin' ? this.signinFormTarget : this.signupFormTarget

    if (activeForm) {
      const firstInput = activeForm.querySelector('input:not([type="hidden"])')
      if (firstInput) {
        requestAnimationFrame(() => { firstInput.focus() })
      }
    }
  }

  // Keyboard navigation support
  handleKeydown(event) {
    if (!this.hasTabButtonTarget) return

    const currentTab = event.target
    const isTabButton = this.tabButtonTargets.includes(currentTab)

    if (!isTabButton) return

    let targetButton = null

    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault()
        targetButton = this.getPreviousTab(currentTab)
        break
      case 'ArrowRight':
      case 'ArrowDown':
        event.preventDefault()
        targetButton = this.getNextTab(currentTab)
        break
      case 'Home':
        event.preventDefault()
        targetButton = this.tabButtonTargets[0]
        break
      case 'End':
        event.preventDefault()
        targetButton = this.tabButtonTargets[this.tabButtonTargets.length - 1]
        break
    }

    if (targetButton) {
      const targetTab = targetButton.dataset.tab
      this.activeTabValue = targetTab
      this.updateTabState(targetTab)
      targetButton.focus()
      this.dispatch('tabChanged', { detail: { activeTab: targetTab } })
    }
  }

  getPreviousTab(currentTab) {
    const currentIndex = this.tabButtonTargets.indexOf(currentTab)
    const prevIndex = currentIndex > 0 ? currentIndex - 1 : this.tabButtonTargets.length - 1
    return this.tabButtonTargets[prevIndex]
  }

  getNextTab(currentTab) {
    const currentIndex = this.tabButtonTargets.indexOf(currentTab)
    const nextIndex = currentIndex < this.tabButtonTargets.length - 1 ? currentIndex + 1 : 0
    return this.tabButtonTargets[nextIndex]
  }
}
