/**
 * Shared Controller Utilities
 * Common functionality used across multiple Stimulus controllers
 * This is a utility module, not a Stimulus controller
 */

/**
 * Throttle function to limit how often a function can be called
 * @param {Function} func - The function to throttle
 * @param {number} limit - Time limit in milliseconds
 * @returns {Function} Throttled function
 */
export function throttle(func, limit) {
  let inThrottle
  return function () {
    const args = arguments
    const context = this
    if (!inThrottle) {
      func.apply(context, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

/**
 * Keyboard Handler Mixin for ESC key functionality
 * Provides consistent keyboard handling across modal controllers
 */
export const KeyboardHandlerMixin = {
  setupKeyboardListener() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  },

  removeKeyboardListener() {
    if (this.handleKeydown) {
      document.removeEventListener('keydown', this.handleKeydown)
    }
  },

  handleKeydown(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.close()
    }
  }
}
