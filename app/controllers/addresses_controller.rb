# frozen_string_literal: true

class AddressesController < ApplicationController
  before_action :resume_session
  before_action :set_address, only: [ :edit, :update, :destroy, :set_default ]

  def index
    @addresses = Current.user.addresses.active.recently_used
  end

  def new
    @address = Current.user.addresses.build
  end

  def create
    @address = Current.user.addresses.build(address_params)

    if @address.save
      respond_to do |format|
        format.turbo_stream do
          if from_checkout?
            # Checkout context: Store new address ID in checkout form and reload address list with it selected
            if Current.user
              checkout_form = CheckoutForm.from_user(Current.user, session)
              checkout_form.selected_address_id = @address.id
              checkout_form.persist_to_session(session)
            end

            # Reload address list view with new address pre-selected
            render turbo_stream: turbo_stream.replace(
              "address-selection-ui",
              partial: "checkout/address_selections/list_view",
              locals: {
                user_addresses: Current.user.addresses.active.recently_used,
                selected_address: @address
              }
            )
          else
            # Regular context: update the addresses list
            render turbo_stream: [
              turbo_stream.prepend("addresses-list", partial: "addresses/address_card", locals: { address: @address }),
              turbo_stream.replace("address-form-modal", partial: "shared/empty"),
              turbo_stream.replace("flash-messages", partial: "shared/flash", locals: { notice: t("addresses.created") })
            ]
          end
        end
        format.html { redirect_to addresses_path, notice: t("addresses.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          if from_checkout?
            # Checkout context: re-render the form in the turbo frame
            render turbo_stream: turbo_stream.replace(
              "address-selection-ui",
              partial: "checkout/address_selections/form_view",
              locals: { address_obj: @address }
            ), status: :unprocessable_entity
          else
            # Regular context
            render turbo_stream: turbo_stream.replace(
              "address-form",
              partial: "addresses/form",
              locals: { address: @address }
            ), status: :unprocessable_entity
          end
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "address-#{@address.id}",
          partial: "addresses/form",
          locals: { address: @address }
        )
      end
      format.html
    end
  end

  def update
    if @address.update(address_params)
      respond_to do |format|
        format.turbo_stream do
          if from_checkout?
            # Checkout context: Store updated address ID in checkout form and reload address list with it selected
            if Current.user
              checkout_form = CheckoutForm.from_user(Current.user, session)
              checkout_form.selected_address_id = @address.id
              checkout_form.persist_to_session(session)
            end

            # Reload address list view with updated address pre-selected
            render turbo_stream: turbo_stream.replace(
              "address-selection-ui",
              partial: "checkout/address_selections/list_view",
              locals: {
                user_addresses: Current.user.addresses.active.recently_used,
                selected_address: @address
              }
            )
          else
            # Regular context: update the address card
            render turbo_stream: [
              turbo_stream.replace("address-#{@address.id}", partial: "addresses/address_card", locals: { address: @address }),
              turbo_stream.replace("flash-messages", partial: "shared/flash", locals: { notice: t("addresses.updated") })
            ]
          end
        end
        format.html { redirect_to addresses_path, notice: t("addresses.updated") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          if from_checkout?
            # Checkout context: re-render the form in the turbo frame
            render turbo_stream: turbo_stream.replace(
              "address-selection-ui",
              partial: "checkout/address_selections/form_view",
              locals: { address_obj: @address }
            ), status: :unprocessable_entity
          else
            # Regular context
            render turbo_stream: turbo_stream.replace(
              "address-#{@address.id}",
              partial: "addresses/form",
              locals: { address: @address }
            ), status: :unprocessable_entity
          end
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    was_default = @address.default?
    @address.soft_delete

    # Auto-promote new default if deleted address was default
    if was_default
      next_address = Current.user.addresses.active.recently_used.first
      next_address&.update(default: true)
    end

    respond_to do |format|
      format.turbo_stream do
        if from_checkout?
          # Checkout context: reload association to get fresh data after soft_delete
          Current.user.addresses.reload
          remaining_addresses = Current.user.addresses.active.recently_used

          if remaining_addresses.any?
            # Has addresses: show list
            render turbo_stream: turbo_stream.replace(
              "address-selection-ui",
              partial: "checkout/address_selections/list_view",
              locals: {
                user_addresses: remaining_addresses,
                selected_address: selected_address_from_form_for(Current.user)
              }
            )
          else
            # No addresses: clear session and update UI
            checkout_form = CheckoutForm.from_user(Current.user, session)
            checkout_form.selected_address_id = nil
            checkout_form.address_line_1 = nil
            checkout_form.address_line_2 = nil
            checkout_form.landmarks = nil
            checkout_form.persist_to_session(session)

            # Setup form for modal
            @address = Current.user.addresses.build
            @address.city = StoreConfigurationService::DEFAULT_CITY
            @address.governorate = StoreConfigurationService::DEFAULT_GOVERNORATE
            @delivery_card = build_delivery_card_for_addresses
            @show_save_checkbox = true
            @default_checkbox_checked = true
            @has_saved_addresses = false
            @submit_props = submit_button_props_for_addresses
            @label_options = label_options_for_addresses

            # Update both modal and delivery summary
            render turbo_stream: [
              # Update modal to show form
              turbo_stream.replace(
                "address-selection-ui",
                partial: "checkout/address_selections/form_view"
              ),
              # Update delivery summary to show "Set delivery address"
              turbo_stream.update(
                "delivery-summary",
                Checkout::DeliverySummaryComponent.new(
                  delivery_method: "courier",
                  address_data: {},  # Empty = shows "Set delivery address"
                  city: StoreConfigurationService::DEFAULT_CITY
                ).render_in(view_context)
              )
            ]
          end
        else
          # Regular context: remove card and show flash
          render turbo_stream: [
            turbo_stream.remove("address-edit-#{@address.id}"),
            turbo_stream.replace("flash-messages", partial: "shared/flash", locals: { notice: t("addresses.deleted") })
          ]
        end
      end
      format.html { redirect_to addresses_path, notice: t("addresses.deleted") }
    end
  end

  def set_default
    @address.update!(default: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("addresses-list", partial: "addresses/addresses_list", locals: { addresses: Current.user.addresses.active.recently_used }),
          turbo_stream.replace("flash-messages", partial: "shared/flash", locals: { notice: t("addresses.set_as_default") })
        ]
      end
      format.html { redirect_to addresses_path, notice: t("addresses.set_as_default") }
    end
  end

  private

  def set_address
    @address = Current.user.addresses.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to addresses_path, alert: t("addresses.not_found")
  end

  def address_params
    params.require(:address).permit(
      :label,
      :address_line_1,
      :address_line_2,
      :city,
      :governorate,
      :landmarks,
      :phone_number,
      :default
    )
  end

  def from_checkout?
    params[:from] == "checkout"
  end

  def selected_address_from_form_for(user)
    return nil unless user
    checkout_form = CheckoutForm.from_user(user, session)
    selected_id = checkout_form.selected_address_id
    return nil unless selected_id

    user.addresses.find_by(id: selected_id) || user.default_address
  end

  def build_delivery_card_for_addresses
    DeliveryCardComponent.new(
      icon: :truck,
      title: "Delivering to #{StoreConfigurationService.default_governorate}"
    )
  end

  def submit_button_props_for_addresses
    {
      text: t("addresses.save_address", default: "Save Address"),
      css_class: "btn-interactive btn-full btn-lg"
    }
  end

  def label_options_for_addresses
    [
      [ t("addresses.labels.home", default: "Home"), "Home" ],
      [ t("addresses.labels.work", default: "Work"), "Work" ],
      [ t("addresses.labels.other", default: "Other"), "Other" ]
    ]
  end
end
