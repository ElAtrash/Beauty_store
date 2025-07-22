# frozen_string_literal: true

class BrandsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @letter = params[:letter]&.upcase
    @search = params[:search]
    @brands_service = BrandsService.new(letter: @letter, search: @search)

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render "brands_frame"
        else
          render "index"
        end
      end
      format.turbo_stream
    end
  end

  def show
    @brand = Brand.friendly.find(params[:id])
    redirect_to brand_products_path(@brand)
  end
end
