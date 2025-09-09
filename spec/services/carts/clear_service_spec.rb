# frozen_string_literal: true

RSpec.describe Carts::ClearService do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe ".call" do
    subject(:result) { described_class.call(cart: cart) }

    context "when cart has items to clear" do
      let(:product_1) { create(:product) }
      let(:product_2) { create(:product) }
      let(:variant_1) { create(:product_variant, product: product_1) }
      let(:variant_2) { create(:product_variant, product: product_2) }
      let!(:cart_item_1) { create(:cart_item, cart: cart, product_variant: variant_1, quantity: 2) }
      let!(:cart_item_2) { create(:cart_item, cart: cart, product_variant: variant_2, quantity: 1) }

      before do
        allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
          instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
        )
      end

      it "clears all cart items successfully" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.cart).to eq(cart)
          expect(result.cleared_items_count).to eq(2)
          expect(result.cleared_variants).to contain_exactly(variant_1, variant_2)
        end
      end

      it "uses ItemUpdateService to set quantities to 0" do
        result
        aggregate_failures do
          expect(Carts::ItemUpdateService).to have_received(:set_quantity).with(cart_item_1, 0)
          expect(Carts::ItemUpdateService).to have_received(:set_quantity).with(cart_item_2, 0)
        end
      end

      it "reloads cart items after clearing" do
        expect(cart.cart_items).to receive(:reload)
        result
      end

      it "collects variants and counts before clearing" do
        result
        aggregate_failures do
          expect(result.cleared_variants.size).to eq(2)
          expect(result.cleared_items_count).to eq(2)
        end
      end

      it "uses find_each for performance with large carts" do
        expect(cart.cart_items).to receive(:find_each).and_call_original
        result
      end

      it "includes product_variant associations for performance" do
        expect(cart.cart_items).to receive(:includes).with(:product_variant).and_call_original
        result
      end
    end

    context "when cart is empty" do
      it "returns success immediately without processing" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.cart).to eq(cart)
          expect(result.cleared_items_count).to eq(0)
          expect(result.cleared_variants).to eq([])
        end
      end

      it "does not call ItemUpdateService" do
        allow(Carts::ItemUpdateService).to receive(:set_quantity)
        result
        expect(Carts::ItemUpdateService).not_to have_received(:set_quantity)
      end
    end

    context "when cart is nil" do
      let(:cart) { nil }

      it "returns success with nil cart" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.cart).to be_nil
          expect(result.cleared_items_count).to eq(0)
          expect(result.cleared_variants).to eq([])
        end
      end
    end

    context "when ItemUpdateService fails to clear an item" do
      let!(:cart_item) { create(:cart_item, cart: cart, quantity: 2) }

      before do
        failed_result = instance_double(Carts::BaseResult,
          success?: false,
          failure?: true,
          errors: [ "Out of stock validation failed" ]
        )
        allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(failed_result)
      end

      it "returns failure and rolls back transaction" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.cart).to eq(cart)
          expect(result.errors).to include("Out of stock validation failed")
        end
      end

      it "logs rollback error" do
        result
        expect(Rails.logger).to have_received(:error).with(
          "Carts::ClearService transaction rolled back: Failed to clear items"
        )
      end

      it "does not clear any items due to transaction rollback" do
        initial_count = cart.cart_items.count
        result
        expect(cart.cart_items.reload.count).to eq(initial_count)
      end
    end

    context "when unexpected error occurs" do
      let!(:cart_item) { create(:cart_item, cart: cart, quantity: 1) }

      before do
        allow(cart.cart_items).to receive(:find_each).and_raise(StandardError.new("Database error"))
      end

      it "returns failure with user-friendly error" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.cart).to eq(cart)
          expect(result.errors).to include("We couldn't clear your cart. Please try again.")
        end
      end

      it "logs error details and backtrace" do
        result
        aggregate_failures do
          expect(Rails.logger).to have_received(:error).with(/Carts::ClearService unexpected error: Database error/)
          expect(Rails.logger).to have_received(:error).with(/Database error/)
        end
      end
    end

    context "transaction behavior" do
      let!(:cart_item) { create(:cart_item, cart: cart, quantity: 1) }

      before do
        allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
          instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
        )
      end

      it "wraps operations in transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original
        result
      end

      context "when operation fails during transaction" do
        before do
          allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
            instance_double(Carts::BaseResult, success?: false, failure?: true, errors: [ "Failed" ])
          )
        end

        it "rolls back all changes" do
          initial_count = cart.cart_items.count
          result
          expect(cart.cart_items.reload.count).to eq(initial_count)
        end
      end
    end

    context "edge cases" do
      context "with mixed success and failure from ItemUpdateService" do
        let!(:cart_item_1) { create(:cart_item, cart: cart, quantity: 1) }
        let!(:cart_item_2) { create(:cart_item, cart: cart, quantity: 1) }

        before do
          success_result = instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
          failed_result = instance_double(Carts::BaseResult, success?: false, failure?: true, errors: [ "Failed" ])

          allow(Carts::ItemUpdateService).to receive(:set_quantity)
            .with(cart_item_1, 0)
            .and_return(success_result)

          allow(Carts::ItemUpdateService).to receive(:set_quantity)
            .with(cart_item_2, 0)
            .and_return(failed_result)
        end

        it "fails on first error and rolls back successfully cleared items" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include("Failed")
            expect(cart.cart_items.reload.count).to eq(2) # Transaction rolled back
          end
        end
      end

      context "with large number of cart items" do
        before do
          5.times { create(:cart_item, cart: cart, quantity: 1) }
          allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
            instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
          )
        end

        it "processes all items" do
          result
          expect(Carts::ItemUpdateService).to have_received(:set_quantity).exactly(5).times
        end

        it "tracks correct cleared count" do
          expect(result.cleared_items_count).to eq(5)
        end
      end

      context "when cart items have complex product variant relationships" do
        let(:variant) { create(:product_variant) }
        let!(:cart_item) { create(:cart_item, cart: cart, product_variant: variant, quantity: 3) }

        before do
          allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
            instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
          )
        end

        it "captures variant information correctly" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.cleared_variants).to include(variant)
            expect(result.cleared_variants.first.id).to eq(variant.id)
          end
        end
      end
    end

    context "integration with BaseResult metadata" do
      let!(:cart_item) { create(:cart_item, cart: cart, quantity: 1) }

      before do
        allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(
          instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
        )
      end

      it "properly sets metadata through BaseResult constructor" do
        aggregate_failures do
          expect(result.cleared_items_count).to eq(1)
          expect(result.cleared_variants.length).to eq(1)
        end
      end

      it "integrates with BaseResult methods" do
        expect(result.cleared_variants).to respond_to(:each)
        expect(result.cleared_items_count).to be_a(Integer)
      end
    end
  end
end
