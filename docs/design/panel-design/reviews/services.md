# Services page review

Route `services`. Stories `features/services/presentation/servicespage/default` and `.../inspector`.
Key paths and focus come from a temporary `pumpPanel` probe test (run through `cargo xtask heavy`, then deleted).

## Summary

Not yet good. The graph reads at a glance, but the page breaks the rules where trust matters most:
Unbind is permanent and runs on Ctrl+Backspace then Enter, failures say nothing useful at the
control, every status is coloured, and most card text is under 4.5:1.

The single most valuable change: make Unbind a hold with a stated outcome, and leave focus on the next
card afterwards (SERVICES-1, SERVICES-3).

## Findings

- id: SERVICES-1
  rule: "An action cannot be undone, or undo is not built yet"
  severity: 4
  region: "Unbind, inspector Operations and Ctrl+Backspace on a selected card"
  evidence: "panel/lib/shared/selectables/operations/unbind_operation.dart:41-48; panel/lib/shared/ui/components/popups.dart:151; probe test: Ctrl+Backspace opened the dialog with focus on Unbind, Enter then unbound the service"
  observed: "Unbind opens `showConfirmationDialogue` (an AlertDialog) with the Unbind button autofocused, so Ctrl+Backspace, Enter disconnects the service. There is no hold, no outcome line, and no Undo. The title reads `Unbind 1 item(s)?`."
  fix: "Use the hold component: the card or button fills on `hold` and types `Unbind discord_bridge? It disconnects straight away.` in reserved space; releasing cancels. Under the hold setting, show the dialog with Cancel focused and confirm by Ctrl or Cmd+Enter."

- id: SERVICES-2
  rule: "A page or surface opens"
  severity: 3
  region: "Whole page on arrival"
  evidence: "panel/lib/features/services/presentation/route.dart:12-52 (no autofocus); probe test: focus is null after the page loads"
  observed: "Nothing has focus when the page opens. The first Tab lands on the pane, not on an item."
  fix: "Focus the first graph card when services exist. With no services, focus the registration field, since typing is then the page's purpose."

- id: SERVICES-3
  rule: "The focused thing disappears"
  severity: 3
  region: "Graph card after a successful Unbind"
  evidence: "unbind_operation.dart:67-73; probe test: focus is null after the Discord card is removed"
  observed: "The unbound card leaves and focus is dropped. The user has to click back into the graph."
  fix: "Move focus to the nearest neighbouring card, next before previous, otherwise to the graph pane."

- id: SERVICES-4
  rule: "Writing text"
  severity: 3
  region: "Card titles and status words in the graph; coloured inspector titles"
  evidence: "panel/lib/shared/ui/components/grid_selectable_card.dart:95,108; panel/lib/features/services/presentation/services_graph.dart:275; tokens in panel/lib/features/services/application/service_projection.dart:3-6; story servicespage/default/Services=Complete,Window=Desktop.png"
  observed: "Text is drawn in the kind colour on a 15% tint of the same colour. Light theme: realm (deepOrangeAccent) 2.38:1, service (green) 2.42:1, engine (blueAccent) 2.82:1, host (blueGrey) 3.67:1. Offline cards are faded to 0.58 opacity: 1.6 to 1.9:1 light, 2.0 to 2.6:1 dark. Inspector titles such as `discord_bridge` use the same colours on the page background."
  fix: "Draw titles and status words in the theme's on surface text colour; keep the kind colour for the tile, badge, and icon only."

- id: SERVICES-5
  rule: "Showing the health of many things"
  severity: 3
  region: "Status line on every graph card; Connection and Realm hosting in the inspector"
  evidence: "services_graph.dart:302-343, 413-419; story servicespage/default/Services=Complete,Window=Desktop.png; inspector/Selected=Host-paper-alpha,-Active.png"
  observed: "Every card carries a coloured dot, and `Active`, `Connected`, and `Available` are green. Offline cards are faded instead of emphasised, so the wrong things get less weight than the healthy ones."
  fix: "Show healthy states as muted words with no colour. Give only Failed, Drifted, Offline and similar wrong states the status colour and more weight; never fade a card because it is wrong."

