# Realm sheets review: inbox, activity, realm selector

Surfaces that open from the app bar on any page:

- Realm inbox: `panel/lib/features/realms/presentation/realm_inbox.dart`, `realm_inbox_view.dart`, `realm_inbox_status.dart`. Stories `features/realms/presentation/realminboxbutton/live-review/` (11 images) and `.../realminboxcontent/provider-owned-review/` (11 images).
- Save activity: `panel/lib/shared/mutations/presentation/mutation_activity_button.dart`, `mutation_activity_details.dart`, `mutation_activity_card.dart`. Story `shared/mutations/presentation/mutationactivityview/default/` (10 images).
- Realm selector: `panel/lib/features/realms/presentation/realm_selector.dart` on `panel/lib/shared/selectables/presentation/selector_popup.dart`. Story `features/realms/presentation/realmselector/default/` (4 images).

Key paths were checked with a throwaway widget probe on `pumpStory` (deleted after the run);
"probe" below refers to it. Contrast is computed from the theme values (`color_scheme.dart:10-24`:
status colours are Material orange `#FF9800`, redAccent `#FF5252`, green `#4CAF50`, brand
`#009FFF`, tints at 12% on the light canvas `#F9F9FF`).

## Summary

Not good yet. Both irreversible actions in these sheets run on one press: Publish (also Ctrl+Enter
from anywhere in the open inbox) releases to the live realm, and Discard drops unsaved work, with
no hold and no undo. Around that, the sheets open with focus on Close, the realm menu ignores Esc,
the same action has two names in two sheets, and 'Needs attention' is orange in one and red in the
other. No story image shows any sheet open over the page, the realm menu, or the activity details.

Single most valuable change: put Publish and Discard behind the hold component, and give both
sheets one focus path (open on the first thing to act on, Esc back to the opener).

## Findings

- id: SHEETS-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Realm inbox, Publish button and Ctrl+Enter"
  evidence: "probe: Shift+P then Ctrl+Enter gives 'Everything is published' with no dialog or hold; probe: one tap on Publish publishes; realm_inbox_view.dart:119-127, :249-257"
  observed: "One press releases every saved change to the live realm. Ctrl+Enter does it from any focus inside the inbox, including the Close button it opens on."
  fix: "Hold to confirm with `hold`, with the outcome line typed in reserved space: 'Publish 3 changes to Main'."

- id: SHEETS-2
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Discard in the Save activity cards and in the inbox Local work rows"
  evidence: "mutation_activity_details.dart:137-146; realm_inbox_view.dart:593-597; editing_workspace.dart:1384-1398 removes the operations with no undo; probe (first run): after tapping Discard no dialog and no Undo appear"
  observed: "One press throws away unsaved work. Nothing asks, nothing offers Undo."
  fix: "Keep the draft struck through with Undo and `drain`, or hold to confirm until undo exists."

- id: SHEETS-3
  rule: "A page or surface opens"
  severity: 3
  region: "Realm inbox popup and Save activity popup"
  evidence: "probe: after Shift+P and after a click, focus is the Close IconButton (Tooltip 'Close'); the activity popup opens the same way"
  observed: "Both sheets open with focus on Close, not on the first issue, the first change, or Publish."
  fix: "Focus the first issue when there are issues, otherwise the first change row."

- id: SHEETS-4
  rule: "A user's action finishes and they have not moved on"
  severity: 3
  region: "Realm inbox closing"
  evidence: "probe: click the inbox button, Esc: focus returns to the route scope, not the button; the activity popup by contrast returns to its '2 drafts' trigger"
  observed: "Closing the inbox drops focus on the page instead of the inbox button that opened it."
  fix: "Return focus to the opener, as the activity popup already does."

- id: SHEETS-5
  rule: "Any action that opens something"
  severity: 3
  region: "Realm selector menu"
  evidence: "probe: open the selector, Arrow Down to 'Paper Alpha', Esc three times: the menu stays open ('Search realms' still shown) and focus stays on the row"
  observed: "Once focus is on a realm row, Esc never steps out of the menu."
  fix: "Esc closes the menu from any row and returns focus to the realm chip."

- id: SHEETS-6
  rule: "Any action"
  severity: 3
  region: "Command list: Realm inbox and realm switching"
  evidence: "probe: Ctrl+K, type 'inbox': no result besides the query field; realm_inbox.dart:46-55 registers the shortcut but it is not found; realm_selector.dart has no Intent; REALMHOME-1 shows the selector is not reachable by Tab"
  observed: "The inbox can be opened only by Shift+P or pointer, and switching realm has no key path at all."
  fix: "List 'Open realm inbox' and 'Switch realm' in the command list through Intents, and make the realm chip a Tab stop."

