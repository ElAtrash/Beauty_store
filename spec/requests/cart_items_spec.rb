RSpec.describe "CartItems", type: :request do
  let!(:product) { create(:product, active: true) }
  let!(:variant) { create(:product_variant, :high_stock, product: product, size_value: 30, size_unit: "ml", size_type: "volume", color_hex: "#000000", sku: "SKU-M-BLK") }
  let!(:cart) { create(:cart) }
  let!(:cart_item) { create(:cart_item, cart: cart, product_variant: variant, quantity: 2) }

  before do
    allow_any_instance_of(CartItemsController).to receive(:current_cart).and_return(cart)
  end

  describe "POST /cart/items" do
    let(:another_variant) { create(:product_variant, :high_stock, product: product) }
    let(:valid_params) do
      {
        product_variant_id: another_variant.id,
        quantity: 1
      }
    end

    context "with a Turbo Stream request" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      context "with successful service call" do
        let(:success_result) do
          double(
            success?: true,
            resource: create(:cart_item, cart: cart, product_variant: another_variant, quantity: 1),
            cart: cart
          )
        end

        before do
          allow(Carts::AddItemService).to receive(:call).and_return(success_result)
        end

        it "responds with turbo streams including notification" do
          post cart_items_path, params: valid_params, headers: headers

          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include('<turbo-stream action="replace" target="cart-badge">')
            expect(response.body).to include('<turbo-stream action="replace" target="cart-popup-body">')
            expect(response.body).to include('<turbo-stream action="prepend" target="notifications">')
            expect(response.body).to include("Added to cart!")
            expect(response.body).to include('notification-success')
          end
        end

        it "includes rich notification with product details" do
          post cart_items_path, params: valid_params, headers: headers

          aggregate_failures do
            expect(response.body).to include(product.name)
            expect(response.body).to include('data-controller="auto-dismiss"')
            expect(response.body).to include('data-auto-dismiss-delay-value="3000"')
          end
        end
      end

      context "when service fails" do
        let(:failure_result) do
          double(success?: false, errors: [ "Product out of stock" ], cart: cart)
        end

        before do
          allow(Carts::AddItemService).to receive(:call).and_return(failure_result)
        end

        it "responds with error turbo stream" do
          post cart_items_path, params: valid_params, headers: headers

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with an HTML request" do
      let(:success_result) do
        double(
          success?: true,
          resource: create(:cart_item, cart: cart, product_variant: another_variant, quantity: 1),
          cart: cart
        )
      end

      before do
        allow(Carts::AddItemService).to receive(:call).and_return(success_result)
      end

      it "creates cart item and redirects back" do
        post cart_items_path, params: valid_params

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PATCH /cart/items/:id/update_quantity" do
    context "with a Turbo Stream request" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      context "when incrementing quantity" do
        let(:success_result) { double(success?: true, cart: cart) }

        before do
          allow(Carts::ItemUpdateService).to receive(:increment).and_return(success_result)
        end

        it "updates quantity and responds without notification" do
          patch update_quantity_cart_item_path(cart_item), params: { quantity_action: "increment" }, headers: headers

          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include('<turbo-stream action="replace" target="cart-badge">')
            expect(response.body).to include('<turbo-stream action="replace" target="cart-popup-body">')
            expect(response.body).not_to include('<turbo-stream action="prepend" target="notifications">')
          end
        end
      end

      context "when service fails" do
        let(:failure_result) { double(success?: false, errors: [ "Unable to update quantity" ]) }

        before do
          allow(Carts::ItemUpdateService).to receive(:increment).and_return(failure_result)
        end

        it "responds with error" do
          patch update_quantity_cart_item_path(cart_item), params: { quantity_action: "increment" }, headers: headers

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "DELETE /cart/items/:id" do
    context "with a Turbo Stream request" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
      let(:success_result) { double(success?: true, cart: cart) }

      before do
        allow(Carts::ItemUpdateService).to receive(:set_quantity).and_return(success_result)
      end

      it "removes cart item without showing notification" do
        delete cart_item_path(cart_item), headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(response.body).to include('<turbo-stream action="replace" target="cart-badge">')
          expect(response.body).to include('<turbo-stream action="replace" target="cart-popup-body">')
          expect(response.body).not_to include('<turbo-stream action="prepend" target="notifications">')
        end
      end
    end
  end

  describe "DELETE /cart/items/clear_all" do
    context "with a Turbo Stream request" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
      let(:success_result) { double(success?: true, cleared_variants: [ variant ]) }

      before do
        allow(Carts::ClearService).to receive(:call).and_return(success_result)
      end

      it "clears all cart items and shows notification" do
        delete clear_all_cart_items_path, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(response.body).to include('<turbo-stream action="replace" target="cart-badge">')
          expect(response.body).to include('<turbo-stream action="replace" target="cart-popup-body">')
          expect(response.body).to include('<turbo-stream action="prepend" target="notifications">')
          expect(response.body).to include("Cart cleared successfully")
        end
      end
    end
  end

  describe "notification behavior summary" do
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
    let(:another_variant) { create(:product_variant, :high_stock, product: product) }

    context "first-time add to cart (create action)" do
      let(:success_result) do
        double(
          success?: true,
          resource: create(:cart_item, cart: cart, product_variant: another_variant, quantity: 1),
          cart: cart
        )
      end

      before do
        allow(Carts::AddItemService).to receive(:call).and_return(success_result)
      end

      it "shows rich notification with product details" do
        post cart_items_path, params: { product_variant_id: another_variant.id, quantity: 1 }, headers: headers

        aggregate_failures do
          expect(response.body).to include('<turbo-stream action="prepend" target="notifications">')
          expect(response.body).to include("Added to cart!")
          expect(response.body).to include(product.name)
          expect(response.body).to include('notification-success')
        end
      end
    end

    context "quantity updates (update_quantity action)" do
      let(:success_result) { double(success?: true, cart: cart) }

      before do
        allow(Carts::ItemUpdateService).to receive(:increment).and_return(success_result)
      end

      it "does not show any notification" do
        patch update_quantity_cart_item_path(cart_item), params: { quantity_action: "increment" }, headers: headers

        expect(response.body).not_to include('<turbo-stream action="prepend" target="notifications">')
      end
    end
  end
end
