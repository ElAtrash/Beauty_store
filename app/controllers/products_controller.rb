class ProductsController < ApplicationController
  def show
    @product = Product.friendly.find(params[:id])
  end
end
