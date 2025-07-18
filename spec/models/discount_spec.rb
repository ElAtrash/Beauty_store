# frozen_string_literal: true

RSpec.describe Discount, type: :model do
  subject(:discount) { build(:discount) }

  describe 'instance methods' do
    describe '#active?' do
      let(:discount) do
        build_stubbed(:discount, active: true, valid_from: 1.day.ago,
                      valid_until: 1.day.from_now, usage_limit: 10,
                      usage_count: 5)
      end

      context 'when the discount is active, valid, and has usage available' do
        it 'returns true' do
          expect(discount).to be_active
        end

        it 'returns true when usage limit is nil' do
          discount.usage_limit = nil
          expect(discount).to be_active
        end
      end

      context 'when the discount is not usable' do
        it 'returns false if globally inactive' do
          discount.active = false
          expect(discount).not_to be_active
        end

        it 'returns false if it has not become valid yet' do
          discount.valid_from = 1.day.from_now
          expect(discount).not_to be_active
        end

        it 'returns false if it has expired' do
          discount.valid_until = 1.day.ago
          expect(discount).not_to be_active
        end

        it 'returns false if usage limit has been reached' do
          discount.usage_count = 10
          expect(discount).not_to be_active
        end
      end
    end

    describe '#apply_to' do
      let(:initial_amount) { Money.new(10_000) }

      context 'when the discount is active' do
        context 'with a fixed discount' do
          let(:discount) { build_stubbed(:discount, :fixed, value_cents: 1000) }

          it 'subtracts the fixed amount' do
            expect(discount.apply_to(initial_amount)).to eq Money.new(9000)
          end

          it 'does not reduce the amount below zero' do
            expect(discount.apply_to(Money.new(500))).to eq Money.new(0)
          end
        end

        context 'with a percentage discount' do
          let(:discount) { build_stubbed(:discount, :percentage, value_cents: 2000) }

          it 'applies the percentage to the amount' do
            expect(discount.apply_to(initial_amount)).to eq Money.new(8000)
          end
        end
      end

      context 'when the discount is not active' do
        let(:discount) { build_stubbed(:discount) }

        before do
          allow(discount).to receive(:active?).and_return(false)
        end

        it 'returns the original amount' do
          expect(discount.apply_to(initial_amount)).to eq initial_amount
        end
      end
    end

    describe '#increment_usage!' do
      let(:discount) { create(:discount, usage_count: 5) }

      it 'increments the usage count' do
        expect { discount.increment_usage! }.to change(discount, :usage_count).by(1)
      end
    end
  end
end
