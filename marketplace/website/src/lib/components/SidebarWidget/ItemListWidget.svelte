<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";

    interface Props {
        title: string;
        items: string[];
    }

    let { title, items }: Props = $props();
</script>

<SidebarWidget title={title}>
    <div class="space-y-4">
        {#if items.length > 0}
            <div class="flex flex-wrap gap-2">
                {#each items as item}
                    <span class="px-2 py-1 text-sm rounded-md bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300">
                        {item}
                    </span>
                {/each}
            </div>
        {/if}
    </div>
</SidebarWidget>