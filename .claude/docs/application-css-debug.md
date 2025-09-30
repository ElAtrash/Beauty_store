@import "tailwindcss";

@import url("https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Noto+Sans+Arabic:wght@300;400;500;600;700&display=swap");

@theme {
  --color-interactive-primary: #f7583b;
  --color-interactive-secondary: #fbab9d;

  /* Text Color System - Centralized text colors */
  --color-text-primary: #100c08;
  /* Headings, important text */
  --color-text-secondary: #1f2937;
  /* Body text, labels */
  --color-text-muted: #4b5563;
  /* Secondary info */
  --color-text-subtle: #9ca3af;
  /* Placeholder, icons */
  --color-text-disabled: #d1d5db;
  /* Disabled states */
  --color-border-light: #e5e7eb;
  /* Light borders, equivalent to border-gray-200 */
  --color-black: #000000;
  /* Pure black for selections, borders */
  --color-white: #ffffff;
  /* Pure white for backgrounds, text on dark */

  /* Background Color System */
  --color-background-light: #f9fafb;
  /* Light background for subtle sections */
  --color-background-subtle: #d1d5db;
  /* Subtle background for disabled states */

  /* Z-Index Scale - Centralized layering system */
  /* Layer 0: Base content (1-9) */
  --z-base: 1;
  --z-dropdown: 10;
  --z-sticky: 20;

  /* Layer 1: Navigation (50-99) */
  --z-nav: 50;
  --z-header: 60;

  /* Layer 2: Overlays (100-199) */
  --z-overlay: 100;
  --z-mobile-menu: 110;
  --z-modal-overlay: 120;
  --z-modal: 130;
  --z-sidebar-popup: 140;

  /* Layer 3: Special Modals (200-299) */
  --z-gallery-modal: 200;

  /* Layer 4: System (300+) */
  --z-notification: 300;
  --z-toast: 310;
  --z-tooltip: 320;

  --thumb-size: 68px;
  --thumb-gap: 8px;

  /* Cart & Button Design Tokens */
  --cart-icon-size: 1.5rem;
  /* 24px - for cart action icons like heart, plus, minus */
  --cart-button-icon-size: 1.25rem;
  /* 20px - for icons inside cart buttons */

  --font-family-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-family-arabic: "Noto Sans Arabic", "Inter", ui-sans-serif, system-ui, sans-serif;
}

@layer base {
  html {
    margin: 0;
    padding: 0;
  }

  body {
    font-family: var(--font-family-sans);
    color: var(--color-text-primary);
    font-weight: 400;
    line-height: 1.6;
    padding-top: 72px;
  }

  .rtl body {
    font-family: var(--font-family-arabic);
  }

  .rtl {
    direction: rtl;
    text-align: right;
  }

  .rtl .ltr-content {
    direction: ltr;
    text-align: left;
  }

  .rtl .space-x-2>*+* {
    margin-left: 0;
    margin-right: 0.5rem;
  }

  .rtl .space-x-4>*+* {
    margin-left: 0;
    margin-right: 1rem;
  }

  .rtl .space-x-8>*+* {
    margin-left: 0;
    margin-right: 2rem;
  }

  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    color: var(--color-text-secondary);
    font-weight: 600;
    line-height: 1.3;
  }
}

