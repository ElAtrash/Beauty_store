# frozen_string_literal: true

class HeroCarouselComponent < ViewComponent::Base
  def initialize
    # No parameters needed - slides are defined internally
  end

  private

  def slides
    [
      {
        index: 0,
        gradient: "from-pink-200 via-rose-300 to-purple-400",
        title: t("hero.title"),
        subtitle: t("hero.subtitle"),
        cta_primary: t("hero.cta_primary"),
        cta_secondary: t("hero.cta_secondary"),
        opacity: "opacity-100", # First slide visible by default
        animations: true
      },
      {
        index: 1,
        gradient: "from-amber-200 via-lime-300 to-emerald-400",
        title: t("hero.title_2"),
        subtitle: t("hero.subtitle_2"),
        cta_primary: t("hero.cta_primary_2"),
        cta_secondary: t("hero.cta_secondary_2"),
        opacity: "opacity-0",
        animations: false
      },
      {
        index: 2,
        gradient: "from-cyan-200 via-blue-200 to-indigo-400",
        title: t("hero.title_3"),
        subtitle: t("hero.subtitle_3"),
        cta_primary: t("hero.cta_primary_3"),
        cta_secondary: t("hero.cta_secondary_3"),
        opacity: "opacity-0",
        animations: false
      }
    ]
  end

  def navigation_arrow_icon(direction)
    icon_name = direction == :left ? :arrow_left : :arrow_right
    render(IconComponent.new(name: icon_name, class: "w-6 h-6"))
  end

  def slide_animation_classes(slide)
    if slide[:animations]
      "animate-fade-in-up"
    else
      ""
    end
  end

  def subtitle_animation_classes(slide)
    if slide[:animations]
      "animate-fade-in-up animation-delay-200"
    else
      ""
    end
  end

  def cta_animation_classes(slide)
    if slide[:animations]
      "animate-fade-in-up animation-delay-400"
    else
      ""
    end
  end
end
