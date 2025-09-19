# frozen_string_literal: true

RSpec.describe "Checkout", type: :request do
  let!(:product) { create(:product, active: true) }
  let!(:variant) { create(:product_variant, :high_stock, product: product, size_value: 30, size_unit: "ml", size_type: "volume", color_hex: "#000000", sku: "SKU-M-BLK") }
  let!(:cart) { create(:cart, :with_items, items_count: 2) }
  let!(:empty_cart) { create(:cart) }

  before do
    allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(cart)
  end

  describe "GET /checkout" do
    context "when cart has items" do
      it "renders the checkout form successfully" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("checkout")
        end
      end
    end

    context "when cart is empty" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(empty_cart)
      end

      it "redirects to cart page with alert" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to redirect_to(cart_path)
          expect(flash[:alert]).to eq(I18n.t("checkout.cart_empty"))
        end
      end
    end

    context "when no cart exists" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(nil)
      end

      it "redirects to cart page with alert" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to redirect_to(cart_path)
          expect(flash[:alert]).to eq(I18n.t("checkout.cart_empty"))
        end
      end
    end
  end

  describe "POST /checkout" do
    let(:valid_checkout_params) do
      {
        checkout_form: {
          email: "customer@example.com",
          phone_number: "+96170123456",
          first_name: "John",
          last_name: "Doe",
          address_line_1: "123 Main Street",
          address_line_2: "Apt 4B",
          city: "Beirut",
          landmarks: "Near ABC Bank",
          delivery_method: "courier",
          payment_method: "cod",
          delivery_notes: "Ring the bell twice",
          delivery_date: Date.tomorrow,
          delivery_time_slot: "9:00 AM - 12:00 PM"
        }
      }
    end

    let(:invalid_checkout_params) do
      {
        checkout_form: {
          email: "invalid-email",
          phone_number: "",
          first_name: "",
          last_name: ""
        }
      }
    end

    context "with valid checkout form and successful order creation" do
      let(:order) { create(:order, :cod, number: "ORD-12345") }
      let(:success_result) do
        double(
          success?: true,
          resource: order,
          order: order
        )
      end
      let(:clear_cart_success) { double(success?: true) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(success_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_cart_success)
      end

      it "creates order, clears cart, and redirects to confirmation" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to redirect_to(checkout_confirmation_path(order.number))
          expect(flash[:notice]).to eq(I18n.t("checkout.order_placed_successfully"))
          expect(Orders::CreateService).to have_received(:call).with(
            cart: cart,
            customer_info: instance_of(Hash)
          )
          expect(Carts::ClearService).to have_received(:call).with(cart: cart)
        end
      end

      it "passes correct customer information to Orders::CreateService" do
        post checkout_path, params: valid_checkout_params

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
      let(:order) { create(:order, :cod, number: "ORD-12345") }
      let(:success_result) do
        double(
          success?: true,
          resource: order,
          order: order
        )
      end
      let(:clear_cart_failure) { double(success?: false, errors: [ "Failed to clear cart" ]) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(success_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_cart_failure)
        allow(Rails.logger).to receive(:error)
      end

      it "still redirects to confirmation but logs the error" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to redirect_to(checkout_confirmation_path(order.number))
          expect(flash[:notice]).to eq(I18n.t("checkout.order_placed_successfully"))
          expect(Rails.logger).to have_received(:error).with(/Failed to clear cart/)
        end
      end
    end

    context "when order creation fails" do
      let(:failure_result) do
        double(
          success?: false,
          errors: [ "Payment method not available", "Delivery slot unavailable" ]
        )
      end

      before do
        allow(Orders::CreateService).to receive(:call).and_return(failure_result)
      end

      it "re-renders the form with service errors" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("checkout")
          expect(flash[:alert]).to eq("Payment method not available, Delivery slot unavailable")
        end
      end
    end

    context "with invalid checkout form parameters" do
      it "re-renders the form with validation errors" do
        post checkout_path, params: invalid_checkout_params

        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("checkout")
        end
      end
    end

    context "when cart is empty" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(empty_cart)
      end

      it "redirects to cart page before processing" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to redirect_to(cart_path)
          expect(flash[:alert]).to eq(I18n.t("checkout.cart_empty"))
        end
      end
    end
  end

  describe "GET /checkout/:id" do
    let(:order) { create(:order, :cod, number: "ORD-12345") }

    context "when order exists" do
      it "renders the order confirmation page" do
        get checkout_confirmation_path(order.number)

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(order.number)
        end
      end
    end

    context "when order does not exist" do
      it "returns not found" do
        get checkout_confirmation_path("INVALID-NUMBER")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /checkout/delivery_schedule" do
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "with courier delivery method" do
      let(:params) { { delivery_method: "courier" } }

      it "responds with turbo stream for courier delivery schedule" do
        post checkout_delivery_schedule_path, params: params, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "with pickup delivery method" do
      let(:params) { { delivery_method: "pickup" } }

      it "responds with turbo stream for pickup schedule" do
        post checkout_delivery_schedule_path, params: params, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "without delivery method parameter" do
      it "defaults to pickup method" do
        post checkout_delivery_schedule_path, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "with invalid delivery method parameter" do
      let(:params) { { delivery_method: "rocket" } }

      it "defaults to pickup method for invalid values" do
        post checkout_delivery_schedule_path, params: params, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "with HTML request" do
      it "responds only to turbo_stream format" do
        post checkout_delivery_schedule_path, params: { delivery_method: "courier" }
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "form state preservation" do
    let(:form_data) do
      {
        email: "test@example.com",
        first_name: "John",
        last_name: "Doe",
        delivery_method: "courier"
      }
    end
    let(:checkout_params) { { checkout_form: form_data } }

    context "when form submission fails" do
      let(:failure_result) do
        double(success?: false, errors: [ "Some validation error" ])
      end

      before do
        allow(Orders::CreateService).to receive(:call).and_return(failure_result)
      end

      it "stores form data in session for later use" do
        post checkout_path, params: checkout_params

        expect(session[:checkout_form_data]).to include(
          "email" => "test@example.com",
          "first_name" => "John",
          "last_name" => "Doe",
          "delivery_method" => "courier"
        )
      end

      it "preserves form data when switching delivery methods" do
        # Submit form data first
        post checkout_path, params: checkout_params

        # Now call delivery_schedule which should restore the form data
        post checkout_delivery_schedule_path,
             params: { delivery_method: "pickup" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        # Form data should be preserved in the controller instance variable
        # (we can't directly test @checkout_form but the session should persist)
        expect(session[:checkout_form_data]).to include("email" => "test@example.com")
      end
    end

    context "when order is successfully created" do
      let(:order) { create(:order, :cod, number: "ORD-SUCCESS") }
      let(:success_result) { double(success?: true, resource: order, order: order) }
      let(:clear_cart_success) { double(success?: true) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(success_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_cart_success)
      end

      it "clears form data from session" do
        # First store some form data
        post checkout_path, params: checkout_params
        expect(session[:checkout_form_data]).to be_present

        # Create a new session to simulate form submission with valid data
        valid_params = {
          checkout_form: {
            email: "customer@example.com",
            phone_number: "+96170123456",
            first_name: "Jane",
            last_name: "Smith",
            delivery_method: "pickup",
            payment_method: "cod"
          }
        }

        post checkout_path, params: valid_params

        expect(session[:checkout_form_data]).to be_nil
      end
    end
  end

  describe "checkout flow integration" do
    let(:checkout_params) do
      {
        checkout_form: {
          email: "integration@example.com",
          phone_number: "+96170987654",
          first_name: "Jane",
          last_name: "Smith",
          address_line_1: "456 Oak Avenue",
          city: "Beirut",
          delivery_method: "pickup",
          payment_method: "cod"
        }
      }
    end

    context "complete successful flow" do
      let(:order) { create(:order, :pickup, :cod, number: "ORD-FLOW-TEST") }
      let(:success_result) { double(success?: true, resource: order, order: order) }
      let(:clear_cart_success) { double(success?: true) }

      before do
        allow(Orders::CreateService).to receive(:call).and_return(success_result)
        allow(Carts::ClearService).to receive(:call).and_return(clear_cart_success)
      end

      it "completes the entire checkout process" do
        # Start checkout
        get new_checkout_path
        expect(response).to have_http_status(:ok)

        # Submit order
        post checkout_path, params: checkout_params
        expect(response).to redirect_to(checkout_confirmation_path(order.number))

        # View confirmation
        get checkout_confirmation_path(order.number)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(order.number)
      end
    end
  end
end
