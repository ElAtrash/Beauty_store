// Shared mixin for timeout management across controllers
export const TimeoutMixin = {
  initializeTimeout() {
    this.timeout = null
  },

  setTimeoutWithCleanup(callback, delay) {
    this.clearCurrentTimeout()
    this.timeout = setTimeout(callback, delay)
  },

  clearCurrentTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  },

  cleanupOnDisconnect() {
    this.clearCurrentTimeout()
  }
}
