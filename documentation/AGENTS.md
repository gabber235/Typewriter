# AGENT Instructions – Documentation

This folder contains the Docusaurus website. Documentation and blog posts are written in Markdown/MDX.

## Setup

Install dependencies once with:

```bash
npm ci
```

## Validate Changes

Before committing documentation updates make sure the site builds:

```bash
npm run test
```

## Writing Docs

- Place general docs in `docs/` and blog posts in `devlog/`.
- Keep line length under 120 characters.
- Use Markdown links with relative paths when linking between pages.
- The site is TypeScript enabled, so TS/React components can be used in `.mdx` files.

## Docs Structure

- `docs/docs/` – player-facing documentation.
- `docs/develop/` – developer guides and API docs.
- `docs/adapters/` – integration guides for optional adapters. **Never edit this folder directly.**
- Each folder, and any nested folder within it, keeps its own `assets/` directory for images and other media.

## Code Snippets

All example code lives in `extensions/_DocsExtension`. **Never place code directly in the docs.**
Wrap Kotlin samples with `//<code-block:some_tag>` and `//</code-block:some_tag>`
and use the `<CodeSnippet tag="some_tag" json={require('../snippets.json')} />`
component to embed them. This applies to every code snippet, especially pages
under `develop`.

Never write directly to the `snippets.json` file. It will be automcatically generated during the build.

## Common Components

Reusable React components live in `src/components/`. Commonly used elements are
`CodeSnippet`, `Player`, `Image`, and `EntrySearch`. For admonitions use either
the `Admonition` component or the Markdown `::note`/`::warning` syntax depending
on the context. Import these when interactive UI is required.

## Code Highlighting

Code blocks support line highlighting via Prism "magic comments" configured in
`docusaurus.config.ts`. Prefix a line with `// highlight-next-line` or wrap
multiple lines with `// highlight-start` and `// highlight-end`. Colored
variants (`-red`, `-green`, `-blue`) are also available and map to CSS classes in
`src/css/custom.css`.

