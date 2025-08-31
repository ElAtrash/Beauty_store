# frozen_string_literal: true

# TODO: Consider refactoring this controller to use a service object for brand-related logic
class BrandsController < ApplicationController
  include Filterable

  allow_unauthenticated_access only: %i[ index show ]

  filterable_config(
    route_helper: :brand_path,
    available_filters: [ :price_range, :in_stock, :product_types, :skin_types, :colors, :sizes ],
    default_sort: "popularity"
  )

  def index
    @letter = params[:letter]&.upcase
    @search = params[:search]
    @brands_service = BrandsService.new(letter: @letter, search: @search)
  end

  rescue_from ActiveRecord::RecordNotFound, with: :handle_brand_not_found

  def show
    @brand = find_brand
    all_params = normalized_filter_params
    all_params[:sort_by] = params[:sort_by] if params[:sort_by].present?
    @filter_form = ProductFilterForm.new(all_params, context: "brand", context_resource: @brand)

    unless @filter_form.valid?
      handle_invalid_filters
      return
    end

    # Redirect to clean URL format if using legacy parameters
    if should_redirect_to_clean_url?
      redirect_to build_clean_url_path(@brand), status: :moved_permanently
      return
    end

    # Unfiltered products for calculating full ranges (price, etc.)
    @unfiltered_products = @brand.products.available

    # Create clean relation for filter options (without sorting aggregations)
    @filter_products = @brand.products.available
                             .filtered(@filter_form.to_filter_params)

    # Get filtered product IDs first to avoid SQL conflicts with sorting scopes
    filtered_ids = @filter_products.pluck(:id)

    # Create sorted relation for display using the filtered IDs
    @filtered_products = @brand.products.where(id: filtered_ids)
                               .sorted(@filter_form.sort_by)
                               .includes(:brand, product_variants: { images_attachments: :blob })
    @pagy, @products = pagy(@filtered_products, items: 40)

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "brands/products_frame", locals: {
            brand: @brand,
            products: @products,
            pagy: @pagy
          }
        else
          render :show
        end
      end
      format.turbo_stream { render_turbo_stream_response }
    end
  end

  private

  def find_brand
    Brand.friendly.find(params[:id])
  end

  def render_turbo_stream_response
    render turbo_stream: turbo_stream.append(
      "products-container",
      component: ProductGridComponent.new(products: @products)
    )
  end

  def handle_invalid_filters
    flash.now[:error] = "Invalid filter parameters: #{@filter_form.errors.full_messages.join(', ')}"
    render :show, status: :unprocessable_entity
  end

  def handle_brand_not_found
    flash[:error] = "Brand not found"
    redirect_to brands_path
  end
end
