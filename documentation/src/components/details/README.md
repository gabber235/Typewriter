# Details

Collapsible content block rendered as a native `<details>`/`<summary>`, styled to
match the aside family. No client script: disclosure is native browser
behaviour and the open/close animation is pure CSS.

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
- No `{variant=...}` — one look, matching the rest of the aside family.

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
  favour of an inline chevron SVG that rotates 90° when open, driven purely by
  the `details[open]` attribute selector.
- The chevron is `aria-hidden`: it duplicates the open state the UA already
  exposes on `<details>`.
- The focus outline is `--material-light-blue-800` in light mode and
  `--color-primary` in dark, because the site primary is 2.8:1 on the light
  page and a focus indicator needs 3:1.
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
  `my-0` and symmetric non-zero `py-3` on the content wrapper (padding is
  itself a collapse barrier). The padding belongs on that inner wrapper, never
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
- Changing the content wrapper's `py-3` to a one-sided padding re-opens the
  margin-collapse bug above; only do it together with a close-animation check.
- No client script and no `Runtime` component — server-rendered markup plus CSS.
