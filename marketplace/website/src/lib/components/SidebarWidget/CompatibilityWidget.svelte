<script lang="ts">
    import ListWidget from "./ListWidget.svelte";

    interface Props {
        gameEdition: string;
        versions: string[];
    }

    let { gameEdition, versions }: Props = $props();
</script>

<ListWidget
    title="Compatibility"
    items={versions}
    subtitle={gameEdition}
/>