- id: SHEETS-7
  rule: "Writing text"
  severity: 3
  region: "Save activity button labels, light theme"
  evidence: "mutation_activity_button.dart:90-93 (text in the status colour on a 12% tint of it); computed: '2 drafts' and 'Needs input' orange 1.88:1, 'Needs attention' red 2.65:1, 'Saved' green 2.38:1, 'Pending' and 'Saving' brand 2.39:1; images Phase=*.png"
  observed: "Every activity label is under 4.5:1 in light theme."
  fix: "Use the matching onContainer colour for the text and keep the status colour on the icon only."

- id: SHEETS-8
  rule: "Showing a state"
  severity: 3
  region: "Inbox button, inbox Issues heading, activity button"
  evidence: "realm_inbox_status.dart:57, :70 (attention is warning orange); mutation_activity_button.dart:154-156 (attention is error red); realm_inbox_view.dart:299 (Issues count always warning); images realminboxbutton/Review=Blocked.png ('1 issue' orange) and realminboxcontent/Review=Blocked.png (red error row under an orange count)"
  observed: "'Needs attention' is orange on the inbox button and red on the activity button. A blocking error shows as an orange '1 issue' and an orange count above a red row."
  fix: "One status map: blocking errors red everywhere, warnings orange everywhere, shared by both buttons and the inbox."

- id: SHEETS-9
  rule: "Showing the health of many things"
  severity: 3
  region: "App bar status buttons in a narrow bar"
  evidence: "story mutationactivityview/Window=Compact.png (red icon alone); appbar_control.dart:45 and :114 drop the label when the button is square; animated_status_content.dart:29 does the same for the inbox"
  observed: "When the app bar is narrow the status keeps only its icon; 'Needs attention' becomes a red circle with no words."
  fix: "Keep a short word ('Fix', '3 issues') or move the status into the sidebar sheet with its words."

- id: SHEETS-10
  rule: "Naming an action"
  severity: 2
  region: "Save and retry actions in the inbox and the activity sheet"
  evidence: "realm_inbox_view.dart:586 'Apply' and mutation_activity_details.dart:111 'Save' both call save; realm_inbox_view.dart:421-423 'Refresh result', 'Retry request' against mutation_activity_details.dart:180, :187 'Refresh saved result', 'Retry captured request'"
  observed: "One command carries different names in two sheets."
  fix: "Pick one name per command (Save, Retry, Refresh) and use it in both."

- id: SHEETS-11
  rule: "Choosing an action's weight"
  severity: 2
  region: "Realm inbox, Publish"
  evidence: "realminboxcontent/initial.png, Review=Warnings.png; realm_inbox_view.dart:119-127 (full width, 44 px, in the body after the lists)"
  observed: "The filled main action spans the body below the list; with a long review it is off screen (Review=Large-review.png)."
  fix: "Put Publish in the inbox header, right side, next to Close."

- id: SHEETS-12
  rule: "A button has a key"
  severity: 2
  region: "Inbox button (Shift+P), Publish (Ctrl+Enter)"
  evidence: "realminboxbutton/live-review/initial.png; realminboxcontent/initial.png; realm_inbox.dart:141-158 (key only in the tooltip); realm_inbox_view.dart:249-257"
  observed: "Neither button shows its key cap; Shift+P appears only in the hint bar and a hover tooltip."
  fix: "Show the cap inside each button."

- id: SHEETS-13
  rule: "Something is empty"
  severity: 2
  region: "Inbox 'Everything is published', 'No saved content to publish'; activity 'No pending changes'"
  evidence: "realminboxcontent/Review=Everything-published.png, Review=Nothing-published-yet.png; realm_inbox_view.dart:108-116 (description \"\"); mutation_activity_details.dart:198-207"
  observed: "One grey line and no mascot or subtitle saying what belongs here."
  fix: "Mascot, a playful line ('Nothing left to ship'), and a subtitle: 'Saved changes to this realm appear here until you publish them.' See SHEETS-S3 for the shared cause."

- id: SHEETS-14
  rule: "Misreading would cost the user something"
  severity: 3
  region: "Inbox issue rows and the blocked line"
  evidence: "realminboxcontent/Review=Warnings.png, Review=Blocked.png; resource_issues.dart:29-34; resource_issue_badge.dart:64-78; realm_inbox_view.dart:136-141"
  observed: "Rows read 'Saved content. Changed locally or awaiting evaluation' and 'Arrival > Resource'. 'Publish blocked' is grey, small, and does not say what to do."
  fix: "Say what to do: 'Fix this before you publish' on blockers, and 'Publish is blocked by 1 problem. Open it to fix.' Name the field, not 'Resource'."

