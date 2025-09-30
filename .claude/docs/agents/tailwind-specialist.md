# Tailwind Specialist Guide

## 🎨 Tailwind CSS v4 Expertise

This guide covers Tailwind CSS v4 patterns, breaking changes, and best practices for utility-first design in Rails 8 applications.

## ⚠️ **CRITICAL: Tailwind v4 Breaking Changes**

**IMPORTANT**: This project uses `tailwindcss-rails` gem v4.2.3 which includes **Tailwind CSS v4** with breaking changes.

### ❌ BROKEN in v4

```css
@layer components {
  .my-component {
    @apply flex items-center gap-2; /* ❌ Does NOT work reliably */
  }
}
```

### ✅ WORKING in v4

```css
@layer components {
  .my-component {
    display: flex; /* ✅ Use explicit CSS properties */
    align-items: center;
    gap: 0.5rem;
  }
}
```

### Key Rules for v4

1. **Never use `@apply` directives** in `@layer components` - they fail silently or work inconsistently
2. **Use explicit CSS properties** with actual values instead of Tailwind utilities
3. **Replace Tailwind utility classes** with custom CSS classes when building components
4. **This affects ANY custom CSS** - hover states, component styles, etc.

### Why This Happens

- Tailwind v4 no longer "hijacks" the `@layer` at-rule
- `@apply` directive has restrictions in v4 that cause silent failures
- This is a known, widespread issue affecting Rails 8 + Tailwind v4 users

## 🎨 Utility-First Design Patterns

### Responsive Design

**Mobile-First Approach:**
```erb
<div class="w-full
            px-4 sm:px-6 md:px-8
            text-sm sm:text-base md:text-lg
            grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
```

**Breakpoint Strategy:**
- `sm:` - 640px and up (tablet)
- `md:` - 768px and up (desktop)
- `lg:` - 1024px and up (large desktop)
- `xl:` - 1280px and up (extra large)

### Component Patterns

**Card Components:**
```erb
<div class="bg-white rounded-lg shadow-md p-6 border border-gray-200">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">Card Title</h3>
  <p class="text-gray-600">Card content</p>
</div>
```

**Button Patterns:**
```erb
<!-- Primary Button -->
<button class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md transition-colors">
  Primary Action
</button>

<!-- Secondary Button -->
<button class="bg-gray-200 hover:bg-gray-300 text-gray-900 font-medium py-2 px-4 rounded-md transition-colors">
  Secondary Action
</button>

<!-- Icon Button -->
<button class="flex items-center justify-center w-8 h-8 p-0 rounded-md hover:bg-gray-100 transition-colors">
  <svg class="w-5 h-5">...</svg>
</button>
```

**Form Patterns:**
```erb
<!-- Form Field -->
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Field Label
  </label>
  <input class="w-full px-3 py-2 border border-gray-300 rounded-md
               focus:ring-2 focus:ring-blue-500 focus:border-blue-500
               placeholder-gray-400">
</div>

<!-- Error State -->
<input class="w-full px-3 py-2 border border-red-300 rounded-md
             focus:ring-2 focus:ring-red-500 focus:border-red-500
             bg-red-50">
<p class="mt-1 text-sm text-red-600">Error message</p>
```

### Layout Patterns

**Flexbox Layouts:**
```erb
<!-- Center Content -->
<div class="flex items-center justify-center min-h-screen">
  <div class="text-center">Centered content</div>
</div>

<!-- Header Layout -->
<header class="flex items-center justify-between px-4 py-3 bg-white border-b">
  <div class="flex items-center">Logo & Nav</div>
  <div class="flex items-center gap-4">Actions</div>
</header>

<!-- Sidebar Layout -->
<div class="flex min-h-screen">
  <aside class="w-64 bg-gray-100">Sidebar</aside>
  <main class="flex-1 p-6">Main content</main>
</div>
```

**Grid Layouts:**
```erb
<!-- Product Grid -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
  <div class="bg-white rounded-lg shadow-md">Product card</div>
</div>

<!-- Dashboard Grid -->
<div class="grid grid-cols-12 gap-6">
  <div class="col-span-12 lg:col-span-8">Main content</div>
  <div class="col-span-12 lg:col-span-4">Sidebar</div>
</div>
```

### Animation & Transitions

**Hover Effects:**
```erb
<button class="transform hover:scale-105 transition-transform duration-200">
  Hover to scale
</button>

<div class="opacity-75 hover:opacity-100 transition-opacity duration-300">
  Fade on hover
</div>
```

**Loading States:**
```erb
<div class="animate-pulse">
  <div class="h-4 bg-gray-300 rounded mb-2"></div>
  <div class="h-4 bg-gray-300 rounded w-3/4"></div>
</div>

<div class="animate-spin w-5 h-5 border-2 border-blue-600 border-t-transparent rounded-full"></div>
```

