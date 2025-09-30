# frozen_string_literal: true

RSpec.describe OrderConfirmation::TimelineComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:order) { build(:order, fulfillment_status: :processing, number: 'ORD-12345') }
  let(:component) { described_class.new(order: order) }

  describe "rendering" do
    it "renders the vertical timeline with progress bar" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.text).to include("Order Status")
        expect(rendered.css('[role="list"]')).to be_present
        expect(rendered.css('.bg-green-500')).to be_present
      end
    end

    it "displays timeline steps with I18n translations" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.text).to include("Order Confirmed")
        expect(rendered.text).to include("Processing")
        expect(rendered.text).to include("We've received your order")
        expect(rendered.text).to include("Preparing your beauty essentials")
      end
    end

    it "shows estimated times only for dispatched incomplete steps" do
      courier_order = build(:order, fulfillment_status: :processing, delivery_method: 'courier', delivery_date: 1.day.from_now, delivery_time_slot: "09:00-12:00", number: 'ORD-12345')
      courier_component = described_class.new(order: courier_order)
      rendered = render_inline(courier_component)

      expect(rendered.text).to include("Estimated:") if rendered.text.include?("Dispatched")
    end

    context "when order is courier delivery" do
      let(:order) { build(:order, delivery_method: 'courier', fulfillment_status: :processing, number: 'ORD-12345') }

      it "includes courier-specific steps" do
        rendered = render_inline(component)

        expect(rendered.text).to include("Packed")
        expect(rendered.text).to include("Dispatched")
        expect(rendered.text).to include("Delivered")
      end
    end

    context "when order is pickup" do
      let(:order) { build(:order, delivery_method: 'pickup', fulfillment_status: :processing, number: 'ORD-12345') }

      it "includes pickup-specific steps" do
        aggregate_failures do
          rendered = render_inline(component)

          expect(rendered.text).to include("Packed")
          expect(rendered.text).to include("Picked Up")
        end
      end
    end

    context "when order is cancelled" do
      let(:order) { build(:order, fulfillment_status: 'cancelled', number: 'ORD-12345') }

      it "shows cancelled timeline steps" do
        aggregate_failures do
          rendered = render_inline(component)
          step_keys = rendered.text

          expect(step_keys).to include("Order Confirmed")
          expect(step_keys).to include("Order Cancelled")
        end
      end

      it "uses gray styling instead of green for cancelled orders" do
        aggregate_failures do
          cancelled_component = described_class.new(order: order)
          rendered = render_inline(cancelled_component)

          expect(rendered.to_html).not_to include("border-green-500")
          expect(rendered.to_html).not_to include("text-green-600")
          expect(rendered.to_html).not_to include("bg-green-50")

          expect(rendered.to_html).to include("border-gray-400")
          expect(rendered.to_html).to include("text-gray-500")
          expect(rendered.to_html).to include("bg-gray-50")
        end
      end
    end
  end

  describe "#progress_percentage" do
    it "calculates correct progress percentage based on index position" do
      # Unfulfilled order with courier delivery: at index 0 out of max index 4 (delivered)
      unfulfilled_order = build(:order, fulfillment_status: 'unfulfilled', delivery_method: 'courier', number: 'ORD-TEST')
      unfulfilled_component = described_class.new(order: unfulfilled_order)

      expect(unfulfilled_component.progress_percentage).to eq(0)
    end

    context "when order is completed" do
      let(:order) { build(:order, fulfillment_status: 'delivered', number: 'ORD-12345', delivery_method: 'courier') }

      it "shows 100% progress" do
        expect(component.progress_percentage).to eq(100)
      end
    end

    context "when timeline is empty" do
      it "returns 0 percentage" do
        allow(component).to receive(:timeline_steps).and_return([])
        expect(component.progress_percentage).to eq(0)
      end
    end
  end

  describe "step styling" do
    it "applies correct theme-based classes" do
      aggregate_failures do
        rendered = render_inline(component)

        # Should have completed step styling from theme
        expect(rendered.to_html).to include("border-green-500")
        expect(rendered.to_html).to include("text-green-600")

        # Should have current step styling from theme
        expect(rendered.to_html).to include("border-interactive-primary")
      end
    end

    it "applies correct theme for each step state" do
      # Test with processing order to show different themes
      processing_order = build(:order, fulfillment_status: 'processing', number: 'ORD-TEST')
      processing_component = described_class.new(order: processing_order)

      unfulfilled_step = processing_component.send(:build_step, :unfulfilled)
      processing_step = processing_component.send(:build_step, :processing)
      packed_step = processing_component.send(:build_step, :packed)

      # Theme is now pre-resolved to actual hash, check the structure
      expect(unfulfilled_step[:theme]).to have_key(:icon_wrapper)
      expect(unfulfilled_step[:theme][:icon_wrapper]).to include("border-green-500") # Completed styling
      expect(processing_step[:theme][:icon_wrapper]).to include("border-interactive-primary") # Current styling
      expect(packed_step[:theme][:icon_wrapper]).to include("border-gray-300") # Pending styling
    end

    it "includes accessibility attributes" do
      aggregate_failures do
        rendered = render_inline(component)

        expect(rendered.css('[role="list"]')).to be_present
        expect(rendered.css('[role="listitem"]')).to be_present
        expect(rendered.css('[aria-label]')).to be_present
      end
    end
  end

  describe "estimated times" do
    context "for non-shipped steps" do
      let(:order) { build(:order, fulfillment_status: :processing, number: 'ORD-12345', delivery_method: 'pickup') }

      it "returns nil for all non-dispatched steps" do
        aggregate_failures do
          expect(component.send(:calculate_estimated_time, :unfulfilled)).to be_nil
          expect(component.send(:calculate_estimated_time, :processing)).to be_nil
          expect(component.send(:calculate_estimated_time, :packed)).to be_nil
          expect(component.send(:calculate_estimated_time, :delivered)).to be_nil
          expect(component.send(:calculate_estimated_time, :picked_up)).to be_nil
        end
      end
    end

    context "for dispatched step with delivery schedule" do
      let(:delivery_date) { 1.day.from_now }
      let(:order) { build(:order, fulfillment_status: :processing, number: 'ORD-12345', delivery_method: 'courier', delivery_date: delivery_date, delivery_time_slot: "09:00-12:00") }

      it "uses actual delivery schedule for dispatched step only" do
        aggregate_failures do
          result = component.send(:calculate_estimated_time, :dispatched)
          expect(result).to include(delivery_date.strftime("%A, %b %d"))
          expect(result).to include("09:00-12:00")
        end
      end
    end

    context "for pickup orders" do
      let(:order) { build(:order, fulfillment_status: :processing, number: 'ORD-12345', delivery_method: 'pickup') }

      it "returns nil for dispatched step" do
        result = component.send(:calculate_estimated_time, :dispatched)
        expect(result).to be_nil
      end
    end

    it "returns nil for cancelled orders" do
      cancelled_order = build(:order, fulfillment_status: 'cancelled')
      cancelled_component = described_class.new(order: cancelled_order)

      expect(cancelled_component.send(:calculate_estimated_time, :processing)).to be_nil
    end
  end
end
