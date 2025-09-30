# frozen_string_literal: true

class Checkout::Modals::PickupDetailsModalComponent < Modal::BaseComponent
  include StoreInformation

  def initialize(store_info: nil)
    @store_info = store_info || store_pickup_details
    super(
      id: "pickup-details-modal",
      title: "Pickup Details",
      size: :medium,
      position: :right,
      data: { controller: "pickup-details-modal" }
    )
  end

  attr_reader :store_info
end
