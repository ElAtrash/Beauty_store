# frozen_string_literal: true

class Products::ProductReviewsComponent < ViewComponent::Base
  def initialize(product:)
    @product = product
  end

  private

  attr_reader :product

  def has_reviews?
    product.reviews.any?
  end

  def average_rating
    @average_rating ||= product.average_rating || 0
  end

  def rating_breakdown
    @rating_breakdown ||= begin
      return [] unless has_reviews?

      breakdown = (1..5).map do |rating|
        count = product.reviews.where(rating: rating).count
        percentage = (count.to_f / product.reviews_count * 100).round
        { rating: rating, count: count, percentage: percentage }
      end.reverse
    end
  end

  def recommendation_percentage
    @recommendation_percentage ||= begin
      return 0 unless has_reviews?

      positive_reviews = product.reviews.where(rating: [ 4, 5 ]).count
      (positive_reviews.to_f / product.reviews_count * 100).round
    end
  end

  def recent_reviews
    @recent_reviews ||= product.reviews
                              .includes(:user)
                              .order(created_at: :desc)
                              .limit(5)
  end

  def render_stars(rating, size: "w-5 h-5")
    content_tag :div, class: "flex items-center space-x-0.5" do
      5.times.map do |i|
        if i < rating
          render(IconComponent.new(name: :star, class: "#{size} text-secondary transition-colors"))
        else
          render(IconComponent.new(name: :star, class: "#{size} text-disabled"))
        end
      end.join.html_safe
    end
  end

  def time_ago_in_words_russian(time)
    case
    when time > 1.year.ago
      "#{time_ago_in_words(time)} ago"
    when time > 1.month.ago
      "#{time_ago_in_words(time)} ago"
    when time > 1.day.ago
      "#{time_ago_in_words(time)} ago"
    else
      "Today"
    end
  end
end