- id: SERVICES-6
  rule: "Showing a state"
  severity: 3
  region: "Same status on a graph card and in the inspector"
  evidence: "services_graph.dart:390-411 against panel/lib/features/services/application/service_inspector_layout.dart:209-250; inspector/Selected=Engine-paper-rollback,-Rolled-back.png, Selected=Realm-creative,-Staging.png, Selected=Host-paper-beta,-Reconciling.png"
  observed: "Two separate status maps disagree. Rolled back is grey on the card and orange in the inspector; Staging and Reconciling are orange on the card and blue in the inspector; Quiescing is warning on the card and paused in the inspector."
  fix: "One status map, one `StatusIndicator`, used by the card and the inspector."

- id: SERVICES-7
  rule: "Showing a state"
  severity: 3
  region: "Keyboard focus on a graph card"
  evidence: "grid_selectable_card.dart:114-117"
  observed: "Focus is a 2 px border in the card's kind colour, not the focus ring. On a selected card the border matches the fill, so focus disappears; the orange and green borders are under 3:1 against the page."
  fix: "Use the shared 2 px focus ring (`#009FFF` dark, `#006FB8` light) outside the card, so focus and selection stay distinct."

- id: SERVICES-8
  rule: "Something fails"
  severity: 3
  region: "Connect button and registration field; Unbind"
  evidence: "panel/lib/shared/ui/components/loading_button/loading_button.dart:182-186, 349-353; probe test with `servicesService(commandFailure: ...)`; panel/test/features/services/presentation/services_grid_test.dart:105-108"
  observed: "A failed Connect shakes the button and puts the error in a hover only tooltip. What the page shows is `Needs attention` and `The operation result could not be confirmed`, away from the control and with no next step. A failed Unbind opens an `Unbind errors` popup reading `404: Service not found`."
  fix: "Show the message under the registration field, saying what happened and what to do (for example `That token is not known. Copy a new token from the service log and press Connect.`). It stays until the next try. Show an Unbind failure at the inspector button in plain words, not as a popup with a status code."

- id: SERVICES-9
  rule: "The connection or a service is lost"
  severity: 3
  region: "Graph area when the services or topology backend is unreachable"
  evidence: "panel/lib/shared/ui/components/riverpod.dart:36-44; panel/lib/shared/ui/screens/error_screen.dart:25; story servicespage/default/Services=Services-failing,Window=Desktop.png, Services=Topology-failing,Window=Desktop.png"
  observed: "The graph is replaced by the crash screen: a 40 px red `Typewriter hit an error`, `please report this to the Typewriter discord`, and the raw `Bad state: The services backend is unreachable`."
  fix: "Show one steady notice in the pane, such as `The services backend did not answer. The panel keeps trying.`, keep any graph already loaded readable, and keep the crash screen for real crashes."

- id: SERVICES-10
  rule: "The layout is known and its content is not"
  severity: 2
  region: "Graph area while services or topology load"
  evidence: "riverpod.dart:31-33; story Services=Services-loading,Window=Desktop.png, Services=Topology-loading,Window=Desktop.png"
  observed: "A looping circular spinner with `Loading Services...` or `Loading Runtime Topology...` fills the middle of the pane."
  fix: "Show a skeleton of the card grid that shimmers, then ripple the cards in with `loadIn`."

- id: SERVICES-11
  rule: "Moving around"
  severity: 2
  region: "Tab order across the page"
  evidence: "probe test: 16 Tab presses cycle pane, then the four cards, then the pane again; arrows from the pane do nothing"
  observed: "Tab never reaches the registration field, Connect, or any inspector control. Connect is reachable only by an arrow key from a card."
  fix: "Make the registration row, the graph, and the inspector Tab groups, with arrows and H, J, K, L inside the graph."

- id: SERVICES-12
  rule: "An action means something the key language already covers"
  severity: 2
  region: "Unbind shortcut"
  evidence: "unbind_operation.dart:26-28; probe test: D, Delete and Backspace do nothing on a selected card"
  observed: "Unbind uses Ctrl+Backspace, a key outside the language. D, Delete, and Backspace, which mean remove, do nothing."
  fix: "Bind Unbind to D, Delete, and Backspace on a service, named `Unbind service` in context, behind the hold from SERVICES-1."

