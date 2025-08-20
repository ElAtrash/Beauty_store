# frozen_string_literal: true

class HeroSlideComponent < ViewComponent::Base
  with_collection_parameter :slide

  def initialize(slide:)
    @slide = slide
  end

  private

  attr_reader :slide

  def slide_index
    slide[:index]
  end

  def title
    slide[:title]
  end

  def subtitle
    slide[:subtitle]
  end

  def cta_primary
    slide[:cta_primary]
  end

  def cta_secondary
    slide[:cta_secondary]
  end

  def gradient_classes
    slide[:gradient]
  end

  def opacity_classes
    slide[:opacity]
  end

  def slide_classes
    "carousel-slide-base #{opacity_classes}"
  end

  def gradient_background_classes
    "absolute inset-0 bg-gradient-to-br #{gradient_classes}"
  end

  def slide_data_attributes
    {
      ui_hero_carousel_target: "slide",
      slide_index: slide_index
    }
  end

  def slide_animation_classes
    # Animation classes were removed from CSS, using empty string for now
    # TODO: Re-implement with CSS animations if needed
    ""
  end

  def subtitle_animation_classes
    # Animation classes were removed from CSS, using empty string for now
    # TODO: Re-implement with CSS animations if needed
    ""
  end

  def cta_animation_classes
    # Animation classes were removed from CSS, using empty string for now
    # TODO: Re-implement with CSS animations if needed
    ""
  end
end
