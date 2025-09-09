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

    describe '#ordered_items' do
      let!(:cart) { create(:cart) }
      let!(:older_item) { create(:cart_item, cart: cart, created_at: 2.days.ago) }
      let!(:newer_item) { create(:cart_item, cart: cart, created_at: 1.day.ago) }

      it 'returns cart items ordered by created_at' do
        expect(cart.ordered_items).to eq([ older_item, newer_item ])
      end

      it 'includes necessary associations to avoid N+1 queries' do
        expect(cart.ordered_items.first.association(:product_variant)).to be_loaded
        expect(cart.ordered_items.first.product_variant.association(:product)).to be_loaded
        expect(cart.ordered_items.first.product_variant.product.association(:brand)).to be_loaded
      end
    end

    describe '#formatted_total' do
      context 'with no items' do
        it 'returns $0.00' do
          expect(cart.formatted_total).to eq('$0.00')
        end
      end

      context 'with cart items' do
        let!(:cart) { create(:cart) }
        let(:variant) { create(:product_variant, price: Money.new(2599)) } # $25.99
        let!(:item) { create(:cart_item, cart: cart, product_variant: variant, quantity: 2) }

        it 'returns formatted total price' do
          expect(cart.formatted_total).to eq('$51.98')
        end
      end
    end

    describe '#display_quantity_text' do
      context 'when cart is empty' do
        it 'returns empty string' do
          expect(cart.display_quantity_text).to eq('')
        end
      end

      context 'with single item' do
        let!(:cart) { create(:cart) }
        let!(:item) { create(:cart_item, cart: cart, quantity: 1) }

        it 'returns singular unit text' do
          expect(cart.display_quantity_text).to eq('/ 1 unit')
        end
      end

      context 'with multiple items' do
        let!(:cart) { create(:cart) }
        let!(:item1) { create(:cart_item, cart: cart, quantity: 2) }
        let!(:item2) { create(:cart_item, cart: cart, quantity: 3) }

        it 'returns plural units text' do
          expect(cart.display_quantity_text).to eq('/ 5 units')
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
