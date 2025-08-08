# frozen_string_literal: true

class FilterUrlBuilder
  # Parameter mappings for clean URLs
  CLEAN_PARAM_MAPPINGS = {
    "product_types" => "type",
    "skin_types" => "skin",
    "brands" => "brand",
    "colors" => "color",
    "sizes" => "size"
  }.freeze

  REVERSE_PARAM_MAPPINGS = CLEAN_PARAM_MAPPINGS.invert.freeze

  def initialize(base_url:, current_params: {})
    @base_url = base_url
    @current_params = current_params.with_indifferent_access
  end

  # Build clean URL from filter hash (compatible with JavaScript usage)
  def build_url_from_filters(filters)
    url = URI.parse(@base_url)
    params = URLSearchParams.new

    filters.each do |key, value|
      case key.to_s
      when "price_range"
        add_price_range_param(params, value) if value.is_a?(Hash)
      when "in_stock"
        add_in_stock_param(params, value) if value
      else
        add_generic_param(params, key.to_s, value)
      end
    end

    # Preserve additional parameters
    preserve_additional_params(params)

    url.query = params.to_s
    url.to_s
  end

  # Parse clean URL parameters back to filter format (for JavaScript usage)
  def parse_url_to_filters(url_string = nil)
    url = url_string ? URI.parse(url_string) : URI.parse(@base_url)
    return {} unless url.query

    filters = {}
    params = URLSearchParams.new(url.query)

    params.each do |key, value|
      case key
      when "price"
        parse_price_range(filters, value)
      when "stock"
        parse_in_stock(filters, value)
      else
        parse_generic_param(filters, key, value)
      end
    end

    filters
  end

  # Build URL with additional parameters (for server-side usage)
  def build_url_with_params(**additional_params)
    url = URI.parse(@base_url)
    query_params = @current_params.dup

    additional_params.each do |key, value|
      if value.present?
        query_params[key] = value
      else
        query_params.delete(key)
      end
    end

    url.query = query_params.to_query if query_params.any?
    url.to_s
  end

  private

  def add_price_range_param(params, price_range)
    return unless price_range[:min] && price_range[:max]

    params.set("price", "#{price_range[:min]}-#{price_range[:max]}")
  end

  def add_in_stock_param(params, value)
    params.set("stock", "1") if value.to_s == "true"
  end

  def add_generic_param(params, key, value)
    clean_key = CLEAN_PARAM_MAPPINGS[key] || key

    case value
    when Array
      params.set(clean_key, value.join(",")) if value.any?
    when String, Integer, Float
      params.set(clean_key, value.to_s) if value.present?
    end
  end

  def parse_price_range(filters, value)
    min, max = value.split("-", 2)
    filters[:price_range] = { min: min, max: max } if min && max
  end

  def parse_in_stock(filters, value)
    filters[:in_stock] = "true" if value == "1"
  end

  def parse_generic_param(filters, key, value)
    filter_key = REVERSE_PARAM_MAPPINGS[key] || key

    # Check if this looks like an array parameter (contains commas)
    if value.include?(",")
      filters[filter_key.to_sym] = value.split(",").map(&:strip).reject(&:blank?)
    else
      filters[filter_key.to_sym] = value
    end
  end

  def preserve_additional_params(params)
    # Preserve sort parameter
    params.set("sort_by", @current_params[:sort_by]) if @current_params[:sort_by].present?

    # Preserve other non-filter parameters like query, page, etc.
    preserved_keys = %w[query q search page per_page]
    preserved_keys.each do |key|
      params.set(key, @current_params[key]) if @current_params[key].present?
    end
  end

  # Simple URLSearchParams implementation for Ruby (similar to JavaScript)
  class URLSearchParams
    def initialize(query_string = nil)
      @params = {}
      parse_query_string(query_string) if query_string
    end

    def set(key, value)
      @params[key.to_s] = value.to_s
    end

    def get(key)
      @params[key.to_s]
    end

    def each(&block)
      @params.each(&block)
    end

    def to_s
      @params.map { |k, v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    end

    private

    def parse_query_string(query_string)
      query_string.split("&").each do |pair|
        key, value = pair.split("=", 2)
        next unless key && value

        @params[CGI.unescape(key)] = CGI.unescape(value)
      end
    end
  end
end
