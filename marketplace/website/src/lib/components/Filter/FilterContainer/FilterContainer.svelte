<script lang="ts">
    import type { HTMLAttributes } from "svelte/elements";
    import type { Snippet } from "svelte";
    import Icon from '@iconify/svelte';
    import { slide } from 'svelte/transition';

    interface Props extends HTMLAttributes<HTMLDivElement> {
        children?: Snippet;
        name: string;
    }
    let { name = "", children }: Props = $props();
    let isCollapsed = $state(false);

    function toggleCollapse() {
        isCollapsed = !isCollapsed;
    }
</script>

<div class="rounded-lg bg-[#16181c] mb-5 p-2">
    <button class="flex justify-between items-center w-full text-left px-4 py-3 text-white" onclick={toggleCollapse} aria-expanded={!isCollapsed} type="button">
        <span class="text-2xl font-semibold">{name}</span>
        {#if isCollapsed}
            <Icon icon="material-symbols:keyboard-arrow-up-rounded" class="mr-2 text-3xl" />
        {:else}
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" class="mr-2 text-3xl" />
        {/if}
    </button>
    {#if !isCollapsed}
        <div class="mt-2 space-y-2" in:slide={{ duration: 300 }} out:slide={{ duration: 300 }}>
            {#if children && typeof children === 'function'}
                {@render children?.()}
            {/if}
        </div>
    {/if}
</div>