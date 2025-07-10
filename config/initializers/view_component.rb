# ViewComponent configuration for Rails 8 + ViewComponent 4.0
ViewComponent::Base.config.tap do |config|
  # Generate components in app/components directory
  config.generate.path = "app/components"

  # Use suffix for component class names (e.g., HeaderComponent vs Header)
  config.generate.suffix = "Component"

  # Generate sidecar directory for component files
  config.generate.sidecar = true

  # Generate stimulus controller alongside component
  config.generate.stimulus_controller = true

  # Show previews in development
  if Rails.env.development?
    config.previews.show = true
    config.previews.path = "app/components/previews"
    config.previews.layout = "component_preview"
  end

  # Use default render method (call)
  config.generate.method = true

  # Template options
  config.generate.inline = false
end

# Optional: Enable component instrumentation for performance monitoring
if Rails.env.development? || Rails.env.test?
  ViewComponent::Base.config.instrumentation_enabled = true
end
