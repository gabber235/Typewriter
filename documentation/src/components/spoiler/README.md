# Spoiler

A **gated section**: a whole block of documentation (headings, paragraphs, code
blocks, lists, asides) hidden behind an overlay card that explains *why* it is
hidden, with a button to reveal it.

This is not an inline blur for a single word. It is the "we don't recommend
doing this, but here is the documentation if you really want it" pattern.

## Syntax

````markdown
:::spoiler[Not recommended]{reason="This bypasses the panel's validation and can corrupt your pages. Only use it for migrations." button="Show me anyway" variant=warning}

## Editing page JSON by hand

Open `plugins/Typewriter/pages/<name>.json` …

```json
{ "id": "…" }
```

:::
````

### Nesting other directives

`remark-directive` closes a container at the first fence with the **same or
fewer** colons. A spoiler that contains another directive (an aside, tabs, …)
must therefore open and close with **four** colons:

````markdown
::::spoiler[Not recommended]{reason="…"}

Some prose.

:::warning
Take a backup first.
:::

::::
````

## Attributes

| Attribute | Default | Meaning |
| --- | --- | --- |
| `[label]` | `Hidden section` | Title on the gate card and in the header bar. |
| `reason` | `This content is hidden. Reveal it only if you know what you are doing.` | Sentence under the title explaining why it is gated. |
| `button` | `Reveal section` | Label of the reveal button. |
| `hide` | `Hide again` | Label of the collapse button in the header bar. |
| `variant` | `warning` | `warning` (orange), `danger` (red), `info` (blue), `neutral` (blue-grey). |
| `open` | *(absent)* | Bare flag; the section starts revealed. |

Unknown `variant` values fall back to `warning`. Icons come from
`../aside/aside-config.ts` and the colour ramp is the same material palette the
asides use, so a spoiler reads as the same family; `neutral` reuses the `note`
icon and blue-grey.

## Rendered structure

```
div[data-spoiler][data-spoiler-variant][data-spoiler-open]   grid, rows [auto 1fr]
├── div[data-spoiler-bar]        row 1 · sticky header, hidden while closed
│   └── icon · title · button[data-spoiler-hide]
├── div[data-spoiler-shell]      row 2 · overflow clip; contain-size + min-h while closed
│   └── div[data-spoiler-content][id]   the real markdown (Starlight prose applies)
└── div[data-spoiler-gate]       row 2 · scrim + bottom fade, hidden while open
    └── div[data-spoiler-card]   icon · title · reason · button[data-spoiler-reveal] · hint
```

Every variant only sets `--spoiler-tint` and `--spoiler-ink`; the border, the
5% surface (`--spoiler-surface`), the bar, the chip and the gradient all derive
from the tint.

## Sizing

The shell and the gate share one grid cell, and **both are in normal flow while
closed**. The shell has `contain: size` plus `min-height: 10rem`, so it
contributes only the peek height to the row; the gate contributes the card plus
its padding. The closed row is therefore `max(peek, card)`, which means the card
can never be clipped at any width, the shell stretches to cover the whole closed
box even for short content, and nothing is measured in JavaScript to lay the
closed state out.

## Motion

Reveal and collapse are one coordinated motion driven by the Web Animations
API: four `animate()` calls that share the same duration and easing, started in
the same frame.

| Track | Reveal | Collapse |
| --- | --- | --- |
| root `height` | closed px → open px | open px → closed px |
| content `filter` / `opacity` | `blur(7px)` / 0.7 → none / 1 | mirror |
| gate `opacity` | 1 → 0 | 0 → 1 |
| card `transform` | `scale(1)` → `scale(0.96)` | mirror |

Duration 350 ms open / 300 ms close, easing `cubic-bezier(0.2, 0, 0, 1)`
(Material 3 "standard"); exits are shorter, as M3 prescribes.

While a run is in flight the gate is lifted out of flow (`absolute inset-0
z-20`) so the root's height is driven purely by the animation, the card stays
centred inside the shrinking or growing box, and the sticky bar emerges *under*
the fading scrim. The root is `overflow-hidden` only for the duration;
afterwards it is visible again so the sticky bar works.

Keyframe start values are read from computed style, so a toggle that interrupts
a running toggle reverses from exactly where it is. A timer races the `finished`
promises because a background tab never ticks animations to completion; the
`running` map tells a stale run apart from a cancelled one.

`prefers-reduced-motion: reduce` skips the animation and jumps to the end state.

