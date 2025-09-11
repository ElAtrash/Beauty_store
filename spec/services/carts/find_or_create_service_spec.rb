# frozen_string_literal: true

RSpec.describe Carts::FindOrCreateService do
  let(:user) { create(:user) }
  let(:cart_token) { SecureRandom.hex(16) }
  let(:session) { {} }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  describe ".call" do
    subject(:result) { described_class.call(user: user, session: session, cart_token: cart_token) }

    context "when user has existing active cart" do
      let!(:existing_user_cart) { create(:cart, user: user) }

      it "returns the existing user cart" do
        aggregate_failures do
          expect(result).to eq(existing_user_cart)
          expect(result.user).to eq(user)
        end
      end

      it "updates session with cart token" do
        result
        expect(session[:cart_token]).to eq(existing_user_cart.session_token)
      end

      context "when user also has guest cart to merge" do
        let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }
        let!(:guest_item) { create(:cart_item, cart: guest_cart, quantity: 2) }

        before do
          allow(Carts::MergeService).to receive(:call).and_return(
            instance_double(BaseResult,
              success?: true,
              failure?: false,
              merged_any_items?: true,
              merged_items_count: 1,
              cart: existing_user_cart
            )
          )
        end

        it "attempts to merge guest cart with user cart" do
          result
          expect(Carts::MergeService).to have_received(:call).with(
            user_cart: existing_user_cart,
            guest_cart: guest_cart
          )
        end

        it "logs successful merge" do
          result
          expect(Rails.logger).to have_received(:info).with(
            /Successfully merged 1 items from guest cart/
          )
        end

        it "returns the merged cart" do
          expect(result).to eq(existing_user_cart)
        end
      end
    end

    context "when user has no existing cart but guest cart exists" do
      let(:user) { nil }
      let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }

      it "returns the existing guest cart" do
        aggregate_failures do
          expect(result).to eq(guest_cart)
          expect(result.user).to be_nil
          expect(result.session_token).to eq(cart_token)
        end
      end

      it "updates session with cart token" do
        result
        expect(session[:cart_token]).to eq(guest_cart.session_token)
      end
    end

    context "when no existing cart is found" do
      let(:user) { create(:user) }
      let(:cart_token) { nil }

      it "creates a new cart for the user" do
        aggregate_failures do
          expect(result).to be_a(Cart)
          expect(result.user).to eq(user)
          expect(result).to be_persisted
        end
      end

      it "updates session with new cart token" do
        result
        expect(session[:cart_token]).to eq(result.session_token)
      end

      it "creates cart with generated session token" do
        expect(result.session_token).to be_present
        expect(result.session_token.length).to eq(32)
      end
    end

    context "when creating cart for guest user" do
      let(:user) { nil }
      let(:cart_token) { nil }

      it "creates a new guest cart" do
        aggregate_failures do
          expect(result).to be_a(Cart)
          expect(result.user).to be_nil
          expect(result).to be_persisted
        end
      end
    end

    context "without session parameter" do
      subject(:result) { described_class.call(user: user, cart_token: cart_token) }

      let!(:existing_cart) { create(:cart, user: user) }

      it "does not attempt to update session" do
        expect(result).to eq(existing_cart)
      end
    end

    context "when cart merge fails" do
      let!(:existing_user_cart) { create(:cart, user: user) }
      let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }

      before do
        allow(Carts::MergeService).to receive(:call).and_return(
          instance_double(BaseResult,
            success?: false,
            failure?: true,
            errors: [ "Merge validation failed" ],
            cart: nil
          )
        )
      end

      it "logs merge failure" do
        result
        expect(Rails.logger).to have_received(:warn).with(
          "Carts::FindOrCreateService: Cart merge failed: Merge validation failed"
        )
      end

      it "returns the original user cart when merge fails" do
        expect(result).to eq(existing_user_cart)
      end
    end

    context "edge cases for merge logic" do
      context "when guest cart has user assigned (not truly guest)" do
        let!(:existing_user_cart) { create(:cart, user: user) }
        let(:other_user) { create(:user) }
        let!(:not_guest_cart) { create(:cart, user: other_user, session_token: cart_token) }

        before do
          allow(Carts::MergeService).to receive(:call)
        end

        it "does not attempt merge when cart has user assigned" do
          result
          expect(Carts::MergeService).not_to have_received(:call)
        end
      end

      context "when user cart is not owned by the requesting user" do
        let(:other_user) { create(:user) }
        let!(:other_user_cart) { create(:cart, user: other_user) }
        let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }

        it "returns the guest cart instead of other user's cart" do
          aggregate_failures do
            expect(result).not_to eq(other_user_cart)
            expect(result).to eq(guest_cart)
            expect(result.user).to be_nil
            expect(result.session_token).to eq(cart_token)
          end
        end
      end

      context "when merge service returns successful result without merged items" do
        let!(:existing_user_cart) { create(:cart, user: user) }
        let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }

        before do
          allow(Carts::MergeService).to receive(:call).and_return(
            instance_double(BaseResult,
              success?: true,
              failure?: false,
              merged_any_items?: false,
              cart: existing_user_cart
            )
          )
        end

        it "does not log merge info when no items were merged" do
          result
          expect(Rails.logger).not_to have_received(:info)
        end
      end
    end
  end

  describe "private methods behavior" do
    let(:service) { described_class.new(user: user, session: session, cart_token: cart_token) }

    describe "#find_existing_cart" do
      context "with user and existing user cart" do
        let!(:user_cart) { create(:cart, user: user) }
        let!(:guest_cart) { create(:cart, user: nil, session_token: cart_token) }

        it "prioritizes user cart over guest cart" do
          result = service.call
          expect(result).to eq(user_cart)
        end
      end

      context "with abandoned user cart" do
        let!(:abandoned_cart) { create(:cart, user: user, abandoned_at: 1.hour.ago) }

        it "does not find abandoned carts" do
          result = service.call
          expect(result).not_to eq(abandoned_cart)
          expect(result.user).to eq(user)
          expect(result).to be_persisted
        end
      end
    end

    describe "#should_attempt_merge?" do
      let(:cart) { create(:cart, user: user) }

      it "returns true when all conditions are met" do
        service_instance = described_class.new(user: user, cart_token: cart_token)
        expect(service_instance.send(:should_attempt_merge?, cart)).to be true
      end

      it "returns false when user is nil" do
        service_instance = described_class.new(user: nil, cart_token: cart_token)
        expect(service_instance.send(:should_attempt_merge?, create(:cart))).to be false
      end

      it "returns false when cart_token is nil" do
        service_instance = described_class.new(user: user, cart_token: nil)
        expect(service_instance.send(:should_attempt_merge?, cart)).to be false
      end

      it "returns false when cart user doesn't match" do
        other_user = create(:user)
        other_cart = create(:cart, user: other_user)
        service_instance = described_class.new(user: user, cart_token: cart_token)
        expect(service_instance.send(:should_attempt_merge?, other_cart)).to be false
      end
    end
  end
end
