# frozen_string_literal: true

RSpec.describe Products::ProductDisplayData do
  subject(:display_data) { described_class.new(**initialization_params) }

  let(:product_info) { Products::ProductInfo.new(name: "Lipstick", brand_name: "Test Brand") }
  let(:default_variant) { { id: 1, name: "Red Lipstick" } }
  let(:all_variants) { [ default_variant, { id: 2, name: "Blue Lipstick" } ] }
  let(:variant_images) { { 1 => [ "image1.jpg" ], 2 => [ "image2.jpg" ] } }

  let(:price_matrix) do
    {
      1 => { current: "$25.00", original: "$30.00", on_sale: true },
      2 => { current: "$20.00", on_sale: false }
    }
  end

  let(:stock_matrix) do
    {
      1 => { available: true, message: "In stock", quantity: 5 },
      2 => { available: false, message: "Out of stock", quantity: 0 }
    }
  end

  let(:variant_options) do
    [
      Products::VariantOption.new(name: "Color", value: "Red", type: "color", variant_id: 1),
      Products::VariantOption.new(name: "Color", value: "Blue", type: "color", variant_id: 2)
    ]
  end

  let(:initialization_params) do
    {
      product_info: product_info,
      default_variant: default_variant,
      all_variants: all_variants,
      variant_images: variant_images,
      price_matrix: price_matrix,
      stock_matrix: stock_matrix,
      variant_options: variant_options
    }
  end

  describe "#price_info" do
    context "when variant_id is provided" do
      it "returns price data for the specified variant" do
        result = display_data.price_info(1)

        expect(result).to eq({
          current: "$25.00",
          original: "$30.00",
          on_sale: true
        })
      end

      it "returns price data for variant without sale" do
        result = display_data.price_info(2)

        expect(result).to eq({
          current: "$20.00",
          on_sale: false
        })
      end

      context "when variant_id not found in matrix" do
        it "falls back to default variant price" do
          result = display_data.price_info(999)

          expect(result).to eq({
            current: "$25.00",
            original: "$30.00",
            on_sale: true
          })
        end
      end
    end

    context "when variant_id is nil" do
      it "returns default variant price info" do
        result = display_data.price_info(nil)

        expect(result).to eq({
          current: "$25.00",
          original: "$30.00",
          on_sale: true
        })
      end
    end

    context "when price_matrix is nil" do
      let(:price_matrix) { nil }

      it "returns unavailable price message" do
        result = display_data.price_info(1)

        expect(result).to eq({
          current: "Price not available",
          on_sale: false
        })
      end
    end

    context "when default_variant is nil" do
      let(:default_variant) { nil }

      it "returns unavailable price message when variant not in matrix" do
        result = display_data.price_info(999)

        expect(result).to eq({
          current: "Price not available",
          on_sale: false
        })
      end
    end
  end

  describe "#stock_info" do
    context "when variant_id is provided" do
      it "returns stock data for the specified variant" do
        result = display_data.stock_info(1)

        expect(result).to eq({
          available: true,
          message: "In stock",
          quantity: 5
        })
      end

      it "returns out of stock data for unavailable variant" do
        result = display_data.stock_info(2)

        expect(result).to eq({
          available: false,
          message: "Out of stock",
          quantity: 0
        })
      end

      context "when variant_id not found in matrix" do
        it "falls back to default variant stock" do
          result = display_data.stock_info(999)

          expect(result).to eq({
            available: true,
            message: "In stock",
            quantity: 5
          })
        end
      end
    end

    context "when variant_id is nil" do
      it "returns default variant stock info" do
        result = display_data.stock_info(nil)

        expect(result).to eq({
          available: true,
          message: "In stock",
          quantity: 5
        })
      end
    end

    context "when stock_matrix is nil" do
      let(:stock_matrix) { nil }

      it "returns out of stock default" do
        result = display_data.stock_info(1)

        expect(result).to eq({
          available: false,
          message: "Out of stock",
          quantity: 0
        })
      end
    end

    context "when default_variant is nil" do
      let(:default_variant) { nil }

      it "returns out of stock default when variant not in matrix" do
        result = display_data.stock_info(999)

        expect(result).to eq({
          available: false,
          message: "Out of stock",
          quantity: 0
        })
      end
    end
  end

  describe "#variant_available?" do
    it "returns true when variant is available" do
      expect(display_data.variant_available?(1)).to be true
    end

    it "returns false when variant is not available" do
      expect(display_data.variant_available?(2)).to be false
    end

    it "uses fallback logic for unknown variant_id" do
      expect(display_data.variant_available?(999)).to be true
    end

    context "when stock info is unavailable" do
      let(:stock_matrix) { nil }

      it "returns false" do
        expect(display_data.variant_available?(1)).to be false
      end
    end
  end

  describe "#as_json" do
    it "returns hash with all public attributes except all_variants" do
      result = display_data.as_json

      expect(result).to eq({
        product_info: product_info,
        default_variant: default_variant,
        variant_images: variant_images,
        price_matrix: price_matrix,
        stock_matrix: stock_matrix,
        variant_options: variant_options
      })
    end

    it "excludes all_variants from serialization" do
      result = display_data.as_json

      expect(result).not_to have_key(:all_variants)
    end

    it "ignores passed options parameter" do
      result = display_data.as_json({ include_all: true })

      expect(result.keys).to match_array([
        :product_info, :default_variant, :variant_images,
        :price_matrix, :stock_matrix, :variant_options
      ])
    end
  end

  describe "#merge_dynamic!" do
    let(:dynamic_data) do
      instance_double(
        "DynamicData",
        default_variant: { id: 3, name: "Green Lipstick" },
        price_matrix: { 3 => { current: "$15.00", on_sale: false } },
        stock_matrix: { 3 => { available: true, message: "Available", quantity: 10 } },
        variant_options: [ Products::VariantOption.new(name: "Color", value: "Green", type: "color", variant_id: 3) ]
      )
    end

    it "merges all provided dynamic data" do
      display_data.merge_dynamic!(dynamic_data)

      expect(display_data.default_variant).to eq({ id: 3, name: "Green Lipstick" })
      expect(display_data.price_matrix).to eq({ 3 => { current: "$15.00", on_sale: false } })
      expect(display_data.stock_matrix).to eq({ 3 => { available: true, message: "Available", quantity: 10 } })
      expect(display_data.variant_options.first.value).to eq("Green")
    end

    it "returns self for method chaining" do
      result = display_data.merge_dynamic!(dynamic_data)

      expect(result).to be(display_data)
    end

    context "when dynamic_data has nil values" do
      let(:dynamic_data) do
        instance_double(
          "DynamicData",
          default_variant: nil,
          price_matrix: { 3 => { current: "$15.00", on_sale: false } },
          stock_matrix: nil,
          variant_options: nil
        )
      end

      it "only updates non-nil values" do
        original_default = display_data.default_variant
        original_stock = display_data.stock_matrix
        original_options = display_data.variant_options

        display_data.merge_dynamic!(dynamic_data)

        expect(display_data.default_variant).to eq(original_default)
        expect(display_data.price_matrix).to eq({ 3 => { current: "$15.00", on_sale: false } })
        expect(display_data.stock_matrix).to eq(original_stock)
        expect(display_data.variant_options).to eq(original_options)
      end
    end
  end
end
