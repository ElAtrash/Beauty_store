# frozen_string_literal: true

RSpec.describe Carts::QuantityService do
  let(:product) { create(:product) }
  let(:in_stock_variant) { create(:product_variant, product: product, stock_quantity: 10) }
  let(:out_of_stock_variant) { create(:product_variant, product: product, stock_quantity: 0) }
  let(:limited_stock_variant) { create(:product_variant, product: product, stock_quantity: 3) }
  let(:cart) { create(:cart) }

  describe ".validate_quantity" do
    subject(:result) { described_class.validate_quantity(quantity, product_variant: product_variant, existing_quantity: existing_quantity) }

    let(:product_variant) { in_stock_variant }
    let(:existing_quantity) { 0 }

    context "with valid quantities" do
      let(:quantity) { 5 }

      it "returns success result" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to eq(5)
          expect(result.errors).to be_empty
        end
      end
    end

    context "with quantity validation" do
      context "when quantity is zero" do
        let(:quantity) { 0 }

        it "returns failure with error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.must_be_positive"))
        end
      end

      context "when quantity is negative" do
        let(:quantity) { -1 }

        it "returns failure with error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.must_be_positive"))
        end
      end

      context "when quantity exceeds maximum" do
        let(:quantity) { 100 }

        it "returns failure with error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.exceeds_maximum", max: 99))
        end
      end

      context "when quantity is at maximum (99)" do
        let(:quantity) { 99 }

        it "returns success if stock allows" do
          variant_with_high_stock = create(:product_variant, product: product, stock_quantity: 100)
          result = described_class.validate_quantity(quantity, product_variant: variant_with_high_stock)
          expect(result).to be_success
        end
      end

      context "when quantity is string" do
        let(:quantity) { "7" }

        it "converts to integer and validates" do
          expect(result).to be_success
          expect(result.resource).to eq(7)
        end
      end
    end

    context "with product variant validations" do
      context "when product variant is out of stock" do
        let(:product_variant) { out_of_stock_variant }
        let(:quantity) { 1 }

        it "returns failure with stock error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.out_of_stock", product_name: product_variant.product.name, variant_name: product_variant.name))
        end
      end

      context "when final quantity exceeds stock" do
        let(:product_variant) { limited_stock_variant }
        let(:quantity) { 2 }
        let(:existing_quantity) { 2 }

        it "returns failure with availability error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.only_more_available", available: 1, product_name: product_variant.product.name, variant_name: product_variant.name))
        end
      end

      context "when final quantity would exceed maximum" do
        let(:quantity) { 1 }
        let(:existing_quantity) { 99 }

        it "returns failure with max quantity error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.cannot_add_more", max: 99))
        end
      end

      context "when no more items can be added" do
        let(:product_variant) { limited_stock_variant }
        let(:quantity) { 1 }
        let(:existing_quantity) { 3 }

        it "returns failure with no availability error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.no_more_available", product_name: product_variant.product.name, variant_name: product_variant.name))
        end
      end

      context "without product variant" do
        let(:product_variant) { nil }
        let(:quantity) { 5 }

        it "only validates basic quantity rules" do
          expect(result).to be_success
          expect(result.resource).to eq(5)
        end
      end
    end

    context "with multiple validation errors" do
      let(:product_variant) { out_of_stock_variant }
      let(:quantity) { 0 }

      it "includes all applicable errors" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.quantity.must_be_positive"))
          expect(result.errors).to include(I18n.t("services.quantity.out_of_stock", product_name: product_variant.product.name, variant_name: product_variant.name))
        end
      end
    end
  end

  describe ".can_increment?" do
    subject(:result) { described_class.can_increment?(cart_item) }

    let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: current_quantity) }
    let(:current_quantity) { 1 }

    context "when increment is allowed" do
      let(:product_variant) { in_stock_variant }
      let(:current_quantity) { 5 }

      it "returns success" do
        expect(result).to be_success
      end
    end

    context "when increment would exceed stock" do
      let(:product_variant) { limited_stock_variant }
      let(:current_quantity) { 3 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.no_more_available", product_name: product_variant.product.name, variant_name: product_variant.name))
      end
    end

    context "when product is out of stock" do
      let(:product_variant) { out_of_stock_variant }
      let(:current_quantity) { 1 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.out_of_stock", product_name: product_variant.product.name, variant_name: product_variant.name))
      end
    end

    context "when increment would exceed maximum quantity" do
      let(:product_variant) { create(:product_variant, product: product, stock_quantity: 200) }
      let(:current_quantity) { 99 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.cannot_add_more", max: 99))
      end
    end
  end

  describe ".can_set_quantity?" do
    subject(:result) { described_class.can_set_quantity?(cart_item, new_quantity) }

    let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 2) }
    let(:product_variant) { in_stock_variant }

    context "with valid new quantity" do
      let(:new_quantity) { 5 }

      it "returns success" do
        expect(result).to be_success
        expect(result.resource).to eq(5)
      end
    end

    context "when setting quantity to zero (deletion)" do
      let(:new_quantity) { 0 }

      it "returns success" do
        expect(result).to be_success
        expect(result.resource).to eq(0)
      end
    end

    context "when new quantity is negative" do
      let(:new_quantity) { -1 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.cannot_be_negative"))
      end
    end

    context "when new quantity exceeds maximum" do
      let(:new_quantity) { 100 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.exceeds_maximum", max: 99))
      end
    end

    context "when new quantity exceeds stock" do
      let(:product_variant) { limited_stock_variant }
      let(:new_quantity) { 5 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.only_available", available: 3))
      end
    end

    context "when product is out of stock and quantity > 0" do
      let(:product_variant) { out_of_stock_variant }
      let(:new_quantity) { 1 }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("services.quantity.out_of_stock", product_name: product_variant.product.name, variant_name: product_variant.name))
      end
    end

    context "when product is out of stock but quantity is 0" do
      let(:product_variant) { out_of_stock_variant }
      let(:new_quantity) { 0 }

      it "allows deletion even if out of stock" do
        expect(result).to be_success
        expect(result.resource).to eq(0)
      end
    end

    context "when new quantity is string" do
      let(:new_quantity) { "3" }

      it "converts to integer and validates" do
        expect(result).to be_success
        expect(result.resource).to eq(3)
      end
    end
  end

  describe "MAX_QUANTITY constant" do
    it "is set to 99" do
      expect(described_class::MAX_QUANTITY).to eq(99)
    end
  end
end
