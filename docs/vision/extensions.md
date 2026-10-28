# Extensions

## What it is

Extensions add functionality to Typewriter. They are built with **Imprint**, and code generation handles registration so developers do not write registration code by hand.

An extension can have code on both sides:

| Side | Example |
| --- | --- |
| Realm | Presentation layer: how an entry looks and is edited |
| Engine | The runtime behaviour of entries when content is created and used |

Extensions can also contribute:

- **Validators and linters** that query the content graph and report problems.
- **Expression members**: functions and properties for the formula language (see [expressions.md](expressions.md)).
- **Capability layers**: abstractions on top of engine capabilities (see [engines.md](engines.md)).
- **Assets** for resource packs, with defaults that can be overridden (see [resource-packs.md](resource-packs.md)).

### Source parts and targets

An extension is split into **source parts**. Each part targets one level:

| Target | Meaning |
| --- | --- |
| Nothing (common) | Core code, inherited by every targeted part |
| A set of capabilities | Runs on any engine that implements them |
| A specific engine type | Runs only on that engine (with a supported version range) |

At every level, a part can include or build on **other extensions** at that same target level. (Already modelled in Imprint as `ExtensionSourcePart`.)

Extensions can be published as perks on the [marketplace](marketplace.md).

## Who it serves

Extension developers first; content creators and protagonists through what extensions enable.

## Why

Typewriter's value grows with what it can do. Extensions must be easy to write, prefer capabilities over one engine where possible, and compose with each other.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Realm and engine code, generated registration | closed beta | shaped |
| Source parts targeting common, capabilities, or an engine | closed beta | shaped (exists in Imprint) |
| Validators that query the graph | closed beta | shaped (some exist) |
| Expression members from extensions | closed beta | shaped |
| Extension assets | later | sketch |

## Open questions

- Where do extensions run when a realm and engine share one host; is the realm side always present?
