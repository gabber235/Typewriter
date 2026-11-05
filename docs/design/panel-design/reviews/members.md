# Members page review

Surface: Members, route `members/`, story `features/members/presentation/memberlistpage/default`.
Evidence: the nine story images under `.xtask/results/stories/features/members/presentation/memberlistpage/default/`,
the presentation source in `panel/lib/features/members/presentation/`, the token values from
`buildTheme` and `buildTypewriterColors`, and two throwaway `pumpPanel` probe tests (deleted after the run).

## Summary

Not yet good. The page shows members and lets an owner change roles, but removing a member breaks the
weight rules at every level: Shift+D removes a member at once with no question and no undo, the
normal path is an `AlertDialog` with Remove focused, a failed removal hides the row's remove button
for good, and focus is lost after a removal. Role chips mostly fail contrast, and emails can only be
revealed with a pointer.

Single most valuable change: make Remove member a hold to confirm action (one command through one
Intent for the icon, the keys, the bulk bar, and the compact card), with no modifier bypass, and focus
moving to the next row afterwards.

## Findings

- id: MEMBERS-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Any member row, Shift+D (also Shift with any Delete key reaching DeleteIntent)"
  evidence: "panel/lib/shared/shortcuts/shortcuts.dart:85 (Shift+D is DeleteIntent); panel/lib/shared/ui/components/popups.dart:198 (Shift held skips the dialog and runs onConfirm); member_table_row_shortcuts.dart:71-75; probe test: focus Grace's row, press Shift+D, Grace is gone with no dialog and no Undo"
  observed: "Shift+D removes the focused member immediately: no question, no hold, no undo."
  fix: "Remove the Shift bypass from the confirmation path. Removal goes through the hold component only."

- id: MEMBERS-2
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Remove member: row icon, D/Delete/Backspace on a row, bulk Remove, compact card Remove Member"
  evidence: "member_row_actions.dart:44; member_table_row_shortcuts.dart:83; member_card.dart:248; member_list.dart:46; popups.dart:129 (AlertDialog), popups.dart:151 (confirm button autofocused when there is no delay); probe test: Delete on a row opens the dialog with focus on Remove, Enter removes"
  observed: "Removal asks through an AlertDialog with the destructive Remove button focused, so Enter right after D removes. No hold, no outcome line with a count, wording is 'Are you sure you want to remove this member from the organization?'."
  fix: "Use the hold component: the row fills on a spring, the key cap glows, and one typed line states 'Remove Ada? They lose access straight away.' (with the count for a selection). With the hold setting off, the dialog focuses Cancel and confirms with Ctrl or Cmd+Enter."

- id: MEMBERS-3
  rule: "The focused thing disappears"
  severity: 3
  region: "Member table after a row is removed"
  evidence: "probe test: focus Grace's row, Delete, Enter; Grace is removed and focus lands on an unlabelled Focus node that is not Linus's row"
  observed: "After removing a member, focus does not move to the next row."
  fix: "Move focus to the next row (previous when it was the last, otherwise the table)."

- id: MEMBERS-4
  rule: "A page or surface opens"
  severity: 3
  region: "Members page on open"
  evidence: "probe test: after pumpPanel at membersPage() and settling, primary focus is the route's FocusScope; the first member row is reached only at the fourth Tab"
  observed: "Opening the page focuses nothing to act on."
  fix: "Focus the first member row when the page opens."

- id: MEMBERS-5
  rule: "Something fails"
  severity: 3
  region: "Remove member icon in the row; confirmation dialog"
  evidence: "member_row_actions.dart:19-23 and :52 (isRemoving is set and never reset; the doc comment at :9 says so); probe test with commandFailure: remove buttons go from 3 to 2, Grace stays, the dialog stays open, and the only message is 'The operation result could not be confirmed' (submission_exception.dart:14)"
  observed: "A failed removal makes the row's remove button vanish until the widget is rebuilt. The message neither says what happened nor what to do next, and the same control cannot repeat the action."
  fix: "Keep the control; on failure it shakes with `jam`, returns to Remove, and a still message at the row says 'The membership service did not answer. Press Remove to try again.'"

