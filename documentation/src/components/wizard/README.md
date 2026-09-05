# Wizard

A decision-tree directive for "which entry / approach do I need?" pages. Authors
write a plain nested markdown list; readers click through one question at a
time and land on a recommendation with working links.

## Syntax

```markdown
:::wizard[Which dialogue entry do I need?]
- Should the player see text?
  - Yes → Should they pick an option?
    - Yes → Use the [Option Dialogue](../reference/option-dialogue.md) entry.
    - No → Use the [Spoken Dialogue](../reference/spoken-dialogue.md) entry.
  - No → Look at the [action entries](../reference/actions.md) instead.
:::
```

Rules:

- When the list has a **single top-level item** with a nested list and no
  arrow, that item is the **root question** and the directive label (if any) is
  shown as a small title above the wizard. Otherwise the label is the root
  question and every top-level item is one of its answers.
- Every list item is an **answer**. Text before the first `→` (or `->`) is the
  answer label; text after it is either the **follow-up question** (when the
  item has a nested list) or the **result** (when it does not).
- An item with a nested list but no arrow uses its whole text as both the answer
  label and the follow-up question.
- An item without a nested list and without an arrow shows its whole text as
  both the answer label and the result.
- Results and questions are arbitrary inline markdown. Links stay real `link`
  nodes, so relative links are rewritten by Starlight at build time and
  glossary terms are still linked.
- Answer labels may contain formatting and `code`, but links in labels are
  downgraded to plain spans (a button cannot contain a link).
- Only one arrow per item is interpreted (the first one in a top-level text
  node). An arrow inside `**bold**` or a link is left alone.

## Attributes

| Attribute   | Effect                                                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------------------------ |
| `{persist}` | Remembers the reader's answer path in `sessionStorage` (keyed by page path + wizard index) and restores it on load. |

## Behaviour

- One question at a time. Answers are whole-card buttons with a chevron.
- **The box never changes size.** Every reachable panel — each question and
  each result — is built up front, stacked absolutely in the stage, and the
  stage's `min-height` is set to the tallest of them. Choosing an answer,
  going back and starting over leave the outer height, the footer position and
  the page scroll position untouched.
- Header is a single fixed-height row (`min-h-6`) holding the **trail of
  chips** on the left and the **counter** on the right ("Question 2 of 3",
  where the total is the longest remaining path from the current step). The
  trail never wraps: it scrolls horizontally, auto-scrolls to the newest chip,
  and gets a fading right edge only while it overflows. Clicking a chip jumps
  back to that question with the previously chosen answer focused.
- Footer has **Back** and **Start over**. Both are always rendered and only
  become `disabled` at the root.
- The **result card** is primary-tinted with a check icon and a
  "Recommendation" label; its body is the rendered inline markdown.
- Keyboard: `↑/↓/←/→` move between answers (wrapping), `Home`/`End` jump,
  `Enter`/`Space` select (native button), `Escape`/`Backspace` go back.
- Focus management: choosing an answer focuses the first answer of the next
  question (or the result card); going back focuses the answer that was
  previously chosen. Initial render does not steal focus. Every `focus()` call
  passes `preventScroll: true`.
- A visually hidden `aria-live="polite"` region announces
  "Question n of N: …" / "Recommendation: …" on every step change. The question
  panel is `role="group"` labelled by the question; the result is a labelled
  `region`; the trail is a `nav` whose `aria-label` includes the wizard's own
  title (or root question), so several wizards on one page stay distinguishable
  in a landmark list.
- Transitions: steps **crossfade** in place (180 ms opacity, `ease-out`).
  Under `prefers-reduced-motion` the swap is instant.
- Works with Astro's `ClientRouter` view transitions: `WizardRuntime.astro`
  (included once from `Head.astro`) runs `setupWizards` on `astro:page-load`
  and `astro:after-swap`; a `data-wizard-ready` flag makes it idempotent.
- Multiple wizards per page are independent.
- No-JS / crawlers: the remark plugin only wraps the label and the nested list
  in `div[data-wizard]`, so the full tree renders as ordinary markdown. The
  client hides the source list (`hidden`) and prepends the interactive UI.

## Files

| File                  | Role                                                                     |
| --------------------- | ------------------------------------------------------------------------ |
| `remark-wizard.ts`    | Turns `:::wizard` into `div[data-wizard]` + `p[data-wizard-question]` + the list. |
| `wizard.ts`           | Client entry (`setupWizards`): state, events, focus.                     |
| `parse.ts`            | DOM list → question/answer tree.                                         |
| `render.ts`           | Builds the shell, panels and trail chips.                                |
| `stage.ts`            | Panel crossfade and stage sizing.                                        |
| `tree.ts`             | Pure tree helpers (path resolution, depth, panel keys).                  |
| `persist.ts`          | `sessionStorage` read/write for `{persist}`.                             |
| `WizardRuntime.astro` | Script-only component that registers `setupWizards` on router events.   |
| `styles.ts`           | Tailwind class strings (`as const`).                                     |
| `types.ts`            | Tree and runtime types.                                                  |

## Limitations

- One root question per directive; extra top-level items (when a label is
  present, all of them; without a label, everything after the first) are
  ignored by the client but still render in the no-JS fallback.
- Arrows are only recognised in top-level text of an item, so an arrow inside
  bold/italic/link text is not a separator.
- The step counter's total is an upper bound (longest remaining branch), so it
  can shrink as the reader picks shorter branches.
- The stage is as tall as the **tallest** panel, so a flow with one long result
  card leaves visible empty space under the short questions; keep results to a
  few lines.
- Deep trees stay usable but the chip trail scrolls sideways rather than
  wrapping; keep flows to ~4 levels so the trail stays readable on mobile.
- Panels are measured with a debounced `ResizeObserver`, so a width change (or
  a late web font) is picked up ~120 ms later, not in the same frame.
- `{persist}` keys by page path and wizard order on the page; reordering
  wizards changes which stored path applies (an invalid path is truncated).
- Block content inside items (code fences, nested paragraphs) is carried into
  the result card but is not styled beyond basic paragraph spacing.
