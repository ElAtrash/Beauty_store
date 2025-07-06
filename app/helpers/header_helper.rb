module HeaderHelper
  def header_language_class(locale)
    base_classes = "hover:text-cyan-600 transition-colors"
    active_classes = "font-bold text-cyan-600"

    if I18n.locale == locale
      "#{base_classes} #{active_classes}"
    else
      base_classes
    end
  end

  def header_navigation_items
    [
      { key: "catalog", path: "#", highlight: false },
      { key: "brands", path: "#", highlight: false },
      { key: "new_in", path: "#", highlight: false },
      { key: "sale", path: "#", highlight: true },
      { key: "skincare", path: "#", highlight: false },
      { key: "makeup", path: "#", highlight: false },
      { key: "fragrance", path: "#", highlight: false },
      { key: "hair", path: "#", highlight: false }
    ]
  end

  def header_nav_class(item_key)
    base_classes = "transition-colors font-medium"

    case item_key
    when "sale"
      "#{base_classes} text-cyan-600"
    else
      "#{base_classes} text-gray-700 hover:text-cyan-600"
    end
  end
end
