# Conflict review

Overlay in the editor. Stories under `.xtask/results/stories/authoring/presentation/`:
`authoringconflictnotice/retained-conflict` (`initial`, `dark`, four `Saved-Realm` values each with
`Saved-values=Readable|Unreadable`), `authoringconflictcomparison/complete-group-comparison`
(`initial`, `dark`, `Saved-Realm=Renamed-elsewhere|Renamed-twice-elsewhere|Name-cleared-elsewhere|Removed-elsewhere`),
and as supporting evidence `realmeditingreview/retained-rename`.
Source: `panel/lib/authoring/presentation/authoring_conflict_notice.dart`,
`authoring_conflict_comparison.dart`, `realm_editing_review.dart`,
`authored_resource_inspection.dart` (where the notice sits), `panel/lib/authoring/application/realm_editing.dart`
(resolution), `panel/lib/shared/theme/component_themes.dart`.
Key paths were checked with a throwaway widget test built on `pumpStory` (deleted after the run);
"probe" in evidence below refers to it.

## Summary

Not good yet. The surface explains the conflict honestly and keeps the user's edits, but its
weightiest action is unsafe: `Use saved` throws away every unsent change in the group on one
press, with no hold and no undo. The review opens as a stock AlertDialog at the centre with nothing
focused, no action has a key, and when it cannot keep the user's work it prints a raw
`Bad state: The resource is absent`.

The single most valuable change: put `Use saved` behind the hold (or give it Undo), and grow the
review out of the notice with focus on `Keep mine` and Ctrl or Cmd+Enter running it.

## Findings

- id: CONFLICT-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Use saved button, comparison footer (in the review dialog and in the comparison story)"
  evidence: "authoring_conflict_comparison.dart:141-144; realm_editing.dart:178-189 (useSaved passes replacement null to replaceUnsubmitted, editing_workspace.dart:1232, no undo); probe: Tab to Use saved, Enter, the comparison vanished at once and no hold or question appeared"
  observed: "One press discards every unsent change in the editing group. No hold, no outcome line with a count, no Undo. The only warning is a sentence above the buttons."
  fix: "Make Use saved a hold that types the outcome, such as `Discard 1 change to Main quest?`, or keep the discarded edits struck through with Undo."

- id: CONFLICT-2
  rule: "A page or surface opens"
  severity: 3
  region: "Review changes dialog"
  evidence: "probe: after Enter on Review changes, primaryFocus is the dialog route's _ModalScopeState focus scope; the first Tab reaches Use saved"
  observed: "Opening the review focuses nothing. The first Tab lands on Use saved, the destructive choice, not on the main action."
  fix: "Focus Keep mine when it is available, otherwise the first comparison value, when the review opens."

- id: CONFLICT-3
  rule: "Adding an action"
  severity: 3
  region: "Review changes, Use saved, Keep mine, Refresh review, Close"
  evidence: "authoring_conflict_notice.dart:22-45, authoring_conflict_comparison.dart:138-151, realm_editing_review.dart:309-312 (plain TextButton and FilledButton onPressed, no Intent); probe: Ctrl+Enter in the open dialog left it open and changed nothing"
  observed: "No action is a command. None has a key or key cap, none is in the command list, and Ctrl or Cmd+Enter does not run Keep mine. Reaching an action needs Tab walking."
  fix: "Make each choice an Intent. Bind Ctrl or Cmd+Enter to Keep mine, show key caps, and list the choices in the command list while the review is open."

- id: CONFLICT-4
  rule: "Something fails"
  severity: 3
  region: "Keep mine after a second save elsewhere (Renamed twice elsewhere)"
  evidence: "authoring_conflict_comparison.dart:73-81 and 132-133; probe: after Enter on Keep mine the message `These changes changed again. Review the current values` sits at y 442 while Keep mine is at y 568; focus stays on Keep mine and a second Enter repeats"
  observed: "The button does not shake or flash red. The message appears above the explanation text, 126 px away from the control, and pushes the buttons down because no space was reserved. Pressing again does repeat the action and the edits are kept."
  fix: "Jam Keep mine, show the message directly under it in reserved space, and keep the rest of the layout still."

