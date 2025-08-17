class ProductsController < ApplicationController
  allow_unauthenticated_access only: %i[ show ]

  def show
    @product = Product.friendly.find(params[:id])

    unless @product.available?
      raise ActiveRecord::RecordNotFound
    end

    @product_data = Products::ProductPresenter.new(@product).build_display_data

    setup_breadcrumbs
    setup_seo_data
  end

  private

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
