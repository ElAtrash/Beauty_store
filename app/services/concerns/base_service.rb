# frozen_string_literal: true

module BaseService
  extend ActiveSupport::Concern

  included do
    attr_reader :last_result
  end

  class_methods do
    # Standard service entry point - allows calling Service.call(...)
    def call(*args, **kwargs, &block)
      new(*args, **kwargs).call(&block)
    end
  end

  protected

  def success(resource: nil, message: nil, **metadata)
    result_metadata = {}
    result_metadata[:message] = message if message.present?
    result_metadata.merge!(metadata)

    BaseResult.new(success: true, resource: resource, **result_metadata)
  end

  def failure(errors, **metadata)
    BaseResult.new(success: false, errors: Array(errors), **metadata)
  end

  def validation_failure(errors)
    BaseResult.new(success: false, errors: errors, error_type: :validation)
  end

  def service_failure(errors)
    BaseResult.new(success: false, errors: errors, error_type: :service)
  end

  def validate_required_params(**params)
    missing_params = params.select { |_key, value| value.blank? }.keys

    return if missing_params.empty?

    if missing_params.size == 1
      param = missing_params.first
      specific_key = "services.errors.#{param}_required"

      if I18n.exists?(specific_key)
        @last_result = failure(I18n.t(specific_key))
      else
        @last_result = failure(I18n.t("services.errors.param_required", params: param.to_s))
      end
    else
      @last_result = failure(I18n.t("services.errors.params_required", params: missing_params.join(", ")))
    end
  end

  private

  def log_error(error_type, exception)
    service_name = self.class.name
    Rails.logger.error "#{service_name} #{error_type}: #{exception.message}"

    Rails.logger.error exception.backtrace.join("\n") if error_type == "unexpected error"
  end
end
