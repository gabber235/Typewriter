# Organizations review

Surface: Organizations, route `/`, story `features/organizations/presentation/indexpage/default`.
Evidence: the eight images under `.xtask/results/stories/features/organizations/presentation/indexpage/default/`,
the presentation source in `panel/lib/features/organizations/presentation/` (`route.dart`,
`organizations.dart`, `join_organization.dart`, `create_organization.dart`), the shared components it
uses, the theme values, and a throwaway `pumpStory` probe (deleted after the run). "Probe" below refers
to it. Paths without a folder are in `panel/lib/features/organizations/presentation/`.

## Summary

Not yet good. Picking an organization works with arrows and Enter, but the page is three stacked
forms with three headings, two filled buttons, and dividers, and none of its actions are commands:
nothing is focused on open, the first Tab goes to the footer, no action has a key except cancelling
a request, and validation leaves focus where it was. Failures arrive as transient snackbars with raw
text (`Failed to submit join request: The operation result could not be confirmed`), and cancelling
a join request asks through an AlertDialog with the destructive button focused.

Single most valuable change: focus the first organization on open and make Open, Join, Create, and
Cancel request commands through Intents, with messages and focus at the field or button that ran them.

## Findings

- id: ORGS-1
  rule: "A page or surface opens"
  severity: 3
  region: "Whole page"
  evidence: "route.dart:14-75 and organizations.dart:35-42 (no autofocus); probe: on open the primary focus is the route's FocusScope; Tab order is Support, Docs, Ada, search field, Acme"
  observed: "Nothing is focused on open, and the first three Tabs go to the footer links in the corner before reaching the organizations."
  fix: "Focus the first organization row on open (typing is not the page's purpose), and put the footer after the content in Tab order."

- id: ORGS-2
  rule: "A user's action finishes and they have not moved on"
  severity: 3
  region: "Name field under Create organization; Invite URL or code field"
  evidence: "create_organization.dart:111-113 and join_organization.dart:154-156 (`validate()` with no focus request); probe: after Create with an empty name, focus stays on the route scope with `Please enter an organization name.` shown; after Join with an empty field, the same"
  observed: "After validation fails, focus does not move to the first bad field."
  fix: "Focus the first invalid field when validation fails."

- id: ORGS-3
  rule: "Adding an action"
  severity: 3
  region: "Organization rows, Join, Create, the icon picker"
  evidence: "organizations.dart:75-101 (InkWell onTap), join_organization.dart:76-79, create_organization.dart:53-66, :148-153; only the pending request row has an Intent (join_organization.dart:225-235); probe: Ctrl+K and `?` change nothing on this page"
  observed: "Open organization, Join, Create, and Randomize icon are plain callbacks. They have no Intent, no key, and no command list; the page has no command list or key help at all."
  fix: "Make each one a command through an Intent: Enter opens the focused row, Ctrl or Cmd+Enter runs Join or Create from its field, and all appear in the command list."

- id: ORGS-4
  rule: "Something fails"
  severity: 3
  region: "Join and Create buttons"
  evidence: "join_organization.dart:167-172 and create_organization.dart:125-130 (`showErrorSnackBar` with the raw error); probe: a failed join shows the snackbar `Failed to submit join request: The operation result could not be confirmed`, which has gone 12 s later, while only the activity button keeps `Needs attention`"
  observed: "A failed join or create is reported in a snackbar away from the button, with exception text and no next step, and it disappears before the next try."
  fix: "Shake the button, then keep a plain line under the field, such as `The server did not answer. Press Join to try again.`, until the next press."

- id: ORGS-5
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 3
  region: "Cancel request (red cross and D on a pending request row)"
  evidence: "join_organization.dart:180-192 (`showConfirmationDialogue`); probe: D on a pending row opens the dialog with `Cancel Request` focused, so D then Enter cancels; Esc returns focus to the row"
  observed: "Cancelling a join request asks `Are you sure you want to cancel your request to join Loog Zzt?` in an AlertDialog with the destructive button focused. No hold, no outcome line. Severity lowered from 4 to 3: the user can send a new request with the same code, so only the place in the queue is lost. The focused destructive button is the shared fault in SERVICES-1 and SERVICES-18."
  fix: "Use the hold component on the row: `Cancel the request to join Loog Zzt?` typed in reserved space during the hold."

