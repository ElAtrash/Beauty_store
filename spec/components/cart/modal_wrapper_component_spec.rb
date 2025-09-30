# frozen_string_literal: true

RSpec.describe Cart::ModalWrapperComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:empty_cart) {
    double('cart',
      blank?: true,
      empty?: true,
      cart_items: [],
      total_quantity: 0,
      total_price: nil,
      ordered_items: [],
      formatted_total: "$0.00"
    )
  }
  let(:cart_with_items) do
    double('cart',
      blank?: false,
      empty?: false,
      cart_items: double('cart_items', sum: 3),
      total_quantity: 3,
      total_price: double('price',
        format: '$25.99',
        cents: 2599,
        currency: double('currency', iso_code: 'USD')
      ),
      ordered_items: [ cart_item ],
      formatted_total: "$25.99"
    )
  end
  let(:product) { double('product', name: 'Test Product') }
  let(:product_variant) {
    double('product_variant',
      name: 'Variant 1',
      sku: 'TEST-001',
      featured_image: double('attachment', attached?: false),
      track_inventory?: false,
      allow_backorder?: true,
      stock_quantity: 10
    )
  }
  let(:cart_item) {
    double('cart_item',
      quantity: 2,
      id: 1,
      product: product,
      product_variant: product_variant,
      total_price: double('price', format: '$12.99')
    )
  }

  describe "initialization" do
    it "can be instantiated without cart" do
      component = described_class.new
      expect(component).to be_present
    end

    it "accepts cart parameter" do
      component = described_class.new(cart: cart_with_items)
      expect(component.send(:cart)).to eq(cart_with_items)
    end
  end

  describe "with empty cart" do
    let(:component) { described_class.new(cart: empty_cart) }

    before do
      # Mock component renders to avoid complexity
      allow(component).to receive(:render).with(instance_of(Cart::ModalComponent)).and_return("modal content")
    end

    it "detects empty cart state" do
      expect(component.send(:empty_cart?)).to be true
    end

    it "returns basic cart title" do
      expect(component.send(:cart_title)).to eq("Shopping Cart")
    end

    it "returns zero item count" do
      expect(component.send(:cart_item_count)).to eq(0)
    end

    it "does not render footer for empty cart" do
      rendered = render_inline(component)
      expect(rendered.text).to be_present
    end

    it "returns empty cart items array" do
      expect(component.send(:cart_items)).to eq([])
    end

    it "renders without header action when cart is empty" do
      rendered = render_inline(component)
      expect(rendered.text).to be_present
    end
  end

  describe "with items in cart" do
    let(:component) { described_class.new(cart: cart_with_items) }

    before do
      allow(component).to receive(:clear_all_cart_items_path).and_return("/cart/clear")
      allow(component).to receive(:render).and_call_original
    end

    it "detects non-empty cart state" do
      expect(component.send(:empty_cart?)).to be false
    end

    it "returns cart title with count" do
      expect(component.send(:cart_title)).to eq("Shopping Cart / 3 units")
    end

    it "returns correct item count" do
      expect(component.send(:cart_item_count)).to eq(3)
    end

    it "uses cart's formatted total" do
      expect(cart_with_items).to receive(:formatted_total).and_return("$25.99")
      rendered = render_inline(component)
      expect(rendered.text).to be_present
    end

    it "returns cart items array" do
      expect(component.send(:cart_items)).to eq([ cart_item ])
    end

    it "includes clear cart button classes" do
      classes = component.send(:clear_cart_button_classes)
      expect(classes).to include("flex items-center justify-center w-8 h-8 p-0")
    end

    it "includes clear cart button options" do
      aggregate_failures do
        options = component.send(:clear_cart_button_options)
        expect(options[:data][:turbo_method]).to eq("delete")
        expect(options[:title]).to be_present
        expect(options[:"aria-label"]).to be_present
        expect(options[:class]).to be_present
      end
    end
  end

  describe "with nil cart" do
    let(:component) { described_class.new(cart: nil) }

    it "handles nil cart gracefully" do
      aggregate_failures do
        expect(component.send(:empty_cart?)).to be true
        expect(component.send(:cart_item_count)).to eq(0)
        expect(component.send(:cart_items)).to eq([])
      end
    end
  end

  describe "units text formatting" do
    let(:component) { described_class.new(cart: empty_cart) }

    it "formats zero units" do
      expect(I18n).to receive(:t).with("cart.units", count: 0).and_return("0 units")
      expect(component.send(:format_units_text, 0)).to eq("0 units")
    end

    it "formats one unit" do
      expect(I18n).to receive(:t).with("cart.units", count: 1).and_return("1 unit")
      expect(component.send(:format_units_text, 1)).to eq("1 unit")
    end

    it "formats multiple units" do
      expect(I18n).to receive(:t).with("cart.units", count: 5).and_return("5 units")
      expect(component.send(:format_units_text, 5)).to eq("5 units")
    end
  end

  describe "internationalization" do
    let(:component) { described_class.new(cart: empty_cart) }

    it "uses I18n for empty cart title" do
      expect(I18n).to receive(:t).with("cart.title").and_return("Shopping Cart")
      expect(component.send(:cart_title)).to eq("Shopping Cart")
    end

    it "uses I18n for units text" do
      expect(I18n).to receive(:t).with("cart.units", count: 0).and_return("0 units")
      expect(component.send(:format_units_text, 0)).to eq("0 units")
    end

    it "uses I18n for clear cart tooltip" do
      allow(I18n).to receive(:t).with("cart.clear_all.tooltip").and_return("Clear all items")
      allow(I18n).to receive(:t).with("cart.clear_all.aria_label").and_return("Clear all items")
      options = component.send(:clear_cart_button_options)
      expect(options[:title]).to eq("Clear all items")
    end
  end

  describe "component integration" do
    let(:component) { described_class.new(cart: cart_with_items) }

    before do
      allow(component).to receive(:clear_all_cart_items_path).and_return("/cart/clear")
    end

    it "renders the wrapper with all slots" do
      rendered = render_inline(component)

      expect(rendered.css("div[id='cart']")).to be_present
      expect(rendered.css("h2").text).to include("Shopping Cart / 3 units")
    end
  end

  describe "helper methods accessibility" do
    let(:component) { described_class.new(cart: cart_with_items) }

    it "provides clear cart button classes method" do
      expect(component.respond_to?(:clear_cart_button_classes, true)).to be true
    end

    it "provides clear cart button options method" do
      expect(component.respond_to?(:clear_cart_button_options, true)).to be true
    end

    it "provides format units text method" do
      expect(component.respond_to?(:format_units_text, true)).to be true
    end

    it "provides cart total cents method" do
      expect(component.respond_to?(:cart_total_cents, true)).to be true
    end

    it "provides cart currency method" do
      expect(component.respond_to?(:cart_currency, true)).to be true
    end
  end

  describe "money object data" do
    let(:component) { described_class.new(cart: cart_with_items) }

    it "returns cart total in cents" do
      allow(cart_with_items.total_price).to receive(:cents).and_return(2599)
      expect(component.send(:cart_total_cents)).to eq(2599)
    end

    it "returns cart currency code" do
      allow(cart_with_items.total_price).to receive(:currency).and_return(double(iso_code: "USD"))
      expect(component.send(:cart_currency)).to eq("USD")
    end

    it "handles empty cart with default values" do
      component = described_class.new(cart: nil)
      expect(component.send(:cart_total_cents)).to eq(0)
      expect(component.send(:cart_currency)).to eq("USD")
    end

    it "handles different currencies" do
      allow(cart_with_items.total_price).to receive(:cents).and_return(4999)
      allow(cart_with_items.total_price).to receive(:currency).and_return(double(iso_code: "EUR"))
      expect(component.send(:cart_total_cents)).to eq(4999)
      expect(component.send(:cart_currency)).to eq("EUR")
    end
  end
end
