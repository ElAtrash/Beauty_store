# frozen_string_literal: true

RSpec.describe Checkout::Modals::PickupDetailsModalComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:store_info) do
    {
      name: "Beauty Boutique",
      address: "Main Street 123, Downtown",
      working_hours: "Mon-Sat: 9 AM - 8 PM",
      phone: "+961 1 234 567",
      coordinates: "33.8938,35.5018",
      delivery_date: "today",
      shelf_life: "Products valid for 30 days",
      directions: "Located next to ABC Mall, opposite the blue building"
    }
  end
  let(:component) { described_class.new(store_info: store_info) }

  describe "initialization" do
    it "sets default modal properties" do
      aggregate_failures do
        expect(component.id).to eq("pickup-details-modal")
        expect(component.title).to eq("Pickup Details")
        expect(component.size).to eq(:medium)
        expect(component.position).to eq(:right)
      end
    end

    it "accepts optional store_info parameter" do
      expect(component.store_info).to eq(store_info)
    end

    it "uses default store info when none provided" do
      allow_any_instance_of(described_class).to receive(:store_pickup_details).and_return(store_info)
      default_component = described_class.new
      expect(default_component.store_info).to eq(store_info)
    end

    it "includes StoreInformation concern" do
      expect(described_class.included_modules).to include(StoreInformation)
    end

    it "sets pickup-details-modal specific data attributes" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='pickup-details-modal']").first

      expect(modal_div.attributes["data-controller"].value).to include("modal")
      expect(modal_div.attributes["data-controller"].value).to include("pickup-details-modal")
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
        modal.with_body { "Custom pickup details content" }
      end

      expect(rendered.text).to include("Custom pickup details content")
    end
  end

  describe "store_info accessor" do
    it "provides public store_info method" do
      aggregate_failures do
        expect(component).to respond_to(:store_info)
        expect(component.store_info).to be_a(Hash)
        expect(component.store_info[:name]).to eq("Beauty Boutique")
        expect(component.store_info[:address]).to eq("Main Street 123, Downtown")
        expect(component.store_info[:phone]).to eq("+961 1 234 567")
      end
    end
  end

  describe "rendering integration" do
    it "renders complete modal structure" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.css("div[id='pickup-details-modal']")).to be_present
        expect(rendered.css("h2").text).to include("Pickup Details")
        expect(rendered.css("#pickup-details-modal-content")).to be_present
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

    it "uses medium size for details content" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("w-[680px]")
    end
  end

  describe "accessibility" do
    it "includes proper ARIA attributes" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='pickup-details-modal']").first

        expect(modal_div.attributes["role"].value).to eq("dialog")
        expect(modal_div.attributes["aria-modal"].value).to eq("true")
        expect(modal_div.attributes["aria-labelledby"].value).to eq("pickup-details-modal-title")
        expect(modal_div.attributes["aria-describedby"].value).to eq("pickup-details-modal-content")
      end
    end
  end

  describe "data attributes" do
    it "includes pickup-details-modal specific controller" do
      aggregate_failures do
        rendered = render_inline(component)
        modal_div = rendered.css("div[id='pickup-details-modal']").first

        controller_attr = modal_div.attributes["data-controller"].value
        expect(controller_attr).to include("modal")
        expect(controller_attr).to include("pickup-details-modal")
      end
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
    it "accepts no parameters (uses defaults)" do
      allow_any_instance_of(described_class).to receive(:store_pickup_details).and_return(store_info)
      expect {
        described_class.new
      }.not_to raise_error
    end

    it "accepts optional store_info parameter" do
      expect {
        described_class.new(store_info: store_info)
      }.not_to raise_error
    end
  end

  describe "store information integration" do
    it "has access to store information methods" do
      expect(described_class.included_modules).to include(StoreInformation)
    end
  end

  describe "modal inheritance" do
    it "inherits from Modal::BaseComponent" do
      expect(described_class.superclass).to eq(Modal::BaseComponent)
    end
  end
end
