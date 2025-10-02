# frozen_string_literal: true

RSpec.describe Checkout::Modals::AddressModalComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:form) { double('form') }
  let(:city) { "Beirut" }
  let(:component) { described_class.new(form: form, city: city) }

  describe "initialization" do
    it "sets default modal properties" do
      aggregate_failures do
        expect(component.id).to eq("address-modal")
        expect(component.title).to eq("Delivery Address")
        expect(component.size).to eq(:medium)
        expect(component.position).to eq(:right)
      end
    end

    it "accepts form and city parameters" do
      expect(component.form).to eq(form)
      expect(component.city).to eq(city)
    end

    it "includes StoreInformation concern" do
      expect(described_class.included_modules).to include(StoreInformation)
    end

    it "sets address-modal specific data attributes" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='address-modal']").first

        expect(modal_div.attributes["data-controller"].value).to include("modal")
        expect(modal_div.attributes["data-controller"].value).to include("address-modal")
        expect(modal_div.attributes["data-address-modal-city-value"].value).to eq("Beirut")
      end
    end
  end

  describe "slot-based content" do
    it "supports modern slot-based approach" do
      aggregate_failures do
        expect(component).to respond_to(:body)
        expect(component).to respond_to(:header_action)
        expect(component).to respond_to(:footer)
      end
    end

    it "works with slot-based rendering" do
      rendered = render_inline(component) do |modal|
        modal.with_body { "Custom slot content" }
      end

      expect(rendered.text).to include("Custom slot content")
    end
  end

  describe "helper methods" do
    it "provides public delivery_card_props method" do
      aggregate_failures do
        expect(component).to respond_to(:delivery_card_props)
        props = component.delivery_card_props
        expect(props).to be_a(Hash)
        expect(props[:icon]).to eq(:truck)
        expect(props[:title]).to eq("Delivering to Beirut")
        expect(props[:subtitle]).to eq(nil)
      end
    end

    it "provides public submit_button_props method" do
      aggregate_failures do
        expect(component).to respond_to(:submit_button_props)
        props = component.submit_button_props
        expect(props).to be_a(Hash)
        expect(props[:text]).to eq("Bring it here")
        expect(props[:css_class]).to include("btn-interactive")
      end
    end
  end

  describe "rendering integration" do
    it "renders complete modal structure" do
      aggregate_failures do
        rendered = render_inline(component)
        expect(rendered.css("div[id='address-modal']")).to be_present
        expect(rendered.css("h2").text).to include("Delivery Address")
        expect(rendered.css("#address-modal-content")).to be_present
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

    it "uses right position for checkout flow" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("right-0")
    end

    it "uses medium size for form content" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("w-[680px]")
    end
  end

  describe "accessibility" do
    it "includes proper ARIA attributes" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='address-modal']").first

        expect(modal_div.attributes["role"].value).to eq("dialog")
        expect(modal_div.attributes["aria-modal"].value).to eq("true")
        expect(modal_div.attributes["aria-labelledby"].value).to eq("address-modal-title")
        expect(modal_div.attributes["aria-describedby"].value).to eq("address-modal-content")
      end
    end
  end

  describe "data attributes" do
    it "includes address-modal specific controller" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='address-modal']").first

        controller_attr = modal_div.attributes["data-controller"].value
        expect(controller_attr).to include("modal")
        expect(controller_attr).to include("address-modal")
      end
    end

    it "includes city value for controller" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='address-modal']").first

      expect(modal_div.attributes["data-address-modal-city-value"].value).to eq("Beirut")
    end
  end

  describe "responsive design" do
    it "includes mobile-responsive classes" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("max-md:w-full")
      expect(rendered.to_html).to include("sm:px-12")
    end
  end

  describe "parameter validation" do
    it "requires form parameter" do
      expect {
        described_class.new(city: city)
      }.to raise_error(ArgumentError)
    end

    it "requires city parameter" do
      expect {
        described_class.new(form: form)
      }.to raise_error(ArgumentError)
    end

    it "accepts both required parameters" do
      expect {
        described_class.new(form: form, city: city)
      }.not_to raise_error
    end
  end

  describe "store information integration" do
    it "has access to store information methods" do
      expect(described_class.included_modules).to include(StoreInformation)
    end
  end
end