- id: SHEETS-15
  rule: "Showing any state on something"
  severity: 2
  region: "Inbox button outline, inbox message boxes, activity cards"
  evidence: "realm_inbox_status.dart:73 (`side: BorderSide(...)`); realm_inbox_view.dart:209; mutation_activity_card.dart:74; images Review=Publishing.png, Review=Unavailable.png"
  observed: "States are drawn with tinted borders around the button, each message box, and each activity card."
  fix: "Drop the borders; the fill tint already carries the state."

- id: SHEETS-16
  rule: "Styling a static page"
  severity: 2
  region: "Inbox issue location line"
  evidence: "realm_inbox_view.dart:468; resource_issue_badge.dart:78"
  observed: "Locations use the `>` text marker: 'Arrival > Resource'."
  fix: "Show the field name alone in the muted label style, with the resource's colour tile before it."

- id: SHEETS-18
  rule: "A surface is new or changed"
  severity: 2
  region: "All three stories"
  evidence: "realm_selector.stories.dart:11-27; realm_inbox.stories.dart:16-42; publication.dart:89 ('Reply lost'); mutation_activity.stories.dart:105-131"
  observed: "No image shows the realm menu, the inbox open over the page, or the activity details. 'Reply lost' is identical to Ready because nothing presses Publish. No image for Checking, outcome unknown, waiting, Local work rows, submission issues, Publish busy or failed, Idle activity, or a sheet at phone width. Pressing Discard in the story throws a StateError (probe), because the drafts are not known to the controller."
  fix: "Add opened variants (menu, inbox, details), press Publish in 'Reply lost', and back the activity drafts with real work entries."

- id: SHEETS-19
  rule: "One thing shows in several places"
  severity: 2
  region: "Realm chip, realm menu rows, offline card"
  evidence: "realm_selector.dart:35, :147; realm_suspension.dart:216; realmselector/default/initial.png shows 'Paper Alpha' for realm `main`"
  observed: "The realm is named by its owner host everywhere, so a realm and its host carry the same name and two realms on one host could not be told apart."
  fix: "Show the realm's own name; mention the host as secondary text in the menu."

- id: SHEETS-20
  rule: "Rows added or removed (everyday motion)"
  severity: 3
  region: "Activity details list"
  evidence: "mutation_activity_details.dart:75-208 (plain ListView, no animated list)"
  observed: "Cards appear and vanish at once when a save settles, a draft is discarded, or a result is dismissed. Severity 3: rows added or removed are everyday motion."
  fix: "Use `AnimatedSliverList` like the inbox, on `rowIn` and `listOut` once those tokens exist."

- id: SHEETS-21
  rule: "Anything leaves"
  severity: 2
  region: "Activity card details expand and collapse"
  evidence: "mutation_activity_card.dart:84-87 (`Expansible` 240 ms easeOut both ways), :153-156 (`AnimatedRotation` 240 ms easeOut); no reduced motion check"
  observed: "Collapsing takes as long as expanding, on a literal curve, and ignores reduced motion (MOTION-1, MOTION-2 for the literal and reduced motion parts)."
  fix: "Expand with `surfaceIn`, collapse faster with `panelOut`."

## Shared

- id: SHEETS-S1
  rule: "The window is under 900 px, or a pane would be narrower than 320 px"
  severity: 3
  region: "Every popover and sheet, sidebar"
  evidence: "responsive.dart:17-18 (MOBILE ends at 450 px, TABLET to 1000); context.dart:22; probe at the 800 px Compact window: tapping the inbox opens the anchored popup, no bottom sheet; window.dart:6"
  observed: "Between 451 and 899 px floating surfaces stay popovers and the sidebar stays beside the content. RESOURCE-6 is one symptom on the resource surface."
  fix: "Switch to one pane and bottom sheets below 900 px, in the breakpoint definition."

- id: SHEETS-S2
  rule: "Anything changes state"
  severity: 2
  region: "Status labels: inbox button, inbox sections, every SliverAnimatedContent"
  evidence: "elastic_message_switcher.dart:10-45 (AnimatedSwitcher keyed by the whole child, linear switch curves, 1000 ms ElasticOutCurve size); animated_status_content.dart:23-45 (180, 120, 200 ms literals)"
  observed: "'Checking' to 'Publishing' to 'Review changes' replaces the whole label with an elastic pop; shared letters do not stay and nothing types."
  fix: "One status text component that keeps shared letters and types the rest, on tokens."

