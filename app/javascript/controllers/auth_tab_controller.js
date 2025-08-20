import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    activeTab: { type: String, default: "signin" }
  }

  connect() {
    this.updateTabState(this.activeTabValue)
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
    const authContainer = this.element.closest('[data-navigation--auth-popup-target="panel"]') ||
      this.element.closest('.auth-sidebar') ||
      this.element

    if (authContainer) {
      authContainer.dataset.authTab = tabName
    }
  }
}
