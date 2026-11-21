# Join codes page review

Surface: Join codes, route `members/join-codes`, story
`features/members/join_codes/presentation/joincodespage/default`, plus the component story
`.../joincodesettings/default`.
Evidence: the story images under `.xtask/results/stories/features/members/join_codes/`, the
presentation source in `panel/lib/features/members/join_codes/presentation/`, the shared
`SecretField` (`panel/lib/shared/ui/components/secret_field*.dart`), the theme values from
`buildTheme`, and throwaway `pumpStory` probes (deleted after the run; "probe" below). Paths are
below `panel/lib/` unless stated.

## Summary

Not yet good. The page makes and lists codes, but Revoke cannot be undone and still skips its
question with Shift+D, a failed revoke hides that row's revoke control for good, and Generate has no
key and leaves focus nowhere. The code field loops a fake typing animation forever, which suggests a
hidden code exists. The table shows the type of each code but never the roles a code grants, though
the subtitle promises that.

Single most valuable change: make Revoke a hold to confirm with no modifier bypass, restore the
control on failure, and move focus to the next row afterwards.

## Findings

- id: JOINCODES-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Revoke: D or Shift+D on a row, the revoke icon, compact card Revoke, Revoke All"
  evidence: "join_code_table_row_shortcuts.dart:74-83 and :89-101; join_code_row_actions.dart:33-52; join_code_card.dart:93-102, :237-252; route_content.dart:49-79; shared cause popups.dart:189-199 (MEMBERS-1); probe: focus a row, Shift+D, rows 6 to 5 with no dialog; D opens the dialog with focus on Revoke, Enter revokes"
  observed: "Shift+D revokes immediately. D and the icon open a dialog with Revoke focused, so D then Enter revokes. No hold, no outcome line with a count."
  fix: "Hold to confirm with `hold`; the line states 'Revoke this code' or 'Revoke 3 codes'. Remove the Shift bypass (MEMBERS-1)."

- id: JOINCODES-2
  rule: "Something fails"
  severity: 3
  region: "Revoke icon in a table row"
  evidence: "join_code_row_actions.dart:5-8 (doc: flag never reset), :17-21, :45; probe with 'Service answers: With a failure': revoke icons 6 before, 5 after while every row stays; the dialog stays open with 'The operation result could not be confirmed'"
  observed: "A failed revoke removes that row's revoke icon until the widget is rebuilt, so the same control cannot repeat the action. The message neither says what happened nor what to do."
  fix: "Keep the control; shake and flash it with `jam`, then show 'Could not reach the membership service. Try again.' at the row until the next try."

- id: JOINCODES-3
  rule: "The focused thing disappears"
  severity: 3
  region: "Code table after a revoke"
  evidence: "join_code_table.dart:27-38 (removal builder only, no focus handling); probe: revoke the focused row by D, Enter; focus lands on the header Select all checkbox (rect 262,514)"
  observed: "After a revoke, focus jumps to the header checkbox instead of the next row."
  fix: "Move focus to the next row, or the previous one at the end."

- id: JOINCODES-4
  rule: "A page or surface opens"
  severity: 3
  region: "Whole page on open"
  evidence: "route.dart:11-33 and route_content.dart (no autofocus); probe: primary focus after open is the route scope; first Tab lands on Generate Join Code"
  observed: "Opening the page focuses nothing."
  fix: "Focus the first code row, or Generate when the list is empty."

- id: JOINCODES-5
  rule: "Adding an action"
  severity: 3
  region: "Generate Join Code"
  evidence: "route_content.dart:91-110 (SecretField with a plain onGenerate, no ManagedActionSet, no Intent); probe: N on a focused row leaves 6 rows and no 'New Join Code' button"
  observed: "Generate has no Intent, no key, and no command list entry; N, the create key, does nothing on this page."
  fix: "One Generate command through an Intent, bound to N, used by the button and the command list."

- id: JOINCODES-6
  rule: "A user's action finishes and they have not moved on"
  severity: 3
  region: "After Generate"
  evidence: "route_content.dart:96-105; secret_field_controller.dart:55-64; probe: after tapping Generate, a seventh row appears and focus is the route scope"
  observed: "The new code appears as a row, but focus goes nowhere; neither the new row nor Copy is focused."
  fix: "Focus the new code (its row, or Copy beside the revealed code)."

