import '../src/app.css';
import { withThemeByClassName } from '@storybook/addon-themes';
import { INITIAL_VIEWPORTS } from '@storybook/addon-viewport';

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
        viewport: {
            viewports: {
                ...INITIAL_VIEWPORTS,
                pc: {
                    name: 'PC',
                    styles: {
                        width: '100%',
                        height: '100%',
                    },
                    type: 'desktop',
                    default: true,
                }
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
