# Hotspots

Annotated screenshots for plain markdown: numbered pins placed over an image by
percentage coordinates, each described by a popover card. The descriptions live
in a legend list that is screen-reader-only by default and only becomes a
visible list when the picture cannot carry the annotation.

## Syntax

```md
:::hotspots[The pages tab of the panel]
![The pages tab of the panel](./panel.png)

1. [12%, 30%] **Page list** — every page in the project. Click one to open it.
2. [50%, 45%] **Graph canvas** — entries are nodes, connections are triggers.
3. [86%, 20%] **Inspector** — fields of the selected entry.
:::
```

- The first child must be a paragraph containing an image. The mdast `image`
  node is kept intact, so relative paths go through Astro's image pipeline
  exactly like a normal markdown image (hashed `/_astro/...` src, `width` and
  `height`, lazy loading).
- The first list after the image gives the pins, in order. Each item starts
  with `[x%, y%]` (the `%` signs are optional: `[12, 30]` works too). `x` is
  measured from the left edge, `y` from the top, both clamped to 0–100. The
  bracket is stripped; the rest of the item is inline markdown (bold, links,
  code). An item without coordinates still appears in the legend but gets no
  pin.
- The optional `[label]` becomes a `<figcaption>` under the image.
- Anything after the list is rendered after the legend, inside the figure.

### Attributes

| Attribute        | Default | Effect                                                                                   |
| ---------------- | ------- | ---------------------------------------------------------------------------------------- |
| `numbers=false`  | `true`  | Dot pins instead of numbered badges; the popover drops its number badge and a visible legend uses matching dots. |
| `legend=visible` | auto    | Always render the legend as a visible list under the caption, instead of only as a fallback. |

```md
:::hotspots[A caption]{numbers=false legend=visible}
```

## Behaviour

- **Positioning.** Pins are `position: absolute` buttons with `left`/`top`
  percentages inside a `w-fit max-w-full` stage that hugs the image, so they
  stay put at every column width. Everything, including pins, renders at build
  time.
- **Legend.** The `<ol>` is always in the DOM: it is the target of every pin's
  `aria-describedby` and the source of the popover's HTML. By default it is
  `sr-only`; it is promoted to a visible list by `legend=visible` or by any of
  the fallbacks below.
- **Sync.** Hovering or focusing a pin sets `data-active` on the pin and its
  legend item; hovering a legend item does the same for its pin. Keyboard focus
  on a pin scrolls its legend item into view (`block: "nearest"`), only while
  the legend is visible.
- **Popover.** Click/tap (or Enter/Space) toggles a card with a clone of the
  legend item's HTML, plus the pin's number badge when `numbers` is on. There is
  one card element for the whole page, appended to `<body>` and positioned with
  `position: fixed`, so no ancestor can clip it. It prefers below the pin, flips
  above when there is more room there, is clamped to the viewport on both axes
  with a 12px margin, and its arrow tracks the pin (`--hs-arrow-x`,
  `data-placement`). It follows the pin while the page scrolls and closes once
  the pin leaves the viewport. Scrolling lives on an inner box
  (`max-h: min(22rem, 60vh)`). One popover is open at a time.
- **Popover keyboard.** Escape closes it and returns focus to the pin; clicking
  elsewhere or moving focus outside closes it too. Because the card is at the
  end of `<body>`, Tab order is bridged by hand: Tab from the pin moves into the
  card's first link, Shift+Tab from that link returns to the pin, and tabbing
  past the last link lets focus leave and closes the card.
- **Ping.** When a figure first scrolls into view (40% visible), each pin
  plays a two-cycle expanding ring via the Web Animations API, staggered per
  pin. Skipped entirely under `prefers-reduced-motion`.
- **View transitions.** `HotspotsRuntime.astro` (included once from
  `Head.astro`) calls `setupHotspots()` on `astro:page-load` and
  `astro:after-swap`. Listeners are delegated on `document` and bound once;
  figures are marked `data-hotspots-ready` so re-runs are no-ops. Open state is
  reset on `astro:before-swap`, and the card is re-appended to the swapped
  `<body>` on the next open.