- id: MEMBERS-6
  rule: "The connection or a service is lost"
  severity: 3
  region: "Whole content area under Current Members, Failing story"
  evidence: "story memberlistpage/default/Members=Failing.png; member_list.dart:131-137; error_screen.dart:25 and :78"
  observed: "When the membership service is unreachable, the list is replaced by 'Typewriter hit an error. Something went wrong, please report this to the Typewriter discord.' It does not name the membership service, offers no retry, and asks the user to report a normal outage."
  fix: "Show one steady notice naming the membership service and the next step ('Members did not load. The panel retries on its own.'), keeping any members already loaded readable."

- id: MEMBERS-7
  rule: "Something works with one input"
  severity: 3
  region: "Email under each member name, desktop table row"
  evidence: "blur_reveal.dart:3-6 (doc: pointer only, no keyboard or touch path), :50-52; member_table.dart:257; story memberlistpage/default/Members=Many.png"
  observed: "Emails unblur only on pointer hover. Row focus and touch never reveal them. The compact card shows the same emails unblurred (Window=Compact.png), so the blur protects nothing consistently."
  fix: "Reveal on row focus and on touch as well, or drop the blur if the email is not secret."

- id: MEMBERS-8
  rule: "Writing text"
  severity: 3
  region: "Role chips in the Roles column (and the bulk role field)"
  evidence: "role_multiselect_dropdown.dart:43-45; multiselect_dropdown.dart:105 (SmallChip draws text in the role colour over 15% of it on the field fill); contrast computed from buildTheme tokens; story memberlistpage/default/Members=Many.png"
  observed: "Light theme: Moderator 1.76:1, Writer 2.21, Guest 2.16, Editor 2.44, Admin 2.76 (only Founder passes at 5.00). Dark theme: Founder 2.37, Admin 4.22. All below 4.5:1."
  fix: "Keep the role colour as a tile or dot and draw the chip label in content colour, or derive a text tone from the role colour that reaches 4.5:1 on both themes."

- id: MEMBERS-9
  rule: "Showing a state"
  severity: 3
  region: "Member table rows and avatars"
  evidence: "member_table.dart:193-200 (focus is a secondaryContainer fill at 0.12; selection is a primaryContainer fill, stronger when also focused); selectable_avatar.dart:28-32 (selected avatar turns success green with a check)"
  observed: "Focus is shown as a fill instead of a ring, so focus and selection share one signal. Selection also uses the success status colour on the avatar."
  fix: "Show focus with the focus ring only, selection with the fill only, and drop the success colour from selection."

- id: MEMBERS-10
  rule: "Anything needs saying"
  severity: 3
  region: "Roles field in each row"
  evidence: "member_table.dart:286-294 and member_card.dart:200-209 (catchApiExceptionsAndDisplay); operation_failure_display.dart:14 (showErrorSnackBar)"
  observed: "A failed role change is reported in a snackbar, not at the roles field that changed."
  fix: "Say it under or at the roles field of that row, and keep the attempted roles."

- id: MEMBERS-11
  rule: "Choosing an action's weight"
  severity: 2
  region: "Remove icon column on every row; bulk bar Remove; compact card Remove Member"
  evidence: "member_row_actions.dart:27-35 (always visible, error colour); member_actions.dart:113-123 and member_card.dart:218-233 (OutlinedButton with red border); story memberlistpage/default/Members=Many.png right column"
  observed: "A red remove icon shows on every row at all times, and the bulk and compact Remove buttons carry a red outline. The column of red icons is the loudest thing on the page."
  fix: "Show row actions only on hover and focus, and in the context menu, as quiet controls without a red border."

- id: MEMBERS-12
  rule: "Placing content"
  severity: 2
  region: "Page heading, Current Members title, table"
  evidence: "story memberlistpage/default/Members=Many.png: heading 'Members' starts at x 262, 'Current Members' at x 254, the header checkbox at x 269; rows repeat every 74 px (y 354, 428, 502); member_list_route.dart:22-28 (PageHeading inset 32 vs SliverPadding space6)"
  observed: "Title and content sit on three left edges, and rows are about 74 px tall instead of about 42 px."
  fix: "Put heading, section title, and table on one left edge, and bring rows to about 42 px (one line name, roles inline)."

- id: MEMBERS-13
  rule: "Showing many things that have details"
  severity: 2
  region: "Member table"
  evidence: "member_table.dart:47-123 (table only); members carry email, roles, and joinedAt; no inspector on the page"
  observed: "There is a table but no inspector. Details (join date, full email, all roles) and actions live inside each row instead."
  fix: "Add an inspector: the selected member appears large with email, join date, roles, actions, and keys; the row stays a short scan line."

