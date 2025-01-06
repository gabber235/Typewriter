import '../src/app.css';
import { withThemeByClassName } from '@storybook/addon-themes';

/** @type { import('@storybook/svelte').Preview } */
const preview = {
    parameters: {
        backgrounds: {
            disable: true,
        },
        controls: {
            matchers: {
                color: /(background|color)$/i,
                date: /Date$/i,
            },
        },
    },
    decorators: [
        withThemeByClassName({
            themes: {
                light: 'light',
                dark: 'dark',
            },
            defaultTheme: 'light',
        }),
    ],
};

export default preview;
