# Keyboard

Everything in the panel can be done from the keyboard, and the keyboard is the fastest way to do it. The
visible modes are part of the product's character: a machine that shows which state it is in.

## The model

- **Normal mode** is for commands. Single keys act. Arrows and H, J, K, L move focus.
- **Insert mode** is for typing. A field entering focus enters it, and Esc leaves it.
- **Surface modes** extend Normal where a surface needs them: Move and Resize on graph and timeline.
- **A command** is one action with one definition: `key + scope + action`. Buttons, menus, the command
  list, and shortcuts all invoke it through the same path, using an Intent.

## Rules

### KB-01 MUST: Everything works without a pointer

Every action, including drag, hover reveals, context menus, and canvas panning, has a keyboard path.

- Why: this is a product requirement, not an accessibility extra.
- Check: `test`.
- Broken: severity 3.
- Do: a hidden email is revealed by focusing its row.
- Don't: `BlurReveal` reveals only on pointer hover.

### KB-02 MUST: The current mode is always visible

The mode chip shows the current mode, and it updates when the mode changes.

- Why: a modal tool without a visible mode is how people get lost.
- Check: `test`.
- Broken: severity 3.

### KB-03 MUST: One command list

Every command appears in the command list (Ctrl or Cmd+K) with its key, and `?` opens the full list for the
current scope.

- Why: this is how people find actions and learn shortcuts.
- Check: `test`.
- Broken: severity 3.
- Do: "Rename" with its key beside it.
- Don't: a command that exists only as a key or only as a button.

### KB-04 MUST: No dead keys

No default binding uses a key the browser or the operating system takes first.

- Why: a key that does nothing looks like a broken product.
- Check: `lint` against a reserved list.
- Broken: severity 3.
- Reserved in the browser: Ctrl or Cmd+N, T, W. Reserved by Windows: Ctrl+Esc.
- Don't: `Ctrl+N` for next focus, `Ctrl+Esc` for cancel (`shortcuts.dart:31,37`).

### KB-05 MUST: Single keys can be turned off or remapped

A setting turns single key commands off or remaps them, unless a key only works while its control has focus.

- Why: WCAG 2.1.4, Level A. Speech input and stray presses can fire single keys.
- Check: `test`.
- Broken: severity 3.

### KB-06 MUST: Tab between, arrows within

Tab moves between controls and groups. Arrows move inside lists, trees, tables, and menus. Esc steps back
out, one level at a time.

- Why: the established pattern from the WAI ARIA practices, and what users expect.
- Check: `test`.
- Broken: severity 2.

### KB-07 MUST: Focus is never lost

Closing or removing something moves focus to a sensible neighbour or back to its opener, never to nothing.

- Why: a keyboard user with no focus position has nowhere to go from.
- Check: `test`.
- Broken: severity 3.
- Do: deleting a row focuses the next row.
- Don't: deleting a row leaves focus on the page.

### KB-08 MUST: Dragging has both alternatives

Anything draggable has a keyboard path and a single pointer path that needs no drag.

- Why: WCAG 2.5.7, Level AA. A keyboard path alone does not meet it.
- Check: `test`.
- Broken: severity 2.

### KB-09 MUST: Flutter semantics stay reachable

Semantics are available to assistive technology on web, and the reviewer's captures include a semantics dump.

- Why: Flutter web turns semantics off by default for performance.
- Check: `semantics`.
- Broken: severity 3.

## Open

- Replacement for `Ctrl+Esc` (Windows takes it). `Ctrl+N` and `Ctrl+P` can go: arrows and J, K cover them.
- The full key map per scope.