@layer components {

  /* Delivery Schedule Components */
  .date-button {
    min-width: 60px;
    height: 70px;
    border: 2px solid transparent;
    background: white;
    color: #374151;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 2px;
    transition: all 0.2s ease;
    cursor: pointer;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .date-button:hover:not(:disabled) {
    background: #f3f4f6;
    border-color: #d1d5db;
  }

  .date-button.selected {
    background: #1f2937;
    color: white;
    border-color: #1f2937;
  }

  .date-button:disabled {
    background: #f9fafb;
    color: #9ca3af;
    cursor: not-allowed;
    opacity: 0.5;
  }

  .time-button {
    padding: 12px 16px;
    border-radius: 8px;
    border: 2px solid #e5e7eb;
    background: white;
    color: #374151;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s ease;
    cursor: pointer;
    white-space: nowrap;
  }

  .time-button:hover:not(:disabled) {
    background: #f3f4f6;
    border-color: #d1d5db;
  }

  .time-button.selected {
    background: #1f2937;
    color: white;
    border-color: #1f2937;
  }

  .time-button:disabled {
    background: #f9fafb;
    color: #9ca3af;
    cursor: not-allowed;
    opacity: 0.5;
  }

  /* Color Circle Components */
  .color-circle {
    width: 1.25rem;
    height: 1.25rem;
    border-radius: 50%;
    border: 1px solid var(--color-border-light);
    flex-shrink: 0;
    transition: all 0.2s ease-in-out;
    position: relative;
    background-color: var(--selected-color, transparent);
  }

  /* Placeholder state for color circle */
  .color-circle--placeholder {
    background-color: transparent !important;
    border: 2px dashed var(--color-text-disabled) !important;
  }

  /* Color circle hover state */
  .color-circle:hover {
    transform: scale(1.1);
    border-color: var(--color-text-muted);
  }

  /* Mobile responsiveness for color circles */
  @media (max-width: 640px) {
    .color-circle {
      width: 1rem;
      height: 1rem;
    }
  }

  /* Scrollbar */
  .scrollbar-thin {
    scrollbar-width: thin;
    scrollbar-color: rgb(203 213 225) transparent;
  }

  .scrollbar-thin::-webkit-scrollbar-thumb {
    background-color: rgb(203 213 225);
    border-radius: 3px;
    border: none;
  }

  .scrollbar-thin::-webkit-scrollbar-thumb:hover {
    background-color: rgb(148 163 184);
  }

  /* Secondary button */
  .btn-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    font-weight: 600;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: all 200ms ease-in-out;
    padding: 0.5rem 1rem;
    background-color: white;
    border: 1px solid #d1d5db;
    color: var(--color-text-secondary);
    cursor: pointer;
  }

  .btn-secondary:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgba(107, 114, 128, 0.5), 0 0 0 4px rgba(107, 114, 128, 0.2);
  }

  .btn-secondary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
    background-color: #f9fafb;
    border-color: #9ca3af;
  }

  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  /* Interactive button - black with orange hover */
  .btn-interactive {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    font-weight: 600;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: all 200ms ease-in-out;
    padding: 0.5rem 1rem;
    background-color: var(--color-text-primary);
    color: white;
    border: none;
    cursor: pointer;
  }

  .btn-interactive:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgba(247, 88, 59, 0.5), 0 0 0 4px rgba(247, 88, 59, 0.2);
  }

  .btn-interactive:hover:not(:disabled) {
    background-color: var(--color-interactive-primary);
  }

  .btn-interactive:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  /* Button size modifiers */
  .btn-lg {
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    line-height: 1.5rem;
  }

  /* Full width modifier */
  .btn-full {
    width: 100%;
  }

  /* Legacy button classes - maintained for compatibility */
  .btn-show-more {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    font-weight: 600;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: all 200ms ease-in-out;
    background-color: black;
    color: white;
    padding: 0.75rem 2rem;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    border: none;
    cursor: pointer;
  }

  .btn-show-more:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgba(0, 0, 0, 0.5), 0 0 0 4px rgba(0, 0, 0, 0.2);
  }

  .btn-show-more:hover:not(:disabled) {
    background-color: #374151;
  }

  .btn-show-more:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  @media (min-width: 768px) {
    .btn-show-more {
      padding: 1rem 3rem;
    }
  }

  /* Filter Toggle Button */
  .filter-toggle-button {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 1rem;
    line-height: 1.5rem;
    font-weight: 700;
    transition: color 200ms ease-in-out;
    color: var(--color-text-secondary);
    background: none;
    border: none;
    cursor: pointer;
  }

  .filter-toggle-button:hover {
    color: var(--color-interactive-primary);
  }

  /* Sort Dropdown Button */
  .sort-dropdown-button {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 1rem;
    line-height: 1.5rem;
    font-weight: 700;
    transition: color 200ms ease-in-out;
    color: var(--color-text-secondary);
    background: none;
    border: none;
    cursor: pointer;
  }

  .sort-dropdown-button:hover {
    color: var(--color-interactive-primary);
  }

  /* Sort Dropdown Menu */
  .sort-dropdown-menu {
    position: absolute;
    top: 100%;
    margin-top: 0.5rem;
    right: 0;
    width: 16rem;
    background-color: white;
    border-radius: 0.5rem;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
    border: 1px solid #e5e7eb;
    padding: 0.25rem 0;
    z-index: var(--z-dropdown);
    opacity: 0;
    visibility: hidden;
    transform: scale(0.95);
    transition: all 200ms ease-in-out;
    transform-origin: top right;
  }

  /* Dropdown menus */
  .color-dropdown-menu,
  .brand-dropdown-menu {
    z-index: var(--z-dropdown);
  }

  /* Close buttons in modals */
  .modal-close-button {
    z-index: var(--z-dropdown);
  }

  .sort-dropdown-menu.show {
    opacity: 1;
    visibility: visible;
    transform: scale(1);
  }

  .sort-dropdown-item {
    width: 100%;
    text-align: left;
    padding: 0.75rem 1rem;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: colors 150ms ease-in-out;
    color: var(--color-text-secondary);
    display: flex;
    align-items: center;
    justify-content: space-between;
    background: none;
    border: none;
    cursor: pointer;
  }

  .sort-dropdown-item:hover {
    background-color: #f9fafb;
  }

  .sort-dropdown-item.active {
    background-color: var(--color-interactive-light);
    color: var(--color-interactive-dark);
    font-weight: 500;
  }

  .sort-dropdown-item:first-child {
    border-top-left-radius: 0.5rem;
    border-top-right-radius: 0.5rem;
  }

  .sort-dropdown-item:last-child {
    border-bottom-left-radius: 0.5rem;
    border-bottom-right-radius: 0.5rem;
  }

  .product-tab-button {
    white-space: nowrap;
    padding: 1rem 0.25rem;
    border-bottom: 2px solid transparent;
    font-weight: 500;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: color 0.2s ease-in-out, border-color 0.2s ease-in-out;
    color: var(--color-text-muted);
  }

  .product-tab-button:hover {
    color: var(--color-text-secondary);
  }

  .product-tab-panel {
    display: none;
  }

  .product-tab-panel.active {
    display: block;
  }

  .btn-icon-light {
    padding: 0.5rem;
    border-radius: 50%;
    transition: colors 200ms ease-in-out;
    background: none;
    border: none;
    cursor: pointer;
  }

  .btn-icon-light:hover {
    background-color: #f3f4f6;
  }

  /* Form Components */
  .form-input {
    width: 100%;
    padding: 0.5rem 0.75rem;
    border: 1px solid #d1d5db;
    transition: border-color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
  }

  .form-input:focus {
    outline: none;
    border-color: var(--color-cyan-primary);
    box-shadow: 0 0 0 3px rgba(6, 182, 212, 0.1);
  }

  .form-checkbox {
    height: 1rem;
    width: 1rem;
    color: var(--color-interactive-primary);
    border-color: var(--color-text-disabled);
  }

  .form-field-error {
    border-color: #fca5a5;
  }

  .form-field-error:focus {
    border-color: #ef4444;
    box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
  }

  .form-field-valid {
    border-color: #86efac;
  }

  .form-field-valid:focus {
    border-color: #22c55e;
    box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
  }

  .error-message {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    color: #dc2626;
    font-size: 0.75rem;
    line-height: 1rem;
    margin-top: 0.25rem;
    transition: all 200ms ease-in-out;
  }

  .success-message {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    color: #16a34a;
    font-size: 0.75rem;
    line-height: 1rem;
    margin-top: 0.25rem;
    transition: all 200ms ease-in-out;
  }

  /* Rating Components */
  .rating-component {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .rating-stars {
    display: flex;
    align-items: center;
    gap: 0.125rem;
  }

  /* Rating Star Base */
  .rating-stars svg.rating-star {
    transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
    display: inline-block;
    flex-shrink: 0;
    vertical-align: top;
  }

  /* Half Star Container */
  .rating-stars .rating-half-star-container {
    display: inline-block;
    position: relative;
    width: 1rem;
    height: 1rem;
  }

  .rating-stars .rating-half-star-container svg.rating-star {
    position: absolute;
    top: 0;
    left: 0;
    width: 1rem;
    height: 1rem;
  }

  .rating-stars .rating-half-star-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 50%;
    height: 100%;
    overflow: hidden;
  }

  /* Compact half-star container */
  .rating-component--compact .rating-stars .rating-half-star-container {
    width: 0.75rem;
    height: 0.75rem;
  }

  .rating-component--compact .rating-stars .rating-half-star-container svg.rating-star {
    width: 0.75rem;
    height: 0.75rem;
  }

  /* Star Type Variants */
  .rating-stars svg.rating-star--full {
    fill: var(--color-black);
    color: var(--color-black);
    width: 1rem;
    height: 1rem;
  }

  .rating-stars svg.rating-star--half {
    fill: var(--color-black);
    color: var(--color-black);
    width: 1rem;
    height: 1rem;
  }

  .rating-stars svg.rating-star--empty {
    color: var(--color-text-disabled);
    width: 1rem;
    height: 1rem;
  }

  /* Compact Size Variant */
  .rating-component--compact .rating-stars svg.rating-star--full,
  .rating-component--compact .rating-stars svg.rating-star--half,
  .rating-component--compact .rating-stars svg.rating-star--empty {
    width: 0.75rem;
    height: 0.75rem;
  }

  .rating-text {
    font-size: 0.875rem;
    line-height: 1.25rem;
    font-weight: 500;
    color: var(--color-text-secondary);
    transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
  }

  .rating-count {
    font-size: 0.875rem;
    line-height: 1.25rem;
    color: var(--color-text-muted);
    transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
  }

  /* Product Layout Components */
  .product-layout {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    padding-left: 1rem;
    padding-right: 1rem;
  }

  .product-gallery-section {
    width: 100%;
  }

  .product-info-section {
    width: 100%;
  }

  /* Product info container - used by ProductInfoComponent and gallery modal */
  .product-info-container {
    width: 100%;
    max-width: none;
  }

  /* Tablet Layout: Medium screens */
  @media (min-width: 768px) and (max-width: 1023px) {
    .product-layout {
      gap: 3rem;
    }

    .product-info-section {
      padding-left: 2rem;
      padding-right: 2rem;
      max-width: 28rem;
      margin-left: auto;
      margin-right: auto;
    }
  }

  /* Desktop Layout: Asymmetric Flex */
  @media (min-width: 1024px) {
    .product-layout {
      flex-direction: row;
      align-items: flex-start;
      gap: 0;
      padding-left: 0;
      padding-right: 0;
    }

    .product-gallery-section {
      flex: 0 0 auto;
      max-width: 60%;
      padding-left: 0;
    }

    .product-info-section {
      flex: 1;
      max-width: 42rem;
      padding-left: 4rem;
      padding-right: 5rem;
    }
  }

  /* Extra Large Screens: Prevent excessive stretching */
  @media (min-width: 1536px) {
    .product-gallery-section {
      max-width: 55%;
    }

    .product-info-section {
      max-width: 48rem;
      padding-left: 5rem;
      padding-right: 6rem;
    }
  }

  /* Size/Volume Selection */
  .size-option {
    width: 3.125rem;
    height: 3.125rem;
    border-width: 2px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.875rem;
    font-weight: 500;
    transition-property: all;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
    position: relative;
    overflow: hidden;
  }

  .size-option:hover {
    border-color: var(--color-text-muted);
  }

  .size-option--available {
    border-color: var(--color-text-disabled);
    cursor: pointer;
  }

  .size-option--unavailable {
    border-color: var(--color-text-disabled);
    background-color: var(--color-background-light);
    color: var(--color-text-subtle);
    cursor: pointer;
  }

  .size-option--unavailable:hover {
    border-color: var(--color-text-disabled);
    background-color: var(--color-background-light);
  }

  .size-option--selected {
    border-color: var(--color-black);
  }

  .size-option--selected:hover {
    border-color: var(--color-black);
  }

  /* Ensure peer-checked state applies selected styling with higher specificity */
  .peer:checked~.size-option {
    border-color: var(--color-black) !important;
  }

  .peer:checked~.size-option:hover {
    border-color: var(--color-black) !important;
  }

  /* Focus states for accessibility */
  .size-option--available:focus-visible {
    outline: 2px solid var(--color-interactive-primary);
    outline-offset: 2px;
  }

  /* Mobile responsiveness for size options */
  @media (max-width: 640px) {
    .size-option {
      width: 2.75rem;
      height: 2.75rem;
      font-size: 0.75rem;
    }
  }

  /* Color Dropdown */
  .color-dropdown-button {
    width: 100%;
    max-width: 22.5rem;
    height: 3.125rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding-left: 1rem;
    padding-right: 1rem;
    background-color: var(--color-white);
    border-bottom-width: 1.5px;
    border-color: var(--color-text-interactive);
    transition-property: border-color;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
  }

  /* Color dropdown menu */
  .color-dropdown-menu {
    max-width: 22.5rem;
  }

  /* Mobile responsiveness for color dropdown */
  @media (max-width: 640px) {
    .color-dropdown-button {
      height: 2.75rem;
      padding-left: 0.75rem;
      padding-right: 0.75rem;
      font-size: 0.875rem;
    }

    .color-dropdown-menu {
      max-width: 100%;
    }
  }

  /* Color dropdown menu enhancements */
  .color-dropdown-menu-item {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    padding: 0.75rem 1rem;
    min-height: 3rem;
  }

  /* Base styles for all color circles and text */
  .color-dropdown-menu-item span {
    color: var(--color-text-primary);
    transition: color 0.2s ease;
  }

  .color-dropdown-menu-item .color-circle {
    border: 1px solid var(--color-text-disabled);
    transition: border-color 0.2s ease;
  }

  /* Base hover states for all items */
  .color-dropdown-menu-item.group:hover span {
    color: var(--color-interactive-primary);
  }

  .color-dropdown-menu-item.group:hover .color-circle {
    border-color: var(--color-interactive-primary);
  }

  /* OUT-OF-STOCK STYLES - Higher specificity overrides */
  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock:hover {
    background-color: transparent;
  }

  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock span {
    color: var(--color-text-muted);
  }

  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock .color-circle {
    width: 1.25rem;
    height: 1.25rem;
    border: 1.5px solid var(--color-text-disabled);
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: transparent;
  }

  /* Inner colored circle for out-of-stock items */
  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock .color-circle::before {
    content: '';
    width: 0.75rem;
    height: 0.75rem;
    border-radius: 50%;
    background-color: var(--selected-color, currentColor);
    position: absolute;
  }

  /* Out-of-stock hover states - Highest specificity */
  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock.group:hover span {
    color: var(--color-interactive-primary);
  }

  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock.group:hover .color-circle {
    border-color: var(--color-interactive-primary);
  }

  /* Strikethrough effect for out-of-stock color circles */
  .color-circle--out-of-stock::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    height: 1.5px;
    background-color: var(--color-text-disabled);
    transform: translateY(-50%) rotate(45deg);
    transition: background-color 0.2s ease;
  }

  /* Strikethrough hover effect */
  .color-dropdown-menu-item.color-dropdown-menu-item--out-of-stock.group:hover .color-circle--out-of-stock::after {
    background-color: var(--color-interactive-primary);
  }

  /* Action Buttons */
  .product-actions {
    display: flex;
    gap: 0.75rem;
    max-width: 22.5rem;
  }

  .add-to-cart-button {
    display: flex;
    align-items: center;
    justify-content: center;
    flex: 1;
    height: 3.125rem;
    /* 50px */
    padding-left: 2rem;
    padding-right: 2rem;
    font-weight: 500;
    transition-property: all;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
    background-color: var(--color-black);
    color: var(--color-white);
  }

  .add-to-cart-button:hover:not(:disabled) {
    background-color: var(--color-interactive-primary);
  }

  .add-to-cart-button:disabled {
    background-color: var(--color-background-subtle);
    cursor: not-allowed;
  }

  .wishlist-button {
    flex-shrink: 0;
    width: 3.125rem;
    height: 3.125rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition-property: all;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 0.2s;
    background-color: var(--color-black);
    color: var(--color-white);
  }

  .wishlist-button:hover {
    background-color: var(--color-interactive-primary);
  }

  /* Mobile responsiveness for action buttons */
  @media (max-width: 640px) {
    .product-actions {
      max-width: none;
      gap: 0.5rem;
    }

    .add-to-cart-button {
      height: 2.75rem;
      padding-left: 1rem;
      padding-right: 1rem;
      font-size: 0.875rem;
    }

    .product-actions[data-cart-state="quantity"] .quantity-controls {
      height: 2.75rem;
      padding-left: 1rem;
      padding-right: 1rem;
      font-size: 0.875rem;
    }

    .wishlist-button {
      width: 2.75rem;
      height: 2.75rem;
    }
  }

  .product-card {
    background-color: white;
    transition: all 200ms ease-in-out;
    position: relative;
    overflow: hidden;
  }

  .product-card:hover {
    transform: translateY(-4px);
  }

  /* Product Card Hover Effects */
  .product-wishlist-button {
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 200ms ease-in-out;
    color: var(--color-text-muted);
    background: none;
    border: none;
    cursor: pointer;
  }

  .product-wishlist-button:hover {
    color: var(--color-interactive-primary);
  }

  .product-wishlist-button:hover svg {
    fill: var(--color-interactive-primary);
  }

  .category-card {
    background-color: white;
    border-radius: 0.5rem;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
    border: 1px solid #f3f4f6;
    transition: all 200ms ease-in-out;
    padding: 1.5rem;
    text-align: center;
  }

  .category-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  }

  .brand-card {
    background-color: white;
    border-radius: 0.5rem;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
    border: 1px solid #e5e7eb;
    transition: all 200ms ease-in-out;
    padding: 1.5rem;
  }

  .brand-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  }

  .brand-card:hover .brand-card-arrow {
    color: var(--color-interactive-primary);
  }

  .brand-card-arrow {
    display: flex;
    justify-content: flex-end;
    margin-top: 1rem;
    transition: color 200ms ease-in-out;
    color: var(--color-text-subtle);
  }

  .brand-category-card {
    background-color: white;
    border-radius: 1rem;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
    border: 1px solid #f3f4f6;
    transition: all 200ms ease-in-out;
    padding: 1.5rem;
  }

  .brand-category-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  }

  .brand-category-card:hover .category-icon {
    transform: scale(1.1);
  }

  /* Icon Containers */
  .category-icon {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
    transition: all 300ms ease-in-out;
  }

  .category-icon-container {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1rem auto;
  }

  .icon-container-sm {
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icon-container-md {
    width: 3rem;
    height: 3rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icon-container-lg {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* Reusable SVG icon utility class for interactive icons */
  .icon-interactive {
    color: var(--color-text-primary);
    transition: color 0.2s ease;
  }

  .icon-interactive:hover {
    color: var(--color-interactive-primary);
  }

  /* For buttons containing SVG icons - hover applies to icon when button is hovered */
  .btn-icon .icon-interactive:hover,
  .btn-icon:hover .icon-interactive {
    color: var(--color-interactive-primary);
  }

  /* Quantity control buttons */
  .qty-btn {
    background-color: var(--color-background-light);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
  }

  .qty-btn:hover {
    background-color: color-mix(in oklch, var(--color-interactive-secondary) 60%, transparent);
  }

  /* Smaller quantity buttons (- and +) */
  .qty-btn--small {
    width: 1.5rem;
    height: 1.5rem;
  }

  /* Remove button specific hover effect */
  .qty-btn[title="Remove item"]:hover {
    background-color: color-mix(in oklch, var(--color-interactive-primary) 15%, transparent);
  }

  .products-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    column-gap: 1rem;
    row-gap: 2rem;
  }

  @media (min-width: 768px) {
    .products-grid {
      grid-template-columns: repeat(3, minmax(0, 1fr));
      column-gap: 1.5rem;
      row-gap: 3rem;
    }
  }

  @media (min-width: 1024px) {
    .products-grid {
      grid-template-columns: repeat(4, minmax(0, 1fr));
    }
  }

  .section-title {
    font-size: 1.5rem;
    line-height: 2rem;
    font-weight: 700;
    text-align: center;
    margin-bottom: 2rem;
    color: var(--color-text-primary);
  }

  @media (min-width: 768px) {
    .section-title {
      font-size: 1.875rem;
      line-height: 2.25rem;
      margin-bottom: 3rem;
    }
  }

  .hero-title {
    font-size: 1.875rem;
    line-height: 2.25rem;
    font-weight: 700;
    margin-bottom: 1rem;
  }

  @media (min-width: 768px) {
    .hero-title {
      font-size: 3rem;
      line-height: 1;
      margin-bottom: 1.5rem;
    }
  }

  @media (min-width: 1024px) {
    .hero-title {
      font-size: 4.5rem;
    }
  }

  .hero-subtitle {
    font-size: 1.125rem;
    line-height: 1.75rem;
    margin-bottom: 1.5rem;
    max-width: 42rem;
    margin-left: auto;
    margin-right: auto;
  }

  @media (min-width: 768px) {
    .hero-subtitle {
      font-size: 1.25rem;
      line-height: 1.75rem;
      margin-bottom: 2rem;
    }
  }

  @media (min-width: 1024px) {
    .hero-subtitle {
      font-size: 1.5rem;
      line-height: 2rem;
    }
  }

  .brand-name {
    font-size: 1.125rem;
    line-height: 1.75rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: var(--color-text-primary);
  }

  .brand-products-count {
    font-size: 0.875rem;
    line-height: 1.25rem;
    margin-bottom: 0.5rem;
    color: var(--color-text-muted);
  }

  .brand-description {
    font-size: 0.875rem;
    line-height: 1.625;
    color: var(--color-text-muted);
  }

  .letter-heading {
    font-size: 3rem;
    font-weight: 700;
    color: transparent;
    background-clip: text;
    background-image: linear-gradient(to right, var(--color-interactive-secondary), var(--color-interactive-primary));
  }

  /* Header Wrapper - Container for the entire header system */
  .header-wrapper {
    position: relative;
    z-index: var(--z-header);
  }

  /* Base Header Styles - Always visible and properly positioned */
  .header-wrapper .site-header {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    height: var(--header-height);
    z-index: var(--z-header);
    display: block;
    visibility: visible;
    opacity: 1;
  }

  /* Fallback for when no state is set (JS-disabled) - but not on homepage */
  .header-wrapper .site-header:not([data-header-state]):not([data-header-context="default"]) {
    background-color: var(--header-bg-fallback);
    backdrop-filter: var(--header-blur-medium);
    -webkit-backdrop-filter: var(--header-blur-medium);
  }

  :root {
    /* Animation and timing */
    --header-transition-duration: 300ms;
    --header-transition-easing: ease;
    --header-height: 72px;

    /* Background colors - semantic naming */
    --header-bg-transparent: transparent;
    --header-bg-white: rgb(255, 255, 255);
    --header-bg-fallback: rgba(255, 255, 255, 0.95);
    /* JS disabled fallback */
    --header-bg-glass: rgba(255, 255, 255, 0.8);
    /* Standard transparent state */

    /* Backdrop filters - performance optimized values */
    --header-blur-none: none;
    --header-blur-light: blur(2px);
    /* Subtle effect */
    --header-blur-medium: blur(8px);
    /* Standard glass effect */

    /* Brand specific backgrounds */
    --brand-gradient: linear-gradient(to right, rgb(249, 250, 251), rgb(243, 244, 246));
  }

  .header-wrapper .site-header,
  .navigation-wrapper,
  .header-wrapper .site-header[data-header-state],
  .navigation-wrapper[data-header-state] {
    border-bottom: none !important;
    border-top: none !important;
    transition: background var(--header-transition-duration) var(--header-transition-easing),
      backdrop-filter var(--header-transition-duration) var(--header-transition-easing);
  }

  /* Force homepage and brand pages header and navigation to be transparent in all non-hover/scroll states */
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .site-header,
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .navigation-wrapper,
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .site-header,
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .navigation-wrapper {
    background-color: var(--header-bg-transparent) !important;
    backdrop-filter: var(--header-blur-none) !important;
    -webkit-backdrop-filter: var(--header-blur-none) !important;
  }

  /* Override only when explicitly in hover/scrolled states */
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .site-header[data-header-state="hovered"],
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .navigation-wrapper[data-header-state="hovered"],
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .site-header[data-header-state="scrolled"],
  .header-wrapper[data-navigation--header-state-page-type-value="home"] .navigation-wrapper[data-header-state="scrolled"],
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .site-header[data-header-state="hovered"],
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .navigation-wrapper[data-header-state="hovered"],
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .site-header[data-header-state="scrolled"],
  .header-wrapper[data-navigation--header-state-page-type-value="brand"] .navigation-wrapper[data-header-state="scrolled"] {
    background-color: var(--header-bg-white) !important;
    backdrop-filter: var(--header-blur-none) !important;
    -webkit-backdrop-filter: var(--header-blur-none) !important;
  }

  .navigation-wrapper {
    position: relative;
    z-index: calc(var(--z-header) - 1);
    display: none;
  }

  @media (min-width: 768px) {
    .header-wrapper .navigation-wrapper {
      display: block !important;
      position: relative;
      z-index: calc(var(--z-header) - 1);
    }
  }

  /* Transparent State - General case (other pages) - Glass effect */
  .header-wrapper .site-header[data-header-state="transparent"]:not([data-header-context="default"]):not([data-header-context="brand-gradient"]):not([data-header-context="brand-image"]),
  .navigation-wrapper[data-header-state="transparent"]:not([data-header-context="default"]):not([data-header-context="brand-gradient"]):not([data-header-context="brand-image"]) {
    background-color: var(--header-bg-glass) !important;
    backdrop-filter: var(--header-blur-medium) !important;
    -webkit-backdrop-filter: var(--header-blur-medium) !important;
  }

  /* Scrolled/Hovered/White States - Solid white background */
  .header-wrapper .site-header[data-header-state="scrolled"],
  .header-wrapper .site-header[data-header-state="hovered"],
  .header-wrapper .site-header[data-header-state="white"],
  .navigation-wrapper[data-header-state="scrolled"],
  .navigation-wrapper[data-header-state="hovered"],
  .navigation-wrapper[data-header-state="white"] {
    background-color: var(--header-bg-white) !important;
    background-image: none !important;
    backdrop-filter: var(--header-blur-none) !important;
    -webkit-backdrop-filter: var(--header-blur-none) !important;
  }

  /* Brand Gradient Context - individual backgrounds with synchronized timing */
  .header-wrapper .site-header[data-header-state="transparent"][data-header-context="brand-gradient"],
  .navigation-wrapper[data-header-state="transparent"][data-header-context="brand-gradient"] {
    background: var(--brand-gradient);
    backdrop-filter: var(--header-blur-none);
    -webkit-backdrop-filter: var(--header-blur-none);
  }

  /* Brand Image Context - individual backgrounds with synchronized timing */
  .header-wrapper .site-header[data-header-state="transparent"][data-header-context="brand-image"],
  .navigation-wrapper[data-header-state="transparent"][data-header-context="brand-image"] {
    background-image: var(--header-banner-url);
    background-size: cover;
    background-position: center center;
    background-repeat: no-repeat;
    background-attachment: fixed;
    backdrop-filter: var(--header-blur-none);
    -webkit-backdrop-filter: var(--header-blur-none);
  }

  /* Brand contexts - white backgrounds when hovered/scrolled */
  .header-wrapper .site-header[data-header-state="hovered"][data-header-context="brand-gradient"],
  .header-wrapper .site-header[data-header-state="scrolled"][data-header-context="brand-gradient"],
  .navigation-wrapper[data-header-state="hovered"][data-header-context="brand-gradient"],
  .navigation-wrapper[data-header-state="scrolled"][data-header-context="brand-gradient"],
  .header-wrapper .site-header[data-header-state="hovered"][data-header-context="brand-image"],
  .header-wrapper .site-header[data-header-state="scrolled"][data-header-context="brand-image"],
  .navigation-wrapper[data-header-state="hovered"][data-header-context="brand-image"],
  .navigation-wrapper[data-header-state="scrolled"][data-header-context="brand-image"] {
    background-color: var(--header-bg-white);
    background-image: none;
    backdrop-filter: var(--header-blur-none);
    -webkit-backdrop-filter: var(--header-blur-none);
  }

  /* Checkout and static pages - always white, no dynamic states */
  .header-wrapper[data-navigation--header-state-page-type-value="checkout"] .site-header,
  .header-wrapper[data-navigation--header-state-page-type-value="page"] .site-header {
    background-color: rgb(255, 255, 255);
    background-image: none;
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  }

  .header-wrapper[data-navigation--header-state-page-type-value="checkout"] .navigation-wrapper,
  .header-wrapper[data-navigation--header-state-page-type-value="page"] .navigation-wrapper {
    background-color: rgb(255, 255, 255);
    background-image: none;
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  }

  /* Disable hover effects for checkout and regular pages */
  .header-wrapper[data-navigation--header-state-page-type-value="checkout"]:hover .site-header,
  .header-wrapper[data-navigation--header-state-page-type-value="page"]:hover .site-header {
    background-color: rgb(255, 255, 255);
    background-image: none;
  }

  .header-wrapper[data-navigation--header-state-page-type-value="checkout"]:hover .navigation-wrapper,
  .header-wrapper[data-navigation--header-state-page-type-value="page"]:hover .navigation-wrapper {
    background-color: rgb(255, 255, 255);
    background-image: none;
  }

  /* Language Button Styles */
  .header-language-btn {
    transition: color 200ms ease-in-out;
    background: transparent;
    border: none;
    padding: 0;
    color: inherit;
    font-family: inherit;
    cursor: pointer;
    font-size: 0.875rem;
    line-height: 1.25rem;
    appearance: none;
  }

  .header-language-btn:hover {
    color: var(--color-interactive-primary);
  }

  .header-language-btn--active {
    font-weight: 700;
    color: var(--color-interactive-primary);
  }

  /* Navigation Link Styles */
  .header-nav-link {
    transition: color 200ms ease-in-out;
    font-weight: 500;
    cursor: pointer;
    text-decoration: none;
  }

  .header-nav-link:hover {
    color: var(--color-interactive-primary);
  }

  .header-action-button {
    padding: 0.5rem;
    border-radius: 50%;
    transition: color 0.2s;
    position: relative;
  }

  .notification-badge {
    position: absolute;
    top: -0.25rem;
    right: -0.25rem;
    background-color: var(--color-interactive-primary);
    color: white !important;
    font-size: 0.75rem;
    border-radius: 50%;
    width: 1.25rem;
    height: 1.25rem;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .alphabet-navigation {
    border-bottom: 1px solid #e5e7eb;
    background-color: #f9fafb;
  }

  .alphabet-letter-btn {
    position: relative;
    display: inline-flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    font-weight: 500;
    font-size: 0.75rem;
    line-height: 1rem;
    transition: all 200ms ease-in-out;
    border: 1px solid transparent;
    background-color: white;
    color: var(--color-text-muted);
    cursor: pointer;
  }

  .alphabet-letter-btn:hover {
    background-color: #f9fafb;
    border-color: #e5e7eb;
  }

  .alphabet-letter-btn.active {
    background-image: linear-gradient(to right, #14b8a6, var(--color-interactive-primary));
    color: white;
    border-color: transparent;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .alphabet-letter-btn.available {
    color: var(--color-interactive-primary);
    border-color: var(--color-interactive-100);
  }

  .alphabet-letter-btn.disabled {
    cursor: not-allowed;
    color: var(--color-text-disabled);
  }

  .alphabet-letter-btn.disabled:hover {
    background-color: white;
    border-color: transparent;
    color: var(--color-text-disabled);
  }

  .brand-count {
    position: absolute;
    top: -0.25rem;
    right: -0.25rem;
    font-size: 0.75rem;
    line-height: 1rem;
    background-color: #f3f4f6;
    border-radius: 50%;
    padding: 0 0.25rem;
    min-width: 1rem;
    height: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    line-height: 1;
    color: var(--color-text-muted);
  }

  .alphabet-letter-btn.active .brand-count {
    background-color: white;
    color: var(--color-interactive-primary);
  }

  .alphabet-letter-btn.disabled .brand-count {
    background-color: #f9fafb;
    color: var(--color-text-disabled);
  }

  .mobile-menu-item {
    width: 100%;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem;
    text-align: left;
    border-radius: 0.5rem;
    transition: color 200ms ease-in-out;
    color: var(--color-text-secondary);
    background: none;
    border: none;
    cursor: pointer;
  }

  .mobile-menu-item:hover {
    background-color: #f9fafb;
  }

  .mobile-menu-toggle {
    padding: 0.5rem;
    transition: color 200ms ease-in-out;
    background: none;
    border: none;
    cursor: pointer;
  }

  .mobile-menu-overlay {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    transition: opacity 300ms ease-in-out;
    top: 72px;
    z-index: var(--z-overlay);
  }

  .mobile-menu-panel {
    position: fixed;
    left: 0;
    right: 0;
    background-color: white;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    transform: translateX(0);
    transition: transform 300ms ease-in-out;
    top: 72px;
    height: calc(100vh - 72px);
    z-index: var(--z-mobile-menu);
  }

  /* Mobile Menu State Management */
  [data-mobile-menu="closed"] .mobile-menu-overlay {
    opacity: 0;
    pointer-events: none;
  }

  [data-mobile-menu="closed"] .mobile-menu-panel {
    transform: translateX(-100%);
  }

  [data-mobile-menu="open"] .mobile-menu-overlay {
    opacity: 1;
    pointer-events: auto;
  }

  [data-mobile-menu="open"] .mobile-menu-panel {
    transform: translateX(0);
  }

  [data-mobile-menu="open"] body {
    overflow: hidden;
  }

  /* Popup container - hidden by default */
  /* Modal base styles - leveraging Tailwind utilities where possible */
  /* Most styling now handled by Modal::BaseComponent classes */

  /* Modal state transitions - clean and reliable */

  /* Basic modal visibility */
  .modal-closed {
    display: none;
  }

  .modal-open {
    display: block;
  }

  /* All modal animations now handled directly by JavaScript with Tailwind utility classes */

  /* Modal panel styles removed - now handled by Tailwind utilities in Modal::BaseComponent */

  /* Modal open/close states handled by JavaScript and Tailwind utilities */

  /* Body scroll lock when modal is open */
  body.modal-open {
    overflow: hidden;
  }

  /* Defensive rules to ensure page content remains visible when no modals are open */
  body:not(.modal-open) {
    background-color: white;
    overflow: visible;
  }

  /* Ensure main content is always visible unless modal is open */
  body:not(.modal-open) main {
    background-color: transparent;
    opacity: 1;
    visibility: visible;
  }

  /* Modal component styles removed - now handled by Tailwind utilities in Modal::BaseComponent */

  /* Modal-specific styling preserved for component states */
  .auth-modal--signed-in .bg-white {
    background-color: rgb(249 250 251);
  }

  .cart-modal--has-items {
    /* Cart specific styling handled by component */
  }

  .gallery-modal {
    /* Gallery modal uses full-screen layout handled by component */
  }

  /* Modal close button styling - unified for all modal types */
  button[data-action*="modal#close"],
  button[data-action*="->modal#close"],
  button[data-action*="click->modal#close"] {
    color: var(--color-text-primary);
    transition: color 0.2s ease-in-out;
  }

  button[data-action*="modal#close"]:hover,
  button[data-action*="->modal#close"]:hover,
  button[data-action*="click->modal#close"]:hover {
    color: var(--color-interactive-primary);
  }

  /* Filter Popup Components */
  .filter-popup-overlay {
    position: fixed;
    inset: 0;
    background-color: rgb(0 0 0 / 0.5);
    transition: opacity 300ms ease;
    z-index: var(--z-modal-overlay);
  }

  .filter-popup-panel {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100vh;
    background-color: white;
    box-shadow: 0 25px 50px -12px rgb(0 0 0 / 0.25);
    transform: translateX(0);
    transition: transform 300ms ease;
    z-index: var(--z-modal);
  }

  @media (min-width: 640px) {
    .filter-popup-panel {
      width: 480px;
      max-width: 90vw;
    }
  }

  .filter-section {
    padding-bottom: 0.75rem;
  }

  .filter-section:last-child {
    padding-bottom: 0;
  }

  .filter-section-header {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: space-between;
    text-align: left;
  }

  .filter-section-header[aria-expanded="true"] svg {
    transform: rotate(180deg);
  }

  .filter-section-content {
    overflow: hidden;
    transition: all 200ms ease;
  }

  /* Toggle Switch */
  .filter-toggle-switch {
    position: relative;
  }

  .toggle-label {
    position: relative;
    display: inline-block;
    width: 3rem;
    height: 1.5rem;
    background-color: #e5e7eb;
    border-radius: 9999px;
    cursor: pointer;
    transition: colors 200ms ease-in-out;
  }

  .toggle-slider {
    position: absolute;
    top: 0.125rem;
    left: 0.125rem;
    width: 1.25rem;
    height: 1.25rem;
    background-color: white;
    border-radius: 9999px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
    transform: translateX(0);
    transition: transform 200ms ease-in-out;
  }

  input:checked+.toggle-label {
    background-color: var(--color-interactive-primary);
  }

  input:checked+.toggle-label .toggle-slider {
    transform: translateX(1.5rem);
  }

  /* Color Dropdown */
  .color-dropdown-open .color-dropdown-arrow {
    transform: rotate(180deg);
  }

  /* Range Slider */
  .filter-range-container {
    position: relative;
  }

  .range-slider-container {
    position: relative;
    height: 1.5rem;
    display: flex;
    align-items: center;
  }

  .range-slider {
    position: relative;
    width: 100%;
    height: 0.5rem;
  }

  .range-track {
    position: absolute;
    inset: 0;
    background-color: #e5e7eb;
    border-radius: 9999px;
    height: 2px;
    top: 50%;
    transform: translateY(-50%);
  }

  .range-fill {
    position: absolute;
    height: 2px;
    background-color: var(--color-text-primary);
    border-radius: 9999px;
    top: 50%;
    transform: translateY(-50%);
  }

  .range-input {
    position: absolute;
    inset: 0;
    width: 100%;
    background-color: transparent;
    appearance: none;
    cursor: pointer;
    height: 20px;
    pointer-events: none;
  }

  /* Style the range input handles (thumbs) */
  .range-input::-webkit-slider-thumb {
    appearance: none;
    background-color: white;
    cursor: pointer;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    border: 2px solid var(--color-black);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    pointer-events: auto;
    margin-top: -9px;
  }

  .range-input::-moz-range-thumb {
    background-color: white;
    cursor: pointer;
    border: 2px solid var(--color-black);
    width: 20px;
    height: 20px;
    border-radius: 50%;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    pointer-events: auto;
  }

  /* Remove default track styling for Firefox */
  .range-input::-moz-range-track {
    background: transparent;
    border: none;
  }

  .range-input.range-min {
    z-index: 1;
  }

  .range-input.range-max {
    z-index: 2;
  }

  .range-input.range-min::-webkit-slider-thumb {
    z-index: 3;
  }

  .range-input.range-min::-moz-range-thumb {
    z-index: 3;
  }

  .form-field {
    position: relative;
    width: 100%;
  }

  .form-input {
    width: 100%;
    padding-left: 2.5rem;
    padding-right: 1rem;
    padding-top: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #d1d5db;
    font-size: 1rem;
    line-height: 1.5rem;
    background-color: transparent;
    position: relative;
    transition: all 200ms ease-in-out;
    font-family: inherit;
    border-top: none;
    border-left: none;
    border-right: none;
    border-radius: 0;
    box-shadow: none;
  }

  .form-input::placeholder {
    color: #9ca3af;
  }

  .form-input:focus {
    outline: none;
    border-bottom-color: #d1d5db;
    box-shadow: none;
  }

  .form-input:focus {
    border-bottom-color: #d1d5db !important;
    box-shadow: none !important;
    outline: none !important;
    border-color: #d1d5db !important;
  }

  /* Remove any browser default focus styles */
  input:focus,
  select:focus,
  textarea:focus {
    box-shadow: none !important;
    outline: none !important;
    border-color: #d1d5db !important;
  }

  .form-input--error {
    border-color: #ef4444;
  }

  .form-input--error:focus {
    border-color: #ef4444;
  }

  .form-select {
    width: 100%;
    padding-left: 2.5rem;
    padding-right: 2.5rem;
    padding-top: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #d1d5db;
    font-size: 1rem;
    line-height: 1.5rem;
    background-color: transparent;
    transition: all 200ms ease-in-out;
    appearance: none;
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
    background-position: right 0.75rem center;
    background-repeat: no-repeat;
    background-size: 1.5em 1.5em;
    border-top: none;
    border-left: none;
    border-right: none;
    border-radius: 0;
    box-shadow: none;
  }

  .form-select:focus {
    outline: none;
    border-bottom-color: #d1d5db;
    box-shadow: none;
  }

  .form-select:focus {
    border-bottom-color: #d1d5db !important;
    box-shadow: none !important;
    outline: none !important;
  }

  .form-select--error {
    border-color: #ef4444;
  }

  .form-select--error:focus {
    border-color: #ef4444;
  }

  .form-textarea {
    width: 100%;
    padding: 1rem;
    border-bottom: 1px solid #d1d5db;
    font-size: 1rem;
    line-height: 1.5rem;
    resize: none;
    background-color: transparent;
    transition: all 200ms ease-in-out;
    font-family: inherit;
    min-height: 100px;
    border-top: none;
    border-left: none;
    border-right: none;
    border-radius: 0;
  }

  .form-textarea::placeholder {
    color: #9ca3af;
  }

  .form-textarea:focus {
    outline: none;
    border-bottom-color: #d1d5db;
  }

  .form-textarea--error {
    border-color: #ef4444;
  }

  .form-textarea--error:focus {
    border-color: #ef4444;
  }

  .form-error-message {
    color: #ef4444;
    font-size: 0.875rem;
    line-height: 1.25rem;
    margin-top: 0.5rem;
    font-weight: 500;
    line-height: 1.4;
  }

  .form-helper-text {
    color: #6b7280;
    font-size: 0.875rem;
    line-height: 1.25rem;
    margin-top: 0.5rem;
    line-height: 1.4;
  }

  .form-radio-group {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .form-radio-option {
    display: flex;
    align-items: flex-start;
  }

  .form-radio-input {
    appearance: none;
    width: 1.375rem;
    height: 1.375rem;
    border: 2px solid rgb(209 213 219);
    border-radius: 50%;
    background-color: white;
    transition: all 200ms ease-in-out;
    position: relative;
    margin-top: 0.125rem;
    flex-shrink: 0;
    box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  }

  .form-radio-input:checked {
    border-color: var(--color-interactive-primary);
    background-color: var(--color-interactive-primary);
    box-shadow: 0 0 0 2px rgba(247, 88, 59, 0.2), 0 1px 3px 0 rgb(0 0 0 / 0.1);
  }

  .form-radio-input:checked::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0.375rem;
    height: 0.375rem;
    border-radius: 50%;
    background-color: white;
    transform: translate(-50%, -50%);
  }

  .form-radio-input:hover {
    border-color: var(--color-interactive-primary);
    transform: scale(1.05);
    box-shadow: 0 0 0 2px rgba(247, 88, 59, 0.1), 0 1px 3px 0 rgb(0 0 0 / 0.1);
  }

  .form-radio-input:focus {
    outline: none;
    border-color: var(--color-interactive-primary);
    box-shadow: 0 0 0 4px rgba(247, 88, 59, 0.15), 0 1px 3px 0 rgb(0 0 0 / 0.1);
  }

  .form-radio-label {
    margin-left: 0.75rem;
    font-size: 1rem;
    line-height: 1.5rem;
    color: #374151;
    line-height: 1.5;
  }

  .form-section {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .form-section-title {
    font-size: 1.25rem;
    line-height: 1.75rem;
    font-weight: 600;
    color: #111827;
    margin-bottom: 1rem;
  }

  /* Checkout specific form styling */
  .checkout-form {
    max-width: 42rem;
    margin-left: auto;
    margin-right: auto;
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .checkout-form-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  @media (min-width: 768px) {
    .checkout-form-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }
  }

  .checkout-form-full {
    grid-column: 1 / -1;
  }

  .checkout-payment-option {
    display: flex;
    align-items: center;
    padding: 1.25rem;
    border: 1px solid var(--color-border-light);
    border-radius: 0.75rem;
    cursor: pointer;
    transition: all 200ms ease-in-out;
    background-color: var(--color-white);
    box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  }

  .checkout-payment-option:hover {
    background-color: rgb(249 250 251);
    border-color: var(--color-interactive-primary);
    transform: translateY(-1px);
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05), 0 2px 4px -2px rgb(0 0 0 / 0.05);
  }

  /* Enhanced responsive design for checkout */
  @media (max-width: 767px) {
    .checkout-form {
      padding: 0 1rem;
      display: flex;
      flex-direction: column;
      gap: 1.5rem;
    }

    .checkout-section {
      padding: 1.25rem;
      border-radius: 0.75rem;
      margin-bottom: 1rem;
    }
    .checkout-section-header {
      margin-bottom: 1rem;
      padding-bottom: 0.5rem;
    }

    .checkout-section-title {
      font-size: 1.125rem;
    }

    .checkout-section-title::after {
      width: 2rem;
      height: 2px;
      bottom: -10px;
    }

    /* Mobile specific improvements */
    .checkout-payment-option {
      padding: 1rem;
    }

    .form-radio-input {
      width: 1.25rem;
      height: 1.25rem;
    }

    .checkout-form-grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }
  }

  @media (min-width: 768px) {
    .checkout-form {
      padding: 0;
    }

    .checkout-section {
      padding: 1.5rem;
    }
  }

  .checkout-payment-option--selected {
    border-color: var(--color-interactive-primary);
    background-color: rgba(247, 88, 59, 0.08);
    box-shadow: 0 0 0 1px var(--color-interactive-primary), 0 4px 6px -1px rgb(0 0 0 / 0.05);
    transform: translateY(-1px);
  }

  .checkout-submit-button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    font-weight: 600;
    transition: all 200ms ease-in-out;
    width: 100%;
    padding: 1rem 2rem;
    font-size: 1.125rem;
    line-height: 1.75rem;
    background-color: var(--color-interactive-primary);
    color: white;
    border: none;
    cursor: pointer;
  }

  .checkout-submit-button:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgba(247, 88, 59, 0.5), 0 0 0 4px rgba(247, 88, 59, 0.2);
  }

  .checkout-submit-button:hover:not(:disabled) {
    background-color: var(--color-interactive-secondary);
  }

  .checkout-submit-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  /* Checkout Section Styles */
  .checkout-section {
    background-color: var(--color-white);
    border: 1px solid var(--color-border-light);
    border-radius: 0.75rem;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.05), 0 1px 2px -1px rgb(0 0 0 / 0.05);
    transition: box-shadow 200ms ease-in-out;
  }

  .checkout-section:hover {
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.07), 0 2px 4px -2px rgb(0 0 0 / 0.05);
  }

  .checkout-section:last-of-type {
    margin-bottom: 0;
  }

  .checkout-section-header {
    margin-bottom: 1.5rem;
    padding-bottom: 0.75rem;
    border-bottom: 1px solid rgb(243 244 246);
  }

  .checkout-section-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--color-text-primary);
    position: relative;
    margin-bottom: 0.25rem;
  }

  .checkout-section-title::after {
    content: '';
    position: absolute;
    bottom: -12px;
    left: 0;
    width: 2.5rem;
    height: 3px;
    background-color: var(--color-interactive-primary);
    border-radius: 2px;
  }

  /* Alert Components */
  .alert-success {
    padding: 1.5rem;
    border: 1px solid rgb(34 197 94);
    border-radius: 1rem;
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    display: flex;
    align-items: center;
    gap: 1rem;
    background-color: rgb(240 253 244);
    animation: fadeIn 0.4s cubic-bezier(0.4, 0, 0.2, 1) both;
  }

  .alert-error {
    padding: 1.5rem;
    border: 1px solid rgb(239 68 68);
    border-radius: 1rem;
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    display: flex;
    align-items: center;
    gap: 1rem;
    background-color: rgb(254 242 242);
    animation: fadeIn 0.4s cubic-bezier(0.4, 0, 0.2, 1) both;
  }

  /* Auth Components */
  .auth-tab-button {
    flex: 1;
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
    font-weight: 500;
    transition: color 0.2s ease-in-out;
  }

  /* Auth Tab States */
  [data-auth-tab="signin"] .signin-tab,
  [data-auth-tab="signup"] .signup-tab {
    background-color: white;
    box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    color: var(--color-text-primary);
  }

  [data-auth-tab="signin"] .signup-tab,
  [data-auth-tab="signup"] .signin-tab {
    color: var(--color-text-muted);
  }

  /* Auth Form Container Visibility - Handled by JavaScript */


  /* Carousel Components */
  .hero-carousel {
    position: relative;
    z-index: 10;
    margin-top: -120px;
  }

  @media (min-width: 768px) {
    .hero-carousel {
      margin-top: -200px;
    }
  }

  .carousel-slide-base {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    transition: opacity 700ms cubic-bezier(0.4, 0, 0.2, 1);
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
  }

  .carousel-content-container {
    position: relative;
    z-index: 10;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100%;
    padding: 4rem 1rem 0;
  }

  @media (min-width: 768px) {
    .carousel-content-container {
      padding-top: 5rem;
    }
  }

  .carousel-nav-button {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    z-index: 20;
    background-color: rgb(255 255 255 / 0.2);
    color: white;
    padding: 0.75rem;
    border-radius: 9999px;
    transition: all 300ms ease-in-out;
    backdrop-filter: blur(4px);
  }

  .carousel-nav-button:hover {
    background-color: rgb(255 255 255 / 0.3);
  }

  .carousel-dots-container {
    position: absolute;
    bottom: 1rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 20;
    display: flex;
    gap: 0.5rem;
  }

  @media (min-width: 768px) {
    .carousel-dots-container {
      bottom: 2rem;
      gap: 0.75rem;
    }
  }

  .hero-cta-container {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    justify-content: center;
  }

  @media (min-width: 640px) {
    .hero-cta-container {
      flex-direction: row;
    }
  }

  @media (min-width: 768px) {
    .hero-cta-container {
      gap: 1rem;
    }
  }

  .hero-cta-secondary {
    font-size: 1rem;
    padding: 0.75rem 1.5rem;
    background-color: rgb(255 255 255 / 0.2);
    border: 1px solid rgb(255 255 255 / 0.3);
    color: white;
    font-weight: 600;
    transition: all 200ms ease-in-out;
  }

  @media (min-width: 768px) {
    .hero-cta-secondary {
      font-size: 1.125rem;
      padding: 1rem 2rem;
    }
  }

  .hero-cta-secondary:hover {
    background-color: rgb(255 255 255 / 0.3);
  }

  .scroll-indicator {
    position: absolute;
    bottom: 1rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 20;
    animation: bounce 1s infinite;
  }

  /* Gallery Thumbnail Container */
  .thumbnail-container {
    scrollbar-width: none;
    /* Firefox */
    -ms-overflow-style: none;
    /* Internet Explorer 10+ */
  }

  .thumbnail-container::-webkit-scrollbar {
    display: none;
    /* Safari and Chrome */
  }

  /* Hide header when gallery modal is open (not cart/auth modals) */
  body.gallery-modal-open .site-header,
  body.gallery-modal-open .header-wrapper header,
  body.gallery-modal-open .header-wrapper nav {
    display: none !important;
  }

  /* Hide product selection elements when zoom modal is open */
  body.modal-open .size-13,
  body.modal-open [data-controller="products--color-dropdown"],
  body.modal-open [data-products--color-dropdown-target="menu"] {
    display: none !important;
  }

  /* Gallery Component Classes */
  .gallery-click-zone {
    position: absolute;
    top: 0;
    height: 100%;
    z-index: 10;
  }

  .gallery-click-zone--left {
    left: 0;
    width: 20%;
  }

  .gallery-click-zone--right {
    right: 0;
    width: 20%;
  }

  .gallery-click-zone--center {
    left: 20%;
    width: 60%;
  }

  .gallery-modal-sidebar {
    background-color: white;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
    width: 120px;
  }

  .thumbnail-container-vertical {
    scroll-behavior: smooth;
    scroll-snap-type: y mandatory;
    overflow-y: auto;
  }

  .thumbnail-container-vertical .thumbnail-desktop {
    scroll-snap-align: start;
  }

  .gallery-modal-content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    padding: 2rem;
    min-height: 100vh;
  }

  /* Hide product info when modal is open to prevent overlay issues */
  .gallery-modal-open .product-info-container,
  .gallery-modal-open .product-info-section {
    display: none;
  }

  /* Hide header when modal is open for full-screen experience */
  .gallery-modal-open .site-header,
  .gallery-modal-open .header-wrapper {
    display: none;
  }

  /* Gallery zoom modal */
  .gallery-zoom-modal {
    z-index: var(--z-gallery-modal);
  }

  /* Hide specific page sections when modal is open - target breadcrumbs, product info, tabs, and reviews */
  .gallery-modal-open .product-info-section,
  .gallery-modal-open .product-layout .product-info-section,
  .gallery-modal-open section:has(.container),
  .gallery-modal-open #reviews-section {
    display: none;
  }

  /* Hide the product gallery thumbnails and controls when modal is open - but NOT modal thumbnails */
  .gallery-modal-open .product-gallery-section .gallery-click-zone,
  .gallery-modal-open .product-gallery-section [data-products--gallery-thumbnails-target="thumbnail"]:not(.gallery-zoom-modal [data-products--gallery-thumbnails-target="thumbnail"]),
  .gallery-modal-open .product-gallery-section [data-products--gallery-thumbnails-target="upArrow"]:not(.gallery-zoom-modal [data-products--gallery-thumbnails-target="upArrow"]),
  .gallery-modal-open .product-gallery-section [data-products--gallery-thumbnails-target="downArrow"]:not(.gallery-zoom-modal [data-products--gallery-thumbnails-target="downArrow"]),
  .gallery-modal-open .product-gallery-section [data-products--gallery-thumbnails-target="thumbnailContainer"]:not(.gallery-zoom-modal [data-products--gallery-thumbnails-target="thumbnailContainer"]),
  .gallery-modal-open .product-gallery-section img[data-products--gallery-target="mainImage"] {
    display: none;
  }

  /* Cart Badge Styles */
  .cart-badge {
    position: absolute;
    top: -0.25rem;
    right: -0.25rem;
    background-color: rgb(239 68 68);
    color: white;
    font-size: 0.75rem;
    border-radius: 9999px;
    min-width: 1.25rem;
    height: 1.25rem;
    display: flex;
    align-items: center;
    justify-content: center;
    padding-left: 0.25rem;
    padding-right: 0.25rem;
    line-height: 1;
  }

  /* Cart State Management */
  [data-cart-state="initial"] .quantity-controls {
    display: none;
  }

  [data-cart-state="quantity"] .quantity-controls {
    display: flex;
  }

  /* Cart Loading States */
  .cart-loading .add-to-cart-button,
  .cart-quantity-form.loading {
    opacity: 0.6;
    transition: opacity 200ms ease-in-out;
  }

  .cart-loading .add-to-cart-button {
    cursor: wait;
  }

  /* Cart Error States */
  .cart-error .quantity-controls {
    border-color: rgb(239 68 68);
    background-color: rgb(254 242 242);
  }

  /* Notification Styles */
  .notification {
    position: fixed;
    top: 5rem;
    right: 1rem;
    z-index: var(--z-notification);
    width: 20rem;
    padding: 1rem;
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    transition-property: all;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 300ms;
    animation: slideInFromRight 400ms ease-out forwards;
    pointer-events: auto;
  }

  @keyframes slideInFromRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }

    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  .notification-success {
    background-color: var(--color-interactive-primary);
    color: white;
    border: 1px solid var(--color-interactive-primary);
  }

  .notification-error {
    background-color: rgb(254 242 242);
    color: rgb(153 27 27);
    border: 1px solid rgb(254 202 202);
  }

  .notification-info {
    background-color: rgb(239 246 255);
    color: rgb(30 64 175);
    border: 1px solid rgb(191 219 254);
  }

  /* Auto-dismiss animation */
  .notification[data-auto-dismiss-active] {
    opacity: 0;
    transform: translateX(100%);
  }

  /* Cart item styles  */
  .cart-item {
    border-bottom: 1px solid rgb(243 244 246);
    padding: 1.5rem 0;
    overflow: hidden;
    word-wrap: break-word;
  }

  .cart-item:last-child {
    border-bottom: 0;
  }

  /* Cart quantity controls */
  .cart-quantity-form button {
    transition: all 200ms ease-in-out;
  }

  .cart-quantity-form button:hover {
    background-color: rgb(249 250 251);
  }

  /* Cart Focus & Accessibility Styles */
  .cart-modal button:focus-visible,
  [data-controller*="modal"] button:focus-visible {
    outline: 2px solid var(--color-interactive-primary);
    outline-offset: 2px;
  }

  .cart-quantity-form button:focus-visible {
    box-shadow: 0 0 0 2px var(--color-interactive-primary), 0 0 0 4px transparent;
  }

  /* Prevent body scroll when popup is open */
  body.overflow-hidden {
    overflow: hidden;
  }

  /* Additional defensive rules for page content visibility */
  body {
    position: relative;
    min-height: 100vh;
  }

  /* Force page content to be visible by default */
  html,
  body {
    background-color: white;
  }

  /* Ensure page sections remain visible and properly styled */
  body:not(.modal-open) header,
  body:not(.modal-open) nav,
  body:not(.modal-open) main,
  body:not(.modal-open) footer,
  body:not(.modal-open) section {
    position: relative;
    z-index: auto;
    opacity: 1;
    visibility: visible;
    background-color: transparent;
  }

  /* Reset any potential z-index conflicts for normal page content */
  body:not(.modal-open) .container,
  body:not(.modal-open) .product-layout,
  body:not(.modal-open) .products-grid {
    position: relative;
    z-index: auto;
  }

  /* Emergency visibility fix - ensure all content is visible when no modal is open */
  body:not(.modal-open) p,
  body:not(.modal-open) span:not(.btn-interactive):not(.add-to-cart-button):not(.wishlist-button),
  body:not(.modal-open) div:not(.btn-interactive):not(.add-to-cart-button):not(.wishlist-button),
  body:not(.modal-open) h1,
  body:not(.modal-open) h2,
  body:not(.modal-open) h3,
  body:not(.modal-open) h4,
  body:not(.modal-open) h5,
  body:not(.modal-open) h6 {
    color: inherit;
  }

  /* Custom Select Component Styles */
  .custom-select-trigger:focus {
    outline: none;
    border-color: var(--color-interactive-primary);
  }

  .custom-select-dropdown {
    margin-top: 2px;
    border: 1px solid rgb(209 213 219);
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  }

  .custom-select-option {
    transition: all 0.15s ease-in-out;
  }

  .custom-select-option:hover {
    color: var(--color-interactive-primary) !important;
    background-color: transparent !important;
  }

  /* Custom scrollbar for dropdown */
  .custom-select-dropdown .py-2 {
    scrollbar-width: thin;
    scrollbar-color: #000000 transparent;
  }

  .custom-select-dropdown .py-2::-webkit-scrollbar {
    width: 2px;
  }

  .custom-select-dropdown .py-2::-webkit-scrollbar-track {
    background: transparent;
  }

  .custom-select-dropdown .py-2::-webkit-scrollbar-thumb {
    background-color: #000000;
    border-radius: 2px;
  }

  .custom-select-dropdown .py-2::-webkit-scrollbar-thumb:hover {
    background-color: #333333;
  }

  /* Interactive primary text color utility */
  .text-interactive-primary {
    color: var(--color-interactive-primary);
  }
}

