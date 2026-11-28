# Start up, connection lost, and crash screens review

Surfaces: `LoadingScreen` (start up and connection lost) and `ErrorScreen` with `ErrorScreen.small`
(crash), shown on any route. Stories `shared/ui/screens/loadingscreen/default` and
`shared/ui/screens/errorscreen/default`; images under `.xtask/results/stories/shared/ui/screens/`.
Source: `panel/lib/shared/ui/screens/loading_screen.dart`, `error_screen.dart`,
`panel/lib/shared/ui/components/text_scroller.dart`, and the callers that decide when they show:
`panel/lib/app/presentation/shell/nats_connection.dart` (connection lost and failed),
`panel/lib/app/application/eager_initialization.dart` (start up), and
`panel/lib/shared/ui/components/riverpod.dart` (every provider error). Focus was checked with a
throwaway `pumpStory` probe (deleted after the run); "probe" below refers to it.

## Summary

Not yet good. When the connection drops, the whole panel is replaced by the start up screen, so the
user loses sight of their work for every reconnect, however short. The crash screen always adds
`Something went wrong, please report this to the Typewriter discord.`, even under `Access denied`
where the real next step is to sign in again, and its red title is under 4.5:1 on light. While
waiting, a shuffled list of joke status lines rotates forever instead of getting more specific.

Single most valuable change: on a lost connection keep the page readable and show one steady notice
at page level (`Connecting to the realm`) after 300 ms, growing more specific past 5 s, and keep the
full screen only for start up.

## Findings

- id: SCREENS-1
  rule: "The connection or a service is lost"
  severity: 3
  region: "Whole window while the connection is reconnecting or failed"
  evidence: "nats_connection.dart:29 (`NatsReconnecting() => const LoadingScreen()`), :34-46 (content `Offstage` and focus excluded while blocked), :59-96 (failures replace content with ErrorScreen); story loadingscreen/default/initial.png fills the window"
  observed: "A lost connection hides every page behind the full start up screen. Content is not readable, focus is dropped, and the user cannot tell their work is still there."
  fix: "Keep the page mounted and visible; show one steady notice at page level with the reconnect state, and disable only the controls that need the connection."

- id: SCREENS-2
  rule: "Misreading would cost the user something"
  severity: 3
  region: "Line under every ErrorScreen title"
  evidence: "error_screen.dart:77-91 (fixed line shown whatever the title); nats_connection.dart:60-65 (`Access denied` with `Sign out, then sign in again.`); story errorscreen/default/Size=Full,Retry-action=true,Window=Desktop.png"
  observed: "Every full crash screen says `Something went wrong, please report this to the Typewriter discord.` even when the cause is known and the next step is different, such as `Access denied` (sign in again) or `Server unavailable` (check your connection). Two instructions contradict each other, and the user is told to report normal outages."
  fix: "Show the caller's message only. Keep the Discord line for real crashes, worded as in the Values table: `That jammed. Reload the panel, and tell us on Discord if it happens again.`"

- id: SCREENS-3
  rule: "A page or surface opens"
  severity: 3
  region: "Retry and Sign out on the crash screen"
  evidence: "error_screen.dart:112-116 and nats_connection.dart:99-108 (no autofocus); probe: on open the primary focus is the route's FocusScope; the first Tab reaches Retry"
  observed: "When the crash screen opens, its only action is not focused."
  fix: "Focus the recovery action when the screen opens."

- id: SCREENS-4
  rule: "Adding an action"
  severity: 3
  region: "Retry, Sign out"
  evidence: "nats_connection.dart:99-108 (`LoadingButton` with a callback), eager_initialization.dart:103 (`ElevatedButton`), sign_out_button.dart; probe on the story: Tab is the only way to reach Retry"
  observed: "Retry and Sign out are plain callbacks: no Intent, no key, no key cap. Ctrl or Cmd+Enter, the key for a surface's main action, does not run them."
  fix: "Make Retry a command bound to Ctrl or Cmd+Enter (and R if it joins the key language), with its key cap shown."

- id: SCREENS-5
  rule: "You cannot name what a move tells the user"
  severity: 2
  region: "Rotating line under `Waiting for connection`"
  evidence: "loading_screen.dart:32-35 and :47-96 (39 joke lines, shuffled in build); text_scroller.dart:26-32 (2 s timer, looping PageView)"
  observed: "The line under the title scrolls to a new random joke every 2 s for as long as the wait lasts. The motion says nothing about the connection, and only rippling busy words and skeletons may loop."
  fix: "Keep one line still and ripple the status word with `ripple`; a single joke beside it is fine."

