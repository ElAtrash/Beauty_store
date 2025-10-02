# frozen_string_literal: true

class PhoneValidator < ActiveModel::EachValidator
  LEBANON_PHONE_REGEX = /\A(\+961|961)?(70|71|03|76|81)\d{6}\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    unless value.match?(LEBANON_PHONE_REGEX)
      record.errors.add(attribute,
        options[:message] || I18n.t("validation.errors.phone_lebanon_invalid"))
    end
  end
end
