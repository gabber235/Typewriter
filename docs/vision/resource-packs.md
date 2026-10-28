# Resource packs

## What it is

Support for custom assets through Minecraft resource packs.

### Assets

- Assets are defined **inside books**: a creator uploads a custom item in the book that uses it.
- Extensions register **asset handlers** in the pack pipeline. Given a file, a handler transforms it (for example into a texture) and stores associated data about it.
- Asset kinds: textures, fonts, custom items, custom blocks, shaders.
- Extensions can ship **their own assets** so they work out of the box, with a way to override them. Examples from the basic extension: a pumpkin head texture for blinding, a shader for cinematic black bars, an animated custom font.

### Packs

- A resource pack is a **root level resource**, like configurations, tags, and books.
- Several books can assign their assets to **one pack**; their assets are merged into it.
- **Separate packs always load separately**, stacked, never merged. Reason: one pack can get very large, so splitting lets packs load or not depending on other factors.
- A pack can **reference other packs** and inherit from them.
- A book can require a pack without using its assets. Example: "load this pack while in this region". If a loaded pack already includes it through inheritance, it stays loaded; otherwise it is loaded.
- A book's content is only available when its pack is loaded; books apply conditionally (see [content-model.md](content-model.md)).
- **Other plugins' packs** (ItemsAdder, Oraxen) are left alone: newer Minecraft versions let a server send several packs, and Typewriter takes its own slot or slots.

### Serving packs

Not decided. **Not the engine**, since there are several. Options:

| Option | Note |
| --- | --- |
| The realm | Owners would need to port forward |
| Typewriter Cloud as a reverse proxy | Maybe free, maybe not |
| A CDN such as Cloudflare | If bandwidth is very cheap, possibly a premium offering |

### Wanted later

Overlays, custom GUIs, shader effects. **Canvas pages** come with this work (see [content-model.md](content-model.md)).

## Who it serves

Extension developers (bundled assets), content creators (richer visuals), protagonists.

## Why

Many rich interactions need custom visuals, and they should plug into Typewriter like everything else.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Asset handlers in a pack pipeline | later | sketch |
| Assets defined inside books | later | shaped |
| Packs as root resources; merged within, stacked between, inheritance | later | shaped |
| Own pack slots next to other plugins' packs | later | shaped |
| Conditional loading (book conditions, regions) | later | shaped |
| Extension assets with overrides | later | sketch |
| Serving: realm, cloud proxy, or CDN | later | open |
| Overlays, custom GUIs, shaders | later | wish |

## Open questions

- Who serves packs to protagonists: the realm, a cloud reverse proxy, or a CDN?