- id: JOINCODES-7
  rule: "Moving around"
  severity: 3
  region: "Tab order through the code table"
  evidence: "join_code_table_row_shortcuts.dart:85 (a focusable `Focus` wraps each wrapped cell); join_code_table.dart:210, :221, :285; probe: Tabs 4 and 5 both land on the row checkbox (rect 262,589), Tab 6 on an empty code cell wrapper, Tab 7 copy, Tab 8 an empty actions wrapper, Tab 9 revoke"
  observed: "Each row is six Tab stops, two of them invisible wrappers and one a second stop on the checkbox. Severity raised from 2: focus disappears from view twice per row."
  fix: "One Tab stop per row; arrows or H, J, K, L move inside it. Same shape as MEMBERS-18."

- id: JOINCODES-8
  rule: "Showing a state"
  severity: 3
  region: "Focused table row; compact card avatar"
  evidence: "join_code_table.dart:192-199 (focus is a secondaryContainer fill at 12%, selection a primaryContainer fill); join_code_card.dart:113-126 (selected avatar in the success colour); probe: the focused wrappers draw no ring"
  observed: "Focus is shown as a fill instead of a ring, so focus and selection share one signal, and selection uses the success status colour on compact cards."
  fix: "Focus ring only for focus, fill only for selection, no status colour for selection."

- id: JOINCODES-9
  rule: "Writing text"
  severity: 3
  region: "Auto-accept badge, light theme; revoke labels"
  evidence: "join_code_badges.dart:33-38 (colorScheme.primary #009FFF on primaryContainer #DBEEFF); computed 2.39:1 light, 4.53:1 dark; story joincodespage/default/Join-codes=Many.png; red labels are SHARED-JOINREQ-1"
  observed: "Auto-accept is brand fill blue text at 2.39:1 in light theme."
  fix: "Use brand text #006FB8 on light (SHARED-CONFLICT-1 has the same cause for buttons)."

- id: JOINCODES-10
  rule: "Loaded content arrives"
  severity: 3
  region: "Code table rows on load"
  evidence: "join_code_table.dart:65, :129, :204, :220, :255, :266, :284 (a StaggerEntrance per TableCell); timing is MOTION-16; image joincodespage/default/initial.png catches rows mid entrance"
  observed: "Each cell enters on its own, so a row arrives cell by cell, on StaggerEntrance timing, not as one row with `loadIn`. Same shape as MOTION-24 in this page's own table."
  fix: "One entrance per row on `loadIn`."

- id: JOINCODES-11
  rule: "A task needs more room than its place has"
  severity: 3
  region: "Advanced options; compact code card"
  evidence: "join_code_settings.dart:48-58 (chevron icon swaps), :99-103 (AnimatedSize 200 ms easeInOut; content inserted at once); join_code_card.dart:52-57 (500 ms ElasticOutCurve(0.9) open, 20 ms close), :163-172 (chevron points up while collapsed)"
  observed: "Advanced options grows on a literal ease while its content appears at once; the compact card opens on a literal elastic and snaps shut in 20 ms. Neither uses `surfaceIn`, and Esc closes neither. Severity 3: opening is an everyday move."
  fix: "Grow both with `surfaceIn`, close with `panelOut`, bind Esc to close, and point the chevron down when closed."

- id: JOINCODES-12
  rule: "The user causes something to arrive"
  severity: 2
  region: "Customized chip beside Advanced options"
  evidence: "join_code_settings.dart:84-93 (scale 750 ms ElasticOutCurve(0.4) in, 400 ms fastOutSlowIn out, fade 400 ms linear)"
  observed: "The chip pops in on a literal elastic and fades linearly in both directions."
  fix: "Type 'Customized' into its reserved space with `type`."

- id: JOINCODES-13
  rule: "Anything leaves"
  severity: 2
  region: "Bulk bar (selected chip, Revoke All)"
  evidence: "route_content.dart:141-147 (AnimatedSize 800 ms ElasticOutCurve(0.9) both ways; AnimatedSwitcher 400 ms linear)"
  observed: "The bar bounces when it closes, as slow as it opens, and cross fades linearly. Same pattern as MOTION-26 in this page's own code."
  fix: "Arrive with `panelIn`, leave with `panelOut`."

- id: JOINCODES-14
  rule: "Choosing an action's weight"
  severity: 2
  region: "Generate card; every table row; bulk bar"
  evidence: "secret_field_view.dart:186-200 (filled Generate in the body); join_code_row_actions.dart:25-29 (red icon, always visible); join_code_table.dart:242-247 (copy icon, always visible); join_code_actions.dart:49-59 (red outlined Revoke All); story Join-codes=Many.png"
  observed: "The main action sits in the pane body, not the header, and every row shows a red revoke icon and a copy icon at all times."
  fix: "Generate as the one filled button in the pane header; row actions on hover and focus."

