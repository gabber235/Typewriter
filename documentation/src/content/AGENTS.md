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

- Files in `src/content/docs/` with hierarchical numeric prefixes: `01-filename.md`
- Folders create categories: `guides/`, `reference/`, `training/`
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
