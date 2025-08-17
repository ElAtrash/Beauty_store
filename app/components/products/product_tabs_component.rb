# frozen_string_literal: true

class Products::ProductTabsComponent < ViewComponent::Base
  TAB_DEFINITIONS = [
    {
      id: "description",
      name: "Description",
      condition: ->(product) { product.description.present? },
      content_method: :render_description_content
    },
    {
      id: "application",
      name: "Application",
      condition: ->(product) { product.how_to_use.present? },
      content_method: :render_application_content
    },
    {
      id: "ingredients",
      name: "Ingredients",
      condition: ->(product) { product.ingredients.present? },
      content_method: :render_ingredients_content
    },
    {
      id: "brand",
      name: "Brand",
      condition: ->(product) { product.brand.present? },
      content_method: :render_brand_content
    }
  ].freeze

  def initialize(product:)
    @product = product
  end

  def tab_sections
    @tab_sections ||= build_tab_sections
  end

  def tab_button_classes(index)
    base_class = "product-tab-button"
    index.zero? ? "#{base_class} active" : base_class
  end

  def tab_panel_classes(index)
    base_class = "product-tab-panel"
    index.zero? ? "#{base_class} active" : base_class
  end

  private

  attr_reader :product

  def build_tab_sections
    TAB_DEFINITIONS.filter_map do |tab_def|
      next unless tab_def[:condition].call(product)

      {
        id: tab_def[:id],
        name: tab_def[:name],
        content: send(tab_def[:content_method])
      }
    end
  end

  def render_description_content
    content_tag :div, class: "space-y-6" do
      concat content_tag(:h3, product.name.upcase, class: "text-xl font-bold text-gray-900")

      concat(content_tag(:p, class: "text-sm text-gray-500") do
        "SKU: ".html_safe + content_tag(:span, product.product_code, class: "sku-display", data: { "products--variant-selector-target" => "skuDisplay" })
      end)

      concat content_tag(:div, simple_format(product.description, {}, class: "text-gray-700 leading-relaxed"), class: "mt-4")
      concat product_details_section
    end
  end

  def render_application_content
    formatted_text = product.how_to_use.gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>').html_safe
    simple_format(formatted_text, {}, class: "text-gray-700 leading-relaxed")
  end

  def render_ingredients_content
    ingredients = product.ingredients.split(",").map(&:strip)
    content_tag :div, class: "text-gray-700" do
      ingredients.map do |ingredient|
        content_tag(:span, ingredient, class: "inline-block bg-gray-100 px-2 py-1 rounded-md text-sm mr-2 mb-2")
      end.join.html_safe
    end
  end

  def render_brand_content
    content_tag :div, class: "space-y-4" do
      concat content_tag(:h4, product.brand.name, class: "text-xl font-medium text-gray-900")
      if product.brand.description.present?
        concat content_tag(:p, product.brand.description, class: "text-gray-700 leading-relaxed")
      else
        concat content_tag(:p, "Discover more products from #{product.brand.name}.", class: "text-gray-700")
      end
    end
  end

  def product_details_section
    attributes = ProductAttributeService.format_for_display(product)
    render Products::ProductDetailsComponent.new(attributes: attributes)
  end
end
