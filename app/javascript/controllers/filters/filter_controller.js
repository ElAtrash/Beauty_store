import { Controller } from "@hotwired/stimulus"

// Configurable Filter Controller - Handles all filter functionality
// Works with different contexts (brand, product, search) and routes
export default class extends Controller {
  static targets = [
    "resetButton",
    "filterPopupOverlay",
    "filterPopupPanel",
    "priceRange",
    "rangeMin",
    "rangeMax",
    "minPriceDisplay",
    "maxPriceDisplay",
    "rangeFill"
  ]

  static values = {
    turboFrameId: String,
    context: String
  }

  connect() {
    this.currentFilters = {}
    this.initializeFromURL()
    this.initializePriceRange()
    this.updateResetButtonState()

    // Keyboard navigation
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown)
  }

  // Filter Popup Management
  openFilters() {
    document.body.style.overflow = 'hidden'

    // Re-sync form inputs when opening popup
    this.initializeFromURL()
    this.initializePriceRange()

    if (this.hasFilterPopupOverlayTarget && this.hasFilterPopupPanelTarget) {
      this.filterPopupOverlayTarget.classList.remove('opacity-0', 'pointer-events-none')
      this.filterPopupOverlayTarget.classList.add('opacity-100')

      this.filterPopupPanelTarget.classList.remove('-translate-x-full')
      this.filterPopupPanelTarget.classList.add('translate-x-0')
    }

    this.updateResetButtonState()
  }

  closeFilters() {
    document.body.style.overflow = ''

    if (this.hasFilterPopupOverlayTarget && this.hasFilterPopupPanelTarget) {
      this.filterPopupOverlayTarget.classList.add('opacity-0', 'pointer-events-none')
      this.filterPopupOverlayTarget.classList.remove('opacity-100')

      this.filterPopupPanelTarget.classList.add('-translate-x-full')
      this.filterPopupPanelTarget.classList.remove('translate-x-0')
    }
  }

  // Section Management
  toggleSection(event) {
    const button = event.currentTarget
    const sectionName = button.dataset.section
    const content = this.element.querySelector(`[data-section-content="${sectionName}"]`)
    const icon = button.querySelector('svg')

    if (!content || !icon) return

    const isExpanded = button.getAttribute('aria-expanded') === 'true'

    content.classList.toggle('hidden', isExpanded)
    button.setAttribute('aria-expanded', !isExpanded)
    icon.classList.toggle('rotate-180', !isExpanded)
  }

  // Filter Management
  updateFilter(event) {
    const filterType = event.target.dataset.filterType
    const input = event.target

    if (filterType === 'in_stock') {
      if (input.checked) {
        this.currentFilters[filterType] = 'true'
      } else {
        delete this.currentFilters[filterType]
      }
    } else {
      // Handle array filters (brands, colors, etc.)
      if (!this.currentFilters[filterType]) {
        this.currentFilters[filterType] = []
      }

      if (input.checked) {
        if (!this.currentFilters[filterType].includes(input.value)) {
          this.currentFilters[filterType].push(input.value)
        }
      } else {
        this.currentFilters[filterType] = this.currentFilters[filterType].filter(
          value => value !== input.value
        )
      }

      // Clean up empty arrays
      if (this.currentFilters[filterType].length === 0) {
        delete this.currentFilters[filterType]
      }
    }

    this.updateResetButtonState()
  }

  // Price Range Management
  updatePriceRange(event) {
    if (!this.hasRangeMinTarget || !this.hasRangeMaxTarget) return

    let minVal = parseInt(this.rangeMinTarget.value)
    let maxVal = parseInt(this.rangeMaxTarget.value)
    const min = parseInt(this.rangeMinTarget.min)
    const max = parseInt(this.rangeMaxTarget.max)

    // Constrain values
    minVal = Math.max(min, Math.min(max, minVal))
    maxVal = Math.max(min, Math.min(max, maxVal))

    // Handle overlapping sliders
    if (minVal >= maxVal) {
      if (this.rangeMinTarget === document.activeElement) {
        maxVal = Math.min(max, minVal + 1)
        this.rangeMaxTarget.value = maxVal
      } else {
        minVal = Math.max(min, maxVal - 1)
        this.rangeMinTarget.value = minVal
      }
    }

    // Update values
    this.rangeMinTarget.value = minVal
    this.rangeMaxTarget.value = maxVal

    // Update displays
    if (this.hasMinPriceDisplayTarget) {
      this.minPriceDisplayTarget.textContent = `$${minVal}`
    }
    if (this.hasMaxPriceDisplayTarget) {
      this.maxPriceDisplayTarget.textContent = `$${maxVal}`
    }

    // Update slider fill
    this.updateSliderFill(minVal, maxVal, min, max)
    this.updateResetButtonState()
  }

  updateSliderFill(minVal, maxVal, min, max) {
    if (!this.hasRangeFillTarget) return

    const leftPercent = ((minVal - min) / (max - min)) * 100
    const rightPercent = ((maxVal - min) / (max - min)) * 100

    this.rangeFillTarget.style.left = `${leftPercent}%`
    this.rangeFillTarget.style.width = `${rightPercent - leftPercent}%`
  }

  initializePriceRange() {
    if (!this.hasPriceRangeTarget || !this.hasRangeMinTarget || !this.hasRangeMaxTarget) return

    const container = this.priceRangeTarget
    const dataMin = container.dataset.min
    const dataMax = container.dataset.max
    const dataCurrentMin = container.dataset.currentMin
    const dataCurrentMax = container.dataset.currentMax

    // Set limits
    if (dataMin) {
      this.rangeMinTarget.min = dataMin
      this.rangeMaxTarget.min = dataMin
    }
    if (dataMax) {
      this.rangeMinTarget.max = dataMax
      this.rangeMaxTarget.max = dataMax
    }

    // Set current values - check URL first, then data attributes
    const urlFilters = this.getFiltersFromURL()
    let minValue = urlFilters.price_range?.min || dataCurrentMin || dataMin
    let maxValue = urlFilters.price_range?.max || dataCurrentMax || dataMax

    // Constrain values to valid bounds
    const actualMin = parseInt(dataMin)
    const actualMax = parseInt(dataMax)
    minValue = Math.max(actualMin, Math.min(actualMax, parseInt(minValue)))
    maxValue = Math.max(actualMin, Math.min(actualMax, parseInt(maxValue)))

    // Ensure min <= max
    if (minValue >= maxValue) {
      minValue = actualMin
      maxValue = actualMax
    }

    this.rangeMinTarget.value = minValue
    this.rangeMaxTarget.value = maxValue

    // Update displays
    if (this.hasMinPriceDisplayTarget) {
      this.minPriceDisplayTarget.textContent = `$${minValue}`
    }
    if (this.hasMaxPriceDisplayTarget) {
      this.maxPriceDisplayTarget.textContent = `$${maxValue}`
    }

    // Update slider fill
    this.updateSliderFill(
      parseInt(minValue),
      parseInt(maxValue),
      parseInt(dataMin),
      parseInt(dataMax)
    )
  }

  // Filter Actions
  applyFilters() {
    try {
      // Add current price range to filters
      if (this.hasRangeMinTarget && this.hasRangeMaxTarget) {
        this.currentFilters.price_range = {
          min: this.rangeMinTarget.value,
          max: this.rangeMaxTarget.value
        }
      }

      // Build URL with filter parameters
      const newUrl = this.buildFilterURL(this.currentFilters)

      // Update Turbo Frame
      this.updateTurboFrame(newUrl)
      this.closeFilters()
    } catch (error) {
      console.error('Error applying filters:', error)
    }
  }

  resetFilters() {
    try {
      // Reset checkboxes
      const inputs = this.element.querySelectorAll('input[type="checkbox"], input[type="radio"]')
      inputs.forEach(input => {
        input.checked = false
      })

      // Reset price range
      if (this.hasRangeMinTarget && this.hasRangeMaxTarget) {
        const minValue = this.rangeMinTarget.min
        const maxValue = this.rangeMaxTarget.max

        this.rangeMinTarget.value = minValue
        this.rangeMaxTarget.value = maxValue

        if (this.hasMinPriceDisplayTarget) {
          this.minPriceDisplayTarget.textContent = `$${minValue}`
        }
        if (this.hasMaxPriceDisplayTarget) {
          this.maxPriceDisplayTarget.textContent = `$${maxValue}`
        }

        // Update slider fill to show full range
        this.updateSliderFill(
          parseInt(minValue),
          parseInt(maxValue),
          parseInt(minValue),
          parseInt(maxValue)
        )
      }

      // Clear filters and navigate to clean URL
      this.currentFilters = {}
      const cleanUrl = window.location.pathname
      this.updateTurboFrame(cleanUrl)
      this.updateResetButtonState()
    } catch (error) {
      console.error('Error resetting filters:', error)
    }
  }

  // URL and State Management
  buildFilterURL(filters) {
    const url = new URL(window.location)
    const params = new URLSearchParams()

    Object.entries(filters).forEach(([key, value]) => {
      if (key === 'price_range' && value && typeof value === 'object') {
        // Clean price range: price=8-46
        if (value.min && value.max) {
          params.set('price', `${value.min}-${value.max}`)
        }
      } else if (key === 'in_stock' && value === 'true') {
        // Clean in-stock flag: stock=1
        params.set('stock', '1')
      } else if (Array.isArray(value) && value.length > 0) {
        // Clean arrays: type=lipstick,foundation
        const cleanKey = this.getCleanParamName(key)
        params.set(cleanKey, value.join(','))
      } else if (value !== null && value !== undefined && value !== '') {
        // Other single values with clean names
        const cleanKey = this.getCleanParamName(key)
        params.set(cleanKey, value)
      }
    })

    return `${url.pathname}?${params.toString()}`
  }

  getCleanParamName(key) {
    const paramMap = {
      'product_types': 'type',
      'skin_types': 'skin',
      'brands': 'brand',
      'colors': 'color',
      'sizes': 'size'
    }
    return paramMap[key] || key
  }

  updateTurboFrame(url) {
    // Use configured turbo frame ID or try to auto-detect
    const frameSelector = this.turboFrameIdValue ?
      `#${this.turboFrameIdValue}` :
      '[id^="brand_products_"], [id^="product_results_"], [id^="search_results_"]'

    const turboFrame = document.querySelector(frameSelector)
    if (turboFrame) {
      window.history.pushState({}, '', url)
      turboFrame.src = url
    }
  }

  getFiltersFromURL() {
    const filters = {}
    const params = new URLSearchParams(window.location.search)

    params.forEach((value, key) => {
      // Handle clean URL parameters first
      if (key === 'price') {
        // Parse price=8-46 format
        const [min, max] = value.split('-')
        if (min && max) {
          filters.price_range = { min, max }
        }
        return
      }

      if (key === 'stock' && value === '1') {
        filters.in_stock = 'true'
        return
      }

      // Handle clean array parameters: type=lipstick,foundation
      const cleanParamMappings = {
        'type': 'product_types',
        'skin': 'skin_types',
        'brand': 'brands',
        'color': 'colors',
        'size': 'sizes'
      }

      if (cleanParamMappings[key]) {
        filters[cleanParamMappings[key]] = value.split(',').filter(v => v.trim())
        return
      }

      // Backward compatibility: Handle old format filters[key][subkey]
      const priceRangeMatch = key.match(/filters\[price_range\]\[(min|max)\]/)
      if (priceRangeMatch) {
        if (!filters.price_range) filters.price_range = {}
        filters.price_range[priceRangeMatch[1]] = value
        return
      }

      // Backward compatibility: Handle old format filters[key][] arrays
      const filterMatch = key.match(/filters\[(.*?)\](\[\])?/)
      if (filterMatch) {
        const filterType = filterMatch[1]
        const isArray = !!filterMatch[2]

        if (isArray) {
          if (!filters[filterType]) filters[filterType] = []
          filters[filterType].push(value)
        } else {
          filters[filterType] = value
        }
      }
    })

    return filters
  }

  initializeFromURL() {
    this.currentFilters = this.getFiltersFromURL()
    this.syncFormInputs()
  }

  syncFormInputs() {
    // Reset all checkboxes first
    const allCheckboxes = this.element.querySelectorAll('input[type="checkbox"]')
    allCheckboxes.forEach(checkbox => {
      checkbox.checked = false
    })

    // Set checkboxes based on current filters
    Object.entries(this.currentFilters).forEach(([filterType, filterValue]) => {
      if (filterType === 'price_range') return // Price range handled separately

      if (Array.isArray(filterValue)) {
        filterValue.forEach(value => {
          const checkbox = this.element.querySelector(`input[data-filter-type="${filterType}"][value="${value}"]`)
          if (checkbox) {
            checkbox.checked = true
          }
        })
      } else {
        if (filterType === 'in_stock') {
          const checkbox = this.element.querySelector(`input[data-filter-type="${filterType}"]`)
          if (checkbox) {
            checkbox.checked = filterValue === 'true'
          }
        } else {
          const checkbox = this.element.querySelector(`input[data-filter-type="${filterType}"][value="${filterValue}"]`)
          if (checkbox) {
            checkbox.checked = true
          }
        }
      }
    })
  }

  updateResetButtonState() {
    if (!this.hasResetButtonTarget) return

    // Check if there are any filter parameters in the URL
    const params = new URLSearchParams(window.location.search)
    const hasUrlFilters = Array.from(params.keys()).some(key =>
      ['price', 'stock', 'type', 'skin', 'brand', 'color', 'size'].includes(key) ||
      key.startsWith('filters[')
    )

    // Also check current form state (for unsaved changes)
    const checkedInputs = this.element.querySelectorAll('input[type="checkbox"]:checked')
    let hasFormFilters = checkedInputs.length > 0

    // Check price range changes
    if (!hasFormFilters && this.hasRangeMinTarget && this.hasRangeMaxTarget) {
      const currentMin = parseInt(this.rangeMinTarget.value)
      const currentMax = parseInt(this.rangeMaxTarget.value)
      const defaultMin = parseInt(this.rangeMinTarget.min)
      const defaultMax = parseInt(this.rangeMaxTarget.max)

      hasFormFilters = currentMin !== defaultMin || currentMax !== defaultMax
    }

    // Enable reset button if there are URL filters OR unsaved form changes
    this.resetButtonTarget.disabled = !(hasUrlFilters || hasFormFilters)
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.closeFilters()
    }
  }
}
