# Highlight

Renders `==highlighted text==` as `<mark>`, the markdown-it-mark / Obsidian
convention.

## Syntax

```markdown
This is ==important== to know.
```

No attributes.

## Matching rules

The delimiters must hug their content, loosely mirroring CommonMark's flanking
rules:

| Input | Result |
| ----- | ------ |
| `==yes==` | highlighted |
| `== no ==` | literal |
| `====` | literal |
| `==a== and ==b==` | two highlights |

Matching is non-greedy and runs per `text` node, so:

- text inside `inlineCode` is a different node type and is never matched;
- a highlight cannot span other nodes.

## Limitations

- **Inline formatting inside a highlight is not supported.** `==**bold**==`
  arrives as three sibling nodes (`text` `==`, `strong`, `text` `==`), and this
  plugin only splits within one `text` node, so the `==` stay literal. Write
  `**==bold==**` instead.
- **`\==` is not honoured.** CommonMark consumes the backslash before this
  plugin runs (`=` is escapable punctuation), so the escape is invisible here.

## Styling

Translucent site primary (`--color-primary-rgb` at 22%) with `text-inherit`, so
it overrides the UA stylesheet's black-on-yellow and stays readable in both
themes. `box-decoration-clone` keeps the rounded corners on every line of a
highlight that wraps.

## Files

- `styles.ts` — Tailwind class strings
- `remark-highlight.ts` — the `remarkHighlight` plugin
- `index.ts` — re-exports
