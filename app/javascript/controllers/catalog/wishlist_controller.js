import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()

    const button = event.currentTarget
    const productId = button.dataset.productId

    const isActive = button.classList.contains('text-pink-500')

    if (isActive) {
      button.classList.remove('text-pink-500')
      button.classList.add('text-gray-600')
    } else {
      button.classList.remove('text-gray-600')
      button.classList.add('text-pink-500')
    }

    button.style.transform = 'scale(0.9)'
    setTimeout(() => {
      button.style.transform = 'scale(1)'
    }, 150)

    // TODO: Implement an AJAX request to add/remove from wishlist
    // For now, just log the action
    console.log(`Product ${productId} ${isActive ? 'removed from' : 'added to'} wishlist`)

    // TODO: Implement actual wishlist API call
    // this.#updateWishlist(productId, !isActive)
  }

  // Private method for future implementation
  // #updateWishlist(productId, add) {
  //   const url = add ? '/wishlist' : `/wishlist/${productId}`
  //   const method = add ? 'POST' : 'DELETE'
  //
  //   fetch(url, {
  //     method: method,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
  //     },
  //     body: JSON.stringify({ product_id: productId })
  //   })
  //   .then(response => response.json())
  //   .then(data => {
  //     // Handle response
  //   })
  //   .catch(error => {
  //     console.error('Error updating wishlist:', error)
  //     // Revert the visual state on error
  //   })
  // }
}
