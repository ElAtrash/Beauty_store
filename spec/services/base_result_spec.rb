# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseResult do
  let(:cart) { create(:cart) }
  let(:order) { create(:order) }
  let(:cart_item) { create(:cart_item, cart: cart) }
  let(:errors) { [ 'Error message' ] }

  describe 'initialization' do
    context 'with success result' do
      let(:result) { described_class.new(success: true, resource: cart_item, cart: cart) }

      it 'sets all attributes correctly' do
        expect(result.success).to be true
        expect(result.resource).to eq cart_item
        expect(result.cart).to eq cart
        expect(result.order).to be_nil
        expect(result.errors).to eq []
        expect(result.metadata).to eq({})
      end

      it 'responds to success? predicate' do
        expect(result.success?).to be true
      end

      it 'responds to failure? predicate' do
        expect(result.failure?).to be false
      end
    end

    context 'with failure result' do
      let(:result) { described_class.new(success: false, errors: errors, cart: cart) }

      it 'sets attributes correctly' do
        expect(result.success).to be false
        expect(result.errors).to eq errors
        expect(result.cart).to eq cart
        expect(result.success?).to be false
        expect(result.failure?).to be true
      end

      it 'converts single error to array' do
        result = described_class.new(success: false, errors: 'Single error')
        expect(result.errors).to eq [ 'Single error' ]
      end
    end

    context 'with order result' do
      let(:result) { described_class.new(success: true, resource: order, order: order) }

      it 'sets order attribute correctly' do
        expect(result.order).to eq order
        expect(result.cart).to be_nil
      end
    end

    context 'with metadata' do
      let(:metadata) do
        {
          merged_items_count: 2,
          cleared_variants: [ 1, 2, 3 ],
          cleared_items_count: 5,
          custom_key: 'custom_value'
        }
      end

      let(:result) { described_class.new(success: true, cart: cart, **metadata) }

      it 'provides merged_items_count accessor' do
        expect(result.merged_items_count).to eq 2
      end

      it 'provides cleared_variants accessor' do
        expect(result.cleared_variants).to eq [ 1, 2, 3 ]
      end

      it 'provides cleared_items_count accessor' do
        expect(result.cleared_items_count).to eq 5
      end

      it 'stores custom metadata' do
        expect(result.metadata[:custom_key]).to eq 'custom_value'
      end
    end

    context 'with default metadata values' do
      let(:result) { described_class.new(success: true, cart: cart) }

      it 'returns zero for merged_items_count when not set' do
        expect(result.merged_items_count).to eq 0
      end

      it 'returns false for merged_any_items? when count is zero' do
        expect(result.merged_any_items?).to be false
      end

      it 'returns empty array for cleared_variants when not set' do
        expect(result.cleared_variants).to eq []
      end

      it 'returns zero for cleared_items_count when not set' do
        expect(result.cleared_items_count).to eq 0
      end
    end

    context 'merged_any_items? logic' do
      it 'returns true when merged_items_count > 0' do
        result = described_class.new(success: true, merged_items_count: 1)
        expect(result.merged_any_items?).to be true
      end

      it 'returns false when merged_items_count is 0' do
        result = described_class.new(success: true, merged_items_count: 0)
        expect(result.merged_any_items?).to be false
      end
    end
  end

  describe 'result pattern usage' do
    it 'follows service result pattern for success' do
      result = described_class.new(
        success: true,
        resource: cart_item,
        cart: cart,
        merged_items_count: 3,
        cleared_variants: [ 1, 2 ]
      )

      expect(result.success?).to be true
      expect(result.failure?).to be false
      expect(result.resource).to eq cart_item
      expect(result.cart).to eq cart
      expect(result.merged_items_count).to eq 3
      expect(result.cleared_variants).to eq [ 1, 2 ]
    end

    it 'follows service result pattern for failure' do
      result = described_class.new(
        success: false,
        errors: [ 'Validation failed' ],
        cart: cart
      )

      expect(result.success?).to be false
      expect(result.failure?).to be true
      expect(result.errors).to eq [ 'Validation failed' ]
      expect(result.cart).to eq cart
    end
  end
end
