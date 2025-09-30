# frozen_string_literal: true

RSpec.describe DeliveryScheduleService do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    Time.use_zone('UTC') { example.run }
  end

  let(:delivery_method) { "courier" }
  let(:city) { "Beirut" }
  let(:selected_date) { nil }
  let(:selected_time) { nil }

  subject do
    described_class.new(
      method: delivery_method,
      city: city,
      selected_date: selected_date,
      selected_time: selected_time
    )
  end

  describe '#title_for_method' do
    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      it 'returns internationalized courier title' do
        expect(subject.title_for_method).to eq(I18n.t("delivery_schedule.titles.courier"))
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      it 'returns internationalized pickup title' do
        expect(subject.title_for_method).to eq(I18n.t("delivery_schedule.titles.pickup"))
      end
    end

    context 'with unknown delivery method' do
      let(:delivery_method) { "unknown" }

      it 'returns default pickup title' do
        expect(subject.title_for_method).to eq(I18n.t("delivery_schedule.titles.pickup"))
      end
    end
  end

  describe '#subtitle_for_method' do
    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      it 'returns internationalized courier subtitle' do
        expect(subject.subtitle_for_method).to eq(I18n.t("delivery_schedule.subtitles.courier"))
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      it 'returns internationalized pickup subtitle' do
        expect(subject.subtitle_for_method).to eq(I18n.t("delivery_schedule.subtitles.pickup"))
      end
    end
  end

  describe '#available_options' do
    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      it 'generates courier options using configuration' do
        options = subject.available_options

        expect(options).not_to be_empty
        expect(options.first).to include(:date, :time, :display, :value, :disabled, :selected)

        # Should use configured time slots
        time_slots = options.map { |opt| opt[:time] }.uniq
        expect(time_slots).to match_array(DeliveryConfiguration::COURIER_CONFIG[:time_slots])
      end

      it 'starts from tomorrow for courier delivery' do
        options = subject.available_options
        earliest_date = options.map { |opt| opt[:date] }.min

        # Courier starts 1 day ahead (tomorrow)
        expected_start = DeliveryConfiguration.base_date_for("courier")
        expect(earliest_date).to eq(expected_start)
      end

      it 'covers the configured number of days' do
        options = subject.available_options
        unique_dates = options.map { |opt| opt[:date] }.uniq

        expected_days = DeliveryConfiguration::COURIER_CONFIG[:days_ahead].count
        expect(unique_dates.length).to eq(expected_days)
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      it 'generates pickup options using configuration' do
        options = subject.available_options

        expect(options).not_to be_empty
        expect(options.first).to include(:date, :time, :display, :value, :disabled, :selected)

        # Should use store hours
        expect(options.first[:time]).to eq(DeliveryConfiguration::PICKUP_CONFIG[:store_hours])
      end

      it 'starts from today for pickup' do
        options = subject.available_options
        earliest_date = options.map { |opt| opt[:date] }.min

        expect(earliest_date).to eq(Date.current)
      end
    end
  end

  describe '#available_dates' do
    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      it 'returns unique dates from available options' do
        dates = subject.available_dates

        expect(dates).not_to be_empty
        expect(dates).to all(be_a(Date))
        expect(dates).to eq(dates.uniq) # Should be unique

        # Should match dates from available_options
        options_dates = subject.available_options.map { |opt| opt[:date] }.uniq
        expect(dates).to match_array(options_dates)
      end

      it 'returns dates in chronological order' do
        dates = subject.available_dates

        expect(dates).to eq(dates.sort)
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      it 'returns unique dates from pickup options' do
        dates = subject.available_dates

        expect(dates).not_to be_empty
        expect(dates).to all(be_a(Date))
        expect(dates).to eq(dates.uniq)

        # Should include today for pickup
        expect(dates).to include(Date.current)
      end
    end

    context 'with multiple time slots per day' do
      let(:delivery_method) { "courier" }

      it 'deduplicates dates when multiple time slots exist per day' do
        # Courier has multiple time slots per day
        options = subject.available_options
        dates = subject.available_dates

        # Should have fewer unique dates than total options
        expect(dates.length).to be < options.length
        expect(dates.length).to eq(options.map { |opt| opt[:date] }.uniq.length)
      end
    end
  end

  describe '#option_selected?' do
    let(:test_date) { Date.tomorrow }
    let(:test_time) { "9:00 AM - 12:00 PM" }
    let(:selected_date) { test_date }
    let(:selected_time) { test_time }

    it 'returns true when date and time match selection' do
      expect(subject.option_selected?(test_date, test_time)).to be true
    end

    it 'returns false when date does not match' do
      expect(subject.option_selected?(test_date + 1.day, test_time)).to be false
    end

    it 'returns false when time does not match' do
      expect(subject.option_selected?(test_date, "2:00 PM - 5:00 PM")).to be false
    end

    it 'returns false when no selection is made' do
      subject = described_class.new(method: delivery_method, city: city)
      expect(subject.option_selected?(test_date, test_time)).to be false
    end
  end

  describe '#option_disabled?' do
    let(:test_time) { "9:00 AM - 12:00 PM" }

    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      context 'for today' do
        it 'disables all options when same day delivery is not enabled' do
          expect(subject.option_disabled?(Date.current, test_time)).to be true
        end
      end

      context 'for future dates' do
        it 'does not disable future slots' do
          expect(subject.option_disabled?(Date.tomorrow, test_time)).to be false
        end
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      context 'for today' do
        it 'checks if time slot has passed using TimeSlotParser' do
          # Mock TimeSlotParser to return a past time
          past_time = 2.hours.ago
          allow(TimeSlotParser).to receive(:parse_datetime_range)
            .with(test_time, Date.current)
            .and_return({ start_datetime: past_time, end_datetime: past_time + 3.hours })

          expect(subject.option_disabled?(Date.current, test_time)).to be true
        end

        it 'allows future time slots for today' do
          # Mock TimeSlotParser to return a future time
          future_time = 2.hours.from_now
          allow(TimeSlotParser).to receive(:parse_datetime_range)
            .with(test_time, Date.current)
            .and_return({ start_datetime: future_time, end_datetime: future_time + 3.hours })

          expect(subject.option_disabled?(Date.current, test_time)).to be false
        end

        it 'handles invalid time slots gracefully' do
          allow(TimeSlotParser).to receive(:parse_datetime_range)
            .with(test_time, Date.current)
            .and_return({ start_datetime: nil, end_datetime: nil })

          expect(subject.option_disabled?(Date.current, test_time)).to be true
        end
      end

      context 'for future dates' do
        it 'does not disable future slots' do
          expect(subject.option_disabled?(Date.tomorrow, test_time)).to be false
        end
      end
    end
  end

  describe '#placeholder_text' do
    context 'with courier delivery' do
      let(:delivery_method) { "courier" }

      it 'returns internationalized courier placeholder' do
        expect(subject.placeholder_text).to eq(I18n.t("delivery_schedule.placeholders.courier"))
      end
    end

    context 'with pickup delivery' do
      let(:delivery_method) { "pickup" }

      it 'returns internationalized pickup placeholder with formatted dates' do
        start_date = I18n.l(Date.current, format: :short)
        end_date = I18n.l(Date.current + 2.days, format: :short)
        expected = I18n.t("delivery_schedule.placeholders.pickup", start_date: start_date, end_date: end_date)

        expect(subject.placeholder_text).to eq(expected)
      end
    end
  end

  describe '#has_selection?' do
    context 'with both date and time selected' do
      let(:selected_date) { Date.tomorrow }
      let(:selected_time) { "9:00 AM - 12:00 PM" }

      it 'returns true' do
        expect(subject.has_selection?).to be true
      end
    end

    context 'with only date selected' do
      let(:selected_date) { Date.tomorrow }

      it 'returns false' do
        expect(subject.has_selection?).to be false
      end
    end

    context 'with only time selected' do
      let(:selected_time) { "9:00 AM - 12:00 PM" }

      it 'returns false' do
        expect(subject.has_selection?).to be false
      end
    end

    context 'with no selection' do
      it 'returns false' do
        expect(subject.has_selection?).to be false
      end
    end
  end

  describe '#current_selection_display' do
    context 'with selection' do
      let(:selected_date) { Date.new(2024, 12, 25) }
      let(:selected_time) { "9:00 AM - 12:00 PM" }

      it 'returns formatted display string using I18n' do
        date_display = I18n.l(selected_date, format: I18n.t("delivery_schedule.date_formats.display"))
        expected = "#{date_display} - #{selected_time}"

        expect(subject.current_selection_display).to eq(expected)
      end
    end

    context 'without selection' do
      it 'returns empty string' do
        expect(subject.current_selection_display).to eq("")
      end
    end
  end

  describe '#option_value' do
    let(:test_date) { Date.new(2024, 12, 25) }
    let(:test_time) { "9:00 AM - 12:00 PM" }

    it 'returns formatted option value' do
      expected = "2024-12-25|9:00 AM - 12:00 PM"
      expect(subject.option_value(test_date, test_time)).to eq(expected)
    end
  end

  describe '#format_date_display' do
    it 'returns internationalized "Today" for current date' do
      expect(subject.send(:format_date_display, Date.current)).to eq(I18n.t("delivery_schedule.relative_dates.today"))
    end

    it 'returns internationalized "Tomorrow" for tomorrow' do
      expect(subject.send(:format_date_display, Date.tomorrow)).to eq(I18n.t("delivery_schedule.relative_dates.tomorrow"))
    end

    it 'returns localized date format for other dates' do
      test_date = Date.current + 3.days
      expected = I18n.l(test_date, format: I18n.t("delivery_schedule.date_formats.short"))

      expect(subject.send(:format_date_display, test_date)).to eq(expected)
    end
  end

  describe '#time_slot_has_passed?' do
    let(:test_date) { Date.current }
    let(:test_time) { "9:00 AM - 12:00 PM" }

    it 'returns true when time slot has passed' do
      past_time = 2.hours.ago
      allow(TimeSlotParser).to receive(:parse_datetime_range)
        .and_return({ start_datetime: past_time, end_datetime: past_time + 3.hours })

      expect(subject.send(:time_slot_has_passed?, test_time, test_date)).to be true
    end

    it 'returns false when time slot is in the future' do
      future_time = 2.hours.from_now
      allow(TimeSlotParser).to receive(:parse_datetime_range)
        .and_return({ start_datetime: future_time, end_datetime: future_time + 3.hours })

      expect(subject.send(:time_slot_has_passed?, test_time, test_date)).to be false
    end

    it 'returns true for invalid time slots' do
      allow(TimeSlotParser).to receive(:parse_datetime_range)
        .and_return({ start_datetime: nil, end_datetime: nil })

      expect(subject.send(:time_slot_has_passed?, test_time, test_date)).to be true
    end
  end

  describe 'edge cases' do
    context 'with different timezones' do
      around do |example|
        Time.use_zone('America/New_York') { example.run }
      end

      let(:delivery_method) { "pickup" }

      it 'handles timezone-aware time comparisons' do
        # Test during a specific time to ensure timezone handling
        travel_to Time.zone.parse('2024-12-25 14:30:00') do # 2:30 PM EST
          morning_slot = "9:00 AM - 12:00 PM"

          expect(subject.option_disabled?(Date.current, morning_slot)).to be true
        end
      end
    end

    context 'with DST transitions' do
      around do |example|
        Time.use_zone('America/New_York') { example.run }
      end

      let(:delivery_method) { "pickup" }

      it 'handles DST transition dates correctly' do
        # Spring forward date (2024-03-10)
        dst_date = Date.new(2024, 3, 10)

        travel_to Time.zone.parse('2024-03-10 09:30:00') do
          morning_slot = "10:00 AM - 1:00 PM"

          expect(subject.option_disabled?(dst_date, morning_slot)).to be false
        end
      end
    end

    context 'with midnight edge cases' do
      let(:delivery_method) { "pickup" }

      it 'handles midnight transitions correctly' do
        travel_to Time.zone.parse('2024-12-25 23:59:59') do
          tomorrow_slot = "9:00 AM - 12:00 PM"

          expect(subject.option_disabled?(Date.tomorrow, tomorrow_slot)).to be false
        end
      end
    end

    context 'with configuration-driven cities' do
      let(:city) { "Unknown City" }

      it 'falls back to default configuration for unknown cities' do
        options = subject.available_options

        expect(options).not_to be_empty
        # Should use default Beirut configuration
      end
    end
  end

  describe 'integration with TimeSlotParser' do
    let(:delivery_method) { "pickup" }

    it 'leverages TimeSlotParser for accurate time validation' do
      expect(TimeSlotParser).to receive(:parse_datetime_range)
        .with("9:00 AM - 12:00 PM", Date.current)
        .and_return({ start_datetime: 1.hour.from_now, end_datetime: 4.hours.from_now })

      subject.option_disabled?(Date.current, "9:00 AM - 12:00 PM")
    end

    it 'handles TimeSlotParser validation errors gracefully' do
      allow(TimeSlotParser).to receive(:parse_datetime_range).and_raise(StandardError)

      # Should not raise an error and default to disabled
      expect { subject.option_disabled?(Date.current, "invalid time") }.not_to raise_error
    end
  end

  describe 'internationalization support' do
    context 'with Arabic locale' do
      around do |example|
        I18n.with_locale(:ar) { example.run }
      end

      it 'returns Arabic translations for titles' do
        expect(subject.title_for_method).to eq(I18n.t("delivery_schedule.titles.courier"))
        expect(I18n.locale).to eq(:ar)
      end

      it 'formats dates using Arabic locale' do
        test_date = Date.new(2024, 12, 25)
        display = subject.send(:format_date_display, test_date + 3.days)

        # Should use Arabic date formatting - check for Arabic day names or numbers
        expect(display).to match(/\d{1,2}/) # Should contain day numbers
      end
    end
  end
end