- id: CONFLICT-5
  rule: "Misreading would cost the user something"
  severity: 3
  region: "Line above the footer when Keep mine is unavailable; the unreadable review message"
  evidence: "story complete-group-comparison/Saved-Realm=Removed-elsewhere.png; authoring_conflict_comparison.dart:131 prints `review.unavailableReason` verbatim (authoring_conflict_review.dart:44); realm_editing_review.dart:288-291"
  observed: "When the quest was removed elsewhere the page shows `Bad state: The resource is absent`, a raw exception, and Keep mine is greyed with no reason a user can read. When saved values cannot be read the message `Current saved values are unavailable. Your edits are retained.` says what happened but not what to do next."
  fix: "Write the reason in plain words with the next step, such as `Main quest was removed in the Realm. Use saved to drop your change, or recreate the quest.` For the unreadable case add `Press Refresh review to try again.`"

- id: CONFLICT-6
  rule: "Something happens that the user did not just do"
  severity: 3
  region: "Saved values changed notice at the top of the inspector"
  evidence: "authoring_conflict_notice.dart:18-19 (title and sentence only); story retained-conflict/initial.png"
  observed: "The notice says saved values changed but not who changed them or where. No chip with the other person's avatar or name. Motion and layout parts are MOTION-21 and the resource editor note that the notice pushes the editor down."
  fix: "Show a chip with who saved, as their avatar, and from where (another panel, the game), beside the notice title."

- id: CONFLICT-7
  rule: "A task needs more room than its place has"
  severity: 3
  region: "Review changes opens the comparison"
  evidence: "authoring_conflict_notice.dart:23-44 (showDialog with AlertDialog, fixed width 700); probe: dialog shown, Esc closes it and focus returns to Review changes"
  observed: "The review strikes in at the centre over a dimmed page as a stock AlertDialog with the framework transition, not growing out of the notice with `surfaceIn`. Nothing else is blocked by a conflict, so it is not a question that may use a dialog. Raised to 3: opening something is an everyday move. Esc and focus return work."
  fix: "Grow the notice into the review surface with `surfaceIn`; Esc shrinks it back into the notice."

- id: CONFLICT-8
  rule: "One thing shows in several places"
  severity: 2
  region: "Fact titles in the comparison"
  evidence: "story complete-group-comparison/Saved-Realm=Removed-elsewhere.png and Name-cleared-elsewhere.png; authoring_conflict_comparison.dart:93 labels each fact with `review.saved`, and 252-255 falls back to `Removed resource`"
  observed: "The quest is named from the saved Realm only: `Removed resource.name`, `Resource Removed resource`, `Configuration of Removed resource`, and `tag.name` when its name was cleared. The user's own Main quest never appears under its name, and raw paths such as `.name` and the type key `tag` show."
  fix: "Name the resource from the user's proposal or the original, never `Removed resource`, and show field display names in sentence case."

- id: CONFLICT-9
  rule: "Naming an action"
  severity: 2
  region: "Column headings in the comparison and in the editing group review"
  evidence: "authoring_conflict_comparison.dart:101, 106, 111; realm_editing_review.dart:368, 378, 388; stories complete-group-comparison/initial.png and realmeditingreview/retained-rename/initial.png"
  observed: "One situation uses two vocabularies: `Before your changes`, `Your proposal`, `Saved now` against `Before changes`, `Working`, `Saved`. The choices then say `Keep mine` and `Use saved`, which match neither set."
  fix: "Pick one set and use it in headings and choices, such as `Before`, `Mine`, `Saved`, with `Keep mine` and `Use saved`."