- id: SERVICES-13
  rule: "Choosing an action's weight"
  severity: 2
  region: "Connect on the registration row; Unbind and Open under the inspector's Operations heading"
  evidence: "unbind_operation.dart:98-115; registration_token_input.dart:485-489; inspector/Selected=Service-discord_bridge,-online.png, Selected=Realm-main,-Active.png"
  observed: "Filled buttons sit in the pane body, not in the pane header. Unbind is filled in raw orange, the warning status colour, so an action looks like a status."
  fix: "Put at most one filled button in each pane header, right side. Make Unbind quiet; its hold gives it weight."

- id: SERVICES-14
  rule: "Placing content"
  severity: 2
  region: "Page heading, registration row, graph; inspector title, section headers, fields"
  evidence: "story Services=Complete,Window=Desktop.png: heading at x 262, field at 248, first card at 293; inspector/Selected=Host-paper-alpha,-Active.png: title at 1002, `Name` at 1014, `CONNECTION` at 1026, `Service` at 1070"
  observed: "Titles and their content start on three or four different left edges in each pane."
  fix: "Align heading, field, and graph to one left edge; align the inspector title, section headers, labels, and values to one edge."

- id: SERVICES-15
  rule: "Setting any visual value"
  severity: 2
  region: "Graph cards and Unbind"
  evidence: "services_graph.dart:275 (opacity 0.58), 285 (icon size 30), 324-325 (dot 7 px); unbind_operation.dart:39,103 (`Colors.orange`); grid_selectable_card.dart:20-21 (250 ms `fastEaseInToSlowEaseOut`)"
  observed: "Opacity, icon size, dot size, button colour, and the card's state transition are literals, not tokens."
  fix: "Use the theme's warning or neutral colours, the 20 px control icon size, and a motion token for state changes."

- id: SERVICES-16
  rule: "Naming an action"
  severity: 2
  region: "Unbind dialog title; key hint bar; loading text"
  evidence: "unbind_operation.dart:44; story servicespage/default/initial.png key hint bar; riverpod.dart:32"
  observed: "`Unbind 1 item(s)?` has no real plural. `Switch Focus`, `Switch Panes`, and `Loading Runtime Topology...` are title case."
  fix: "`Unbind discord_bridge?` or `Unbind 3 services?`; `Switch focus`, `Switch panes`, sentence case throughout."

- id: SERVICES-17
  rule: "A surface is new or changed"
  severity: 2
  region: "Stories for the Services page"
  evidence: "panel/widgetbook/lib/stories/features/services/presentation/route.stories.dart:11-87"
  observed: "No story shows a hovered card, a focused card, a focused and selected card, several cards selected, Unbind confirming, busy, or failed, Connect busy or failed on the page, a rejected rename, the connection lost, or the inspector at compact width."
  fix: "Add those states as traits of the page stories."

- id: SERVICES-18
  rule: "A shared component does the job"
  severity: 2
  region: "Graph card status line; Unbind confirmation"
  evidence: "services_graph.dart:302-343 (`TopologyStatusIndicator`); unbind_operation.dart:41 (`showConfirmationDialogue`)"
  observed: "The graph has its own status widget beside the shared one the inspector uses, which is how SERVICES-6 arose. Unbind uses the confirmation dialog the rules list under Never."
  fix: "Use `StatusIndicator` in the card and the hold component for Unbind."

- id: SERVICES-19
  rule: "A control is busy or unavailable"
  severity: 2
  region: "Connect and Unbind while their request runs"
  evidence: "loading_button.dart:321-324 (`_Spinner` replaces the label)"
  observed: "The busy button swaps its label for a spinner instead of looking pressed in and typing the busy word."
  fix: "Press the button in, type `Connecting` or `Unbinding`, and ripple its letters with `ripple`. This is in the shared `LoadingButton`, so every page gains it."

- id: SERVICES-20
  rule: "Something is empty"
  severity: 2
  region: "Graph area with no services"
  evidence: "services_graph.dart:31-37; story Services=No-services,Window=Desktop.png"
  observed: "A grey server icon, `No services connected`, and `Start a Typewriter service and enter its registration token above.` There is no mascot or playful line, and the main action is not beside it with its key."
  fix: "Mascot, a playful line, the existing sentence as subtitle, and the registration field with Connect on the right in the empty state itself."