- id: SHEETS-S3
  rule: "Something is empty"
  severity: 2
  region: "EmptyState component"
  evidence: "empty_state.dart:35-70 (optional icon, title, optional description, optional button; no mascot, no key cap)"
  observed: "The shared empty component cannot show the mascot or a main action with its key, so every empty state fails the rule (MEMBERS-23, SERVICES-20, SHEETS-13)."
  fix: "Build the mascot, playful line, serious subtitle, and right side keyed action into EmptyState."

## Known faults these sheets show

- MOTION-8, MOTION-18: Saving and Publish busy use `CircularProgressIndicator` (`mutation_activity_button.dart:65-68`; `LoadingButton` at `realm_inbox_view.dart:122`).
- MOTION-9, MOTION-23, RESOURCE-12 pattern: a failed Publish raises a snackbar with `error.toString()` (`realm_inbox_view.dart:26-35`); see Cannot verify.
- MOTION-10: Review draft opens an `AlertDialog` (`realm_inbox_view.dart:559-576`, `mutation_activity_details.dart:17-32`).
- MOTION-11, MOTION-12: popovers fade in place; sheets use the framework bottom sheet (`realm_inbox.dart:105`, `mutation_activity_button.dart:34`, `selector_popup.dart:159`).
- MOTION-16, MOTION-17: inbox rows use `StaggerEntrance` and `ElasticTransition` (`animated_slivers.dart:66-82`).
- MOTION-19: `SliverAnimatedGap` is a linear 300 ms `AnimatedContainer` (`animated_slivers.dart:31-36`).
- MOTION-1, MOTION-22: the activity button pops in from scale 0 on an 800 ms elastic (`elastic_switcher.dart:19-40`).
- MOTION-3, MOTION-6: the realm chip and rows hover and press with ink (`selector_popup.dart:146-157`).
- MOTION-25: selecting a realm swaps the row fill at once (`realm_selector.dart:126-131`).
- RESOURCE-10: the selector's error builders print the raw error (`selector_popup.dart:83`, `:86`, `:89`).
- SERVICES-16: hint bar title case.

## Action walk

| Action | Keys only | Focus after | Move expected | Code and move found |
|---|---|---|---|---|
| Open inbox | Shift+P (not in command list) | Close. SHEETS-3 | `surfaceIn` from the button | AnchoredPopup fade. MOTION-11 |
| Close inbox (Esc, Close) | Esc works | Route scope. SHEETS-4 | `panelOut` back to the button | Popup vanishes. MOTION-11 |
| Publish | Ctrl+Enter, one press. SHEETS-1 | Unchanged | `hold`, then busy `ripple` | `LoadingButton` spinner. MOTION-8 |
| Publish fails | Not probed | Not probed | `jam` at Publish | Snackbar. Cannot verify |
| Open an issue or change | Tab, Enter | Navigates; popup closes | Row becomes the page heading | Route change. MOTION-15 |
| Review draft | Tab | Dialog | `surfaceIn` | AlertDialog. MOTION-10 |
| Apply, Retry, Discard (local work) | Tab | Not probed | Row leaves with `listOut` | Rows on ElasticTransition. MOTION-17; Discard SHEETS-2 |
| Inbox status changes | n/a | Unchanged | Letters type in place | Whole label swaps. SHEETS-S2 |
| Open activity | Tab to the button only from the app bar (unreachable on realm routes, REALMHOME-1) | Close. SHEETS-3 | `surfaceIn` | MOTION-11, MOTION-12 |
| Close activity | Esc | Trigger. pass | `panelOut` | MOTION-11 |
| Expand activity card | Tab, Enter | Card | Grow, faster shrink | SHEETS-21 |
| Save, Retry, Dismiss, Discard in activity | Tab | Not probed | `listOut` when a card leaves | No move. SHEETS-20; Discard SHEETS-2 |
| Copy problem report | Tab | Unchanged | Type 'Copied' at the button | Types 'Copied'. pass |
| Open realm menu | Unreachable by keys. SHEETS-6 | Search field. pass (typing is its purpose) | `panelIn` from the chip | MOTION-11 |
| Move in realm menu | Arrow Down works | Row | `focusMove` | MOTION-4 |
| Close realm menu | Esc fails from a row. SHEETS-5 | Row | `panelOut` | n/a |
| Choose a realm | Enter on a row | Not probed | Rows ripple in | Navigation. MOTION-15, MOTION-25 |
| Compact width | 800 px still popovers | n/a | Bottom sheets | SHEETS-S1 |

