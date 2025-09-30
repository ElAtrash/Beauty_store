# frozen_string_literal: true

RSpec.describe Orders::ReorderService do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:product_variant_1) { create(:product_variant, stock_quantity: 10) }
  let(:product_variant_2) { create(:product_variant, stock_quantity: 5) }
  let(:order) { create(:order, user: user) }
  let!(:order_item_1) { create(:order_item, order: order, product_variant: product_variant_1, quantity: 2) }
  let!(:order_item_2) { create(:order_item, order: order, product_variant: product_variant_2, quantity: 1) }

  subject(:result) do
    described_class.call(
      order: order,
      user: user,
      session: {},
      cart_token: "test_token"
    )
  end

  before do
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  describe "#call" do
    context "with valid inputs" do
      let(:cart_service_result) { double(success?: true, cart: cart) }
      let(:quantity_validation_success) { double(success?: true) }
      let(:add_item_success) { double(success?: true) }

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_result)
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(quantity_validation_success)
        allow(Carts::AddItemService).to receive(:call).and_return(add_item_success)
      end

      it "successfully reorders all items" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.cart).to eq(cart)
          expect(result.metadata[:success_items].size).to eq(2)
          expect(result.metadata[:failed_items]).to be_empty
          expect(result.metadata[:message]).to include("2 items added to cart")
        end
      end

      it "validates required parameters" do
        expect(result).to be_success
      end

      it "creates cart using FindOrCreateService" do
        result
        expect(Carts::FindOrCreateService).to have_received(:call).with(
          user: user,
          session: {},
          cart_token: "test_token"
        )
      end

      it "validates quantities for each item" do
        result
        expect(Carts::QuantityService).to have_received(:validate_quantity).twice
      end

      it "adds items using AddItemService" do
        result
        expect(Carts::AddItemService).to have_received(:call).with(
          cart: cart,
          product_variant: product_variant_1,
          quantity: 2
        )
        expect(Carts::AddItemService).to have_received(:call).with(
          cart: cart,
          product_variant: product_variant_2,
          quantity: 1
        )
      end

      it "tracks successful items with correct attributes" do
        success_items = result.metadata[:success_items]
        expect(success_items.first).to include(
          product_name: order_item_1.product_name,
          variant_name: order_item_1.variant_name,
          quantity: 2,
          status: :success
        )
      end
    end

    context "with invalid inputs" do
      context "when order is nil" do
        subject(:result) { described_class.call(order: nil, user: user) }

        it "returns failure with parameter error" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include(I18n.t("services.errors.param_required", params: "order"))
          end
        end
      end

      context "when order has no items" do
        let(:empty_order) { create(:order, user: user) }
        subject(:result) { described_class.call(order: empty_order, user: user) }

        it "returns failure with no items error" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include(I18n.t("checkout.reorder.errors.no_items_added"))
          end
        end
      end
    end

    context "when cart creation fails" do
      let(:cart_service_failure) { double(success?: false, errors: [ "Cart creation failed" ]) }

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_failure)
      end

      it "returns failure with cart error" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include(I18n.t("services.errors.something_went_wrong"))
        end
      end
    end

    context "when some items are out of stock" do
      let(:out_of_stock_variant) { create(:product_variant, :out_of_stock) }
      let(:in_stock_variant) { create(:product_variant, stock_quantity: 5) }
      let(:order_with_mixed_stock) { create(:order, user: user) }
      let!(:out_of_stock_order_item) { create(:order_item, order: order_with_mixed_stock, product_variant: out_of_stock_variant, quantity: 2) }
      let!(:in_stock_order_item) { create(:order_item, order: order_with_mixed_stock, product_variant: in_stock_variant, quantity: 1) }

      let(:cart_service_result) { double(success?: true, cart: cart) }

      subject(:result) do
        described_class.call(
          order: order_with_mixed_stock,
          user: user,
          session: {},
          cart_token: "test_token"
        )
      end

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_result)
        # Mock successful addition for available item
        allow(Carts::QuantityService).to receive(:validate_quantity).and_return(double(success?: true))
        allow(Carts::AddItemService).to receive(:call).and_return(double(success?: true))
      end

      it "handles partial success with mixed results" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.metadata[:success_items].size).to eq(1)
          expect(result.metadata[:failed_items].size).to eq(1)
          expect(result.metadata[:message]).to include("1 item added to cart")
          expect(result.metadata[:message]).to include("1 item unavailable")
        end
      end

      it "tracks failed items with reasons" do
        failed_item = result.metadata[:failed_items].first
        expect(failed_item).to include(
          product_name: out_of_stock_order_item.product_name,
          variant_name: out_of_stock_order_item.variant_name,
          quantity: 2,
          reason: I18n.t("checkout.reorder.messages.product_not_available"),
          status: :failed
        )
      end
    end

    context "when quantity exceeds stock" do
      let(:low_stock_variant) { create(:product_variant, stock_quantity: 1) }
      let(:normal_stock_variant) { create(:product_variant, stock_quantity: 5) }
      let(:order_with_quantity_issues) { create(:order, user: user) }
      let!(:low_stock_order_item) { create(:order_item, order: order_with_quantity_issues, product_variant: low_stock_variant, quantity: 2) }
      let!(:normal_stock_order_item) { create(:order_item, order: order_with_quantity_issues, product_variant: normal_stock_variant, quantity: 1) }

      let(:cart_service_result) { double(success?: true, cart: cart) }
      let(:quantity_validation_failure) do
        double(success?: false, errors: [ "Quantity exceeds available stock" ])
      end

      subject(:result) do
        described_class.call(
          order: order_with_quantity_issues,
          user: user,
          session: {},
          cart_token: "test_token"
        )
      end

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_result)
        allow(Carts::QuantityService).to receive(:validate_quantity)
          .with(2, product_variant: low_stock_variant, existing_quantity: 0)
          .and_return(quantity_validation_failure)
        allow(Carts::QuantityService).to receive(:validate_quantity)
          .with(1, product_variant: low_stock_variant, existing_quantity: 0)
          .and_return(double(success?: true))
        allow(Carts::QuantityService).to receive(:validate_quantity)
          .with(1, product_variant: normal_stock_variant, existing_quantity: 0)
          .and_return(double(success?: true))
        allow(Carts::AddItemService).to receive(:call).and_return(double(success?: true))
      end

      it "adds partial quantity when possible" do
        aggregate_failures do
          expect(result).to be_success
          expect(result.metadata[:success_items].size).to eq(2)

          partial_item = result.metadata[:success_items].find { |item| item[:status] == :partial }
          expect(partial_item).to include(
            product_name: low_stock_order_item.product_name,
            quantity: 1,
            requested_quantity: 2,
            status: :partial
          )
        end
      end
    end

    context "when all items fail to add" do
      let(:unavailable_variant_1) { create(:product_variant, :out_of_stock) }
      let(:unavailable_variant_2) { create(:product_variant, :out_of_stock) }
      let(:order_with_all_unavailable) { create(:order, user: user) }
      let!(:unavailable_order_item_1) { create(:order_item, order: order_with_all_unavailable, product_variant: unavailable_variant_1, quantity: 2) }
      let!(:unavailable_order_item_2) { create(:order_item, order: order_with_all_unavailable, product_variant: unavailable_variant_2, quantity: 1) }

      let(:cart_service_result) { double(success?: true, cart: cart) }

      subject(:result) do
        described_class.call(
          order: order_with_all_unavailable,
          user: user,
          session: {},
          cart_token: "test_token"
        )
      end

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_result)
      end

      it "returns failure when no items can be added" do
        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include("Could not add items: Product is no longer available")
          expect(result.metadata[:success_items]).to be_empty
          expect(result.metadata[:failed_items].size).to eq(2)
        end
      end
    end

    context "error handling" do
      let(:cart_service_result) { double(success?: true, cart: cart) }

      before do
        allow(Carts::FindOrCreateService).to receive(:call).and_return(cart_service_result)
      end

      context "when an unexpected error occurs" do
        before do
          allow(order).to receive(:order_items).and_raise(StandardError, "Database connection error")
        end

        it "returns failure with generic error message" do
          aggregate_failures do
            expect(result).to be_failure
            expect(result.errors).to include(I18n.t("checkout.reorder.errors.processing_error"))
          end
        end

        it "logs the error" do
          result
          expect(Rails.logger).to have_received(:error).with(/Orders::ReorderService unexpected error: Database connection error/)
        end
      end
    end
  end
end
