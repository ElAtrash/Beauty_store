class HomeController < ApplicationController
  include Pagy::Backend
  allow_unauthenticated_access only: %i[ index ]

  FEATURED_PRODUCTS_PER_PAGE = 40

  def index
    if params[:page].present?
      page = [ params[:page].to_i, 1 ].max
      @pagy, @products = pagy(featured_products_query, limit: FEATURED_PRODUCTS_PER_PAGE, page: page)

      respond_to do |format|
        format.turbo_stream
      end
    else
      @pagy, @featured_products = pagy(featured_products_query, limit: FEATURED_PRODUCTS_PER_PAGE, page: 1)

      respond_to do |format|
        format.html
      end
    end
  end

  private

  def featured_products_query
    Product.available
           .includes(:brand, :categories, product_variants: { images_attachments: :blob })
           .preload(:reviews)
           .by_popularity
  end
end
