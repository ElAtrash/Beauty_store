# Modal System Architecture Research

## Overview

This Rails codebase implements a sophisticated, flexible modal system built on `Modal::BaseComponent` with ViewComponent v4 slot architecture. The system supports both modern slot-based composition and legacy method-based content, providing dual compatibility during transitions. Modals integrate seamlessly with Stimulus controllers, Turbo Streams, and Tailwind CSS for rich, interactive user experiences.

**Key Finding**: The codebase uses TWO distinct modal patterns - the newer `Modal::BaseComponent` slot-based system and an older direct partial rendering approach. Current address modal implementation uses the LEGACY partial-based approach, but should migrate to slot-based architecture.

## Relevant Files

### Core Modal Infrastructure
- `/app/components/modal/base_component.rb` - Universal modal foundation with slot architecture
- `/app/components/modal/base_component.html.erb` - Modal template with overlay, panel, header, content, footer
- `/app/javascript/controllers/modal_controller.js` - Stimulus controller for modal interactions (270 lines)
- `/.claude/docs/agents/shared/modal-system.md` - Comprehensive modal system documentation

### Existing Modal Implementations
- `/app/components/cart/modal_component.rb` - Shopping cart modal (inherits BaseComponent)
- `/app/components/cart/modal_wrapper_component.rb` - Cart wrapper using slot-based approach
- `/app/components/checkout/modals/address_modal_component.rb` - Address modal (inherits BaseComponent, MIXED approach)
- `/app/components/checkout/modals/pickup_details_modal_component.rb` - Pickup details modal (inherits BaseComponent)
- `/app/components/products/gallery_modal_component.rb` - Full-screen gallery modal (heavily customized)
- `/app/components/modal/auth_component.rb` - Authentication modal (method-based content)
- `/app/components/modal/filter_component.rb` - Filter modal (method-based content)

### Address-Related Components
- `/app/components/addresses/selector_card_component.rb` - Address selection card with radio button
- `/app/components/addresses/selector_card_component.html.erb` - Card template with edit/delete actions
- `/app/components/addresses/form_component.rb` - Address form component
- `/app/components/addresses/form_component.html.erb` - Full address form with all fields
- `/app/models/address.rb` - Address model with validations, soft delete, scopes
- `/app/controllers/addresses_controller.rb` - Full CRUD with Turbo Stream responses

### Current Address Modal Implementation (LEGACY)
- `/app/views/checkout/modals/_address_modal_body.html.erb` - Turbo Frame wrapper for list/form switching
- `/app/javascript/controllers/address_modal_controller.js` - Address modal logic (160 lines)

### Address Management Views
- `/app/views/addresses/index.html.erb` - Address book index page
- `/app/views/addresses/new.html.erb` - New address page
- `/app/views/addresses/edit.html.erb` - Edit address page

### Supporting Documentation
- `/.claude/docs/implementations/address-modal-workflow.md` - Current address modal workflow documentation
- `/.claude/docs/implementations/unified-popup-system.md` - Popup system (separate from modals)

## Architectural Patterns

### **Modal::BaseComponent Slot Architecture**
The foundation of the modal system uses ViewComponent v4 slots for flexible content composition:
```ruby
# app/components/modal/base_component.rb
renders_one :body          # Main content area
renders_one :header_action # Actions next to title (e.g., clear cart button)
renders_one :footer        # Bottom actions (e.g., submit buttons)
```

**Key Features**:
- Position variants: `:left`, `:right`, `:center` with distinct animations
- Size variants: `:medium` (680px), `:full` (100%)
- Automatic Stimulus controller integration via data attributes
- Dual compatibility: supports both slots AND legacy method-based content
- Centralized `POSITION_CONFIG` hash eliminates code duplication
- Built-in ARIA attributes for accessibility

### **Two Content Approaches**

