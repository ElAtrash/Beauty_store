# frozen_string_literal: true

RSpec.describe Carts::MergeService do
  let(:user) { create(:user) }
  let!(:user_cart) { create(:cart, user: user) }
  let!(:guest_cart) { create(:cart, user: nil) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe ".call" do
    subject(:result) { described_class.call(user_cart: user_cart, guest_cart: guest_cart) }

    context "when guest cart has items to merge" do
      let(:product_1) { create(:product) }
      let(:product_2) { create(:product) }
      let(:variant_1) { create(:product_variant, product: product_1, stock_quantity: 10) }
      let(:variant_2) { create(:product_variant, product: product_2, stock_quantity: 10) }

      context "merging new items (no existing items in user cart)" do
        let!(:guest_item_1) { create(:cart_item, cart: guest_cart, product_variant: variant_1, quantity: 2) }
        let!(:guest_item_2) { create(:cart_item, cart: guest_cart, product_variant: variant_2, quantity: 1) }

        it "moves guest items to user cart" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.cart).to eq(user_cart)
            expect(result.merged_items_count).to eq(2)
            expect(result.merged_any_items?).to be true
          end
        end

        it "updates guest items cart association" do
          result
          aggregate_failures do
            expect(guest_item_1.reload.cart).to eq(user_cart)
            expect(guest_item_2.reload.cart).to eq(user_cart)
            expect(user_cart.cart_items.count).to eq(2)
          end
        end

        it "marks guest cart as abandoned" do
          result
          aggregate_failures do
            expect(guest_cart.reload.abandoned_at).to be_present
            expect(Cart.active.where(id: guest_cart.id)).to be_empty
          end
        end

        it "logs successful item moves" do
          result
          aggregate_failures do
            expect(Rails.logger).to have_received(:info).with(/Moved item .* to user cart/).twice
            expect(Rails.logger).to have_received(:info).with(/Marked guest cart .* as abandoned/)
          end
        end

        it "reloads user cart items after merge" do
          expect(user_cart.cart_items).to receive(:reload)
          result
        end
      end

      context "merging with existing items in user cart" do
        let!(:existing_user_item) { create(:cart_item, cart: user_cart, product_variant: variant_1, quantity: 1) }
        let!(:guest_item_1) { create(:cart_item, cart: guest_cart, product_variant: variant_1, quantity: 2) }
        let!(:guest_item_2) { create(:cart_item, cart: guest_cart, product_variant: variant_2, quantity: 1) }

        before do
          allow(Carts::ItemUpdateService).to receive(:add_more).and_return(
            instance_double(Carts::BaseResult,
              success?: true,
              failure?: false,
              errors: []
            )
          )
        end

        it "uses ItemUpdateService to merge existing items" do
          result
          expect(Carts::ItemUpdateService).to have_received(:add_more).with(existing_user_item, 2)
        end

        it "moves non-existing items to user cart" do
          result
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(2)
            expect(guest_item_2.reload.cart).to eq(user_cart)
          end
        end

        it "logs both merge types" do
          result
          aggregate_failures do
            expect(Rails.logger).to have_received(:info).with(/Merged .* items .* into existing cart item/)
            expect(Rails.logger).to have_received(:info).with(/Moved item .* to user cart/)
          end
        end
      end

      context "when ItemUpdateService fails to merge existing item" do
        let!(:existing_user_item) { create(:cart_item, cart: user_cart, product_variant: variant_1, quantity: 1) }
        let!(:guest_item) { create(:cart_item, cart: guest_cart, product_variant: variant_1, quantity: 2) }

        before do
          allow(Carts::ItemUpdateService).to receive(:add_more).and_return(
            instance_double(Carts::BaseResult,
              success?: false,
              failure?: true,
              errors: [ "Out of stock" ]
            )
          )
        end

        it "logs warning and collects errors but still succeeds overall" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
            expect(Rails.logger).to have_received(:warn).with(/Failed to merge item .* Out of stock/)
          end
        end

        it "still marks guest cart as abandoned" do
          result
          expect(guest_cart.reload.abandoned_at).to be_present
        end
      end
    end

    context "when no items need to be merged" do
      context "guest cart is empty" do
        it "returns success without merging anything" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
            expect(result.merged_any_items?).to be false
          end
        end

        it "does not mark guest cart as abandoned" do
          result
          expect(guest_cart.reload.abandoned_at).to be_nil
        end
      end

      context "guest cart is nil" do
        let(:guest_cart) { nil }

        it "returns success without errors" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
          end
        end
      end

      context "user cart is nil" do
        let(:user_cart) { nil }

        it "returns success without merging" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
          end
        end
      end

      context "when user_cart and guest_cart are the same" do
        let(:guest_cart) { user_cart }

        let!(:cart_item) { create(:cart_item, cart: user_cart, quantity: 1) }

        it "skips merge and logs info" do
          result
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
            expect(Rails.logger).to have_received(:info).with(/Skipping merge - same cart/)
          end
        end
      end
    end

    context "error handling" do
      let!(:guest_item) { create(:cart_item, cart: guest_cart, product_variant: create(:product_variant), quantity: 1) }

      context "when unexpected error occurs during merge" do
        before do
          allow_any_instance_of(CartItem).to receive(:update!).and_raise(StandardError.new("Database error"))
        end

        it "returns failure with user-friendly error" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include("We couldn't merge your cart items. Please try again.")
          end
        end

        it "logs error details" do
          result
          aggregate_failures do
            expect(Rails.logger).to have_received(:error).with(/Carts::MergeService error: Database error/)
            expect(Rails.logger).to have_received(:error).with(/Database error/)
          end
        end

        it "rolls back transaction" do
          original_cart = guest_item.cart
          result
          expect(guest_item.reload.cart).to eq(original_cart)
        end
      end

      context "when guest cart abandonment fails" do
        before do
          allow(guest_cart).to receive(:mark_as_abandoned!).and_raise(StandardError.new("Abandonment failed"))
        end

        it "handles error gracefully" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include("We couldn't merge your cart items. Please try again.")
          end
        end
      end
    end

    context "transaction behavior" do
      let!(:guest_item) { create(:cart_item, cart: guest_cart, product_variant: create(:product_variant), quantity: 1) }

      it "wraps operations in transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original
        result
      end

      context "when operation fails mid-transaction" do
        before do
          allow(guest_cart).to receive(:mark_as_abandoned!).and_raise(StandardError.new("Failed"))
        end

        it "rolls back all changes" do
          original_cart = guest_item.cart
          result
          expect(guest_item.reload.cart).to eq(original_cart)
        end
      end
    end

    context "edge cases" do
      context "with items that have complex product variant relationships" do
        let(:variant) { create(:product_variant, stock_quantity: 5) }
        let!(:guest_item) { create(:cart_item, cart: guest_cart, product_variant: variant, quantity: 3) }
        let!(:existing_item) { create(:cart_item, cart: user_cart, product_variant: variant, quantity: 1) }

        before do
          allow(Carts::ItemUpdateService).to receive(:add_more).and_return(
            instance_double(Carts::BaseResult, success?: true, failure?: false, errors: [])
          )
        end

        it "properly handles variant matching" do
          result
          expect(Carts::ItemUpdateService).to have_received(:add_more).with(existing_item, 3)
        end
      end

      context "when guest cart has cart_items association but is empty" do
        before do
          guest_cart.cart_items.delete_all
        end

        it "returns early without processing" do
          aggregate_failures do
            expect(result).to be_success
            expect(result.merged_items_count).to eq(0)
          end
        end
      end
    end
  end

  describe "private method behavior through integration" do
    let!(:guest_item) { create(:cart_item, cart: guest_cart, quantity: 1) }

    describe "#should_merge?" do
      context "validation scenarios" do
        it "merges when all conditions are met" do
          result = described_class.call(user_cart: user_cart, guest_cart: guest_cart)
          expect(result.merged_items_count).to eq(1)
        end

        it "doesn't merge when guest cart has no items" do
          guest_cart.cart_items.delete_all
          result = described_class.call(user_cart: user_cart, guest_cart: guest_cart)
          expect(result.merged_items_count).to eq(0)
        end

        it "doesn't merge when user_cart is nil" do
          result = described_class.call(user_cart: nil, guest_cart: guest_cart)
          expect(result.merged_items_count).to eq(0)
        end
      end
    end

    describe "#merge_cart_item integration" do
      it "processes cart items with includes for performance" do
        expect(guest_cart.cart_items).to receive(:includes).with(:product_variant).and_call_original
        described_class.call(user_cart: user_cart, guest_cart: guest_cart)
      end
    end
  end
end
