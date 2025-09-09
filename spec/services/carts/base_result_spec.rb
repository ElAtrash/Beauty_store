# frozen_string_literal: true

RSpec.describe Carts::BaseResult do
  let(:cart) { create(:cart) }
  let(:cart_item) { create(:cart_item, cart: cart) }

  describe "initialization" do
    context "with success result" do
      let(:result) { described_class.new(success: true, resource: cart_item, cart: cart) }

      it "sets all attributes correctly" do
        aggregate_failures do
          expect(result.success?).to be true
          expect(result.failure?).to be false
          expect(result.resource).to eq(cart_item)
          expect(result.cart).to eq(cart)
          expect(result.errors).to be_empty
        end
      end
    end

    context "with failure result" do
      let(:errors) { [ "Item not found", "Out of stock" ] }
      let(:result) { described_class.new(success: false, errors: errors, cart: cart) }

      it "sets attributes correctly" do
        aggregate_failures do
          expect(result.success?).to be false
          expect(result.failure?).to be true
          expect(result.resource).to be_nil
          expect(result.cart).to eq(cart)
          expect(result.errors).to eq(errors)
        end
      end

      it "converts single error to array" do
        single_error_result = described_class.new(success: false, errors: "Single error")
        expect(single_error_result.errors).to eq([ "Single error" ])
      end
    end

    context "with metadata" do
      let(:metadata) { { merged_items_count: 3, cleared_variants: [ cart_item.product_variant ] } }
      let(:result) { described_class.new(success: true, cart: cart, **metadata) }

      it "provides merged_items_count accessor" do
        expect(result.merged_items_count).to eq(3)
      end

      it "provides cleared_variants accessor" do
        expect(result.cleared_variants).to eq([ cart_item.product_variant ])
      end

      it "provides cleared_items_count accessor" do
        metadata_with_count = { cleared_items_count: 5 }
        count_result = described_class.new(success: true, **metadata_with_count)
        expect(count_result.cleared_items_count).to eq(5)
      end
    end

    context "with default metadata values" do
      let(:result) { described_class.new(success: true) }

      it "returns zero for merged_items_count when not set" do
        expect(result.merged_items_count).to eq(0)
      end

      it "returns false for merged_any_items? when count is zero" do
        expect(result.merged_any_items?).to be false
      end

      it "returns empty array for cleared_variants when not set" do
        expect(result.cleared_variants).to eq([])
      end

      it "returns zero for cleared_items_count when not set" do
        expect(result.cleared_items_count).to eq(0)
      end
    end

    context "merged_any_items? logic" do
      it "returns true when merged_items_count > 0" do
        result = described_class.new(success: true, merged_items_count: 2)
        expect(result.merged_any_items?).to be true
      end

      it "returns false when merged_items_count is 0" do
        result = described_class.new(success: true, merged_items_count: 0)
        expect(result.merged_any_items?).to be false
      end
    end
  end

  describe "result pattern usage" do
    it "follows service result pattern for success" do
      result = described_class.new(
        success: true,
        resource: cart_item,
        cart: cart,
        merged_items_count: 1
      )

      aggregate_failures do
        expect(result).to be_success
        expect(result.resource).to be_present
        expect(result.cart).to be_present
        expect(result.errors).to be_empty
        expect(result.merged_any_items?).to be true
      end
    end

    it "follows service result pattern for failure" do
      result = described_class.new(
        success: false,
        errors: [ "Validation failed", "Out of stock" ],
        cart: cart
      )

      aggregate_failures do
        expect(result).to be_failure
        expect(result.resource).to be_nil
        expect(result.cart).to be_present
        expect(result.errors).to contain_exactly("Validation failed", "Out of stock")
        expect(result.merged_any_items?).to be false
      end
    end
  end
end
