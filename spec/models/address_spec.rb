# frozen_string_literal: true

RSpec.describe Address, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:address, user: user) }

    # Note: Label presence is enforced via database default and set_default_label callback
    it "always has a label due to callback" do
      address = build(:address, user: user, label: nil)
      address.valid?
      expect(address.label).to eq("Home")
    end

    it { is_expected.to validate_presence_of(:address_line_1) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:governorate) }
    it { is_expected.to validate_length_of(:label).is_at_most(50) }
    it { is_expected.to validate_length_of(:address_line_1).is_at_most(255) }
    it { is_expected.to validate_length_of(:address_line_2).is_at_most(255) }
    it { is_expected.to validate_length_of(:city).is_at_most(100) }
    it { is_expected.to validate_length_of(:landmarks).is_at_most(500) }
    it { is_expected.to validate_inclusion_of(:governorate).in_array(User::LEBANESE_GOVERNORATES) }

    context "with phone number validation" do
      it "validates phone format when present" do
        address = build(:address, user: user, phone_number: "70123456")
        expect(address).to be_valid

        address.phone_number = "invalid"
        expect(address).not_to be_valid
      end

      it "allows blank phone number" do
        address = build(:address, user: user, phone_number: nil)
        expect(address).to be_valid
      end
    end

    describe "label uniqueness" do
      it "validates label uniqueness per user (excluding deleted)" do
        create(:address, user: user, label: "Home")
        duplicate = build(:address, user: user, label: "Home")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:label]).to include("has already been taken")
      end

      it "allows same label for different users" do
        another_user = create(:user)
        create(:address, user: user, label: "Home")
        duplicate = build(:address, user: another_user, label: "Home")

        expect(duplicate).to be_valid
      end

      it "allows same label after deletion" do
        address = create(:address, user: user, label: "Home")
        address.soft_delete

        new_address = build(:address, user: user, label: "Home")
        expect(new_address).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_address) { create(:address, user: user, label: "Active") }
    let!(:deleted_address) { create(:address, user: user, label: "Deleted", deleted_at: 1.day.ago) }
    let!(:default_address) { create(:address, user: user, label: "Default", default: true) }

    describe ".active" do
      it "returns only non-deleted addresses" do
        expect(Address.active).to include(active_address, default_address)
        expect(Address.active).not_to include(deleted_address)
      end
    end

    describe ".default_address" do
      it "returns only default address" do
        expect(Address.default_address).to eq([ default_address ])
      end

      it "excludes deleted default addresses" do
        default_address.update(deleted_at: 1.day.ago)
        expect(Address.default_address).to be_empty
      end
    end

    describe ".non_default" do
      it "returns non-default addresses" do
        expect(Address.non_default).to include(active_address)
        expect(Address.non_default).not_to include(default_address)
      end
    end

    describe ".by_label" do
      it "returns addresses matching label" do
        work_address = create(:address, user: user, label: "Work")
        expect(Address.by_label("Work")).to eq([ work_address ])
      end
    end

    describe ".recently_used" do
      it "orders by updated_at desc" do
        # Clear existing addresses from let! blocks
        Address.delete_all

        older_address = create(:address, user: user, label: "Older")
        older_address.update_column(:updated_at, 2.days.ago)

        newer_address = create(:address, user: user, label: "Newer")
        newer_address.update_column(:updated_at, 1.day.ago)

        addresses = user.addresses.recently_used
        expect(addresses.first).to eq(newer_address)
        expect(addresses.second).to eq(older_address)
      end
    end
  end

  describe "callbacks" do
    describe "#ensure_only_one_default" do
      it "unsets previous default when setting new default" do
        old_default = create(:address, user: user, label: "Old", default: true)
        new_default = create(:address, user: user, label: "New", default: true)

        old_default.reload
        expect(old_default.default).to be_falsey
        expect(new_default.default).to be_truthy
      end

      it "does not affect other users' default addresses" do
        another_user = create(:user)
        user_default = create(:address, user: user, default: true)
        another_default = create(:address, user: another_user, default: true)

        expect(user_default.reload.default).to be_truthy
        expect(another_default.reload.default).to be_truthy
      end

      it "does nothing when default is not changed" do
        address = create(:address, user: user, default: true)
        address.update(city: "Tripoli")

        expect(address.reload.default).to be_truthy
      end
    end

    describe "#set_default_label" do
      it "sets label to 'Home' if not provided" do
        address = create(:address, user: user, label: nil)
        expect(address.label).to eq("Home")
      end

      it "does not override provided label" do
        address = create(:address, user: user, label: "Work")
        expect(address.label).to eq("Work")
      end
    end
  end

  describe "#soft_delete" do
    let(:address) { create(:address, user: user, default: true) }

    it "sets deleted_at timestamp" do
      expect { address.soft_delete }.to change(address, :deleted_at).from(nil)
    end

    it "unsets default flag" do
      expect { address.soft_delete }.to change(address, :default).from(true).to(false)
    end

    it "allows recreating same label after soft delete" do
      address.soft_delete
      new_address = create(:address, user: user, label: address.label)
      expect(new_address).to be_valid
    end
  end

  describe "#deleted?" do
    it "returns true when deleted_at is set" do
      address = create(:address, user: user, deleted_at: Time.current)
      expect(address.deleted?).to be_truthy
    end

    it "returns false when deleted_at is nil" do
      address = create(:address, user: user, deleted_at: nil)
      expect(address.deleted?).to be_falsey
    end
  end

  describe "#full_address" do
    it "returns full address string" do
      address = create(:address,
                      user: user,
                      address_line_1: "123 Main St",
                      address_line_2: "Apt 4B",
                      city: "Beirut",
                      governorate: "Beirut")

      expect(address.full_address).to eq("123 Main St, Apt 4B, Beirut, Beirut")
    end

    it "excludes blank fields" do
      address = create(:address,
                      user: user,
                      address_line_1: "123 Main St",
                      address_line_2: nil,
                      city: "Beirut",
                      governorate: "Beirut")

      expect(address.full_address).to eq("123 Main St, Beirut, Beirut")
    end
  end

  describe "#short_address" do
    it "returns abbreviated address" do
      address = create(:address,
                      user: user,
                      address_line_1: "123 Main St",
                      city: "Beirut")

      expect(address.short_address).to eq("123 Main St, Beirut")
    end
  end

  describe "#display_label" do
    it "returns label when present" do
      address = create(:address, user: user, label: "Work")
      expect(address.display_label).to eq("Work")
    end

    it "returns 'Home' as fallback" do
      address = build(:address, user: user, label: "")
      expect(address.display_label).to eq("Home")
    end
  end

  describe "#only_address?" do
    it "returns true when user has only one active address" do
      address = create(:address, user: user)
      expect(address.only_address?).to be_truthy
    end

    it "returns false when user has multiple addresses" do
      address1 = create(:address, user: user)
      create(:address, user: user, label: "Work")

      expect(address1.only_address?).to be_falsey
    end

    it "excludes deleted addresses from count" do
      address1 = create(:address, user: user)
      address2 = create(:address, user: user, label: "Work")
      address2.soft_delete

      expect(address1.only_address?).to be_truthy
    end
  end
end
