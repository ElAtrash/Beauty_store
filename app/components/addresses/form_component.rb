# frozen_string_literal: true

class Addresses::FormComponent < ViewComponent::Base
  attr_reader :address, :url, :method

  def initialize(address:, url: nil, method: :post)
    @address = address
    @url = url
    @method = address.persisted? ? :patch : :post
  end

  def before_render
    @url ||= @address.persisted? ? address_path(@address) : addresses_path
  end

  private

  def form_id
    address.persisted? ? "edit-address-#{address.id}" : "new-address"
  end

  def turbo_frame_id
    address.persisted? ? "address-#{address.id}" : "address-form-modal"
  end

  def governorate_options
    User::LEBANESE_GOVERNORATES.map { |gov| [ gov, gov ] }
  end

  def label_options
    [
      [ t("addresses.labels.home"), "Home" ],
      [ t("addresses.labels.work"), "Work" ],
      [ t("addresses.labels.other"), "Other" ]
    ]
  end

  def cancel_button
    if address.persisted?
      link_to t("common.cancel"),
              addresses_path,
              data: { turbo_frame: "_top" },
              class: "btn btn-secondary"
    else
      button_tag t("common.cancel"),
                 type: "button",
                 data: { action: "click->modal#close" },
                 class: "btn btn-secondary"
    end
  end

  def submit_button_text
    address.persisted? ? t("common.update") : t("common.save")
  end
end
