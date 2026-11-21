# Join requests page review

Surface: Join requests, route `members/join-requests`, story
`features/members/join_requests/presentation/joinrequestspage/default`, plus the component story
`.../joinrequestapproval/default`.
Evidence: the story images under `.xtask/results/stories/features/members/join_requests/`, the
presentation source in `panel/lib/features/members/join_requests/presentation/`, the theme values
from `buildTheme`, and throwaway `pumpStory` probes (deleted after the run; "probe" below). Paths are
below `panel/lib/` unless stated.

## Summary

Not yet good. The page lists people waiting to join and is quick to scan, but its two daily actions
break the rules hardest. Decline cannot be undone, yet Shift+D declines at once and D opens a dialog
with Decline focused. Accept opens a role panel that keeps focus on the card, does not close on Esc,
and leaves its hidden role chips in the Tab order of every collapsed card. Every row carries a
filled Accept and a red outlined Decline, so the page has six or more main actions and red labels
under 4.5:1.

Single most valuable change: make Decline a hold to confirm with no modifier bypass, and make Accept
open the role panel with focus on its first role chip, Esc closing it and returning focus to the
card.

## Findings

- id: JOINREQ-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Decline on a request row: D, Shift+D, the Decline button, Decline All in the bulk bar"
  evidence: "join_request_card.dart:131-140 (DeleteIntent) and :251-268; join_request_list.dart:28-58; shared cause popups.dart:189-199 (MEMBERS-1); probe: focus Dennis's card, Shift+D, Dennis gone with no dialog; D opens the dialog with focus on its Decline button, Enter declines"
  observed: "Shift+D declines immediately. D and the button open a dialog whose destructive button is focused, so D then Enter declines. No hold, no outcome line with a count, and the text is 'Are you sure you want to decline this join request?'."
  fix: "Hold to confirm with `hold`; the line states 'Decline Dennis Torvalds' or 'Decline 3 requests'. Remove the Shift bypass (MEMBERS-1)."

- id: JOINREQ-2
  rule: "The focused thing disappears"
  severity: 3
  region: "Request list after a decline or an accept"
  evidence: "join_request_list.dart:69-80 (removal animation only, no focus handling); probe: decline Dennis by keys, focus lands on the Select all checkbox at the top (rect 254,209); accept by pointer, focus is the page scope"
  observed: "After a request leaves, focus jumps to Select all or to nothing, not to the next request."
  fix: "Move focus to the next card, or the previous one when the last card leaves."

- id: JOINREQ-3
  rule: "A page or surface opens"
  severity: 3
  region: "Whole page on open"
  evidence: "route.dart:14-35 and route_content.dart (no autofocus); probe: primary focus after open is the route's focus scope; first Tab lands on the Select all checkbox"
  observed: "Opening the page focuses nothing; the first Tab goes to Select all, not to the first request."
  fix: "Focus the first request card on open."

- id: JOINREQ-4
  rule: "A user's action finishes and they have not moved on"
  severity: 3
  region: "Accept on a request row: A key, Accept button"
  evidence: "join_request_card.dart:141-153 and :236-243 (toggle only); join_request_approval.dart:61-69; probe: A opens the panel, focus stays on the card; Esc leaves the panel open; Tab from the card goes Decline, Cancel, then the role chips"
  observed: "Accept opens the role panel but focus stays on the card, so the required role choice needs extra Tabs. Esc does not close the panel."
  fix: "Focus the first assignable role chip when the panel opens; Esc closes it and returns focus to the card."

- id: JOINREQ-5
  rule: "Moving around"
  severity: 3
  region: "Tab order through the request list"
  evidence: "join_request_card.dart:53-92 (Expansible keeps the collapsed body, maintainState defaults to true, so it stays offstage but focusable); probe: Tab 6 lands on an 'Admin' chip that is not hit testable while every card is collapsed; Tabs 6 to 12 alternate between hidden chips and visible buttons"
  observed: "Tab walks into role chips of collapsed cards, so focus disappears from the screen between visible buttons."
  fix: "Drop the collapsed body from focus (ExcludeFocus while closed, or maintainState false). Severity raised from 2: keyboard users lose sight of focus on every pass through the list."

