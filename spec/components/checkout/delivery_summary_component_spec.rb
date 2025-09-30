# frozen_string_literal: true

RSpec.describe Checkout::DeliverySummaryComponent, type: :component do
  subject { described_class.new(delivery_method: delivery_method, address_data: address_data, city: city) }

  let(:delivery_method) { "courier" }
  let(:address_data) { {} }
  let(:city) { "Beirut" }

  describe "constants" do
    it "defines state constants" do
      expect(described_class::PICKUP_STATE).to eq(:pickup)
      expect(described_class::ADDRESS_STATE).to eq(:address)
      expect(described_class::SET_ADDRESS_STATE).to eq(:set_address)
    end
  end

  describe "#summary_state" do
    context "with pickup delivery method" do
      let(:delivery_method) { "pickup" }

      it "returns pickup state" do
        expect(subject.summary_state).to eq(:pickup)
      end
    end

    context "with courier delivery method" do
      let(:delivery_method) { "courier" }

      context "when address is filled" do
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns address state" do
          expect(subject.summary_state).to eq(:address)
        end
      end

      context "when address is not filled" do
        let(:address_data) { {} }

        it "returns set_address state" do
          expect(subject.summary_state).to eq(:set_address)
        end
      end

      context "when address_line_1 is blank" do
        let(:address_data) { { address_line_1: "" } }

        it "returns set_address state" do
          expect(subject.summary_state).to eq(:set_address)
        end
      end

      context "when address_line_1 is nil" do
        let(:address_data) { { address_line_1: nil } }

        it "returns set_address state" do
          expect(subject.summary_state).to eq(:set_address)
        end
      end
    end

    context "with unknown delivery method" do
      let(:delivery_method) { "unknown" }

      it "falls back to pickup state" do
        expect(subject.summary_state).to eq(:pickup)
      end
    end

    context "state memoization" do
      let(:delivery_method) { "courier" }
      let(:address_data) { {} }

      it "memoizes the state calculation" do
        first_result = subject.summary_state
        expect(first_result).to eq(:set_address)

        expect(subject).not_to receive(:calculate_state)
        second_result = subject.summary_state
        expect(second_result).to eq(:set_address)
        expect(second_result).to be(first_result)
      end
    end
  end

  describe "state helper methods" do
    describe "#pickup_state?" do
      context "when in pickup state" do
        let(:delivery_method) { "pickup" }

        it "returns true" do
          expect(subject.pickup_state?).to be true
        end
      end

      context "when not in pickup state" do
        let(:delivery_method) { "courier" }
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns false" do
          expect(subject.pickup_state?).to be false
        end
      end
    end

    describe "#address_state?" do
      context "when in address state" do
        let(:delivery_method) { "courier" }
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns true" do
          expect(subject.address_state?).to be true
        end
      end

      context "when not in address state" do
        let(:delivery_method) { "pickup" }

        it "returns false" do
          expect(subject.address_state?).to be false
        end
      end
    end

    describe "#set_address_state?" do
      context "when in set_address state" do
        let(:delivery_method) { "courier" }
        let(:address_data) { {} }

        it "returns true" do
          expect(subject.set_address_state?).to be true
        end
      end

      context "when not in set_address state" do
        let(:delivery_method) { "pickup" }

        it "returns false" do
          expect(subject.set_address_state?).to be false
        end
      end
    end
  end

  describe "private helper methods" do
    describe "#courier_with_address?" do
      context "with courier delivery and filled address" do
        let(:delivery_method) { "courier" }
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns true" do
          expect(subject.send(:courier_with_address?)).to be true
        end
      end

      context "with courier delivery and empty address" do
        let(:delivery_method) { "courier" }
        let(:address_data) { {} }

        it "returns false" do
          expect(subject.send(:courier_with_address?)).to be false
        end
      end

      context "with pickup delivery" do
        let(:delivery_method) { "pickup" }
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns false" do
          expect(subject.send(:courier_with_address?)).to be false
        end
      end
    end

    describe "#courier_without_address?" do
      context "with courier delivery and empty address" do
        let(:delivery_method) { "courier" }
        let(:address_data) { {} }

        it "returns true" do
          expect(subject.send(:courier_without_address?)).to be true
        end
      end

      context "with courier delivery and filled address" do
        let(:delivery_method) { "courier" }
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns false" do
          expect(subject.send(:courier_without_address?)).to be false
        end
      end

      context "with pickup delivery" do
        let(:delivery_method) { "pickup" }
        let(:address_data) { {} }

        it "returns false" do
          expect(subject.send(:courier_without_address?)).to be false
        end
      end
    end

    describe "#address_filled?" do
      context "when address_line_1 is present" do
        let(:address_data) { { address_line_1: "123 Main St" } }

        it "returns true" do
          expect(subject.send(:address_filled?)).to be true
        end
      end

      context "when address_line_1 is blank" do
        let(:address_data) { { address_line_1: "" } }

        it "returns false" do
          expect(subject.send(:address_filled?)).to be false
        end
      end

      context "when address_line_1 is nil" do
        let(:address_data) { { address_line_1: nil } }

        it "returns false" do
          expect(subject.send(:address_filled?)).to be false
        end
      end

      context "when address_data is empty" do
        let(:address_data) { {} }

        it "returns false" do
          expect(subject.send(:address_filled?)).to be false
        end
      end
    end
  end

  describe "state transitions" do
    it "ensures only one state can be true at a time" do
      all_combinations = [
        { method: "pickup", address: {} },
        { method: "pickup", address: { address_line_1: "123 Main St" } },
        { method: "courier", address: {} },
        { method: "courier", address: { address_line_1: "123 Main St" } },
        { method: "unknown", address: {} }
      ]

      all_combinations.each do |combo|
        component = described_class.new(
          delivery_method: combo[:method],
          address_data: combo[:address]
        )

        states = [
          component.pickup_state?,
          component.address_state?,
          component.set_address_state?
        ]

        expect(states.count(true)).to eq(1),
          "Expected exactly one state to be true for #{combo}, got #{states}"
      end
    end
  end

  describe "StoreInformation integration" do
    let(:delivery_method) { "pickup" }

    it "includes StoreInformation concern" do
      expect(described_class.included_modules).to include(StoreInformation)
    end

    it "can call store_info method through StoreInformation concern" do
      expect { subject.send(:store_info) }.not_to raise_error
    end
  end

  describe "component initialization" do
    it "accepts all required parameters" do
      component = described_class.new(
        delivery_method: "courier",
        address_data: { address_line_1: "Test St" },
        city: "Tripoli"
      )

      expect(component.delivery_method).to eq("courier")
      expect(component.address_data).to eq({ address_line_1: "Test St" })
      expect(component.city).to eq("Tripoli")
    end

    it "has default city value" do
      component = described_class.new(delivery_method: "pickup")
      expect(component.city).to eq("Beirut")
    end
  end
end
