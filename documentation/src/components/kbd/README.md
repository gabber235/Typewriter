# Kbd

Renders keyboard shortcuts as `<kbd>` keycaps.

## Syntax

```markdown
:kbd[Ctrl+S]
:kbd[Cmd+Shift+P]
:kbd[Ctrl+K, Ctrl+S]
```

- `+` joins keys pressed **together**.
- `,` separates **sequential** chords; a `then` separator is rendered between them.
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

Recognised names are normalised (`keys.ts`): `ctrl`/`control` → `Ctrl`,
`cmd`/`command`/`meta` → `⌘ Cmd`, `opt`/`option` → `⌥ Option`, `shift` →
`⇧ Shift`, `alt` → `Alt`, `enter`/`return` → `Enter ↵`, `esc`/`escape` → `Esc`,
`up`/`down`/`left`/`right` → `↑ ↓ ← →`, `space` → `Space`, plus `tab`,
`backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`, `win`/`super`.

Anything else falls back to: single characters are upper-cased (`s` → `S`),
longer names get their first letter capitalised (`f5` → `F5`).

### Spoken names

A cap whose printed glyph does not read as a key name carries a second, spoken
name (`keys.ts`, `KeyCap.spoken`): `↑` is announced as "Up arrow", `⌘ Cmd` as
"Command", `Ctrl` as "Control", `Esc` as "Escape". The glyph is hidden from
assistive technology and the spoken name is rendered as visually hidden text
next to it. Caps with no `spoken` entry (`Alt`, `Tab`, `F5`, `S`) render as
plain text.

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