### Legend fallbacks

The legend becomes a visible list whenever the image cannot do its job. Each
rule is CSS on a state the figure (or the document) carries, so the three can
overlap without fighting.

| Fallback         | Trigger                                                                             | Selector                 |
| ---------------- | ----------------------------------------------------------------------------------- | ------------------------ |
| Image failed     | the `img` fires `error`, or is `complete` with `naturalWidth === 0` at setup        | `[data-hotspots-broken]` |
| Stage too narrow | stage `clientWidth < 240px`, watched with a `ResizeObserver` (plus a `resize` sweep) | `[data-hotspots-narrow]` |
| No scripting     | `<html>` never got the `hotspots-js` class                                          | `html:not(.hotspots-js)` |

- **Broken image.** Pins are hidden and the `img` drops its intrinsic aspect
  ratio so the alt text sits in a compact dashed placeholder instead of a
  full-size empty box.
- **Narrow stage.** Pins stay, but a click highlights the legend entry and
  scrolls it into view instead of opening a card.
- **No scripting.** An inline `is:inline` script in `<head>` adds
  `hotspots-js` to `<html>` before the body is parsed, and re-adds it on
  `astro:after-swap` (the ClientRouter re-syncs root attributes). Without the
  class the CSS keeps every legend visible. A class marker rather than
  `@media (scripting: none)` also covers a CSP or extension blocking the
  script.

### Accessibility

- Pins are `<button type="button">` named after the legend entry's bold lead-in
  plus the number — `aria-label="Page list, callout 1"`, falling back to
  `"Callout 1"` when the entry has no bold lead. They carry `aria-describedby`
  pointing at the legend item's content and `aria-expanded` reflecting the
  popover; while open, `aria-controls` points at the popover.
- The popover is `role="dialog"` (non-modal, focus stays on the pin) labelled
  with the pin's name.
- Badges and numbers inside pins/legend are `aria-hidden`; the list order
  carries the numbering semantically. The badge digit is white on the light
  theme's primary and `grey-900` on the dark theme's, both above 4.5:1.
- Pins have a 44px hit area (`after:-inset-2`; 32px for `numbers=false` dots)
  and a dark `focus-visible` outline drawn flush against the pin's white ring.
  All motion is behind `motion-reduce`.

## Files

| File                    | Role                                                                     |
| ----------------------- | ------------------------------------------------------------------------ |
| `remark-hotspots.ts`    | Remark plugin: directive → figure/stage/pins/legend (hName/hProperties). |
| `hotspots.ts`           | Client entry (`setupHotspots`): delegated listeners and the pin toggle.  |
| `figure.ts`             | Per-figure setup: image and width watching, fallbacks, ping.             |
| `pairs.ts`              | Pin ↔ legend item lookup and `data-active` sync.                         |
| `popover.ts`            | The single popover card: open/close, positioning, Tab bridging.          |
| `HotspotsRuntime.astro` | Renders nothing; the inline `hotspots-js` marker plus the `<script>` that wires `setupHotspots`. |
| `styles.ts`             | Tailwind class strings (`as const`), scanned by Tailwind 4.              |
| `types.ts`              | Shared types.                                                            |
| `index.ts`              | Public exports.                                                          |

## Limitations

- Only tested in `.md`. In `.mdx` the image is handled by
  `@astrojs/mdx`'s image-to-component step; the directive structure should
  survive but is unverified.
- One popover open per page (stricter than per image).
- Popover content is a clone of the legend HTML, so duplicated `id`s inside a
  legend item (e.g. heading anchors) would be duplicated; keep legend items to
  inline content.
- A `[x, y]` prefix must be plain text at the very start of the item; wrapping
  it in formatting (`**[10, 20]**`) is not recognised and the item gets no pin.
- There is no way to author pins without a legend: it is the accessible
  description and the popover's content even when nothing draws it.
- The narrow-stage threshold is a fixed 240px on the stage, not a media or
  container query, because the stage hugs the image and can be far narrower
  than the column it sits in.
- The ping animation only runs for figures that intersect the viewport after
  setup; if `IntersectionObserver` is missing it is skipped.
