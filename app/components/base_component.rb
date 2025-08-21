# frozen_string_literal: true

class BaseComponent < ViewComponent::Base
  private

  def safe_execute(&block)
    yield
  rescue StandardError => e
    Rails.logger.error "Component error in #{self.class.name}: #{e.message}"
    render_error_fallback if respond_to?(:render_error_fallback, true)
  end

  def css_classes(*classes)
    classes.flatten.compact.reject(&:blank?).join(" ")
  end

  def conditional_classes(**conditions)
    conditions.filter_map { |css_class, condition| css_class if condition }.join(" ")
  end

  def safe_attr(object, method, default: nil)
    return default unless object.respond_to?(method)

    object.public_send(method) || default
  rescue StandardError
    default
  end
end
