import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "loadMoreBtn", "loading"]
  static values = {
    pagyUrl: String,
    nextPage: Number
  }

  connect() {
    this.currentPage = 1
  }

  async loadMore() {
    if (this.isLoading) return

    this.isLoading = true
    this.showLoading()

    try {
      const nextPage = this.nextPageValue || 2

      const response = await fetch(`${this.pagyUrlValue}?page=${nextPage}`, {
        method: 'GET',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.currentPage = nextPage
      } else {
        console.error('Failed to load more products:', response.status)
        this.showError(`Failed to load products (${response.status})`)
      }
    } catch (error) {
      console.error('Error loading more products:', error)
      this.showError('Network error. Please check your connection and try again.')
    } finally {
      this.isLoading = false
      this.hideLoading()
    }
  }

  showError(message) {
    let errorDiv = document.getElementById('products-error-message')
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.id = 'products-error-message'
      errorDiv.className = 'text-center mt-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700'

      const container = this.containerTarget
      container.parentNode.insertBefore(errorDiv, container.nextSibling)
    }

    errorDiv.innerHTML = `
      <div class="flex items-center justify-center gap-2">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
        </svg>
        <span>${message}</span>
        <button class="ml-2 text-red-800 hover:text-red-900 underline" onclick="this.parentElement.parentElement.remove()">
          Dismiss
        </button>
      </div>
    `

    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    if (this.hasLoadMoreBtnTarget) {
      this.loadMoreBtnTarget.disabled = true
      this.loadMoreBtnTarget.style.opacity = '0.6'
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    if (this.hasLoadMoreBtnTarget) {
      this.loadMoreBtnTarget.disabled = false
      this.loadMoreBtnTarget.style.opacity = '1'
    }
  }
}