- id: JOINCODES-15
  rule: "Showing many things that have details"
  severity: 2
  region: "Code table"
  evidence: "join_code_table.dart:59-92 (columns Join Code, Type, Expires); join_code_badges.dart:33-38 (only an 'Auto-accept' badge); route.dart:22 ('review their assigned roles')"
  observed: "There is no inspector, and the roles a code grants are shown nowhere, though the subtitle says the page lets you review them."
  fix: "An inspector for the selected code: full link, Copy, roles granted, use limit, expiry, Revoke, with keys."

- id: JOINCODES-16
  rule: "Placing content"
  severity: 2
  region: "Heading, generate card, list title, table"
  evidence: "story Join-codes=Many.png: heading at x 262, card content at x 270, 'Active Join Codes' at x 254, table checkbox at x 269; rows repeat every 81 px (y 612, 693, 774)"
  observed: "Title and content sit on four left edges, and rows are about 81 px tall instead of about 42 px."
  fix: "One left edge; rows of about 42 px with the two type badges side by side."

- id: JOINCODES-17
  rule: "Naming an action"
  severity: 2
  region: "Titles, buttons, dialogs, field text"
  evidence: "route.dart:21 ('Join Codes'); route_content.dart:62-64 ('Revoke ${n} join code(s)?', 'Revoke All'), :106-109 ('Generate Join Code', 'New Join Code', 'Copy Join Code'), :136 ('Active Join Codes'); join_code_table.dart:245 ('Copy Join Code'), :87 ('Join Code'); join_code_duration_input.dart:75 ('Set experation to'), :99 ('Valid Duration:')"
  observed: "Generate is also New Join Code; Revoke is also Revoke All and Revoke join code; Title Case throughout; a fake plural; a misspelt 'experation'."
  fix: "Generate code, Copy, Revoke everywhere, sentence case, real plurals ('Revoke 3 codes')."

- id: JOINCODES-18
  rule: "Something succeeds"
  severity: 2
  region: "Copy on a row, C key, Copy in the generate card, copy after Generate"
  evidence: "join_code_table.dart:292-295 and join_code_card.dart:232-235 (showSuccessSnackBar); secret_field_controller.dart:52; probe: C on a row calls Clipboard.setData"
  observed: "Copying shows a green snackbar instead of typing the result at the control."
  fix: "Type 'Copied' into the copy control and let it return."

- id: JOINCODES-19
  rule: "Choosing a key for a new meaning"
  severity: 2
  region: "Expiration field presets"
  evidence: "join_code_duration_input.dart:70-88 (digits 1 to 4 and numpad 1 to 4 set presets)"
  observed: "Digits 1 to 4 pick a duration preset, a meaning not in the key language."
  fix: "Add the meaning to the key language or move presets to arrows inside the field."

- id: JOINCODES-20
  rule: "Showing any state on something"
  severity: 2
  region: "Duration preset chips"
  evidence: "preset_chip.dart:25-33 (selected adds a 1.5 px primary border on top of the fill)"
  observed: "A selected preset adds a border."
  fix: "Show selection with the fill only."

- id: JOINCODES-21
  rule: "Something is empty"
  severity: 2
  region: "Empty table and compact list"
  evidence: "join_code_table.dart:94-98, join_code_list.dart:32-40; shared cause SHEETS-S3"
  observed: "'No active join codes' and 'Generate a join code above to get started!' No mascot, and the main action is pointed at instead of placed on the right with its key."
  fix: "Mascot, a playful line, a serious subtitle, and Generate with N on the right."

- id: JOINCODES-22
  rule: "A button has a key"
  severity: 2
  region: "Copy (C), revoke (D)"
  evidence: "join_code_table.dart:242-247; join_code_row_actions.dart:25-29; motion part is MOTION-7"
  observed: "No button shows its key cap."
  fix: "Show the key cap on each button."

- id: JOINCODES-23
  rule: "Setting any visual value"
  severity: 2
  region: "Badges, chips, table, settings"
  evidence: "type_badge.dart:32, :38 (14, 11); preset_chip.dart:22-24, :29 (radius 16, padding 10 and 5); join_code_settings.dart:69-71 (6, 2), :124, :156 (Divider 24), :146-147 (two 12 gaps stacked); join_code_badges.dart:17 (6); join_code_card.dart:145, :147-148 (6); join_code_table.dart:51-57 (48, 80), :139 (13); route_content.dart:131 (12)"
  observed: "Literal sizes and spacings instead of tokens; motion literals are in JOINCODES-11 to 13."
  fix: "Move them into the spacing, radius, and type tokens."

