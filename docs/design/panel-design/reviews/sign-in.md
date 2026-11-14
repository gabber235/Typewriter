# Sign in review

Surface: Sign in, route `/auth`, story `features/auth/presentation/authpage/default`.
Evidence: the four images under `.xtask/results/stories/features/auth/presentation/authpage/default/`
(`initial`, `dark`, `Window=Desktop`, `Window=Compact`), `panel/lib/features/auth/presentation/route.dart`,
`panel/lib/infrastructure/session/auth.dart`, the shared `LoadingButton` and `RiveAsset`, the theme
values, and a throwaway `pumpStory` probe (deleted after the run). "Probe" below refers to it.

## Summary

Close to fine for a one button page, but it is not reachable the way the rules ask. Nothing is
focused on open, the one action has no Intent, key, or key cap, and a failed sign in shows the raw
exception in a hover tooltip and a snackbar instead of at the button with a next step. The heading
overrides the theme with a literal size and uses JetBrains Mono, which the font rule does not allow.

Single most valuable change: make Sign in one command through an Intent, focus it on open, and run
it from Ctrl or Cmd+Enter with its key cap shown.

## Findings

- id: SIGNIN-1
  rule: "A page or surface opens"
  severity: 3
  region: "Whole page; Sign in button"
  evidence: "route.dart:31-34 (no autofocus); probe: on open the primary focus is the route's FocusScope, the first Tab lands on Sign in"
  observed: "Nothing is focused when the page opens, although Sign in is the only thing to act on."
  fix: "Focus Sign in on open, so Enter signs in straight away."

- id: SIGNIN-2
  rule: "Adding an action"
  severity: 3
  region: "Sign in button"
  evidence: "route.dart:31-34 (plain onPressed, no Intent or ManagedActionSet); probe: Ctrl+Enter and Ctrl+K change nothing, no key cap text on the page"
  observed: "Sign in is a plain button callback. No Intent, no key (Ctrl or Cmd+Enter is the key language for a surface's main action), no command list entry."
  fix: "Make Sign in a command through an Intent bound to Ctrl or Cmd+Enter, used by the button."

- id: SIGNIN-3
  rule: "Something fails"
  severity: 3
  region: "Sign in button"
  evidence: "auth.dart:158-163 (throws `Exception(\"Auth manager not initialized\")`; OIDC errors pass through); loading_button.dart:182-187 (snackbar with the raw error), :351-353 (error only in a hover Tooltip); the same LoadingButton path was probed in SERVICES-8"
  observed: "A failed sign in shakes the button and shows the raw exception text in a snackbar and a hover only tooltip. Nothing at the button says what happened or what to do next."
  fix: "Show a plain line under Sign in, such as `The sign in service did not answer. Press Sign in to try again.`, kept until the next press."

- id: SIGNIN-4
  rule: "A shared component does the job"
  severity: 2
  region: "Heading `Your journey starts here`"
  evidence: "route.dart:24-29 (`displayLarge.copyWith(fontSize: 40, fontWeight: FontWeight.bold)`); story authpage/default/initial.png"
  observed: "The heading is a local Text with a literal size and weight override instead of `PageHeading` at a theme size. This also breaks \"Setting any visual value\"."
  fix: "Use `PageHeading`, or a theme display role without overrides."

- id: SIGNIN-5
  rule: "Choosing a font"
  severity: 2
  region: "Heading and button label"
  evidence: "typography.dart:17 and :29 (displayLarge and labelLarge are JetBrains Mono at weight 700); story authpage/default/initial.png"
  observed: "The heading and the Sign in label render in JetBrains Mono at weight 700. The rule allows only Lilex (500 or 600 on labels) and IBM Plex Sans. Theme fault: SHARED-SIGNIN-1."
  fix: "See SHARED-SIGNIN-1."

- id: SIGNIN-6
  rule: "A surface is new or changed"
  severity: 2
  region: "Story `authpage/default`"
  evidence: "route.stories.dart:9-18 (only a Window knob); images: initial, dark, Desktop, Compact"
  observed: "No image shows hover, focus, busy (redirecting to the identity provider), a failed sign in, or reduced motion. The Rive mascot does not render in story images, so the page's only illustration is never shown."
  fix: "Add story states for focused, busy, and failed, and a renderer for the mascot or a still frame of it."

## Shared faults seen here

Not repeated; see their reports.

- MOTION-15: the page arrives on the framework route transition.
- MOTION-3, MOTION-6: Sign in hover is an ink overlay and press is an ink ripple.
- MOTION-8: busy swaps the label for a spinning `CircularProgressIndicator`.
- MOTION-9: failure plays a linear `shakeX` with no red flash.
- MOTION-2: the Rive character has no reduced motion path (`rive.dart:52-71`).
- MOTION-7: no key cap to glow.

## Shared