## Cannot verify

- Every Motion rule (`rowIn` when Connect adds a card, `loadIn`, `listOut` when a card is unbound, `wave` when a rename shows elsewhere, `press`, `hoverIn`, `capIn`, `focusMove`, `paneFocus`). Images never prove motion. A maintainer judges the feel in a live panel.
- "The window is too narrow for side by side": the compact story keeps the sidebar beside a narrow pane and clips cards on the right. Whether that width counts as too narrow is not stated. A compact story with the inspector open would settle it.
- "Any action" in the command list: after Ctrl+K with a card selected, `Unbind` text was on screen, but the probe could not tell the command list from the inspector behind it. A probe that reads only the search overlay would settle it.
- Esc from Ctrl+K left focus on an unlabeled node, not the card. That belongs to the Search review.
- "Only touch is available" and the touch path for double tap to open a Realm: no touch story.
- "Reduced motion is on": no story or test exercises it.
- Dark theme contrast: the card surface is derived from the seed scheme. I used `#1B1C1F` as an approximation, so the dark figures in SERVICES-4 are close but not exact.

## Suggestions

- **Realm cards carry their host's name.** `services_graph.dart:201` titles a Realm with `realm.ownerHost.name`, so `Paper Alpha` appears as both a host and a Realm, and the Realm's own name (`main`, `survival`) shows only as the inspector subtitle. Title the card with the Realm's name and put the host in the inspector. A wrong Open is the likely result today.
- **One thing, three names.** The host card says `Paper Alpha`; its inspector says `paper_alpha` with the subtitle `paper-alpha`. The engine card says `paper ^1`; its inspector says `paper engine`. Use one display name in both places.
- **The graph opens mid row.** It centres on the centre of mass, so the top row is cut off under the registration field on arrival. Open anchored to the top left of the content.
- **Selecting a host service highlights nothing.** `inspector/initial.png` shows the `paper_alpha` service in the inspector with no card selected, since the host card stands for it. Select the host card when its service is selected.
- **What is this page for?** The subtitle explains it, but the eye lands first on the bright Connect button and the coloured tiles, not on the Failed or Drifted runtimes. Once SERVICES-5 is fixed, the wrong ones become the first thing seen.
- **What can be removed?** The dotted grid behind the cards does no work on a packed layout. Each card shows its kind twice, as a badge and as an icon. The registration row takes the top of the page forever, though it is used once per service; it could become the create action (N) and the empty state.
- **Expert speed.** Connecting another service has no key; N, "Create a new thing here", fits.
- **First time user.** The empty state says to enter a token but not where a token comes from. Link the docs page that shows where a service prints its token.
- **Runtime failure messages.** `Manifest activation failed` in the Realm inspector says what happened but not what to do.
- **Rule gap.** When the same thing appears in two places on one page, then it has one name and one status look in both. Sev 3.
- **Rule gap.** When an inspector shows an engine or other list as chips, then the chips are soft filled, never outlined; an outline reads as the focus ring. Sev 2. (Supported engines chips are outlined in blue today.)

## Rule results

<details>
<summary>Every applicable rule</summary>

