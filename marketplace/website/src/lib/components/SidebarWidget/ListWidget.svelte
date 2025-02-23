<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";

    interface Props {
        title: string;
        items: string[];
        subtitle?: string;
        itemClassName?: string;
    }

    let { title, items, subtitle = "", itemClassName = "text-xs" }: Props = $props();
</script>

<SidebarWidget {title}>
    <div class="space-y-2">
        {#if subtitle}
            <div class="text-sm text-zinc-700 dark:text-zinc-300">{subtitle}</div>
        {/if}
        <div class="flex flex-wrap gap-1">
            {#each items as item}
                <span class="px-2 py-1 bg-zinc-100 dark:bg-zinc-800 rounded {itemClassName} text-zinc-700 dark:text-zinc-300">{item}</span>
            {/each}
        </div>
    </div>
</SidebarWidget>