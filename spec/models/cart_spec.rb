# frozen_string_literal: true

RSpec.describe Cart, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  subject(:cart) { build(:cart) }

  describe 'scopes' do
    let!(:abandoned_cart) { create(:cart, :abandoned) }
    let!(:active_cart) { create(:cart) }

    describe '.abandoned' do
      it 'returns carts that have been marked as abandoned' do
        expect(Cart.abandoned).to contain_exactly(abandoned_cart)
      end
    end

    describe '.active' do
      it 'returns carts that are not abandoned' do
        expect(Cart.active).to contain_exactly(active_cart)
      end
    end
  end

  describe 'instance methods' do
    describe '#total_quantity' do
      context 'with no items' do
        it 'returns 0' do
          expect(cart.total_quantity).to eq(0)
        end
      end

      context 'with cart items' do
        let!(:cart) { create(:cart) }
        let!(:item1) { create(:cart_item, cart: cart, quantity: 2) }
        let!(:item2) { create(:cart_item, cart: cart, quantity: 3) }

        it 'returns the sum of all item quantities' do
          expect(cart.total_quantity).to eq(5)
        end
      end

      context 'with single item' do
        let!(:cart) { create(:cart) }
        let!(:item) { create(:cart_item, cart: cart, quantity: 7) }

        it 'returns the quantity of the single item' do
          expect(cart.total_quantity).to eq(7)
        end
      end
    end

    describe '#total_price' do
      context 'with no items' do
        it 'returns 0' do
          expect(cart.total_price).to eq(0)
        end
      end

      context 'with cart items' do
        let!(:cart) { create(:cart) }
        let(:variant1) { create(:product_variant, price: Money.new(1000)) }
        let(:variant2) { create(:product_variant, price: Money.new(1500)) }
        let!(:item1) { create(:cart_item, cart: cart, product_variant: variant1, quantity: 2) }
        let!(:item2) { create(:cart_item, cart: cart, product_variant: variant2, quantity: 1) }

        it 'returns the sum of all item total prices' do
          expect(cart.total_price).to eq(Money.new(3500))
        end
      end
    end

    describe '#empty?' do
      context 'when cart has no items' do
        it 'returns true' do
          expect(cart).to be_empty
        end
      end

      context 'when cart has items' do
        let!(:cart) { create(:cart, :with_items) }

        it 'returns false' do
          expect(cart).not_to be_empty
        end
      end
    end

    describe '#add_variant' do
      let!(:cart) { create(:cart) }
      let(:variant) { create(:product_variant) }

      context 'when variant is not in cart' do
        it 'creates a new cart item with default quantity 1' do
          expect { cart.add_variant(variant) }.to change(cart.cart_items, :count).by(1)
          cart_item = cart.cart_items.find_by(product_variant: variant)
          expect(cart_item.quantity).to eq(1)
        end

        it 'creates a new cart item with specified quantity' do
          cart.add_variant(variant, 3)
          cart_item = cart.cart_items.find_by(product_variant: variant)
          expect(cart_item.quantity).to eq(3)
        end
      end

      context 'when variant is already in cart' do
        let!(:existing_item) { create(:cart_item, cart: cart, product_variant: variant, quantity: 2) }

        it 'increases the quantity of existing item with specified quantity' do
          cart.add_variant(variant, 4)
          expect(existing_item.reload.quantity).to eq(6)
        end

        it 'persists the updated quantity' do
          cart.add_variant(variant, 2)
          reloaded_item = cart.cart_items.find_by(product_variant: variant)
          expect(reloaded_item.quantity).to eq(4)
        end
      end

      context 'with multiple different variants' do
        let(:variant2) { create(:product_variant) }

        it 'adds multiple variants without affecting each other' do
          cart.add_variant(variant, 2)
          cart.add_variant(variant2, 3)

          aggregate_failures do
            expect(cart.cart_items.count).to eq(2)
            expect(cart.cart_items.find_by(product_variant: variant).quantity).to eq(2)
            expect(cart.cart_items.find_by(product_variant: variant2).quantity).to eq(3)
          end
        end
      end
    end

    describe '#remove_variant' do
      let!(:cart) { create(:cart) }
      let(:variant) { create(:product_variant) }

      context 'when variant exists in cart' do
        let!(:cart_item) { create(:cart_item, cart: cart, product_variant: variant, quantity: 3) }

        it 'removes the cart item completely' do
          expect { cart.remove_variant(variant) }.to change(cart.cart_items, :count).by(-1)
        end

        it 'removes the specific variant' do
          cart.remove_variant(variant)
          expect(cart.cart_items.find_by(product_variant: variant)).to be_nil
        end
      end

      context 'when variant does not exist in cart' do
        it 'does not raise an error' do
          expect { cart.remove_variant(variant) }.not_to raise_error
        end

        it 'does not change cart items count' do
          expect { cart.remove_variant(variant) }.not_to change(cart.cart_items, :count)
        end
      end

      context 'when removing one of multiple variants' do
        let(:variant2) { create(:product_variant) }
        let!(:item1) { create(:cart_item, cart: cart, product_variant: variant, quantity: 2) }
        let!(:item2) { create(:cart_item, cart: cart, product_variant: variant2, quantity: 1) }

        it 'removes only the specified variant' do
          cart.remove_variant(variant)
          aggregate_failures do
            expect(cart.cart_items.count).to eq(1)
            expect(cart.cart_items.find_by(product_variant: variant)).to be_nil
            expect(cart.cart_items.find_by(product_variant: variant2)).to be_present
          end
        end
      end
    end

    describe '#mark_as_abandoned!' do
      let!(:cart) { create(:cart, abandoned_at: nil) }

      it 'sets the abandoned_at timestamp' do
        freeze_time do
          cart.mark_as_abandoned!
          expect(cart.abandoned_at).to eq(Time.current)
        end
      end

      it 'persists the change to the database' do
        cart.mark_as_abandoned!
        expect(cart.reload.abandoned_at).to be_present
      end
    end
  end
end
