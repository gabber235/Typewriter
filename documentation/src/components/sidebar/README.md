# Custom Sidebar Documentation

## Overview

This sidebar is a custom implementation designed to override the default Astro Starlight sidebar. It's split into modular components with shared types and utilities.

## File Structure

```
src/components/sidebar/
├── Sidebar.astro       # Main container + client-side JS (inline)
├── SidebarList.astro   # Recursive list renderer
├── SidebarGroup.astro  # Collapsible <details> groups
├── SidebarLink.astro   # Individual navigation links
├── types.ts            # Shared TypeScript interfaces
├── utils.ts            # Shared utility functions
└── README.md           # This file
```

## Components

### Sidebar.astro

Main sidebar container that receives data from Starlight's `Astro.locals.starlightRoute.sidebar`. Contains all client-side JavaScript (a bundled module script that initializes once).

**JavaScript Responsibilities:**
- State persistence (localStorage), applied once on first load
- Sibling accordion behavior (collapse one when another opens)
- Animated expand/collapse transitions
- Client-side navigation via `navigate()` (`astro:transitions/client`)
- Active-state sync + auto-expand on each `astro:page-load`

### SidebarList.astro

Recursively renders the sidebar tree. Handles entry type detection and index page extraction.

**Props:**
- `sublist` (SidebarEntry[]): Array of link or group entries
- `nested` (boolean): Whether this is a nested list (default: false)
- `level` (number): Nesting depth for indentation (default: 1)

### SidebarGroup.astro

A collapsible `<details>` element with animated content. Supports optional href for groups with index pages.

**Props:**
- `label` (string): Group name
- `entries` (SidebarEntry[]): Child entries
- `collapsed` (boolean): Initial state
- `level` (number): Nesting depth
- `groupHref` (string, optional): Link for groups with index pages
- `isCurrent` (boolean, optional): Whether the group's index is active

### SidebarLink.astro

Individual navigation link with active state styling.

**Props:**
- `label` (string): Link text
- `href` (string): Destination URL
- `isCurrent` (boolean, optional): Active state
- `attrs` (Record<string, any>, optional): Additional attributes
- `level` (number): Nesting depth

## Shared Files

### types.ts

TypeScript interfaces for sidebar entries:
- `LinkEntry`: Single navigation link
- `GroupEntry`: Collapsible group with children
- `SidebarEntry`: Union type of LinkEntry | GroupEntry

### utils.ts

Utility functions:
- `getPaddingClass(level)`: Returns Tailwind padding class for nesting
- `formatLabel(text)`: Sentence-case formatting (preserves explicit caps)
- `findIndexEntry(entries)`: Finds the index page in a group
- `processGroupEntries(entries)`: Extracts index and returns render metadata

## CSS Classes (JS Hooks)

The inline script uses these classes to identify elements:
- `.sidebar-group` - The `<details>` element
- `.sidebar-content` - The animated content wrapper
- `.sidebar-toggle` - The toggle button (chevron)
- `.sidebar-group-link` - Links inside group summaries

## Data Attributes

- `data-group-id` - Unique identifier for state persistence
- `data-level` - Nesting depth
- `data-is-current` - Whether this link/group is the current page

## Persistence & View Transitions

The site runs with Astro's `<ClientRouter />` (enabled in `src/components/Head.astro`), and the sidebar `<nav>` is marked `transition:persist` in `PageFrame.astro`. This means the sidebar DOM — including open/closed groups, scroll position, and event listeners — survives navigation untouched, so there is no per-navigation flicker or re-initialization.

Because the persisted DOM is not re-rendered by the server on navigation, the active link/group highlight is updated by JavaScript on each `astro:page-load` (see `updateActiveState`), which also auto-expands the current page's parent groups and scrolls the active link into view.

A short `.sidebar-ready` reveal still guards the very first paint (and hard refresh) to avoid a flash of incorrect group state while localStorage is read.

## Badges

You can add badges to sidebar items using frontmatter. When using a string, the badge will display with the default accent color. For more control, pass an object with `text`, `variant`, and optionally `class` fields.

**Simple badge:**
```yaml
---
title: Page with a badge
sidebar:
  badge: New
---
```

**Custom badge with variant:**
```yaml
---
title: Page with a badge
sidebar:
  badge:
    text: Experimental
    variant: caution
---
```

**Available variants:** `note` (blue), `tip` (purple), `danger` (red), `caution` (orange), `success` (green), `default` (theme accent color).

## Accessibility

- `aria-label` on the nav element (localized)
- `aria-expanded` on collapsible groups
- Keyboard-accessible toggle buttons
