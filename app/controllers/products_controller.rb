class ProductsController < ApplicationController
  allow_unauthenticated_access only: %i[ show update_variant ]

  before_action :set_product, only: %i[show update_variant]

  def show
    @selected_variant = find_selected_variant || @product.default_variant
    @product_data = build_product_data_for_variant(@selected_variant)
    setup_breadcrumbs
    setup_seo_data(@product)
  end

  def update_variant
    @selected_variant = find_selected_variant || @product.default_variant
    @product_data = build_product_data_for_variant(@selected_variant)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_variant_update_streams
      end
      format.html do
        redirect_to product_path(@product, color: params.dig(:product, :color), size: params.dig(:product, :size))
      end
    end
  end

  private

  def set_product
    @product = Product.includes(:product_variants).find_available!(params[:id])
  end

  def build_variant_update_streams
    [
      turbo_stream.replace("product-pricing", html: render_pricing_partial),
      turbo_stream.replace("product-gallery", html: render_gallery_partial),
      turbo_stream.replace("variant-selector", html: render_variant_selector_partial),
      turbo_stream.update_all(".sku-display", html: @selected_variant.sku)
    ]
  rescue => e
    Rails.logger.error "UpdateVariant: Error rendering partials - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    [
      turbo_stream.replace("product-pricing", html: "<div>Error loading pricing for #{@selected_variant.name}</div>"),
      turbo_stream.replace("product-gallery", html: "<div>Error loading gallery for #{@selected_variant.name}</div>"),
      turbo_stream.replace("variant-selector", html: "<div>Error loading variant selector for #{@selected_variant.name}</div>"),
      turbo_stream.update_all(".sku-display", html: @selected_variant.sku)
    ]
  end

  def render_pricing_partial
    render_to_string(partial: "products/pricing", locals: { product_data: @product_data }, formats: [ :html ])
  end

  def render_gallery_partial
    render_to_string(partial: "products/gallery", locals: { product: @product, selected_variant: @selected_variant }, formats: [ :html ])
  end

  def render_variant_selector_partial
    render_to_string(partial: "products/variant_selector", locals: {
      product: @product,
      variant_options: @product_data.variant_options,
      stock_info: @product_data.stock_info,
      product_data: @product_data
    }, formats: [ :html ])
  end

  def build_product_data_for_variant(selected_variant)
    presenter = Products::ProductPresenter.new(@product)

    static_data = Rails.cache.fetch(product_data_cache_key(@product), expires_in: 30.minutes) do
      presenter.build_static_data
    end

    dynamic_data = presenter.build_dynamic_data(selected_variant: selected_variant)
    product_data = static_data.merge_dynamic!(dynamic_data)

    monitor_response_size(product_data)
    product_data
  end

  def product_data_cache_key(product)
    [ product.cache_key_with_version, "product_static_data" ]
  end

  def monitor_response_size(product_data)
    json_size = product_data.as_json.to_json.length
    size_kb = (json_size / 1024.0).round(2)

    if size_kb > 50
      Rails.logger.warn "ProductData: Large response payload for product #{@product.id}: #{size_kb} KB (#{@product.product_variants.count} variants)"
    elsif size_kb > 20
      Rails.logger.info "ProductData: Medium response payload for product #{@product.id}: #{size_kb} KB"
    end

    Rails.logger.debug "ProductData: Payload size for product #{@product.id}: #{size_kb} KB"
  end

  def find_selected_variant
    size = params.dig(:product, :size)
    color = params.dig(:product, :color)

    return if size.blank? && color.blank?

    scope = @product.product_variants
    scope = scope.by_size_key(size) if size.present?
    scope = scope.where(color_hex: color) if color.present?

    if color.present? && size.blank?
      Products::DefaultVariantSelector.call(@product, scope: scope)
    else
      scope.first
    end
  end

  def setup_breadcrumbs
    @breadcrumbs = [ { name: "Home", path: root_path } ]

    if (category = @product.categories.first)
      @breadcrumbs << { name: category.name, path: category_path(category) }
    end

    if (brand = @product.brand)
      @breadcrumbs << { name: brand.name, path: brand_path(brand) }
    end

    @breadcrumbs << { name: @product.name, path: nil }
  end
end
