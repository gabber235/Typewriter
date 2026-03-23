# Project Guidelines

Astro 6 + Starlight documentation site using TypeScript, Tailwind CSS 4, and Bun.

## Validation

Run `bun check` (alias for `astro check`) to validate TypeScript and Astro files. **Never start the dev server** (`bun dev`, `bun start`, `astro dev`). Only use `bun check` for validation.

Parse check output in this format:

```bash
src/components/header/ThemeSelect.astro:191:5 - error ts(2304): Cannot find name 'StarlightThemeProvider'.

191     StarlightThemeProvider.updatePickers(theme);
        ~~~~~~~~~~~~~~~~~~~~~~
```

Format: `file:line:col - severity code: message`, followed by the source line and underline indicator.

## Code Style

- No nesting — keep code flat with early returns and guard clauses
- No comments unless the code cannot explain itself
- TypeScript strict mode — explicit types on public interfaces, infer internally
- Props via `interface Props` destructured from `Astro.props`
- Flat code > nested code. Extract early, return early

## Architecture

- Components in `src/components/<name>/` with dedicated `types.ts`, `styles.ts`, `processor.ts`, `index.ts`
- Content in `src/content/docs/` — see [src/content/AGENTS.md](src/content/AGENTS.md) for markdown rules
- Custom remark plugins handle directives (aside, badge, video)
- Starlight extended schema in `src/content.config.ts` using Zod
- Tailwind 4 with CSS variables for theming (`--material-*`, `--sl-color-*`)

## Conventions

- File naming: PascalCase for `.astro`, camelCase for `.ts`, lowercase-hyphen for `.md`
- Imports: framework first, local components second, types last
- Client JS: `<script is:inline>` for hydration-critical code, standard `<script>` otherwise
- Accessibility: semantic HTML, `aria-*` attributes, keyboard navigation
- Dark mode via Tailwind `dark:` prefix