- id: MEMBERS-14
  rule: "Choosing a font"
  severity: 2
  region: "Page subtitle under 'Members'"
  evidence: "page_heading.dart:55-62 (bodySmall, which is Lilex, at weight 50); typography.dart:28; story memberlistpage/default/initial.png"
  observed: "The full sentence subtitle is set in Lilex at hairline weight, not IBM Plex Sans."
  fix: "Set full sentences in IBM Plex Sans at a normal weight."

- id: MEMBERS-15
  rule: "Naming an action"
  severity: 2
  region: "Remove labels and section title"
  evidence: "member_row_actions.dart:34 'Remove member'; member_card.dart:232 'Remove Member'; member_actions.dart:122 'Remove'; member_list.dart:48 'Remove ${n} member(s)?'; member_list.dart:85 'Current Members'"
  observed: "One action has four labels with mixed case, a fake plural 'member(s)', and Title Case section title."
  fix: "'Remove member' everywhere, 'Remove 3 members' with a real plural, 'Current members'."

- id: MEMBERS-16
  rule: "Choosing a key for a new meaning"
  severity: 2
  region: "Bulk bar, Apply roles"
  evidence: "member_actions.dart:64-71 (SingleActivator keyA)"
  observed: "A is a new meaning (apply roles) that is not in the key language."
  fix: "Use Ctrl or Cmd+Enter (main action of this surface), or add A to the key language in the same change."

- id: MEMBERS-17
  rule: "A button has a key"
  severity: 2
  region: "Bulk bar Apply and Remove; row remove icon"
  evidence: "member_actions.dart:108-123; member_row_actions.dart:27-35"
  observed: "Buttons with keys (A, D) show no key cap."
  fix: "Show the key cap on each button, and press both together."

- id: MEMBERS-18
  rule: "Moving around"
  severity: 2
  region: "Member table rows"
  evidence: "member_table.dart:175-189 (every cell wraps its own Focus via withShortcuts); probe test: Tab 4 and 5 both land on Grace's row, 6 and 7 on her roles field, 8 on the remove cell"
  observed: "Each row is four or more Tab stops, so Tab walks cells instead of moving between groups."
  fix: "One focus stop per row; arrows and J/K move between rows; Enter or Tab enters the row's controls."

- id: MEMBERS-19
  rule: "The layout is known and its content is not"
  severity: 2
  region: "Loading skeleton of the table"
  evidence: "story memberlistpage/default/Members=Loading.png vs Members=Many.png (roles column starts at x 526 in the skeleton and x 802 when loaded); member_list.dart:168-173 and :202-203 (IntrinsicColumnWidth sized by fixed shimmer widths)"
  observed: "The skeleton's columns do not match the loaded table, so the Roles column jumps right when members arrive."
  fix: "Give the member column a fixed width shared by skeleton and table."

- id: MEMBERS-20
  rule: "Loaded content arrives"
  severity: 2
  region: "Member rows on load"
  evidence: "stagger_entrance.dart:3-7 (300 ms easeOutCubic, 60 ms between rows, launch up to 700 ms, 5% slide); member_table.dart:205, 232, 277, 303 (each cell staggers separately)"
  observed: "Rows enter with a private stagger, not `loadIn` (190 ms per row, rises 14 px, last visible row starts within 150 ms)."
  fix: "Drive the entrance from the `loadIn` token, once per pane."

- id: MEMBERS-21
  rule: "Setting any visual value"
  severity: 2
  region: "Section header, bulk bar, header cells, card"
  evidence: "member_list.dart:80 (padding 12), :90-93 (800 ms ElasticOutCurve(0.9)); member_table.dart:137-138 (fontSize 13); member_card.dart:50-53 (500 ms, 20 ms), :135 (fontSize 15); elastic_transition.dart:21-29 (private curves for row arrival and leave)"
  observed: "Literal sizes, durations, and curves instead of tokens."
  fix: "Use spacing and motion tokens (`surfaceIn`, `listOut`, `rowIn`) and theme text sizes."

- id: MEMBERS-22
  rule: "Several things fail at once"
  severity: 2
  region: "Bulk remove"
  evidence: "member_list.dart:53-65 (one showErrorSnackBar per failed member)"
  observed: "Each failed member in a bulk removal raises its own snackbar."
  fix: "The first failure takes the move and focus; the rest show still messages at their rows."

