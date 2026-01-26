// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

import tailwindcss from "@tailwindcss/vite";
import starlightDocSearch from "@astrojs/starlight-docsearch";

// https://astro.build/config
export default defineConfig({
  prefetch: {
    prefetchAll: true,
    defaultStrategy: 'hover',
  },
  experimental: {
    clientPrerender: true,
    svgo: true,
  },
  integrations: [
    starlight({
      title: "Typewriter",
      logo: {
        src: "./src/assets/logo.png",
        alt: "Typewriter Logo",
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/Gabber235/typewriter",
        },
      ],
      customCss: ["./src/styles/global.css"],
      components: {
        Sidebar: "./src/components/sidebar/Sidebar.astro",
        PageFrame: "./src/components/pageframe/PageFrame.astro",
        Header: "./src/components/header/Header.astro",
        SiteTitle: "./src/components/header/SiteTitle.astro",
        ThemeSelect: "./src/components/header/ThemeSelect.astro",
      },
    }),
  ],

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
