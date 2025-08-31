# frozen_string_literal: true

# Configure Active Storage
Rails.application.configure do
  config.active_storage.variant_processor = :vips
end

# Configure libvips
Rails.application.config.after_initialize do
  require "ruby-vips"
end