- id: JOINCODES-24
  rule: "A surface is new or changed"
  severity: 2
  region: "Stories joincodespage/default and joincodesettings/default"
  evidence: "no None image (support/stories.dart:200 skips the first knob option); Slowly and With-a-failure images differ from initial only in the random concealed text; every joincodesettings image shows the collapsed header (three hashes for eight images)"
  observed: "No image shows the empty table, a revealed code, Advanced options open, a selection with the bulk bar, hover, focus, a busy or failed revoke, or a failed Generate."
  fix: "Add knobs or variants that start in those states; open Advanced options in the settings story."

## Shared

- id: SHARED-JOINCODES-1
  rule: "You cannot name what a move tells the user"
  severity: 2
  region: "SecretField before a value exists (Join code field, any page using SecretField)"
  evidence: "shared/ui/components/secret_field_displays.dart:93-109 (types a random string every 50 ms, waits, picks a new one, forever); story joincodespage/default/*.png show a different blurred string each time"
  observed: "The concealed field loops a fake typing animation with no end. It tells the user nothing, and it looks like a hidden code already exists."
  fix: "Show a still placeholder ('No code yet') until a code is generated."

- id: SHARED-JOINCODES-2
  rule: "Something fails"
  severity: 3
  region: "SecretField Generate button"
  evidence: "secret_field_controller.dart:65-71 (catches only Exception; message in a snackbar as 'Failed to generate: ...'); secret_field_view.dart:186-195 (button stays red while the state is error); probe with 'Service answers: With a failure': 'Failed to generate: The operation result could not be confirmed' shown, state is error"
  observed: "A failed Generate leaves the button red until the next try and reports a raw message in a snackbar, not at the control, with no next step. A thrown Error escapes with no message at all."
  fix: "Shake and flash with `jam`, return to the normal button, and put a plain message with the next step under the field."

- id: SHARED-JOINCODES-3
  rule: "Text appears"
  severity: 2
  region: "SecretField revealed value"
  evidence: "secret_field_displays.dart:150-200 (types the value 30 ms per letter while a blur decays)"
  observed: "The full link, about 45 letters, types itself letter by letter on a literal 30 ms step. Text longer than about 20 letters should arrive whole."
  fix: "Let the link arrive whole on a bounce; keep `type` (36 ms) for short text only."

## Cannot verify

- "Something works with one input": the code is blurred until hovered (shared BlurReveal, MEMBERS-7); keyboard and touch cannot reveal it here either, but C copies it, so the blur only hides it from sight.
- "Several things fail at once": bulk revoke stops at the first failure (route_content.dart:66-74); not probed.
- "Something happens that the user did not just do": a single use code that is used, or a code that expires, leaves the table through ElasticTransition (MOTION-21); the route resets the generate card when its code leaves (route_content.dart:24-38). Layout stability under that needs a live check.
- Esc after opening the revoke dialog from a focused row returns focus to that row (probe, pass); opened by pointer, focus falls to the route scope, which the walk does not define.
- How the expansions feel once tokens run: a maintainer.
- "Only touch is available": no touch story.

## Rule results

