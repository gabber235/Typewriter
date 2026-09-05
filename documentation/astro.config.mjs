// @ts-check

import { unified } from "@astrojs/markdown-remark";
import starlight from "@astrojs/starlight";
import starlightDocSearch from "@astrojs/starlight-docsearch";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "astro/config";
import remarkDirective from "remark-directive";
import starlightDotMd from "starlight-dot-md";
import starlightLlmsTxt from "starlight-llms-txt";
import { remarkAside } from "./src/components/aside/remark-aside";
import { remarkCmd } from "./src/components/cmd/remark-cmd";
import { remarkCompare } from "./src/components/compare/remark-compare";
import { remarkDetails } from "./src/components/details/remark-details";
import { remarkTerm } from "./src/components/glossary/remark-term";
import { remarkHighlight } from "./src/components/highlight/remark-highlight";
import { remarkHotspots } from "./src/components/hotspots/remark-hotspots";
import { remarkKbd } from "./src/components/kbd/remark-kbd";
import { ecLog } from "./src/components/log/ec-log";
import { remarkSpoiler } from "./src/components/spoiler/remark-spoiler";
import { remarkTldr } from "./src/components/tldr/remark-tldr";
import { remarkVariables } from "./src/components/variables/remark-variables";
import { remarkWizard } from "./src/components/wizard/remark-wizard";
import { BASE_PATH } from "./src/lib/base-path";
import { EDIT_BASE_URL } from "./src/lib/edit-url";
import { rehypeBaseLinks } from "./src/plugins/rehype-base-links";
import { remarkMdLinks } from "./src/plugins/remark-md-links";

// https://astro.build/config
export default defineConfig({
	site: "https://docs.typewritermc.com",
	base: BASE_PATH,
	output: "static",
	prefetch: {
		prefetchAll: true,
		defaultStrategy: "viewport",
	},
	integrations: [
		starlight({
			title: "Typewriter",
			// A dedicated `src/pages/404.astro` (via `<StarlightPage>`) replaces the
			// injected route; keeping both would race the same content collection
			// entry through `[...slug]` and log a route-priority warning at build.
			disable404Route: true,
			logo: {
				src: "./src/assets/logo.png",
				alt: "Typewriter Logo",
			},
			favicon: "/favicon.ico",
			head: [
				{
					tag: "link",
					attrs: {
						rel: "icon",
						type: "image/png",
						href: `${BASE_PATH}favicon-96x96.png`,
						sizes: "96x96",
					},
				},
				{
					tag: "link",
					attrs: {
						rel: "icon",
						type: "image/svg+xml",
						href: `${BASE_PATH}favicon.svg`,
					},
				},
				{
					tag: "link",
					attrs: {
						rel: "apple-touch-icon",
						sizes: "180x180",
						href: `${BASE_PATH}apple-touch-icon.png`,
					},
				},
				{
					tag: "meta",
					attrs: { name: "apple-mobile-web-app-title", content: "Typewriter" },
				},
				{
					tag: "link",
					attrs: { rel: "manifest", href: `${BASE_PATH}site.webmanifest` },
				},
			],
			social: [
				{
					icon: "github",
					label: "GitHub",
					href: "https://github.com/Gabber235/typewriter",
				},
			],
			customCss: ["./src/styles/global.css", "./src/styles/home.css"],
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			// Git-derived; the deploy workflow checks out with fetch-depth: 0 so
			// the full history is available in CI.
			lastUpdated: true,
			editLink: {
				baseUrl: EDIT_BASE_URL,
			},
			routeMiddleware: "./src/lib/route-middleware.ts",
			components: {
				Head: "./src/components/Head.astro",
				Sidebar: "./src/components/sidebar/Sidebar.astro",
				PageFrame: "./src/components/pageframe/PageFrame.astro",
				Header: "./src/components/header/Header.astro",
				SiteTitle: "./src/components/header/SiteTitle.astro",
				ThemeSelect: "./src/components/header/ThemeSelect.astro",
				PageSidebar: "./src/components/pagesidebar/PageSidebar.astro",
				Pagination: "./src/components/pagination/Pagination.astro",
				PageTitle: "./src/components/pagetitle/PageTitle.astro",
				ContentPanel: "./src/components/contentpanel/ContentPanel.astro",
				Footer: "./src/components/footer/Footer.astro",
			},
			plugins: [starlightLlmsTxt(), starlightDotMd()],
			expressiveCode: {
				plugins: [ecLog()],
			},
		}),
	],

	markdown: {
		// `markdown.remarkPlugins`/`rehypePlugins` are deprecated in favour of
		// configuring the unified processor directly (Astro now defaults to a
		// different, non-unified processor that doesn't run these plugins).
		processor: unified({
			// Order matters: remarkDirective parses `:x[]` / `::x` / `:::x` syntax,
			// remarkVariables resolves `:var[]` before the other directives see it.
			remarkPlugins: [
				remarkDirective,
				remarkVariables,
				remarkMdLinks,
				remarkTerm,
				remarkAside,
				remarkKbd,
				remarkCmd,
				remarkHighlight,
				remarkDetails,
				remarkTldr,
				remarkSpoiler,
				remarkWizard,
				remarkHotspots,
				remarkCompare,
			],
			rehypePlugins: [rehypeBaseLinks],
		}),
	},

	vite: {
		plugins: [
			tailwindcss(),
			starlightDocSearch({
				appId: "GE6F02MN59",
				apiKey: "57ae467d6c3f66ac2cae2c98e4275f49",
				indexName: "typewriter",
			}),
		],
	},
});