- id: JOINREQ-6
  rule: "Something fails"
  severity: 3
  region: "Confirm & Add Member, the Decline dialog"
  evidence: "join_request_card.dart:79-88 (catchApiExceptionsAndDisplay, shared/mutations/presentation/operation_failure_display.dart:10-20 shows a snackbar); probe with 'Service answers: With a failure': Accept shows 'The operation result could not be confirmed' in a snackbar; Decline keeps the dialog open with the same text"
  observed: "A failed accept is reported in a snackbar away from the button. Neither message says what happened to this person or what to do next."
  fix: "Shake and flash the button with `jam`, then put 'Could not reach the membership service. Try again.' under the role panel until the next try. Same text inside the decline hold."

- id: JOINREQ-7
  rule: "A task needs more room than its place has"
  severity: 3
  region: "Role panel under a request card (and the compact card body)"
  evidence: "join_request_card.dart:53-60 (Expansible 500 ms ElasticOutCurve(0.9), reverse 20 ms easeInCubic) and :71 (ElasticMessageTransition); same pattern as MOTION-29 but a separate literal here"
  observed: "The panel opens on a literal elastic and snaps shut in 20 ms; it does not grow with `surfaceIn`, and Esc does not shrink it. Severity 3: opening is an everyday move."
  fix: "Grow the row into the panel with `surfaceIn`, close with `panelOut`, and bind Esc to close."

- id: JOINREQ-8
  rule: "Anything changes state"
  severity: 2
  region: "Accept button label while the panel is open"
  evidence: "join_request_card.dart:240-242; join_request_responsive_content.dart:94"
  observed: "The same button swaps its label from Accept to Cancel at once, so one control means two things and nothing types."
  fix: "Keep Accept as Accept; close the panel with Esc or a quiet Cancel inside the panel."

- id: JOINREQ-9
  rule: "Anything leaves"
  severity: 2
  region: "Bulk bar (Select roles, Accept All, Decline All)"
  evidence: "join_request_actions.dart:88-98 (AnimatedSize 500 ms, ElasticOutCurve(0.9) on mobile and easeOutCubic otherwise, both ways; AnimatedSwitcher 100 ms linear)"
  observed: "The bar arrives and leaves on the same literal curve; on mobile it bounces when it closes, and the content cross fades linearly. Same pattern as MOTION-26 in a separate widget."
  fix: "Arrive with `panelIn` from the selection, leave with `panelOut`."

- id: JOINREQ-10
  rule: "Choosing an action's weight"
  severity: 2
  region: "Every request row; bulk bar; role panel"
  evidence: "join_request_card.dart:225-243; join_request_actions.dart:114-131; join_request_approval.dart:74-78; story joinrequestspage/default/Join-requests=Many.png"
  observed: "Each row has a filled Accept and a red outlined Decline, always visible; the bulk bar and the role panel add more filled buttons in the body. The column of bright buttons is the loudest thing on the page."
  fix: "Show row actions on hover and focus only; keep one filled button per pane, in the pane header."

- id: JOINREQ-11
  rule: "Writing text"
  severity: 3
  region: "Decline labels, light theme"
  evidence: "SHARED-JOINREQ-1; story joinrequestspage/default/initial.png"
  observed: "Decline is red text at 3.19:1 on the white pane."
  fix: "See SHARED-JOINREQ-1."

- id: JOINREQ-12
  rule: "Showing many things that have details"
  severity: 2
  region: "Request list"
  evidence: "join_request_list.dart:172-185 (cards in a sliver list); join_request_card.dart:177-248"
  observed: "Requests are tall cards with actions and the role choice inside each card; there is no table and no inspector for the selected request."
  fix: "A table of requests (name, email, expiry) with an inspector that shows the person large, the role choice, Accept and Decline, and their keys."

- id: JOINREQ-13
  rule: "Placing content"
  severity: 2
  region: "Heading, Select all, cards"
  evidence: "story joinrequestspage/default/Join-requests=Many.png: heading at x 262, Select all checkbox at x 269, card content at x 270; cards repeat every 98 px (y 274, 372, 470)"
  observed: "Title and content sit on different left edges, and rows are about 98 px tall instead of about 42 px."
  fix: "One left edge for heading and list; table rows of about 42 px."

