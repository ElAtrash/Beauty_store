# frozen_string_literal: true

class UI::RatingComponent < ViewComponent::Base
  def initialize(product:, style: :full)
    @product = product
    @style = style
  end

  def container_classes
    "rating-component rating-component--#{@style}"
  end

  private

  attr_reader :product, :style

  def rating
    @rating ||= product.rating || 0
  end

  def review_count
    @review_count ||= product.reviews_count || 0
  end

  def full_stars
    @full_stars ||= rating.floor
  end

  def has_half_star?
    @has_half_star ||= (rating % 1) >= 0.5
  end

  def empty_stars
    @empty_stars ||= 5 - full_stars - (has_half_star? ? 1 : 0)
  end
end
