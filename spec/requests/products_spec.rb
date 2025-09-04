RSpec.describe "Products", type: :request do
  let!(:product) { create(:product, active: true) }
  let!(:variant_m_black) { create(:product_variant, product: product, size_value: 30, size_unit: "ml", size_type: "volume", color_hex: "#000000", sku: "SKU-M-BLK") }
  let!(:variant_l_blue) { create(:product_variant, product: product, size_value: 50, size_unit: "ml", size_type: "volume", color_hex: "#0000FF", sku: "SKU-L-BLU") }

  describe "GET /show" do
    context "when the product is active" do
      it "returns a successful response and renders the show template" do
        get product_path(product)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(product.name)
      end
    end

    context "when the product is not found or unavailable" do
      it "returns a not_found (404) response" do
        get product_path(id: -1)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /update_variant" do
    let(:valid_params) do
      {
        product: {
          color: variant_m_black.color_hex,
          size: variant_m_black.size_key
        }
      }
    end

    context "with a Turbo Stream request" do
      let(:headers) { { "Accept": "text/vnd.turbo-stream.html" } }

      context "with valid variant parameters" do
        it "responds with the correct turbo streams for the selected variant" do
          patch update_variant_product_path(product), params: valid_params, headers: headers

          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include('<turbo-stream action="replace" target="product-pricing">')
            expect(response.body).to include('<turbo-stream action="replace" target="product-gallery">')
            expect(response.body).to include('<turbo-stream action="replace" target="variant-selector">')
            expect(response.body).to include(variant_m_black.sku)
          end
        end

        it "includes the correct SKU update in the turbo stream response" do
          patch update_variant_product_path(product), params: valid_params, headers: headers

          aggregate_failures do
            expect(response.body).to include('<turbo-stream action="update" targets=".sku-display">')
            expect(response.body).to include("<template>#{variant_m_black.sku}</template>")
          end
        end
      end

      context "when an error occurs during partial rendering" do
        it "returns fallback turbo_stream frames with error messages" do
          allow_any_instance_of(ProductsController).to receive(:render_pricing_partial).and_raise("Test rendering error")

          patch update_variant_product_path(product), params: valid_params, headers: headers

          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include("Error loading pricing")
            expect(response.body).to include("Error loading gallery")
          end
        end
      end

      context "with invalid variant parameters" do
        let(:invalid_params) { { product: { color: "#123456", size: "XXL" } } }

        it "falls back gracefully (e.g., to the default variant)" do
          default_variant = product.default_variant

          patch update_variant_product_path(product), params: invalid_params, headers: headers

          expect(response).to be_successful
          expect(response.body).to include(default_variant.sku)
        end
      end
    end

    context "with an HTML request" do
      it "redirects to the product show page with variant params" do
        patch update_variant_product_path(product), params: valid_params

        expect(response).to redirect_to(
          product_path(
            product,
            color: valid_params.dig(:product, :color),
            size: valid_params.dig(:product, :size)
          )
        )
      end
    end
  end
end
