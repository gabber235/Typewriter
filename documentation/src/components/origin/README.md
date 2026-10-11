# AI disclosure badge

A small icon and label in the page footer, next to "Edit this page" and
"Updated ... by", stating how much of the page an AI wrote.

## Usage in frontmatter

```markdown
---
title: Writing Syntax
aiDisclosure: human-assisted
---
```

Optional. Pages without `aiDisclosure` show no badge.

## The scale

Six levels, ordered from no AI involvement to fully AI-written.

| Level | Meaning |
|---|---|
| `human` | Written and edited by a person. No AI was used. |
| `human-checked` | Written by a person; AI was used only to check grammar and spelling. |
| `human-assisted` | Written by a person, using AI along the way for research, examples, or wording. |
| `ai-drafted-rewritten` | An AI wrote the first draft; a person substantially rewrote and verified it. |
| `ai-drafted-reviewed` | An AI wrote the draft; a person reviewed it and made small edits. |
| `ai-generated` | Written entirely by AI and published without human changes. |

## Icons

Two base glyphs, a person and a chip, for who held the pen more. A small
top-right accent shows how much the other party did, shrinking as the scale
moves toward `ai-generated`:

`human` (person) → `human-checked` (person + check) → `human-assisted`
(person + spark) → `ai-drafted-rewritten` (chip + pen) →
`ai-drafted-reviewed` (chip + check) → `ai-generated` (chip alone).

## Files

- `types.ts` — the ordered level list and the Zod schema for `aiDisclosure`.
- `levels.ts` — display copy per level.
- `icons.ts` — the six custom SVGs.
- `styles.ts` — Tailwind classes matching the footer's other meta items.
- `OriginBadge.astro` — renders the icon and label.
- `index.ts` — re-exports.

## Wiring

`content.config.ts` extends the docs schema with `aiDisclosure: originSchema`.
`footer/Footer.astro` renders `<OriginBadge>` next to "Edit this page" when
the field is set; splash pages (the homepage) show no page meta at all, so a
badge there would need its own placement.

## Decisions worth knowing

- **No colour judgement.** Every icon uses the site's plain text colour, not
  a red-to-green scale. AI involvement is disclosed, not scored as good or
  bad.
- **Always visible, not behind a hover.** The label is plain text next to
  its icon, read at a glance like its neighbours. The longer one-sentence
  description sits in the element's `title` attribute as a bonus for anyone
  who wants it, never as the only way to reach the core disclosure.
- **This project isn't in the EU AI Act's Article 50 mandatory scope.** That
  obligation targets text published on matters of public interest
  (political, financial, scientific, cultural), not Minecraft plugin
  documentation — so this badge is a voluntary transparency practice, not a
  compliance claim. Its always-visible label follows Article 50's own
  guidance anyway, since that's simply the more honest way to disclose this.
- **Six levels, not five.** `human-assisted` (AI used as a tool throughout,
  by a person who still wrote the piece) sits between "grammar-checked only"
  and "AI wrote the first draft" because those are meaningfully different
  claims about who actually authored the content.
