# frozen_string_literal: true

class BrandsService
  class BrandServiceError < StandardError; end

  ALPHABET = ("A".."Z").to_a + [ "0-9" ]

  def initialize(letter: nil, search: nil)
    @letter = letter
    @search = search&.strip
    @letter_counts = nil
  end

  def alphabet_navigation
    Rails.cache.fetch("brands_alphabet_navigation", expires_in: 1.hour) do
      ALPHABET.map do |char|
        {
          letter: char,
          url: brands_path(letter: char.downcase),
          active: active?(char),
          count: brand_count_for_letter(char)
        }
      end
    end
  end

  def brands_by_letter
    return search_brands if searching?
    return {} unless @letter

    begin
      if @letter == "0-9"
        numeric_brands
      else
        letter_brands
      end
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "BrandsService error: #{e.message}"
      raise BrandServiceError, "Unable to fetch brands"
    end
  end

  def has_brands?
    brands_by_letter.any?
  rescue BrandServiceError
    false
  end

  def searching?
    @search.present? && @search.length >= 2
  end

  def selected_letter
    @letter
  end

  private

  attr_reader :letter

  def active?(char)
    return false unless @letter

    if char == "0-9"
      @letter == "0-9"
    else
      @letter.upcase == char
    end
  end

  def brand_count_for_letter(char)
    letter_counts[char] || 0
  end

  def letter_counts
    @letter_counts ||= calculate_letter_counts
  end

  def calculate_letter_counts
    counts = Brand.connection.select_all("
      SELECT
        CASE
          WHEN name ~ '^[0-9]' THEN '0-9'
          ELSE UPPER(LEFT(name, 1))
        END as letter_group,
        COUNT(*) as brand_count
      FROM brands
      GROUP BY letter_group
    ").to_a.each_with_object({}) do |row, hash|
      hash[row["letter_group"]] = row["brand_count"].to_i
    end

    ALPHABET.each_with_object({}) do |char, hash|
      hash[char] = counts[char] || 0
    end
  end

  def numeric_brands
    brands = Brand.where("name ~ ?", "^[0-9]")
                  .order(:name)

    { "0-9" => brands }
  end

  def letter_brands
    brands = Brand.where("name ILIKE ?", "#{@letter}%")
                  .order(:name)

    { @letter.upcase => brands }
  end

  def search_brands
    brands = Brand.where(
      "name ILIKE ? OR description ILIKE ?",
      "%#{@search}%", "%#{@search}%"
    ).order(:name)

    { "Search Results" => brands }
  end

  def brands_path(letter:)
    Rails.application.routes.url_helpers.brands_path(letter: letter)
  end
end
