class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  before_action :set_locale
  before_action :set_current_session
  before_action :set_active_storage_url_options

  helper_method :current_cart, :cart_item_count, :cart_title

  # Session key constants
  CART_TOKEN_KEY = :cart_token

  private

  def set_locale
    I18n.locale = params[:locale] ||
                  session[:locale] ||
                  extract_locale_from_accept_language_header ||
                  I18n.default_locale

    session[:locale] = I18n.locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted_languages = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/)
    available_locales = I18n.available_locales.map(&:to_s)

    accepted_languages.find { |lang| available_locales.include?(lang) }&.to_sym
  end

  def set_current_session
    resume_session
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.host, port: request.port, protocol: request.protocol }
  end

  def setup_seo_data(entity)
    @page_title = entity.meta_title.presence || default_title_for(entity)
    @meta_description = entity.meta_description.presence || default_description_for(entity)
  end

  def default_title_for(entity)
    case entity
    when Product
      "#{entity.name}#{StoreConfigurationService.seo_title_suffix}"
    when Brand
      "#{entity.name} Products#{StoreConfigurationService.seo_title_suffix}"
    else
      StoreConfigurationService.name
    end
  end

  def default_description_for(entity)
    case entity
    when Product
      "#{entity.description&.truncate(150)} Shop #{entity.name} at #{StoreConfigurationService.name}."
    when Brand
      "Discover #{entity.name} beauty products. Shop the latest #{entity.name} collection at #{StoreConfigurationService.name}."
    else
      StoreConfigurationService.default_meta_description
    end
  end

  def render_not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  # Cart helper methods
  def current_cart
    return @current_cart if defined?(@current_cart)

    result = Carts::FindOrCreateService.call(
      user: Current.user,
      session: session,
      cart_token: session[CART_TOKEN_KEY]
    )

    @current_cart = result.cart
  end

  def cart_item_count
    current_cart&.total_quantity || 0
  end
end
