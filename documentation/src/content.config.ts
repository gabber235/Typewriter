import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';
import { badgeSchema } from './components/badge';

export const collections = {
	docs: defineCollection({
		loader: docsLoader(),
		schema: docsSchema({
			extend: z.object({
				/** Badge variant: new, experimental, or deprecated */
				badge: badgeSchema,
			}),
		}),
	}),
};
