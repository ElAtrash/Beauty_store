import { Controller } from "@hotwired/stimulus"
import { TimeoutMixin } from "mixins/timeout_mixin"

export default class extends Controller {
  static targets = [
    "container",
    "slider",
    "fill",
    "minInput",
    "maxInput",
    "minDisplay",
    "maxDisplay"
  ]

  static values = {
    debounceDelay: { type: Number, default: 50 }
  }

  disconnect() {
    this.clearCurrentTimeout()
  }

  connect() {
    Object.assign(this, TimeoutMixin)
    this.initializeTimeout()
    
    this.initialize()
  }

  initialize() {
    if (!this.hasContainerTarget) return

    this.setRangeLimits()
    this.setCurrentValues()
    this.updateDisplay()
    this.scheduleRangeUpdate()
  }

  updateRange() {
    if (!this.hasMinInputTarget || !this.hasMaxInputTarget) return

    const { minVal, maxVal, min, max } = this.getConstrainedValues()

    this.handleRangeConflicts(minVal, maxVal, min, max)
    this.updateZIndex(minVal, maxVal, min, max)
    this.updateDisplay()
    this.notifyChange()
  }

  reset() {
    if (this.hasMinInputTarget && this.hasMaxInputTarget) {
      this.minInputTarget.value = this.minInputTarget.min
      this.maxInputTarget.value = this.maxInputTarget.max
      this.updateDisplay()
    }
  }

  getCurrentValues() {
    return {
      min: this.hasMinInputTarget ? this.minInputTarget.value : null,
      max: this.hasMaxInputTarget ? this.maxInputTarget.value : null
    }
  }

  getCurrentRange() {
    return this.getCurrentValues()
  }

  hasChangedFromDefault() {
    if (!this.hasContainerTarget || !this.hasMinInputTarget || !this.hasMaxInputTarget) return false

    const container = this.containerTarget
    const defaultMin = container.dataset.min
    const defaultMax = container.dataset.max
    const currentMin = this.minInputTarget.value
    const currentMax = this.maxInputTarget.value

    return currentMin !== defaultMin || currentMax !== defaultMax
  }

  initializeFromURL() {
    const params = new URLSearchParams(window.location.search)
    let minFromURL = null
    let maxFromURL = null

    params.forEach((value, key) => {
      if (key === 'filters[price_range][min]') {
        minFromURL = value
      } else if (key === 'filters[price_range][max]') {
        maxFromURL = value
      }
    })

    if (minFromURL !== null || maxFromURL !== null) {
      this.setValues(minFromURL, maxFromURL)
    } else {
      this.initialize()
    }
  }

  setValues(min, max) {
    if (this.hasMinInputTarget && min !== null) {
      this.minInputTarget.value = min
    }
    if (this.hasMaxInputTarget && max !== null) {
      this.maxInputTarget.value = max
    }
    this.updateDisplay()
  }

  setRangeLimits() {
    const container = this.containerTarget
    const dataMin = container.dataset.min
    const dataMax = container.dataset.max

    if (this.hasMinInputTarget && this.hasMaxInputTarget) {
      if (dataMin) {
        this.minInputTarget.min = dataMin
        this.maxInputTarget.min = dataMin
      }
      if (dataMax) {
        this.minInputTarget.max = dataMax
        this.maxInputTarget.max = dataMax
      }
    }
  }

  setCurrentValues() {
    const container = this.containerTarget
    const dataCurrentMin = container.dataset.currentMin
    const dataCurrentMax = container.dataset.currentMax

    if (this.hasMinInputTarget && this.hasMaxInputTarget) {
      this.minInputTarget.value = dataCurrentMin || this.minInputTarget.min
      this.maxInputTarget.value = dataCurrentMax || this.maxInputTarget.max
    }
  }

  getConstrainedValues() {
    let minVal = parseInt(this.minInputTarget.value)
    let maxVal = parseInt(this.maxInputTarget.value)
    const min = parseInt(this.minInputTarget.min)
    const max = parseInt(this.maxInputTarget.max)

    minVal = Math.max(min, Math.min(max, minVal))
    maxVal = Math.max(min, Math.min(max, maxVal))

    return { minVal, maxVal, min, max }
  }

  handleRangeConflicts(minVal, maxVal, min, max) {
    if (minVal >= maxVal) {
      if (this.minInputTarget === document.activeElement) {
        maxVal = Math.min(max, minVal + 1)
        this.maxInputTarget.value = maxVal
      } else {
        minVal = Math.max(min, maxVal - 1)
        this.minInputTarget.value = minVal
      }
    } else {
      this.minInputTarget.value = minVal
      this.maxInputTarget.value = maxVal
    }
  }

  updateZIndex(minVal, maxVal, min, max) {
    const range = max - min
    const gap = maxVal - minVal

    if (gap < range * 0.1) {
      this.minInputTarget.style.zIndex = '4'
      this.maxInputTarget.style.zIndex = '3'
    } else {
      this.minInputTarget.style.zIndex = '1'
      this.maxInputTarget.style.zIndex = '2'
    }
  }

  updateDisplay() {
    if (!this.hasMinInputTarget || !this.hasMaxInputTarget) return

    const minVal = parseInt(this.minInputTarget.value)
    const maxVal = parseInt(this.maxInputTarget.value)
    const min = parseInt(this.minInputTarget.min)
    const max = parseInt(this.maxInputTarget.max)

    this.updatePriceDisplay(minVal, maxVal)
    this.updateSliderFill(minVal, maxVal, min, max)
  }

  updatePriceDisplay(minVal, maxVal) {
    if (this.hasMinDisplayTarget) {
      this.minDisplayTarget.textContent = `$${minVal}`
    }
    if (this.hasMaxDisplayTarget) {
      this.maxDisplayTarget.textContent = `$${maxVal}`
    }
  }

  updateSliderFill(minVal, maxVal, min, max) {
    if (this.hasFillTarget) {
      const leftPercent = ((minVal - min) / (max - min)) * 100
      const rightPercent = ((maxVal - min) / (max - min)) * 100

      this.fillTarget.style.left = `${leftPercent}%`
      this.fillTarget.style.width = `${rightPercent - leftPercent}%`
    }
  }

  scheduleRangeUpdate() {
    this.setTimeoutWithCleanup(() => {
      this.updateRange()
    }, this.debounceDelayValue)
  }

  notifyChange() {
    this.dispatch("changed", {
      detail: this.getCurrentValues(),
      bubbles: true
    })
  }
}
