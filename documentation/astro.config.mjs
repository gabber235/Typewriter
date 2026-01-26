// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: "Typewriter",
      logo: {
        src: "/public/logo.png",
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
      },
    }),
  ],

  vite: {
    plugins: [tailwindcss()],
  },
});