- id: CONFLICT-10
  rule: "Choosing an action's weight"
  severity: 2
  region: "Keep mine, comparison footer; dialog actions"
  evidence: "authoring_conflict_comparison.dart:145; authoring_conflict_notice.dart:37-42; story complete-group-comparison/initial.png"
  observed: "The filled main action sits in the body footer, not in the surface header on the right. The dialog then adds Refresh review and a second Close row below it, so four quiet and filled buttons are spread over two rows."
  fix: "Put Keep mine in the review header, right side, with its key cap; make Refresh review and close header controls."

- id: CONFLICT-11
  rule: "Placing content"
  severity: 2
  region: "Comparison cells under each fact title"
  evidence: "authoring_conflict_comparison.dart:157-159 (Padding all space2); story complete-group-comparison/initial.png: `Side quest.name` at x 362, `Before your changes` at x 370"
  observed: "Each comparison cell is padded on all sides, so the cell labels start 8 px right of the fact title above them. The button row is inset again (SHARED-CONFLICT-2)."
  fix: "Drop the outer cell padding on the start side so title and cells share one left edge."

- id: CONFLICT-12
  rule: "Content is on screen and refreshing"
  severity: 2
  region: "Loading current saved values line, Refresh review"
  evidence: "realm_editing_review.dart:287 (const Text, no ripple, shown at once), 296 (`enabled: !reading` disables both choices), 309-312"
  observed: "Refresh review shows a still `Loading current saved values` line above the comparison, appears without the 300 ms grace, and greys both choices. The Refresh review button itself shows no busy state. Kept at the rule's 2: no image shows this state to confirm it a second way."
  fix: "Keep the comparison, ripple the status word with `ripple` after 300 ms, and press Refresh review in while it reads."

- id: CONFLICT-13
  rule: "A control is busy or unavailable"
  severity: 2
  region: "Keep mine when unavailable or while reading"
  evidence: "story complete-group-comparison/Saved-Realm=Removed-elsewhere.png; component_themes.dart:138-144"
  observed: "Unavailable Keep mine is faded to a 12% brand fill with disabled text, not pressed in like a held key. Disabled text contrast is RESOURCE-7."
  fix: "Draw unavailable and busy controls pressed in, and say why at the control."

- id: CONFLICT-14
  rule: "Anything leaves"
  severity: 2
  region: "Notice and comparison after resolving"
  evidence: "authored_resource_inspection.dart:97-101 (`if (needsReview)` with no transition); authoring_conflict_notice.dart:33 (Navigator.pop); story _Comparison returns SizedBox.shrink"
  observed: "After Keep mine or Use saved the dialog leaves with the framework route exit (MOTION-10) and the notice is dropped from the column at once; the editor below jumps up."
  fix: "Shrink the review back into the notice, then close the notice with `listOut` so the editor follows."

- id: CONFLICT-15
  rule: "A surface is new or changed"
  severity: 2
  region: "Conflict stories"
  evidence: "retained-conflict `Saved-values=Unreadable` images are identical to `Readable`; no image of the open review"
  observed: "The story offers Unreadable saved values but no image shows it. No image shows the review as users see it (inside the dialog with Refresh review and Close), loading, the failure message after a stale Keep mine, hover, focus, or a compact width under 560 px where cells stack."
  fix: "Add stories with the review open for each state: loading, unreadable, stale choice rejected, Keep mine unavailable, focus on each button, and compact."

## Cannot verify

- "The focused thing disappears": in the editor the notice is removed once the group no longer needs review (authored_resource_inspection.dart:97), so focus returned to Review changes would land on a widget that is gone. The story keeps the notice, so the probe saw focus return to Review changes. A probe on the routed resource editor that resolves a conflict and reads primaryFocus would settle it.
- "Something happens that the user did not just do", layout part: whether the notice pushes the editor down while the user types. Already noted in the resource editor review; a probe comparing the editor's offset before and after a conflict arrives would settle it.
- "Choosing how strong a move is", "Any move runs": feel and retargeting, for a maintainer once tokens exist.
- Whether the editable looking fields in the Before and Saved columns of the editing group review (`realmeditingreview/retained-rename/initial.png`) accept input: they render `AuthoredResourceEditor` for historical documents. A probe typing into the Saved column would settle it.

