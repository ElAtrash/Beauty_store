// Shared mixin for consistent event handling across controllers
export const EventHandlerMixin = {
  preventDefaultIfPresent(event) {
    if (event) {
      event.preventDefault()
    }
  },

  stopPropagationIfPresent(event) {
    if (event) {
      event.stopPropagation()
    }
  },

  handleEventSafely(event, callback) {
    try {
      this.preventDefaultIfPresent(event)
      callback.call(this, event)
    } catch (error) {
      console.error('Event handler error:', error)
      this.dispatchError('event-handler-error', error)
    }
  },

  dispatchError(type, error) {
    if (this.dispatch) {
      this.dispatch(type, {
        detail: {
          error: error.message || error,
          controller: this.identifier || 'unknown'
        }
      })
    }
  }
}