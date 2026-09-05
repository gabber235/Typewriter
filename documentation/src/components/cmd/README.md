# Cmd

Renders a command as a monospace chip that copies itself when clicked.

## Syntax

```markdown
:cmd[/tw reload]
:cmd[tw reload]
:cmd[/tw connect]{nocopy}
```

- A leading `/` is rendered dimmed. It is never added — `:cmd[tw reload]` stays
  slashless.
- The copied text is the **full** label, slash included.
- Directives resolve inside the label, so `:cmd[/tw version :var[latest]]` works
  (`remarkVariables` runs before `remarkCmd`).

## Attributes

| Attribute | Effect |
| --------- | ------ |
| `nocopy` | Renders an inert `<span>` chip: no button, no icon, no click handler |

## Behaviour

- The chip *is* a `<button type="button">`, so clicking anywhere on it copies,
  and Enter/Space work for free.
- Copy uses `navigator.clipboard.writeText`, falling back to a hidden textarea
  plus `document.execCommand("copy")` on insecure origins or when the permission
  is denied. Nothing happens if both fail.
- On success the chip gets `data-copied="true"` for 1.5s: the copy icon
  cross-fades to a green check and the border turns green. Both icons live in
  one `1em` grid cell, so the swap cannot change the chip's width, height or
  baseline. The cross-fade is skipped under `prefers-reduced-motion`.
- A "Copied" pill fades in above the chip for the same 1.5s. It is
  `position: fixed` with left/top computed in JS from the chip's rect, so no
  `overflow` ancestor can clip it, and it is `pointer-events-none`. It flips
  below the chip when there is no room above, and follows the chip on scroll and
  resize. "Room above" is measured against the chip's nearest scrolling
  ancestor, not the viewport, because the docs body scrolls inside a pane that
  starts below a fixed header.
- Repeated clicks reposition the same pill and restart the single reset timer;
  clicking a different chip clears the previous one's state first. There is one
  timer and one pill for the whole page.
- The accessible name stays `Copy command <cmd>` throughout — renaming a control
  mid-press is announced unreliably and breaks voice control — so the
  confirmation goes through a `role="status" aria-live="polite"` region appended
  to `<body>`. The pill itself is `aria-hidden`.
- Hover tints the border and fill and brings the copy icon to full opacity, but
  deliberately not the label.

## Client script

`cmd.ts` exports `setupCmdCopy()`, imported once from `CmdRuntime.astro`, which
is itself included once from `Head.astro`.

The listener is a single delegated `click` on `document`, guarded by a module
level `bound` flag. That matters because the site uses Astro's `ClientRouter`:
per-element listeners would be lost on every view-transition swap, and a
re-executed setup would otherwise stack duplicate listeners. The live region is
re-appended if a swap detached it.

## Files

- `styles.ts` — Tailwind class strings
- `remark-cmd.ts` — the `remarkCmd` plugin, inline SVG icons and the icon slot
- `cmd.ts` — client controller (`setupCmdCopy`): clipboard write, copied state,
  pill positioning, live-region announcement
- `CmdRuntime.astro` — renders nothing, carries the `<script>`
- `index.ts` — re-exports
