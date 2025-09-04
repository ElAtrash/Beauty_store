# frozen_string_literal: true

RSpec.describe Products::DefaultVariantSelector do
  let(:product) { create(:product) }

  subject(:selector) { described_class.call(product, scope: scope) }

  let(:scope) { nil }

  describe ".call" do
    context "when no variants exist" do
      it { is_expected.to be_nil }
    end

    context "when admin override exists" do
      let!(:variant) { create(:product_variant, product:, is_default: true, stock_quantity: 5) }

      it "returns the admin override variant" do
        expect(selector).to eq(variant)
      end
    end

    context "when all variants are out of stock" do
      let!(:canonical) { create(:product_variant, product:, canonical_variant: true, stock_quantity: 0) }

      it "falls back to canonical" do
        expect(selector).to eq(canonical)
      end
    end

    context "when bestseller exists" do
      let!(:low_perf)  { create(:product_variant, product:, stock_quantity: 5, sales_count: 1, conversion_score: 1) }
      let!(:best_perf) { create(:product_variant, product:, stock_quantity: 5, sales_count: 10, conversion_score: 5) }

      it "returns the bestseller variant" do
        expect(selector).to eq(best_perf)
      end
    end

    context "when product has size-only variants" do
      before do
        allow(product).to receive(:size_only_variants?).and_return(true)
      end

      let!(:small) { create(:product_variant, :small_size, product:, stock_quantity: 5) }
      let!(:medium) { create(:product_variant, :medium_size, product:, stock_quantity: 5) }

      it "returns the smallest size variant" do
        expect(selector).to eq(small)
      end
    end

    context "when product has mixed variants (colors & sizes)" do
      before do
        allow(product).to receive(:size_only_variants?).and_return(false)
      end

      let!(:cheap) { create(:product_variant, product:, stock_quantity: 5, price_cents: 1000) }
      let!(:mid) { create(:product_variant, product:, stock_quantity: 5, price_cents: 2000) }
      let!(:expensive) { create(:product_variant, product:, stock_quantity: 5, price_cents: 5000) }

      it "returns the entry-level (second cheapest) variant" do
        expect(selector).to eq(mid)
      end
    end

    context "when no other rules apply" do
      let!(:canonical) { create(:product_variant, product:, canonical_variant: true, stock_quantity: 5) }

      it "returns the canonical variant" do
        expect(selector).to eq(canonical)
      end
    end

    context "when using a scoped subset (e.g., color)" do
      let!(:red_small) { create(:product_variant, :red, :small_size, product:, stock_quantity: 5) }
      let!(:red_medium) { create(:product_variant, :red, :medium_size, product:, stock_quantity: 5) }
      let!(:yellow_small) { create(:product_variant, :yellow, :small_size, product:, stock_quantity: 5) }

      let(:scope) { product.product_variants.where(color: "red") }

      before do
        allow(product).to receive(:size_only_variants?).and_return(true)
      end

      it "applies the logic only within the scope" do
        expect(selector).to eq(red_small)
      end
    end
  end
end
