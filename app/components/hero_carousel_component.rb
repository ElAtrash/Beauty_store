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
        gradient: "from-blue-200 via-indigo-200 to-purple-400",
        title: t("hero.title_3"),
        subtitle: t("hero.subtitle_3"),
        cta_primary: t("hero.cta_primary_3"),
        cta_secondary: t("hero.cta_secondary_3"),
        opacity: "opacity-0",
        animations: false
      }
    ]
  end

  def cursor_data_url(icon_name)
    icon_path = IconPath::ICONS[icon_name]
    return "" unless icon_path

    size = 36
    svg_content = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" fill="none" viewBox="0 0 24 24">
        #{icon_path}
      </svg>
    SVG

    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_content)}"
  end
end
