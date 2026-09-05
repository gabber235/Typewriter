# Variables

Substitutes site-wide values written once in `src/content/variables.yml`.

## Syntax

```markdown
Latest release: :var[latest]
[Join the Discord](:var[discord])
![Logo](:var[logo])
**:var[latest]**
:cmd[/tw version :var[latest]]
```

No attributes.

## Source file

`src/content/variables.yml` is a flat `name: value` map:

```yaml
latest: "1.0.2"
discord: "https://discord.gg/HtbKyuDDBw"
```

Quote every value. Unquoted `1.20` parses as the number `1.2` and would render
as `1.2`. Nested objects and lists are ignored; scalars are stringified.

The file is read with `node:fs` once per build and cached in module scope. The
path is resolved from `process.cwd()` first, then relative to this module, so it
works for `bun run build` from the project root.

## Where it works

| Position | Handled by |
| -------- | ---------- |
| Body text, headings, table cells | `textDirective` nodes replaced with a plain `text` node |
| Inside other directives (`:cmd[]`, `:kbd[]`) | same — the visitor descends into directive children |
| `link` / `image` / `definition` `url` and `title` | string replacement of `:var[name]` |

Because a resolved variable becomes a plain `text` node, `**:var[latest]**`
gives bold text and the glossary plugin still sees the substituted words.

URLs need the string-replacement path because remark-directive cannot parse a
directive inside a link destination — `[x](:var[discord])` arrives as the raw
url `:var[discord]`.

`inlineCode` is deliberately left alone, so `` `:var[latest]` `` stays literal.

## Unknown variables

Never throws. In text the directive renders the visible marker `⚠ var:name`; in
a URL the raw `:var[name]` is left in place. Both log a `console.warn` naming
the variable and the source file.

The marker is a `<span>` rather than a bare text node, because `⚠` is a glyph a
screen reader either skips or spells out. The sign is `aria-hidden` and the
reason is spelled out in visually hidden text, so the marker reads as
"Unknown variable var:name":

```html
<span class="not-italic">
	<span aria-hidden="true">⚠ </span><span class="sr-only">Unknown variable </span>var:name
</span>
```

## Ordering

`remarkVariables` is registered directly after `remarkDirective` and before
every other directive plugin (see `astro.config.mjs`), so downstream plugins
only ever see resolved text.

## Files

- `styles.ts` — Tailwind class strings for the missing-variable marker
- `site-variables.ts` — YAML loading and the module-scope cache
- `types.ts` — `SiteVariables`
- `remark-variables.ts` — the `remarkVariables` plugin
- `index.ts` — re-exports
