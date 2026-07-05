import { defineCollection } from "astro:content";
import { docsLoader } from "@astrojs/starlight/loaders";
import { docsSchema } from "@astrojs/starlight/schema";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { badgeSchema } from "./components/badge";

export const collections = {
	docs: defineCollection({
		loader: docsLoader(),
		schema: docsSchema({
			extend: z.object({
				/** Badge variant: new, experimental, or deprecated */
				badge: badgeSchema,
				/** Set to false to disable glossary term linking on this page */
				glossary: z.boolean().optional(),
			}),
		}),
	}),
	glossary: defineCollection({
		loader: glob({ pattern: "**/*.{md,mdx}", base: "./src/content/glossary" }),
		schema: z.object({
			/** Display name shown in the hover card and on the glossary page */
			title: z.string(),
			/** Word forms that get linked in docs pages, matched case-insensitively */
			aliases: z.array(z.string()).min(1),
			/** Optional target the term links to instead of the glossary page */
			link: z.string().optional(),
		}),
	}),
};
