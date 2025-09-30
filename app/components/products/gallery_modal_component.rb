# frozen_string_literal: true

class Products::GalleryModalComponent < Modal::BaseComponent
  MAX_VISIBLE_THUMBNAILS = 4

  def initialize(product:, gallery_images:, current_image_index: 0)
    @product = product
    @gallery_images = gallery_images
    @current_image_index = current_image_index

    super(
      id: "gallery-zoom-modal",
      title: product.name,
      size: :full,
      position: :center,
      data: {
        controller: "products--gallery",
        "products--gallery-target": "zoomModal",
        action: "click->products--gallery#closeZoom"
      }
    )
  end

  # Override BaseComponent method to provide gallery-specific content
  def content
    render "products/gallery_modal/content",
           product: product,
           gallery_images: gallery_images,
           current_image_index: current_image_index,
           component: self
  end

  # Gallery modal should not show the default header
  def title
    ""
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

  # Override to create full-screen gallery modal specific styling
  def container_classes
    [
      "fixed", "inset-0", "z-[var(--z-gallery-modal)]",
      "hidden", "bg-white"
    ].join(" ")
  end

  def panel_classes
    [
      "flex", "h-full", "w-full", "bg-white"
    ].join(" ")
  end

  # Gallery modal doesn't use the standard header
  def header_classes
    "hidden"
  end

  # Gallery modal uses full height content
  def content_classes
    "flex h-full w-full p-0"
  end

  # Override to add gallery-specific data attributes
  def additional_data_attributes
    super.merge({
      "products--gallery-target": "zoomModal"
    })
  end
end