- id: JOINREQ-14
  rule: "Naming an action"
  severity: 2
  region: "Page title, buttons, dialogs, command list"
  evidence: "route.dart:24 ('Join Requests'); join_request_list.dart:41-43 ('Decline ${n} request(s)?', 'Decline All'); join_request_actions.dart:65, :119, :130 ('Accept requests', 'Accept All', 'Decline All'); join_request_approval.dart:54, :77 ('Select roles for this member:', 'Confirm & Add Member'); route.dart:25 ('Approve each request')"
  observed: "One action is called Accept, Approve, Accept All, Accept requests, and Confirm & Add Member. Title Case throughout, a fake plural 'request(s)'."
  fix: "Accept everywhere, with Accepted as its result; sentence case; 'Decline 3 requests'."

- id: JOINREQ-15
  rule: "Choosing a key for a new meaning"
  severity: 2
  region: "Request card keys"
  evidence: "join_request_card.dart:106-113 (ActivateIntent selects), :141-153 (A and Space open Accept); join_request_actions.dart:63-70 (A accepts selected); member_actions.dart:68 (A applies roles), realms/presentation/resource_route.dart:115 (A creates); probe: Enter and Space both select the card, Space does not open the panel"
  observed: "A means Accept here, Apply roles on Members, and Create in the editor, and is not in the key language. Space is declared as an Accept key but selects instead, and Enter selects instead of opening."
  fix: "Space selects (toggle), Enter opens the role panel (activate), and Accept inside the panel is Ctrl or Cmd+Enter. Drop A. MEMBERS-16 covers A on Members."

- id: JOINREQ-16
  rule: "A button has a key"
  severity: 2
  region: "Accept (A), Decline (D), Confirm & Add Member (Ctrl or Cmd+Enter)"
  evidence: "join_request_card.dart:225-243; join_request_approval.dart:74-78; motion part is MOTION-7"
  observed: "No button shows its key cap."
  fix: "Show the key cap on each button."

- id: JOINREQ-17
  rule: "Something is empty"
  severity: 2
  region: "Empty list"
  evidence: "join_request_list.dart:82-89; shared cause SHEETS-S3"
  observed: "'No join requests' and 'When members request to join, they will appear here.' No mascot, no playful line, and the people who ask are not members yet."
  fix: "Mascot, a playful line, and 'People who use a join code that needs approval wait here.' with a link to Join codes."

- id: JOINREQ-18
  rule: "Misreading would cost the user something"
  severity: 2
  region: "Decline dialog title"
  evidence: "join_request_card.dart:257 ('Decline ${request.userName}'s request?'; userName is nullable, the card shows only the email when it is null, :198-210)"
  observed: "A request without a name asks 'Decline null's request?', so the user cannot tell whom they decline. Severity 2: names are usually present."
  fix: "Fall back to the email."

- id: JOINREQ-19
  rule: "Setting any visual value"
  severity: 2
  region: "Cards, header, skeleton"
  evidence: "join_request_card.dart:190, :202, :209 (radius 24, font 16, 14); join_request_responsive_content.dart:39, :45, :52, :60 (radius 20, spacing 2, font 15, 13); join_request_list.dart:112, :126 (padding 12, height 52); join_request_actions.dart:104 (8.0, 4.0), :118, :129 (icon 18); alpha 0.3 and 0.5 throughout"
  observed: "Literal sizes, spacings, and alphas instead of tokens; motion literals are in JOINREQ-7 and JOINREQ-9."
  fix: "Move them into the spacing and type tokens."

- id: JOINREQ-20
  rule: "A surface is new or changed"
  severity: 2
  region: "Story joinrequestspage/default"
  evidence: "md5 of initial, Join-requests=Few, Service-answers=Slowly and Service-answers=With-a-failure images are identical; no None image (support/stories.dart:200 skips the first knob option)"
  observed: "No image shows the empty list, a selection with the bulk bar, the role panel open on the page, hover, focus, a busy accept or decline, or a failure."
  fix: "Add knobs or variants that start in those states."

## Shared

