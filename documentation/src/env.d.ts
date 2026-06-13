/// <reference path="../.astro/types.d.ts" />

// The custom `Search.astro` and `SiteTitle.astro` overrides are copies of
// Starlight's built-ins and import Starlight's *internal* virtual modules
// (`virtual:starlight/user-images`, `virtual:starlight/pagefind-config`, ...).
// Those declarations live in a file Starlight doesn't export, so pull it into
// the project's type graph here to keep `astro check` happy.
/// <reference path="../node_modules/@astrojs/starlight/virtual-internal.d.ts" />
