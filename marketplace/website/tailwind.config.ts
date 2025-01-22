import type { Config } from "tailwindcss";
import containerQueries from '@tailwindcss/container-queries';
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';
import tailwindcssAnimate from "tailwindcss-animate";

const config: Config = {
    content: ["./src/**/*.{html,js,svelte,ts}"],
    safelist: [
        "dark",
    ],
    theme: {
        container: {
            center: true,
            padding: "2rem",
            screens: {
                "2xs": "320px",
                "xs": "480px",
                "2xl": "1400px"
            }
        },
        extend: {
            screens: {
                "2xs": "370px",
                "xs": "480px",
                "2xl": "1400px"
            },
            colors: {
                twblue: "#059EFC",
                twaccent: "#4BB962",
                kerzinatoryellow: "#E7B21B",
                border: "hsl(var(--border) / <alpha-value>)",
                input: "hsl(var(--input) / <alpha-value>)",
                ring: "hsl(var(--ring) / <alpha-value>)",
                background: "hsl(var(--background) / <alpha-value>)",
                foreground: "hsl(var(--foreground) / <alpha-value>)",
                primary: {
                    DEFAULT: "hsl(var(--primary) / <alpha-value>)",
                    foreground: "hsl(var(--primary-foreground) / <alpha-value>)"
                },
                secondary: {
                    DEFAULT: "hsl(var(--secondary) / <alpha-value>)",
                    foreground: "hsl(var(--secondary-foreground) / <alpha-value>)"
                },
                destructive: {
                    DEFAULT: "hsl(var(--destructive) / <alpha-value>)",
                    foreground: "hsl(var(--destructive-foreground) / <alpha-value>)"
                },
                muted: {
                    DEFAULT: "hsl(var(--muted) / <alpha-value>)",
                    foreground: "hsl(var(--muted-foreground) / <alpha-value>)"
                },
                accent: {
                    DEFAULT: "hsl(var(--accent) / <alpha-value>)",
                    foreground: "hsl(var(--accent-foreground) / <alpha-value>)"
                },
                popover: {
                    DEFAULT: "hsl(var(--popover) / <alpha-value>)",
                    foreground: "hsl(var(--popover-foreground) / <alpha-value>)"
                },
                card: {
                    DEFAULT: "hsl(var(--card) / <alpha-value>)",
                    foreground: "hsl(var(--card-foreground) / <alpha-value>)"
                },
                sidebar: {
                    DEFAULT: "hsl(var(--sidebar-background))",
                    foreground: "hsl(var(--sidebar-foreground))",
                    primary: "hsl(var(--sidebar-primary))",
                    "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
                    accent: "hsl(var(--sidebar-accent))",
                    "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
                    border: "hsl(var(--sidebar-border))",
                    ring: "hsl(var(--sidebar-ring))",
                },
            },
            borderRadius: {
                xl: "calc(var(--radius) + 4px)",
                lg: "var(--radius)",
                md: "calc(var(--radius) - 2px)",
                sm: "calc(var(--radius) - 4px)"
            },
            boxShadow: {
                'glow': '0 0 15px 0 rgba(0, 0, 0, 0.1)',
            },
            fontFamily: {
                sans: ["JetBrains Mono", 'monospace']
            },
            keyframes: {
                "accordion-down": {
                    from: { height: "0" },
                    to: { height: "var(--bits-accordion-content-height)" },
                },
                "accordion-up": {
                    from: { height: "var(--bits-accordion-content-height)" },
                    to: { height: "0" },
                },
                "caret-blink": {
                    "0%,70%,100%": { opacity: "1" },
                    "20%,50%": { opacity: "0" },
                },
            },
            animation: {
                "accordion-down": "accordion-down 0.2s ease-out",
                "accordion-up": "accordion-up 0.2s ease-out",
                "caret-blink": "caret-blink 1.25s ease-out infinite",
            },
        },
    },
    plugins: [typography, forms, containerQueries, tailwindcssAnimate],
    darkMode: ['variant', [
        '&:is(.dark *)',
        '&:is([data-theme="dark"] *)',
        '@media (prefers-color-scheme: dark) { &:not(.light *):not(.dark *):not([data-theme]) }',
    ]],
};

export default config;