- id: SCREENS-6
  rule: "A wait continues past 5 s"
  severity: 2
  region: "LoadingScreen title and line"
  evidence: "loading_screen.dart:8 (fixed title), :32-35; nats_connection.dart:29 (no reconnect detail passed)"
  observed: "The words never become more specific. After 5 s, or 5 minutes, the screen still says `Waiting for connection` with a random joke; it never says what it is connecting to, how many tries, or what the user can do."
  fix: "After 5 s, name the target and the next step: `Still connecting to the realm. Check that the server is running.`"

- id: SCREENS-7
  rule: "A wait is too short to notice, under 300 ms"
  severity: 2
  region: "Whole window on connect, reconnect, and start up"
  evidence: "nats_connection.dart:29 (shown on the first connecting or reconnecting state, no delay); eager_initialization.dart:82"
  observed: "Any reconnect, however brief, swaps the page for the full screen at once, so a short network blip flashes the panel away and back."
  fix: "Show nothing for the first 300 ms."

- id: SCREENS-8
  rule: "Text appears"
  severity: 2
  region: "Crash screen title, line, message, and action"
  evidence: "error_screen.dart:74-76, :89-91, :105-107, :114-116 (fade in 300 ms after 100, 200, 300 ms delays), :178-200 (same for the small screen)"
  observed: "The crash text is held back up to 300 ms and then fades in piece by piece, delaying reading."
  fix: "Let the message arrive whole on a bounce, with no delay."

- id: SCREENS-9
  rule: "Placing content"
  severity: 2
  region: "Small crash screen"
  evidence: "error_screen.dart:141-143 (column aligned start) with :167 and :183 (`TextAlign.center`); story errorscreen/default/Size=Small,Retry-action=true,Window=Desktop.png"
  observed: "The title and Retry sit on the left edge, but the message's second and third lines are centred, so the block has three left edges."
  fix: "Align every line of the small screen to the start."

- id: SCREENS-10
  rule: "Setting any visual value"
  severity: 2
  region: "LoadingScreen title and line; ErrorScreen title, line, and message"
  evidence: "loading_screen.dart:27-31, :32-35 (`fontSize: 40`, `20`, bold); error_screen.dart:64-72, :80-87, :96-103, :168-176, :184-191 (responsive literal sizes 10 to 40, bold)"
  observed: "Every text on both screens overrides the theme with literal sizes and weights."
  fix: "Use `PageHeading` and theme roles."

- id: SCREENS-11
  rule: "A shared component does the job"
  severity: 2
  region: "Start up error screen"
  evidence: "eager_initialization.dart:101-104 (`message: \"$error\"`, `ElevatedButton` Retry)"
  observed: "The start up failure shows the raw error and a stock ElevatedButton. Retry gives no busy or failure feedback, so a second failure looks like nothing happened."
  fix: "Use `LoadingButton` for Retry and a plain message with a next step."

- id: SCREENS-12
  rule: "A surface is new or changed"
  severity: 2
  region: "Stories `loadingscreen/default` and `errorscreen/default`"
  evidence: "loading_screen.stories.dart (Title and Reduce motion knobs only); error_screen.stories.dart (one hand written title and a stack trace message); images under shared/ui/screens/"
  observed: "No story shows the connection lost state over a page, the real NATS failure screens (Access denied, Connection incompatible, Server unavailable, Connection failed, Connection closed), the start up error, LoadingScreen at compact width, or Retry busy and failed. The rotating line is shuffled in build, so each render shows a different text. The loading story's doc says the messages stay still with reduced motion, but `TextScroller` never reads it (MOTION-2)."
  fix: "Add stories for each NATS failure and for reconnecting over a real page, and make the line deterministic."

## Shared faults seen here

Not repeated; see their reports.

- SERVICES-9, MEMBERS-6, RESOURCE-9: provider errors become this crash screen with raw exception text (riverpod.dart:35-45).
- MOTION-2: `TextScroller` and every `RiveAsset` ignore reduced motion; the loading story claims otherwise.
- MOTION-19: crash text fades in linearly (`flutter_animate` defaults).
- MOTION-8, MOTION-9: Retry busy and failure motion.
- MOTION-18: provider loading elsewhere uses the looping spinner instead of this screen or a skeleton.
- SHARED-SIGNIN-1: titles in JetBrains Mono. RESOURCE-20: sentences in Lilex.

