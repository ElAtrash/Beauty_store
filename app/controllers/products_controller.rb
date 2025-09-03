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
        render turbo_stream: [
          turbo_stream.replace("product-pricing", partial: "products/pricing", locals: { product_data: @product_data }),
          turbo_stream.replace("product-gallery", partial: "products/gallery", locals: { product: @product, selected_variant: @selected_variant })
        ]
      end
    end
  end

  private

  def set_product
    @product = Product.includes(:product_variants).find_available!(params[:id])
  end

  def build_product_data_for_variant(selected_variant)
    presenter = Products::ProductPresenter.new(@product)

    static_data = Rails.cache.fetch(product_data_cache_key(@product), expires_in: 30.minutes) do
      presenter.build_static_data
    end

    dynamic_data = presenter.build_dynamic_data(selected_variant: selected_variant)
    static_data.merge_dynamic!(dynamic_data)
  end

  def product_data_cache_key(product)
    [ product.cache_key_with_version, "product_static_data" ]
  end

  def find_selected_variant
    return if params[:size].blank? && params[:color].blank?

    if params[:color].present? && params[:size].blank?
      variant_for_color_only
    elsif params[:color].present? && params[:size].present?
      variant_for_color_and_size
    elsif params[:size].present?
      variant_for_size_only
    end
  end

  def variant_for_color_only
    color_variants = @product.product_variants.where(color_hex: params[:color])
    Products::DefaultVariantSelector.call(@product, scope: color_variants)
  end

  def variant_for_color_and_size
    @product.product_variants.by_size_key(params[:size]).find_by(color_hex: params[:color])
  end

  def variant_for_size_only
    @product.product_variants.by_size_key(params[:size]).first
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

  def product_data_cache_key(product)
    [ product.cache_key_with_version, "product_static_data" ]
  end
end
