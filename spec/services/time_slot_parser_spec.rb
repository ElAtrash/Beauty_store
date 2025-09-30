# frozen_string_literal: true

RSpec.describe TimeSlotParser do
  around do |example|
    Time.use_zone('UTC') { example.run }
  end

  describe '.parse_time_slot' do
    subject { described_class.parse_time_slot(time_slot_string) }

    context 'with valid time slot format' do
      let(:time_slot_string) { '9:00 AM - 12:00 PM' }

      it 'returns hash with start and end times' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_a(Time)
          expect(result[:end_time]).to be_a(Time)
          expect(result[:start_time].hour).to eq(9)
          expect(result[:start_time].min).to eq(0)
          expect(result[:end_time].hour).to eq(12)
          expect(result[:end_time].min).to eq(0)
        end
      end
    end

    context 'with PM times' do
      let(:time_slot_string) { '2:30 PM - 5:45 PM' }

      it 'correctly converts PM times to 24-hour format' do
        result = subject

        aggregate_failures do
          expect(result[:start_time].hour).to eq(14)
          expect(result[:start_time].min).to eq(30)
          expect(result[:end_time].hour).to eq(17)
          expect(result[:end_time].min).to eq(45)
        end
      end
    end

    context 'with 12 AM midnight' do
      let(:time_slot_string) { '12:00 AM - 2:00 AM' }

      it 'correctly handles midnight hour' do
        result = subject

        aggregate_failures do
          expect(result[:start_time].hour).to eq(0)
          expect(result[:start_time].min).to eq(0)
          expect(result[:end_time].hour).to eq(2)
          expect(result[:end_time].min).to eq(0)
        end
      end
    end

    context 'with 12 PM noon' do
      let(:time_slot_string) { '12:00 PM - 2:00 PM' }

      it 'correctly handles noon hour' do
        result = subject

        aggregate_failures do
          expect(result[:start_time].hour).to eq(12)
          expect(result[:start_time].min).to eq(0)
          expect(result[:end_time].hour).to eq(14)
          expect(result[:end_time].min).to eq(0)
        end
      end
    end

    context 'with mixed case AM/PM' do
      let(:time_slot_string) { '9:00 am - 12:00 pm' }

      it 'handles case-insensitive AM/PM' do
        result = subject

        aggregate_failures do
          expect(result[:start_time].hour).to eq(9)
          expect(result[:end_time].hour).to eq(12)
        end
      end
    end

    context 'with extra whitespace' do
      let(:time_slot_string) { '  9:00 AM  -  12:00 PM  ' }

      it 'handles whitespace correctly' do
        result = subject

        aggregate_failures do
          expect(result[:start_time].hour).to eq(9)
          expect(result[:end_time].hour).to eq(12)
        end
      end
    end

    context 'with invalid format' do
      let(:time_slot_string) { 'invalid format' }

      it 'returns nil values' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_nil
          expect(result[:end_time]).to be_nil
        end
      end
    end

    context 'with missing separator' do
      let(:time_slot_string) { '9:00 AM 12:00 PM' }

      it 'returns nil values' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_nil
          expect(result[:end_time]).to be_nil
        end
      end
    end

    context 'with nil input' do
      let(:time_slot_string) { nil }

      it 'returns nil values' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_nil
          expect(result[:end_time]).to be_nil
        end
      end
    end

    context 'with empty string' do
      let(:time_slot_string) { '' }

      it 'returns nil values' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_nil
          expect(result[:end_time]).to be_nil
        end
      end
    end

    context 'with invalid time format' do
      let(:time_slot_string) { '25:00 AM - 26:00 PM' }

      it 'returns nil values for invalid times' do
        result = subject

        aggregate_failures do
          expect(result[:start_time]).to be_nil
          expect(result[:end_time]).to be_nil
        end
      end
    end
  end

  describe '.parse_delivery_time' do
    let(:date) { Date.new(2024, 12, 25) }

    subject { described_class.parse_delivery_time(time_slot_string, date) }

    context 'with valid 24-hour time slot' do
      let(:time_slot_string) { '09:00-12:00' }

      it 'returns formatted delivery schedule string' do
        expected_string = 'Wednesday, Dec 25 - 09:00-12:00'
        expect(subject).to eq(expected_string)
      end
    end

    context 'with afternoon time slot' do
      let(:time_slot_string) { '12:00-15:00' }

      it 'correctly formats afternoon slot' do
        expected_string = 'Wednesday, Dec 25 - 12:00-15:00'
        expect(subject).to eq(expected_string)
      end
    end

    context 'with evening time slot' do
      let(:time_slot_string) { '18:00-21:00' }

      it 'correctly formats evening slot' do
        expected_string = 'Wednesday, Dec 25 - 18:00-21:00'
        expect(subject).to eq(expected_string)
      end
    end

    context 'with invalid time slot' do
      let(:time_slot_string) { '10:00-14:00' }

      it 'returns nil for invalid time slot' do
        expect(subject).to be_nil
      end
    end

    context 'with AM/PM format' do
      let(:time_slot_string) { '9:00 AM - 12:00 PM' }

      it 'returns nil for AM/PM format' do
        expect(subject).to be_nil
      end
    end

    context 'with invalid time slot' do
      let(:time_slot_string) { 'invalid' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'without date specified' do
      let(:time_slot_string) { '09:00-12:00' }

      it 'uses current date when no date provided' do
        result = described_class.parse_delivery_time(time_slot_string, nil)
        expect(result).to include(Date.current.strftime('%A, %b %d'))
        expect(result).to include('09:00-12:00')
      end
    end
  end

  describe 'instance methods' do
    let(:date) { Date.new(2024, 12, 25) }
    let(:parser) { described_class.new(time_slot_string, date) }

    describe '#parse' do
      context 'with valid time slot' do
        let(:time_slot_string) { '9:00 AM - 12:00 PM' }

        it 'returns parsed start and end times' do
          result = parser.parse

          aggregate_failures do
            expect(result[:start_time].hour).to eq(9)
            expect(result[:end_time].hour).to eq(12)
          end
        end
      end
    end

    describe '#parse_start_datetime' do
      context 'with valid time slot' do
        let(:time_slot_string) { '9:00 AM - 12:00 PM' }

        it 'returns start datetime on specified date' do
          result = parser.parse_start_datetime
          expected = Time.zone.parse('2024-12-25 09:00:00')
          expect(result).to eq(expected)
        end
      end

      context 'with invalid time slot' do
        let(:time_slot_string) { 'invalid' }

        it 'returns nil' do
          expect(parser.parse_start_datetime).to be_nil
        end
      end
    end
  end

  describe '.valid?' do
    subject { described_class.valid?(time_slot_string) }

    context 'with valid time slot formats' do
      [
        '9:00 AM - 12:00 PM',
        '9 AM - 12 PM',
        '12:00 AM - 2:00 AM',
        '12 PM - 2 PM',
        '1:30 PM - 5:45 PM',
        '  9:00 AM  -  12:00 PM  '
      ].each do |valid_format|
        context "with format '#{valid_format}'" do
          let(:time_slot_string) { valid_format }

          it 'returns true' do
            expect(subject).to be true
          end
        end
      end
    end

    context 'with invalid time slot formats' do
      [
        'invalid format',
        '9:00 AM 12:00 PM',  # missing separator
        '25:00 AM - 26:00 PM',  # invalid hours
        '9:60 AM - 12:00 PM',  # invalid minutes
        '0:00 AM - 12:00 PM',  # invalid hour (0)
        '13:00 AM - 12:00 PM',  # invalid hour (13)
        '',
        nil
      ].each do |invalid_format|
        context "with format '#{invalid_format}'" do
          let(:time_slot_string) { invalid_format }

          it 'returns false' do
            expect(subject).to be false
          end
        end
      end
    end
  end

  describe '.parse_datetime_range' do
    let(:date) { Date.new(2024, 12, 25) }

    subject { described_class.parse_datetime_range(time_slot_string, date) }

    context 'with valid time slot' do
      let(:time_slot_string) { '9:00 AM - 12:00 PM' }

      it 'returns hash with start and end datetimes' do
        result = subject

        aggregate_failures do
          expect(result[:start_datetime]).to eq(Time.zone.parse('2024-12-25 09:00:00'))
          expect(result[:end_datetime]).to eq(Time.zone.parse('2024-12-25 12:00:00'))
        end
      end
    end

    context 'with PM times' do
      let(:time_slot_string) { '2:30 PM - 5:45 PM' }

      it 'correctly converts PM times' do
        result = subject

        aggregate_failures do
          expect(result[:start_datetime]).to eq(Time.zone.parse('2024-12-25 14:30:00'))
          expect(result[:end_datetime]).to eq(Time.zone.parse('2024-12-25 17:45:00'))
        end
      end
    end

    context 'with midnight times' do
      let(:time_slot_string) { '12:00 AM - 2:00 AM' }

      it 'correctly handles midnight' do
        result = subject

        aggregate_failures do
          expect(result[:start_datetime]).to eq(Time.zone.parse('2024-12-25 00:00:00'))
          expect(result[:end_datetime]).to eq(Time.zone.parse('2024-12-25 02:00:00'))
        end
      end
    end

    context 'with invalid time slot' do
      let(:time_slot_string) { 'invalid' }

      it 'returns nil values' do
        result = subject

        aggregate_failures do
          expect(result[:start_datetime]).to be_nil
          expect(result[:end_datetime]).to be_nil
        end
      end
    end
  end

  describe 'enhanced regex pattern support' do
    describe 'times without minutes' do
      subject { described_class.parse_time_slot(time_slot_string) }

      context 'with "9 AM - 5 PM"' do
        let(:time_slot_string) { '9 AM - 5 PM' }

        it 'parses correctly with default minutes' do
          result = subject

          aggregate_failures do
            expect(result[:start_time].hour).to eq(9)
            expect(result[:start_time].min).to eq(0)
            expect(result[:end_time].hour).to eq(17)
            expect(result[:end_time].min).to eq(0)
          end
        end
      end

      context 'with mixed format "9 AM - 12:30 PM"' do
        let(:time_slot_string) { '9 AM - 12:30 PM' }

        it 'parses mixed format correctly' do
          result = subject

          aggregate_failures do
            expect(result[:start_time].hour).to eq(9)
            expect(result[:start_time].min).to eq(0)
            expect(result[:end_time].hour).to eq(12)
            expect(result[:end_time].min).to eq(30)
          end
        end
      end
    end

    describe 'case insensitive AM/PM' do
      [
        { input: '9:00 am - 12:00 pm', desc: 'lowercase' },
        { input: '9:00 Am - 12:00 Pm', desc: 'mixed case' },
        { input: '9:00 AM - 12:00 PM', desc: 'uppercase' }
      ].each do |test_case|
        context "with #{test_case[:desc]} AM/PM" do
          let(:time_slot_string) { test_case[:input] }

          it 'parses correctly' do
            result = described_class.parse_time_slot(time_slot_string)

            aggregate_failures do
              expect(result[:start_time].hour).to eq(9)
              expect(result[:end_time].hour).to eq(12)
            end
          end
        end
      end
    end
  end

  describe 'edge cases' do
    context 'with different separators' do
      [ ' - ', '-', ' -', '- ' ].each do |separator|
        context "with separator '#{separator}'" do
          let(:time_slot_string) { "9:00 AM#{separator}12:00 PM" }

          it 'parses correctly' do
            result = described_class.parse_time_slot(time_slot_string)

            aggregate_failures do
              expect(result[:start_time].hour).to eq(9)
              expect(result[:end_time].hour).to eq(12)
            end
          end
        end
      end
    end

    context 'with single digit hours' do
      let(:time_slot_string) { '9:00 AM - 5:00 PM' }

      it 'handles single digit hours correctly' do
        result = described_class.parse_time_slot(time_slot_string)

        aggregate_failures do
          expect(result[:start_time].hour).to eq(9)
          expect(result[:end_time].hour).to eq(17)
        end
      end
    end

    context 'with double digit hours' do
      let(:time_slot_string) { '10:30 AM - 11:45 PM' }

      it 'handles double digit hours correctly' do
        result = described_class.parse_time_slot(time_slot_string)

        aggregate_failures do
          expect(result[:start_time].hour).to eq(10)
          expect(result[:start_time].min).to eq(30)
          expect(result[:end_time].hour).to eq(23)
          expect(result[:end_time].min).to eq(45)
        end
      end
    end

    context 'with object reuse across different dates' do
      let(:parser) { described_class.new('9:00 AM - 12:00 PM') }
      let(:date1) { Date.new(2024, 6, 15) }
      let(:date2) { Date.new(2024, 12, 25) }

      it 'maintains consistent behavior when reused' do
        # Parse with first date
        parser.instance_variable_set(:@date, date1)
        result1 = parser.parse_start_datetime

        # Parse with second date
        parser.instance_variable_set(:@date, date2)
        result2 = parser.parse_start_datetime

        aggregate_failures do
          expect(result1.to_date).to eq(date1)
          expect(result2.to_date).to eq(date2)
          expect(result1.hour).to eq(9)
          expect(result2.hour).to eq(9)
        end
      end
    end

    context 'with boundary minute values' do
      [
        { input: '9:00 AM - 12:59 PM', desc: 'minute 59' },
        { input: '9:01 AM - 12:00 PM', desc: 'minute 01' }
      ].each do |test_case|
        context "with #{test_case[:desc]}" do
          let(:time_slot_string) { test_case[:input] }

          it 'handles boundary minutes correctly' do
            result = described_class.parse_time_slot(time_slot_string)

            aggregate_failures do
              expect(result[:start_time]).not_to be_nil
              expect(result[:end_time]).not_to be_nil
            end
          end
        end
      end
    end

    context 'with invalid boundary values' do
      [
        { input: '9:60 AM - 12:00 PM', desc: 'minute 60' },
        { input: '0:00 AM - 12:00 PM', desc: 'hour 0' },
        { input: '13:00 AM - 12:00 PM', desc: 'hour 13 with AM' }
      ].each do |test_case|
        context "with #{test_case[:desc]}" do
          let(:time_slot_string) { test_case[:input] }

          it 'rejects invalid boundary values' do
            result = described_class.parse_time_slot(time_slot_string)

            aggregate_failures do
              expect(result[:start_time]).to be_nil
              expect(result[:end_time]).to be_nil
            end
          end
        end
      end
    end

    context 'timezone consistency' do
      around do |example|
        Time.use_zone('America/New_York') { example.run }
      end

      let(:time_slot_string) { '9:00 AM - 12:00 PM' }
      let(:date) { Date.new(2024, 7, 15) }  # Summer date when EDT is active

      it 'maintains timezone consistency during EDT' do
        result = described_class.parse_datetime_range(time_slot_string, date)

        aggregate_failures do
          expect(result[:start_datetime].zone).to eq('EDT')
          expect(result[:end_datetime].zone).to eq('EDT')
          expect(result[:start_datetime].hour).to eq(9)
          expect(result[:end_datetime].hour).to eq(12)
        end
      end
    end
  end

  describe '.parse_delivery_datetime' do
    let(:date) { Date.new(2024, 12, 25) }

    subject { described_class.parse_delivery_datetime(time_slot_string, date) }

    context 'with valid time slot' do
      let(:time_slot_string) { '9:00 AM - 12:00 PM' }

      it 'returns datetime for start time on specified date' do
        expected_datetime = Time.zone.parse('2024-12-25 09:00:00')
        expect(subject).to eq(expected_datetime)
      end
    end

    context 'with PM time' do
      let(:time_slot_string) { '2:30 PM - 5:00 PM' }

      it 'correctly handles PM times' do
        expected_datetime = Time.zone.parse('2024-12-25 14:30:00')
        expect(subject).to eq(expected_datetime)
      end
    end

    context 'with midnight' do
      let(:time_slot_string) { '12:00 AM - 2:00 AM' }

      it 'correctly handles midnight' do
        expected_datetime = Time.zone.parse('2024-12-25 00:00:00')
        expect(subject).to eq(expected_datetime)
      end
    end

    context 'with noon' do
      let(:time_slot_string) { '12:00 PM - 2:00 PM' }

      it 'correctly handles noon' do
        expected_datetime = Time.zone.parse('2024-12-25 12:00:00')
        expect(subject).to eq(expected_datetime)
      end
    end

    context 'with invalid time slot' do
      let(:time_slot_string) { 'invalid' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.valid_delivery_time_slot?' do
    context 'with valid time slots' do
      it 'returns true for allowed morning slot' do
        expect(described_class.valid_delivery_time_slot?('09:00-12:00')).to be true
      end

      it 'returns true for allowed afternoon slot' do
        expect(described_class.valid_delivery_time_slot?('12:00-15:00')).to be true
      end

      it 'returns true for allowed late afternoon slot' do
        expect(described_class.valid_delivery_time_slot?('15:00-18:00')).to be true
      end

      it 'returns true for allowed evening slot' do
        expect(described_class.valid_delivery_time_slot?('18:00-21:00')).to be true
      end
    end

    context 'with invalid time slots' do
      it 'returns false for invalid time slot' do
        expect(described_class.valid_delivery_time_slot?('10:00-14:00')).to be false
      end

      it 'returns false for AM/PM format' do
        expect(described_class.valid_delivery_time_slot?('9:00 AM - 12:00 PM')).to be false
      end

      it 'returns false for generic terms' do
        expect(described_class.valid_delivery_time_slot?('morning')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid_delivery_time_slot?(nil)).to be false
      end
    end
  end
end