<details>
<summary>Every checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | fail (JOINCODES-6) |
| The focused thing disappears | fail (JOINCODES-3) |
| A page or surface opens | fail (JOINCODES-4) |
| Something happens that the user did not just do | fail, MOTION-21 |
| A task concerns something on screen | pass (copy and revoke act in the row) |
| A choice comes from a short fixed list | pass (presets and role chips in place) |
| A choice comes from a list that can grow or be searched | not applicable |
| A task needs more room than its place has | fail (JOINCODES-11) |
| Other work cannot continue until a question is answered | fail, covered by JOINCODES-1 |
| The window is under 900 px, or a pane would be narrower than 320 px | fail, RESOURCE-6 and SHEETS-S1 (Window=Compact.png keeps the sidebar at 800 px) |
| Anything needs saying | fail, covered by JOINCODES-2 and SHARED-JOINCODES-2 |
| Something succeeds | fail (JOINCODES-18) |
| Something fails | fail (JOINCODES-2, SHARED-JOINCODES-2) |
| Several things fail at once | cannot_verify |
| A change appears elsewhere on screen | cannot_verify |
| Something is empty | fail (JOINCODES-21) |
| The connection or a service is lost | fail, MEMBERS-6 (Join-codes=Failing.png shows the crash screen under a live Generate) |
| Nothing about the page is known yet | pass (heading and generate card show) |
| The layout is known and its content is not | pass (route_content.dart:206-248 matches the table; Join-codes=Loading.png) |
| Loaded content arrives | fail (JOINCODES-10) |
| The user causes one new row | fail, MOTION-17 (new row grows through ElasticTransition, join_code_table.dart:99-100) |
| A wait continues past 5 s | cannot_verify |
| An action cannot be undone, or undo is not built yet | fail (JOINCODES-1) |
| Anything would skip those rules | fail, covered by JOINCODES-1 (Shift bypass) |
| The user causes something to arrive | fail (JOINCODES-12) |
| Showing any state on something | fail (JOINCODES-20, SHARED-JOINREQ-2); busy spinner is MOTION-8 |
| Anything changes state | fail, MOTION-25 (row fill and avatar swap at once, join_code_table.dart:192-199) |
| Anything grows or responds over time | fail, MOTION-6 |
| Text appears | fail (SHARED-JOINCODES-3) |
| A key is in use | fail, MOTION-7 |
| A control is busy or unavailable | fail, MOTION-8 |
| Anything leaves | fail (JOINCODES-13); rows leaving are MOTION-17 |
| You cannot name what a move tells the user | fail (SHARED-JOINCODES-1) |
| The pointer reaches something you can act on | fail, MOTION-3 |
| A button has a key | fail (JOINCODES-22) |
| Focus moves | fail, MOTION-4 |
| A pane gains focus | fail, MOTION-5 |
| Any move runs | cannot_verify |
| Reduced motion is on | fail, MOTION-2 |
| Adding an action | fail (JOINCODES-5) |
| Something works with one input | cannot_verify (see above) |
| An action means something the key language already covers | pass (D revoke, C copy, Space select) |
| Choosing a key for a new meaning | fail (JOINCODES-19) |
| Placing an action | pass |
| Both a focused row and a selection exist | pass (join_code_table_row_shortcuts.dart:80-82) |
| Moving around | fail (JOINCODES-7) |
| Setting any visual value | fail (JOINCODES-23, SHARED-JOINREQ-3) |
| Showing a state | fail (JOINCODES-8) |
| Choosing an action's weight | fail (JOINCODES-14) |
| Placing content | fail (JOINCODES-16) |
| Showing many things that have details | fail (JOINCODES-15) |
| A static page feels boring | pass (type badges and expiry give real colour) |
| Adding colour to a page | pass |
| Styling a static page | fail, covered by JOINCODES-14 (red outlined Revoke All) |
| Writing text | fail (JOINCODES-9, SHARED-JOINREQ-1) |
| Choosing a font | fail, MEMBERS-14 and SHARED-SIGNIN-1 |
| Misreading would cost the user something | fail, covered by SHARED-JOINCODES-1 (a fake hidden code) |
| Naming an action | fail (JOINCODES-17, SHARED-JOINREQ-3) |
| A shared component does the job | fail, covered by JOINCODES-1 (confirmation dialog instead of a hold) |
| A surface is new or changed | fail (JOINCODES-24) |

Action walk: compact width keeps every action reachable through the card body (pass, Window=Compact.png).

</details>

## Skill friction

- The settings story renders eight images of a collapsed header; the skill's "a state the story offers but no image shows" fits, but the skill gives no way to open it without re-rendering, which the brief forbids.
- `pumpStory` probes find snackbars poorly (their text is not under a `SnackBar` finder in this harness); I fell back to searching all text. A testkit helper for "the message the user sees" would help every failure check.
- The Tab walk needed node rectangles to tell invisible wrappers from real controls; the skill's focus check could name that technique.

## Suggestions

- Eye lands first on the grey generate card, which fills a third of the pane for a once in a while action. Move Generate to the pane header and open its options as a surface from that button.
- What can be removed: 'Active Join Codes' repeats the page title; drop it. 'Multi-use' is plain text while 'Single-use' is a chip, and Multi-use and Never share the infinity icon; give each fact one look.
- Generate copies the link to the clipboard without asking, replacing whatever was there. Copy only on request, or say 'Copied' at the field.
- Expiry ticks seconds ('5 days 14:59:59'); show '5 days' and add detail only when it is close.
- Rule gap: When a value is generated once and shown once (a secret), Then show a still placeholder until it exists, and say at the field how long it stays visible. Sev 2.
