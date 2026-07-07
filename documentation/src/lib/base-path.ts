// Mirrors the `base` passed to `defineConfig()` in astro.config.mjs, but
// usable from plain Node context (astro.config.mjs itself, remark/rehype
// plugins) where `import.meta.env.BASE_URL` isn't available. Always ends
// with exactly one trailing slash, matching Astro's own normalization.
export const BASE_PATH = (process.env.DOCS_BASE_PATH || "/").replace(
	/\/?$/,
	"/",
);
