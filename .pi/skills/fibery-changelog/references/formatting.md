# Changelog Formatting Reference

## Discord heading typography (`:mx:`)

Each alphabetic character becomes `:m{letter}:` (letter directly after `m`). Adjacent letters join with `::`. Words separate with a space. Digits stay plain.

Examples:
- `major` → `:mm::ma::mj::mo::mr:`
- `features` → `:mf::me::ma::mt::mu::mr::me::ms:`
- `bug fixes` → `:mb::mu::mg: :mf::mi::mx::me::ms:`

### `toDiscordHeading` helper

```ts
function toDiscordHeading(text: string): string {
  return text
    .toLowerCase()
    .split(/\s+/)
    .map((word) =>
      [...word]
        .filter((ch) => /[a-z]/.test(ch))
        .map((ch) => `:m${ch}:`)
        .join("::"),
    )
    .join(" ");
}
```

Apply to every heading, including H1. Never use raw `# Beta 174` for Discord-bound output.

## Document structure and order

1. **Features first** (always the primary section).
2. **Bugs second** (beta releases only; omitted entirely for full releases).

Do **not** group features or bugs under generic importance or priority headings like `### Major` or `### Critical`. Importance and priority only control depth of write-up and inclusion, not section headers.

## Feature inclusion by release type

| Importance | Beta release | Full release |
|---|---|---|
| Major | Own `#` heading (discord-font **descriptive title**, a few words summarizing the feature) + paragraph explaining the change | Own `#` heading (descriptive title) + extensive multi-paragraph explanation |
| Notable | Own `#` heading (descriptive title) + paragraph | Single bullet + short explanation (no separate heading) |
| Minor | Single shared `# :mf::me::ma::mt::mu::mr::me::ms:` heading; each minor item is a bullet + one-line explanation beneath it | **Omit** |
| Internal | **Omit** | **Omit** |

**Descriptive titles:** the heading for each Major or Notable feature must be a short, human changelog title distilled from the Fibery item (not the literal importance label "Major" or "Notable").

Process Major and Notable features in importance order (Major before Notable). List all Minor features together under the shared `:mf::me::ma::mt::mu::mr::me::ms:` heading.

## Bug inclusion

| Release type | Bugs |
|---|---|
| Beta | Include **all** linked bugs, sorted Critical → High → Normal → Low |
| Full | **Never include bugs** (tool may still return them; skill omits the entire bugs section) |

**Format:** bugs are **always bullet points only** (never headings, never paragraphs), regardless of priority.

Beta bugs section: a single discord-font section heading (e.g. `:mb::mu::mg: :mf::mi::mx::me::ms:`) followed by bullets ordered by priority. Each bullet: short title + one-line explanation.

## Punctuation rule

**Never use dashes as punctuation** in changelog text (no em dash, en dash, or hyphen as a separator). Use a colon and space instead.

Good: `- **Panel labels**: Sidebar labels are easier to scan.`
Bad: `- **Panel labels** — Sidebar labels are easier to scan.`

## Description distillation

Fibery bug descriptions use Expected behavior, Actual behavior, Impact, Scope. Feature descriptions use Capability now possible, Problem today, Why this matters, and similar sections. The skill should:
- Lead with what changed for the user.
- Pull from Impact, Capability, or Problem sections.
- Strip implementation detail and internal process language.
- Distill a concise descriptive heading (few words) for Major and Notable features.

## Example output skeleton (`docs/changelog.md`)

```markdown
# :ms::mt::ma::mt::me::mf::mu::ml: :me::mn::mt::mi::mt::mi::me::ms:
NPC activities now persist across interruptions like dialogue, so pathing and similar behaviors resume instead of restarting.

# :me::mx::mt::me::mn::md: :mp::mo::ms::me: :md::ma::mt::ma:
Sitting poses can now be applied to non-player entities.

# :mf::me::ma::mt::mu::mr::me::ms:
- **Panel labels**: Sidebar labels are easier to scan.

## :mb::mu::mg: :mf::mi::mx::me::ms:
- **Quest tracker double refresh**: Quest status no longer re-evaluates redundantly when facts change.
- **Command help typo**: Help text now matches the actual command name.
```
