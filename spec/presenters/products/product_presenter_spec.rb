# frozen_string_literal: true

RSpec.describe Products::ProductPresenter do
  subject(:presenter) { described_class.new(product) }

  let(:brand) { create(:brand, name: "Test Brand") }
  let(:product) do
    create(:product,
      name: "Test Lipstick",
      subtitle: "Premium Formula",
      brand: brand,
      reviews_count: 42
    )
  end

  let(:reviews) do
    [
      create(:review, product: product, rating: 5),
      create(:review, product: product, rating: 4),
      create(:review, product: product, rating: 4)
    ]
  end

  let(:variant1) do
    create(:product_variant,
      product: product,
      name: "Red Variant",
      color: "Red",
      color_hex: "#FF0000",
      size_value: 3.5,
      size_unit: "ml",
      size_type: "volume",
      sku: "TEST-001",
      price: Money.new(2500),
      stock_quantity: 10
    )
  end

  let(:variant2) do
    create(:product_variant,
      product: product,
      name: "Blue Variant",
      color: "Blue",
      color_hex: "#0000FF",
      size_value: 5.0,
      size_unit: "ml",
      size_type: "volume",
      sku: "TEST-002",
      price: Money.new(3000),
      compare_at_price: Money.new(3500),
      stock_quantity: 3
    )
  end

  let(:out_of_stock_variant) do
    create(:product_variant,
      product: product,
      name: "Green Variant",
      color: "Green",
      color_hex: "#00FF00",
      sku: "TEST-003",
      price: Money.new(2000),
      stock_quantity: 0
    )
  end

  before do
    [ variant1, variant2, out_of_stock_variant ]
    reviews
  end

  describe "#initialize" do
    context "when product variants are not preloaded" do
      it "loads variants with image associations" do
        expect(product.product_variants).to receive(:loaded?).and_return(false)
        expect(product.product_variants).to receive(:includes)
          .with(featured_image_attachment: :blob, images_attachments: :blob)
          .and_call_original

        presenter = described_class.new(product)

        expect(presenter.variants).to be_present
        expect(presenter.variants).to all(be_a(ProductVariant))
      end
    end

    context "when product variants are already preloaded" do
      it "uses the preloaded variants" do
        product.product_variants.load
        expect(product.product_variants).to receive(:loaded?).and_return(true)
        expect(product.product_variants).not_to receive(:includes)

        presenter = described_class.new(product)

        expect(presenter.variants).to be_present
      end
    end
  end

  describe "#build_static_data" do
    let(:static_data) { presenter.build_static_data }

    it "returns a ProductDisplayData instance" do
      expect(static_data).to be_a(Products::ProductDisplayData)
    end

    it "includes product_info with correct attributes" do
      product_info = static_data.product_info

      aggregate_failures do
        expect(product_info).to be_a(Products::ProductInfo)
        expect(product_info.name).to eq("Test Lipstick")
        expect(product_info.subtitle).to eq("Premium Formula")
        expect(product_info.brand_name).to eq("Test Brand")
        expect(product_info.reviews_count).to eq(45)
        expect(product_info.rating).to eq(4.3)
      end
    end

    it "includes all_variants data" do
      all_variants = static_data.all_variants

      expect(all_variants).to be_an(Array)
      expect(all_variants.size).to eq(3)

      red_variant_data = all_variants.find { |v| v[:color] == "Red" }
      expect(red_variant_data).to include(
        id: variant1.id,
        name: "Red Variant",
        color: "Red",
        color_hex: "#FF0000",
        size_value: 3.5,
        size_unit: "ml",
        size_type: "volume",
        sku: "TEST-001"
      )
    end

    context "when brand is nil" do
      let(:product) { create(:product, brand: nil) }

      it "uses fallback brand name" do
        expect(static_data.product_info.brand_name).to eq("Beauty Store")
      end
    end
  end

  describe "#build_dynamic_data" do
    let(:dynamic_data) { presenter.build_dynamic_data(selected_variant: variant1) }

    it "returns a ProductDisplayData instance" do
      expect(dynamic_data).to be_a(Products::ProductDisplayData)
    end

    it "includes default_variant data for selected variant" do
      default_variant = dynamic_data.default_variant

      expect(default_variant).to include(
        id: variant1.id,
        name: "Red Variant",
        color: "Red",
        color_hex: "#FF0000"
      )
    end

    it "includes variant_images for selected variant only" do
      variant_images = dynamic_data.variant_images

      expect(variant_images).to be_a(Hash)
      expect(variant_images.keys).to contain_exactly(variant1.id)
    end

    it "includes price_matrix with all variants" do
      price_matrix = dynamic_data.price_matrix

      expect(price_matrix).to be_a(Hash)
      expect(price_matrix.keys).to match_array([ variant1.id, variant2.id, out_of_stock_variant.id ])

      expect(price_matrix[variant1.id]).to include(
        current_cents: 2500,
        currency: "USD",
        on_sale: false,
        formatted_current_price: be_a(String)
      )

      expect(price_matrix[variant2.id]).to include(
        current_cents: 3000,
        original_cents: 3500,
        currency: "USD",
        on_sale: true,
        discount_percentage: be_a(Numeric),
        formatted_current_price: be_a(String),
        formatted_original_price: be_a(String)
      )
    end

    it "includes stock_matrix with all variants" do
      stock_matrix = dynamic_data.stock_matrix

      expect(stock_matrix).to be_a(Hash)
      expect(stock_matrix.keys).to match_array([ variant1.id, variant2.id, out_of_stock_variant.id ])

      expect(stock_matrix[variant1.id]).to include(
        available: true,
        message: be_a(String),
        quantity: 10
      )

      expect(stock_matrix[variant2.id]).to include(
        available: true,
        message: be_a(String),
        quantity: 3
      )

      expect(stock_matrix[out_of_stock_variant.id]).to include(
        available: false,
        message: be_a(String),
        quantity: 0
      )
    end

    it "includes variant_options with colors and sizes" do
      variant_options = dynamic_data.variant_options

      aggregate_failures do
        expect(variant_options).to be_a(Hash)
        expect(variant_options).to have_key(:colors)
        expect(variant_options).to have_key(:sizes)

        colors = variant_options[:colors]
        expect(colors).to be_an(Array)
        expect(colors.size).to eq(3)

        red_color = colors.find { |c| c.name == "Red" }
        expect(red_color.value).to eq("#FF0000")
        expect(red_color.type).to eq(:color)
        expect(red_color.variant_id).to eq(variant1.id)

        sizes = variant_options[:sizes]
        expect(sizes).to be_an(Array)
        expect(sizes.map(&:name)).to include("3.5", "5")
        expect(sizes.size).to be >= 2
      end
    end

    context "when selected_variant is nil" do
      let(:dynamic_data) { presenter.build_dynamic_data(selected_variant: nil) }

      it "handles nil selected_variant gracefully" do
        aggregate_failures do
          expect(dynamic_data.default_variant).to be_nil
          expect(dynamic_data.variant_images).to eq({})
          expect(dynamic_data.price_matrix).to be_present
          expect(dynamic_data.stock_matrix).to be_present
        end
      end
    end
  end

  describe "#build_variant_images_mapping" do
    let(:variant_with_image) { variant1 }

    before do
      allow(variant_with_image).to receive(:featured_image).and_return(
        double("attachment", attached?: true)
      )
      allow(variant_with_image).to receive(:images).and_return(
        double("images", attached?: true, any?: true, each_with_index: nil)
      )
    end

    it "returns a hash mapping variant IDs to image arrays" do
      mapping = presenter.build_variant_images_mapping

      expect(mapping).to be_a(Hash)
      expect(mapping.keys).to match_array([ variant1.id, variant2.id, out_of_stock_variant.id ])
    end

    it "caches the result on subsequent calls" do
      first_call = presenter.build_variant_images_mapping
      second_call = presenter.build_variant_images_mapping

      expect(first_call).to be(second_call)
    end

    context "when image processing fails" do
      before do
        allow(variant1).to receive(:featured_image).and_raise(StandardError, "Image error")
        allow(Rails.logger).to receive(:warn)
      end

      it "gracefully handles errors and continues processing" do
        mapping = presenter.build_variant_images_mapping

        aggregate_failures do
          expect(mapping).to have_key(variant1.id)
          expect(mapping[variant1.id]).to eq([])

          expect(mapping).to have_key(variant2.id)
          expect(mapping).to have_key(out_of_stock_variant.id)
        end
      end
    end
  end

  describe "private methods behavior" do
    describe "price calculation logic" do
      context "when variant has no price" do
        let(:no_price_variant) do
          build(:product_variant, price: nil, cost: Money.new(0))
        end

        before do
          allow(presenter).to receive(:variants).and_return([ no_price_variant ])
        end

        it "handles missing price gracefully" do
          dynamic_data = presenter.build_dynamic_data(selected_variant: no_price_variant)
          price_info = dynamic_data.price_matrix[no_price_variant.id]

          expect(price_info).to include(
            current_cents: 0,
            currency: "USD",
            on_sale: false,
            formatted_current_price: be_a(String)
          )
        end
      end
    end

    describe "variant sorting and filtering" do
      let(:size_variant1) { create(:product_variant, product: product, size_value: 10, size_type: "volume") }
      let(:size_variant2) { create(:product_variant, product: product, size_value: 5, size_type: "volume") }
      let(:weight_variant) { create(:product_variant, product: product, size_value: 100, size_type: "weight") }

      before do
        [ size_variant1, size_variant2, weight_variant ]
      end

      it "sorts sizes correctly in variant options" do
        dynamic_data = presenter.build_dynamic_data(selected_variant: variant1)
        sizes = dynamic_data.variant_options[:sizes]
        size_values = sizes.map { |s| s.name.to_f }

        expect(size_values.first(2)).to eq([ 3.5, 5.0 ])
      end
    end

    describe "unique filtering" do
      let(:duplicate_color_variant) do
        create(:product_variant,
          product: product,
          color: "Different Red Name",
          color_hex: "#FF0000"
        )
      end

      before do
        duplicate_color_variant
      end

      it "filters out duplicate colors by hex value" do
        dynamic_data = presenter.build_dynamic_data(selected_variant: variant1)
        colors = dynamic_data.variant_options[:colors]

        red_colors = colors.select { |c| c.value == "#FF0000" }
        expect(red_colors.size).to eq(1)
      end
    end
  end
end
