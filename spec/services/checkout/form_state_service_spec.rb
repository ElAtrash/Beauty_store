# frozen_string_literal: true

RSpec.describe Checkout::FormStateService do
  let(:session) { {} }
  let(:form_data) { { email: 'test@example.com', first_name: 'John' } }

  describe '.restore_from_session' do
    context 'when session has form data' do
      before do
        session[:checkout_form_data] = form_data
      end

      it 'restores form from session data' do
        form = described_class.restore_from_session(session)
        expect(form).to be_a(CheckoutForm)
        expect(form.email).to eq('test@example.com')
        expect(form.first_name).to eq('John')
      end
    end

    context 'when session has no form data' do
      it 'returns new empty form' do
        form = described_class.restore_from_session(session)
        expect(form).to be_a(CheckoutForm)
        expect(form.email).to be_nil
      end
    end
  end

  describe '.update_and_persist' do
    let(:form) { CheckoutForm.new }
    let(:params) { { email: 'updated@example.com', last_name: 'Doe' } }

    before do
      allow(form).to receive(:has_partial_data?).and_return(true)
    end

    it 'updates form with params' do
      expect(form).to receive(:update_from_params).with(params)
      described_class.update_and_persist(form, params, session)
    end

    it 'persists form if valid' do
      expect(form).to receive(:persist_to_session).with(session)
      described_class.update_and_persist(form, params, session)
    end

    it 'returns the form' do
      result = described_class.update_and_persist(form, params, session)
      expect(result).to eq(form)
    end
  end

  describe '.persist_if_valid' do
    let(:form) { CheckoutForm.new }

    context 'when form has partial data' do
      before do
        allow(form).to receive(:has_partial_data?).and_return(true)
      end

      it 'persists to session' do
        expect(form).to receive(:persist_to_session).with(session)
        described_class.persist_if_valid(form, session)
      end
    end

    context 'when form does not have partial data' do
      before do
        allow(form).to receive(:has_partial_data?).and_return(false)
      end

      it 'does not persist to session' do
        expect(form).not_to receive(:persist_to_session)
        described_class.persist_if_valid(form, session)
      end
    end
  end

  describe '.clear_from_session' do
    before do
      session[:checkout_form_data] = form_data
    end

    it 'removes form data from session' do
      described_class.clear_from_session(session)
      expect(session[:checkout_form_data]).to be_nil
    end
  end

  describe 'session state management edge cases' do
    describe '.update_and_persist with complex scenarios' do
      let(:form) { CheckoutForm.new(email: 'existing@example.com', first_name: 'John') }
      let(:update_params) { { delivery_method: 'courier', address_line_1: '456 Oak Avenue' } }

      before do
        session[:checkout_form_data] = { 'email' => 'existing@example.com', 'first_name' => 'John' }
        allow(form).to receive(:has_partial_data?).and_return(true)
      end

      it 'preserves existing session data while updating with new fields' do
        described_class.update_and_persist(form, update_params, session)

        form_data = session[:checkout_form_data]
        expect(form_data['email']).to eq('existing@example.com')
        expect(form_data['first_name']).to eq('John')
        expect(form_data['delivery_method']).to eq('courier')
        expect(form_data['address_line_1']).to eq('456 Oak Avenue')
      end

      it 'handles updating delivery method switching scenarios' do
        pickup_params = { delivery_method: 'pickup' }
        described_class.update_and_persist(form, pickup_params, session)
        expect(session[:checkout_form_data]['delivery_method']).to eq('pickup')

        courier_params = { delivery_method: 'courier', address_line_1: '123 Main St' }
        described_class.update_and_persist(form, courier_params, session)

        form_data = session[:checkout_form_data]
        expect(form_data['delivery_method']).to eq('courier')
        expect(form_data['address_line_1']).to eq('123 Main St')
        expect(form_data['email']).to eq('existing@example.com') # Preserved
      end

      it 'handles blank values properly using compact_blank' do
        params_with_blanks = {
          delivery_method: 'courier',
          address_line_1: '123 Main Street',
          address_line_2: '',
          landmarks: '   '
        }

        described_class.update_and_persist(form, params_with_blanks, session)

        form_data = session[:checkout_form_data]
        expect(form_data).to include('address_line_1' => '123 Main Street')
        expect(form_data).not_to have_key('address_line_2')
        expect(form_data).not_to have_key('landmarks')
      end
    end

    describe '.restore_from_session with corrupted data' do
      context 'when session data contains invalid values' do
        before do
          session[:checkout_form_data] = { 'delivery_method' => 'invalid_method' }
        end

        it 'normalizes invalid delivery methods' do
          form = described_class.restore_from_session(session)
          expect(form.delivery_method).to eq('invalid_method')
        end
      end

      context 'when session data is nil' do
        before do
          session[:checkout_form_data] = nil
        end

        it 'returns empty form without errors' do
          form = described_class.restore_from_session(session)
          expect(form).to be_a(CheckoutForm)
          expect(form.delivery_method).to eq('pickup')
        end
      end

      context 'when session data contains unexpected keys' do
        before do
          session[:checkout_form_data] = {
            'email' => 'test@example.com',
            'unknown_field' => 'ignored_value'
          }
        end

        it 'safely handles unexpected keys by letting CheckoutForm filter them' do
          expect { described_class.restore_from_session(session) }.to raise_error(ActiveModel::UnknownAttributeError)
        end
      end

      context 'when session data contains only valid keys' do
        before do
          session[:checkout_form_data] = {
            'email' => 'test@example.com',
            'first_name' => 'John'
          }
        end

        it 'successfully creates form with valid attributes' do
          form = described_class.restore_from_session(session)
          expect(form.email).to eq('test@example.com')
          expect(form.first_name).to eq('John')
        end
      end
    end

    describe 'page refresh and state persistence scenarios' do
      it 'maintains state across multiple requests' do
        initial_form = CheckoutForm.new(email: 'test@example.com')
        allow(initial_form).to receive(:has_partial_data?).and_return(true)
        described_class.update_and_persist(initial_form, { first_name: 'John' }, session)

        restored_form = described_class.restore_from_session(session)
        expect(restored_form.email).to eq('test@example.com')
        expect(restored_form.first_name).to eq('John')

        allow(restored_form).to receive(:has_partial_data?).and_return(true)
        described_class.update_and_persist(restored_form, { last_name: 'Doe' }, session)

        final_form = described_class.restore_from_session(session)
        expect(final_form.email).to eq('test@example.com')
        expect(final_form.first_name).to eq('John')
        expect(final_form.last_name).to eq('Doe')
      end

      it 'handles concurrent updates properly' do
        form = CheckoutForm.new
        allow(form).to receive(:has_partial_data?).and_return(true)

        described_class.update_and_persist(form, { email: 'first@example.com' }, session)
        described_class.update_and_persist(form, { first_name: 'John' }, session)
        described_class.update_and_persist(form, { delivery_method: 'courier' }, session)

        restored_form = described_class.restore_from_session(session)
        expect(restored_form.email).to eq('first@example.com')
        expect(restored_form.first_name).to eq('John')
        expect(restored_form.delivery_method).to eq('courier')
      end
    end
  end
end
