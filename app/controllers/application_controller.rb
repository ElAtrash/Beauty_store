class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

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
end
