class Products::ProductCacheWarmerJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.includes(
      :brand,
      product_variants: [
        :featured_image_attachment,
        { images_attachments: :blob }
      ]
    ).find(product_id)

    presenter = Products::ProductPresenter.new(product)
    cache_key = cache_key_for(product)

    Rails.cache.write(
      cache_key,
      presenter.build_static_data,
      expires_in: 30.minutes
    )

    Rails.logger.info "Cache warmed for product #{product_id}: #{cache_key}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "Product #{product_id} not found for cache warming: #{e.message}"
    raise
  rescue => e
    Rails.logger.error "Failed to warm cache for product #{product_id}: #{e.message}"
    raise
  end

  private

  def cache_key_for(product)
    [ product.cache_key_with_version, "product_static_data" ]
  end
end