- id: SHARED-SIGNIN-1
  rule: "Choosing a font"
  severity: 2
  region: "Every display, headline, title, and label role in the theme: page headings, section titles, button labels"
  evidence: "panel/lib/shared/theme/typography.dart:11-31 (display, headline, title, and label roles use `JetBrainsMono`, labels at weight 650 to 700); pubspec.yaml:128; probe: `displayLarge.fontFamily == JetBrainsMono`"
  observed: "Headings and labels use JetBrains Mono, a third font the rule does not allow, and labels and buttons are set at 650 to 700 instead of 500 or 600."
  fix: "Map those roles to Lilex at 500 or 600, and body sentences to IBM Plex Sans (RESOURCE-20 covers the body part)."

- id: SHARED-SIGNIN-2
  rule: "Setting any visual value"
  severity: 2
  region: "Every filled `LoadingButton` when focused"
  evidence: "panel/lib/shared/ui/components/loading_button/loading_button.dart:197-210 (focused side is a 3 px border in the label colour)"
  observed: "A focused filled LoadingButton draws a 3 px border in its label colour (black on the brand fill) instead of the 2 px focus ring in `#009FFF` on dark and `#006FB8` on light."
  fix: "Drop the local border and let the shared focus ring draw focus."

## Cannot verify

- "A wait is too short to notice, under 300 ms" and "A wait continues past 5 s": what the page shows between pressing Sign in and leaving for the identity provider. On the web the tab navigates away; the busy state is the shared spinner (MOTION-8). A probe with a slow auth double would settle it.
- "Something is empty", "Access is lost": not applicable.
- "A static page feels boring": the Rive character fills most of the page, but story images never render it. A maintainer judging live.
- "Choosing how strong a move is": how the character's state machine feels. A maintainer.
- "You cannot name what a move tells the user": whether `game_character.riv` loops is inside the binary asset. If it loops forever it breaks the rule; a maintainer opening the asset settles it.

## Rule results

<details>

| Rule (When) | Result |
|---|---|
| A user's action finishes and they have not moved on | not applicable (the page leaves) |
| A page or surface opens | fail (SIGNIN-1) |
| Anything needs saying | fail, covered by SIGNIN-3 |
| Something succeeds | pass (the page is left on success) |
| Something fails | fail (SIGNIN-3) |
| A wait is too short to notice, under 300 ms | cannot_verify |
| A wait continues past 5 s | cannot_verify |
| The window is under 900 px, or a pane would be narrower than 320 px | pass (Compact image keeps the one action) |
| The user causes something to arrive | not applicable |
| Moving between pages with nothing to carry over | fail (MOTION-15) |
| Showing any state on something | fail (MOTION-8) |
| Anything changes state | fail (MOTION-8) |
| Anything grows or responds over time | fail (MOTION-6) |
| Text appears | pass (static text) |
| A key is in use | fail (MOTION-7) |
| A control is busy or unavailable | fail (MOTION-8) |
| The pointer reaches something you can act on | fail (MOTION-3) |
| A button has a key | fail, covered by SIGNIN-2 (no key at all) |
| Focus moves | fail (MOTION-4) |
| You cannot name what a move tells the user | cannot_verify |
| Reduced motion is on | fail (MOTION-2) |
| Adding an action | fail (SIGNIN-2) |
| Something works with one input | pass |
| Choosing any key | not applicable |
| Moving around | pass (Tab reaches Sign in) |
| Only touch is available | not applicable |
| Setting any visual value | fail (SIGNIN-4, SHARED-SIGNIN-2) |
| Showing a state | pass |
| Choosing an action's weight | pass (one filled button) |
| Placing content | pass (one centred column) |
| A static page feels boring | cannot_verify |
| Adding colour to a page | pass (only the brand button) |
| Styling a static page | pass |
| Writing text | pass (heading and label above 4.5:1 in both themes) |
| Choosing a font | fail (SIGNIN-5) |
| Nothing depends on it: sign in, empty, long wait, small success, first run | pass (`Your journey starts here` beside a plain `Sign in`) |
| Naming an action | pass |
| A shared component does the job | fail (SIGNIN-4) |
| A surface is new or changed | fail (SIGNIN-6) |
| Keyboard behaviour is new or changed | not applicable |

</details>

## Skill friction

- The Rive mascot is the largest thing on this page and on the start up and crash screens, but the test renderer draws nothing, so half of each image is blank. The skill does not say whether to judge the layout without it.
- "Adding an action" asks for a command list entry, but signed out pages have no command list at all. The skill does not say whether pages outside the shell are exempt.

## Suggestions

- First time user: nothing says what Typewriter is or which account signs in. Add one serious line under the heading, such as `Sign in with your Typewriter account to manage your servers.`, beside the playful heading.
- Rule gap, new row for Building: When a story shows a Rive asset, Then the story renderer draws a still frame of it, so images show the real layout. Sev 2.
