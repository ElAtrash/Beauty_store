---
name: component
description: ViewComponent operations - create, preview, test, and manage components
aliases: ["vc", "viewcomponent"]
---

# ViewComponent Management

Manage ViewComponents following your project's component-driven architecture.

## Usage Examples:
- `/component create ProductCard` - Create new component with test
- `/component list` - Show all components
- `/component preview ProductCard` - Open component preview
- `/component test ProductCard` - Run component tests
- `/component refactor _product_partial` - Convert partial to component

## What I'll do:
1. Create ViewComponents with proper structure and tests
2. Follow your component patterns from CLAUDE.md
3. Generate component templates with Tailwind v4 compatible CSS
4. Set up component previews for development
5. Convert partials to reusable components when requested

**Arguments**: $ARGUMENTS

```bash
case "$1" in
  "create"|"new")
    echo "🔲 Creating ViewComponent: $2"
    bundle exec rails generate component "$2"
    echo "✅ Created component files. Don't forget to add component preview!"
    ;;
  "list"|"ls")
    echo "📋 ViewComponents in your app:"
    find app/components -name "*.rb" -type f | sed 's/.*\///' | sed 's/.rb$//' | sort
    ;;
  "preview")
    echo "👀 Opening component preview for: $2"
    echo "Navigate to: http://localhost:3000/rails/view_components/$2"
    ;;
  "test")
    if [ -n "$2" ]; then
      echo "🧪 Running tests for component: $2"
      bundle exec rspec "spec/components/${2}_spec.rb" --format documentation
    else
      echo "🧪 Running all component tests..."
      bundle exec rspec spec/components/ --format documentation
    fi
    ;;
  *)
    echo "Usage: /component [create|list|preview|test] [component_name]"
    ;;
esac
```