## Rule results

<details>
<summary>Every checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | pass in the story (focus returns to Review changes after Esc and after Keep mine); editor path under Cannot verify |
| The focused thing disappears | cannot_verify |
| A page or surface opens | fail (CONFLICT-2) |
| Something happens that the user did not just do | fail (CONFLICT-6, MOTION-21) |
| A task concerns something on screen | pass (notice sits in the inspector of the resource) |
| A task needs more room than its place has | fail (CONFLICT-7) |
| Other work cannot continue until a question is answered | fail (CONFLICT-7, dialog used for a non blocking task) |
| The window is under 900 px, or a pane would be narrower than 320 px | cannot_verify (cells stack under 560 px in source, line 115; no compact image) |
| Anything needs saying | fail (CONFLICT-4) |
| Something succeeds | pass (the review closes; the result is visible) |
| Something fails | fail (CONFLICT-4, CONFLICT-5) |
| Several things fail at once | pass (one status line, first diagnostic only) |
| A change appears elsewhere on screen | fail (MOTION-21) |
| Something is empty | pass (`The saved values now match the original expectations.`; not a list) |
| The connection or a service is lost | cannot_verify (the unreadable state has no image) |
| A wait is too short to notice, under 300 ms | fail (CONFLICT-12) |
| Content is on screen and refreshing | fail (CONFLICT-12) |
| An action can be undone | fail (CONFLICT-1, Use saved has no Undo) |
| An action cannot be undone, or undo is not built yet | fail (CONFLICT-1) |
| Anything would skip those rules | fail (CONFLICT-1) |
| The user causes something to arrive | fail (CONFLICT-7) |
| Something exists before and after a change | fail (CONFLICT-7, CONFLICT-14) |
| Showing any state on something | fail (CONFLICT-13) |
| Anything changes state | fail (CONFLICT-4, status text appears without motion) |
| Anything grows or responds over time | fail (MOTION-6) |
| Text appears | fail (CONFLICT-4, no reserved space) |
| A key is in use | fail (CONFLICT-3, MOTION-7) |
| A control is busy or unavailable | fail (CONFLICT-13) |
| Anything leaves | fail (CONFLICT-14) |
| The pointer reaches something you can act on | fail (MOTION-3) |
| A button has a key | fail (CONFLICT-3) |
| Focus moves | fail (MOTION-4) |
| You cannot name what a move tells the user | pass (nothing loops) |
| Reduced motion is on | fail (MOTION-2) |
| Choosing how strong a move is | cannot_verify |
| Any move runs | cannot_verify |
| Adding an action | fail (CONFLICT-3) |
| Something works with one input | pass (no hover reveal or drag) |
| Moving around | pass (Tab walks Use saved, Keep mine, Refresh review, Close and wraps; Esc closes) |
| Choosing any key | pass (no keys chosen) |
| Setting any visual value | fail (authoring_conflict_notice.dart:28 width 700, realm_editing_review.dart:337 width 700 are literals) |
| Showing a state | pass |
| Choosing an action's weight | fail (CONFLICT-10) |
| Placing content | fail (CONFLICT-11, SHARED-CONFLICT-2) |
| Writing text | fail (SHARED-CONFLICT-1, RESOURCE-7) |
| Choosing a font | fail (RESOURCE-20) |
| Misreading would cost the user something | fail (CONFLICT-5) |
| Naming an action | fail (CONFLICT-9) |
| One thing shows in several places | fail (CONFLICT-8) |
| A shared component does the job | fail (AlertDialog is under Never; folded into CONFLICT-7) |
| A surface is new or changed | fail (CONFLICT-15) |
| Keyboard behaviour is new or changed | fail (no test covers focus on open or Ctrl+Enter; existing `authoring_conflict_story_test.dart` covers Enter on a focused button only) |
| Action walk: Any action, keys only | fail (CONFLICT-3) |
| Action walk: Any action that opens something, cancel it | pass (Esc closes the review, focus returns to Review changes) |
| Action walk: A failing action | fail (CONFLICT-4) |
| Action walk: An action that cannot be undone, modifiers | fail (CONFLICT-1; Shift+Enter did nothing, plain Enter discarded at once) |
| Action walk: Compact width | cannot_verify (no compact image) |

