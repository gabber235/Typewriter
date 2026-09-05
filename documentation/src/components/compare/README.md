# Compare

A before/after image comparison slider. Written as a `remark-directive` container
directive, so it works in plain `.md` content with no imports.

## Syntax

```markdown
:::compare[Before|After]{start=50}
![Old panel](./old.png)
![New panel](./new.png)
:::
```

The label is split on `|`: the first half labels the clipped (top) image, the
second half labels the base (bottom) image. Both halves are optional — omit the
label entirely and you get `Before` / `After`.

The first two `image` nodes found anywhere inside the directive become the two
layers, in document order. Everything else inside the directive is dropped.

## Attributes

| Attribute     | Values                    | Default      | Meaning                                                        |
| ------------- | ------------------------- | ------------ | -------------------------------------------------------------- |
| `start`       | `0`–`100`                 | `50`         | Initial handle position, in percent. Clamped.                   |
| `orientation` | `horizontal` \| `vertical`| `horizontal` | Split axis. Vertical clips from the bottom instead of the right.|
| `hover`       | flag, or `hover=false`    | off          | Follow the pointer without pressing, instead of drag-to-move.   |

```markdown
:::compare[Old|New]{orientation=vertical start=25}
:::compare[Before|After]{hover}
```

## Behaviour

**Layout.** The "after" image is the base layer and defines the frame's height.
The "before" image sits on top, absolutely positioned and clipped with
`clip-path: inset(...)`, so neither image is ever scaled or re-laid-out while the
handle moves. Astro's markdown image pipeline writes `width`/`height` onto both
`<img>` elements, so the frame reserves its final height before either file has
downloaded.

**Stacking.** Every overlapping child carries an explicit `z-index` — after layer
`0`, before layer `10`, divider `20`, handle `30` — and the frame is `isolate`.
This is load-bearing: a non-`none` `clip-path` makes the before layer a stacking
context, so with `z-index: auto` the after layer paints over it and the slider
looks frozen.

**Position.** A single CSS custom property, `--compare-pos` (unitless, `0`–`100`),
is set on the wrapper; CSS derives the clip inset, the divider offset, the handle
offset and the label opacities from it, so a drag frame is one
`style.setProperty` call.

**Pointer.** `pointerdown` on the frame jumps to that position and calls
`setPointerCapture`, so mouse, touch and pen all follow the same path and a drag
that leaves the frame keeps tracking. Moves are coalesced into
`requestAnimationFrame`. Horizontal sliders set `touch-action: pan-y` and vertical
ones `pan-x`, so the page still scrolls along the unused axis. `hover` suppresses
the press-to-drag path per pointer type, not globally: a touch pointer never
hovers, so touch keeps the normal drag even on a `hover` slider.

**Keyboard and screen readers.** The handle contains a real
`<input type="range" aria-label="…">`, visually hidden but focusable. Arrow keys
step 1%, Shift+arrows and PageUp/PageDown step 10%, Home/End jump to the ends.
Vertical sliders invert the arrow mapping so ArrowDown moves the divider down.
Every change also writes `aria-valuetext` ("62% Before, 38% After"), and the
remark plugin renders the starting value so it is right before the script runs.
Focusing the input rings the visible handle via `has-[:focus-visible]`.

**Motion.** `--compare-dur` is `150ms` by default, so clicks and key presses
animate; the script drops it to `0ms` for the duration of a drag and in hover
mode. `motion-reduce:transition-none` removes the animation entirely under
`prefers-reduced-motion`.

**Labels.** Each label lives inside its own layer, so it is clipped and unclipped
with its own image. Opacity is a function of `--compare-pos` and `--compare-fade`,
the label's own extent along the split axis as a percentage, written per label by
the script and refreshed by a `ResizeObserver` on the frame and both labels. The
label therefore reaches opacity 0 exactly as the clip edge arrives at it.

**No-JS fallback.** `@media (scripting: none)` unsets the clip, returns the
before layer to normal flow, and hides the divider and handle, giving two stacked
images, both fully visible and both labelled.

**View transitions.** `setupCompare()` runs on module load, `astro:after-swap`
and `astro:page-load`. Init is idempotent via a `data-compare-ready` flag on the
wrapper, and all state is per-element, so any number of sliders per page is fine.

## Limitations

- **The two images must have identical dimensions.** The base image sets the
  frame height; the clipped image is stretched to fill it with `object-cover`, so
  mismatched aspect ratios crop rather than letterbox.
- Exactly two images are used. A directive with fewer than two `image` nodes is
  left untransformed, and any third image (or other content) inside is discarded.
- The label fade band is a fixed 4% of the split axis. On a very wide frame that
  band is a long fade; on a very narrow one it is abrupt.
- Label opacity depends on `--compare-fade`, which only the script can measure.
  Until it runs, both labels stay fully opaque, so a label can briefly overlap the
  divider on first paint.
- The two labels sit in different stacking contexts, so the "after" label is
  painted under the before layer. It is invisible by the time the clip edge
  reaches it, but a label restyled to be much larger than its measured box would
  be clipped before it faded.
- `@media (scripting: none)` drives the no-JS layout. In a browser that both lacks
  that media feature and has JavaScript disabled, the slider renders frozen at its
  `start` position.
- No RTL handling: position is always measured from the left edge.
- Images inside the slider are `pointer-events: none`, so they cannot be
  right-click-saved through the frame.

## Files

- `types.ts` — `CompareOptions`, `CompareOrientation` and the shared defaults
- `styles.ts` — Tailwind class strings
- `remark-compare.ts` — the `remarkCompare` plugin
- `compare.ts` — client controller (`setupCompare`)
- `CompareRuntime.astro` — renders nothing, carries the `<script>`
- `index.ts` — re-exports
