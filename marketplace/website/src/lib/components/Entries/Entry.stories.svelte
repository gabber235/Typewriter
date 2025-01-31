<script module>
    import { defineMeta } from "@storybook/addon-svelte-csf";
    import Entry from "./Entry.svelte";

    const { Story } = defineMeta({
        component: Entry,
        tags: ["autodocs"],
        args: {
            color: "bg-blue-500",
            icon: "ci:shuffle",
            title: "Add Ambient Sound Activity",
            description: "Play an ambient sound for an entity"
        }
    });
</script>

<Story name="Default" />