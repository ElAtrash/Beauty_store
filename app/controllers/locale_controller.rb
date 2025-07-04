class LocaleController < ApplicationController
  def set
    locale = params[:locale]

    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
      I18n.locale = locale

      redirect_to params[:return_to] || root_path
    else
      redirect_to root_path
    end
  end
end