#### 1. Modern Slot-Based (RECOMMENDED)
Used by: Cart modal, recommended for new implementations
```ruby
# app/components/cart/modal_wrapper_component.html.erb
<%= render Cart::ModalComponent.new(...) do |modal| %>
  <% modal.with_body { render Cart::ContentComponent.new(...) } %>
  <% modal.with_header_action do %>
    <%= link_to clear_all_cart_items_path do %>
      <%= render UI::IconComponent.new(name: :trash) %>
    <% end %>
  <% end %>
  <% modal.with_footer { render Cart::FooterComponent.new(...) } %>
<% end %>
```

**Benefits**:
- Clean separation of concerns
- Easy to compose complex content
- Type-safe with ViewComponent slots
- Clear visual hierarchy in code

#### 2. Legacy Method-Based
Used by: Auth modal, Filter modal, partially by address modal
```ruby
# app/components/modal/auth_component.rb
def content
  if signed_in?
    render "modal/auth/user_menu", current_user: current_user
  else
    render "modal/auth/login_form"
  end
end

def header_actions
  # Optional header actions
end

def footer_content
  # Optional footer content
end
```

**When Used**:
- Backward compatibility with existing modals
- Simple conditional rendering based on state
- Gradual migration path

### **Turbo Frame Integration for Dynamic Content**
Current address modal uses Turbo Frames for view switching:
```erb
<!-- app/views/checkout/modals/_address_modal_body.html.erb -->
<%= turbo_frame_tag "address-selection-ui", data: { controller: "address-selector" } do %>
  <% if initial_view == :list %>
    <%= render "checkout/address_selection/list_view", ... %>
  <% else %>
    <%= render "checkout/address_selection/form_view", ... %>
  <% end %>
<% end %>
```

**Pattern**: Turbo Frame wraps content that can be replaced without full page reload, enabling seamless view transitions within the modal.

### **Stimulus Controller Integration**

**Base Modal Controller** (`modal_controller.js`):
- Static values: `id`, `backdropClose`, `position`, `animationDuration`
- Targets: `overlay`, `panel`
- Methods: `open()`, `close()`, `toggle()`, `handleKeydown()`
- Features: Focus trapping, scroll locking, keyboard navigation, position-based animations
- Event dispatch: `modal:opened`, `modal:closed`

**Specialized Controllers**: Address modal, pickup details modal, etc. extend base functionality
- Use Stimulus outlets to connect with modal controller
- `data-controller="address-modal modal"` - Multiple controllers on same element
- Outlets: `modal`, `form-validation` for cross-controller communication

### **Address-Specific Components**

**Addresses::SelectorCardComponent**:
- Radio button selection pattern
- Inline edit/delete actions via Turbo Frames
- Default badge for primary address
- Wraps each card in `turbo_frame_tag "address-edit-#{address.id}"` for in-place editing

**Addresses::FormComponent**:
- Full CRUD form with all address fields
- Governorate dropdown (Lebanese governorates from User constant)
- Phone validation integration
- Default checkbox with automatic sibling management
- Turbo Stream compatible responses

**Address Model**:
- Soft delete pattern (`deleted_at` timestamp)
- Automatic default management (ensures only one default per user)
- Scopes: `active`, `default_address`, `recently_used`
- Display helpers: `full_address`, `short_address`, `display_label`

### **Addresses Controller Pattern**
Full RESTful CRUD with comprehensive Turbo Stream responses:
```ruby
# app/controllers/addresses_controller.rb
def create
  if @address.save
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.prepend("addresses-list", ...),
        turbo_stream.replace("address-form-modal", partial: "shared/empty"),
        turbo_stream.replace("flash-messages", ...)
      ]
    end
  end
end
```

**Pattern**: Multiple Turbo Stream actions in single response - prepend new content, clear form, show flash message.

## Edge Cases & Gotchas

### **Modal vs Popup Confusion**
- The codebase has BOTH a modal system and a popup system (BasePopupComponent)
- Modals = `Modal::BaseComponent` for overlays, drawers, dialogs
- Popups = `BasePopupComponent` for smaller contextual UI (delivery schedule picker)
- **Gotcha**: Don't mix the two systems - they have different controllers and patterns