@layer utilities {

  /* Cart Item Animation */
  .animate-fade-in-up {
    animation: fade-in-up 0.4s ease-out forwards;
    opacity: 0;
    transform: translateY(20px);
  }

  @keyframes fade-in-up {
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .border-beauty {
    border-color: #fce7f3;
  }

  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  /* Interactive Color Utilities */
  .text-interactive {
    color: var(--color-interactive-primary);
  }

  .text-interactive-secondary {
    color: var(--color-interactive-secondary);
  }

  .text-interactive-dark {
    color: var(--color-interactive-dark);
  }

  .bg-interactive {
    background-color: var(--color-interactive-primary);
  }

  .bg-interactive-secondary {
    background-color: var(--color-interactive-secondary);
  }

  .bg-interactive-light {
    background-color: var(--color-interactive-light);
  }

  .bg-interactive-100 {
    background-color: var(--color-interactive-100);
  }

  .bg-interactive-dark {
    background-color: var(--color-interactive-dark);
  }

  .border-interactive {
    border-color: var(--color-interactive-primary);
  }

  .border-interactive-secondary {
    border-color: var(--color-interactive-secondary);
  }

  /* Hover States */
  .hover\:text-interactive:hover {
    color: var(--color-interactive-primary);
  }

  .hover\:text-interactive-secondary:hover {
    color: var(--color-interactive-secondary);
  }

  .hover\:text-interactive-dark:hover {
    color: var(--color-interactive-dark);
  }

  .hover\:bg-interactive:hover {
    background-color: var(--color-interactive-primary);
  }

  .hover\:bg-interactive-secondary:hover {
    background-color: var(--color-interactive-secondary);
  }

  .hover\:bg-interactive-dark:hover {
    background-color: var(--color-interactive-dark);
  }

  .hover\:border-interactive:hover {
    border-color: var(--color-interactive-primary);
  }

  .hover\:border-interactive-100:hover {
    border-color: var(--color-interactive-100);
  }

  /* Group Hover States */
  .group:hover .group-hover\:text-interactive {
    color: var(--color-interactive-primary);
  }

  .group:hover .group-hover\:text-interactive-secondary {
    color: var(--color-interactive-secondary);
  }

  .group:hover .group-hover\:text-interactive-dark {
    color: var(--color-interactive-dark);
  }

  .group:hover .group-hover\:translate-x-0\.5 {
    transform: translateX(0.125rem);
  }

  .group:hover .group-hover\:scale-105 {
    transform: scale(1.05);
  }

  /* Focus States */
  .focus\:ring-interactive:focus {
    --tw-ring-color: var(--color-interactive-500-alpha);
  }

  .focus\:border-interactive:focus {
    border-color: var(--color-interactive-primary);
  }

  /* Form Elements */
  .form-checkbox-interactive {
    color: var(--color-interactive-primary);
  }

  .form-checkbox-interactive:focus {
    --tw-ring-color: var(--color-interactive-500-alpha);
  }

  /* Text Color Utilities */
  .text-primary {
    color: var(--color-text-primary);
  }

  .text-secondary {
    color: var(--color-text-secondary);
  }

  .text-muted {
    color: var(--color-text-muted);
  }

  .text-subtle {
    color: var(--color-text-subtle);
  }

  .text-disabled {
    color: var(--color-text-disabled);
  }

  /* Text Hover States */
  .hover\:text-primary:hover {
    color: var(--color-text-primary);
  }

  .hover\:text-secondary:hover {
    color: var(--color-text-secondary);
  }

  .hover\:text-muted:hover {
    color: var(--color-text-muted);
  }

  .hover\:text-subtle:hover {
    color: var(--color-text-subtle);
  }

  /* Group Hover Text States */
  .group:hover .group-hover\:text-primary {
    color: var(--color-text-primary);
  }

  .group:hover .group-hover\:text-secondary {
    color: var(--color-text-secondary);
  }

  .group:hover .group-hover\:text-muted {
    color: var(--color-text-muted);
  }

  .group:hover .group-hover\:text-subtle {
    color: var(--color-text-subtle);
  }

  .product-cart-actions {
    transition: all 0.3s ease-in-out;
  }

  /* Cart form submission loading states */
  .cart-add-form[data-turbo-submitting] .add-to-cart-button,
  .cart-quantity-form[data-turbo-submitting] button {
    opacity: 0.6;
  }

  .product-actions {
    transition: opacity 200ms ease-in-out;
  }

  .product-actions:has([data-turbo-submitting]) {
    opacity: 0.8;
  }

  /* Stock Status Styling */
  [data-stock-status="available"] {
    color: rgb(34 197 94);
  }

  [data-stock-status="low_stock"] {
    color: rgb(234 88 12);
  }

  [data-stock-status="out_of_stock"] {
    color: rgb(239 68 68);
  }

  /* Gallery Thumbnail States */
  [data-products--gallery-target="thumbnail"],
  [data-products--gallery-target="mobileThumbnail"],
  [data-products--gallery-target="zoomThumbnail"] {
    border: 2px solid transparent;
    opacity: 0.7;
    transition: all 0.2s ease;
  }

  [data-products--gallery-target="thumbnail"]:hover,
  [data-products--gallery-target="mobileThumbnail"]:hover,
  [data-products--gallery-target="zoomThumbnail"]:hover {
    opacity: 1;
    border-color: rgb(209 213 219);
  }

  [data-products--gallery-target="thumbnail"][data-selected="true"],
  [data-products--gallery-target="mobileThumbnail"][data-selected="true"],
  [data-products--gallery-target="zoomThumbnail"][data-selected="true"] {
    border-color: rgb(0 0 0);
    opacity: 1;
  }

  [data-products--gallery-target="upArrow"]:disabled,
  [data-products--gallery-target="downArrow"]:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .gallery-modal-open {
    overflow: hidden;
  }

  [data-thumbnail-visible="false"] {
    display: none;
  }

  [data-thumbnail-visible="true"] {
    display: block;
  }

  .gallery-thumbnails-container {
    display: grid;
    grid-auto-flow: column;
    grid-auto-columns: minmax(68px, max-content);
    gap: 0.5rem;
    overflow-x: auto;
    scroll-behavior: smooth;
    scroll-snap-type: x mandatory;
    scrollbar-width: thin;
    scrollbar-color: rgb(156 163 175) transparent;
  }

  .gallery-thumbnails-container::-webkit-scrollbar {
    height: 4px;
  }

  .gallery-thumbnails-container::-webkit-scrollbar-track {
    background: transparent;
  }

  .gallery-thumbnails-container::-webkit-scrollbar-thumb {
    background-color: rgb(156 163 175);
    border-radius: 2px;
  }

  .gallery-thumbnails-mobile {
    display: grid;
    grid-auto-flow: column;
    grid-auto-columns: 4rem;
    gap: 0.75rem;
    overflow-x: auto;
    scroll-behavior: smooth;
    scroll-snap-type: x mandatory;
    padding: 1rem 0;
  }

  .thumbnail-desktop,
  .thumbnail-mobile {
    scroll-snap-align: center;
    flex-shrink: 0;
    border: 2px solid transparent;
    border-radius: 0.375rem;
    overflow: hidden;
    opacity: 0.7;
    transition: all 0.2s ease;
    cursor: pointer;
    position: relative;
  }

  .thumbnail-desktop {
    width: 68px;
    height: 68px;
    background-color: rgb(249 250 251);
  }

  .thumbnail-mobile {
    width: 4rem;
    height: 4rem;
    background-color: rgb(249 250 251);
    border-radius: 0.5rem;
  }

  .thumbnail-desktop:hover,
  .thumbnail-mobile:hover {
    opacity: 1;
    border-color: rgb(209 213 219);
  }

  .thumbnail-desktop:focus,
  .thumbnail-mobile:focus {
    outline: none;
    border-color: rgb(0 0 0);
    opacity: 1;
  }

  .thumbnail-desktop[data-selected="true"],
  .thumbnail-mobile[data-selected="true"] {
    border-color: rgb(0 0 0);
    opacity: 1;
  }

  .thumbnail-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }


  .gallery-modal-open {
    overflow: hidden;
  }

  .gallery-thumbnails-loading {
    opacity: 0.5;
    pointer-events: none;
  }

  .gallery-thumbnails-loading::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 2rem;
    height: 2rem;
    margin: -1rem 0 0 -1rem;
    border: 2px solid rgb(156 163 175);
    border-top-color: rgb(0 0 0);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* =================================================================== */
/* DELIVERY COMPONENTS - Modern E-commerce Design */
/* =================================================================== */

/* Base delivery card styling */
.delivery-card {
  padding: 1.25rem;
  background: linear-gradient(135deg,
    rgba(251, 171, 157, 0.08),
    rgba(251, 171, 157, 0.12)
  );
  border: 1px solid rgba(251, 171, 157, 0.25);
  border-radius: 0.5rem;
  transition: all 0.2s ease-in-out;
  position: relative;
}

.delivery-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(251, 171, 157, 0.15);
  border-color: rgba(251, 171, 157, 0.4);
}