- id: MEMBERS-23
  rule: "Something is empty"
  severity: 2
  region: "Empty member list"
  evidence: "member_table.dart:92-96 and member_tablet_list.dart:33-38 (EmptyState: icon, 'No members yet', 'Invite someone to get started!'); empty_state.dart:62-66 (description at 70% of onSurfaceVariant, computed 4.06:1 on light)"
  observed: "No mascot, the line points at inviting with no way to invite here, and the subtitle is below 4.5:1 on light. Severity kept at 2 for the contrast part too: the viewer is always a member, so this state is rare."
  fix: "Mascot, a playful line, a serious subtitle, and a link or key to Join codes; subtitle at full secondary colour."

- id: MEMBERS-24
  rule: "A surface is new or changed"
  severity: 2
  region: "Story memberlistpage/default"
  evidence: "membership_story.dart:30-39; every_story_test.dart and support/stories.dart:200 (each knob's first option is skipped); the images folder has no 'Members=None' image"
  observed: "No image shows: empty (the None option is skipped because Few is the initial option), a selection with the bulk bar, hover, focus, a busy removal, a failed command (the 'With a failure' and 'Slowly' images are identical to initial), or offline."
  fix: "Add story states that reach these, including a selection and a failed command after it is triggered."

## Cannot verify

- "Any move runs" and "Reduced motion is on": whether row entrance, the bulk bar, and card expansion retarget and reduce in tokens. Settled by a test with `disableAnimations` and mid-animation input.
- "A user's action finishes and they have not moved on": where focus lands after a role change and after Esc out of the confirmation dialog (the probe showed an unlabelled Focus node). Settled by a widget test naming the expected node.
- "Focus moves" and "A pane gains focus": no evidence of `focusMove` or `paneFocus` on this page; images never prove motion. A maintainer judging live.
- "The pointer reaches something you can act on": hover rise of rows and buttons. A hover story or a maintainer.
- "Choosing how strong a move is": how the bulk bar spring and card expansion feel. A maintainer.
- "The window is too narrow for side by side": the Compact story keeps the navigation and content side by side at about 720 px; whether that width counts as too narrow is not defined.
- Avatars: every avatar renders as an empty grey circle in the images (network images do not load in tests), so the "stable colour tile for each person" look cannot be judged.
- "Only touch is available": no touch story.

## Suggestions

- Page purpose and first glance: the eye lands on the column of red remove icons and the long subtitle. Shorten the subtitle to one line ("Everyone who can open this organization, and their roles.") and hide row actions until hover or focus.
- What can be removed: the "Current Members" title repeats the page heading; drop it.
- What slows an expert: every role change is a full dropdown field per row. Show roles as compact chips in the row and edit them in the inspector or a popover at the focused row.
- First time user: the Founder (the viewer) has a remove icon on their own row. Proposal: hide Remove on the viewer's own row and on the last founder.
- Compact card: the chevron is `expand_less` (pointing up) while the card is collapsed (member_card.dart:151-159). Point down when collapsed.
- New rule proposal: When a value is hidden for privacy (blurred email, secret), Then it reveals on focus, hover, and touch alike, and stays hidden in every layout, or it is not hidden at all. Sev 3.
- New rule proposal: When the confirmation path has a modifier shortcut (Shift skips the question), Then remove it for actions that cannot be undone. Sev 4.

## Rule checks

