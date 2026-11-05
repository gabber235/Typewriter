# Configurations

## What it is

Configurations replace the legacy **snippet system**. A configuration is a full **root resource type** of its own, next to content like books and entries.

- Configurations are **typed**: each has its own configuration data type. Example: a dialogue configuration.
- **Extensions** define configuration types; creators create configurations of those types. Creators never define configuration types.
- Configurations are **not global settings**. They are for an extension's features: shared settings that, for example, all entries of one type use by default and can override individually. A configuration type is an ordinary record type, like other resource types.
- For a value creators want to share across their own content, they use a **book variable** instead.
- An entry can hold a **configuration reference**, tying it to a specific configuration.
- Each configuration type has a **default**: the configuration selected on the realm root. With none selected, the extension's own defaults apply.
- Related configuration types use **composition, not inheritance**. Example: a spoken dialogue entry uses both the dialogue configuration (text speed) and the spoken dialogue configuration (voice volume). Each type owns its own settings, and both apply.

### Overrides

| Override | Meaning |
| --- | --- |
| Content tree | The realm, a book, or a page selects a configuration; everything inside uses it unless overridden lower down (like priority). Every level adds up, so each value comes from the nearest level that sets it |
| Per entry | An entry overrides single values directly |
| Formulas | Configuration values can be formulas, so they can differ per protagonist |

```
spoken dialogue entry
  uses dialogue configuration          text speed = 2
  uses spoken dialogue configuration   voice volume = 80

each configuration type:
  default        selected on the realm
  selected one   chosen by entry reference, or inherited from book or page
  overrides      per entry values, formulas
```

## Who it serves

Content creators (consistent settings in one place, overridable where needed), extension developers (declare typed settings for their features).

## Why

Most creators do not think about configurations while writing, so the entry editor keeps them out of the way: one quiet row, opening to a picker per type, then each value with where it comes from.

Snippets were loose text values. Typed, overridable configurations with defaults are better in every way.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Configurations replace snippets | closed beta | shaped |
| Typed configuration data, default variant | closed beta | shaped |
| Entry configuration references | closed beta | shaped |
| Composition of related types, not inheritance | closed beta | shaped |
| Overrides through content tree, entries, formulas | closed beta | shaped |
| Configuration types defined by extensions | closed beta | shaped |

## Open questions

- None yet.
