import containerQueries from '@tailwindcss/container-queries';
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';
import type { Config } from 'tailwindcss';

export default {
    content: ['./src/**/*.{html,js,svelte,ts}'],

    theme: {
        extend: {
            fontFamily: {
                sans: ["JetBrains Mono", 'monospace']
            },
            boxShadow: {
                'glow': '0 0 15px 0 rgba(0, 0, 0, 0.1)',
            },
            colors: {
                primary: {
                    DEFAULT: '#029FFF',
                    dark: '#7cc4ff',
                },
                card: {
                    DEFAULT: '#F3EDF7',
                    dark: '#1f1d23',
                },
            },
        }
    },

    plugins: [typography, forms, containerQueries],
    darkMode: ['variant', [
        '&:is(.dark *)',
        '&:is([data-theme="dark"] *)',
        '@media (prefers-color-scheme: dark) { &:not(.light *):not(.dark *):not([data-theme]) }',
    ]],
} satisfies Config;