| Rule (When) | Result |
|---|---|
| A user's action finishes and they have not moved on | cannot_verify |
| The focused thing disappears | fail (MEMBERS-3) |
| A page or surface opens | fail (MEMBERS-4) |
| Something happens that the user did not just do | cannot_verify |
| A task concerns something on screen | pass (roles and remove act in the row) |
| A choice comes from a short fixed list | pass (roles dropdown at the control) |
| A task needs more room than its place has | pass (compact card expands in place) |
| Other work cannot continue until a question is answered | fail, covered by MEMBERS-2 |
| The window is too narrow for side by side | cannot_verify |
| Anything needs saying | fail (MEMBERS-10) |
| Something succeeds | pass (role and removal results are visible) |
| Something fails | fail (MEMBERS-5) |
| Several things fail at once | fail (MEMBERS-22) |
| Something is empty | fail (MEMBERS-23) |
| The connection or a service is lost | fail (MEMBERS-6) |
| Nothing about the page is known yet | pass (heading shows, list area loads) |
| The layout is known and its content is not | fail (MEMBERS-19) |
| Loaded content arrives | fail (MEMBERS-20) |
| An action can be undone | not applicable |
| An action cannot be undone, or undo is not built yet | fail (MEMBERS-1, MEMBERS-2) |
| Anything would skip those rules | fail, covered by MEMBERS-1 |
| Motion rules (arrive, leave, springs, focus, hover) | cannot_verify, except tokens in MEMBERS-20 and MEMBERS-21 |
| A control is busy or unavailable | fail, covered by MEMBERS-5 (control disappears) |
| Adding an action | pass (Intents with command list entries via ManagedActionSet) |
| Something works with one input | fail (MEMBERS-7) |
| An action means something the key language already covers | pass (D, Delete, Space, Esc reused) |
| Choosing a key for a new meaning | fail (MEMBERS-16) |
| Placing an action | pass (row first, selection when it contains the row) |
| Both a focused row and a selection exist | pass (member_table_row_shortcuts.dart:73-75) |
| Moving around | fail (MEMBERS-18) |
| A button has a key | fail (MEMBERS-17) |
| Setting any visual value | fail (MEMBERS-21) |
| Showing a state | fail (MEMBERS-9) |
| Choosing an action's weight | fail (MEMBERS-11) |
| Placing content | fail (MEMBERS-12) |
| Showing many things that have details | fail (MEMBERS-13) |
| A static page feels boring | cannot_verify (avatars do not render in images) |
| Styling a static page | fail, covered by MEMBERS-11 (red outlined buttons) |
| Writing text | fail (MEMBERS-8, MEMBERS-23) |
| Choosing a font | fail (MEMBERS-14) |
| Misreading would cost the user something | fail, covered by MEMBERS-2 and MEMBERS-6 |
| Naming an action | fail (MEMBERS-15) |
| A shared component does the job | fail, covered by MEMBERS-2 (AlertDialog instead of the hold component) |
| A surface is new or changed | fail (MEMBERS-24) |

## Skill friction

- The output format has no place for the per rule `pass`, `fail`, `cannot_verify` record that step 5 asks for. I added a `Rule checks` section; say where it belongs.
- `rule` must quote a `panel-design` When cell, but the action walk rows have their own When column ("An action that cannot be undone") and their own severities. It is unclear which to quote when a finding comes from the walk; I quoted the `panel-design` cell.
- The action walk's remove row covers only "books, pages, or entries". Members are none of these, so it is unclear whether member removal should have Undo (sev 4 row) or a hold (the "cannot be undone" rule). I used the hold rule because no undo exists for removal.
- Step 4 says a state with no story is a finding, but the only matching rule ("A surface is new or changed") is scoped to new or changed surfaces, which a review of an existing page is not. I reported it under that rule anyway.
- The story renderer skips the first option of each knob (support/stories.dart:200), assuming it is the initial. For this story the initial is "Few", so "None" (empty) is never rendered. The skill tells reviewers not to re-render and gives no way to reach a skipped state; I treated empty as source only.
- "Service answers = Slowly / With a failure" images are identical to initial because nothing triggers a command. The skill says to use images for states, but these knobs only matter after an action, so they need a widget test, which the evidence table does not mention for failure states.
- Most images are captured mid entrance (rows fading). The skill covers not reporting them as contrast, but row height, column positions, and the full Few list can only be read from the Many image.
- "Compute contrast from the token values" needs the colours `ColorScheme.fromSeed` produces at runtime; no token file lists them. I wrote a throwaway test; the skill could name a command that prints the resolved palette.
- "Focus target ... Run or write a widget test" gives no helper to name what holds focus. Probes report unlabelled `Focus` nodes, which makes "focus is on the next row" hard to prove. A testkit helper returning the focused row would settle these.
- Several findings sit in shared components (popups.dart, blur_reveal.dart, page_heading.dart, error_screen.dart, the theme's focus ring token which is the neutral outline, not `#009FFF`). The skill does not say whether to report shared component faults per page or once in the cross page report.
- The severity table's sev 4 example ("Shift+D deletes with no question and no undo") is exactly what this page does, which suggests it was written from this page; if so, the example should say whether it is a known issue or a calibration target.