- id: ORGS-6
  rule: "Writing text"
  severity: 3
  region: "Request limit message under the invite field"
  evidence: "join_organization.dart:86-97 (`colorScheme.error` on bodySmall); probe: error on the light canvas is 3.04:1; story Join-requests=Request-limit-reached.png"
  observed: "The limit message is red 12 px text at 3.04:1 on light, below 4.5:1. Cause is the theme: SHARED-SCREENS-1."
  fix: "See SHARED-SCREENS-1. The message is not a failure either; content colour with a small status mark would do."

- id: ORGS-7
  rule: "Something exists before and after a change"
  severity: 3
  region: "Organization rows"
  evidence: "organizations.dart:94-101 (`context.pushRoute`); theme has no page transition (MOTION-15)"
  observed: "Opening an organization replaces the page on the framework transition. The row is not carried into the organization's heading. Severity 3: opening is an everyday action on this page."
  fix: "Carry the row's logo and name into the organization page heading; the rest ripples in, and Back reverses."

- id: ORGS-8
  rule: "A choice comes from a list that can grow or be searched"
  severity: 2
  region: "`Search Organization` field above the list"
  evidence: "organizations.dart:35-42 and :17-20 (local filter); story Organizations=Many.png"
  observed: "The page has its own inline filter field instead of the search overlay, and the overlay (Ctrl+K) does not open here."
  fix: "Drop the inline field; open the search overlay with Ctrl or Cmd+K, scoped to organizations."

- id: ORGS-9
  rule: "Something succeeds"
  severity: 2
  region: "Join and Cancel request"
  evidence: "join_organization.dart:166 (`Join request submitted successfully.`), :197 (`Join request canceled.`)"
  observed: "Both show a success snackbar although the result is visible: the pending row appears or leaves."
  fix: "Say nothing; the row arriving or leaving is the result."

- id: ORGS-10
  rule: "Choosing an action's weight"
  severity: 2
  region: "Join and Create buttons; red cross on every pending request"
  evidence: "join_organization.dart:76-79, create_organization.dart:53-66, join_organization.dart:255-262; story Join-requests=Few.png"
  observed: "Two filled buttons sit in one pane body, not in a pane header. Every pending row shows a red cross at all times, the loudest mark on the page."
  fix: "One filled main action at most; show the row's Cancel request only on hover and focus, in the content colour."

- id: ORGS-11
  rule: "Placing content"
  severity: 2
  region: "Organization and pending request rows"
  evidence: "story Organizations=Many.png (rows at y 189, 270, 353, 431, 509: about 78 px); Join-requests=Few.png (about 90 px); headings at x 416, row names at x 480"
  observed: "Rows are about 78 to 90 px tall instead of about 42 px, and row names start 64 px right of the headings above them."
  fix: "Use the shared table row height and align names to the heading edge, with the logo as a small tile before it."

- id: ORGS-12
  rule: "Text appears"
  severity: 2
  region: "Request limit message"
  evidence: "join_organization.dart:85-98 (SliverAnimatedContent with ElasticMessageSwitcher, no reserved space); story Join-requests=Request-limit-reached.png versus Join-requests=Few.png (pending list moves down 40 px)"
  observed: "When the limit is reached the message grows in on a 1000 ms elastic and pushes the pending list down."
  fix: "Reserve the line under the field and type the message into it."

- id: ORGS-13
  rule: "Something is empty"
  severity: 2
  region: "List with no match for the filter; page with no organizations"
  evidence: "organizations.dart:45-53 (EmptyState `No organizations found.` / `Try adjusting your search query.`, no mascot); route.dart:109-116 (no organizations shows only Join and Create)"
  observed: "No mascot or playful line in either case. A new user with no organizations gets no line saying what an organization is. The subtitle contrast fault is MEMBERS-23."
  fix: "With no organizations, show the mascot, a playful line, and `An organization holds your servers and its members.`, with Create on the right with its key."

- id: ORGS-14
  rule: "The layout is known and its content is not"
  severity: 2
  region: "Whole page while organizations or join requests load"
  evidence: "route.dart:23-40 (`organizations(name:...)` falls back to riverpod.dart:31, a centred spinner with `Loading Organizations...`)"
  observed: "A centred spinner replaces the page while loading, although the layout (heading, rows, forms) is known. The spinner itself is SERVICES-10 and MOTION-18."
  fix: "Show a skeleton of the heading and three rows."