- id: SHARED-JOINREQ-1
  rule: "Writing text"
  severity: 3
  region: "Any text in the danger colour, light theme: Decline, Revoke, Remove labels, error titles"
  evidence: "shared/theme/color_scheme.dart:15 (`_dangerColor = Colors.redAccent`), :64, :111; computed: #FF5252 on white 3.19:1, on the light canvas 3.04:1 (dark theme passes at 5.36:1); stories joinrequestspage/default/initial.png and joincodespage/default/Join-codes=Failing.png"
  observed: "The theme's danger colour is used as text and is under 4.5:1 on every light surface."
  fix: "Add a danger text value for light (about #C62828) and use it wherever red is text; keep #FF5252 for fills and icons."

- id: SHARED-JOINREQ-2
  rule: "Showing any state on something"
  severity: 2
  region: "Role chips in the role panel and in join code settings"
  evidence: "features/members/presentation/role_multiselect_chips.dart:95-99 (selected adds a border in the role colour); story joinrequestapproval/default/Roles=Ready,Role-picked=true.png (Writer)"
  observed: "A selected role chip adds a coloured border on top of its fill."
  fix: "Show selection with the fill only."

- id: SHARED-JOINREQ-3
  rule: "Naming an action"
  severity: 2
  region: "CountdownBadge, on request rows, code rows, and the generated code"
  evidence: "shared/ui/components/countdown_badge.dart:91 (`\"$days days ...\"`), :53, :58 (literal 10 and 16)"
  observed: "One day left reads '1 days 03:12:09'; the badge also writes literal padding and radius."
  fix: "Real plural ('1 day'); tokens for padding and radius."

## Cannot verify

- "Showing a state": an expanded card fills with `cardColor` (join_request_card.dart:41-45), a second meaning for fill next to selection; no image shows the panel open on the page, so the look is unchecked. Selection also turns the avatar into a success coloured check (shared `SelectableAvatar`, MEMBERS-9).
- "A static page feels boring": avatars render as empty grey circles in tests, so the per person tile cannot be judged.
- "Something happens that the user did not just do": a request that expires or arrives from someone else uses the list's ElasticTransition (MOTION-21); layout stability under that cannot be shown in an image.
- "Several things fail at once": bulk decline stops at the first failure (join_request_list.dart:46-51); the probe did not run a bulk failure.
- How the role panel and bulk bar feel, once tokens run: a maintainer.
- "Only touch is available": no touch story.

## Rule results

