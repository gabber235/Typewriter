// @ts-check

import starlight from "@astrojs/starlight";
import starlightDocSearch from "@astrojs/starlight-docsearch";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "astro/config";
import remarkDirective from "remark-directive";
import starlightDotMd from "starlight-dot-md";
import starlightLlmsTxt from "starlight-llms-txt";
import { remarkAside } from "./src/components/aside/remark-aside";

// https://astro.build/config
export default defineConfig({
	site: "https://docs.typewritermc.com",
	base: process.env.DOCS_BASE_PATH || "/",
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
						href: "/favicon-96x96.png",
						sizes: "96x96",
					},
				},
				{
					tag: "link",
					attrs: { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" },
				},
				{
					tag: "link",
					attrs: {
						rel: "apple-touch-icon",
						sizes: "180x180",
						href: "/apple-touch-icon.png",
					},
				},
				{
					tag: "meta",
					attrs: { name: "apple-mobile-web-app-title", content: "Typewriter" },
				},
				{
					tag: "link",
					attrs: { rel: "manifest", href: "/site.webmanifest" },
				},
			],
			social: [
				{
					icon: "github",
					label: "GitHub",
					href: "https://github.com/Gabber235/typewriter",
				},
			],
			customCss: ["./src/styles/global.css"],
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			components: {
				Head: "./src/components/Head.astro",
				Sidebar: "./src/components/sidebar/Sidebar.astro",
				PageFrame: "./src/components/pageframe/PageFrame.astro",
				Header: "./src/components/header/Header.astro",
				SiteTitle: "./src/components/header/SiteTitle.astro",
				ThemeSelect: "./src/components/header/ThemeSelect.astro",
				PageSidebar: "./src/components/pagesidebar/PageSidebar.astro",
				Pagination: "./src/components/pagination/Pagination.astro",
			},
			plugins: [starlightLlmsTxt(), starlightDotMd()],
		}),
	],

	markdown: {
		remarkPlugins: [remarkDirective, remarkAside],
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