- id: ORGS-15
  rule: "Naming an action"
  severity: 2
  region: "Cancel request; search hint"
  evidence: "join_organization.dart:229 (`Revoke request`), :258 (tooltip `Cancel request`), :185 (`Cancel Request`), :197 (`canceled`); organizations.dart:37 (`Search Organization`)"
  observed: "One action has three names (Revoke request, Cancel request, Cancel Request) with mixed case. The search hint is Title Case."
  fix: "Call it Cancel request everywhere, with `Request cancelled` as its result; write `Search organizations`."

- id: ORGS-16
  rule: "A shared component does the job"
  severity: 2
  region: "Headings `Select organization`, `Join organization`, `Create organization`"
  evidence: "organizations.dart:26-29, join_organization.dart:38-41, create_organization.dart:28-31 (local Text with headlineMedium)"
  observed: "Three local headings instead of `PageHeading` and `SectionTitle`; the page has no single page heading."
  fix: "One `PageHeading` (`Organizations`), with Join and Create as `SectionTitle`s."

- id: ORGS-17
  rule: "Anything changes state"
  severity: 2
  region: "Icon picker under Create organization"
  evidence: "create_organization.dart:148-153 and organization_icon.dart:27 (`Image.network` swaps the image)"
  observed: "Randomizing the icon, or typing a name, swaps the logo at once; nothing moves to perform the change."
  fix: "Animate the swap inside the tile, for example a flip on `press`."

- id: ORGS-18
  rule: "A surface is new or changed"
  severity: 2
  region: "Story `indexpage/default`"
  evidence: "route.stories.dart (knobs Organizations None, Few, Many, Loading); images listed above"
  observed: "No image shows: no organizations (None is skipped because Few is the initial option), loading (the Loading image shows the crash screen after the 10 s timeout), the Create organization form (never in frame), hover, focus, Join or Create busy or failed, validation messages, or the cancel confirmation."
  fix: "Add story states for these and capture the full scroll height."

## Shared faults seen here

Not repeated; see their reports.

- SERVICES-9, MEMBERS-6: when loading fails the page becomes the crash screen with a raw `TimeoutException ... cloud.to.user.ada.organization.watch` (story Organizations=Loading.png).
- SERVICES-1, SERVICES-18: `showConfirmationDialogue` focuses the destructive button.
- MEMBERS-23: EmptyState subtitle under 4.5:1 on light.
- RESOURCE-20: sentences such as `Enter an invite URL or code to request to join an organization.` render in Lilex, not IBM Plex Sans.
- SHARED-SIGNIN-1: headings and labels in JetBrains Mono.
- SHARED-SIGNIN-2: focused Join and Create draw a 3 px black border, not the ring.
- CONFLICT-13, RESOURCE-7: the unavailable Join (limit reached) is faded, not pressed in, and its label is under 4.5:1 (probe: 2.30:1 light, 2.96:1 dark).
- MOTION-16: sections enter on `StaggerEntrance`, not `loadIn`.
- MOTION-17: organization and pending rows arrive and leave on `ElasticTransition`; a new request does not slide in with `rowIn`.
- MOTION-19: `SliverAnimatedGap` animates linearly (animated_slivers.dart:31-35).
- MOTION-3, MOTION-6, MOTION-8, MOTION-9, MOTION-10, MOTION-23: hover, press, busy, failure, dialog, and snackbar motion.
- MOTION-15: page change on the framework transition.
- MOTION-21: an expired request leaves without a word on who or why.

## Cannot verify

- "The focused thing disappears": where focus goes after a pending request is cancelled or expires. The probe did not complete a cancel; a probe pressing D, then confirming, then naming the focused row would settle it.
- "A static page feels boring": organization logos do not load in story images (network images), so the colour tiles cannot be judged.
- "Text appears" for validation messages: whether the field's error line shifts the form. An image of a failed validation would settle it.
- "Choosing how strong a move is": how the row and message springs feel. A maintainer.

## Rule results

<details>

