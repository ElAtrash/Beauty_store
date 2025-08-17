import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "tabPanel"]
  static values = { activeIndex: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.activeIndexValue)
  }

  switchTab(event) {
    const index = parseInt(event.params.index)
    this.showTab(index)
  }

  showTab(index) {
    if (index < 0 || index >= this.tabButtonTargets.length) {
      return
    }

    this.activeIndexValue = index
    this.updateTabButtons(index)
    this.updateTabPanels(index)
    this.scrollToTabsIfNeeded()
  }

  updateTabButtons(activeIndex) {
    this.tabButtonTargets.forEach((button, index) => {
      if (index === activeIndex) {
        button.classList.remove("border-transparent", "text-gray-500")
        button.classList.add("border-black", "text-black")
      } else {
        button.classList.remove("border-black", "text-black")
        button.classList.add("border-transparent", "text-gray-500")
      }
    })
  }

  updateTabPanels(activeIndex) {
    this.tabPanelTargets.forEach((panel, index) => {
      if (index === activeIndex) {
        this.showPanel(panel)
      } else {
        this.hidePanel(panel)
      }
    })
  }

  showPanel(panel) {
    panel.classList.remove("hidden")
    panel.classList.add("block")

    // Add fade-in animation
    panel.style.opacity = "0"
    panel.style.transform = "translateY(10px)"

    // Trigger animation
    requestAnimationFrame(() => {
      panel.style.transition = "opacity 0.3s ease, transform 0.3s ease"
      panel.style.opacity = "1"
      panel.style.transform = "translateY(0)"
    })
  }

  hidePanel(panel) {
    panel.classList.remove("block")
    panel.classList.add("hidden")
    panel.style.opacity = ""
    panel.style.transform = ""
    panel.style.transition = ""
  }

  scrollToTabsIfNeeded() {
    if (window.innerWidth < 768) {
      const tabsContainer = this.element
      const rect = tabsContainer.getBoundingClientRect()

      if (rect.top < 0 || rect.top > window.innerHeight * 0.7) {
        tabsContainer.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        })
      }
    }
  }

  keydown(event) {
    if (!this.element.contains(event.target)) {
      return
    }

    let newIndex = this.activeIndexValue

    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault()
        newIndex = this.activeIndexValue > 0 ? this.activeIndexValue - 1 : this.tabButtonTargets.length - 1
        break
      case "ArrowRight":
        event.preventDefault()
        newIndex = this.activeIndexValue < this.tabButtonTargets.length - 1 ? this.activeIndexValue + 1 : 0
        break
      case "Home":
        event.preventDefault()
        newIndex = 0
        break
      case "End":
        event.preventDefault()
        newIndex = this.tabButtonTargets.length - 1
        break
      default:
        return
    }

    this.showTab(newIndex)
    this.tabButtonTargets[newIndex].focus()
  }

  resize() {
    this.showTab(this.activeIndexValue)
  }
}
