# Marketplace

## What it is

A place to publish and acquire **perks**, free or paid.

| Perk | Example |
| --- | --- |
| Extension | New entries and other functionality from a developer |
| Book | A ready made set of content. Because books have instance variables, buyers tweak values and formulas carry them through |

### Bought books are sealed by default

```
Book: Bounty board (bought)
  variables:   town, reward               buyer fills these in per instance
  public:      generated entry, functions buyer uses these
  book only:   internal entries, helpers  hidden or read only
```

- A bought book is a **sealed package**: the buyer uses its public parts and fills in its variables. Seller updates apply cleanly.
- The buyer can **unpack** it to edit the internals. An unpacked book no longer receives the seller's updates.
- Protecting a seller's internals needs a way to hide parts of a book from importers. Formulas have no visibility levels for now (see [formulas.md](formulas.md)); when the marketplace needs it, it becomes a filter on what a book exports.

### Sellers and review

- Ideally **anyone can sell**.
- Perks are **reviewed**, especially a seller's first publication, with as much **automated checking** as possible; manual review does not scale.

### What can be sold

| Perk | Note |
| --- | --- |
| Extension | Can be free with **paid parts**, unlocked through feature flags inside it |
| Book | The unit of content you sell; pages belong to books. Assets defined in the book (custom items) come with it, so resource packs are sold implicitly |
| Configuration | Possibly |

### Trust and licensing

- Extensions are third party code on someone's server, trusted the same way Minecraft plugins already are. No sandbox.
- **Signing** exists for licensing: stealing an extension cannot be fully blocked, but it should be annoying, and break again on every update.

### Updates

The Typewriter team publishes its own extensions, engines, and realms here too; everything is distributed through it (see [distribution.md](distribution.md)).

## Who it serves

Extension developers and content creators as sellers; server owners as buyers.

## Why

Reusable books and extensions are more valuable when they can be shared and sold.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Marketplace with extension and book perks | later | sketch |
| Paid perks, including paid parts behind feature flags | later | sketch |
| Bought books sealed by default, unpackable | later | shaped |
| Anyone can sell; mostly automated review | later | sketch |
| Signing for licensing, not sandboxing | later | sketch |
| Updates and rollouts through the marketplace | later | sketch |

## Open questions

- Are configurations sellable perks?
