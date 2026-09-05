# Content Guidelines

Markdown and MDX content for the Starlight documentation site.

## Frontmatter

Every page requires `title` and `description`. Optional fields below.

```yaml
---
title: Page Title
description: Brief description for SEO and previews
badge: new              # optional: new | experimental | deprecated
---
```

## File Organization

- Two top-level categories under `src/content/docs/`, each with its own sidebar (scoped by `src/lib/route-middleware.ts`, configured in `src/lib/categories.ts`):
  - `docs/` — Documentation (user-facing), served at `/docs/...`
  - `develop/` — Develop (developer-facing), served at `/develop/...`
- Every new page goes inside a category folder; only `index.mdx` (splash home) and `glossary.mdx` stay at the collection root
- Files use hierarchical numeric prefixes: `01-filename.md`; the prefix stays in the URL (`/docs/01-syntax/`)
- Folders inside a category create sidebar groups. Every folder needs an `index.md` or `index.mdx`: its `title` is the sidebar group label, otherwise the group is named after its first page
- The site currently holds only landing pages plus `docs/01-syntax.mdx`, the single-page reference and live demo of every authoring feature. Read it before writing new pages
- Source material for facts lives in the 0.9.0 docs (`O:\Typewriter Project\develop\documentation\docs\`); verify behaviour against the 1.0 engine and extensions before stating it, and flag unverified 1.0 changes with `:::experimental`
- Videos live in `src/assets/videos/<section>/` and are embedded with `<VideoPlayer src="@assets/videos/..." />` from `.mdx`; images sit next to the page that uses them
- Use `.mdx` only when importing components, `.md` otherwise

## Heading Rules

- Never use H1 (`#`) — the page title comes from frontmatter
- Start content headings at H2 (`##`)
- Follow heading hierarchy: H2 → H3 → H4, never skip levels

## Aside Directives

Use `remark-directive` syntax for callouts:

```markdown
:::info
Default title derived from variant name.
:::

:::warning[Custom Title]
Content with a custom title.
:::
```

Available variants: `info`, `warning`, `danger`, `success`, `tip`, `note`, `example`, `experimental`, `deprecated`, `bug`, `performance`

Nesting rule for every container directive: a directive placed inside another one needs the **outer** fence to use more colons (`::::details` outside, `:::info` inside), otherwise the inner closing fence ends the outer block.

## Inline Directives

Each component folder under `src/components/` has a README with the full details.

| Syntax | Renders |
|---|---|
| `:kbd[Ctrl+S]`, `:kbd[Ctrl+K, Ctrl+P]` | Keycaps. `+` joins a combo, `,` separates chords. Names like `cmd`, `shift`, `enter`, `up` get symbols. |
| `:cmd[/tw reload]` | Command chip that copies itself on click. `:cmd[/tw help]{nocopy}` renders it without the copy button. |
| `:var[latest]` | Value from `src/content/variables.yml`, replaced as plain text. Also works inside link and image URLs: `[Discord](:var[discord])`. Unknown names render a visible `⚠ var:name` marker and warn at build time. |
| `==text==` | `<mark>` highlight. Plain text only, delimiters must hug the text. |
| `:term[entries]`, `:term[a page's building blocks]{as=entry}` | Glossary link with a hover card. The label is matched against the aliases in `src/content/glossary/*.mdx`; `as=` names the entry when the wording differs. Unknown terms render as plain text and warn at build time. |

## Glossary

Glossary terms are never linked automatically. Mark the first meaningful occurrence of a term on a page with `:term[...]` and leave later mentions plain, so pages don't turn into walls of underlines. Add a term by creating `src/content/glossary/<slug>.mdx` with `title`, `aliases` (every word form that may appear in `:term[]`) and an optional `link` that replaces the glossary-page target.

## Block Directives

| Syntax | Renders |
|---|---|
| `:::details[Label]{open}` … `:::` | Native collapsible with an animated chevron. `{id=anchor}` sets an id. |
| `:::tldr` or `:::tldr[Custom label]` … `:::` | Compact summary box for the top of long pages. |
| `:::spoiler[Title]{reason="…" button="…" hide="…" variant=warning}` … `:::` | Gated section: content is blurred behind a card explaining why it is hidden, with a reveal button. Variants `warning`, `danger`, `info`, `neutral`; `{open}` starts revealed. Links to headings inside a closed spoiler open it automatically. Use `::::spoiler` when it contains asides or code fences with directives. |
| `:::wizard[Title]{persist}` + nested list … `:::` | Click-through decision tree. A single top-level item is the root question, its nested items are answers; `Answer → Follow-up question` items nest further, leaf items are results. `{persist}` remembers the path per session. |
| `:::hotspots[Caption]` + `![alt](./image.png)` + ordered list … `:::` | Annotated screenshot. Each list item starts with `[x%, y%]` and becomes a numbered pin; pins open a popover with the item's text. The legend list is screen-reader-only and only shows visibly when the image fails to load, scripting is off, or the image is too narrow. `{numbers=false}` for dot pins, `{legend=visible}` to always show the legend. |
| `:::compare[Before\|After]{start=50 orientation=horizontal hover}` + two images … `:::` | Before/after image slider. Both images must share the same dimensions. |
| ```` ```log ```` fenced block | Minecraft server log viewer: level colours, line numbers, stack-trace styling. Meta options: `title="latest.log"`, `{3}` line marks, `collapse-traces`, `highlight="Typewriter"`, `wrap`. |

Images referenced from `hotspots` and `compare` go through Astro's image pipeline like any markdown image, so keep them next to the page and use relative paths.

## MDX Components

Import Astro components only in `.mdx` files:

```mdx
import Aside from '@components/aside/Aside.astro';

<Aside type="info" title="Custom Title">
  Content here
</Aside>
```

Wrap a numbered list in `Steps` for sequential instructions:

```mdx
import { Steps } from '@components/steps';

<Steps>

1. First step.
2. Second step.

</Steps>
```

Previous/Next navigation cards at the bottom of every page are rendered automatically by the `Pagination` override — no authoring needed.

## Links

- Prefer relative file paths over absolute URLs — `../04-concepts/index.md` not `/docs/04-concepts/`
- Link to other docs pages by relative file path (`.md`/`.mdx`, `#hash` allowed); `src/plugins/remark-md-links.ts` rewrites them to the rendered page URL at build time, so the link works in the browser and survives base-path deploys
- Use absolute paths only when relative would be unclear or overly complex

## Markdown Conventions

- **Bold** for important terms, *italic* for emphasis
- Backticks for inline code: symbols, variables, function names
- Fenced code blocks with language tags for syntax highlighting
- Ordered lists for sequential steps, unordered for features
- `---` horizontal rules to separate major sections
- Tables with alignment syntax when needed
