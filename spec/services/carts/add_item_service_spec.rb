# frozen_string_literal: true

RSpec.describe Carts::AddItemService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }
  let(:product_variant) { create(:product_variant, product: product, stock_quantity: 10) }
  let(:quantity) { 2 }

  subject(:result) { described_class.call(cart: cart, product_variant: product_variant, quantity: quantity) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe ".call" do
    context "with valid inputs" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      context "when adding new item to cart" do
        it "creates new cart item with correct attributes" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.resource).to be_a(CartItem)
            expect(result.resource.cart).to eq(cart)
            expect(result.resource.product_variant).to eq(product_variant)
            expect(result.resource.quantity).to eq(quantity)
            expect(result.cart).to eq(cart)
          end
        end

        it "sets price snapshot from product variant" do
          expect(result.resource.price_snapshot_cents).to eq(product_variant.price_cents)
        end

        it "validates quantity with QuantityService" do
          result
          expect(Carts::QuantityService).to have_received(:validate_quantity).with(
            quantity,
            product_variant: product_variant,
            existing_quantity: 0
          )
        end

        it "persists the cart item" do
          expect { result }.to change(cart.cart_items, :count).by(1)
        end
      end

      context "when adding to existing cart item" do
        let!(:existing_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 3) }
        let(:existing_quantity_validation) do
          instance_double(BaseResult, success?: true, failure?: false, errors: [])
        end

        before do
          allow(Carts::QuantityService).to receive(:validate_quantity)
            .with(quantity, product_variant: product_variant, existing_quantity: 3)
            .and_return(existing_quantity_validation)
        end

        it "updates existing item quantity" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.resource).to eq(existing_item)
            expect(result.resource.quantity).to eq(5)
          end
        end

        it "validates with existing quantity" do
          result
          expect(Carts::QuantityService).to have_received(:validate_quantity).with(
            quantity, product_variant: product_variant, existing_quantity: 3
          )
        end

        it "does not create new cart item" do
          expect { result }.not_to change(cart.cart_items, :count)
        end
      end
    end

    context "with invalid inputs" do
      context "when cart is nil" do
        let(:cart) { nil }

        it "returns failure with error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.errors.cart_required"))
        end
      end

      context "when product_variant is nil" do
        let(:product_variant) { nil }

        it "returns failure with error" do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.errors.product_variant_required"))
        end
      end

      context "when quantity validation fails" do
        let(:failed_validation) do
          instance_double(BaseResult,
            success?: false,
            failure?: true,
            errors: [ "Quantity must be greater than 0", "Out of stock" ])
        end

        before do
          allow(Carts::QuantityService).to receive(:validate_quantity).and_return(failed_validation)
        end

        it "returns failure with validation errors" do
          aggregate_failures do
            aggregate_failures do
              expect(result).to be_failure
              expect(result.errors).to include("Quantity must be greater than 0")
              expect(result.errors).to include("Out of stock")
            end
          end
        end

        it "does not create cart item" do
          expect { result }.not_to change(CartItem, :count)
        end
      end
    end

    context "with quantity parameter handling" do
      context "when quantity is not provided" do
        let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

        before do
          allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
        end

        it "defaults to quantity 1" do
          result = described_class.call(cart: cart, product_variant: product_variant)
          expect(result).to be_success
          expect(result.resource.quantity).to eq(1)
        end
      end

      context "when quantity is string" do
        let(:quantity) { "3" }
        let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

        before do
          allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
        end

        it "converts to integer" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.resource.quantity).to eq(3)
          end
        end
      end

      context "when quantity is nil" do
        let(:quantity) { nil }

        it "converts to 0 and fails validation" do
          failed_validation = instance_double(BaseResult,
            success?: false, failure?: true, errors: [ "Quantity must be greater than 0" ])
          allow(Carts::QuantityService).to receive(:validate_quantity).and_return(failed_validation)

          expect(result).to be_failure
          expect(Carts::QuantityService).to have_received(:validate_quantity).with(
            0, product_variant: product_variant, existing_quantity: 0
          )
        end
      end
    end

    context "error handling" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      context "when ActiveRecord::RecordInvalid is raised" do
        before do
          allow_any_instance_of(CartItem).to receive(:save!).and_raise(
            ActiveRecord::RecordInvalid.new(CartItem.new)
          )
        end

        it "returns failure with user-friendly error" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include(I18n.t("services.errors.cart_item_add_failed"))
          end
        end

        it "logs the error" do
          result
          expect(Rails.logger).to have_received(:error).with(/Carts::AddItemService validation error/)
        end
      end

      context "when unexpected error is raised" do
        before do
          allow_any_instance_of(CartItem).to receive(:save!).and_raise(StandardError.new("Database error"))
        end

        it "returns failure with user-friendly error" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include(I18n.t("services.errors.something_went_wrong"))
          end
        end

        it "logs the error and backtrace" do
          result
          expect(Rails.logger).to have_received(:error).with(/Carts::AddItemService unexpected error/)
          expect(Rails.logger).to have_received(:error).with(/Database error/)
        end
      end
    end

    context "transaction behavior" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      it "wraps cart item creation in transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original
        result
      end

      context "when save fails" do
        before do
          allow_any_instance_of(CartItem).to receive(:save!).and_raise(StandardError.new("Save failed"))
        end

        it "does not create cart item due to transaction rollback" do
          expect { result }.not_to change(CartItem, :count)
        end
      end
    end

    context "business logic edge cases" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      context "with zero quantity (edge case)" do
        let(:quantity) { 0 }

        it "still calls validation service which should reject it" do
          result
          expect(Carts::QuantityService).to have_received(:validate_quantity).with(
            0,
            product_variant: product_variant,
            existing_quantity: 0
          )
        end
      end

      context "with very high quantity" do
        let(:quantity) { 999 }

        it "delegates validation to QuantityService" do
          result
          expect(Carts::QuantityService).to have_received(:validate_quantity).with(
            999,
            product_variant: product_variant,
            existing_quantity: 0
          )
        end
      end
    end
  end
end
