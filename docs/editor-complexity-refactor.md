# Editor Complexity Refactor

Tracking document for streamlining the panel editor system
(`panel/lib/shared/editors`, ~22k lines / 200 files). The domain complexity
(type system, reconciliation, presentation protocol) is real and stays; this
effort removes the *implementation* complexity layered on top of it, which
made the editor unreadable and bug-prone.

Update this document as phases land: mark items done, record decisions and
surprises. It is the recovery point if agent context is lost.

## Phase 0 — Editor state reliability (DONE)

Shipped in commits `0c61b44d` and `883dfa12`.

Symptoms fixed: fields stuck on "Pending" forever, saves that sometimes never
happened, typed values visually rolled back, the priority field losing focus
per keystroke.

Root causes and fixes:

- Save state was *recorded* in four parallel maps (`_dirtyPaths`,
  `_conflicts`, `_saveStates`, `_interactions`) that desynchronized and were
  never pruned. Now: `EditorPathStates` — one pruned map of
  `EditorPathRecord { EditorPathProgress? progress, gate }` where
  `EditorPathProgress` is a sealed union (pending / saving / failed /
  contended / conflicted / settled). Phases are derived from live facts;
  "pending forever" is unrepresentable.
- `beginInteraction` cancelled the shared debounce timer and gated its path
  forever if blur never fired. Now: a gate only exempts its own path from
  autosave; the timer is never cancelled by focus; ending an interaction
  flushes everything dirty.
- Interaction lifecycle was hand-rolled per renderer with `useRef`. Now:
  `useEditorFieldInteraction` — begins on focus, commits on blur *and*
  unmount *and* reference change, cancels only explicitly.
- Widget keys embedded values (`ValueKey((reference, value))`) so every
  keystroke destroyed the field element. Now: keys are stable per binding
  reference.
- Insert-mode ownership in `InputFieldContainer` used stale build-time
  closures; moving focus between two fields clobbered the gaining field's
  mode and kicked focus out. Now: fresh reads + explicit takeover when
  another field still owns the mode.

Interaction semantics (decided, do not regress):

| Action | Result |
|---|---|
| Blur / click elsewhere / Tab | commit |
| Escape (`DismissIntent`) | leave field, commit |
| Field unmount / editor close | commit |
| `CancelIntent` = adaptive Ctrl+Escape (⌘⎋ on Mac) | revert to focus-session origin, leave field |
| Overlay pickers (color popup, search) | Escape still cancels the preview |

Key tests: `test/shared/editors/application/transactional_editor_source_test.dart`,
`test/shared/editors/presentation/editor_interaction_lifecycle_test.dart`,
`test/shared/editors/presentation/editor_surface_focus_test.dart`.

## Phase 1 — Structural simplification (DONE)

### 1.1 Collapse the renderer dispatch pyramid (DONE)

Was: `PresentationNodeRenderer` switch → 8 category extensions on
`PresentationElement` (`InputElementRendering` → `ScalarInputRendering` /
`SimpleInputRendering` / `CompositeInputRendering`, ...) → per-element
extensions → private widgets. Categories existed only to share import
headers; they added `(this as X)` casts and `_ => SizedBox.shrink()`
fallbacks that silently rendered nothing when a dispatcher was missed.

Now: `node_renderer.dart` holds one exhaustive `switch` over all 46 concrete
elements calling per-element `render` extensions directly; all 8 category
dispatch extensions are deleted; composites share a `_renderResolved`
prologue in `composite_input_renderer.dart` (absorbed by 1.2 later). No `_`
fallback — the compiler enforces element coverage.

Decision: the `part of` library groupings stay for now — they exist to share
library-private helpers, and untangling 55 files is churn without the
dispatch pain. Revisit after 1.2 shrinks the shared-helper surface.

### 1.2 Extract the bound-control shell (DONE)

Was: every input renderer repeated resolve binding → `TypeFailure` check →
diagnostic widget → type-shape validation → editability computation →
`LabeledControl` wrap → interaction wiring. Three different editability
formulas existed (`_bindingLocked`, `!scope.enabled || scope.readOnly ||
!binding.writable`, `scope.enabled && binding.writable`).

Now: `BoundControlShell` owns resolution, shape diagnostics, interaction
lifecycle, label wrapping, and the single editability calculation. It exposes
`BoundControlField` (`binding`, `enabled`, `readOnly`, `editable`, `locked`,
`interaction`, `update`) to the leaf. All protocol input renderers and the
three composite inputs use it; direct binding resolution remains only in the
shell and `ProtocolBoundValueEditor` (the latter is a recursive default-
presentation host, not an input leaf).

