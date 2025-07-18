# frozen_string_literal: true

RSpec.describe OrderItem, type: :model do
  describe 'callbacks' do
    describe '#set_product_details' do
      subject(:order_item) { build(:order_item, product_variant: product_variant) }

      before { order_item.valid? }

      context 'when product_variant is present' do
        let(:product) { build(:product, name: 'Test Product') }
        let(:product_variant) do
          build(:product_variant, product: product, name: 'Test Variant', price: Money.new(2500))
        end

        it 'sets all product and price details from the variant' do
          aggregate_failures do
            expect(order_item.product).to eq(product)
            expect(order_item.product_name).to eq('Test Product')
            expect(order_item.variant_name).to eq('Test Variant')
            expect(order_item.unit_price).to eq(Money.new(2500))
          end
        end
      end

      context 'when product_variant is not present' do
        subject(:order_item) { build(:order_item, product_variant: nil, product: nil) }

        it 'does not set any product details' do
          aggregate_failures do
            expect(order_item.product).to be_nil
            expect(order_item.product_name).to be_nil
            expect(order_item.variant_name).to be_nil
            expect(order_item.unit_price).to eq(Money.new(0))
          end
        end
      end
    end

    describe '#calculate_total_price' do
      let(:product_variant) { build(:product_variant, price: Money.new(1500)) }
      let(:order_item) { build(:order_item, product_variant: product_variant, quantity: 3) }

      before { order_item.valid? }

      it 'calculates the total price using the price from the product variant' do
        expect(order_item.total_price).to eq(Money.new(4500))
      end

      it 'recalculates the total when quantity changes' do
        order_item.quantity = 5
        order_item.valid?
        expect(order_item.total_price).to eq(Money.new(7500))
      end
    end
  end
end
