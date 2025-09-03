class Products::ProductCacheWarmerJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.includes(:product_variants).find(product_id)
    presenter = Products::ProductPresenter.new(product)

    Rails.cache.write(
      cache_key_for(product),
      presenter.build_static_data,
      expires_in: 30.minutes
    )
  end

  private

  def cache_key_for(product)
    [ product.cache_key_with_version, "product_static_data" ]
  end
end
