# Kbd

Renders keyboard shortcuts as `<kbd>` keycaps, styled exactly like the key
caps in the 1.0 panel (`panel/lib/shared/ui/components/shortcut_display.dart`,
`_KeyDisplay` with `KeyStyle.solid()` at size 12).

## Look

- One cap per key, 4px apart, no visible `+` (screen readers still hear
  "plus").
- 20px tall, at least 20px wide (wider for words like `Esc`), 4px horizontal
  padding, 4px radius, no border.
- JetBrains Mono 12px bold, 0.5px letter spacing, line height 1.
- A hard ledge under the cap: `0 2px 0` in light, `0 3px 0` in dark.
- Colours are the panel's `surfaceContainerHighest` / `onSurface` and the
  ledge (background darkened in OkHSL), computed from the panel's
  `ColorScheme.fromSeed(#62646A)`:

  | | Light | Dark |
  | --- | --- | --- |
  | Cap | `#E1E2E9` | `#33353A` |
  | Text | `#191C20` | `#E1E2E9` |
  | Ledge | `#C7C8D5` | `#1E1F23` |

- Sizes are px, as in the panel, so a shortcut in a heading stays panel-size.
- Groups align on the text baseline. `vertical-align: middle` placed groups
  inconsistently on the tall reading lines.

## Syntax

```markdown
:kbd[Ctrl+S]
:kbd[Cmd+Shift+P]
:kbd[Ctrl+K, Ctrl+S]
```

- `+` joins keys pressed **together**.
- `,` separates **sequential** chords; a muted `then` is rendered between them
  (the panel has no multi-step shortcuts, so this is the docs' own addition).
- Whitespace around keys is trimmed, so `:kbd[ Ctrl + S ]` is the same as `:kbd[Ctrl+S]`.

No attributes.

## Literal separators

A separator only separates when there is content on both sides of it, so the
separator characters stay usable as keys:

| Input | Keys |
| ----- | ---- |
| `:kbd[Ctrl++]` | `Ctrl` `+` |
| `:kbd[+]` | `+` |
| `:kbd[Ctrl+,]` | `Ctrl` `,` |
| `:kbd[,]` | `,` |

## Display names

Recognised names become the panel's symbols (`keys.ts`): `ctrl`/`control` →
`⌃`, `alt` → `⌥`, `cmd`/`command`/`meta` → `⌘`, `opt`/`option` → `⌥`, `shift` →
`⇧`, `enter`/`return` → `↵`, `tab` → `⇥`, `space` → `⎵`, `backspace` → `⌫`,
`delete` → `Del`, `esc`/`escape` → `Esc`, `up`/`down`/`left`/`right` → `↑ ↓ ← →`,
`win`/`super` → `⊞`. `home`, `end`, `pageup` and `pagedown` stay words. The
panel draws these as icons; the docs use the matching characters.

Anything else falls back to: single characters are upper-cased (`s` → `S`),
longer names get their first letter capitalised (`f5` → `F5`).

### Spoken names

A symbol cap carries a spoken name (`keys.ts`, `KeyCap.spoken`): `⌃` is
announced as "Control", `↑` as "Up arrow", `Esc` as "Escape". The symbol is
hidden from assistive technology, the spoken name is rendered as visually
hidden text next to it, and it is also the cap's `title`, so hovering a symbol
shows its name. Caps with no `spoken` entry (`F5`, `S`) render as plain text.

## Markup

The whole shortcut is one outer `<kbd>` and each key is a nested `<kbd>`:

```html
<kbd class="…"><kbd class="…"><span aria-hidden="true">Ctrl</span><span class="sr-only">Control</span></kbd><span class="…">+</span><kbd class="…">S</kbd></kbd>
```

Sizes are all `em`-relative, so a shortcut inside a heading or a table cell
scales with the surrounding text, and `whitespace-nowrap` keeps a combo from
breaking across lines.

## Files

- `keys.ts` — chord/key splitting and display-name normalisation
- `styles.ts` — Tailwind class strings
- `remark-kbd.ts` — the `remarkKbd` plugin
- `index.ts` — re-exports
