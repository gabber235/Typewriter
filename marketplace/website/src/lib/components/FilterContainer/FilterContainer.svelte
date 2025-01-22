<script lang="ts">
    import type { HTMLAttributes } from "svelte/elements";
    import type { Snippet } from "svelte";

    interface Props extends HTMLAttributes<HTMLDivElement> {
        children?: Snippet;
        name: string;
    }
    let { name = "", children }: Props = $props();

</script>

<div>
    <h3 class="text-sm font-semibold">{name}</h3>
    <div class="mt-2 space-y-2">
        {@render children?.()}
    </div>
</div>