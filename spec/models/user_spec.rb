# frozen_string_literal: true

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  subject(:user) { build(:user) }

  describe 'validations' do
    context 'with email_address' do
      it 'accepts valid email formats' do
        valid_emails = [ 'user@example.com', 'test.email+tag@domain.co.uk', 'user123@test-domain.org' ]

        aggregate_failures 'valid email formats' do
          valid_emails.each do |email|
            user.email_address = email
            expect(user).to be_valid, "#{email} should be valid"
          end
        end
      end

      it 'rejects invalid email formats' do
        invalid_emails = [ 'invalid', '@domain.com', 'user@', 'user space@domain.com' ]

        aggregate_failures 'invalid email formats' do
          invalid_emails.each do |email|
            user.email_address = email
            expect(user).to be_invalid, "#{email} should be invalid"
          end
        end
      end
    end

    context 'with phone_number' do
      it 'accepts valid phone formats' do
        valid_phones = [ '+96171123456', '03-123456', '(03) 123 456', '03 123 456' ]

        aggregate_failures 'valid phone formats' do
          valid_phones.each do |phone|
            user.phone_number = phone
            expect(user).to be_valid, "#{phone} should be valid"
          end
        end
      end

      it 'rejects invalid phone formats' do
        invalid_phones = [ 'abc123', '123abc', 'phone' ]

        aggregate_failures 'invalid phone formats' do
          invalid_phones.each do |phone|
            user.phone_number = phone
            expect(user).to be_invalid, "#{phone} should be invalid"
          end
        end
      end

      it 'allows blank phone numbers' do
        user.phone_number = nil
        expect(user).to be_valid
      end
    end

    context 'with preferred_language' do
      let(:allowed_languages) { [ 'en', 'ar', nil ] }
      let(:invalid_languages) { %w[fr de it] }

      it "allows valid languages" do
        allowed_languages.each do |lang|
          is_expected.to allow_value(lang).for(:preferred_language)
        end
      end

      it "rejects invalid languages" do
        invalid_languages.each do |lang|
          expect { user.preferred_language = lang }.to raise_error(ArgumentError, "'#{lang}' is not a valid preferred_language")
        end
      end
    end

    context 'with governorate' do
      it 'accepts valid Lebanese governorates' do
        aggregate_failures 'valid governorates' do
          described_class::LEBANESE_GOVERNORATES.each do |governorate|
            user.governorate = governorate
            expect(user).to be_valid, "#{governorate} should be valid"
          end
        end
      end

      it 'rejects invalid governorates' do
        user.governorate = 'Invalid Governorate'
        expect(user).to be_invalid
      end

      it 'allows blank governorates' do
        user.governorate = nil
        expect(user).to be_valid
      end
    end

    context 'with names and city' do
      it { is_expected.to validate_length_of(:first_name).is_at_least(2).is_at_most(50) }
      it { is_expected.to validate_length_of(:last_name).is_at_least(2).is_at_most(50) }
      it { is_expected.to validate_length_of(:city).is_at_most(100) }
    end

    context 'with date_of_birth' do
      it 'accepts dates in the past' do
        user.date_of_birth = 25.years.ago.to_date
        expect(user).to be_valid
      end

      it 'rejects future dates' do
        user.date_of_birth = 1.day.from_now.to_date
        expect(user).to be_invalid
      end

      it 'allows blank dates' do
        user.date_of_birth = nil
        expect(user).to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.by_language' do
      let!(:arabic_user) { create(:user, :arabic_speaker) }
      let!(:english_user) { create(:user, :english_speaker) }

      it 'returns only users with the specified language' do
        expect(described_class.by_language('ar')).to contain_exactly(arabic_user)
      end
    end

    describe '.by_governorate' do
      let!(:beirut_user) { create(:user, governorate: 'Beirut') }
      let!(:north_user) { create(:user, governorate: 'North Lebanon') }

      it 'returns only users with the specified governorate' do
        expect(described_class.by_governorate('Beirut')).to contain_exactly(beirut_user)
      end
    end

    describe '.admins' do
      let!(:admin_user) { create(:user, :admin) }
      let!(:non_admin_user) { create(:user) }

      it 'returns only admin users' do
        expect(described_class.admins).to contain_exactly(admin_user)
      end
    end

    describe '.adults' do
      let!(:adult_user) { create(:user, date_of_birth: 25.years.ago) }
      let!(:minor_user) { create(:user, date_of_birth: 15.years.ago) }

      it 'returns users 18 years or older' do
        expect(described_class.adults).to contain_exactly(adult_user)
      end
    end
  end

  describe 'instance methods' do
    describe '#display_name' do
      it 'returns full name when full_name is present' do
        user.first_name = 'John'
        user.last_name = 'Doe'
        expect(user.display_name).to eq('John Doe')
      end

      it 'returns email when full name is blank' do
        user.first_name = nil
        user.last_name = nil
        expect(user.display_name).to eq(user.email_address)
      end
    end

    describe '#rtl_language?' do
      it 'delegates to preferred_language_ar?' do
        allow(user).to receive(:preferred_language_ar?).and_return(true)
        expect(user).to be_rtl_language
      end
    end

    describe '#age' do
      it 'calculates age correctly' do
        user.date_of_birth = Date.new(1998, 6, 15)
        travel_to Date.new(2024, 6, 16) do
          expect(user.age).to eq(26)
        end
      end

      it 'returns nil when date_of_birth is blank' do
        user.date_of_birth = nil
        expect(user.age).to be_nil
      end

      it 'handles leap years correctly' do
        user.date_of_birth = Date.new(1996, 2, 29)
        travel_to Date.new(2024, 3, 1) do
          expect(user.age).to eq(28)
        end
      end
    end

    describe '#full_address' do
      it 'combines city and governorate' do
        user.city = 'Zahle'
        user.governorate = 'Bekaa'
        expect(user.full_address).to eq('Zahle, Bekaa')
      end

      it 'handles missing city' do
        user.city = nil
        user.governorate = 'South Lebanon'
        expect(user.full_address).to eq('South Lebanon')
      end

      it 'handles missing governorate' do
        user.city = 'Baalbek'
        user.governorate = nil
        expect(user.full_address).to eq('Baalbek')
      end

      it 'returns empty string when both are missing' do
        user.city = nil
        user.governorate = nil
        expect(user.full_address).to eq('')
      end
    end
  end

  describe 'attribute normalization' do
    describe 'email_address normalization' do
      it 'strips whitespace and converts to lowercase' do
        user.email_address = '  USER@EXAMPLE.COM  '
        user.valid?
        expect(user.email_address).to eq('user@example.com')
      end
    end

    describe 'phone_number normalization' do
      it 'removes spaces and dashes' do
        user.phone_number = '+961 (71) 123-456'
        user.valid?
        expect(user.phone_number).to eq('+96171123456')
      end
    end

    describe 'name normalization' do
      it 'strips whitespace and titleizes names' do
        user.first_name = '  john  '
        user.last_name = '  doe  '
        user.valid?

        aggregate_failures 'name normalization' do
          expect(user.first_name).to eq('John')
          expect(user.last_name).to eq('Doe')
        end
      end
    end

    describe 'city normalization' do
      it 'strips whitespace and titleizes city' do
        user.city = '  beirut  '
        user.valid?
        expect(user.city).to eq('Beirut')
      end
    end
  end
end
