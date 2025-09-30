# Filter System Architecture

The filter functionality uses a **clean, single-controller approach** for maximum reliability and maintainability.

## Controller Structure

### 1. FilterController (Main Filter Handler)

- **Purpose**: Handles all filter functionality in one place
- **Responsibility**: Popup management, price range logic, filter state, URL handling
- **Location**: `app/javascript/controllers/filters/filter_controller.js`
- **API**: `openFilters()`, `closeFilters()`, `applyFilters()`, `resetFilters()`, `updateFilter()`, `updatePriceRange()`

### 2. SortDropdownController (Sort Functionality)

- **Purpose**: Handles sort dropdown interactions
- **Responsibility**: Dropdown toggle, option selection, form submission triggering
- **Location**: `app/javascript/controllers/sort_dropdown_controller.js`
- **API**: `toggle()`, `selectOption()`, `open()`, `close()`

### 3. AutoSubmitController (Form Auto-Submission)

- **Purpose**: Automatically submits forms when values change
- **Responsibility**: Preserves URL parameters and triggers form submission
- **Location**: `app/javascript/controllers/auto_submit_controller.js`
- **API**: `submit()`

## Organized File Structure

```
app/javascript/controllers/
├── filters/
│   └── filter_controller.js      # Main filter functionality
├── sort_dropdown_controller.js   # Sort dropdown
├── auto_submit_controller.js     # Auto form submission
└── [other organized controllers]
```

## Key Features

✅ **Complete Filter System**: Price range, checkboxes, in-stock toggle
✅ **Smooth Animations**: Popup slides in/out, no page reloads
✅ **Clean URL Management**: SEO-friendly URLs with backward compatibility
✅ **Turbo Frame Integration**: Seamless updates without full page refresh
✅ **Keyboard Navigation**: ESC key closes popup
✅ **Reset Functionality**: Clear all filters with one click

## URL Format Examples

### New Clean Format (SEO-Friendly)

```
/brands/charlotte-tilbury?price=8-46&type=lipstick,foundation&stock=1
/brands/charlotte-tilbury?price=10-50&brand=dior,chanel&color=red
```

### Legacy Format (Backward Compatible)

```
/brands/charlotte-tilbury?filters[price_range][min]=8&filters[price_range][max]=46
```

**Automatic Redirect:** Legacy URLs automatically redirect to clean format with `301 Moved Permanently`

## Filter Form Integration

### Rails Form Object

The filter system uses a form object pattern:

```ruby
class ProductFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :price_min, :integer
  attribute :price_max, :integer
  attribute :categories, array: true
  attribute :brands, array: true
  attribute :in_stock, :boolean

  def apply_to_scope(scope)
    scope = scope.where(price_cents: price_min_cents..price_max_cents) if price_range_present?
    scope = scope.where(category: categories) if categories.present?
    scope = scope.where(brand: brands) if brands.present?
    scope = scope.in_stock if in_stock.present?
    scope
  end
end
```

### URL Parameter Handling

```ruby
# In controller
def filter_params
  params.permit(:price, :stock, categories: [], brands: [], types: [])
end

def parse_price_range(price_param)
  return [nil, nil] if price_param.blank?

  min, max = price_param.split('-').map(&:to_i)
  [min, max]
end
```

## JavaScript Controller Patterns

### Main Filter Controller

```javascript
export default class extends Controller {
  static targets = ["popup", "form", "priceMin", "priceMax"]
  static values = {
    minPrice: Number,
    maxPrice: Number,
    currentFilters: Object
  }

  openFilters() {
    this.popupTarget.classList.remove('translate-x-full')
    this.popupTarget.classList.add('translate-x-0')
  }

  closeFilters() {
    this.popupTarget.classList.add('translate-x-full')
    this.popupTarget.classList.remove('translate-x-0')
  }

  updatePriceRange() {
    const min = this.priceMinTarget.value
    const max = this.priceMaxTarget.value
    this.updateHiddenFields({ price: `${min}-${max}` })
  }

  resetFilters() {
    this.formTarget.reset()
    this.submitForm()
  }
}
```

## Benefits

- **Reliable**: Single controller approach eliminates complex coordination issues
- **Maintainable**: All filter logic in one place, easy to understand and debug
- **Performant**: Turbo Frames prevent unnecessary page reloads
- **User-Friendly**: Smooth animations and preserved state
- **SEO-Friendly**: Clean URLs that work with back/forward navigation
- **Backward Compatible**: Legacy filter URLs still work with automatic redirection

## Testing Approach

### System Tests

```ruby
RSpec.describe "Product Filtering", type: :system do
  it "filters products by price range" do
    visit products_path

    click_button "Filter"
    fill_in "Min Price", with: "10"
    fill_in "Max Price", with: "50"
    click_button "Apply Filters"

    expect(page).to have_current_path("/products?price=10-50")
    expect(page).to have_css(".product-card", count: 5)
  end
end
```

### JavaScript Tests

```javascript
// Test filter controller interactions
describe("FilterController", () => {
  it("opens and closes filter popup", () => {
    const controller = application.getControllerForElementAndIdentifier(element, "filter")

    controller.openFilters()
    expect(popup.classList.contains("translate-x-0")).toBe(true)

    controller.closeFilters()
    expect(popup.classList.contains("translate-x-full")).toBe(true)
  })
})