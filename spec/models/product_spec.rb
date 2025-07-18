# frozen_string_literal: true

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

  describe 'skin type helper methods' do
    it 'provides helper methods for each skin type' do
      product.skin_types = %w[oily sensitive]

      aggregate_failures do
        expect(product).to be_oily_skin
        expect(product).to be_sensitive_skin
        expect(product).not_to be_dry_skin
        expect(product).not_to be_combination_skin
        expect(product).not_to be_normal_skin
      end
    end

    it 'handles nil skin_types gracefully' do
      product.skin_types = nil

      expect(product).not_to be_oily_skin
      expect(product).not_to be_dry_skin
    end
  end

  describe 'scopes' do
    describe '.active' do
      let(:active_product) { create(:product, active: true) }
      let(:inactive_product) { create(:product, active: false) }

      it 'returns only active products' do
        expect(Product.active).to contain_exactly(active_product)
      end
    end

    describe '.published' do
      let(:published_product) { create(:product, published_at: 1.day.ago) }
      let(:unpublished_product) { create(:product, published_at: nil) }
      let(:future_product) { create(:product, published_at: 1.day.from_now) }

      it 'returns only published products' do
        expect(Product.published).to contain_exactly(published_product)
      end
    end

    describe '.available' do
      let(:available_product) { create(:product, active: true, published_at: 1.day.ago) }
      let(:inactive_product) { create(:product, active: false, published_at: 1.day.ago) }
      let(:unpublished_product) { create(:product, active: true, published_at: nil) }

      it 'returns only active and published products' do
        expect(Product.available).to contain_exactly(available_product)
      end
    end
  end

  describe 'instance methods' do
    describe '#published?' do
      it 'returns true when published_at is in the past' do
        product.published_at = 1.day.ago
        expect(product).to be_published
      end

      it 'returns false when published_at is nil' do
        product.published_at = nil
        expect(product).not_to be_published
      end

      it 'returns false when published_at is in the future' do
        product.published_at = 1.day.from_now
        expect(product).not_to be_published
      end
    end

    describe '#available?' do
      it 'returns true when product is active and published' do
        product.active = true
        product.published_at = 1.day.ago
        expect(product).to be_available
      end

      it 'returns false when product is not active' do
        product.active = false
        product.published_at = 1.day.ago
        expect(product).not_to be_available
      end

      it 'returns false when product is not published' do
        product.active = true
        product.published_at = nil
        expect(product).not_to be_available
      end
    end
  end
end
