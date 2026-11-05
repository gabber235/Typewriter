# Motion

Motion serves the questions in [experience.md](experience.md). This chapter defines how each move
behaves. Everything moves like one machine, with a small vocabulary, so that each action keeps a single
meaning across the panel.

## The vocabulary

| Action | Feels like | Used for |
| --- | --- | --- |
| **Strike** | A struck key: fast, overshoots once, settles | Surfaces arriving: panels, dialogs, menus; the focus ring's slide |
| **Carriage** | Runs into a stop and recoils slightly | Content arriving: new rows; button presses |
| **Exit** | Leaves at once, no overshoot | Everything leaving |
| **Type** | Letters appear one at a time | Short status words: `Saved`, `Copied`; breadcrumbs |
| **Jam** | Brief sideways judder | Something refused: invalid input, failed save |
| **Ink** | A mark that appears, then dries | What changed: edits here, and changes made elsewhere |
| **Caret** | A blinking caret | Waiting. The only motion allowed to loop |
| **Step** | Progress that clicks forward | Measurable work |

## Rules

### MO-01 MUST: Every move has a job

A move answers a question from [experience.md](experience.md), using this vocabulary.

- Why: motion nobody can explain is noise, and it dilutes the moves that matter.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: a new row arrives with Carriage, because it shows what was added and where.
- Don't: cards scale on hover because it looks lively.

### MO-02 MUST: Moves land

Arrivals have a landing: Strike overshoots and Carriage recoils. A plain fade is not an arrival, except
for tooltips and live changes, which must stay quiet.

- Why: weight is the panel's character. A move with no landing feels soulless.
- Check: `human`, `visual-llm`.
- Broken: severity 2.
- Do: a dialog strikes in and the page gives way beneath it.
- Don't: a 120 ms fade on every surface.

### MO-03 MUST: In place quickly

A moving thing reaches its final position within 150 ms. The landing plays out after that, and nobody
has to wait for it. Everything that moves can be retargeted at any moment.

- Why: speed comes from when a thing arrives; character comes from how it settles.
- Check: `test` against the token curves.
- Broken: severity 3.
- Do: a panel in place at about 140 ms, fully settled at 420 ms.
- Don't: a one second move that must end before the next key works.

### MO-04 MUST: Exits never bounce

Everything leaves with Exit, faster than it arrived.

- Why: an elastic close bounces against the side of the screen and looks wrong.
- Check: `test` against the token curves.
- Broken: severity 2.
- Do: the panel opens with Strike and closes with Exit.
- Don't: use one elastic curve for both directions.

### MO-05 MUST: One loud thing at a time

Only the user's current action gets a loud move. Decorative loops are not allowed. Only Caret and
loading placeholders may repeat.

- Why: stillness is what makes the moving thing the important thing.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: a jam on the first invalid field, and still marks on the others.
- Don't: rotating messages or rotating key hints.

### MO-06 MUST: Tokens only

All durations and curves come from the motion tokens below, and reduced motion is handled by those
tokens rather than by each widget.

- Why: today each widget opts in on its own, so most forget.
- Check: `lint`; extend `design_system_guardrails_test.dart`.
- Broken: severity 2.

## Tokens

These are starting values, to be tuned in the real panel. Curves are defined by formula, so their exact
behaviour can be tested.

| Token | Curve | Duration | Landing |
| --- | --- | --- | --- |
| `panelIn` | Strike | 420 ms | 10% overshoot |
| `dialogIn` | Strike | 340 ms | 14% overshoot; the page behind scales to 0.98 |
| `focusMove` | Strike | 170 ms | 5% overshoot |
| `rowIn` | Carriage | 280 ms | 6% recoil; arrives from the left |
| `press` | Carriage | 220 ms | 12% recoil |
| `panelOut` | Exit | 200 ms | None |
| `dialogOut` | Exit | 150 ms | None |
| `rowOut` | Exit | 160 ms | None |
| `type` | Stepped | 36 ms per letter | None |
| `ink` | Ease out | 900 ms fade | None |

- **Strike** is a damped spring: `1 - e^(-z*w*t) * (cos(wd*t) + (z*w/wd) * sin(wd*t))`, with `t` from 0 to
  1, `w = 5/z`, `wd = w*sqrt(1 - z*z)`. The damping `z` comes from the overshoot `o`:
  `z = -ln(o) / sqrt(pi^2 + ln(o)^2)`.
- **Carriage** moves as `1 - (1 - t/h)^1.6` until the hit at `h = 0.42`, then recoils by amplitude `a` as
  `1 - a * sin(pi*p) * (1 - p)^1.2`, where `p = (t - h) / (1 - h)`. `press` hits at `h = 0.3`.
- **Exit** is `Cubic(0.4, 0, 0.2, 1)`.

## Mascots

Rive mascots appear only away from active work (see [voice.md](voice.md)). They stop under reduced motion,
and never run while someone is working.

## Demos

[demos/experience.html](demos/experience.html) plays each question live. Open it in a browser. It is the
reference for feel; the tokens above are the reference for values.
