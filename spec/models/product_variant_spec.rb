# frozen_string_literal: true

RSpec.describe ProductVariant, type: :model do
  subject(:variant) { build(:product_variant) }

  describe 'scopes' do
    describe '.in_stock' do
      let!(:in_stock_variant) { create(:product_variant, stock_quantity: 10) }
      let!(:out_of_stock_variant) { create(:product_variant, :out_of_stock) }
      let!(:zero_stock_with_backorder) { create(:product_variant, stock_quantity: 0, allow_backorder: true) }

      it 'includes variants with stock quantity greater than 0' do
        expect(ProductVariant.in_stock).to contain_exactly(in_stock_variant)
      end

      it 'excludes variants with zero stock even if backorders allowed' do
        expect(ProductVariant.in_stock).not_to include(zero_stock_with_backorder)
      end
    end

    describe '.available' do
      let!(:available_variant) { create(:product_variant, stock_quantity: 10) }
      let!(:unavailable_product_variant) { create(:product_variant, stock_quantity: 10) }

      before do
        unavailable_product_variant.product.update(active: false)
      end

      it 'includes variants of available products that are in stock' do
        expect(ProductVariant.available).to include(available_variant)
        expect(ProductVariant.available).not_to include(unavailable_product_variant)
      end
    end

    describe '.ordered' do
      let!(:variant_1) { create(:product_variant, position: 2) }
      let!(:variant_2) { create(:product_variant, position: 1) }
      let!(:variant_3) { create(:product_variant, position: 3) }

      it 'returns variants ordered by position ascending' do
        created_variants = [ variant_1, variant_2, variant_3 ]
        result = ProductVariant.where(id: created_variants.map(&:id)).ordered
        expect(result).to eq([ variant_2, variant_1, variant_3 ])
      end
    end
  end

  describe 'instance methods' do
    describe '#in_stock?' do
      context 'when track_inventory is true' do
        before { variant.track_inventory = true }

        it 'returns true if stock_quantity is positive' do
          variant.stock_quantity = 5
          expect(variant).to be_in_stock
        end

        it 'returns false if stock_quantity is zero and backorders are not allowed' do
          variant.stock_quantity = 0
          variant.allow_backorder = false
          expect(variant).not_to be_in_stock
        end

        it 'returns true if stock_quantity is zero but backorders are allowed' do
          variant.stock_quantity = 0
          variant.allow_backorder = true
          expect(variant).to be_in_stock
        end

        it 'returns false for negative stock quantity' do
          variant.stock_quantity = -1
          expect(variant).not_to be_in_stock
        end
      end

      context 'when track_inventory is false' do
        before { variant.track_inventory = false }

        it 'always returns true regardless of stock quantity' do
          variant.stock_quantity = 0
          expect(variant).to be_in_stock

          variant.stock_quantity = -5
          expect(variant).to be_in_stock
        end
      end
    end

    describe '#available?' do
      it 'returns true when both product and variant are available' do
        allow(variant.product).to receive(:available?).and_return(true)
        allow(variant).to receive(:in_stock?).and_return(true)
        expect(variant).to be_available
      end

      it 'returns false when product is not available' do
        allow(variant.product).to receive(:available?).and_return(false)
        allow(variant).to receive(:in_stock?).and_return(true)
        expect(variant).not_to be_available
      end

      it 'returns false when variant is not in stock' do
        allow(variant.product).to receive(:available?).and_return(true)
        allow(variant).to receive(:in_stock?).and_return(false)
        expect(variant).not_to be_available
      end
    end

    describe '#on_sale?' do
      it 'returns true when compare_at_price is greater than price' do
        variant.price = Money.new(800)
        variant.compare_at_price = Money.new(1000)
        expect(variant).to be_on_sale
      end

      it 'returns false when compare_at_price is zero' do
        variant.price = Money.new(800)
        variant.compare_at_price = Money.new(0)
        expect(variant).not_to be_on_sale
      end

      it 'returns false when compare_at_price equals price' do
        variant.price = Money.new(1000)
        variant.compare_at_price = Money.new(1000)
        expect(variant).not_to be_on_sale
      end

      it 'returns false when compare_at_price is less than price' do
        variant.price = Money.new(1000)
        variant.compare_at_price = Money.new(800)
        expect(variant).not_to be_on_sale
      end

      it 'handles edge case where compare_at_price is slightly higher' do
        variant.price = Money.new(999)
        variant.compare_at_price = Money.new(1000)
        expect(variant).to be_on_sale
      end
    end

    describe '#discount_amount' do
      context 'when on sale' do
        before do
          variant.price = Money.new(750)
          variant.compare_at_price = Money.new(1000)
        end

        it 'returns the correct discount amount' do
          expect(variant.discount_amount).to eq(Money.new(250))
        end
      end

      context 'when not on sale' do
        before do
          allow(variant).to receive(:on_sale?).and_return(false)
        end

        it 'returns zero' do
          expect(variant.discount_amount).to eq(Money.new(0))
        end
      end

      it 'handles small discount amounts correctly' do
        variant.price = Money.new(999)
        variant.compare_at_price = Money.new(1000)
        expect(variant.discount_amount).to eq(Money.new(1))
      end
    end

    describe '#discount_percentage' do
      context 'when on sale' do
        it 'calculates percentage correctly for round numbers' do
          variant.price = Money.new(7500)
          variant.compare_at_price = Money.new(10000)
          expect(variant.discount_percentage).to eq(25)
        end

        it 'rounds percentage to nearest integer' do
          variant.price = Money.new(6667)
          variant.compare_at_price = Money.new(10000)
          expect(variant.discount_percentage).to eq(33)
        end

        it 'handles small percentages' do
          variant.price = Money.new(9900)
          variant.compare_at_price = Money.new(10000)
          expect(variant.discount_percentage).to eq(1)
        end

        it 'handles large percentages' do
          variant.price = Money.new(1000)
          variant.compare_at_price = Money.new(10000)
          expect(variant.discount_percentage).to eq(90)
        end
      end

      context 'when not on sale' do
        before { allow(variant).to receive(:on_sale?).and_return(false) }

        it 'returns 0' do
          expect(variant.discount_percentage).to eq(0)
        end
      end
    end

    describe '#compare_at_price_difference' do
      it 'formats discount percentage with "% off" suffix' do
        allow(variant).to receive(:discount_percentage).and_return(25)
        expect(variant.compare_at_price_difference).to eq('25% off')
      end
    end

    describe '#display_name' do
      it 'combines product name and variant name with hyphen' do
        variant.product.name = 'Face Cream'
        variant.name = '50ml / Sensitive Skin'
        expect(variant.display_name).to eq('Face Cream - 50ml / Sensitive Skin')
      end

      it 'handles simple variant names' do
        variant.product.name = 'Moisturizer'
        variant.name = 'Large'
        expect(variant.display_name).to eq('Moisturizer - Large')
      end

      it 'works with special characters in names' do
        variant.product.name = 'Creme Hydratante'
        variant.name = 'Taille M'
        expect(variant.display_name).to eq('Creme Hydratante - Taille M')
      end
    end
  end
end
