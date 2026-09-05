# TL;DR

A quiet "key takeaways" block meant to sit near the top of a long page. It is
deliberately *not* a callout — it summarises the page you are already on,
rather than interrupting it with a warning or a tip.

## Syntax

```markdown
:::tldr
Facts are per-player variables. Writable facts are set from a **modifier**;
readable facts are checked from a **criteria**.

- `Permanent` facts survive restarts, `Session` facts don't
- Criteria run before an entry triggers, modifiers run after
:::
```

Custom label:

```markdown
:::tldr[Before you start]
Same body rules apply.
:::
```

- `[Label]` is optional. Default label: `TL;DR`.
- The label is rendered as written — it is **not** upper-cased — so
  `[Before you start]` stays in sentence case.
- No attributes, no `{variant=...}` — one deliberately opinionated look.

## Behaviour

- The card is a `role="note"` labelled by its own eyebrow, via
  `aria-labelledby` pointing at a per-block `tldr-label-N` id. `note` is a
  section role, not a landmark, so a screen reader can tell where the summary
  starts and ends without every page adding one more "complementary" entry to
  its landmark list — which is what `<aside aria-label>` would have done.
- Unordered lists get an explicit `role="list"`, because `list-style: none`
  drops the list role in Safari/VoiceOver and the bullet here is a `::before`
  dash, not a marker. Ordered lists keep their markers, so they keep their role
  and are left alone.
- The counter that produces `tldr-label-N` restarts per markdown file, so ids
  are unique per page but not globally.

## Files

- `remark-tldr.ts` — the plugin, transforms `containerDirective` nodes named
  `tldr` into the summary block's hast tree
- `styles.ts` — Tailwind class strings
- `index.ts` — re-exports

## Limitations

- Intentionally has no variants — if a page needs more than one visual
  flavour of "summary block", that's a sign the content should be split rather
  than the component extended.
- Length is not enforced. Three facts, five at the very most, one block per
  page is guidance for authors, not something the plugin can lint.
