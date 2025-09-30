# frozen_string_literal: true

RSpec.describe Modal::BaseComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:component) { described_class.new(id: "test-modal", title: "Test Modal") }

  describe "initialization" do
    it "sets required attributes" do
      expect(component.id).to eq("test-modal")
      expect(component.title).to eq("Test Modal")
    end

    it "sets default size and position" do
      expect(component.size).to eq(:medium)
      expect(component.position).to eq(:right)
    end

    it "accepts custom size and position" do
      custom_component = described_class.new(
        id: "custom",
        title: "Custom",
        size: :full,
        position: :left
      )

      expect(custom_component.size).to eq(:full)
      expect(custom_component.position).to eq(:left)
    end

    it "validates size options" do
      expect {
        described_class.new(id: "test", title: "Test", size: :invalid)
      }.to raise_error(ArgumentError, /Invalid size: invalid/)
    end

    it "validates position options" do
      expect {
        described_class.new(id: "test", title: "Test", position: :invalid)
      }.to raise_error(ArgumentError, /Invalid position: invalid/)
    end
  end

  describe "basic functionality" do
    it "can be instantiated" do
      expect(component).to be_a(described_class)
    end

    it "inherits from ViewComponent::Base" do
      expect(described_class.superclass).to eq(ViewComponent::Base)
    end

    it "has required public attributes" do
      expect(component).to respond_to(:id)
      expect(component).to respond_to(:title)
      expect(component).to respond_to(:size)
      expect(component).to respond_to(:position)
    end
  end

  describe "content rendering - dual compatibility" do
    it "works with slot-based content (modern approach)" do
      # This test will be handled by ViewComponent slots test
      expect(component).to respond_to(:body)
    end

    context "with method-based content (backward compatibility)" do
      let(:method_component) do
        Class.new(described_class) do
          private

          def content
            "Method-based content"
          end
        end.new(id: "method-test", title: "Method Test")
      end

      it "allows child components to override content method" do
        expect(method_component.send(:content)).to eq("Method-based content")
      end
    end
  end

  describe "helper methods" do
    it "has header action helper" do
      expect(component.send(:has_header_action?)).to be false
    end

    it "has footer helper" do
      expect(component.send(:has_footer?)).to be false
    end

    it "provides container data attributes" do
      attrs = component.send(:container_data_attributes)
      expect(attrs).to be_a(Hash)
      expect(attrs[:data]).to be_a(Hash)
      expect(attrs[:data][:controller]).to include("modal")
    end

    it "provides ARIA attributes" do
      aria_attrs = component.send(:aria_attributes)
      expect(aria_attrs).to be_a(Hash)
      expect(aria_attrs[:role]).to eq("dialog")
      expect(aria_attrs[:"aria-modal"]).to eq("true")
    end
  end

  describe "CSS class generation" do
    it "generates container classes" do
      classes = component.send(:container_classes)
      expect(classes).to be_a(String)
      expect(classes).to include("fixed")
      expect(classes).to include("inset-y-0")
      expect(classes).to include("z-[120]")
    end

    it "generates panel classes" do
      classes = component.send(:panel_classes)
      expect(classes).to be_a(String)
      expect(classes).to include("fixed")
      expect(classes).to include("bg-white")
    end

    it "generates overlay classes" do
      classes = component.send(:overlay_classes)
      expect(classes).to be_a(String)
      expect(classes).to include("fixed")
      expect(classes).to include("inset-0")
    end
  end

  describe "position configuration" do
    it "uses POSITION_CONFIG for consistent positioning" do
      expect(described_class::POSITION_CONFIG).to be_a(Hash)
      expect(described_class::POSITION_CONFIG).to have_key(:left)
      expect(described_class::POSITION_CONFIG).to have_key(:right)
      expect(described_class::POSITION_CONFIG).to have_key(:center)

      # Each position should have required keys
      [ :left, :right, :center ].each do |position|
        config = described_class::POSITION_CONFIG[position]
        expect(config).to have_key(:container)
        expect(config).to have_key(:panel_base)
        expect(config).to have_key(:panel_closed)
        expect(config).to have_key(:panel_open)
      end
    end

    it "applies position-specific classes" do
      left_component = described_class.new(id: "test", title: "Test", position: :left)
      left_classes = left_component.send(:position_container_classes)
      expect(left_classes).to eq("left-0")

      right_component = described_class.new(id: "test", title: "Test", position: :right)
      right_classes = right_component.send(:position_container_classes)
      expect(right_classes).to eq("right-0")
    end
  end

  describe "state classes for JavaScript" do
    it "provides open state classes" do
      open_classes = component.send(:open_state_classes)

      expect(open_classes).to be_a(Hash)
      expect(open_classes).to have_key(:container)
      expect(open_classes).to have_key(:overlay)
      expect(open_classes).to have_key(:panel)
      expect(open_classes[:container]).to eq("block")
    end

    it "provides closed state classes" do
      closed_classes = component.send(:closed_state_classes)

      expect(closed_classes).to be_a(Hash)
      expect(closed_classes).to have_key(:container)
      expect(closed_classes).to have_key(:overlay)
      expect(closed_classes).to have_key(:panel)
      expect(closed_classes[:container]).to eq("hidden")
    end
  end

  describe "data attributes handling" do
    it "includes modal controller" do
      attrs = component.send(:container_data_attributes)
      expect(attrs[:data][:controller]).to include("modal")
      expect(attrs[:data][:modal_id_value]).to eq("test-modal")
    end

    it "merges additional data attributes" do
      custom_component = described_class.new(
        id: "test",
        title: "Test",
        data: { "custom-attr": "value" }
      )
      attrs = custom_component.send(:container_data_attributes)
      expect(attrs[:data][:"custom-attr"]).to eq("value")
    end

    it "combines controllers when additional controller specified" do
      custom_component = described_class.new(
        id: "test",
        title: "Test",
        data: { controller: "custom" }
      )
      attrs = custom_component.send(:container_data_attributes)
      expect(attrs[:data][:controller]).to eq("modal custom")
    end
  end

  describe "dual compatibility helpers" do
    it "checks for header actions correctly" do
      expect(component.send(:has_header_action?)).to be false
    end

    it "checks for footer content correctly" do
      expect(component.send(:has_footer?)).to be false
    end

    it "works with inherited components that have backward compatibility methods" do
      # Create a component that still has the old methods
      legacy_component = Class.new(described_class) do
        private

        def header_actions
          "Legacy header action"
        end

        def footer_content
          "Legacy footer content"
        end
      end.new(id: "legacy", title: "Legacy")

      expect(legacy_component.send(:has_header_action?)).to be true
      expect(legacy_component.send(:has_footer?)).to be true
    end
  end

  describe "ViewComponent slots" do
    it "responds to body slot method" do
      expect(component).to respond_to(:body)
    end

    it "responds to header_action slot method" do
      expect(component).to respond_to(:header_action)
    end

    it "responds to footer slot method" do
      expect(component).to respond_to(:footer)
    end
  end
end