| Rule (When) | Result |
|---|---|
| A user's action finishes and they have not moved on | pass: Esc on the Unbind dialog returns focus to the card; after Connect, focus stays in the field |
| The focused thing disappears | fail, SERVICES-3 |
| A page or surface opens | fail, SERVICES-2 |
| Something happens that the user did not just do | cannot_verify |
| A task concerns something on screen | pass: inspector beside the graph; a new service appears as a card |
| A task needs more room than its place has | pass: nothing on this page needs it |
| Other work cannot continue until a question is answered | fail, folded into SERVICES-1 |
| The window is too narrow for side by side | cannot_verify |
| Anything needs saying | fail, SERVICES-8 |
| Something succeeds | pass: a successful Connect shows the new card and clears the field |
| Something fails | fail, SERVICES-8 |
| Something is empty | fail, SERVICES-20 |
| The connection or a service is lost | fail, SERVICES-9 |
| A wait is too short to notice, under 300 ms | cannot_verify |
| The layout is known and its content is not | fail, SERVICES-10 |
| Loaded content arrives | cannot_verify |
| The user causes one new row | cannot_verify |
| An action cannot be undone, or undo is not built yet | fail, SERVICES-1 |
| Anything would skip those rules | fail, SERVICES-1 |
| Showing any state on something | fail: SERVICES-5 (dots), SERVICES-19 (spinner) |
| Anything grows or responds over time | fail, SERVICES-15 (eased card transition) |
| A key is in use | cannot_verify |
| A control is busy or unavailable | fail, SERVICES-19 |
| A button has a key | pass: Unbind and Open show their key caps |
| Focus moves | cannot_verify |
| You cannot name what a move tells the user | fail, SERVICES-10 (looping spinner) |
| Adding an action | pass: Unbind and Open are operations shared by key, button, menu, and command list |
| Something works with one input | pass: Realm opens by double tap or Ctrl+Enter; pan by focus centring |
| Keys change meaning | pass: the mode chip shows NORMAL, then INSERT in the field |
| An action means something the key language already covers | fail, SERVICES-12 |
| Choosing any key | pass |
| Placing an action | pass: Unbind and Open act on the selection |
| An action cannot work here | pass: the hint bar shows Unbind only for services and Open only for Realms |
| Moving around | fail, SERVICES-11 |
| Setting any visual value | fail, SERVICES-15 |
| Showing a state | fail, SERVICES-6, SERVICES-7 |
| Choosing an action's weight | fail, SERVICES-13 |
| Placing content | fail, SERVICES-14 |
| Showing many things that have details | pass: graph with inspector |
| A static page feels boring | pass: kind colour tiles |
| Showing the health of many things | fail, SERVICES-5 |
| Styling a static page | pass, with the dotted grid noted under Suggestions |
| Writing text | fail, SERVICES-4 |
| Choosing a font | pass: Lilex throughout |
| Misreading would cost the user something | fail, folded into SERVICES-8 and SERVICES-9 |
| Naming an action | fail, SERVICES-16 |
| A shared component does the job | fail, SERVICES-18 |
| A surface is new or changed | fail, SERVICES-17 |
| Keyboard behaviour is new or changed | pass: services_grid_test.dart covers key paths for Unbind and rename |

</details>

## Skill friction

- **Pass records have no home.** Step 5 says to record `pass`, `fail`, or `cannot_verify` for every rule, but the Output block has no section for them. I added `Rule results` in a collapsed block.
- **Severity of `item(s)` conflicts.** The Severity table gives `item(s)` as a severity 1 example, while the rule it breaks ("Naming an action") says Sev 2, and the skill says to use the rule's Sev. I used 2.
- **No rule for naming the same thing consistently.** The Realm card titled with its host's name is the most misleading thing on the page, yet no When covers it; the closest ("Misreading would cost the user something") is about sentence style. It went under Suggestions, though it arguably outranks most findings.
- **"Showing the health of many things" and "Showing a state" overlap.** The colour of a status falls under both; I split findings by cause (too much colour against inconsistent colour).
- **Shared components and shell findings.** `LoadingButton`, the crash screen, the hint bar, and the confirmation dialog are shared, so the same finding will recur on every page. The skill does not say whether to report it once in `cross-page.md` or on each page.
- **Compact has no threshold.** "The window is too narrow for side by side" has no width, and the compact story still renders the sidebar beside the pane, so I could not decide pass or fail.
- **The inventory lists only page stories.** `RegistrationTokenInput` has its own story with the invalid, slow, and failing states, but it is not in the inventory and was not rendered, so I took its states from a probe test.
- **Fakes shape failure text.** The testkit fake's `commandFailure` produced `The operation result could not be confirmed`. The skill says to fail an action "through a fake" but not how to tell fake wording from real wording.
- **The command list check is hard to isolate.** "the command list shows it" needs a driver that reads only the search overlay; `panel.shows` also matched the inspector behind it.
- **Too many inspector images.** The inspector story renders 29 images that are nearly identical. Opening each one at full size, as step 3 asks, cost a lot and added little after the first of each kind.
- **Contrast in dark needs the derived surface.** "Compute it from the token values" fails when the surface comes from `ColorScheme.fromSeed` and has no token. I approximated it.
