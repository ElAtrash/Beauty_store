# frozen_string_literal: true

class BrandsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @letter = params[:letter]&.upcase
    @search = params[:search]
    @brands_service = BrandsService.new(letter: @letter, search: @search)
  end

  def show
    @brand = Brand.friendly.find(params[:id])
    @pagy, @products = pagy(@brand.products.displayable, items: 40)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("products-container",
          component: ProductGridComponent.new(products: @products)
        )
      end
    end
  end
end
