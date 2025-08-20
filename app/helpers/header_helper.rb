module HeaderHelper
  def header_language_class(locale)
    base_classes = "hover:text-interactive transition-colors bg-transparent border-none p-0 text-inherit font-inherit cursor-pointer text-sm appearance-none"
    active_classes = "font-bold text-interactive"

    if I18n.locale == locale
      "#{base_classes} #{active_classes}"
    else
      base_classes
    end
  end

  def language_link(locale, text)
    if I18n.locale == locale
      content_tag :span, text, class: header_language_class(locale)
    else
      button_to text, "/set_locale",
        method: :post,
        params: { locale: locale, return_to: request.fullpath },
        form_class: "inline",
        class: header_language_class(locale),
        local: true
    end
  end

  def header_navigation_items
    [
      { key: "catalog", path: "#", highlight: false },
      { key: "brands", path: brands_path, highlight: false },
      { key: "new_in", path: "#", highlight: false },
      { key: "sale", path: "#", highlight: true },
      { key: "skincare", path: "#", highlight: false },
      { key: "makeup", path: "#", highlight: false },
      { key: "fragrance", path: "#", highlight: false },
      { key: "hair", path: "#", highlight: false }
    ]
  end

  def header_nav_class(item_key)
    "transition-colors font-medium hover:text-interactive"
  end

  # Centralized page type detection
  def current_page_type
    if controller_name == "brands" && action_name == "show"
      "brand"
    elsif controller_name == "products" && action_name == "show"
      "product"
    else
      "home"
    end
  end

  # Centralized data attributes for header wrapper
  def header_data_attributes
    attributes = {
      controller: "navigation--header",
      "navigation--header-page-type-value": current_page_type
    }

    # Add banner URL for brand pages if available
    if current_page_type == "brand" && @brand&.banner_image&.attached?
      attributes["navigation--header-banner-url-value"] = Rails.application.routes.url_helpers.url_for(@brand.banner_image)
    end

    attributes
  end

  # Dynamic badge counts (replace hardcoded values)
  def header_badge_count(type)
    case type
    when :cart
      # TODO: Replace with actual cart item count from session/user
      2
    when :favorites, :wishlist
      # TODO: Replace with actual favorites count from user
      3
    else
      0
    end
  end
end
