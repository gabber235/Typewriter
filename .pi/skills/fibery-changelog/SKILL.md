---
name: fibery-changelog
description: Generate Discord-ready changelogs from Fibery beta or milestone data. Use when the user asks for changelog, release notes, beta announcement, or /fibery-changelog.
metadata:
  short-description: Fibery to docs/changelog.md
---

# Fibery Changelog

Generate `docs/changelog.md` from Fibery beta or milestone items.

## When to use

- User asks to write or generate a changelog, beta announcement, or release notes from Fibery.
- User runs `/fibery-changelog` or `/fibery-changelog beta` or `/fibery-changelog full`.

## Workflow

1. If `releaseType` is missing, use `ask_user`: beta vs full.
2. Call `fibery_get_changelog_items` with the chosen `releaseType`.
3. If the tool returns `{ error: "..." }`, ask the user for `targetIdentifier` (beta) or `targetName` (milestone) and retry.
4. Read formatting rules in `references/formatting.md` in this skill directory.
5. Distill user-facing prose from Fibery descriptions. Do not paste intake templates verbatim.
6. Write `docs/changelog.md` at the repo root (create `docs/` if needed).
7. Summarize what was included and omitted.

## Output rules (summary)

- Features first, bugs second (beta only).
- Use `:mx:` discord-font headings for all headings. See `references/formatting.md` for `toDiscordHeading`.
- Major and Notable features get descriptive discord-font titles (not bland labels like "Major").
- Minor features share one `# :mf::me::ma::mt::mu::mr::me::ms:` section with bullets.
- Internal features: omit.
- Beta bugs: all linked bugs as bullets only, sorted Critical to Low, under one bugs section heading.
- Full release: never include bugs.
- Never use dashes as punctuation in written changelog text. Use colons instead.

## Tool

```
fibery_get_changelog_items({
  releaseType: "beta" | "full",
  targetIdentifier?: number,   // beta only, e.g. 174
  targetName?: string,         // full only, e.g. "Interim (0.9)"
  includeDescriptions?: true
})
```
