# frozen_string_literal: true

RSpec.describe OrderConfirmation::ItemComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:product) { build(:product, name: 'Pro Filt\'r Soft Matte Longwear Foundation') }
  let(:product_variant) { build(:product_variant, product: product, price: Money.new(3600, 'USD')) }
  let(:order_item) {
    build(:order_item,
      product: product,
      product_variant: product_variant,
      quantity: 1,
      product_name: product.name,
      unit_price: Money.new(3600, 'USD'),
      total_price: Money.new(3600, 'USD')
    )
  }
  let(:component) { described_class.new(order_item: order_item) }

  describe "rendering" do
    it "renders the order item with product information" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.text).to include(order_item.product_name)
        expect(rendered.text).to include("Qty: #{order_item.quantity}")
        expect(rendered.text).to include(order_item.total_price.format)
      end
    end

    it "includes clickable product name link" do
      rendered = render_inline(component)

      expect(rendered.css("a[href*=\"products\"]")).to be_present
      expect(rendered.css("a").text).to include(order_item.product_name)
    end

    it "includes clickable product image link" do
      rendered = render_inline(component)

      image_links = rendered.css("a[href*=\"products\"] img").present? ||
                   rendered.css("a[href*=\"products\"] svg").present?
      expect(image_links).to be true
    end

    it "shows variant name when present" do
      order_item.variant_name = "210 - Light with warm undertones"
      rendered = render_inline(component)

      expect(rendered.text).to include("210 - Light with warm undertones")
    end

    it "applies hover effects to links" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.to_html).to include("hover:text-interactive-primary")
        expect(rendered.to_html).to include("hover:opacity-80")
        expect(rendered.to_html).to include("transition-")
      end
    end
  end

  describe "product url generation" do
    it "generates correct product path" do
      allow(component).to receive(:product_path).with(product).and_return("/products/#{product.id}")

      expect(component.send(:product_url)).to eq("/products/#{product.id}")
    end
  end
end
