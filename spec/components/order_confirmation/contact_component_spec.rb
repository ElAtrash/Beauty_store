# frozen_string_literal: true

RSpec.describe OrderConfirmation::ContactComponent, type: :component do
  include ViewComponent::TestHelpers
  let(:order) { create(:order) }
  let(:component) { described_class.new(order: order) }

  before do
    order.update!(
      email: "customer@example.com",
      phone_number: "+961 70 123 456",
      delivery_method: delivery_method,
      shipping_address: shipping_address,
      delivery_notes: delivery_notes
    )
  end

  context "with courier delivery" do
    let(:delivery_method) { "courier" }
    let(:shipping_address) do
      {
        "address_line_1" => "123 Main Street",
        "address_line_2" => "Apartment 4B",
        "landmarks" => "Near the big oak tree"
      }
    end
    let(:delivery_notes) { "Ring the doorbell twice" }

    it "renders contact and delivery information with I18n labels" do
      aggregate_failures do
        render_inline(component)

        expect(rendered_content).to include("Contact &amp; Delivery Details")
        expect(rendered_content).to include(I18n.t("order.contact.email"))
        expect(rendered_content).to include(I18n.t("order.contact.phone"))
        expect(rendered_content).to include(I18n.t("order.contact.delivery_method"))
        expect(rendered_content).to include("customer@example.com")
        expect(rendered_content).to include("+961 70 123 456")
        expect(rendered_content).to include(I18n.t("order.contact.delivery_methods.courier"))
      end
    end

    it "renders delivery address with I18n labels" do
      aggregate_failures do
        render_inline(component)

        expect(rendered_content).to include(I18n.t("order.contact.delivery_address"))
        expect(rendered_content).to include("123 Main Street")
        expect(rendered_content).to include("Apartment 4B")
        expect(rendered_content).to include("Near the big oak tree")
      end
    end

    it "renders delivery notes with I18n labels" do
      aggregate_failures do
        render_inline(component)

        expect(rendered_content).to include(I18n.t("order.contact.delivery_notes"))
        expect(rendered_content).to include("Ring the doorbell twice")
      end
    end

    context "without address line 2" do
      let(:shipping_address) do
        {
          "address_line_1" => "123 Main Street",
          "landmarks" => "Near the big oak tree"
        }
      end

      it "does not render empty address line 2" do
        aggregate_failures do
          render_inline(component)

          expect(rendered_content).to include("123 Main Street")
          expect(rendered_content).to include("Near the big oak tree")
          expect(rendered_content).not_to include("Apartment")
        end
      end
    end

    context "without landmarks" do
      let(:shipping_address) do
        {
          "address_line_1" => "123 Main Street",
          "address_line_2" => "Apartment 4B"
        }
      end

      it "does not render landmarks section" do
        aggregate_failures do
          render_inline(component)

          expect(rendered_content).to include("123 Main Street")
          expect(rendered_content).to include("Apartment 4B")
          expect(rendered_content).not_to include("Near the")
        end
      end
    end

    context "without delivery notes" do
      let(:delivery_notes) { nil }

      it "does not render delivery notes section" do
        aggregate_failures do
          render_inline(component)

          expect(rendered_content).not_to include("Delivery Notes")
          expect(rendered_content).not_to include("Ring the")
        end
      end
    end
  end

  context "with store pickup" do
    let(:delivery_method) { "pickup" }
    let(:shipping_address) { {} }
    let(:delivery_notes) { nil }

    it "renders pickup information with I18n labels" do
      aggregate_failures do
        render_inline(component)

        expect(rendered_content).to include("Contact &amp; Delivery Details")
        expect(rendered_content).to include("customer@example.com")
        expect(rendered_content).to include("+961 70 123 456")
        expect(rendered_content).to include(I18n.t("order.contact.delivery_methods.pickup"))
      end
    end

    it "does not render delivery address" do
      render_inline(component)

      expect(rendered_content).not_to include(I18n.t("order.contact.delivery_address"))
    end

    it "does not render delivery notes" do
      render_inline(component)

      expect(rendered_content).not_to include(I18n.t("order.contact.delivery_notes"))
    end
  end
end
