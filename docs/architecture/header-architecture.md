# Header Architecture Documentation

## Overview

The header system implements a **nuclear border removal** approach with **design token-based architecture** for consistent, maintainable styling across all page types.

## Design Principles

### 1. Nuclear Border Removal
- **Zero borders**: All header and navigation elements have `border-bottom: none !important`
- **Universal application**: No exceptions, no special cases, no page-specific border rules
- **Future-proof**: New pages automatically inherit seamless styling

### 2. Design Token System
All styling values are centralized in CSS custom properties for consistency and maintainability.

### 3. State-Based Architecture
Headers respond to user interactions through data attributes:
- `data-header-state`: `transparent`, `hovered`, `scrolled`, `white`
- `data-header-context`: `default`, `brand-gradient`, `brand-image`
- `data-navigation--header-state-page-type-value`: `home`, `brand`, `checkout`, `page`, `product`

## CSS Custom Properties (Design Tokens)

```css
:root {
  /* Animation and timing */
  --header-transition-duration: 300ms;
  --header-transition-easing: ease;
  --header-height: 72px;

  /* Background colors - semantic naming */
  --header-bg-transparent: transparent;
  --header-bg-white: rgb(255, 255, 255);
  --header-bg-fallback: rgba(255, 255, 255, 0.95);    /* JS disabled fallback */
  --header-bg-glass: rgba(255, 255, 255, 0.8);        /* Standard transparent state */

  /* Backdrop filters - performance optimized values */
  --header-blur-none: none;
  --header-blur-light: blur(2px);      /* Subtle effect */
  --header-blur-medium: blur(8px);     /* Standard glass effect */

  /* Brand specific backgrounds */
  --brand-gradient: linear-gradient(to right, rgb(249, 250, 251), rgb(243, 244, 246));
  --z-header: 60;                     /* Z-index for header layering */
}
```

## Architecture Components

### 1. Universal Rules
```css
/* Universal border removal - applies to ALL header and navigation elements */
.header-wrapper .site-header,
.navigation-wrapper,
.header-wrapper .site-header[data-header-state],
.navigation-wrapper[data-header-state] {
  border-bottom: none !important;
  border-top: none !important;
  transition: background var(--header-transition-duration) var(--header-transition-easing),
              backdrop-filter var(--header-transition-duration) var(--header-transition-easing);
}
```

### 2. Base Structure
- **Header Wrapper**: Contains the entire header system, `z-index: var(--z-header)`
- **Header**: `position: fixed` at top, height: `var(--header-height)`
- **Navigation**: `position: relative` (scrolls with content on mobile, visible on desktop)
- **Z-index**: Header above navigation (`calc(var(--z-header) - 1)`)

### 3. State Management

#### Transparent State (Default)
- **General pages**: Glass effect with `--header-bg-glass` and `--header-blur-medium`
- **Homepage/Brand pages**: Forced transparent with `--header-bg-transparent`
- **Product pages**: White background (special case)

#### Hover/Scroll States
- **All contexts**: Solid white background with `--header-bg-white`
- **Synchronized timing**: Both header and navigation transition together
- **Product pages**: Always use white background regardless of state

#### Brand Contexts
- **Gradient**: Uses `--brand-gradient` for consistent brand styling
- **Image**: Dynamic background from `--header-banner-url` CSS variable

### 4. Navigation Wrapper
- **Mobile**: Hidden by default, shown through mobile menu controller
- **Desktop**: Visible with `display: block !important` on `min-width: 768px`
- **Z-index**: Slightly below header at `calc(var(--z-header) - 1)`

## Page Type Behaviors

### Homepage (`home`)
- **Transparent**: Wrapper provides unified background, children are transparent
- **Hover/Scroll**: Both sections turn white simultaneously
- **Perfect timing**: Single transition source eliminates sync issues

### Brand Pages (`brand`)
- **Transparent**: Individual backgrounds (gradient or image)
- **Hover/Scroll**: Override to solid white
- **Context-aware**: Different styling based on `brand-gradient` vs `brand-image`

### Checkout/Static Pages (`checkout`, `page`)
- **Always white**: No dynamic states, always use white background
- **Border**: Has bottom border `border-bottom: 1px solid rgba(0, 0, 0, 0.1)`
- **Hover disabled**: Hover effects are disabled for these page types

### Product Pages (`product`)
- **Always white**: Use white background regardless of state
- **Special handling**: Product pages always display white background
- **No hover effects**: Hover effects are disabled for consistent product experience

## Transition System

### Synchronized Timing
All transitions use the same timing values:
- **Duration**: `--header-transition-duration` (300ms)
- **Easing**: `--header-transition-easing` (ease)
- **Properties**: `background` and `backdrop-filter`

### Performance Optimization
- **Single rule**: Universal transition rule prevents duplication
- **Consistent timing**: Eliminates visual jarring between elements
- **GPU acceleration**: Backdrop-filter transitions use hardware acceleration

## Key Benefits

### 1. Maintainability
- **Single source of truth**: Change design tokens to update globally
- **No hardcoded values**: All styling values centralized
- **Clear separation**: Structure vs styling values

### 2. Consistency
- **Universal borders**: No visual seams anywhere
- **Synchronized transitions**: Perfect timing across all contexts
- **Semantic tokens**: Easy to understand and modify

### 3. Performance
- **Fewer CSS rules**: Optimized selector specificity
- **Hardware acceleration**: Proper use of backdrop-filter transitions
- **Reduced complexity**: Simplified cascade hierarchy

### 4. Developer Experience
- **Predictable behavior**: Same patterns across all page types
- **Easy debugging**: Clear documentation and comments
- **Future-proof**: New pages automatically get correct styling

## Browser Support

- **Modern browsers**: Full support for backdrop-filter and CSS custom properties
- **Fallback**: Graceful degradation with `--header-bg-fallback` for older browsers
- **Progressive enhancement**: Core functionality works without JavaScript

## Migration Pattern

When adding new page types or header states:

1. **Use existing design tokens** where possible
2. **Add new tokens** to `:root` if needed
3. **Follow state-based patterns** with data attributes
4. **Test transition timing** to ensure synchronization
5. **Document new behaviors** in this file

## Troubleshooting

### Common Issues

1. **Border appearing**: Check for competing CSS rules with higher specificity
2. **Timing mismatch**: Ensure all elements use universal transition rule
3. **Background not showing**: Verify data attributes are set correctly by Stimulus controllers

### Debug Tools

1. **Browser DevTools**: Inspect data attributes on header wrapper
2. **CSS custom properties**: Check computed values in DevTools
3. **Transition debugging**: Use browser animation timeline

---

*This architecture was implemented to solve border inconsistencies and timing issues across different page types, providing a unified, maintainable solution for the entire application.*