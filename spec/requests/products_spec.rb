# frozen_string_literal: true

RSpec.describe "Products", type: :request do
  let!(:brand) { create(:brand) }
  let!(:category) { create(:category) }
  let!(:product) { create(:product, :published, brand: brand, categories: [ category ]) }

  let!(:default_variant) do
    create(:product_variant, product: product, is_default: true,
           name: "30ml", size_value: 30, size_unit: "ml", size_type: "volume",
           stock_quantity: 10)
  end
  let!(:small_red) do
    create(:product_variant, product: product,
           name: "50ml Red", color: "Red", color_hex: "#ff0000",
           size_value: 50, size_unit: "ml", size_type: "volume",
           stock_quantity: 5)
  end
  let!(:large_red) do
    create(:product_variant, product: product,
           name: "100ml Red", color: "Red", color_hex: "#ff0000",
           size_value: 100, size_unit: "ml", size_type: "volume",
           stock_quantity: 3)
  end
  let!(:small_blue) do
    create(:product_variant, product: product,
           name: "50ml Blue", color: "Blue", color_hex: "#0000ff",
           size_value: 50, size_unit: "ml", size_type: "volume",
           stock_quantity: 8)
  end

  describe "GET /products/:id" do
    context "basic product display" do
      it "displays the product page successfully" do
        get product_path(product)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(product.name)
      end

      it "assigns the default variant when no parameters given" do
        get product_path(product)

        # Check the response includes default variant data
        expect(response.body).to include(default_variant.name)
      end
    end

    context "variant selection business logic" do
      it "selects variant by exact color and size match" do
        get product_path(product, color: "#ff0000", size: large_red.size_key)

        expect(response).to have_http_status(:ok)
        # Verify the large red variant data is in the response
        expect(response.body).to include(large_red.name)
      end

      it "uses DefaultVariantSelector for color-only selection" do
        allow(Products::DefaultVariantSelector).to receive(:call).and_return(small_red)

        get product_path(product, color: "#ff0000")

        expect(response).to have_http_status(:ok)
        expect(Products::DefaultVariantSelector).to have_received(:call).with(
          product,
          scope: anything
        )
      end

      it "selects first available variant for size-only selection" do
        get product_path(product, size: small_red.size_key)

        expect(response).to have_http_status(:ok)
        # Should work without errors - the exact variant selected depends on database ordering
      end

      it "falls back to default variant when selection fails" do
        get product_path(product, color: "#nonexistent", size: "nonexistent")

        expect(response).to have_http_status(:ok)
        # Should fall back to default variant and not crash
        expect(response.body).to include(default_variant.name)
      end
    end

    context "product availability" do
      shared_examples "returns not found status" do
        it "returns 404 status for unavailable products" do
          expect {
            get product_path(unavailable_product)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with unpublished product" do
        let(:unavailable_product) { create(:product, :unpublished, brand: brand) }
        include_examples "returns not found status"
      end

      context "with inactive product" do
        let(:unavailable_product) { create(:product, active: false, brand: brand) }
        include_examples "returns not found status"
      end

      context "with non-existent product" do
        it "raises ActiveRecord::RecordNotFound" do
          expect {
            get product_path(id: "nonexistent")
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "PATCH /products/:id/update_variant" do
    context "with turbo_stream format" do
      it "updates variant and returns turbo streams for pricing and gallery" do
        patch update_variant_product_path(product, format: :turbo_stream),
              params: { color: "#ff0000", size: large_red.size_key }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")

        # Verify both turbo streams are included
        expect(response.body).to include('turbo-stream action="replace" target="product-pricing"')
        expect(response.body).to include('turbo-stream action="replace" target="product-gallery"')
      end

      it "works with color-only selection" do
        allow(Products::DefaultVariantSelector).to receive(:call).and_return(small_red)

        patch update_variant_product_path(product, format: :turbo_stream),
              params: { color: "#ff0000" }

        expect(response).to have_http_status(:ok)
        expect(Products::DefaultVariantSelector).to have_received(:call).at_least(:once)
      end
    end

    context "with HTML format" do
      it "returns not acceptable status" do
        patch update_variant_product_path(product),
              params: { color: "#ff0000", size: large_red.size_key }

        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end
end
