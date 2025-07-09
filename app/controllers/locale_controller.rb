class LocaleController < ApplicationController
  allow_unauthenticated_access only: [:set]
  
  def set
    locale = params[:locale]

    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
      I18n.locale = locale

      return_to = params[:return_to] || root_path

      clean_return_to = return_to.gsub(%r{^/(en|ar)/?}, "/")
      clean_return_to = "/" if clean_return_to.empty?

      redirect_to clean_return_to
    else
      redirect_to root_path
    end
  end
end