## Shared

- id: SHARED-SCREENS-1
  rule: "Writing text"
  severity: 3
  region: "Any text in the danger or error colour on the light canvas: crash screen titles, the request limit message, inline error lines"
  evidence: "panel/lib/shared/theme/color_scheme.dart:15 (`Colors.redAccent` family), :111 and :154 (`danger` and `error`); error_screen.dart:71 and :175; probe: 3.04:1 on the light canvas `#F9F9FF`, 5.82:1 on dark; story errorscreen/default/initial.png"
  observed: "Red text is 3.04:1 on the light canvas, under 4.5:1. Dark passes at 5.82:1."
  fix: "Derive a danger text tone that reaches 4.5:1 on light, and keep the bright red for marks and fills."

## Cannot verify

- "You cannot name what a move tells the user" and "Reduced motion is on" for the Rive mascots (`tour.riv`, `robot_island.riv`): whether their state machines loop and how they behave is inside the binary assets, and story images do not render them. A maintainer opening the assets.
- "Something works with one input": the crash mascot sets a `zoomIn` cursor (error_screen.dart:47-48, :147-148), which suggests a pointer interaction inside the asset with no keyboard path. Opening the asset would settle it.
- "Choosing how strong a move is": how the mascots feel. A maintainer.
- Layout of both full screens: the mascot area (flex 6 and 8) is blank in images, so the empty top half cannot be judged.

## Rule results

<details>

| Rule (When) | Result |
|---|---|
| A page or surface opens | fail (SCREENS-3) |
| The focused thing disappears | fail, covered by SCREENS-1 (focus excluded on reconnect) |
| Something happens that the user did not just do | fail, covered by SCREENS-1 (layout replaced on reconnect) |
| Anything needs saying | pass (page level, no closer place) |
| Something fails | fail, covered by SCREENS-11 (start up Retry) |
| Access is lost | pass (`Access denied` hides content and offers Sign out); wording fails under SCREENS-2 |
| The connection or a service is lost | fail (SCREENS-1) |
| A wait is too short to notice, under 300 ms | fail (SCREENS-7) |
| Nothing about the page is known yet | pass (start up shows a full screen) |
| A wait continues past 5 s | fail (SCREENS-6) |
| Text appears | fail (SCREENS-8) |
| You cannot name what a move tells the user | fail (SCREENS-5) |
| Any move runs | pass (nothing blocks input) |
| Reduced motion is on | fail (MOTION-2) |
| A control is busy or unavailable | fail (MOTION-8) |
| Adding an action | fail (SCREENS-4) |
| A button has a key | fail, covered by SCREENS-4 |
| Setting any visual value | fail (SCREENS-10) |
| Showing a state | pass |
| Choosing an action's weight | pass (one filled Retry) |
| Placing content | fail (SCREENS-9) |
| Adding colour to a page | pass (red only on the error title) |
| Styling a static page | pass |
| Writing text | fail (SHARED-SCREENS-1) |
| Choosing a font | fail (SHARED-SIGNIN-1, RESOURCE-20) |
| Misreading would cost the user something | fail (SCREENS-2) |
| Nothing depends on it: sign in, empty, long wait, small success, first run | pass for start up; the jokes stand beside a plain title |
| Naming an action | fail, see Suggestions (`Authenticating User`) |
| A shared component does the job | fail (SCREENS-11) |
| A surface is new or changed | fail (SCREENS-12) |

</details>

## Skill friction

- The inventory lists "connection lost" as a screen under `shared/ui/screens/`, but no such story exists; it is the start up `LoadingScreen` reused by `RequiredNatsConnection`. I reviewed the caller from source.
- The crash screen is both a surface and a shared component already blamed in three page reports (SERVICES-9, MEMBERS-6, RESOURCE-9). The skill does not say whether the component's own review should repeat those or only add what the pages could not see; I only added new faults.
- "A wait continues past 5 s" and "A wait is too short to notice" can only be judged from source, since story images are single frames; the evidence table has no row for timing.

## Suggestions

- Start up title `Authenticating User` is Title Case and names a mechanism. Write `Signing you in`.
- The start up and connection screens share one title, `Waiting for connection`. Name what is awaited: `Connecting to Typewriter` at start up, `Connecting to the realm` for a realm.
- Rule gap, new row for Loading and waiting: When a status line rotates or changes on a timer, Then each line states a real step or fact; no line is chosen at random. Sev 2.
