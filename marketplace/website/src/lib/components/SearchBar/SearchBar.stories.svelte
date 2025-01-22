<script module>
    import { defineMeta } from "@storybook/addon-svelte-csf";
    import SearchBar from "./SearchBar.svelte";

    const { Story } = defineMeta({
        component: SearchBar,
        tags: ["autodocs"],
        args: {}
    });
</script>

<Story name="Logged Out" parameters={{ viewport: { defaultViewport: "pc" } }} />
<Story name="Logged Out - Galaxy S5" parameters={{ viewport: { defaultViewport: "galaxys5" } }} />
<Story
        name="Logged Out - iPhone14 PM"
        parameters={{ viewport: { defaultViewport: "iphone14promax" } }}
/>
<Story name="Logged Out - iPad" parameters={{ viewport: { defaultViewport: "ipad" } }} />

<Story
        name="Logged In"
        args={{
	}}
/>
