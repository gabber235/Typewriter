#!/bin/sh

# Start the Svelte dev server in the background
npm run dev -- --host 0.0.0.0 &


# Start Storybook
BROWSER=true npm run storybook
