# frozen_string_literal: true

RSpec.describe Brand, type: :model do
  describe 'scopes' do
    describe '.featured' do
      let!(:featured_brand) { create(:brand, :featured) }
      let!(:non_featured_brand) { create(:brand) }

      it 'returns only featured brands' do
        expect(Brand.featured).to include(featured_brand)
        expect(Brand.featured).not_to include(non_featured_brand)
      end
    end
  end
end
