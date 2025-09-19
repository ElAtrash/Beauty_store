# frozen_string_literal: true

RSpec.describe Orders::CreateService do
  let(:cart) { create(:cart) }
  let!(:cart_item) { create(:cart_item, cart: cart, quantity: 2) }

  let(:customer_info) do
    {
      email: "customer@example.com",
      phone_number: "70-123-456",
      first_name: "John",
      last_name: "Doe",
      delivery_method: "courier",
      payment_method: "cod",
      delivery_notes: "Ring doorbell twice",
      delivery_date: Date.tomorrow,
      delivery_time_slot: "9:00 AM - 12:00 PM",
      address_line_1: "123 Main Street",
      address_line_2: "Apt 4B",
      city: "Beirut",
      landmarks: "Near ABC Mall"
    }
  end

  subject(:result) { described_class.call(cart: cart, customer_info: customer_info) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe ".call" do
    context "with valid inputs" do
      it "returns a successful result" do
        expect(result).to be_success
        expect(result.failure?).to be false
      end

      it "creates an order with correct attributes" do
        order = result.resource

        aggregate_failures do
          expect(order).to be_a(Order)
          expect(order).to be_persisted
          expect(order.email).to eq("customer@example.com")
          expect(order.phone_number).to eq("70-123-456")
          expect(order.delivery_method).to eq("courier")
          expect(order.payment_status).to eq("cod_due")
          expect(order.fulfillment_status).to eq("unfulfilled")
          expect(order.delivery_notes).to eq("Ring doorbell twice")
          expect(order.delivery_date).to eq(Date.tomorrow)
          expect(order.delivery_time_slot).to eq("9:00 AM - 12:00 PM")
        end
      end

      it "maps address fields correctly into billing_address" do
        order = result.resource

        expect(order.billing_address).to eq({
          "first_name" => "John",
          "last_name" => "Doe",
          "address_line_1" => "123 Main Street",
          "address_line_2" => "Apt 4B",
          "city" => "Beirut",
          "landmarks" => "Near ABC Mall"
        })
      end

      it "creates order items from cart items" do
        order = result.resource

        expect(order.order_items.count).to eq(1)

        order_item = order.order_items.first
        expect(order_item.product_variant).to eq(cart_item.product_variant)
        expect(order_item.quantity).to eq(2)
        expect(order_item.unit_price_cents).to eq(cart_item.price_snapshot_cents)
      end

      it "calculates order totals" do
        order = result.resource

        expected_subtotal = cart_item.total_price
        expect(order.subtotal).to eq(expected_subtotal)
        expect(order.total).to eq(expected_subtotal)
      end

      it "returns the order in the result" do
        expect(result.order).to eq(result.resource)
      end

      context "when user is signed in" do
        let(:user) { create(:user) }

        before do
          allow(Current).to receive(:user).and_return(user)
        end

        it "associates the order with the current user" do
          order = result.resource
          expect(order.user).to eq(user)
        end
      end

      context "when user is not signed in" do
        before do
          allow(Current).to receive(:user).and_return(nil)
        end

        it "creates order without user association" do
          order = result.resource
          expect(order.user).to be_nil
        end
      end
    end

    context "with pickup delivery method" do
      let(:customer_info) do
        {
          email: "customer@example.com",
          phone_number: "70-123-456",
          first_name: "John",
          last_name: "Doe",
          delivery_method: "pickup",
          payment_method: "cod"
        }
      end

      it "creates order with empty billing_address" do
        order = result.resource
        expect(order.billing_address).to eq({})
      end

      it "doesn't require address fields" do
        expect(result).to be_success
        expect(result.resource.delivery_method).to eq("pickup")
      end
    end

    context "with different payment methods" do
      context "when payment method is cod" do
        let(:customer_info) { super().merge(payment_method: "cod") }

        it "sets payment status to cod_due" do
          order = result.resource
          expect(order.payment_status).to eq("cod_due")
        end
      end

      context "when payment method is not cod" do
        let(:customer_info) { super().merge(payment_method: "credit_card") }

        it "sets payment status to payment_pending" do
          order = result.resource
          expect(order.payment_status).to eq("payment_pending")
        end
      end
    end

    context "with partial address information" do
      let(:customer_info) do
        super().merge(
          address_line_2: "",
          landmarks: nil
        )
      end

      it "only includes non-blank address fields" do
        order = result.resource

        expect(order.billing_address).to eq({
          "first_name" => "John",
          "last_name" => "Doe",
          "address_line_1" => "123 Main Street",
          "city" => "Beirut"
        })
      end
    end

    context "with validation errors" do
      let(:customer_info) { super().merge(email: "invalid-email") }

      it "returns a failure result" do
        expect(result).to be_failure
        expect(result.success?).to be false
      end

      it "includes validation error message" do
        expect(result.errors).to include("We couldn't create your order. Please check your information and try again.")
      end

      it "logs the validation error" do
        result
        expect(Rails.logger).to have_received(:error).with(/Orders::CreateService validation error/)
      end

      it "doesn't create an order" do
        expect { result }.not_to change(Order, :count)
      end

      it "doesn't create order items" do
        expect { result }.not_to change(OrderItem, :count)
      end
    end

    context "with missing cart" do
      subject(:result) { described_class.call(cart: nil, customer_info: customer_info) }

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "returns appropriate error message" do
        expect(result.errors).to include("Cart is required")
      end
    end

    context "with empty cart" do
      let(:empty_cart) { create(:cart) }
      subject(:result) { described_class.call(cart: empty_cart, customer_info: customer_info) }

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "returns appropriate error message" do
        expect(result.errors).to include("Cart is empty")
      end
    end

    context "with missing customer information" do
      let(:customer_info) { nil }

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "returns appropriate error message" do
        expect(result.errors).to include("Customer information is required")
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Order).to receive(:create!).and_raise(StandardError.new("Database connection lost"))
      end

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "returns generic error message" do
        expect(result.errors).to include("Something went wrong. Please try again.")
      end

      it "logs the unexpected error" do
        result
        expect(Rails.logger).to have_received(:error).with(/Orders::CreateService unexpected error/)
      end
    end

    context "transaction rollback scenarios" do
      context "when order item creation fails" do
        before do
          allow(OrderItem).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(OrderItem.new))
        end

        it "doesn't create an order" do
          expect { result }.not_to change(Order, :count)
        end

        it "doesn't create any order items" do
          expect { result }.not_to change(OrderItem, :count)
        end

        it "returns a failure result" do
          expect(result).to be_failure
        end
      end

      context "when total calculation fails" do
        before do
          allow_any_instance_of(Order).to receive(:calculate_totals!).and_raise(StandardError.new("Calculation error"))
        end

        it "rolls back the entire transaction" do
          expect { result }.not_to change(Order, :count)
          expect { result }.not_to change(OrderItem, :count)
        end
      end
    end
  end

  describe "private methods" do
    let(:service) { described_class.new(cart: cart, customer_info: customer_info) }

    describe "#build_billing_address" do
      context "for courier delivery" do
        it "builds address hash from customer info" do
          expect(service.send(:build_billing_address)).to eq({
            first_name: "John",
            last_name: "Doe",
            address_line_1: "123 Main Street",
            address_line_2: "Apt 4B",
            city: "Beirut",
            landmarks: "Near ABC Mall"
          })
        end

        context "with blank address fields" do
          let(:customer_info) { super().merge(address_line_2: "", landmarks: nil) }

          it "excludes blank fields" do
            expect(service.send(:build_billing_address)).to eq({
              first_name: "John",
              last_name: "Doe",
              address_line_1: "123 Main Street",
              city: "Beirut"
            })
          end
        end
      end

      context "for pickup delivery" do
        let(:customer_info) { super().merge(delivery_method: "pickup") }

        it "returns empty hash" do
          expect(service.send(:build_billing_address)).to eq({})
        end
      end
    end

    describe "#courier_delivery?" do
      context "when delivery method is courier" do
        it "returns true" do
          expect(service.send(:courier_delivery?)).to be true
        end
      end

      context "when delivery method is pickup" do
        let(:customer_info) { super().merge(delivery_method: "pickup") }

        it "returns false" do
          expect(service.send(:courier_delivery?)).to be false
        end
      end
    end

    describe "#determine_payment_status" do
      context "when payment method is cod" do
        it "returns cod_due" do
          expect(service.send(:determine_payment_status)).to eq("cod_due")
        end
      end

      context "when payment method is not cod" do
        let(:customer_info) { super().merge(payment_method: "credit_card") }

        it "returns payment_pending" do
          expect(service.send(:determine_payment_status)).to eq("payment_pending")
        end
      end
    end
  end
end
