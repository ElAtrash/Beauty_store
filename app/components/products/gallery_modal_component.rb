# frozen_string_literal: true

class Products::GalleryModalComponent < ViewComponent::Base
  MAX_VISIBLE_THUMBNAILS = 4

  def initialize(product:, gallery_images:, current_image_index: 0)
    @product = product
    @gallery_images = gallery_images
    @current_image_index = current_image_index
  end

  def image_url(attachment, size: :large)
    gallery_image = Products::GalleryImage.new(
      attachment: attachment,
      type: attachment ? :gallery : :placeholder
    )
    gallery_image.url(size)
  end

  def thumbnail_container_height
    "calc(#{MAX_VISIBLE_THUMBNAILS} * (var(--thumb-size) + var(--thumb-gap)) - var(--thumb-gap))"
  end

  def show_thumbnail_arrows?
    gallery_images.size > MAX_VISIBLE_THUMBNAILS
  end

  private

  attr_reader :product, :gallery_images, :current_image_index
end