## 🎯 Project-Specific Patterns

### Beauty Store UI Patterns

**Square Aesthetic (Project Style):**
```erb
<!-- Product Cards -->
<div class="bg-white border-0 shadow-sm aspect-square">
  <img class="w-full h-48 object-cover" src="...">
  <div class="p-4">
    <h3 class="font-medium text-gray-900">Product name</h3>
    <p class="text-gray-600">$25.99</p>
  </div>
</div>

<!-- Borderless Containers -->
<div class="bg-white shadow-sm p-6">
  <!-- No borders, use shadows for separation -->
</div>
```

**Modal Patterns:**
```erb
<!-- Modal Overlay -->
<div class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm z-50">
  <!-- Modal Panel -->
  <div class="fixed inset-y-0 right-0 w-[680px] max-w-[90vw] bg-white shadow-xl">
    <div class="flex flex-col h-full">
      <header class="px-8 py-6 border-b border-gray-200">Header</header>
      <main class="flex-1 overflow-y-auto p-8">Content</main>
      <footer class="px-8 py-6 border-t border-gray-200">Footer</footer>
    </div>
  </div>
</div>
```

### Color Scheme

**Primary Colors:**
- Primary: `blue-600`, `blue-700` (hover)
- Secondary: `gray-200`, `gray-300` (hover)
- Success: `green-600`, `green-700` (hover)
- Error: `red-600`, `red-700` (hover)
- Warning: `yellow-600`, `yellow-700` (hover)

**Text Colors:**
- Primary text: `text-gray-900`
- Secondary text: `text-gray-600`
- Muted text: `text-gray-500`
- Interactive: `text-blue-600`

**Background Colors:**
- Page background: `bg-gray-50`
- Card background: `bg-white`
- Subtle background: `bg-gray-100`
- Active state: `bg-blue-50`

## 🔧 Development Workflow

### Component Development

**Step 1: Start with Utilities**
```erb
<div class="flex items-center gap-4 p-6 bg-white rounded-lg shadow-md">
  <!-- Build with utilities first -->
</div>
```

**Step 2: Extract to CSS Classes (if needed)**
```css
@layer components {
  .card-base {
    padding: 1.5rem;
    background-color: white;
    border-radius: 0.5rem;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  }
}
```

**Step 3: Use in Templates**
```erb
<div class="card-base flex items-center gap-4">
  <!-- Combine custom classes with utilities -->
</div>
```

### Debugging Classes

**Debug Borders:**
```erb
<div class="border border-red-500"> <!-- Temporary debug -->
  Debug this layout
</div>
```

**Debug Backgrounds:**
```erb
<div class="bg-red-100"> <!-- Temporary debug -->
  Check this container
</div>
```

## 📱 Responsive Best Practices

### Mobile-First Design

1. **Start with mobile styles** (no prefix)
2. **Add breakpoints progressively** (`sm:`, `md:`, `lg:`)
3. **Test on real devices** regularly
4. **Use relative units** where appropriate

### Common Responsive Patterns

**Hide/Show on Different Screens:**
```erb
<div class="block md:hidden">Mobile only</div>
<div class="hidden md:block">Desktop only</div>
```

**Responsive Typography:**
```erb
<h1 class="text-2xl md:text-4xl lg:text-5xl font-bold">
  Responsive heading
</h1>
```

**Responsive Spacing:**
```erb
<div class="p-4 md:p-6 lg:p-8">
  Responsive padding
</div>
```

## ⚡ Performance Considerations

### Utility Class Organization

**Group related classes:**
```erb
<!-- Layout -->
<div class="flex items-center justify-between
           <!-- Spacing -->
           px-4 py-3 mb-6
           <!-- Visual -->
           bg-white border border-gray-200 rounded-lg shadow-sm">
```

### CSS Purging

- Tailwind automatically purges unused classes in production
- Ensure dynamic classes are safeguarded in `tailwind.config.js`
- Use complete class names (avoid string concatenation)

### Custom CSS Minimization

- Use utilities over custom CSS when possible
- Extract truly reusable patterns to components
- Avoid complex custom CSS that duplicates utilities

## 🚀 Best Practices Summary

1. **Use explicit CSS properties** instead of `@apply` in Tailwind v4
2. **Follow mobile-first responsive design** principles
3. **Maintain consistent spacing scale** (4, 8, 16, 24, 32px)
4. **Use semantic color names** in your design system
5. **Group related utility classes** for readability
6. **Avoid complex custom CSS** when utilities exist
7. **Test responsive behavior** on real devices
8. **Use `class_names` helper** for conditional classes in Rails
9. **Keep utility classes readable** with proper indentation
10. **Document custom CSS patterns** for team consistency