# frozen_string_literal: true

RSpec.describe Modal::FilterComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:filter_form) do
    double('filter_form',
           brand: [],
           brands: [],
           price_range: {},
           price_range_min: nil,
           price_range_max: nil,
           in_stock: false,
           product_types: [],
           skin_types: [],
           colors: [],
           sizes: [],
           filter_available?: true,
           value_selected?: false)
  end
  let(:products) { double('products') }
  let(:unfiltered_products) { double('unfiltered_products') }

  describe "initialization" do
    it "sets default modal properties" do
      component = described_class.new(filter_form: filter_form)
      expect(component.id).to eq("filter-modal")
      expect(component.title).to eq("Filters")
      expect(component.size).to eq(:medium)
      expect(component.position).to eq(:left)
    end

    it "accepts all required parameters" do
      component = described_class.new(
        filter_form: filter_form,
        products: products,
        unfiltered_products: unfiltered_products,
        context: "brands",
        context_resource: "charlotte-tilbury",
        turbo_frame_id: "custom-frame"
      )

      expect(component.send(:filter_form)).to eq(filter_form)
      expect(component.send(:products)).to eq(products)
      expect(component.send(:unfiltered_products)).to eq(unfiltered_products)
      expect(component.send(:context)).to eq("brands")
      expect(component.send(:context_resource)).to eq("charlotte-tilbury")
      expect(component.send(:turbo_frame_id)).to eq("custom-frame")
    end

    it "sets default products when none provided" do
      allow(Product).to receive(:available).and_return(products)

      component = described_class.new(filter_form: filter_form)
      expect(component.send(:products)).to eq(products)
    end

    it "sets unfiltered_products to products when none provided" do
      component = described_class.new(filter_form: filter_form, products: products)
      expect(component.send(:unfiltered_products)).to eq(products)
    end
  end

  describe "data attributes" do
    it "includes filter-specific controller and data" do
      component = described_class.new(
        filter_form: filter_form,
        context: "brands",
        turbo_frame_id: "products-frame"
      )

      rendered = render_inline(component)
      modal_div = rendered.css("div[id='filter-modal']").first

      # Should include both modal and filter controllers
      expect(modal_div.attributes["data-controller"].value).to include("modal")
      expect(modal_div.attributes["data-controller"].value).to include("filters--filter")

      # Should include filter-specific data attributes
      expect(modal_div.attributes["data-filters--filter-turbo-frame-id-value"].value).to eq("products-frame")
      expect(modal_div.attributes["data-filters--filter-context-value"].value).to eq("brands")
    end

    it "handles nil context gracefully" do
      component = described_class.new(filter_form: filter_form, context: nil)
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='filter-modal']").first

      expect(modal_div.attributes["data-filters--filter-context-value"]).to be_nil
    end
  end

  describe "turbo frame target" do
    it "uses provided turbo_frame_id" do
      component = described_class.new(
        filter_form: filter_form,
        turbo_frame_id: "custom-frame"
      )

      expect(component.send(:turbo_frame_target)).to eq("custom-frame")
    end

    it "generates default frame ID when none provided" do
      component = described_class.new(filter_form: filter_form, context: "brands")

      # Should call the turbo_frame_target method which likely generates a default
      expect(component.send(:turbo_frame_target)).to be_present
    end
  end

  describe "content rendering" do
    let(:component) do
      described_class.new(
        filter_form: filter_form,
        products: products,
        unfiltered_products: unfiltered_products,
        context: "brands"
      )
    end

    it "renders filter content partial" do
      expect(component).to receive(:render).with(
        "modal/filter/content",
        filter_form: filter_form,
        products: products,
        unfiltered_products: unfiltered_products,
        context: "brands",
        context_resource: nil,
        turbo_frame_id: nil,
        component: component
      ).and_return("Filter content")

      content = component.send(:content)
      expect(content).to include("Filter content")
    end

    it "passes all parameters to content partial" do
      component = described_class.new(
        filter_form: filter_form,
        products: products,
        unfiltered_products: unfiltered_products,
        context: "categories",
        context_resource: "skincare",
        turbo_frame_id: "category-products"
      )

      expect(component).to receive(:render).with(
        "modal/filter/content",
        filter_form: filter_form,
        products: products,
        unfiltered_products: unfiltered_products,
        context: "categories",
        context_resource: "skincare",
        turbo_frame_id: "category-products",
        component: component
      ).and_return("Detailed filter content")

      content = component.send(:content)
      expect(content).to include("Detailed filter content")
    end
  end

  describe "rendering integration" do
    let(:component) { described_class.new(filter_form: filter_form) }

    before do
      allow(component).to receive(:render).and_return("Filter modal content")
    end

    it "renders complete modal structure" do
      rendered = render_inline(component)

      # Check modal structure
      expect(rendered.css("div[id='filter-modal']")).to be_present
      expect(rendered.css("h2").text).to include("Filters")

      # Check content area
      expect(rendered.css("#filter-modal-content")).to be_present
    end

    it "uses left position for filters" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("left-0")
    end

    it "inherits all base modal functionality" do
      rendered = render_inline(component)

      # Should have all base modal features
      expect(rendered.css("[data-modal-target='overlay']")).to be_present
      expect(rendered.css("[data-modal-target='panel']")).to be_present
      expect(rendered.css("button[data-action='click->modal#close']")).to be_present
    end
  end

  describe "accessibility" do
    let(:component) { described_class.new(filter_form: filter_form) }

    it "includes proper ARIA attributes" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='filter-modal']").first

      expect(modal_div.attributes["role"].value).to eq("dialog")
      expect(modal_div.attributes["aria-modal"].value).to eq("true")
      expect(modal_div.attributes["aria-labelledby"].value).to eq("filter-modal-title")
      expect(modal_div.attributes["aria-describedby"].value).to eq("filter-modal-content")
    end
  end

  describe "responsive design" do
    let(:component) { described_class.new(filter_form: filter_form) }

    it "includes mobile-responsive classes" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("max-md:w-full")
      expect(rendered.to_html).to include("sm:px-12")
    end
  end

  describe "filter-specific styling" do
    let(:component) { described_class.new(filter_form: filter_form) }

    it "uses left position for filter sidebar feel" do
      rendered = render_inline(component)
      # Left position classes should be present
      expect(rendered.to_html).to include("left-0")
    end

    it "uses medium size for adequate filter space" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("w-[680px]")
    end
  end

  describe "controller integration" do
    let(:component) { described_class.new(filter_form: filter_form, context: "brands") }

    it "configures filter controller properly" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='filter-modal']").first

      # Should combine modal and filter controllers
      controller_attr = modal_div.attributes["data-controller"].value
      expect(controller_attr).to include("modal")
      expect(controller_attr).to include("filters--filter")
    end
  end

  describe "parameter validation" do
    it "requires filter_form parameter" do
      expect {
        described_class.new
      }.to raise_error(ArgumentError)
    end

    it "accepts filter_form as minimum requirement" do
      expect {
        described_class.new(filter_form: filter_form)
      }.not_to raise_error
    end
  end
end
