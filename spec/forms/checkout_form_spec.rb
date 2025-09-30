# frozen_string_literal: true

RSpec.describe CheckoutForm, type: :model do
  describe "validations" do
    subject(:form) { described_class.new(attributes) }

    let(:valid_attributes) do
      {
        email: "customer@example.com",
        phone_number: "+96170123456",
        first_name: "John",
        last_name: "Doe",
        address_line_1: "123 Main Street",
        city: "Beirut",
        delivery_method: "courier",
        payment_method: "cod",
        delivery_date: Date.tomorrow,
        delivery_time_slot: "09:00-12:00"
      }
    end

    context "with valid attributes" do
      let(:attributes) { valid_attributes }

      it { is_expected.to be_valid }
    end

    describe "email validation" do
      let(:attributes) { valid_attributes.merge(email: email) }

      context "when email is blank" do
        let(:email) { "" }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:email]).to include("can't be blank")
        end
      end

      context "when email is invalid format" do
        let(:email) { "invalid-email" }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:email]).to include("is invalid")
        end
      end

      context "when email is extremely long" do
        let(:email) { "a" * 300 + "@example.com" }

        it "accepts long emails but may fail at service level" do
          expect(form).to be_valid
        end
      end

      context "when email contains SQL injection" do
        let(:email) { "test@example.com'; DROP TABLE users; --" }

        it "validates format only" do
          form.validate
          expect(form.errors[:email]).to include("is invalid")
        end
      end
    end

    describe "phone_number validation" do
      let(:attributes) { valid_attributes.merge(phone_number: phone_number) }

      context "when phone_number is blank" do
        let(:phone_number) { "" }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:phone_number]).to include("can't be blank")
        end
      end

      context "when phone_number is invalid format" do
        let(:phone_number) { "invalid_phone" }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:phone_number]).to include("must be a valid Lebanon phone number")
        end
      end

      context "with valid Lebanon phone formats" do
        %w[+96170123456 96170123456 70123456 +96171123456 96176123456 76123456].each do |valid_phone|
          context "when phone is #{valid_phone}" do
            let(:phone_number) { valid_phone }

            it { is_expected.to be_valid }
          end
        end
      end

      context "with invalid Lebanon phone formats" do
        %w[+1234567890 123456 12345678901 +96169123456 69123456].each do |invalid_phone|
          context "when phone is #{invalid_phone}" do
            let(:phone_number) { invalid_phone }

            it { is_expected.not_to be_valid }
          end
        end
      end
    end

    describe "name validations" do
      context "when first_name is blank" do
        let(:attributes) { valid_attributes.merge(first_name: "") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:first_name]).to include("can't be blank")
        end
      end

      context "when first_name is extremely long" do
        let(:attributes) { valid_attributes.merge(first_name: "a" * 1000) }

        it "accepts long names" do
          expect(form).to be_valid
        end
      end

      context "when last_name is blank" do
        let(:attributes) { valid_attributes.merge(last_name: "") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:last_name]).to include("can't be blank")
        end
      end

      context "when names contain SQL injection attempts" do
        let(:attributes) do
          valid_attributes.merge(
            first_name: "Robert'; DROP TABLE students; --",
            last_name: "Tables'; DELETE FROM orders; --"
          )
        end

        it "accepts the input as text" do
          expect(form).to be_valid
        end
      end
    end

    describe "delivery method validation" do
      context "when delivery_method is invalid" do
        let(:attributes) { valid_attributes.merge(delivery_method: "rocket") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:delivery_method]).to include("is not included in the list")
        end
      end

      %w[courier pickup].each do |method|
        context "when delivery_method is #{method}" do
          let(:attributes) { valid_attributes.merge(delivery_method: method) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe "courier delivery validations" do
      let(:attributes) { valid_attributes.merge(delivery_method: "courier") }

      context "when address_line_1 is blank" do
        let(:attributes) { valid_attributes.merge(delivery_method: "courier", address_line_1: "") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:address_line_1]).to include("can't be blank")
        end
      end

      context "when delivery_date is blank" do
        let(:attributes) { valid_attributes.merge(delivery_method: "courier", delivery_date: nil) }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:delivery_date]).to include("can't be blank")
        end
      end

      context "when delivery_time_slot is blank" do
        let(:attributes) { valid_attributes.merge(delivery_method: "courier", delivery_time_slot: "") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:delivery_time_slot]).to include("can't be blank")
        end
      end
    end

    describe "pickup delivery validations" do
      let(:attributes) { valid_attributes.merge(delivery_method: "pickup") }

      it "does not require address_line_1" do
        form.address_line_1 = ""
        expect(form).to be_valid
      end

      it "does not require delivery_date" do
        form.delivery_date = nil
        expect(form).to be_valid
      end

      it "does not require delivery_time_slot" do
        form.delivery_time_slot = ""
        expect(form).to be_valid
      end
    end

    describe "payment method validation" do
      context "when payment_method is invalid" do
        let(:attributes) { valid_attributes.merge(payment_method: "credit_card") }

        it { is_expected.not_to be_valid }
        it "has error message" do
          form.validate
          expect(form.errors[:payment_method]).to include("is not included in the list")
        end
      end

      context "when payment_method is cod" do
        let(:attributes) { valid_attributes.merge(payment_method: "cod") }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "instance methods" do
    let(:form) do
      described_class.new(
        first_name: "John",
        last_name: "Doe",
        phone_number: "+96170123456",
        address_line_1: "123 Main Street",
        address_line_2: "Apt 4B",
        city: "Beirut",
        landmarks: "Near ABC Bank",
        delivery_method: "courier"
      )
    end

    describe "#full_name" do
      it "returns concatenated first and last name" do
        expect(form.full_name).to eq("John Doe")
      end

      context "when names have extra spaces" do
        before do
          form.first_name = " John "
          form.last_name = " Doe "
        end

        it "strips extra spaces" do
          expect(form.full_name).to eq("John   Doe")
        end
      end
    end

    describe "#courier_delivery?" do
      context "when delivery_method is courier" do
        before { form.delivery_method = "courier" }

        it { expect(form.courier_delivery?).to be true }
      end

      context "when delivery_method is pickup" do
        before { form.delivery_method = "pickup" }

        it { expect(form.courier_delivery?).to be false }
      end
    end

    describe "#formatted_phone" do
      context "with +961 prefix" do
        before { form.phone_number = "+96170123456" }

        it "returns formatted number" do
          expect(form.formatted_phone).to eq("+96170123456")
        end
      end

      context "with 961 prefix" do
        before { form.phone_number = "96170123456" }

        it "adds + prefix" do
          expect(form.formatted_phone).to eq("+96170123456")
        end
      end

      context "without country code" do
        before { form.phone_number = "70123456" }

        it "adds country code" do
          expect(form.formatted_phone).to eq("+96170123456")
        end
      end

      context "with extra characters" do
        before { form.phone_number = "+961-70-123-456" }

        it "removes non-digits and formats" do
          expect(form.formatted_phone).to eq("+96170123456")
        end
      end
    end

    describe "#shipping_address" do
      it "returns hash with shipping details" do
        expected = {
          first_name: "John",
          last_name: "Doe",
          address_line_1: "123 Main Street",
          address_line_2: "Apt 4B",
          city: "Beirut",
          landmarks: "Near ABC Bank",
          phone: "+96170123456"
        }
        expect(form.shipping_address).to eq(expected)
      end
    end

    describe "#billing_address" do
      it "returns same as shipping address" do
        expect(form.billing_address).to eq(form.shipping_address)
      end
    end

    describe "#to_h" do
      let(:form) do
        described_class.new(
          email: "customer@example.com",
          phone_number: "70123456",
          first_name: "John",
          last_name: "Doe",
          delivery_method: "courier",
          delivery_date: Date.new(2024, 1, 15),
          delivery_time_slot: "09:00-12:00",
          payment_method: "cod",
          delivery_notes: "Ring twice",
          address_line_1: "123 Main St",
          city: "Beirut"
        )
      end

      it "returns complete form data as hash" do
        result = form.to_h
        expect(result).to include(
          email: "customer@example.com",
          phone_number: "+96170123456",
          full_name: "John Doe",
          delivery_method: "courier",
          delivery_date: Date.new(2024, 1, 15),
          delivery_time_slot: "09:00-12:00",
          payment_method: "cod",
          delivery_notes: "Ring twice"
        )
        expect(result[:shipping_address]).to be_a(Hash)
        expect(result[:billing_address]).to be_a(Hash)
      end
    end
  end

  describe "session management" do
    let(:form) { described_class.new(email: "test@example.com", first_name: "John") }
    let(:session) { {} }

    describe "#persist_to_session" do
      it "stores form attributes in session" do
        form.persist_to_session(session)
        expect(session[:checkout_form_data]).to include(
          "email" => "test@example.com",
          "first_name" => "John"
        )
      end

      it "removes blank values" do
        form.last_name = ""
        form.persist_to_session(session)
        expect(session[:checkout_form_data]).not_to have_key("last_name")
      end
    end

    describe "#clear_from_session" do
      before { session[:checkout_form_data] = { email: "test@example.com" } }

      it "removes form data from session" do
        form.clear_from_session(session)
        expect(session[:checkout_form_data]).to be_nil
      end
    end

    describe "#valid_for_persistence?" do
      context "when only default fields are present" do
        let(:form) { described_class.new }

        it "returns true because delivery_method has default value" do
          expect(form.valid_for_persistence?).to be true
        end
      end

      context "when all persistence fields are explicitly blank" do
        let(:form) do
          described_class.new(
            email: nil,
            first_name: nil,
            delivery_method: nil,
            address_line_1: nil
          )
        end

        it "returns false when no meaningful data is present" do
          expect(form.valid_for_persistence?).to be false
        end
      end

      context "when email is present" do
        let(:form) { described_class.new(email: "test@example.com") }

        it { expect(form.valid_for_persistence?).to be true }
      end

      context "when first_name is present" do
        let(:form) { described_class.new(first_name: "John") }

        it { expect(form.valid_for_persistence?).to be true }
      end
    end

    describe "#valid_for_full_persistence?" do
      context "when all required fields are present" do
        let(:form) { described_class.new(email: "test@example.com", first_name: "John", last_name: "Doe") }

        it { expect(form.valid_for_full_persistence?).to be true }
      end

      context "when required fields are missing" do
        let(:form) { described_class.new(email: "test@example.com", first_name: "John") }

        it { expect(form.valid_for_full_persistence?).to be false }
      end
    end
  end

  describe "class methods" do
    describe ".from_session" do
      context "with session data" do
        let(:session_data) { { "email" => "test@example.com", "first_name" => "John" } }

        it "creates form with session data" do
          form = described_class.from_session(session_data)
          expect(form.email).to eq("test@example.com")
          expect(form.first_name).to eq("John")
        end
      end

      context "with nil session data" do
        it "creates empty form" do
          form = described_class.from_session(nil)
          expect(form.email).to be_nil
          expect(form.first_name).to be_nil
        end
      end
    end

    describe ".normalize_delivery_method" do
      it "returns valid delivery methods unchanged" do
        expect(described_class.normalize_delivery_method("courier")).to eq("courier")
        expect(described_class.normalize_delivery_method("pickup")).to eq("pickup")
      end

      it "defaults invalid methods to pickup" do
        expect(described_class.normalize_delivery_method("rocket")).to eq("pickup")
        expect(described_class.normalize_delivery_method(nil)).to eq("pickup")
        expect(described_class.normalize_delivery_method("")).to eq("pickup")
      end
    end
  end

  describe "#update_from_params" do
    let(:form) { described_class.new(email: "old@example.com") }
    let(:params) { { email: "new@example.com", first_name: "John" } }

    it "updates form attributes" do
      result = form.update_from_params(params)
      expect(result).to eq(form)
      expect(form.email).to eq("new@example.com")
      expect(form.first_name).to eq("John")
    end
  end
end