/* Pickup-specific styling */
.delivery-card--pickup {
  background: linear-gradient(135deg,
    rgba(251, 171, 157, 0.12),
    rgba(247, 88, 59, 0.08)
  ) !important;
  border-color: rgba(251, 171, 157, 0.3) !important;
}

/* Force override any blue pickup styling */
.delivery-card--pickup,
.delivery-card--pickup * {
  background-color: transparent !important;
  border-color: rgba(251, 171, 157, 0.3) !important;
  color: var(--color-text-primary) !important;
}

.delivery-card--pickup {
  background: linear-gradient(135deg,
    rgba(251, 171, 157, 0.12),
    rgba(247, 88, 59, 0.08)
  ) !important;
}

/* Address/delivery-specific styling */
.delivery-card--address {
  background: linear-gradient(135deg,
    rgba(251, 171, 157, 0.10),
    rgba(251, 171, 157, 0.14)
  );
}

/* Status indicators */
.delivery-status {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.delivery-status-dot {
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  flex-shrink: 0;
}

.delivery-status-dot--confirmed {
  background-color: #10b981;
}

.delivery-status-dot--pending {
  background-color: #f59e0b;
  animation: pulse 2s infinite;
}

.delivery-status-text {
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.delivery-status-text--confirmed {
  color: #065f46;
}

.delivery-status-text--pending {
  color: #92400e;
}

/* Typography hierarchy */
.delivery-card-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
  line-height: 1.25;
  margin-bottom: 0.25rem;
}

.delivery-card-subtitle {
  font-size: 0.75rem;
  font-weight: 400;
  color: var(--color-text-secondary);
  line-height: 1.4;
  margin-bottom: 0.75rem;
}

.delivery-card-meta {
  font-size: 0.6875rem;
  font-weight: 500;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

/* Trust signals container */
.delivery-trust-signals {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-top: 0.5rem;
}

.delivery-trust-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.delivery-trust-badge--free {
  color: #065f46;
}

.delivery-trust-badge--time {
  color: var(--color-text-muted);
}

/* Action buttons */
.delivery-action-button {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-interactive-primary);
  padding: 0.5rem 0.75rem;
  border-radius: 0.375rem;
  transition: all 0.2s ease-in-out;
  text-decoration: none;
  border: none;
  background: transparent;
  cursor: pointer;
}

.delivery-action-button:hover {
  background: rgba(247, 88, 59, 0.1);
  color: var(--color-interactive-primary);
  transform: translateX(2px);
}

.delivery-action-button:focus {
  outline: 2px solid var(--color-interactive-primary);
  outline-offset: 1px;
}

/* Details button with specific styling */
.delivery-details-button {
  font-size: 0.875rem !important;
  font-weight: 500 !important;
  color: var(--color-text-primary) !important;
  padding: 0.5rem 0.75rem !important;
  border-radius: 0.375rem !important;
  transition: all 0.2s ease-in-out !important;
  text-decoration: none !important;
  border: none !important;
  background: transparent !important;
  cursor: pointer !important;
  outline: none !important;
}

.delivery-details-button:hover {
  color: var(--color-interactive-primary) !important;
  transform: translateX(2px) !important;
}

.delivery-details-button:focus {
  outline: none !important;
  color: var(--color-interactive-primary) !important;
}

button.delivery-details-button:hover {
  color: var(--color-interactive-primary) !important;
}

/* Icon container */
.delivery-icon-container {
  width: 2rem;
  height: 2rem;
  background: rgba(251, 171, 157, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.delivery-icon {
  width: 1rem;
  height: 1rem;
  color: var(--color-interactive-primary);
}


/* Set address button styling */
.delivery-set-address-button {
  width: 100%;
  padding: 1.25rem;
  border: 2px dashed rgba(251, 171, 157, 0.4);
  background: rgba(251, 171, 157, 0.05);
  color: var(--color-text-muted);
  font-weight: 500;
  transition: all 0.2s ease-in-out;
  cursor: pointer;
}

.delivery-set-address-button:hover {
  border-color: var(--color-interactive-primary);
  color: var(--color-interactive-primary);
  background: rgba(247, 88, 59, 0.08);
}

.delivery-set-address-button:focus {
  outline: 2px solid var(--color-interactive-primary);
  outline-offset: 2px;
}

/* Pickup schedule specific styling */
.pickup-schedule-card {
  padding: 1.25rem;
  background: linear-gradient(135deg,
    rgba(251, 171, 157, 0.15),
    rgba(247, 88, 59, 0.10)
  );
  border: 1px solid rgba(251, 171, 157, 0.3);
  border-radius: 0.5rem;
  position: relative;
}

.pickup-schedule-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.pickup-schedule-icon {
  width: 1.25rem;
  height: 1.25rem;
  color: var(--color-interactive-primary);
  flex-shrink: 0;
}

.pickup-schedule-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.pickup-schedule-content {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  line-height: 1.5;
}

.pickup-schedule-time {
  font-weight: 500;
  color: var(--color-text-primary);
}

/* Animation for status changes */
@keyframes slideInFromRight {
  from {
    transform: translateX(20px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.delivery-card--confirmed {
  animation: slideInFromRight 0.3s ease-out;
}

/* Responsive adjustments */
@media (max-width: 640px) {
  .delivery-card {
    padding: 1rem;
  }

  .delivery-trust-signals {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }

  .delivery-action-button {
    font-size: 0.8125rem;
    padding: 0.375rem 0.625rem;
  }
}