### **Address Modal Mixed Architecture**
The current address modal (`Checkout::Modals::AddressModalComponent`) uses a HYBRID approach:
- Inherits from `Modal::BaseComponent` (modern)
- But body content is rendered via separate partial (`_address_modal_body.html.erb`)
- Doesn't use slot-based `with_body` approach
- **Issue**: Inconsistent with recommended slot-based pattern

### **Turbo Frame ID Conflicts**
Address selector cards use `turbo_frame_tag "address-edit-#{address.id}"` for inline editing:
- Each card has its own frame
- Edit action targets specific frame
- Delete action removes entire card
- **Gotcha**: Frame IDs must be unique across the page

### **Default Address Management**
Address model automatically manages default flag:
```ruby
# Only one default per user via callback
before_save :ensure_only_one_default, if: :default?

def ensure_only_one_default
  self.class.where(user_id: user_id, default: true)
             .where.not(id: id)
             .update_all(default: false)
end
```
**Gotcha**: Setting any address as default automatically unsets all others - no manual coordination needed.

### **Gallery Modal Heavy Customization**
`Products::GalleryModalComponent` overrides most BaseComponent methods:
- Custom `container_classes`, `panel_classes`, `content_classes`
- Hides default header
- Uses `:center` position with `:full` size
- **Gotcha**: If you need heavy customization, you CAN override BaseComponent methods, but document why.

### **Modal Controller Auto-Registration**
BaseComponent automatically adds `data-controller="modal"` to all modals:
```ruby
def container_data_attributes
  controllers_list = ["modal"]
  controllers_list << additional_attrs.delete(:controller) if additional_attrs[:controller]

  { data: { controller: controllers_list.join(" "), ... } }
end
```
**Pattern**: Child components can add additional controllers via `data: { controller: "custom" }`, which merges with "modal".

### **Soft Delete Pattern**
Addresses use soft delete instead of hard delete:
```ruby
def soft_delete
  update(deleted_at: Time.current, default: false)
end

scope :active, -> { where(deleted_at: nil) }
```
**Gotcha**: Always use `.active` scope when querying addresses - `user.addresses` returns ALL including deleted.

### **Only Address Prevention**
Cannot delete user's last address:
```ruby
def only_address?
  user.addresses.active.count == 1
end

# In controller
if @address.only_address?
  # Return error via Turbo Stream
end
```
**Pattern**: Business rules enforced at controller level, communicated via Turbo Stream flash messages.

## Recommendations for Address Selection Modal

### **Option 1: Full Slot-Based Migration (RECOMMENDED)**

Refactor `Checkout::Modals::AddressModalComponent` to use slots:

```ruby
# app/components/checkout/modals/address_modal_component.rb
class Checkout::Modals::AddressModalComponent < Modal::BaseComponent
  def initialize(form:, city:, user: nil)
    @form = form
    @city = city
    @user = user
    super(
      id: "address-modal",
      title: modal_title,
      size: :medium,
      position: :right,
      data: modal_data_attributes
    )
  end

  # No content method - use slots instead
end
```

```erb
<!-- In parent view -->
<%= render Checkout::Modals::AddressModalComponent.new(...) do |modal| %>
  <% modal.with_body do %>
    <%= turbo_frame_tag "address-selection-ui" do %>
      <% if show_address_selector? %>
        <%= render "checkout/address_selection/list_view", ... %>
      <% else %>
        <%= render "checkout/address_selection/form_view", ... %>
      <% end %>
    <% end %>
  <% end %>

  <% modal.with_footer do %>
    <%= render button_component(...) %>
  <% end %>
<% end %>
```

**Benefits**:
- Consistent with cart modal pattern
- Clear separation between modal structure and content
- Easy to test modal and content independently
- Future-proof for ViewComponent evolution

### **Option 2: Enhanced Method-Based (ALTERNATIVE)**