The height is driven in JS rather than in CSS because neither CSS route works:
`grid-template-rows: 0fr → 1fr` cannot interpolate from a non-zero peek (a
`<length>` track) to a `<flex>` track, and `interpolate-size: allow-keywords` is
Chromium-only, so it would still need this JS path as a fallback — two code
paths with different timing to keep in sync.

## Behaviour

**Closed.** The content is rendered in full but blurred (`blur-[7px]`), dimmed
to 70%, `select-none`, `pointer-events-none`, and — once the client script runs
— `inert` + `aria-hidden="true"`. The gate is a gradient: the surface colour at
30% over the top of the preview, solid surface from 35% down, so the preview
reads as "there is more here" and ends on exactly the wrapper colour.

**Revealing.** The motion above. Once it settles, focus moves to the first
heading inside the revealed content (given `tabindex="-1"`), falling back to the
"Hide again" button, with `preventScroll: true`.

**Collapsing.** If the header bar is currently stuck, the scroll container is
first scrolled instantly so the root's top edge sits where the stuck bar was —
the bar does not visibly move — and *then* the mirror animation runs in view.
Focus returns to the reveal button.

**Header bar.** `position: sticky; top: 0` inside the docs' `.content-pane`
scroll container, which already starts below the fixed nav. It sticks within
the root only, so it leaves with the section.

**Anchors and the table of contents.** Headings inside a spoiler still appear
in the page sidebar. The sidebar's own click handler calls `preventDefault()`,
pushes the hash with `history.pushState` (no `hashchange`) and scrolls at once,
so the spoiler's `click` listener is registered in the **capture** phase: it
opens the gate instantly *before* the sidebar measures the target. A
`hashchange` listener and a `location.hash` check on every `astro:page-load`
cover deep links and back/forward. Hash-driven reveals are never animated.

**Keyboard / AT.** Both buttons are real `<button type="button">` with
`aria-expanded` and `aria-controls` pointing at the content element's id — the
WAI-ARIA disclosure pattern. While closed the content is `inert`, so it is
neither tabbable nor announced; while open the gate is. APG says a simple
disclosure should not move focus; this one does, because the content was
`inert` and the control that had focus disappears.

**View transitions.** `setupSpoilers()` runs on `astro:page-load` and
`astro:after-swap`; per-element work is guarded by `data-spoiler-ready` and the
document-level listeners bind once behind a module-scope flag.

## No-JavaScript fallback

Sections ship **closed in the HTML**, so there is no flash of revealed content
on load. The escape hatch is a `<noscript><style is:inline>` block in
`SpoilerRuntime.astro` that drops the size containment, the blur, the header bar
and the gate. `inert`/`aria-hidden` are deliberately *not* server-rendered; they
are applied by the client script, so a no-JS screen reader still reaches the
content.

Either way the full text is in the initial HTML, so it is indexed by Pagefind
and by crawlers, and `starlight-llms-txt` sees it too.

## Styling constraints

- The wrapper surface is the variant colour at 5% over `--sl-color-bg`, half of
  an aside's 10%, so a `:::warning` nested inside a warning spoiler still reads
  as a distinct box.
- `--spoiler-tint` paints surfaces and borders; `--spoiler-ink` is the same hue
  picked for text and icons, where 1.4.3 wants 4.5:1 against the tinted
  surface. The 500 shades only clear that on a dark background, so light mode
  steps down to an 800/900 and dark mode steps *up* for red and blue-grey.
- Headings and controls inside the content carry `scroll-mt-14`, because the
  header bar is sticky at the scroll port's top edge and a jump would otherwise
  land the target underneath it (2.4.11).
- `not-content` is on the bar, the gate and the card only — never on the content
  area, which is real prose and wants Starlight's typography. The shell and the
  gate also carry `mt-0!`, because Starlight's sibling rule would otherwise add
  a content gap between the grid rows.
- `filter: blur()` is applied to the content wrapper, not to individual blocks,
  so Expressive Code frames and asides keep their exact layout; the shell's
  `overflow-hidden` clips the bleed.

## Limitations

- **Four colons when nesting.** See above.
- **Browser find-in-page** will match text inside a closed spoiler and scroll to
  it while it is still blurred.
- **`top: 0` sticky** assumes the docs' `.content-pane` scroll container. On a
  layout where the document itself scrolls under a fixed nav, the bar would
  slide under that nav; `STICKY_TOP` in `styles.ts` is the one place to change.
- **`open` cannot be persisted.** Every navigation starts from the authored
  state.
- **One counter per file.** Ids are `spoiler-1`, `spoiler-2`, … per markdown
  file, which is unique per page but not globally.
