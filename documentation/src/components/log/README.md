# log

An Expressive Code plugin that renders ` ```log ` fences as a Minecraft server
log viewer, built from this site's own CSS variables.

It is registered once in `astro.config.mjs` under
`starlight({ expressiveCode: { plugins: [ecLog()] } })` and applies only to code
blocks whose language is `log`. Every other language is untouched.

`LogRuntime.astro` renders nothing and carries no script: the whole component is
CSS-only, so it survives ClientRouter DOM swaps without any re-binding.

## Syntax

````markdown
```log
[12:00:01 INFO]: [Typewriter] Loading 3 extensions
[12:00:01 WARN]: [Typewriter] Extension 'Quest' is outdated
[12:00:02 ERROR]: [Typewriter] Could not load extension 'Basic'
java.lang.IllegalStateException: Manifest missing
	at com.typewritermc.engine.ExtensionLoader.load(ExtensionLoader.kt:88)
Caused by: java.io.FileNotFoundException: extension.json
	... 12 more
[12:00:03 INFO]: Done (2.1s)! For help, type "help"
```
````

### Recognised line formats

| Shape | Example |
| --- | --- |
| Bukkit/Spigot console | `[12:00:01 INFO]: message` |
| Paper/vanilla `latest.log` | `[12:00:01] [Server thread/INFO]: message` |
| Extra Log4j fields | `[12:00:01] [Server thread/INFO] [minecraft/DedicatedServer]: message` |
| Dated timestamps | `[2026-09-02 12:00:01.123] [Server thread/WARN]: message` |
| Plugin tag | `...]: [Typewriter] message` |
| Exception header | `java.lang.IllegalStateException: Manifest missing` |
| Stack frame | `\tat com.example.Foo.bar(Foo.kt:12)` |
| Chained cause | `Caused by: ...` / `Suppressed: ...` |
| Elision | `\t... 12 more` |

The parser reads an arbitrary run of leading `[...]` groups and stops at the `:`
that ends the prefix, so a `[PluginName]` tag lands in the message rather than
in the prefix.

Levels understood (mapped onto six render levels): `INFO`, `NOTICE`,
`LIFECYCLE` → info; `WARN`, `WARNING` → warn; `ERROR`, `SEVERE`, `CRITICAL` →
error; `FATAL`, `EMERGENCY` → fatal; `DEBUG`, `CONFIG`, `FINE` → debug; `TRACE`,
`FINER`, `FINEST`, `VERBOSE` → trace.

## Meta options

| Option | Owner | Effect |
| --- | --- | --- |
| `collapse-traces` | this plugin | Stack frames past the first two in each run fold into a `<details>` toggle labelled `… N more frames`. |
| `highlight="Typewriter"` | this plugin | Emphasises every whole-word occurrence of the text, case-insensitively. |
| `title="latest.log"` | EC frames | Renders the frame title bar as usual. |
| `wrap` / `wrap=false` | EC core | Soft-wraps long lines instead of scrolling. Composes with the gutter. |
| `{3}`, `mark={3-5}`, `ins={}`, `del={}` | EC text markers | Still work. A marked line keeps the marker's own background and accent bar; the level tint steps aside. |

There is no `focus` option — Expressive Code has no such feature, and `{3}`
covers the same need.

## Behaviour

- Every line gets `log-line`, `log-kind-<kind>` and, when a level is known,
  `log-level-<level>`.
- Line numbers are always on, rendered through EC's gutter API in the `earlier`
  phase so they sit ahead of any other gutter element. The gutter width is
  driven by `--log-digits`, set inline on the `<pre>` from the block's line
  count, so numbers stay aligned even inside a collapsed `<details>`. They are
  `aria-hidden` and unselectable: a screen reader reading the block would
  otherwise prefix every line with its index.
- The `<pre>` carries `tabindex="0"` unless the block is `wrap`, because a log
  block scrolls horizontally on anything narrower than a desktop pane and a
  scroll container needs a tab stop to be reachable by keyboard. EC's client
  script does the same for blocks it measures as overflowing, but it does not
  always get to them, so the tab stop is rendered in rather than waited for.
- Timestamps and thread names are dimmed, the level is coloured and bold, a
  `[Plugin]` tag is subtle, and the message takes the level's colour for
  `WARN`/`ERROR`/`FATAL`. Nothing is dimmed with `opacity`: an opacity that
  reads well on a plain row drops under 4.5:1 as soon as a level tint is
  layered under it, so the dimming is colour only.
- `WARN`/`ERROR`/`FATAL` entries get a tinted row background plus a coloured
  left accent bar, reusing EC's own `--ecLineBrdCol` so it lines up exactly with
  text-marker bars.
- Lines that EC's text markers own (`.mark`/`.ins`/`.del`) opt out of the row
  tint and the accent bar, and the segment colours defer to EC's own foreground
  there, because the marker background is EC theme colour this plugin cannot
  measure its palette against.
- The gutter fill is mixed into EC's `--ec-frm-edBg` rather than left
  translucent, so a marked line's background cannot bleed through it and drag
  the line numbers under AA.
- Stack trace lines are dimmed; `Caused by:` is bold and red, exception type
  names are emphasised, and `at`/`(File.kt:12)` are separated out.
- Continuation lines (no prefix, following an entry) inherit that entry's level
  and get the accent bar at 40% strength.
- Rows highlight on hover and the line number turns `--log-link` blue rather
  than `--color-primary`, which is only 2.7:1 on the light block ground.
- The block keeps the site's standard code-block ground, so a log block sits
  next to a normal code block without looking foreign. What sets it apart is
  the gutter band, the level tints and the accent bars.
- Shiki never sees a `log` block: the language is switched to `plaintext` in
  `preprocessLanguage`, and the resulting inline style annotations are dropped in
  `annotateCode` so the CSS classes fully own the colours. The frame, the copy
  button and the raw copied text are all unchanged.
- Anything that matches no pattern renders as plain dimmed text. Parsing is pure
  and total — there is no path that throws on odd input.

## Files

| File | Role |
| --- | --- |
| `parse-log.ts` | Pure parsing: `parseLogLine`, `parseLogLines`. No AST, no DOM. |
| `ec-log.ts` | The EC plugin: hooks, gutter, annotations, `<details>` folding. |
| `styles.ts` | `baseStyles` for the plugin, written against the site's variables. |
| `types.ts` | `LogLevel`, `LogLineKind`, `LogSegment`, `ParsedLogLine`, options. |
| `LogRuntime.astro` | Intentionally empty; the component needs no client script. |

Fixtures live in `src/content/docs/docs/logtest/index.md`.

## Naming constraint

`baseStyles` are wrapped in `.expressive-code { … }` and flattened with
`postcss-nested`, after which any selector matching
`^\.expressive-code .*(:root|html|body)` has everything before that keyword
stripped. That is what lets `:root[data-theme="light"] .log-block` escape the
scope — and it is also why **no class name here may contain the substring
`root`, `html` or `body`**, or its rule would be silently rewritten into a bare
element selector. `log-frames-list` is named that way for exactly this reason.

## Limitations

- Only the timestamp/thread/level shapes listed above are recognised. Formats
  without square brackets (plain `2026-09-02 12:00:01 INFO foo`) fall through to
  plain text.
- Minecraft `§`/ANSI colour codes are not interpreted; they render literally.
- `collapse-traces` folds runs of `at …` frames only. `Caused by:` headers,
  exception headers and `... N more` lines always stay visible so the shape of
  the trace survives.
- The `<details>` toggle is nested inside `<code>`, which HTML's content model
  technically disallows for phrasing content. Browsers render it correctly; EC
  already puts `<div>`s there.
- `highlight` takes a single literal string, matched case-insensitively on whole
  words. No regular expressions, no multiple terms.
- There is no analysis sidebar, no "problems detected" panel and no per-line
  anchor links.
- The tab width inside fences is EC's, not the log file's; leading tabs on stack
  frames are normalised to EC's indentation before parsing.
- The block background is not overridden: Starlight's own code-block styling
  wins on specificity, and matching it is the better outcome. The gutter and row
  tints are painted as neutral `color-mix` overlays on top of it so they work in
  both themes without a second palette.
- Incremental builds cache rendered markdown in `node_modules/.astro/data-store.json`.
  Editing only `styles.ts` therefore leaves already-built pages pointing at the
  previous `ec.<hash>.css`. Delete that file (or touch the page) when a CSS-only
  change appears to have no effect locally; clean CI builds are unaffected.
