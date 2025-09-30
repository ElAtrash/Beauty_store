# frozen_string_literal: true

RSpec.describe "Checkout", type: :request do
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

      it "redirects to homepage with alert" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(I18n.t("checkout.cart_empty"))
        end
      end
    end

    context "when no cart exists" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(nil)
      end

      it "redirects to homepage with alert" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(I18n.t("checkout.cart_empty"))
        end
      end
    end

    context "when cart validation raises an exception" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_raise(StandardError, "Database connection error")
        allow(Rails.logger).to receive(:error)
      end

      it "redirects to root with generic error message" do
        get new_checkout_path

        aggregate_failures do
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(I18n.t("errors.something_went_wrong"))
          expect(Rails.logger).to have_received(:error).with(/Cart validation error: Database connection error/)
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
          city: "Beirut",
          delivery_method: "courier",
          payment_method: "cod",
          delivery_date: Date.tomorrow,
          delivery_time_slot: "09:00-12:00"
        }
      }
    end

    context "with successful order creation" do
      let(:order) { create(:order, :cod, number: "ORD-12345") }
      let(:success_result) { double(success?: true, resource: order, order: order) }

      before do
        allow(Checkout::ProcessOrderService).to receive(:call).and_return(success_result)
      end

      it "creates order and redirects to confirmation" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to redirect_to(checkout_confirmation_path(order.number))
          expect(flash[:notice]).to eq(I18n.t("checkout.order_placed_successfully"))
          expect(Checkout::ProcessOrderService).to have_received(:call).with(
            checkout_form: instance_of(CheckoutForm),
            cart: cart,
            session: session
          )
        end
      end
    end

    context "when order creation fails with validation errors" do
      let(:validation_failure_result) do
        double(success?: false, errors: [ "Email is invalid" ], error_type: :validation)
      end

      before do
        allow(Checkout::ProcessOrderService).to receive(:call).and_return(validation_failure_result)
      end

      it "re-renders the form with validation errors" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("checkout")
          expect(flash[:alert]).to eq("Email is invalid")
        end
      end
    end

    context "when order creation fails with service errors" do
      let(:service_failure_result) do
        double(success?: false, errors: [ "Service unavailable" ], error_type: :service)
      end

      before do
        allow(Checkout::ProcessOrderService).to receive(:call).and_return(service_failure_result)
      end

      it "re-renders the form with service errors" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("checkout")
          expect(flash[:alert]).to eq("Service unavailable")
        end
      end
    end

    context "when process order service raises an exception" do
      before do
        allow(Checkout::ProcessOrderService).to receive(:call).and_raise(StandardError, "Unexpected service error")
        allow(Rails.logger).to receive(:error)
      end

      it "handles exception and renders form with generic error" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("checkout")
          expect(flash[:alert]).to eq(I18n.t("errors.something_went_wrong"))
          expect(Rails.logger).to have_received(:error).with(/Order processing error: Unexpected service error/)
        end
      end
    end

    context "when cart is empty" do
      before do
        allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(empty_cart)
      end

      it "redirects to homepage before processing" do
        post checkout_path, params: valid_checkout_params

        aggregate_failures do
          expect(response).to redirect_to(root_path)
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
      it "returns not found status" do
        get checkout_confirmation_path("INVALID-NUMBER")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /checkout/delivery_schedule" do
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "with courier delivery method" do
      it "responds with turbo stream for courier delivery schedule" do
        post checkout_delivery_schedule_path, params: { delivery_method: "courier" }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "with pickup delivery method" do
      it "responds with turbo stream for pickup schedule" do
        post checkout_delivery_schedule_path, params: { delivery_method: "pickup" }, headers: headers

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

  describe "POST /checkout/delivery_summary" do
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "with pickup delivery method" do
      it "responds with turbo stream and persists delivery method" do
        post "/checkout/delivery_summary", params: { delivery_method: "pickup" }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(session[:checkout_form_data]).to include("delivery_method" => "pickup")
        end
      end
    end

    context "with courier delivery method and address data" do
      let(:params) do
        {
          delivery_method: "courier",
          address_line_1: "123 Main Street",
          landmarks: "Near ABC Bank"
        }
      end

      it "responds with turbo stream and persists address data" do
        post "/checkout/delivery_summary", params: params, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          form_data = session[:checkout_form_data]
          expect(form_data).to include("delivery_method" => "courier")
          expect(form_data).to include("address_line_1" => "123 Main Street")
          expect(form_data).to include("landmarks" => "Near ABC Bank")
        end
      end
    end

    context "with malicious parameters" do
      let(:params) do
        {
          delivery_method: "courier",
          address_line_1: "123 Main Street",
          malicious_param: "evil_code",
          admin: "true"
        }
      end

      it "only permits allowed address parameters" do
        post "/checkout/delivery_summary", params: params, headers: headers

        form_data = session[:checkout_form_data]
        aggregate_failures do
          expect(form_data).to include("address_line_1" => "123 Main Street")
          expect(form_data).not_to have_key("malicious_param")
          expect(form_data).not_to have_key("admin")
        end
      end
    end

    context "with HTML request" do
      it "responds only to turbo_stream format" do
        post "/checkout/delivery_summary", params: { delivery_method: "courier" }
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "PATCH /checkout" do
    context "with valid JSON request" do
      let(:form_update_params) do
        {
          checkout_form: {
            email: "updated@example.com",
            first_name: "Jane",
            delivery_method: "courier"
          }
        }
      end

      it "responds with ok and persists form data to session" do
        patch update_checkout_path, params: form_update_params, as: :json

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          form_data = session[:checkout_form_data]
          expect(form_data).to include("email" => "updated@example.com")
          expect(form_data).to include("first_name" => "Jane")
          expect(form_data).to include("delivery_method" => "courier")
        end
      end
    end

    context "with non-JSON request" do
      it "responds with not acceptable for non-JSON requests" do
        patch update_checkout_path, params: { checkout_form: { email: "test@example.com" } }
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context "with malicious parameters" do
      let(:malicious_params) do
        {
          checkout_form: {
            email: "test@example.com",
            user_id: "123",
            admin: "true"
          }
        }
      end

      it "only permits allowed parameters" do
        patch update_checkout_path, params: malicious_params, as: :json

        form_data = session[:checkout_form_data]
        aggregate_failures do
          expect(form_data).to include("email" => "test@example.com")
          expect(form_data).not_to have_key("user_id")
          expect(form_data).not_to have_key("admin")
        end
      end
    end
  end

  describe "PATCH /checkout/:id/reorder" do
    let(:order) { create(:order, :cod, number: "ORD-12345") }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "when reorder is successful" do
      let(:success_result) do
        double(
          success?: true,
          cart: cart,
          metadata: { message: "2 items added to cart successfully" }
        )
      end

      before do
        allow(Orders::ReorderService).to receive(:call).and_return(success_result)
      end

      it "responds with turbo stream for successful reorder" do
        post reorder_order_path(order.number), headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(Orders::ReorderService).to have_received(:call).with(
            order: order,
            user: nil,
            session: session,
            cart_token: session[:cart_token]
          )
        end
      end
    end

    context "when reorder fails" do
      let(:failure_result) do
        double(
          success?: false,
          errors: [ "Some items are no longer available" ]
        )
      end

      before do
        allow(Orders::ReorderService).to receive(:call).and_return(failure_result)
      end

      it "responds with turbo stream for failed reorder" do
        post reorder_order_path(order.number), headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end

    context "when reorder service raises an exception" do
      before do
        allow(Orders::ReorderService).to receive(:call).and_raise(StandardError, "Unexpected error")
        allow(Rails.logger).to receive(:error)
      end

      it "handles exception and responds with error turbo stream" do
        post reorder_order_path(order.number), headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(Rails.logger).to have_received(:error).with(/Reorder error: Unexpected error/)
        end
      end
    end

    context "when order does not exist" do
      it "returns not found status" do
        post reorder_order_path("INVALID-NUMBER"), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with HTML request" do
      it "responds to both HTML and turbo_stream formats" do
        success_result = double(success?: true, cart: cart, metadata: { message: "Items added" })
        allow(Orders::ReorderService).to receive(:call).and_return(success_result)

        post reorder_order_path(order.number)

        aggregate_failures do
          expect(response).to redirect_to(checkout_confirmation_path(order.number))
          expect(flash[:notice]).to eq("Items added")
        end
      end
    end
  end
end
