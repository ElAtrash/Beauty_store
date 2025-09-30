RSpec.describe Carts::SyncService, type: :service do
  let(:cart) { create(:cart) }
  let(:product_variant) { create(:product_variant) }
  let(:notification) { { type: "success", message: "Test message", delay: 3000 } }
  let(:cleared_variants) { [ product_variant ] }

  describe ".call" do
    subject(:result) { described_class.call(cart: cart, notification: notification, variant: product_variant, cleared_variants: cleared_variants) }

    it "returns a successful BaseResult" do
      expect(result).to be_success
      expect(result).to be_a(BaseResult)
    end

    it "includes all the provided data in the result" do
      expect(result.cart).to eq(cart)
      expect(result.notification).to eq(notification)
      expect(result.variant).to eq(product_variant)
      expect(result.cleared_variants).to eq(cleared_variants)
    end

    it "reloads the cart" do
      expect(cart).to receive(:reload)
      result
    end

    context "with cart summary data" do
      let(:cart) { create(:cart, :with_items) }

      it "includes cart summary data" do
        summary = result.cart_summary_data

        expect(summary).to be_a(Hash)
        expect(summary).to have_key(:total_quantity)
        expect(summary).to have_key(:total_price)
        expect(summary).to have_key(:items_count)
      end

      it "provides correct cart summary for cart with items" do
        summary = result.cart_summary_data

        expect(summary[:total_quantity]).to be > 0
        expect(summary[:total_price]).to be_a(Money)
        expect(summary[:items_count]).to be > 0
      end
    end

    context "with nil cart" do
      let(:cart) { nil }

      it "returns default cart summary data" do
        summary = result.cart_summary_data

        expect(summary[:total_quantity]).to eq(0)
        expect(summary[:total_price]).to eq(Money.new(0))
        expect(summary[:items_count]).to eq(0)
      end
    end

    context "with minimal parameters" do
      subject(:result) { described_class.call(cart: cart) }

      it "works with just cart parameter" do
        expect(result).to be_success
        expect(result.cart).to eq(cart)
        expect(result.notification).to be_nil
        expect(result.variant).to be_nil
        expect(result.cleared_variants).to eq([])
      end
    end
  end
end
