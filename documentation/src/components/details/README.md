# Details

Collapsible content block rendered as a native `<details>`/`<summary>`,
styled after the 1.0 panel's collapsible section header. No client script:
disclosure is native browser behaviour and the open/close animation is pure
CSS.

## Look

A hairline row, not a card, after the restrained docs collapsibles (Vercel
Geist, shadcn, MDN, Starlight upstream):

- neutral hairlines above and below; no background, radius or side borders
  (`border-0` also removes Starlight's own `details` border-inline-start);
- the chevron at text size, leading, in the muted colour, brightening on
  hover and turning 90 degrees (200ms, off under reduced motion);
- the title in JetBrains Mono semibold, underlined on hover;
- the open content indented to the title text, unframed;
- adjacent blocks stack into one list: the second drops its top line and
  the gap between them.

Brand colour only appears in the site-wide focus ring.

## Syntax

```markdown
:::details[Why does this happen?]{open}
Typewriter caches pages per player, so a reload only affects new interactions.

\`\`\`yaml
cache: true
\`\`\`
:::
```

- `[Label]` is optional. Default label: `Details`.
- `{open}` (or `{open=true}`) renders the block already expanded. Any other
  value for `open` (e.g. `{open=false}`), or omitting the attribute, renders
  it collapsed.
- `{id=my-anchor}` sets an `id` on the `<details>` element so the block can be
  deep-linked (`#my-anchor`).
- `{name=group}` passes the native `name` attribute through: blocks that share
  a name form an exclusive group, so opening one closes the others. Browsers
  without native support get the same behaviour from `exclusive.ts`, loaded
  once via `DetailsRuntime.astro` in `Head.astro`.
- No `{variant=...}`: one look.

### Nesting

`remark-directive` container fences are matched by colon count, so a directive
nested inside another directive needs a fence with **more** colons than the
outer one, or its closing `:::` prematurely closes the parent:

```markdown
::::details[More info]
Some context.

:::info
A nested aside.
:::
::::
```

This is a `remark-directive` requirement, not something this plugin adds — see
the [test page](../../content/docs/docs/detailstest/index.md) for working
examples of a nested aside and nested details.

## Behaviour

- The summary row is the clickable header. The native marker is hidden in
  favour of an inline chevron SVG that rotates 90° when open, driven by
  `details[open] > summary` (not any open ancestor, so a closed block nested
  in an open one keeps its own state).
- The chevron is `aria-hidden`: it duplicates the open state the UA already
  exposes on `<details>`.
- Focus uses the site-wide ring from `global.css` (2px `--color-primary`,
  2px offset): 5.7:1 in dark and 5.9:1 in light against the page.
- The container gets `scroll-mt-4` so an `{id}` deep link lands with some air
  above it.

### Open/close animation

`::details-content` gets `height: 0`, `overflow: clip` and a transition on
`content-visibility`/`height`/`opacity` with `transition-behavior:
allow-discrete`; `[open]::details-content` gets `height: auto`. With
`interpolate-size: allow-keywords` on the `<details>`, Chromium animates
between the two; elsewhere the browser snaps instantly. `motion-reduce:`
zeroes the duration regardless of browser.

Two details are load-bearing and easy to undo by accident:

- `content-visibility` must stay in the transition list with `allow-discrete`.
  The UA sets `content-visibility: hidden` while closed; listing it discrete
  flips it at 100% instead of 0%, which is what keeps the content rendered for
  the whole close. Drop it and the content vanishes on the first frame.
- `::details-content` must be the only thing contributing height, or the card
  snaps when `content-visibility` finally flips. `overflow: clip` does not
  establish a block formatting context, so a block margin would collapse out of
  the animated box — Starlight's `markdown.css` sibling `margin-block-start`
  did exactly that. Hence `display: flow-root` on `::details-content`, plus
  `my-0` and non-zero top and bottom padding (`pt-1 pb-4`) on the content
  wrapper (padding is itself a collapse barrier). The padding belongs on that inner wrapper, never
  on `::details-content`, because padding does not scale with `height`.

## Files

- `remark-details.ts` — the plugin, transforms `containerDirective` nodes
  named `details` into `<details>`/`<summary>`/`<div>` hast trees
- `styles.ts` — Tailwind class strings
- `index.ts` — re-exports

## Limitations

- The animation is Chromium-only, because `interpolate-size: allow-keywords`
  is. Firefox and Safari get an instant, correct open/close.
- While closing, the content is deliberately still `content-visibility:
  visible` and only clipped by `overflow: clip`, so for those 200ms it remains
  in the accessibility tree. Native `<details>` semantics are unaffected.
- Setting either of the content wrapper's paddings to zero re-opens the
  margin-collapse bug above; only change them together with a close-animation
  check.
- No client script and no `Runtime` component — server-rendered markup plus CSS.
