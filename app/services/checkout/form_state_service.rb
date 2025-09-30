# frozen_string_literal: true

class Checkout::FormStateService
  def self.restore_from_session(session)
    CheckoutForm.from_session(session[:checkout_form_data])
  end

  def self.update_and_persist(form, params, session)
    form.update_from_params(params)
    persist_if_valid(form, session)
    form
  end

  def self.persist_if_valid(form, session)
    form.persist_to_session(session) if form.valid_for_persistence?
  end

  def self.clear_from_session(session)
    session.delete(:checkout_form_data)
  end
end
