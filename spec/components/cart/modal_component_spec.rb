# frozen_string_literal: true

RSpec.describe Cart::ModalComponent, type: :component do
  include ViewComponent::TestHelpers

  describe "initialization" do
    it "sets default modal properties" do
      aggregate_failures do
        component = described_class.new(
          title: "Shopping Cart",
          item_count: 0,
          cart_empty: true,
          total_cents: 0,
          currency: "USD"
        )
        expect(component.id).to eq("cart")
        expect(component.size).to eq(:medium)
        expect(component.position).to eq(:right)
        expect(component.title).to eq("Shopping Cart")
      end
    end

    it "accepts all parameters" do
      component = described_class.new(
        title: "Shopping Cart / 3 units",
        item_count: 3,
        cart_empty: false,
        total_cents: 2599,
        currency: "USD"
      )
      expect(component.title).to eq("Shopping Cart / 3 units")
    end

    it "validates item_count parameter" do
      expect {
        described_class.new(
          title: "Cart",
          item_count: -1,
          cart_empty: true,
          total_cents: 0,
          currency: "USD"
        )
      }.to raise_error(ArgumentError, "item_count must be a non-negative integer")
    end

    it "validates cart_empty parameter" do
      expect {
        described_class.new(
          title: "Cart",
          item_count: 0,
          cart_empty: "not_boolean",
          total_cents: 0,
          currency: "USD"
        )
      }.to raise_error(ArgumentError, "cart_empty must be a boolean")
    end

    it "validates total_cents parameter" do
      expect {
        described_class.new(
          title: "Cart",
          item_count: 0,
          cart_empty: true,
          total_cents: -1,
          currency: "USD"
        )
      }.to raise_error(ArgumentError, "total_cents must be a non-negative integer, got: -1")
    end

    it "validates currency parameter" do
      expect {
        described_class.new(
          title: "Cart",
          item_count: 0,
          cart_empty: true,
          total_cents: 0,
          currency: "INVALID"
        )
      }.to raise_error(ArgumentError, /invalid currency code: INVALID/)
    end

    it "accepts valid multi-currency codes" do
      %w[USD EUR GBP JPY].each do |currency|
        expect {
          described_class.new(
            title: "Cart",
            item_count: 0,
            cart_empty: true,
            total_cents: 0,
            currency: currency
          )
        }.not_to raise_error
      end
    end
  end

  describe "with empty cart" do
    let(:component) do
      described_class.new(
        title: "Shopping Cart",
        item_count: 0,
        cart_empty: true,
        total_cents: 0,
        currency: "USD"
      )
    end
    let(:rendered) { render_inline(component) }

    it "renders empty cart title" do
      expect(component.title).to eq("Shopping Cart")
    end

    it "includes empty cart data attributes" do
      aggregate_failures do
        modal_div = rendered.css("div[id='cart']").first

        expect(modal_div.attributes["data-cart-empty"].value).to eq("true")
        expect(modal_div.attributes["data-cart-item-count"].value).to eq("0")
        expect(modal_div.attributes["data-cart-total-cents"].value).to eq("0")
        expect(modal_div.attributes["data-cart-currency"].value).to eq("USD")
      end
    end

    it "includes empty cart CSS class" do
      expect(rendered.to_html).to include("cart-modal--empty")
      expect(rendered.to_html).not_to include("cart-modal--has-items")
    end
  end

  describe "with items in cart" do
    let(:component) do
      described_class.new(
        title: "Shopping Cart / 3 units",
        item_count: 3,
        cart_empty: false,
        total_cents: 2599,
        currency: "USD"
      )
    end

    it "renders cart title with count" do
      expect(component.title).to eq("Shopping Cart / 3 units")
    end

    it "includes cart items data attributes" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='cart']").first

        expect(modal_div.attributes["data-cart-empty"].value).to eq("false")
        expect(modal_div.attributes["data-cart-item-count"].value).to eq("3")
        expect(modal_div.attributes["data-cart-modal-target"].value).to eq("modal")
        expect(modal_div.attributes["data-cart-total-cents"].value).to eq("2599")
        expect(modal_div.attributes["data-cart-currency"].value).to eq("USD")
      end
    end

    it "includes items cart CSS class" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("cart-modal--has-items")
      expect(rendered.to_html).not_to include("cart-modal--empty")
    end
  end

  describe "multi-currency support" do
    it "handles EUR currency correctly" do
      component = described_class.new(
        title: "Shopping Cart",
        item_count: 2,
        cart_empty: false,
        total_cents: 4999,
        currency: "EUR"
      )
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='cart']").first

      expect(modal_div.attributes["data-cart-total-cents"].value).to eq("4999")
      expect(modal_div.attributes["data-cart-currency"].value).to eq("EUR")
    end

    it "handles JPY currency correctly" do
      component = described_class.new(
        title: "Shopping Cart",
        item_count: 1,
        cart_empty: false,
        total_cents: 12500,
        currency: "JPY"
      )
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='cart']").first

      expect(modal_div.attributes["data-cart-total-cents"].value).to eq("12500")
      expect(modal_div.attributes["data-cart-currency"].value).to eq("JPY")
    end
  end

  describe "modal structure" do
    let(:component) do
      described_class.new(
        title: "Shopping Cart / 3 units",
        item_count: 3,
        cart_empty: false,
        total_cents: 2599,
        currency: "USD"
      )
    end

    it "renders complete modal structure" do
      aggregate_failures do
        rendered = render_inline(component)
        expect(rendered.css("div[id='cart']")).to be_present
        expect(rendered.css("h2").text).to include("Shopping Cart / 3 units")
        expect(rendered.css("#cart-content")).to be_present
      end
    end

    it "inherits all base modal functionality" do
      aggregate_failures do
        rendered = render_inline(component)
        expect(rendered.css("[data-modal-target='overlay']")).to be_present
        expect(rendered.css("[data-modal-target='panel']")).to be_present
        expect(rendered.css("button[data-action='click->modal#close']")).to be_present
      end
    end
  end

  describe "data attributes customization" do
    let(:component) do
      described_class.new(
        title: "Shopping Cart",
        item_count: 3,
        cart_empty: false,
        total_cents: 2599,
        currency: "USD"
      )
    end

    it "includes cart-specific data attributes" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='cart']").first

        expect(modal_div.attributes["data-cart-modal-target"].value).to eq("modal")
        expect(modal_div.attributes["data-cart-item-count"].value).to eq("3")
        expect(modal_div.attributes["data-cart-empty"].value).to eq("false")
        expect(modal_div.attributes["data-cart-total-cents"].value).to eq("2599")
        expect(modal_div.attributes["data-cart-currency"].value).to eq("USD")
      end
    end
  end

  describe "container classes customization" do
    it "adds empty cart CSS class" do
      component = described_class.new(
        title: "Shopping Cart",
        item_count: 0,
        cart_empty: true,
        total_cents: 0,
        currency: "USD"
      )
      rendered = render_inline(component)

      expect(rendered.to_html).to include("cart-modal--empty")
      expect(rendered.to_html).not_to include("cart-modal--has-items")
    end

    it "adds items cart CSS class" do
      component = described_class.new(
        title: "Shopping Cart",
        item_count: 3,
        cart_empty: false,
        total_cents: 2599,
        currency: "USD"
      )
      rendered = render_inline(component)

      expect(rendered.to_html).to include("cart-modal--has-items")
      expect(rendered.to_html).not_to include("cart-modal--empty")
    end
  end
end