<details>
<summary>Every checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | fail (JOINREQ-4) |
| The focused thing disappears | fail (JOINREQ-2) |
| A page or surface opens | fail (JOINREQ-3) |
| Something happens that the user did not just do | fail, MOTION-21 |
| A task concerns something on screen | pass (accept and decline act in the row) |
| A choice comes from a short fixed list | pass (role chips in place) |
| A task needs more room than its place has | fail (JOINREQ-7) |
| Other work cannot continue until a question is answered | fail, covered by JOINREQ-1 |
| The window is under 900 px, or a pane would be narrower than 320 px | fail, RESOURCE-6 and SHEETS-S1 (Window=Compact.png keeps the sidebar at 800 px) |
| Anything needs saying | fail, covered by JOINREQ-6 |
| Something succeeds | pass (the request leaves the list) |
| Something fails | fail (JOINREQ-6) |
| Several things fail at once | cannot_verify |
| A change appears elsewhere on screen | cannot_verify (the sidebar count after a decline was not traced) |
| Something is empty | fail (JOINREQ-17) |
| Access is lost | cannot_verify (no story) |
| The connection or a service is lost | fail, MEMBERS-6 (Join-requests=Failing.png shows the crash screen) |
| A wait is too short to notice, under 300 ms | cannot_verify |
| Nothing about the page is known yet | pass (heading shows) |
| The layout is known and its content is not | pass (route_content.dart:32-129 matches the card layout; Join-requests=Loading.png) |
| Content is on screen and refreshing | cannot_verify |
| Loaded content arrives | fail, MOTION-16 (StaggerEntrance per card, join_request_list.dart:204) |
| The user causes one new row | not applicable |
| A wait continues past 5 s | cannot_verify |
| An action can be undone | not applicable |
| An action cannot be undone, or undo is not built yet | fail (JOINREQ-1) |
| Anything would skip those rules | fail, covered by JOINREQ-1 (Shift bypass) |
| The user causes something to arrive | fail (JOINREQ-9) |
| Something exists before and after a change | not applicable |
| Showing any state on something | fail (SHARED-JOINREQ-2); busy spinner is MOTION-8 |
| Anything changes state | fail (JOINREQ-8); selection swap is MOTION-25 |
| Anything grows or responds over time | fail, MOTION-6 (ink press) |
| Text appears | pass (no text appears without reserved space) |
| A key is in use | fail, MOTION-7 |
| A control is busy or unavailable | fail, MOTION-8 |
| Anything leaves | fail (JOINREQ-9); rows leaving are MOTION-17 |
| Something is temporary | not applicable |
| The pointer reaches something you can act on | fail, MOTION-3 |
| A button has a key | fail (JOINREQ-16) |
| Focus moves | fail, MOTION-4 |
| A pane gains focus | fail, MOTION-5 |
| Several moves would play together | cannot_verify |
| Any move runs | cannot_verify |
| Reduced motion is on | fail, MOTION-2 |
| Adding an action | pass (Intents and ActionShortcuts registered through ManagedActionSet) |
| Something works with one input | pass (selection by click, Enter, Space; accept and decline by keys) |
| Keys change meaning | pass (mode chip shows Normal) |
| An action means something the key language already covers | fail, covered by JOINREQ-15 (Enter selects) |
| Choosing a key for a new meaning | fail (JOINREQ-15) |
| Choosing any key | pass |
| Placing an action | pass |
| Both a focused row and a selection exist | pass (join_request_card.dart:137-140) |
| Moving around | fail (JOINREQ-5) |
| Only touch is available | cannot_verify |
| Setting any visual value | fail (JOINREQ-19) |
| Showing a state | cannot_verify (see above) |
| Choosing an action's weight | fail (JOINREQ-10) |
| Placing content | fail (JOINREQ-13) |
| Showing many things that have details | fail (JOINREQ-12) |
| A static page feels boring | cannot_verify |
| Showing the health of many things | not applicable |
| Adding colour to a page | fail, covered by JOINREQ-10 (bright blue and red columns) |
| Styling a static page | fail, covered by JOINREQ-10 (red outlined buttons) |
| Writing text | fail (JOINREQ-11, SHARED-JOINREQ-1) |
| Choosing a font | fail, MEMBERS-14 and SHARED-SIGNIN-1 (subtitle in Lilex at weight 50) |
| Misreading would cost the user something | fail (JOINREQ-18) |
| Nothing depends on it | fail, covered by JOINREQ-17 |
| Naming an action | fail (JOINREQ-14, SHARED-JOINREQ-3) |
| One thing shows in several places | pass |
| A shared component does the job | fail, covered by JOINREQ-1 (confirmation dialog instead of a hold) |
| A surface is new or changed | fail (JOINREQ-20) |
| Keyboard behaviour is new or changed | not applicable (review of existing code) |

Action walk: Esc out of the decline dialog returns focus to the card (pass, probe). Compact width keeps every action reachable (pass, Window=Compact.png).

</details>

## Skill friction

- The brief says shared faults are already reported, but several page faults share a cause with a Members finding in page local code (Expansible literals, bulk bar AnimatedSize, Shift bypass through popups.dart). I reported each where the page has its own code and cited the Members id where the cause is shared.
- The skill names `cross-page.md` for shared faults while the brief asks for a `## Shared` section; I followed the brief.
- The output format has no place for which action walk rows passed; I added one line under Rule results.
- Story images never show the role panel open or a selection, so most of this page's states needed a probe; the evidence table only points to probes for focus and keys.

## Suggestions

- Eye lands first on the bright Accept column, not on who is asking. Lead each row with the person and the code they used, and keep actions quiet until focus.
- Expiry shows minutes and seconds ticking (41:59). Seconds add motion without information; show '42 min left' and turn it red only when it is close.
- First time user: nothing says where requests come from. Name the join code each request used.
- Rule gap: When a collapsible body is closed, Then nothing inside it can take focus. Sev 3.