Label ownership is explicit through `labeled: false` for controls whose
chrome is rendered elsewhere (toggle headers and composite collection
surfaces), preserving their existing layout. Text-like duration/bytes fields
also gained stable binding keys and the shared interaction lifecycle while
being migrated.

### 1.3 Flatten the text-field tower (DONE)

Was: `ValidatedTextField` → `FormattedTextField` → `DecoratedTextField` →
`InputFieldContainer` → `TextFormField`; ~12 callbacks were re-declared per
layer (adding `onCancel` touched four files).

Now: `EditorTextField` replaces both text-specific layers. It owns
controller/focus synchronization, raw `InputDecoration`, prefix/hint
conveniences, single/multiline formatting, validation callbacks, and builds
directly on `InputFieldContainer`. `ValidatedTextField` remains a thin
parse/validate skin over it. All feature, test, and Widgetbook consumers use
the single component.

Constraint: `InputFieldContainer` is a shared primitive with consumers
outside the editor text stack (pages-editor dropdown,
`multiselect_dropdown`, `search_input_row`). It must remain a standalone
reusable component; the flattening only collapses the text-specific layers
above it.

### 1.4 Delete pass-through and lifecycle waste (DONE)

- Deleted `EditorController` and its forwarding test. `EditorSurface`,
  `EditorRoot`, `TypedEditor`, inspector, stories, and tests consume
  `EditorSource` directly. `editorProvider` is now a plain provider whose
  override explicitly owns and disposes the source.
- `EditorProtocolRenderer.didUpdateWidget` refreshes its existing
  `TransactionalEditorSource` instead of disposing it. External value changes
  receive `source.document.revision + 1`; metadata-only changes retain the
  current revision. Active drafts, focus, interactions, and expansion state
  survive parent rebuilds. A widget test proves metadata refresh preserves a
  focused unsaved draft.

## Phase 2 — Focus/mode coordination and rebuild scoping (DONE)

- `InputFieldModeCoordinator` (DONE): one `FocusManager` listener owns
  interaction-mode transitions. Containers register their focus nodes instead
  of watching global mode, scheduling post-frame focus work, and independently
  inferring ownership. Direct focus transfer between fields now changes insert
  ownership without briefly returning to normal mode.
- Stable editor definition (DONE): cache registry construction, path
  type resolution, presentation selection, substitutions, and binding-type
  derivation against `EditorDocument` identity. Local draft edits preserve that
  identity. Expression context and `localizeFailures` remain dynamic because
  their diagnostics can depend on the current value.
- Consider per-binding rebuild scoping only if profiling still shows churn.

## Phase 3 — Headers and virtual bindings (DONE)

- Header expansion identity (DONE): `HeaderExpansionKey` is an explicit union
  for node-bound and instance-bound state. Every header supplies a key, the
  expansion store accepts only keys, and `PresentationHeaderChrome` no longer
  canonicalizes bindings or guesses identity changes in `didUpdateWidget`.
- Header resolution (DONE): declarative headers combine first and then resolve
  into immutable `_ResolvedPresentationHeader` and `_ResolvedHeaderItem`
  models. Expression evaluation and command derivation stay in
  `header_action_resolution`; widgets, shortcuts, overflow menus, and
  confirmation dialogs live in `header_renderer`.
- Virtual bindings (DONE): `VirtualBindingHost` explicitly owns the current
  snapshot, path updates, interaction target, and local action execution.
  `PresentationRenderScope` only delegates to the host. Sequential actions bind
  the latest hosted value instead of repeatedly evaluating against the initial
  snapshot.

## Out of scope (deliberate)

- `domain/types` (type system), `EditorReconciler`, merge policies — clean,
  pure, well-tested.
- Search-source family and skir codec layer — repetitive but mechanical and
  isolated.

## Known pre-existing failures (not from this work)

- `test/app/presentation/theme/typewriter_design_system_golden_test.dart`
  golden diffs and `design_system_guardrails_test.dart` violations (color
  picker internals, badge/chip renderers, etc.) predate this refactor.

## Progress log

- Phase 0 landed: state engine rewrite, interaction semantics, focus fixes,
  regression tests. Full panel suite green except pre-existing failures
  above.
- Committed as four logical commits ending at `883dfa12`; pushed to `local`
  as `features/refactor-data-blueprint-type-system-agent`.
- Phase 1 landed in four commits ending at `33f7c6f1`: exhaustive renderer
  dispatch, the bound-control shell, the flattened text-field stack, and direct
  `EditorSource` ownership.
