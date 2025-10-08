import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]
  static values = {
    selectedAddressId: String
  }

  connect() {
    // Controller connected
  }

  // Called when a radio button is clicked in an address card
  selectAddress(event) {
    const addressId = event.currentTarget.dataset.addressId

    if (addressId) {
      this.selectedAddressIdValue = addressId
    }
  }

  // Submit the selected address to the main checkout form
  submitSelectedAddress(event) {
    event.preventDefault()

    // Get the selected address ID from the checked radio button
    const checkedRadio = this.element.querySelector('input[name="selected_address_id"]:checked')
    const addressId = checkedRadio ? checkedRadio.value : this.selectedAddressIdValue

    if (!addressId) {
      return
    }

    // Update the value
    this.selectedAddressIdValue = addressId

    // Trigger delivery summary update
    this.updateDeliverySummary(addressId)

    // Close modal using direct approach
    this.closeModal()
  }

  // Close the modal
  closeModal() {
    const modalElement = document.getElementById('address-modal')
    if (modalElement) {
      const modalController = this.application.getControllerForElementAndIdentifier(modalElement, 'modal')
      if (modalController) {
        modalController.close()
      }
    }
  }

  // Update the delivery summary section with selected address
  updateDeliverySummary(addressId) {
    const url = '/checkout/delivery_summary'
    const formData = new FormData()

    formData.append('delivery_method', 'courier')
    formData.append('selected_address_id', addressId)

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }
        return response.text()
      })
      .then(html => {
        if (html.includes('turbo-stream')) {
          Turbo.renderStreamMessage(html)
        }
      })
      .catch(error => {
        console.error('Error updating delivery summary:', error)
      })
  }

  // Handle edit address action
  editAddress(event) {
    event.preventDefault()
    const addressId = event.currentTarget.dataset.addressId

    if (addressId) {
      const editUrl = `/checkout/address_selection/edit_form/${addressId}`
      const frame = document.getElementById('address-selection-ui')

      if (frame) {
        frame.src = editUrl
      }
    }
  }
}
