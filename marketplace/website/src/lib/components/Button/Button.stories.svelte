<script module>
    import { defineMeta } from '@storybook/addon-svelte-csf';

    import Button from './Button.svelte';

    const { Story } = defineMeta({
        component: Button,
        tags: ['autodocs'],
        argTypes: {
            text: {
                control: { type: 'text' },
            },
            variant: {
                options: ['primary', 'secondary', 'accent', 'danger'],
                control: { type: 'select' },
            },
        },
        args: {
            text: 'Click me',
            variant: 'primary',
        },
    });
</script>

<Story name="Default" />
