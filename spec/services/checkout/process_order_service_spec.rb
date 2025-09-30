# frozen_string_literal: true

RSpec.describe Checkout::ProcessOrderService, type: :service do
  let(:cart) { create(:cart, :with_items, items_count: 2) }
  let(:empty_cart) { create(:cart) }
  let(:valid_checkout_form) do
    CheckoutForm.new(
      email: "customer@example.com",
      phone_number: "+96170123456",
      first_name: "John",
      last_name: "Doe",
      address_line_1: "123 Main St",
      city: "Beirut",
      delivery_method: "courier",
      payment_method: "cod",
      delivery_date: Date.tomorrow,
      delivery_time_slot: "09:00-12:00"
    )
  end
  let(:invalid_checkout_form) do
    CheckoutForm.new(
      email: "invalid-email",
      phone_number: "",
      first_name: "",
      last_name: ""
    )
  end
  let(:session) { double("session", :[]= => nil, :delete => nil) }
  let(:order) { create(:order, :cod, number: "ORD-12345") }

  describe ".call" do
    context "with valid parameters and successful flow" do
      let(:order_service_result) { double(success?: true, resource: order, order: order) }
      let(:clear_service_result) { double(success?: true) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(order_service_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_service_result)
      end

      it "creates order successfully and returns success result" do
        result = described_class.call(
          checkout_form: valid_checkout_form,
          cart: cart,
          session: session
        )

        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to eq(order)
          expect(result.order).to eq(order)
          expect(Orders::CreateService).to have_received(:call).with(
            cart: cart,
            customer_info: instance_of(Hash)
          )
          expect(Carts::ClearService).to have_received(:call).with(cart: cart)
        end
      end

      it "calls session management methods on form" do
        expect(valid_checkout_form).to receive(:persist_to_session).with(session)
        expect(valid_checkout_form).to receive(:clear_from_session).with(session)

        described_class.call(
          checkout_form: valid_checkout_form,
          cart: cart,
          session: session
        )
      end

      it "passes correct customer information to Orders::CreateService" do
        described_class.call(
          checkout_form: valid_checkout_form,
          cart: cart,
          session: session
        )

        expect(Orders::CreateService).to have_received(:call) do |args|
          customer_info = args[:customer_info]
          expect(customer_info[:email]).to eq("customer@example.com")
          expect(customer_info[:full_name]).to eq("John Doe")
          expect(customer_info[:delivery_method]).to eq("courier")
          expect(customer_info[:payment_method]).to eq("cod")
        end
      end
    end

    context "when cart clearing fails" do
      let(:order_service_result) { double(success?: true, resource: order, order: order) }
      let(:clear_service_result) { double(success?: false, errors: [ "Failed to clear cart" ]) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(order_service_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_service_result)
        allow(Rails.logger).to receive(:error)
      end

      it "still returns success but logs the cart clearing error" do
        result = described_class.call(
          checkout_form: valid_checkout_form,
          cart: cart,
          session: session
        )

        aggregate_failures do
          expect(result).to be_success
          expect(result.resource).to eq(order)
          expect(Rails.logger).to have_received(:error).with(/Failed to clear cart/)
        end
      end
    end

    context "with invalid checkout form" do
      before do
        allow(Orders::CreateService).to receive(:call)
      end

      it "returns validation failure without calling order service" do
        result = described_class.call(
          checkout_form: invalid_checkout_form,
          cart: cart,
          session: session
        )

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.error_type).to eq(:validation)
          expect(result.errors).to be_present
          expect(Orders::CreateService).not_to have_received(:call)
        end
      end

      it "calls persist_to_session even with invalid form for user correction" do
        expect(invalid_checkout_form).to receive(:persist_to_session).with(session)

        described_class.call(
          checkout_form: invalid_checkout_form,
          cart: cart,
          session: session
        )
      end
    end

    context "when order creation fails" do
      let(:order_service_result) do
        double(success?: false, errors: [ "Payment method unavailable", "Delivery slot full" ])
      end

      before do
        allow(Orders::CreateService).to receive(:call).and_return(order_service_result)
      end

      it "returns service failure with order creation errors" do
        result = described_class.call(
          checkout_form: valid_checkout_form,
          cart: cart,
          session: session
        )

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.error_type).to eq(:service)
          expect(result.errors).to include("Payment method unavailable", "Delivery slot full")
        end
      end
    end

    context "with missing or invalid parameters" do
      it "returns failure when cart is nil" do
        result = described_class.call(
          checkout_form: valid_checkout_form,
          cart: nil,
          session: session
        )

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.errors).to include("Cart is required")
        end
      end

      it "returns failure when cart is empty" do
        result = described_class.call(
          checkout_form: valid_checkout_form,
          cart: empty_cart,
          session: session
        )

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.errors).to include("Cart is empty")
        end
      end

      it "returns failure when checkout_form is nil" do
        result = described_class.call(
          checkout_form: nil,
          cart: cart,
          session: session
        )

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.errors).to include("Checkout form is required")
        end
      end
    end
  end
end
