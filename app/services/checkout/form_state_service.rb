# frozen_string_literal: true

class Checkout::FormStateService
  CHECKOUT_FORM_DATA_KEY = :checkout_form_data

  def self.restore_from_session(session)
    CheckoutForm.from_session(session[CHECKOUT_FORM_DATA_KEY])
  end

  def self.update_and_persist(form, params, session)
    form.update_from_params(params)
    persist_if_valid(form, session)
    form
  end

  def self.persist_if_valid(form, session)
    form.persist_to_session(session) if form.has_partial_data?
  end

  def self.clear_from_session(session)
    session.delete(CHECKOUT_FORM_DATA_KEY)
  end
end