Keep method-based approach but improve structure:

```ruby
def content
  turbo_frame_tag "address-selection-ui", data: { controller: "address-selector" } do
    if show_address_selector?
      render Addresses::SelectorListComponent.new(addresses: user_addresses, selected: selected_address)
    else
      render Addresses::FormComponent.new(address: new_address, context: :checkout)
    end
  end
end

def footer_content
  render Checkout::SubmitButtonComponent.new(text: "Bring it here", ...)
end
```

**Benefits**:
- Simpler refactor from current state
- Keeps conditional logic in component
- Still uses proper components instead of partials

### **View Switching Mechanism**

For switching between list and form within the modal:

**Option A: Turbo Frame Replacement (CURRENT)**
```javascript
// address_selector_controller.js
showNewAddressForm() {
  fetch('/addresses/new', { headers: { 'Turbo-Frame': 'address-selection-ui' } })
    .then(response => response.text())
    .then(html => {
      document.getElementById('address-selection-ui').innerHTML = html
    })
}
```

**Option B: Turbo Stream Replacement (RECOMMENDED)**
```ruby
# addresses_controller.rb
def new
  @address = Current.user.addresses.build

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "address-selection-ui",
        partial: "addresses/form",
        locals: { address: @address }
      )
    end
  end
end
```

**Option C: Client-Side Toggle (SIMPLEST)**
```erb
<div data-controller="view-switcher">
  <div data-view-switcher-target="list" class="hidden">
    <%= render list view %>
  </div>
  <div data-view-switcher-target="form" class="hidden">
    <%= render form view %>
  </div>
</div>
```

### **Recommended Approach**

**For Address Selection Modal with List/Form Switching:**

1. **Use Slot-Based Modal Architecture** (align with cart modal pattern)
2. **Turbo Frame for Content Switching** (current pattern works well)
3. **Separate Components for List and Form** (already exists: `Addresses::SelectorCardComponent`, `Addresses::FormComponent`)
4. **Stimulus Controller for Coordination** (enhance existing `address_selector_controller.js`)

**Why This Approach:**
- Leverages existing working patterns (Turbo Frames)
- Maintains consistency with rest of codebase (slot-based modals)
- Uses proven components (address form/selector cards)
- Minimal JavaScript complexity
- Server-side rendering for address management

**Implementation Steps:**
1. Refactor `AddressModalComponent` to use `with_body` slot
2. Move Turbo Frame content switching logic into slot body
3. Create "Add New Address" button that swaps Turbo Frame content
4. Use existing `Addresses::FormComponent` for new address form
5. Handle form submission via Turbo Stream to update list and close modal

### **Form Submission Pattern**

When submitting new address from modal:

```ruby
# addresses_controller.rb
def create
  @address = Current.user.addresses.build(address_params)

  if @address.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("address-selection-ui",
            partial: "checkout/address_selection/list_view",
            locals: { addresses: Current.user.addresses.active, selected: @address }
          ),
          turbo_stream.dispatch("address:selected", detail: { addressId: @address.id })
        ]
      end
    end
  end
end
```

**Pattern**: Create address, then replace modal content with updated list, auto-select new address.

## Other Relevant Documentation

### Internal Documentation
- `/.claude/docs/agents/shared/modal-system.md` - Complete modal system guide
- `/.claude/docs/agents/shared/form-system.md` - Form field component patterns
- `/.claude/docs/agents/viewcomponent-specialist.md` - ViewComponent best practices
- `/.claude/docs/implementations/address-modal-workflow.md` - Current address modal documentation
- `/CLAUDE.md` - Project structure and agent coordination

### External Resources
- [ViewComponent Documentation](https://viewcomponent.org/) - Official ViewComponent docs
- [Stimulus Handbook](https://stimulus.hotwired.dev/) - Stimulus patterns
- [Turbo Reference](https://turbo.hotwired.dev/) - Turbo Frames and Streams
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
