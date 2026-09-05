---
badge: new
title: Writing Syntax
description: Every authoring feature of this site on one page, each with its
  source and the rendered result.
editUrl: true
head: []
template: doc
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
---

import { Steps } from '@components/steps';
import { Tabs, Tab } from '@components/tabs';
import { VideoPlayer } from '@components/video';

:::tldr
Pages are Markdown plus a handful of directives. Inline ones look like `:name[text]`, block ones open with `:::name` and close with `:::`. Components such as Steps, Tabs and the video player are imported in `.mdx` files only.
:::

## Page basics

Every page starts with frontmatter. `title` and `description` are required; `badge` is optional and shows next to the page title in the sidebar.

```md
---
title: Writing Syntax
description: Every authoring feature on one page.
badge: new
---
```

Headings start at `##`. The title comes from the frontmatter, so never write a `#` heading. Use `.md` unless you import a component; then use `.mdx`.

## Inline text

### Keyboard keys

`+` joins keys pressed together, `,` separates keys pressed one after another. Names like `cmd`, `shift`, `enter` and `up` get their symbols.

```md
Press :kbd[Shift+M] to enter Move mode, or :kbd[Ctrl+H, Ctrl+L] to hop between panes.
```

Press :kbd[Shift+M] to enter Move mode, or :kbd[Ctrl+H, Ctrl+L] to hop between panes.

### Commands

A command chip copies itself when clicked. Add `{nocopy}` for a plain chip.

```md
Run :cmd[/tw reload] after editing. Read-only: :cmd[/tw version]{nocopy}.
```

Run :cmd[/tw reload] after editing. Read-only: :cmd[/tw version]{nocopy}.

### Variables

Values come from `src/content/variables.yml`, so a version bump is one edit. They work in text, in bold, and inside link URLs.

```md
Typewriter :var[latest] needs Java :var[java]. Join the [Discord](:var[discord]).
```

Typewriter :var[latest] needs Java :var[java]. Join the [Discord](:var[discord]).

### Glossary terms

Terms are never linked automatically. Mark the first meaningful mention on a page; the reader gets a hover card. Use `as=` when the wording differs from the glossary aliases.

```md
An :term[entry] lives on a :term[page] inside a :term[book]. Every :term[node on the graph]{as=page-element} is one.
```

An :term[entry] lives on a :term[page] inside a :term[book]. Every :term[node on the graph]{as=page-element} is one.

### Highlight

```md
Only the ==first trigger== fires.
```

Only the ==first trigger== fires.

## Callouts

Asides take a variant name and an optional title in brackets. Variants: `info`, `warning`, `danger`, `success`, `tip`, `note`, `example`, `experimental`, `deprecated`, `bug`, `performance`.

```md
:::tip[Reloading]
:cmd[/tw reload] picks up new extensions without a restart.
:::

:::warning
Facts are per player. Do not use them for global state.
:::
```

:::tip[Reloading]
:cmd[/tw reload] picks up new extensions without a restart.
:::

:::warning
Facts are per player. Do not use them for global state.
:::

### All variants

Without a bracketed title, each variant uses its own default title.

```md
:::info
Something worth knowing.
:::
```

:::info
General information the reader should have before continuing.
:::

:::warning
Something that can go wrong if the reader is not careful.
:::

:::danger
Something that destroys data or cannot be undone.
:::

:::success
What a correct result looks like.
:::

:::tip
A shortcut or a better way to do the same thing.
:::

:::note
A side remark that does not affect the main flow.
:::

:::example
```yaml
websocket:
  port: 9092
```
:::

:::experimental
Behaviour that may still change before the next release.
:::

:::deprecated
Still works, but has a replacement you should move to.
:::

:::bug
A known issue and its workaround.
:::

:::performance
Something that gets slow at scale and how to avoid it.
:::

## Blocks

### TL;DR

A summary box for the top of long pages. The label is optional.

```md
:::tldr
Facts store per-player numbers. Set them with actions, read them with criteria.
:::
```

:::tldr
Facts store per-player numbers. Set them with actions, read them with criteria.
:::

### Collapsible

A native collapsible. `{open}` starts it expanded, `{id=anchor}` makes it linkable, and blocks sharing a `{name=group}` close each other, so only one is open at a time.

```md
:::details[Why does this happen?]
A player runs one interaction at a time. A new one only replaces the current one when its priority is equal or higher.
:::
```

:::details[Why does this happen?]
A player runs one interaction at a time. A new one only replaces the current one when its priority is equal or higher.
:::

### Gated section

For content you would rather people did not use. The whole section stays blurred behind a card until the reader opts in. Variants: `warning` (default), `danger`, `info`, `neutral`; `{open}` starts revealed.

```md
:::spoiler[Not recommended]{reason="The next build overwrites this file." button="Show me anyway" variant=warning}
## Editing extension.json by hand

The extension processor generates it from your annotations.
:::
```

:::spoiler[Not recommended]{reason="The extension processor regenerates this file on every build, so hand edits disappear." button="Show me anyway" variant=warning}
### Editing extension.json by hand

Change the `@Entry` annotations in your Kotlin sources instead. If you must inspect the file, it sits in the built JAR.

```json
{ "extension": { "name": "Basic", "namespace": "typewritermc", "engineVersion": "1.0.2" } }
```
:::

