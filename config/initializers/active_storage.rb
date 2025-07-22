# frozen_string_literal: true

# Configure Active Storage
Rails.application.configure do
  # Variant processor (use mini_magick or vips)
  config.active_storage.variant_processor = :mini_magick
end

# Configure ImageMagick for mini_magick
Rails.application.config.after_initialize do
  require "mini_magick"
  # Set timeout for long-running operations
  MiniMagick.timeout = 120
end
