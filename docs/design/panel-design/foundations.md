# Foundations

## Type

Two families, with one rule for choosing between them: **a full sentence uses IBM Plex Sans; everything
else uses Lilex.**

| Family | Used for |
| --- | --- |
| Lilex | Titles, navigation, labels, buttons, names, values, identifiers, key caps |
| IBM Plex Sans | Descriptions, help text, messages, anything written as a sentence |

JetBrains Mono leaves the panel. Weights drop from 700 to 500 and 600 on labels and buttons, so they stop
competing with titles.

## Colour

Cool, blue tinted greys and one brand blue, carried on from today's theme.

| Role | Value | Notes |
| --- | --- | --- |
| Brand fill | `#009FFF` | Filled controls, with black text (7.4:1) |
| Brand text, dark | `#33AEFF` | 6.8:1 on the dark surface |
| Brand text, light | `#006FB8` | 5.3:1 on white. `#009FFF` on white is 2.84:1, which fails |
| Focus, dark | `#009FFF` | 5.8:1 |
| Focus, light | `#006FB8` | 5.3:1 |

### CO-01 MUST: Text meets contrast

Text reaches 4.5:1 on its background, in both themes.

- Why: `#009FFF` looks fine as a fill and fails as text on white.
- Check: `test`.
- Broken: severity 3.

### CO-02 MUST: One meaning per colour

Warning has its own colour, separate from any accent. A status colour only ever means that status.

- Why: accent and warning are both `Colors.orange` today, so a highlight reads as a warning.
- Check: `test`.
- Broken: severity 2.

### CO-03 MUST: Focus is unmistakable

The ring uses the brand blue, is at least 2 px, and reaches 3:1 against what is next to it. It stays
visible at every window size, and stays distinct from selection.

- Why: this is a keyboard first product, and the ring is its main guide.
- Check: `test`.
- Broken: severity 3.

## Spacing

Spacing comes from `TypewriterSpacing`: 4, 8, 12, 16, 20, 24, 32, 40, 48. Sizes outside the scale are defects
unless a component has a stated reason.

## Shape

Radii come from `TypewriterShapes`: small 4, medium 8, large 12, plus pill and circle. Panes use large; controls
use medium; key caps and small chips use small.

## Elevation

Panes are flat, and hierarchy comes from surface brightness. Only things above the page cast a shadow, with one
step each: menus and toasts, then dialogs.

## Icons

One set, Material Symbols, bundled with the app. Nothing is fetched at runtime. Sizes: 16 inline, 20 in controls.

### IC-01 MUST: One icon set, bundled

- Why: six sets are in use today, and some load over the network, so they can fail or flash.
- Check: `lint`.
- Broken: severity 2.

## Density

### DE-01 SHOULD: Rows are dense

Rows are about 32 px with a pointer and at least 44 px on touch.

- Why: this is a tool for long sessions, and seeing more means moving less.
- Check: `test`, `visual-llm`.
- Broken: severity 2.

## Layout

The shell is a top bar (path, search, mode chip), panes, and a bottom row of key hints.

### LA-01 MUST: The active pane lifts

The pane holding focus uses a brighter surface than the other panes. Exactly one pane is active.

- Why: it answers "where am I?" at a glance, especially when switching panes by keyboard.
- Check: `test`, `visual-llm`.
- Broken: severity 2.

### LA-02 MUST: One left edge

A title and its content start at the same x position, on every page.

- Why: a shared edge makes pages read as one product.
- Check: `test`, `visual-llm`.
- Broken: severity 2.
- Don't: Members title at 262 px with its content at 254 px.

### LA-03 MUST: One main action per pane

A pane has at most one filled action.

- Why: when everything is primary, nothing is.
- Check: `visual-llm`.
- Broken: severity 2.
- Don't: a filled New page on every tree row, plus another floating at the bottom of the screen.

### LA-04 MUST: Every page works on a phone

The same actions are available at every width, and the mouse free path stays available.

- Why: the vision says mobile can do everything.
- Check: `test` with the compact trait.
- Broken: severity 3.

## Open

- How the active pane lift works in light mode, where a brighter surface has less room. Tune in the real panel.
