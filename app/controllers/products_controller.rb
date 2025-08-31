class ProductsController < ApplicationController
  allow_unauthenticated_access only: %i[ show update_variant ]

  def show
    @product = Product.friendly.find(params[:id])

    unless @product.available?
      raise ActiveRecord::RecordNotFound
    end

    @product_data = Products::ProductPresenter.new(@product).build_display_data

    setup_breadcrumbs
    setup_seo_data
  end

  def update_variant
    @product = Product.friendly.find(params[:id])

    unless @product.available?
      raise ActiveRecord::RecordNotFound
    end

    # Get selected variant based on form params
    @selected_variant = find_selected_variant || @product.default_variant
    @product_data = Products::ProductPresenter.new(@product, selected_variant: @selected_variant).build_display_data

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

  def find_selected_variant
    size_param = params[:size]
    color_param = params[:color]

    return nil unless size_param || color_param

    @product.product_variants.find do |variant|
      size_match = size_param.nil? || variant.size_key == size_param
      color_match = color_param.nil? || variant.color_hex == color_param
      size_match && color_match
    end
  end

  def setup_breadcrumbs
    @breadcrumbs = [
      { name: "Home", path: root_path }
    ]

    if @product.categories.any?
      category = @product.categories.first
      @breadcrumbs << { name: category.name, path: category_path(category) }
    end

    if @product.brand
      @breadcrumbs << { name: @product.brand.name, path: brand_path(@product.brand) }
    end

    @breadcrumbs << { name: @product.name, path: nil }
  end

  def setup_seo_data
    @page_title = @product.meta_title.presence || "#{@product.name} | Beauty Store"
    @meta_description = @product.meta_description.presence ||
      "#{@product.description&.truncate(150)} Shop #{@product.name} at Beauty Store."
  end
end
