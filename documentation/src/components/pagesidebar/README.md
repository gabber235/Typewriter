# Table of contents ("On this page")

Replaces Starlight's `PageSidebar`. On wide screens (72em and up) it is a
right-aligned column; below that, a floating pill opens the same list in a
modal sheet. Research, baseline audit and decisions are recorded in
`polish/components/toc.md`.

## Files

- `PageSidebar.astro`: the Starlight override; renders both variants.
- `TableOfContents.astro`: desktop column: "On this page" with the ring
  beside it, the SVG rail, the list. Holds the edge-fade CSS.
- `MobileTableOfContents.astro`: pill button and `<dialog>` sheet.
- `TocList.astro`: recursive nested `<ul>`, `rail` or `sheet` variant.
- `ProgressRing.astro`: decorative ring (`pathLength="100"`) with the
  percentage inside: `inline` (20px, bare number, beside "On this page") or
  `large` (40px, "42%", in the mobile pill).
- `scroll-spy.ts`: one shared engine per page that measures sections and
  works out the current section, the on-screen range and progress.
- `toc-elements.ts`: the `page-toc` and `page-toc-sheet` custom elements.
- `navigation.ts`: jumping to a section, focus, history.
- `styles.ts`, `types.ts`, `index.ts`.

## How the live state works

The scroll pane is `.content-pane`, not the window. A section runs from its
heading to the next TOC heading; the last one ends at the bottom of
`.sl-markdown-content`. Positions are measured once and re-measured when
the content or pane resizes (images, fonts, opened `<details>`, viewport).
Each animation frame then only does arithmetic:

- **visible**: every section with any part inside the pane. Non-current
  ones get full text colour, and the desktop rail lights beside them. The
  rail is one SVG path built from the links' real positions: a vertical run
  per item at `depth * 0.75rem` (the list's own indent step), with a 6px
  diagonal where the depth changes. The lit part is a dash along the same
  path (`stroke-dasharray` / `stroke-dashoffset`), so it follows the bends
  and slides when the range changes. A ResizeObserver redraws the path when
  headings wrap or fonts load.
- **current**: the last section whose heading is above the reading line, a
  quarter down the pane (at most 160px). If the final sections are too short
  to reach that line, the line slides to the bottom edge over the last
  screen of scrolling. It gets `aria-current="true"`, accent colour and
  semibold weight.
- **progress**: `scrollTop / (articleEnd - paneHeight)`. It is 100% once the
  end of the article is visible, not the end of the footer.

A clicked item is pinned until the scroll it started stops for 150ms, or
until the user scrolls by wheel, touch or keyboard. Clicks push a history
entry with a null state; Back and Forward between those entries restore the
position (Astro's router ignores them).

## Accessibility notes

- `<nav aria-labelledby>` pointing at the `h2` "On this page"; the mobile
  sheet has its own `h2` and `nav` inside the dialog.
- Progress (ring and percent) is `aria-hidden`: it is not a status message
  and must never announce while scrolling.
- Following a link moves focus to the heading (`tabindex="-1"`).
- The sheet is a real modal (`showModal()`): Escape, backdrop and the close
  button dismiss it, and focus returns to the pill. While it is open the
  pane is locked by `:root:has(#page-toc-dialog[open])` in `global.css`.
- Rows are 28px (desktop) and 44px (sheet). Forced colours draw the thumb
  and the sheet's current-item bar in `Highlight`.

## Checks

From `polish/tools` (after `bun install`, against `bun run preview`):

```bash
bun checks/toc.mjs
```

```bash
bun audit.mjs "page-toc,page-toc-sheet" docs/01-syntax/ docs/02-long-text/
```