</details>

## Skill friction

- The skill sends shared faults to `cross-page.md`; this run was told to use a `## Shared` section instead. The skill should say which.
- Step 8 asks for a second way for severity 3, but a missing move can usually only be read from source. The everyday motion rule raises such findings to 3 while step 8 then cannot keep them; I kept CONFLICT-12 at 2 for that reason.
- The inventory lists Conflict review as one surface with two component stories, but users only meet it through the notice's dialog, which no story renders. Reviewing it needs a probe to see the real arrangement.
- "Other work cannot continue until a question is answered" and "A task needs more room than its place has" both judge a centred dialog at different severities; I used the second and raised it as an everyday opening move.
- The walk row "An action that cannot be undone" assumes a key; Use saved has none, so "press its key" became Enter on the focused button.

## Suggestions

- Purpose in two seconds: the notice reads as plain body text with a link. Give it the warning status colour as a small mark and the who chip (CONFLICT-6), so it reads as something that needs the user.
- Where the eye lands: in the comparison, on the bright Keep mine button, before the user has seen which value differs. Mark the differing cell (the saved value) with a small status colour so the eye finds the conflict first.
- What can be removed: the two explanatory sentences (`Compare your complete editing group...` and `These actions apply to all unsent changes...`) can become one line typed into the hold of Use saved, where the scope matters.
- Feels like this machine: the review is a stock Material dialog. Growing it from the notice and typing `Kept` or `Saved values used` into the notice as it closes would carry the panel's character.
- Expert speed: a daily conflict takes Tab, Enter, Tab, Tab, Enter. With CONFLICT-3, Ctrl or Cmd+Enter from the notice would keep mine in one chord.
- First time user: `Use saved` does not say it throws work away. Name the outcome, such as `Discard mine`.
- Rule gap, new row for Text: When a message comes from an exception or diagnostic, Then rewrite it in plain words before it reaches the screen; never show an exception type such as `Bad state:`. Sev 3.
- Rule gap, new row for Weight: When an action discards the user's unsent work, Then treat it as a remove action, with hold or Undo, even when nothing in the Realm changes. Sev 4.

## Shared

- id: SHARED-CONFLICT-1
  rule: "Writing text"
  severity: 3
  region: "Every TextButton and OutlinedButton label in the light theme (here Review changes, Use saved, Refresh review, Close)"
  evidence: "component_themes.dart:50-58 and 158 (`button(colors.brand)` sets the label to the brand fill); color_scheme.dart:10 (`#009FFF`); story retained-conflict/initial.png and complete-group-comparison/initial.png show the bright blue labels"
  observed: "Quiet button labels use the brand fill `#009FFF` as text. On the light canvas that is about 2.7:1, under 4.5:1. The Values table gives `#006FB8` as brand text on light."
  fix: "Use the brand text value for button labels: `#006FB8` on light, `#33AEFF` on dark."

- id: SHARED-CONFLICT-2
  rule: "Placing content"
  severity: 2
  region: "Any left aligned TextButton under text"
  evidence: "story retained-conflict/initial.png: `Review changes` at x 502, title at x 490; complete-group-comparison/initial.png: `Use saved` at x 374, text at x 362"
  observed: "The theme's text button keeps Material's inner padding, so a quiet button's label starts 12 px right of the text above it."
  fix: "Give quiet buttons no start padding when they align to content, or align their label, not their box, to the content edge."
