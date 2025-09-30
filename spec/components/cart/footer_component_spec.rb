# frozen_string_literal: true

RSpec.describe Cart::FooterComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:component) { described_class.new(total_price: "$25.99") }

  describe "initialization" do
    it "sets total_price" do
      expect(component.send(:total_price)).to eq("$25.99")
    end
  end

  describe "rendering" do
    let(:rendered) { render_inline(component) }

    before do
      allow(component).to receive(:new_checkout_path).and_return("/checkout")
    end

    it "renders order summary title" do
      expect(rendered.css("h3").text).to include("Order amount")
    end

    it "displays cost of products" do
      expect(rendered.text).to include("Cost of products")
      expect(rendered.text).to include("$25.99")
    end

    it "displays total" do
      expect(rendered.text).to include("Total")
    end

    it "renders checkout button" do
      link = rendered.css("a").first
      expect(link).to be_present
      expect(link["href"]).to eq("/checkout")
      expect(link.text).to include("Checkout")
    end

    it "includes checkout icon" do
      expect(rendered.css("svg")).to be_present
    end
  end

  describe "CSS classes" do
    let(:rendered) { render_inline(component) }

    before do
      allow(component).to receive(:new_checkout_path).and_return("/checkout")
    end

    it "applies container classes" do
      container = rendered.css("div").first
      expect(container["class"]).to include("space-y-4")
    end

    it "applies checkout button classes" do
      aggregate_failures do
        link = rendered.css("a").first
        expect(link["class"]).to include("btn-interactive")
        expect(link["class"]).to include("btn-full")
        expect(link["class"]).to include("btn-lg")
      end
    end
  end

  describe "internationalization" do
    let(:rendered) { render_inline(component) }

    before do
      allow(component).to receive(:new_checkout_path).and_return("/checkout")
      allow(I18n).to receive(:t).and_call_original
    end

    it "uses I18n for order summary title" do
      expect(I18n).to receive(:t).with("cart.order_summary.title", default: "Order amount")
      render_inline(component)
    end

    it "uses I18n for cost label" do
      expect(I18n).to receive(:t).with("cart.order_summary.cost_of_products", default: "Cost of products")
      render_inline(component)
    end

    it "uses I18n for total label" do
      expect(I18n).to receive(:t).with("cart.order_summary.total", default: "Total")
      render_inline(component)
    end

    it "uses I18n for checkout button" do
      expect(I18n).to receive(:t).with("cart.checkout", default: "Checkout")
      render_inline(component)
    end
  end
end
