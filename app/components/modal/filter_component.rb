# frozen_string_literal: true

class Modal::FilterComponent < Modal::BaseComponent
  def initialize(filter_form:, products: nil, unfiltered_products: nil, context: nil, context_resource: nil, turbo_frame_id: nil)
    @filter_form = filter_form
    @products = products || Product.available
    @unfiltered_products = unfiltered_products || @products
    @context = context
    @context_resource = context_resource
    @turbo_frame_id = turbo_frame_id

    super(
      id: "filter-modal",
      title: "Filters",
      size: :medium,
      position: :left,
      data: {
        controller: "filters--filter",
        "filters--filter-turbo-frame-id-value": turbo_frame_target,
        "filters--filter-context-value": context
      }
    )
  end

  # Override BaseComponent method to provide filter-specific content
  def content
    render "modal/filter/content",
           filter_form: filter_form,
           products: products,
           unfiltered_products: unfiltered_products,
           context: context,
           context_resource: context_resource,
           turbo_frame_id: turbo_frame_id,
           component: self
  end

  # Public methods for template access
  attr_reader :filter_form, :products, :unfiltered_products, :context, :context_resource, :turbo_frame_id

  def filter_options_service
    @filter_options_service ||= Filters::FilterOptionsService.new(
      products: products,
      unfiltered_products: unfiltered_products,
      filter_form: filter_form
    )
  end

  def price_range
    filter_options_service.price_range
  end

  def skin_type_options
    filter_options_service.skin_type_options
  end

  def product_type_options
    filter_options_service.product_type_options
  end

  def brand_options
    filter_options_service.brand_options
  end

  def available_colors
    filter_options_service.available_colors
  end

  def available_sizes
    filter_options_service.available_sizes
  end

  def filter_selected?(filter_type, value)
    filter_form.value_selected?(filter_type, value)
  end

  def in_stock_selected?
    filter_form.in_stock
  end

  def current_min_price
    filter_form.price_range_min || price_range[:min]
  end

  def current_max_price
    filter_form.price_range_max || price_range[:max]
  end

  def controller_name
    case context
    when "brand"
      "filters--filter"
    when "product"
      "filters--filter"
    when "search"
      "filters--filter"
    else
      "filters--filter"
    end
  end

  def turbo_frame_target
    turbo_frame_id || "filtered_products"
  end

  def selected_values_for(filter_type)
    case filter_type
    when "product_types"
      filter_form.product_types || []
    when "brands"
      filter_form.brands || []
    when "colors"
      filter_form.colors || []
    when "skin_types"
      filter_form.skin_types || []
    when "sizes"
      filter_form.sizes || []
    else
      []
    end
  end


  private

  # Override to customize modal size for filters (480px as per current CSS)
  def panel_size_classes
    return center_panel_size_classes if position == :center

    base_classes = [ "box-border" ]

    responsive_classes = if size == :full
      [ "w-full", "max-w-none" ]
    else
      [ "w-[480px]", "min-w-[480px]", "max-w-[90vw]" ]
    end

    mobile_classes = [ "max-md:w-full", "max-md:max-w-full", "max-md:min-w-0" ]

    base_classes + responsive_classes + mobile_classes
  end
end
