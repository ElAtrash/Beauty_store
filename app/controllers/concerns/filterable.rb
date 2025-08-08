# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  included do
    class_attribute :_filterable_config, default: {}
  end

  class_methods do
    # Configure filterable behavior for the controller
    # @param route_helper [Symbol] The route helper method to use (e.g., :brand_path, :products_path)
    # @param additional_params [Array<Symbol>] Additional params to preserve in URLs (e.g., [:query])
    # @param available_filters [Array<Symbol>] Which filters are available (:all or specific list)
    # @param default_sort [String] Default sorting option
    def filterable_config(**options)
      self._filterable_config = {
        route_helper: options[:route_helper],
        additional_params: options.fetch(:additional_params, []),
        available_filters: options.fetch(:available_filters, :all),
        default_sort: options.fetch(:default_sort, "popularity")
      }.freeze
    end
  end

  private

  # Normalize filter parameters from both clean URL params and legacy filters[...] params
  def normalized_filter_params
    clean_params = extract_clean_params
    legacy_params = extract_legacy_params

    # Merge with clean params taking precedence
    legacy_params.merge(clean_params)
  end

  # Extract clean URL parameters (e.g., price=8-46, stock=1, type=lipstick,foundation)
  def extract_clean_params
    filters = {}

    # Handle clean price parameter: price=8-46, price=8-, or price=-46
    if params[:price].present?
      min, max = params[:price].split("-", 2)
      filters[:price_range] = {}
      filters[:price_range][:min] = min if min.present?
      filters[:price_range][:max] = max if max.present?
      filters.delete(:price_range) if filters[:price_range].empty?
    end

    # Handle clean in-stock parameter: stock=1
    if params[:stock] == "1"
      filters[:in_stock] = true
    end

    # Handle clean array parameters
    clean_param_mappings = {
      type: :product_types,
      skin: :skin_types,
      brand: :brands,
      color: :colors,
      size: :sizes
    }

    clean_param_mappings.each do |clean_key, filter_key|
      if params[clean_key].present? && filter_available?(filter_key)
        filters[filter_key] = params[clean_key].split(",").map(&:strip).reject(&:blank?)
      end
    end

    filters
  end

  # Extract legacy filters[...] parameters for backward compatibility
  def extract_legacy_params
    permitted_filters = [ :in_stock, price_range: [ :min, :max ] ]

    # Add array filters that are available for this controller
    [ :brands, :product_types, :skin_types, :colors, :sizes ].each do |filter|
      permitted_filters << { filter => [] } if filter_available?(filter)
    end

    params.fetch(:filters, {}).permit(*permitted_filters).to_h
  end

  # Check if we should redirect from legacy URL format to clean URL format
  def should_redirect_to_clean_url?
    params[:filters].present? && !turbo_frame_request?
  end

  # Build clean URL path with current filters
  def build_clean_url_path(resource = nil)
    clean_params = {}
    filters = normalized_filter_params

    # Build clean URL parameters
    if filters[:price_range].present? && filters[:price_range][:min] && filters[:price_range][:max]
      clean_params[:price] = "#{filters[:price_range][:min]}-#{filters[:price_range][:max]}"
    end

    if filters[:in_stock] == true
      clean_params[:stock] = "1"
    end

    # Array parameters
    clean_mappings = {
      product_types: :type,
      skin_types: :skin,
      brands: :brand,
      colors: :color,
      sizes: :size
    }

    clean_mappings.each do |filter_key, param_key|
      if filters[filter_key].present? && filters[filter_key].any? && filter_available?(filter_key)
        clean_params[param_key] = filters[filter_key].join(",")
      end
    end

    # Add sort parameter if present
    clean_params[:sort_by] = params[:sort_by] if params[:sort_by].present?

    # Add additional parameters configured for this controller
    _filterable_config[:additional_params]&.each do |param|
      clean_params[param] = params[param] if params[param].present?
    end

    # Build URL using the configured route helper
    route_helper = _filterable_config[:route_helper]
    raise "No route_helper configured for filterable controller" unless route_helper

    base_path = if resource
      public_send(route_helper, resource)
    else
      public_send(route_helper)
    end

    if clean_params.any?
      "#{base_path}?#{clean_params.to_query}"
    else
      base_path
    end
  end

  # Check if a specific filter is available for this controller
  def filter_available?(filter_name)
    available_filters = _filterable_config[:available_filters]
    return true if available_filters == :all

    Array(available_filters).include?(filter_name)
  end

  # Get the default sort option for this controller
  def default_sort_option
    _filterable_config[:default_sort]
  end
end
