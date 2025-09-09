# frozen_string_literal: true

RSpec.describe CartItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:cart) }
    it { is_expected.to belong_to(:product_variant) }
  end

  describe 'validations' do
    let(:cart_item) { create(:cart_item) }

    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }

    it 'validates uniqueness of cart_id scoped to product_variant_id' do
      existing_cart_item = create(:cart_item)
      duplicate_cart_item = build(:cart_item, cart: existing_cart_item.cart, product_variant: existing_cart_item.product_variant)

      expect(duplicate_cart_item).not_to be_valid
      expect(duplicate_cart_item.errors[:cart_id]).to include('has already been taken')
    end

    it 'validates currency format' do
      cart_item.price_snapshot_currency = 'USD'
      expect(cart_item).to be_valid

      cart_item.price_snapshot_currency = 'invalid'
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:price_snapshot_currency]).to include('must be a 3-letter ISO currency code')

      cart_item.price_snapshot_currency = 'US'
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:price_snapshot_currency]).to include('must be a 3-letter ISO currency code')
    end
  end

  describe 'database constraints' do
    it 'enforces unique constraint at database level' do
      cart = create(:cart)
      variant = create(:product_variant)
      create(:cart_item, cart: cart, product_variant: variant)

      expect {
        ActiveRecord::Base.connection.execute(
          "INSERT INTO cart_items (cart_id, product_variant_id, quantity, price_snapshot_cents, price_snapshot_currency, created_at, updated_at)
           VALUES (#{cart.id}, #{variant.id}, 1, 1000, 'USD', NOW(), NOW())"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /duplicate key value violates unique constraint/)
    end
  end

  describe 'constants' do
    it 'defines DEFAULT_CURRENCY' do
      expect(CartItem::DEFAULT_CURRENCY).to eq('USD')
    end
  end

  describe 'price calculation methods' do
    let(:cart_item) do
      cart_item = build(:cart_item)
      cart_item.price_snapshot_cents = 1500
      cart_item.price_snapshot_currency = 'USD'
      cart_item.quantity = 3
      cart_item.save!(validate: false)
      cart_item
    end

    describe '#total_price' do
      it 'calculates total price correctly' do
        expect(cart_item.total_price).to eq(Money.new(4500, 'USD'))
      end

      it 'falls back to default currency when currency is nil' do
        allow(cart_item).to receive(:price_snapshot_currency).and_return(nil)
        expect(cart_item.total_price).to eq(Money.new(4500, CartItem::DEFAULT_CURRENCY))
      end
    end

    describe '#unit_price' do
      it 'returns unit price as Money object' do
        expect(cart_item.unit_price).to eq(Money.new(1500, 'USD'))
      end
    end

    describe '#total_price_cents' do
      it 'returns total price in cents for performance optimization' do
        expect(cart_item.total_price_cents).to eq(4500)
      end
    end
  end

  describe '#product' do
    let(:product) { create(:product) }
    let(:variant) { create(:product_variant, product: product) }
    let(:cart_item) { create(:cart_item, product_variant: variant) }

    it 'returns the product through product_variant association' do
      expect(cart_item.product).to eq(product)
    end
  end

  describe 'callbacks' do
    describe '#set_price_snapshot' do
      context 'when product variant has price' do
        let(:variant) { create(:product_variant, price: Money.new(2500, 'EUR')) }

        it 'sets price snapshot from variant price on create' do
          cart_item = build(:cart_item, product_variant: variant, price_snapshot_cents: nil, price_snapshot_currency: nil)
          cart_item.save!

          aggregate_failures do
            expect(cart_item.price_snapshot_cents).to eq(2500)
            expect(cart_item.price_snapshot_currency).to eq('EUR')
          end
        end
      end

      context 'when product variant has no price' do
        it 'sets default values for zero-price items' do
          variant = create(:product_variant)
          allow(variant).to receive(:price).and_return(nil)

          cart_item = build(:cart_item, product_variant: variant, price_snapshot_cents: nil, price_snapshot_currency: nil)
          cart_item.save!

          aggregate_failures do
            expect(cart_item.price_snapshot_cents).to eq(0)
            expect(cart_item.price_snapshot_currency).to eq(CartItem::DEFAULT_CURRENCY)
          end
        end
      end
    end
  end
end
