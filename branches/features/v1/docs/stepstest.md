---
title: Steps Test Page
description: A page to test the Steps component for sequential instructions.
editUrl: true
head: []
template: doc
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
---

import { Steps } from '@components/steps';

## Basic Steps

<Steps>

1. Install the package using your preferred package manager.

2. Import the component where you need it.

3. Add it to your page and configure the props.

</Steps>

## Steps With Rich Content

<Steps>

1. **Create the config file.**

   Add a `typewriter.config.ts` file at the root of your project:

   ```ts
   export default {
     name: "my-adventure",
   };
   ```

2. **Register your first entry.**

   Entries are the building blocks of a story.

   :::tip
   Keep entry names short and descriptive.
   :::

3. **Run the validator.**

   ```bash
   bun run validate
   ```

</Steps>

## Pagination

The Previous / Next navigation cards at the bottom of this page are rendered by the
custom `Pagination` override.