| Rule (When) | Result |
|---|---|
| A user's action finishes and they have not moved on | fail (ORGS-2) |
| The focused thing disappears | cannot_verify |
| A page or surface opens | fail (ORGS-1) |
| Something happens that the user did not just do | fail (MOTION-21) |
| A task concerns something on screen | pass (cancel acts in the row) |
| A choice comes from a list that can grow or be searched | fail (ORGS-8) |
| Other work cannot continue until a question is answered | fail, covered by ORGS-5 |
| The window is under 900 px, or a pane would be narrower than 320 px | pass (Compact keeps every action; Support and Docs move into the account menu) |
| Anything needs saying | fail, covered by ORGS-4 |
| Something succeeds | fail (ORGS-9) |
| Something fails | fail (ORGS-4) |
| Something is empty | fail (ORGS-13) |
| The connection or a service is lost | fail (SERVICES-9) |
| The layout is known and its content is not | fail (ORGS-14) |
| Loaded content arrives | fail (MOTION-16) |
| The user causes one new row | fail (MOTION-17) |
| An action cannot be undone, or undo is not built yet | fail (ORGS-5) |
| The user causes something to arrive | fail (MOTION-17) |
| Something exists before and after a change | fail (ORGS-7) |
| Moving between pages with nothing to carry over | fail (MOTION-15) |
| Anything changes state | fail (ORGS-17) |
| Text appears | fail (ORGS-12) |
| A control is busy or unavailable | fail (MOTION-8, CONFLICT-13) |
| Anything leaves | fail (MOTION-17) |
| The pointer reaches something you can act on | fail (MOTION-3) |
| A button has a key | fail, covered by ORGS-3 |
| Focus moves | fail (MOTION-4) |
| Reduced motion is on | pass for the slivers on this page (animated_slivers.dart:33, :54; elastic_message_switcher.dart:25) |
| Adding an action | fail (ORGS-3) |
| Something works with one input | pass |
| An action means something the key language already covers | pass (D cancels a request) |
| Placing an action | pass (cancel on the row) |
| Moving around | pass for rows (probe: Down and J move between organizations); fail for Tab order, covered by ORGS-1 |
| Setting any visual value | fail (route.dart:61-64 literal 8 px offsets, organizations.dart:87 literal 14 px icon, route.dart:95 literal 600 px width) |
| Showing a state | pass |
| Choosing an action's weight | fail (ORGS-10) |
| Placing content | fail (ORGS-11) |
| A static page feels boring | cannot_verify |
| Adding colour to a page | fail, covered by ORGS-10 (red crosses) |
| Styling a static page | fail, see Suggestions (OR rules between sections) |
| Writing text | fail (ORGS-6) |
| Choosing a font | fail (SHARED-SIGNIN-1, RESOURCE-20) |
| Misreading would cost the user something | fail, covered by ORGS-4 |
| Naming an action | fail (ORGS-15) |
| A shared component does the job | fail (ORGS-16) |
| A surface is new or changed | fail (ORGS-18) |

</details>

## Skill friction

- The story renderer skips the first option of every knob, so `Organizations=None`, the first run state of this page, has no image. The skill forbids re-rendering and offers no other way to see it.
- The `Loading` option renders the crash screen, because the renderer runs past the 10 s timeout. A loading knob that times out inside the capture window cannot show loading.
- The probe needed its own focus describer to name what holds focus. A testkit helper that returns the focused row's label would make focus findings faster and comparable across reports.
- "Setting any visual value" findings for small literals do not have a natural home in Findings; I listed them in the rule results.

## Suggestions

- What is this page for: it reads as three forms. Lead with the organization list as a table; put Join and Create as two quiet row actions at its end (`Join with a code`, `Create organization`) that grow into their forms with `surfaceIn`.
- What can be removed: the two `OR` dividers (rules between sections doing no work) and the icon picker sentence `For now, generated and can be randomized again by clicking the icon.`, which names a pointer only path and an internal limitation.
- Where the eye lands: on the red crosses when requests are pending. See ORGS-10.
- Error layout: when loading fails, the raw message runs under the Support link in the bottom left corner (story Organizations=Loading.png). Rule gap, new row for Look: When page content and a floating corner element share the window, Then the content reserves the corner's space. Sev 2.
- First time user: the limit message is red for a normal state. Show it in the content colour with a small count (`5 of 5 requests pending`).
