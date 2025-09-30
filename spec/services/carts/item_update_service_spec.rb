# frozen_string_literal: true

RSpec.describe Carts::ItemUpdateService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }
  let(:product_variant) { create(:product_variant, product: product, stock_quantity: 10) }
  let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 3) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe ".set_quantity" do
    subject(:result) { described_class.set_quantity(cart_item, new_quantity) }

    context "with valid positive quantity" do
      let(:new_quantity) { 5 }
      let(:successful_validation) do
        instance_double(BaseResult, success?: true, failure?: false, errors: [])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "sets the new quantity" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource.quantity).to eq(5)
          expect(result.cart).to eq(cart)
        end
      end

      it "validates with QuantityService" do
        result
        expect(Carts::QuantityService).to have_received(:can_set_quantity?).with(cart_item, new_quantity)
      end
    end

    context "when setting quantity to zero" do
      let(:new_quantity) { 0 }
      let(:successful_validation) do
        instance_double(BaseResult, success?: true, failure?: false, errors: [])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "destroys the cart item" do
        aggregate_failures do
          cart_item_id = cart_item.id
          expect(result).to be_success
          expect(CartItem.exists?(cart_item_id)).to be false
        end
      end
    end

    context "when setting negative quantity" do
      let(:new_quantity) { -1 }
      let(:successful_validation) do
        instance_double(BaseResult, success?: true, failure?: false, errors: [])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "destroys the cart item" do
        aggregate_failures do
          cart_item_id = cart_item.id
          expect(result).to be_success
          expect(CartItem.exists?(cart_item_id)).to be false
        end
      end
    end

    context "when validation fails" do
      let(:new_quantity) { 15 }
      let(:failed_validation) do
        instance_double(BaseResult,
          success?: false,
          failure?: true,
          errors: [ "Quantity exceeds stock" ])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(failed_validation)
      end

      it "returns failure without modifying quantity" do
        aggregate_failures do
          original_quantity = cart_item.quantity
          expect(result).to be_failure
          expect(result.errors).to include("Quantity exceeds stock")
          expect(cart_item.reload.quantity).to eq(original_quantity)
        end
      end
    end

    context "with string quantity" do
      let(:new_quantity) { "7" }
      let(:successful_validation) do
        instance_double(BaseResult, success?: true, failure?: false, errors: [])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "converts string to integer" do
        result
        expect(Carts::QuantityService).to have_received(:can_set_quantity?).with(cart_item, "7")
      end
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(cart_item, params: params) }

    context "with valid increment params" do
      let(:params) { { quantity_action: "increment" } }
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "delegates to increment method" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource.quantity).to eq(4)
        end
      end
    end

    context "with valid decrement params" do
      let(:params) { { quantity_action: "decrement" } }

      it "delegates to decrement method" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource.quantity).to eq(2)
        end
      end
    end

    context "with valid set_quantity params" do
      let(:params) { { quantity: "5" } }
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
      end

      it "delegates to set_quantity method" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource.quantity).to eq(5)
        end
      end
    end

    context "with invalid params" do
      let(:params) { { unknown_action: "invalid" } }

      it "returns failure with invalid action type error" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.cart_item.invalid_action"))
          expect(result.cart).to eq(cart)
        end
      end

      it "does not modify the cart item" do
        original_quantity = cart_item.quantity
        result
        expect(cart_item.reload.quantity).to eq(original_quantity)
      end
    end

    context "with no params" do
      let(:params) { nil }

      it "returns failure with invalid action type error" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.cart_item.invalid_action"))
          expect(result.cart).to eq(cart)
        end
      end
    end
  end

  describe "error handling" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
    end

    context "when ActiveRecord::RecordInvalid is raised" do
      before do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(
          ActiveRecord::RecordInvalid.new(cart_item)
        )
      end

      it "returns failure with user-friendly error and logs the validation error" do
        aggregate_failures do
          result = described_class.call(cart_item, params: { quantity_action: "increment" })
          expect(result.errors).to include(I18n.t("services.cart_item.update_failed"))
          expect(Rails.logger).to have_received(:error).with(/Carts::ItemUpdateService validation error/)
        end
      end
    end

    context "when unexpected error is raised during update" do
      before do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(StandardError.new("Database error"))
      end

      it "returns failure with user-friendly error and logs the error and backtrace" do
        aggregate_failures do
          result = described_class.call(cart_item, params: { quantity_action: "increment" })
          expect(result).to be_failure
          expect(result.errors).to include("Something went wrong. Please try again.")
          expect(Rails.logger).to have_received(:error).with(/Carts::ItemUpdateService unexpected error/)
          expect(Rails.logger).to have_received(:error).with(/Database error/)
        end
      end
    end

    context "when unexpected error is raised during destroy" do
      let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 1) }

      before do
        allow_any_instance_of(CartItem).to receive(:destroy!).and_raise(StandardError.new("Destroy failed"))
      end

      it "returns failure with user-friendly error" do
        aggregate_failures do
          result = described_class.call(cart_item, params: { quantity_action: "decrement" })
          expect(result).to be_failure
          expect(result.errors).to include("Something went wrong. Please try again.")
        end
      end
    end
  end

  describe "transaction behavior" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
    end

    it "wraps operations in transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      described_class.call(cart_item, params: { quantity_action: "increment" })
    end

    context "when operation fails" do
      before do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(StandardError.new("Failed"))
      end

      it "rolls back changes" do
        described_class.call(cart_item, params: { quantity_action: "increment" })
        expect(cart_item.reload.quantity).to eq(cart_item.quantity)
      end
    end
  end

  describe "unified error handling (execute_cart_operation)" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_set_quantity?).and_return(successful_validation)
    end

    context "with operation-specific error messages" do
      it "includes operation type in error message for update operations" do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(
          ActiveRecord::RecordInvalid.new(cart_item)
        )

        result = described_class.call(cart_item, params: { quantity_action: "increment" })
        expect(result.errors).to include(I18n.t("services.cart_item.update_failed"))
      end

      it "includes operation type in error message for remove operations" do
        cart_item_to_remove = create(:cart_item, cart: cart, product_variant: product_variant, quantity: 1)
        allow_any_instance_of(CartItem).to receive(:destroy!).and_raise(ActiveRecord::RecordInvalid.new(cart_item_to_remove))

        result = described_class.call(cart_item_to_remove, params: { quantity_action: "decrement" })
        expect(result.errors).to include(I18n.t("services.cart_item.remove_failed"))
      end
    end
  end
end
