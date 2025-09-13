---
name: hotwire
description: Hotwire/Turbo/Stimulus development helpers and debugging tools
aliases: ["turbo", "stimulus"]
---

# Hotwire Development Tools

Tools for working with Turbo Frames, Turbo Streams, and Stimulus controllers.

## Usage Examples:

- `/hotwire stimulus DropdownController` - Generate Stimulus controller
- `/hotwire debug turbo` - Show Turbo debugging info
- `/hotwire frames` - List all Turbo Frames in views
- `/hotwire streams` - Show Turbo Streams usage
- `/hotwire install` - Install Hotwire dependencies

## What I'll do:

1. Generate Stimulus controllers with proper patterns
2. Help debug Turbo Frame navigation issues
3. Analyze your Hotwire usage patterns
4. Ensure compatibility with your Rails 8 + Hotwire setup

**Arguments**: $ARGUMENTS

```bash
case "$1" in
  "stimulus")
    if [ -n "$2" ]; then
      echo "⚡ Generating Stimulus controller: $2"
      # Convert CamelCase to snake_case for filename
      filename=$(echo "$2" | sed 's/Controller$//' | sed 's/\([A-Z]\)/_\1/g' | sed 's/^_//' | tr '[:upper:]' '[:lower:]')
      controller_file="app/javascript/controllers/${filename}_controller.js"

      if [ ! -f "$controller_file" ]; then
        echo "📝 Creating $controller_file"
        mkdir -p app/javascript/controllers
        cat > "$controller_file" << 'EOF'
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="CONTROLLER_NAME"
export default class extends Controller {
  static targets = []
  static classes = []
  static values = {}

  connect() {
    console.log("CONTROLLER_NAME controller connected")
  }

  disconnect() {
    console.log("CONTROLLER_NAME controller disconnected")
  }
}
EOF
        # Replace placeholder with actual controller name
        sed -i.bak "s/CONTROLLER_NAME/${filename}/g" "$controller_file" && rm "${controller_file}.bak"
        echo "✅ Stimulus controller created at $controller_file"
      else
        echo "⚠️  Controller already exists: $controller_file"
      fi
    else
      echo "Usage: /hotwire stimulus ControllerName"
    fi
    ;;
  "debug")
    echo "🔍 Hotwire debugging information:"
    echo ""
    echo "📄 Checking for Turbo/Stimulus setup..."
    if [ -f "app/javascript/application.js" ]; then
      echo "✅ JavaScript entry point found"
      grep -n "turbo\|stimulus" app/javascript/application.js || echo "⚠️  No Turbo/Stimulus imports found"
    fi
    echo ""
    echo "⚡ Stimulus controllers:"
    find app/javascript/controllers -name "*_controller.js" 2>/dev/null | wc -l | xargs echo "Found controllers:"
    find app/javascript/controllers -name "*_controller.js" 2>/dev/null | head -10
    ;;
  "frames")
    echo "🖼️  Turbo Frames in your views:"
    grep -r "turbo_frame_tag\|<turbo-frame" app/views/ --include="*.erb" | head -10
    ;;
  "streams")
    echo "🌊 Turbo Streams usage:"
    grep -r "turbo_stream\|<turbo-stream" app/views/ --include="*.erb" | head -10
    ;;
  "install")
    echo "📦 Installing Hotwire dependencies..."
    bundle add hotwire-rails
    bundle exec rails hotwire:install
    echo "✅ Hotwire installation complete!"
    ;;
  *)
    echo "Usage: /hotwire [stimulus|debug|frames|streams|install] [options]"
    ;;
esac
```
