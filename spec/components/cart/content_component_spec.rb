# frozen_string_literal: true

RSpec.describe Cart::ContentComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:product) { double("product", name: "Test Product") }
  let(:product_variant) { double("product_variant", name: "Variant 1", sku: "TEST-001", featured_image: attachment_double, track_inventory?: true, allow_backorder?: false, stock_quantity: 10) }
  let(:cart_item) { double("cart_item", quantity: 2, id: 1, product: product, product_variant: product_variant, total_price: "$12.99") }
  let(:attachment_double) do
    double("attachment",
      attached?: true,
      url: "test.jpg",
      to_model: double("attachment_model", model_name: double(param_key: "attachment"))
    )
  end

  describe "with empty cart" do
    let(:component) { described_class.new(cart_items: []) }
    let(:rendered) { render_inline(component) }

    it "renders the empty cart container" do
      expect(rendered.css(".text-center.py-12")).to be_present
    end

    it "renders the shopping cart icon" do
      expect(rendered.css("svg")).to be_present
    end

    it "renders the empty cart title" do
      expect(rendered.css("h3").text).to include("Your cart is empty")
    end

    it "renders the description text" do
      expect(rendered.css("p").text).to include("Add some products to get started")
    end

    it "renders the continue shopping button" do
      button = rendered.css("button").first
      expect(button).to be_present
      expect(button.text).to include("Continue Shopping")
    end

    it "includes modal close action on button" do
      button = rendered.css("button").first
      expect(button["data-action"]).to eq("click->modal#close")
    end
  end

  describe "with cart items" do
    let(:component) { described_class.new(cart_items: [ cart_item, cart_item ]) }

    it "detects non-empty cart" do
      expect(component.send(:empty_cart?)).to be false
    end

    it "generates correct wrapper classes for non-last item" do
      classes = component.send(:item_wrapper_classes, false)
      expect(classes).to include("border-b border-gray-100")
    end

    it "generates correct wrapper classes for last item" do
      classes = component.send(:item_wrapper_classes, true)
      expect(classes).not_to include("border-b")
    end

    it "renders items template branch" do
      # Mock the render method to avoid ActiveStorage complexity
      allow(component).to receive(:render).with(instance_of(Cart::ItemComponent)).and_return("cart item")
      rendered = render_inline(component)

      expect(rendered.text).not_to include("Your cart is empty")
    end
  end

  describe "with custom modal controller" do
    let(:component) { described_class.new(cart_items: [], modal_controller: "custom-modal") }
    let(:rendered) { render_inline(component) }

    it "uses custom controller in data action" do
      button = rendered.css("button").first
      expect(button["data-action"]).to eq("click->custom-modal#close")
    end
  end

  describe "internationalization" do
    let(:component) { described_class.new(cart_items: []) }

    before do
      allow(I18n).to receive(:t).and_call_original
    end

    it "uses I18n for empty title" do
      expect(I18n).to receive(:t).with("cart.empty.title", default: "Your cart is empty")
      render_inline(component)
    end

    it "uses I18n for empty description" do
      expect(I18n).to receive(:t).with("cart.empty.description", default: "Add some products to get started")
      render_inline(component)
    end

    it "uses I18n for button text" do
      expect(I18n).to receive(:t).with("cart.empty.continue_shopping", default: "Continue Shopping")
      render_inline(component)
    end
  end

  describe "CSS classes" do
    let(:component) { described_class.new(cart_items: []) }
    let(:rendered) { render_inline(component) }

    it "applies correct empty container classes" do
      container = rendered.css("div").first
      expect(container["class"]).to include("text-center py-12")
    end

    it "applies correct button classes" do
      button = rendered.css("button").first
      expect(button["class"]).to include("btn-interactive")
      expect(button["class"]).to include("btn-lg")
    end
  end
end
