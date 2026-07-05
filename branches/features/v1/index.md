---
title: Welcome to Starlight
description: Get started building your docs site with Starlight.
editUrl: true
head: []
template: splash
hero:
  tagline: Congrats on setting up a new Starlight project!
  image:
    alt: ""
    file:
      src: /branches/features/v1/_astro/houston.CZZyCf7p.webp
      width: 800
      height: 800
      format: webp
  actions:
    - text: Example Guide
      link: guides/
      variant: primary
      icon:
        type: icon
        name: right-arrow
    - text: Read the Starlight docs
      link: https://starlight.astro.build
      variant: minimal
      icon:
        type: icon
        name: external
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
---

import { Card, CardGrid } from '@astrojs/starlight/components';

## Next steps

<CardGrid stagger>
	<Card title="Update content" icon="pencil">
		Edit `src/content/docs/index.mdx` to see this page change.
	</Card>
	<Card title="Change page layout" icon="document">
		Delete `template: splash` in `src/content/docs/index.mdx` to display a
		sidebar on this page.
	</Card>
	<Card title="Add new content" icon="add-document">
		Add Markdown or MDX files to `src/content/docs` to create new pages.
	</Card>
	<Card title="Configure your site" icon="setting">
		Edit your `sidebar` and other config in `astro.config.mjs`.
	</Card>
	<Card title="Read the docs" icon="open-book">
		Learn more in [the Starlight Docs](https://starlight.astro.build/).
	</Card>
</CardGrid>