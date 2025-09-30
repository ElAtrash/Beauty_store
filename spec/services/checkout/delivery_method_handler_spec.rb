# frozen_string_literal: true

RSpec.describe Checkout::DeliveryMethodHandler do
  let(:form) { CheckoutForm.new }

  describe '.call' do
    subject(:result) { described_class.call(form: form, delivery_method: delivery_method, address_params: address_params) }

    context 'with delivery method only' do
      let(:delivery_method) { 'courier' }
      let(:address_params) { {} }

      it 'updates form with normalized delivery method' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).to have_received(:update_from_params).with(delivery_method: 'courier')
      end

      it 'returns the form' do
        expect(result).to eq(form)
      end
    end

    context 'with address params only' do
      let(:delivery_method) { nil }
      let(:address_params) { { address_line_1: '123 Main St', landmarks: 'Near park' } }

      it 'updates form with address params' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).to have_received(:update_from_params).with(address_line_1: '123 Main St', landmarks: 'Near park')
      end
    end

    context 'with both delivery method and address params' do
      let(:delivery_method) { 'pickup' }
      let(:address_params) { { address_line_1: '456 Oak Ave', address_line_2: 'Apt 2' } }

      it 'updates form with both delivery method and address params' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).to have_received(:update_from_params).with(
          delivery_method: 'pickup',
          address_line_1: '456 Oak Ave',
          address_line_2: 'Apt 2'
        )
      end
    end

    context 'with blank address params' do
      let(:delivery_method) { 'courier' }
      let(:address_params) { { address_line_1: '', landmarks: '   ', address_line_2: nil } }

      it 'updates form with delivery method and blank address params' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).to have_received(:update_from_params).with(
          delivery_method: 'courier',
          address_line_1: '',
          address_line_2: nil,
          landmarks: '   '
        )
      end
    end

    context 'with no params' do
      let(:delivery_method) { nil }
      let(:address_params) { {} }

      it 'does not update form' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).not_to have_received(:update_from_params)
      end

      it 'returns the form' do
        expect(result).to eq(form)
      end
    end

    context 'with invalid delivery method' do
      let(:delivery_method) { 'invalid_method' }
      let(:address_params) { {} }

      before do
        allow(CheckoutForm).to receive(:normalize_delivery_method).with('invalid_method').and_return('pickup')
      end

      it 'normalizes delivery method through CheckoutForm' do
        allow(form).to receive(:update_from_params)
        result
        expect(form).to have_received(:update_from_params).with(delivery_method: 'pickup')
      end
    end
  end
end
