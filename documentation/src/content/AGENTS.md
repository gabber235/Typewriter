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
- Files use hierarchical numeric prefixes: `01-filename.md`
- Folders inside a category create sidebar groups: `guides/`, `reference/`, `training/`
- `index.md` or `index.mdx` for folder landing pages
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

- Prefer relative paths over absolute — `../guides/01-example.md` not `/guides/01-example`
- Link to other docs pages by relative file path when possible
- Use absolute paths only when relative would be unclear or overly complex

## Markdown Conventions

- **Bold** for important terms, *italic* for emphasis
- Backticks for inline code: symbols, variables, function names
- Fenced code blocks with language tags for syntax highlighting
- Ordered lists for sequential steps, unordered for features
- `---` horizontal rules to separate major sections
- Tables with alignment syntax when needed
