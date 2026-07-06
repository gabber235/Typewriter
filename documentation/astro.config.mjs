// @ts-check

import starlight from "@astrojs/starlight";
import starlightDocSearch from "@astrojs/starlight-docsearch";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "astro/config";
import remarkDirective from "remark-directive";
import starlightDotMd from "starlight-dot-md";
import starlightLlmsTxt from "starlight-llms-txt";
import { BASE_PATH } from "./src/base-path";
import { remarkAside } from "./src/components/aside/remark-aside";
import { rehypeGlossary } from "./src/components/glossary/rehype-glossary";
import { rehypeBaseLinks } from "./src/plugins/rehype-base-links";

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
			routeMiddleware: "./src/route-middleware.ts",
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
			},
			plugins: [starlightLlmsTxt(), starlightDotMd()],
		}),
	],

	markdown: {
		remarkPlugins: [remarkDirective, remarkAside],
		// mode: "all" | "first-per-page" | "first-per-section"
		// "first-per-page" links each term only once per page — with a growing
		// glossary, linking every occurrence turned term-dense pages into a wall
		// of underlines.
		rehypePlugins: [
			[rehypeGlossary, { mode: "first-per-page" }],
			rehypeBaseLinks,
		],
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