## Interactive

### Decision wizard

A nested list becomes a click-through questionnaire. The single top-level item is the root question, its children are answers, and `Answer → Follow-up question` items nest further. Items without children are results. `{persist}` remembers the reader's path for the session.

```md
:::wizard[Which dialogue entry do I need?]
- Should the player see text?
  - Yes → Should they pick an option?
    - Yes → Use the **Option Dialogue** entry.
    - No → Use the **Spoken Dialogue** entry.
  - No → Look at the action entries instead.
:::
```

:::wizard[Which dialogue entry do I need?]
- Should the player see text?
  - Yes → Should they pick an option?
    - Yes → Use the **Option Dialogue** entry.
    - No → Use the **Spoken Dialogue** entry.
  - No → Look at the action entries instead.
:::

### Annotated screenshot

Pins are placed by percentage. Clicking a pin opens its description; the legend list stays hidden unless the image cannot be shown. `{numbers=false}` gives dot pins, `{legend=visible}` always shows the list.

```md
:::hotspots[The page editor of a book]
![The panel](./panel.png)

1. [12%, 30%] **Pages** — every page in the book, grouped by chapter.
2. [50%, 45%] **Graph** — page elements are the nodes, triggers are the edges.
3. [86%, 20%] **Inspector** — fields of the selected element.
:::
```

:::hotspots[The page editor of a book]
![The panel](./panel.png)

1. [12%, 30%] **Pages** — every page in the book, grouped by chapter.
2. [50%, 45%] **Graph** — page elements are the nodes, triggers are the edges.
3. [86%, 20%] **Inspector** — fields of the selected element.
:::

### Before and after

Two images of the same size, split by a draggable handle. Options: `start` (percent), `orientation=vertical`, `hover`.

```md
:::compare[Before|After]{start=50}
![The old panel](./before.png)
![The new panel](./after.png)
:::
```

:::compare[Before|After]{start=50}
![The old panel](./before.png)
![The new panel](./after.png)
:::

## Code

### Code blocks

Fenced blocks support a title, line marks and diff marks.

````md
```yaml title="config.yml" {2} ins={4} del={3}
websocket:
  port: 9092
  host: 0.0.0.0
  hostname: play.example.com
```
````

```yaml title="config.yml" {2} ins={4} del={3}
websocket:
  port: 9092
  host: 0.0.0.0
  hostname: play.example.com
```

### Server logs

Use the `log` language for Paper output. Levels are coloured, stack traces are dimmed. Options: `title="latest.log"`, `collapse-traces`, `highlight="Typewriter"`, `wrap`.

````md
```log highlight="Typewriter"
[12:00:01 INFO]: [Typewriter] Loading 3 extensions
[12:00:01 WARN]: [Typewriter] Extension 'Quest' is outdated
[12:00:02 ERROR]: [Typewriter] Could not load extension 'Basic'
java.lang.IllegalStateException: Manifest missing
	at com.typewritermc.engine.ExtensionLoader.load(ExtensionLoader.kt:88)
```
````

```log highlight="Typewriter"
[12:00:01 INFO]: [Typewriter] Loading 3 extensions
[12:00:01 WARN]: [Typewriter] Extension 'Quest' is outdated
[12:00:02 ERROR]: [Typewriter] Could not load extension 'Basic'
java.lang.IllegalStateException: Manifest missing
	at com.typewritermc.engine.ExtensionLoader.load(ExtensionLoader.kt:88)
```

## Components

These need an `.mdx` file and an import at the top.

### Steps

```mdx
import { Steps } from '@components/steps';

<Steps>

1. Download the jar.
2. Drop it in `plugins/`.
3. Restart the server.

</Steps>
```

<Steps>

1. Download the jar.
2. Drop it in `plugins/`.
3. Restart the server.

</Steps>

### Tabs

`syncKey` keeps the same tab selected across every group on the site that shares the key.

```mdx
import { Tabs, Tab } from '@components/tabs';

<Tabs syncKey="os">
  <Tab label="Windows">Press :kbd[Ctrl+L] to move to the next pane.</Tab>
  <Tab label="macOS">Press :kbd[Cmd+L] to move to the next pane.</Tab>
</Tabs>
```

<Tabs syncKey="os">
  <Tab label="Windows">Press :kbd[Ctrl+L] to move to the next pane.</Tab>
  <Tab label="macOS">Press :kbd[Cmd+L] to move to the next pane.</Tab>
</Tabs>

### Video

Clips live in `src/assets/videos/`. They play muted and loop by default; pass `audio` for clips with sound.

```mdx
import { VideoPlayer } from '@components/video';

<VideoPlayer src="@assets/videos/examples/world-specific.webm" />
```

<VideoPlayer src="@assets/videos/examples/world-specific.webm" />

## Links and images

Link to other pages by relative file path, including the extension; the build rewrites it to the page URL. Images sit next to the page that uses them.

```md
See the [developer docs](../develop/index.mdx) and the [glossary](../glossary.mdx).

![The panel](./panel.png)
```

## Nesting directives

A directive inside another directive needs the **outer** fence to use more colons, otherwise the inner closing fence ends the outer block.

```md
::::details[With an aside inside]
:::note
Four colons outside, three inside.
:::
::::
```

::::details[With an aside inside]
:::note
Four colons outside, three inside.
:::
::::