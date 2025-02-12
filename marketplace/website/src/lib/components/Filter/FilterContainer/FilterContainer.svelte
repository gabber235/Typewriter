<script lang="ts">
    import type { HTMLAttributes } from "svelte/elements";
    import type { Snippet } from "svelte";
    import Icon from "@iconify/svelte";
    import { slide } from "svelte/transition";

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

<div class="mb-5 rounded-[12px] bg-[#16181c] p-1">
    <button
            class="flex w-full items-center justify-between px-4 pl-5 py-2 text-left text-white"
            onclick={toggleCollapse}
            aria-expanded={!isCollapsed}
            type="button"
    >
        <span class="text-xl text-gray-300 font-semibold">{name}</span>
        <Icon icon="material-symbols:keyboard-arrow-down-rounded" class={`mr-2 text-3xl transition-transform duration-300 ${isCollapsed ? 'rotate-180' : ''}`} />
    </button>
    {#if !isCollapsed}
        <div class="mt-2 space-y-2" in:slide={{ duration: 300 }} out:slide={{ duration: 300 }}>
            {#if children && typeof children === "function"}
                {@render children?.()}
            {/if}
        </div>
    {/if}
</div>