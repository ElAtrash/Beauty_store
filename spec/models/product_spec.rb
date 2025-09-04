# frozen_string_literal: true

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

  describe 'scopes' do
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
