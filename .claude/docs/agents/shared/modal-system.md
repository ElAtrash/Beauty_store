# Modal System Architecture

## Modal::BaseComponent

**Location**: `app/components/modal/base_component.rb` + `.html.erb`

**Purpose**: Flexible, maintainable base component supporting both slot-based and method-based content approaches.

## Key Features

✅ **Dual Compatibility**: Supports both modern slot-based and legacy method-based content
✅ **Rails 8 Integration**: Uses `class_names` helper and proper data attribute handling
✅ **Position Configuration**: Centralized `POSITION_CONFIG` eliminates code duplication
✅ **Responsive Design**: Mobile-first with consistent breakpoint patterns
✅ **Accessibility**: Built-in ARIA attributes and semantic structure

## Usage Patterns

### Modern Slot-Based Approach (Recommended)

```erb
<%= render Modal::BaseComponent.new(id: "example", title: "Example") do |modal| %>
  <% modal.with_body do %>
    <div class="p-4">
      <p>Your modal content here</p>
    </div>
  <% end %>

  <% modal.with_header_action do %>
    <button class="btn-secondary">Action</button>
  <% end %>

  <% modal.with_footer do %>
    <button class="btn-primary">Save</button>
  <% end %>
<% end %>
```

### Method-Based Approach (Legacy/Backward Compatible)

```ruby
class Modal::CartComponent < Modal::BaseComponent
  def content
    if empty_cart?
      render "modal/cart/empty_state"
    else
      render "modal/cart/cart_items", cart_items: cart_items
    end
  end

  def header_actions
    return nil if empty_cart?
    link_to clear_all_cart_items_path, class: "btn-icon" do
      render UI::IconComponent.new(name: :trash)
    end
  end

  def footer_content
    return nil if empty_cart?
    render "modal/cart/cart_footer", total_price: formatted_total_price
  end
end
```

## Modal Positions

- **`:left`** - Slides from left (filters, navigation)
- **`:right`** - Slides from right (cart, auth, forms)
- **`:center`** - Center overlay (confirmations, alerts)

## Modal Sizes

- **`:medium`** - 680px width (default for most modals)
- **`:full`** - Full width (image galleries, complex forms)

## Data Attributes Integration

```ruby
# Automatic controller and data attribute handling
Modal::BaseComponent.new(
  id: "custom-modal",
  title: "Custom Modal",
  data: { controller: "custom", "custom-value": "123" }
)
# Results in: data-controller="modal custom" data-custom-value="123"
```

## Testing Patterns

```ruby
RSpec.describe Modal::CustomComponent, type: :component do
  include ViewComponent::TestHelpers

  it "renders modal structure" do
    rendered = render_inline(component)

    expect(rendered.css("div[id='custom-modal']")).to be_present
    expect(rendered.css("[data-modal-target='overlay']")).to be_present
    expect(rendered.css("[data-modal-target='panel']")).to be_present
  end

  it "supports both content approaches" do
    # Test method-based content
    expect(component.send(:content)).to be_present

    # Test slot-based content
    rendered = render_inline(component) do |modal|
      modal.with_body { "Slot content" }
    end
    expect(rendered.text).to include("Slot content")
  end
end
```

## Migration Guide

### When Creating New Modals
1. Use slot-based approach with `renders_one :body`
2. Leverage `class_names` helper for CSS management
3. Use centralized configuration patterns
4. Include comprehensive specs

### When Maintaining Existing Modals
1. Existing method-based modals work unchanged
2. Gradually migrate to slot-based approach when making updates
3. Both patterns can coexist during transition

## JavaScript Integration

### Stimulus Controller

The modal system integrates with a Stimulus controller for interaction:

```javascript
// app/javascript/controllers/modal_controller.js
export default class extends Controller {
  static targets = ["overlay", "panel"]

  open() {
    // Modal opening logic
  }

  close() {
    // Modal closing logic
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
```

### Data Attributes

- `data-controller="modal"` - Attaches Stimulus controller
- `data-modal-target="overlay"` - Background overlay
- `data-modal-target="panel"` - Modal content panel
- `data-action="click->modal#close"` - Close button action
- `data-action="keydown@window->modal#handleKeydown"` - Keyboard support