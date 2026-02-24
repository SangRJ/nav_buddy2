# Changelog

All notable changes to NavBuddy2 will be documented in this file.

## [0.3.0] - 2026-02-24

### ✨ Added

- **Collapsible sidebar** — Sidebar defaults to collapsed, showing only the icon rail. Collapsed state persists in localStorage.
- **Sticky page header** — New header bar above main content showing breadcrumb navigation (sidebar title → page title) with glassmorphism styling (`bg-base-100/80 backdrop-blur`).
- **Header sidebar toggle** — Rotating chevron arrow in the page header to expand/collapse the sidebar. Replaces the old hamburger button on the icon rail.
- **Command palette in header** — Search icon (🔍) on the right side of the page header that opens the command palette (`⌘K`), consistent with the horizontal layout.
- **Intelligent icon rail behavior** — Simple sidebars (single navigable item) link directly on click. Multi-item sidebars show a flyout menu on click when collapsed, or switch the active sidebar when expanded.
- **Flyout menus** — Fixed-position flyout panels for multi-item sidebars in collapsed mode. Uses daisyUI `menu` component for consistent theming. Bottom-positioned items anchor upward to stay within the viewport.

### 🔄 Changed

- **Sidebar width** — Reduced from `w-72` (288px) to `w-60` (240px) for a tighter layout.
- **Sidebar slide animation** — Slide in/out transition uses full `translateX` for a more dramatic effect (300ms in, 200ms out).
- **Page header z-index** — Increased to `z-30` to stay above scrollable content.
- **Icon rail buttons** — Switched from `transition-all` to `transition-colors` to avoid conflicts with the wiggle animation.
- **Flyout styling** — Uses daisyUI `menu bg-base-200 rounded-box shadow-lg` matching dropdown conventions. Active items use `bg-primary/10 text-primary font-medium`.
- **Desktop layout container** — Added `overflow-x-hidden` to prevent horizontal scrollbar from sidebar slide animation.

### 🗑️ Removed

- **Hamburger toggle on icon rail** — Replaced by the header chevron arrow for better discoverability.
- **Sidebar close arrow** — Removed the redundant chevron_left button from the sidebar header, since the page header arrow is the sole toggle.

### 🐛 Fixed

- **Command palette trigger** — Uses `window.dispatchEvent(new CustomEvent(...))` instead of Alpine `$dispatch()` to correctly reach the `.window` listener.
- **Bottom flyout positioning** — Flyouts for bottom-positioned sidebar items now anchor upward using measured panel height via `$nextTick`.
- **Active state in flyouts** — Uses explicit `bg-primary/10 text-primary` classes matching the sidebar, instead of daisyUI's generic `active` class which applies neutral colors.
