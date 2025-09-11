# frozen_string_literal: true

RSpec.describe Carts::ItemUpdateService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }
  let(:product_variant) { create(:product_variant, product: product, stock_quantity: 10) }
  let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 3) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe ".increment" do
    subject(:result) { described_class.increment(cart_item) }

    context "when increment is allowed" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:can_increment?).and_return(successful_validation)
      end

      it "increases quantity by 1" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to eq(cart_item)
          expect(result.resource.quantity).to eq(4)
          expect(result.cart).to eq(cart)
        end
      end

      it "validates with QuantityService" do
        result
        expect(Carts::QuantityService).to have_received(:can_increment?).with(cart_item)
      end

      it "reloads cart items" do
        expect(cart.cart_items).to receive(:reload)
        result
      end
    end

    context "when increment validation fails" do
      let(:failed_validation) do
        instance_double(BaseResult,
          success?: false,
          failure?: true,
          errors: [ "No more items available" ])
      end

      before do
        allow(Carts::QuantityService).to receive(:can_increment?).and_return(failed_validation)
      end

      it "returns failure with validation errors" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include("No more items available")
          expect(result.cart).to eq(cart)
        end
      end

      it "does not modify quantity" do
        original_quantity = cart_item.quantity
        result
        expect(cart_item.reload.quantity).to eq(original_quantity)
      end
    end
  end

  describe ".decrement" do
    subject(:result) { described_class.decrement(cart_item) }

    context "when decrementing to positive quantity" do
      it "decreases quantity by 1" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to eq(cart_item)
          expect(result.resource.quantity).to eq(2)
        end
      end
    end

    context "when decrementing to zero" do
      let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 1) }

      it "destroys the cart item" do
        cart_item_id = cart_item.id
        expect(result).to be_success
        expect(result.cart).to eq(cart)
        expect(CartItem.exists?(cart_item_id)).to be false
      end

      it "returns result without resource since item was destroyed" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to be_nil
        end
      end
    end

    context "when decrementing below zero" do
      let(:cart_item) { create(:cart_item, cart: cart, product_variant: product_variant, quantity: 1) }

      it "destroys the item instead of setting negative quantity" do
        aggregate_failures do
          cart_item_id = cart_item.id
          expect(result).to be_success
          expect(CartItem.exists?(cart_item_id)).to be false
        end
      end
    end
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

  describe ".add_more" do
    subject(:result) { described_class.add_more(cart_item, additional_quantity) }

    let(:additional_quantity) { 2 }

    context "when adding more is allowed" do
      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      it "adds to existing quantity" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.resource.quantity).to eq(5)
        end
      end

      it "validates additional quantity with existing quantity" do
        result
        expect(Carts::QuantityService).to have_received(:validate_quantity).with(
          additional_quantity,
          product_variant: product_variant,
          existing_quantity: 3
        )
      end
    end

    context "when validation fails" do
      let(:failed_validation) do
        instance_double(BaseResult,
          success?: false,
          failure?: true,
          errors: [ "Would exceed maximum quantity" ])
      end

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(failed_validation)
      end

      it "returns failure without modifying quantity" do
        aggregate_failures do
          original_quantity = cart_item.quantity
          expect(result).to be_failure
          expect(result.errors).to include("Would exceed maximum quantity")
          expect(cart_item.reload.quantity).to eq(original_quantity)
        end
      end
    end

    context "when additional_quantity is not provided" do
      subject(:result) { described_class.add_more(cart_item) }

      let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

      before do
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(successful_validation)
      end

      it "defaults to adding 1" do
        result
        expect(Carts::QuantityService).to have_received(:validate_quantity).with(
          1,
          product_variant: product_variant,
          existing_quantity: 3
        )
      end
    end
  end

  describe "error handling" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_increment?).and_return(successful_validation)
    end

    context "when ActiveRecord::RecordInvalid is raised" do
      before do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(
          ActiveRecord::RecordInvalid.new(cart_item)
        )
      end

      it "returns failure with user-friendly error and logs the validation error" do
        aggregate_failures do
          result = described_class.increment(cart_item)
          expect(result.errors).to include("We couldn't update your cart item. Please try again.")
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
          result = described_class.increment(cart_item)
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
          result = described_class.decrement(cart_item)
          expect(result).to be_failure
          expect(result.errors).to include("Something went wrong. Please try again.")
        end
      end
    end
  end

  describe "transaction behavior" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_increment?).and_return(successful_validation)
    end

    it "wraps operations in transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      described_class.increment(cart_item)
    end

    context "when operation fails" do
      before do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(StandardError.new("Failed"))
      end

      it "rolls back changes" do
        described_class.increment(cart_item)
        expect(cart_item.reload.quantity).to eq(cart_item.quantity)
      end
    end
  end

  describe "unified error handling (execute_cart_operation)" do
    let(:successful_validation) { instance_double(BaseResult, success?: true, failure?: false, errors: []) }

    before do
      allow(Carts::QuantityService).to receive(:can_increment?).and_return(successful_validation)
    end

    context "with operation-specific error messages" do
      it "includes operation type in error message for update operations" do
        allow_any_instance_of(CartItem).to receive(:update!).and_raise(
          ActiveRecord::RecordInvalid.new(cart_item)
        )

        result = described_class.increment(cart_item)
        expect(result.errors).to include("We couldn't update your cart item. Please try again.")
      end

      it "includes operation type in error message for remove operations" do
        cart_item_to_remove = create(:cart_item, cart: cart, product_variant: product_variant, quantity: 1)
        allow_any_instance_of(CartItem).to receive(:destroy!).and_raise(ActiveRecord::RecordInvalid.new(cart_item_to_remove))

        result = described_class.decrement(cart_item_to_remove)
        expect(result.errors).to include("We couldn't remove your cart item. Please try again.")
      end
    end
  end
end
