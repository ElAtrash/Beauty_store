# frozen_string_literal: true

RSpec.describe Checkout::CartValidationService do
  describe '.call' do
    subject(:result) { described_class.call(cart) }

    context 'with a valid cart' do
      let(:cart) { create(:cart, :with_items) }

      it 'returns success' do
        expect(result).to be_success
      end
    end

    context 'when cart is nil' do
      let(:cart) { nil }

      it 'returns failure with cart empty error' do
        expect(result).not_to be_success
        expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        expect(result.error_type).to eq(:validation)
      end
    end

    context 'when cart is not persisted' do
      let(:cart) { build(:cart) }

      it 'returns failure with cart empty error' do
        expect(result).not_to be_success
        expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        expect(result.error_type).to eq(:validation)
      end
    end

    context 'when cart has no items' do
      let(:cart) { create(:cart) }

      it 'returns failure with cart empty error' do
        expect(result).not_to be_success
        expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        expect(result.error_type).to eq(:validation)
      end
    end

    context 'when cart items have zero total quantity' do
      let(:cart) { create(:cart) }

      before do
        cart_item = create(:cart_item, cart: cart, quantity: 1)
        cart_item.update_column(:quantity, 0)
      end

      it 'returns failure with cart empty error' do
        expect(result).not_to be_success
        expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        expect(result.error_type).to eq(:validation)
      end
    end

    context 'error handling edge cases' do
      context 'when cart validation raises database error' do
        let(:cart) { create(:cart, :with_items) }

        before do
          allow(cart).to receive(:cart_items).and_raise(ActiveRecord::StatementInvalid, "Database connection lost")
        end

        it 'lets the exception propagate for controller to handle' do
          expect { described_class.call(cart) }.to raise_error(ActiveRecord::StatementInvalid, "Database connection lost")
        end
      end

      context 'when cart association has issues' do
        let(:cart) { create(:cart, :with_items) }

        before do
          # Simulate cart_items query returning empty after cart is loaded
          allow(cart).to receive_message_chain(:cart_items, :empty?).and_return(true)
        end

        it 'returns failure when items query returns empty' do
          expect(result).not_to be_success
          expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        end
      end

      context 'when cart exists but is stale' do
        let(:cart) { create(:cart, :with_items) }

        before do
          cart.cart_items.delete_all
          cart.reload
        end

        it 'returns failure for stale cart' do
          expect(result).not_to be_success
          expect(result.errors).to eq([ I18n.t('checkout.cart_empty') ])
        end
      end

      context 'with cart containing items' do
        let(:cart) { create(:cart) }
        let(:variant) { create(:product_variant) }

        before do
          create(:cart_item, cart: cart, product_variant: variant, quantity: 1)
        end

        it 'validates cart presence but allows other services to handle business validation' do
          expect(result).to be_success
        end
      end
    end
  end
end
