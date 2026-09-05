import type { Sponsor } from "./types";

/**
 * Current public GitHub sponsors (github.com/sponsors/gabber235, read
 * 2026-09-05). `featured` marks the $10+/month tiers, the same cut-off the
 * README's sponsors workflow uses (`minimum: 1000`).
 */
export const sponsors: Sponsor[] = [
	{ login: "myiume", name: "Myiume", featured: true },
	{ login: "iamyellowhead", name: "yellowhead", featured: true },
	{ login: "RenaudRl", name: "BTC STUDIO", featured: true },
	{ login: "ItsJustJar", name: "ItsJustJar", featured: true },
	{ login: "GuavaDealer", name: "GuavaDealer", featured: true },
	{ login: "artie-mortus", name: "artie-mortus", featured: true },
	{ login: "Chaosgh", name: "Chaosgh" },
	{ login: "Junkehh", name: "Junkeh" },
	{ login: "vadim-soude", name: "Vadim Soudé" },
	{ login: "rafael5gr2", name: "Rafael Fotakidis" },
	{ login: "Hinogo2210", name: "John Law" },
	{ login: "atcpybd", name: "Champpy" },
	{ login: "Tanerx", name: "Taner" },
	{ login: "lilZoey", name: "Zoey" },
];

/** Sponsors who chose not to be listed publicly; counted, never shown. */
export const PRIVATE_SPONSORS = 1;