## Cannot verify

- "Something fails" for Publish: `realm_inbox_view.dart:26-35` shows `error.toString()` in a snackbar and the button returns to Publish. A severity 3 fault by source, but the 'Reply lost' story never presses Publish, so no second check was possible. A probe pressing Publish in 'Reply lost' would settle it.
- "Writing text" in dark theme for the activity labels: the dark canvas comes from `ColorScheme.fromSeed`; only light was computed.
- "Choosing a font": the 'Saved' label in `Phase=Saved.png` looks set in a proportional face while the other labels are Lilex. It may be an image caught mid switch; the source sets no font on it.
- Whether 'Switch realm' appears in the command list under another name: the story's search double fails ('The Realm double has no search'), so the list could not be read.
- How any move feels: no token runs.

## Rule results

<details>
<summary>One row per checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | fail: SHEETS-4 (activity passes) |
| The focused thing disappears | cannot_verify: not probed |
| A page or surface opens | fail: SHEETS-3; realm menu pass |
| Something happens that the user did not just do | fail: SHEETS-S2, MOTION-21 |
| A choice comes from a short fixed list | pass: realm menu is a popover |
| A choice comes from a list that can grow or be searched | fail: realms can grow and are searched in a private popover, not the search overlay (severity 2, noted, not filed: the search overlay may be the wrong home for the current realm switch; maintainer to decide) |
| A task needs more room than its place has | fail: MOTION-12 |
| Other work cannot continue until a question is answered | fail: Review draft is a dialog for reading, MOTION-10 |
| The window is under 900 px, or a pane would be narrower than 320 px | fail: SHEETS-S1 |
| Anything needs saying | pass: messages sit in the inbox |
| Something succeeds | pass: Copy types 'Copied' at the button |
| Something fails | cannot_verify (see above) |
| Several things fail at once | pass: inbox groups issues |
| Something is empty | fail: SHEETS-13, SHEETS-S3 |
| The connection or a service is lost | pass: 'Publication review unavailable' says what to do |
| A wait continues past 5 s | cannot_verify |
| Work has measurable progress | pass: Preparing release, Activating release |
| An action can be undone | fail: SHEETS-2 |
| An action cannot be undone, or undo is not built yet | fail: SHEETS-1, SHEETS-2 |
| Anything changes state | fail: SHEETS-S2 |
| Anything leaves | fail: SHEETS-20, SHEETS-21 |
| A control is busy or unavailable | fail: MOTION-8 |
| A button has a key | fail: SHEETS-12 |
| Reduced motion is on | fail: SHEETS-21 |
| Adding an action | fail: SHEETS-6 |
| Moving around | fail: SHEETS-5 |
| Choosing a key for a new meaning | pass: Shift+P is in the key language |
| An action cannot work here | pass: inbox shortcut leaves when outside a realm (existing test) |
| Choosing an action's weight | fail: SHEETS-11 |
| Showing a state | fail: SHEETS-8, SHEETS-15 |
| Showing the health of many things | fail: SHEETS-9 |
| Adding colour to a page | pass |
| Styling a static page | fail: SHEETS-15, SHEETS-16 |
| Writing text | fail: SHEETS-7 |
| Misreading would cost the user something | fail: SHEETS-14 |
| Naming an action | fail: SHEETS-10 |
| One thing shows in several places | fail: SHEETS-19 |
| A shared component does the job | fail: AlertDialog for Review draft, MOTION-10 |
| A surface is new or changed | fail: SHEETS-18 |

</details>

## Skill friction

- No story renders any of these sheets open, so step 3 ("open each image") showed only buttons. The inventory row should name opened stories, or the skill should say to open sheets in a probe and capture them.
- The "Rows added or removed" severity bump lives in the Severity section, not in a Motion When cell, so SHEETS-20 has no exact When to quote; I named the bump.
- The rule "A choice comes from a list that can grow or be searched" conflicts with the realm menu being a short popover with its own search field; I could not tell which applies and left it unfiled.
- Story doubles shape what can be checked: the search double fails for every query, and the activity drafts crash on Discard. The skill does not say whether a story fault that blocks a check is a finding.
- Step 8 asks for two ways on severity 3; for Publish failure the source is clear but no story reaches it. A third outcome ("source only, needs a story") would avoid dropping a likely fault.
