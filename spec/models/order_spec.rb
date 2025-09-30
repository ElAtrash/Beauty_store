# frozen_string_literal: true

RSpec.describe Order, type: :model do
  describe 'callbacks' do
    describe '#generate_number' do
      subject(:order) { build(:order) }

      before { order.valid? }

      it 'generates a unique order number' do
        expect(order.number).to match(/^ORD-[A-F0-9]{8}$/)
      end

      it 'ensures the order number is unique' do
        existing_order = create(:order, number: order.number)
        new_order = build(:order, number: existing_order.number)
        expect(new_order).not_to be_valid
        expect(new_order.errors[:number]).to include('has already been taken')
      end

      it 'handles collision by regenerating' do
        allow(SecureRandom).to receive(:hex).with(4).and_return('ABCD1234', 'ABCD1234', 'EFGH5678')

        first_order = create(:order)
        expect(first_order.number).to eq('ORD-ABCD1234')

        second_order = create(:order)
        expect(second_order.number).to eq('ORD-EFGH5678')
      end

      it 'does not regenerate if number is already set' do
        order_with_number = build(:order, number: 'CUSTOM-123')
        expect { order_with_number.valid? }.not_to change { order_with_number.number }
      end
    end
  end

  describe '#total_quantity' do
    let(:order) { create(:order) }

    context 'with order items' do
      let!(:item1) { create(:order_item, order: order, quantity: 2) }
      let!(:item2) { create(:order_item, order: order, quantity: 3) }

      it 'calculates the total quantity of all order items' do
        expect(order.total_quantity).to eq(5)
      end
    end

    context 'with no order items' do
      it 'returns 0' do
        expect(order.total_quantity).to eq(0)
      end
    end
  end

  describe '#calculate_totals!' do
    let(:order) { create(:order) }

    context 'with order items' do
      let!(:item1) { create(:order_item, order: order, quantity: 2, unit_price: Money.new(1000), total_price: Money.new(2000)) }
      let!(:item2) { create(:order_item, order: order, quantity: 3, unit_price: Money.new(2000), total_price: Money.new(6000)) }

      before do
        order.update!(
          subtotal: Money.new(0),
          tax_total: Money.new(500),
          shipping_total: Money.new(300),
          discount_total: Money.new(200)
        )
      end

      it 'calculates and updates the subtotal and total' do
        expected_subtotal = item1.total_price + item2.total_price
        expected_total = expected_subtotal + Money.new(500) + Money.new(300) - Money.new(200)

        order.calculate_totals!
        order.reload

        aggregate_failures do
          expect(order.subtotal).to eq(expected_subtotal)
          expect(order.total).to eq(expected_total)
          expect(order).to be_persisted
        end
      end

      it 'handles zero tax and shipping' do
        order.update!(tax_total: Money.new(0), shipping_total: Money.new(0))
        order.calculate_totals!
        expected_total = item1.total_price + item2.total_price - Money.new(200)
        expect(order.total).to eq(expected_total)
      end

      it 'handles zero discount' do
        order.update!(discount_total: Money.new(0))
        order.calculate_totals!
        expected_total = item1.total_price + item2.total_price + Money.new(500) + Money.new(300)
        expect(order.total).to eq(expected_total)
      end
    end

    context 'with no order items' do
      it 'sets subtotal and total to zero plus fees' do
        order.update!(
          tax_total: Money.new(100),
          shipping_total: Money.new(200),
          discount_total: Money.new(50)
        )
        order.calculate_totals!

        aggregate_failures do
          expect(order.subtotal).to eq(Money.new(0))
          expect(order.total).to eq(Money.new(250))
        end
      end
    end
  end

  describe 'validations' do
    describe 'delivery scheduling validations' do
      context 'for courier orders' do
        let(:order) { build(:order, delivery_method: 'courier') }

        it 'requires delivery_date' do
          order.delivery_date = nil
          expect(order).not_to be_valid
          expect(order.errors[:delivery_date]).to include("can't be blank")
        end

        it 'requires delivery_time_slot' do
          order.delivery_time_slot = nil
          expect(order).not_to be_valid
          expect(order.errors[:delivery_time_slot]).to include("can't be blank")
        end

        it 'is valid with both delivery_date and delivery_time_slot' do
          order.delivery_date = Date.tomorrow
          order.delivery_time_slot = '09:00-12:00'
          expect(order).to be_valid
        end
      end

      context 'for pickup orders without delivery date' do
        let(:order) { build(:order, delivery_method: 'pickup', delivery_date: nil, delivery_time_slot: nil) }

        it 'does not require delivery_date' do
          expect(order).to be_valid
        end

        it 'does not require delivery_time_slot' do
          expect(order).to be_valid
        end
      end
    end
  end
end
