# frozen_string_literal: true

class Checkout::AddressSelectionsController < ApplicationController
  include StoreInformation

  allow_unauthenticated_access
  before_action :setup_checkout_form
  before_action :set_user_addresses, only: [ :list ]

  def list
    if has_saved_addresses?
      # Has addresses: show list view
      @selected_address = selected_address_from_form
      render partial: "checkout/address_selections/list_view", layout: false
    else
      # No addresses: show form view to add first address
      @address = Current.user&.addresses&.build || Address.new
      @address.city ||= StoreConfigurationService::DEFAULT_CITY
      @address.governorate ||= StoreConfigurationService::DEFAULT_GOVERNORATE

      @delivery_card = build_delivery_card
      @show_save_checkbox = should_show_save_checkbox?
      @default_checkbox_checked = true  # First address should be default
      @has_saved_addresses = false
      @submit_props = submit_button_props
      @label_options = label_options

      render partial: "checkout/address_selections/form_view", layout: false
    end
  end

  def new_form
    @address = Current.user&.addresses&.build || Address.new
    # Set defaults for required fields
    @address.city ||= StoreConfigurationService::DEFAULT_CITY
    @address.governorate ||= StoreConfigurationService::DEFAULT_GOVERNORATE

    @delivery_card = build_delivery_card
    @show_save_checkbox = should_show_save_checkbox?
    @default_checkbox_checked = default_checkbox_checked?
    @has_saved_addresses = has_saved_addresses?
    @submit_props = submit_button_props
    @label_options = label_options

    render layout: false
  end

  def edit_form
    @address = Current.user.addresses.find(params[:address_id])
    @delivery_card = build_delivery_card
    @has_saved_addresses = has_saved_addresses?
    @show_save_checkbox = should_show_save_checkbox?
    @default_checkbox_checked = default_checkbox_checked?
    @submit_props = submit_button_props
    @label_options = label_options

    render layout: false
  end

  private

  def setup_checkout_form
    @checkout_form = if Current.user
      CheckoutForm.from_user(Current.user, session)
    else
      Checkout::FormStateService.restore_from_session(session)
    end
  end

  def set_user_addresses
    @user_addresses = Current.user&.addresses&.active&.recently_used || []
  end

  def selected_address_from_form
    return nil unless Current.user
    selected_id = @checkout_form.selected_address_id
    return nil unless selected_id

    Current.user.addresses.find_by(id: selected_id) || Current.user.default_address
  end

  def has_saved_addresses?
    Current.user&.addresses&.active&.any?
  end

  def should_show_save_checkbox?
    Current.user.present?
  end

  def default_checkbox_checked?
    if @address.new_record?
      !has_saved_addresses?  # First address = pre-checked
    else
      @address.default?      # Edit: show current default status
    end
  end

  def build_delivery_card
    DeliveryCardComponent.new(
      icon: :truck,
      title: "Delivering to #{StoreConfigurationService.default_governorate}"
    )
  end

  def submit_button_props
    if @address&.persisted?
      {
        text: t("addresses.update_address", default: "Update Address"),
        css_class: "btn-interactive btn-full btn-lg"
      }
    else
      {
        text: t("addresses.save_address", default: "Save Address"),
        css_class: "btn-interactive btn-full btn-lg"
      }
    end
  end

  def label_options
    [
      [t("addresses.labels.home", default: "Home"), "Home"],
      [t("addresses.labels.work", default: "Work"), "Work"],
      [t("addresses.labels.other", default: "Other"), "Other"]
    ]
  end
end
