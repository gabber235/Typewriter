import * as path from 'node:path';
import { defineConfig } from '@rspress/core';
import { pluginAlgolia } from '@rspress/plugin-algolia';
import readingTime from 'rspress-plugin-reading-time';

export default defineConfig({
  root: path.join(__dirname, 'docs'),
  title: 'My Site',
  icon: '/rspress-icon.png',
  logo: {
    light: '/rspress-light-logo.png',
    dark: '/rspress-dark-logo.png',
  },
  multiVersion: {
    default: 'v1.0.0',
    versions: ['v1.0.0'],
  },
  llms: true,
  plugins: [pluginAlgolia(), readingTime()],
  themeConfig: {
    llmsUI: {
      viewOptions: ['markdownLink'],
    },
    socialLinks: [
      {
        icon: 'github',
        mode: 'link',
        content: 'https://github.com/web-infra-dev/rspress',
      },
    ],
  },
});
