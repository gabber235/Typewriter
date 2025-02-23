<script lang="ts">
    interface Props {
        title: string;
    }

    let { title }: Props = $props();
</script>

<div class="rounded-lg border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-4">
    <h3 class="font-semibold mb-2 text-zinc-900 dark:text-zinc-50">{title}</h3>
    <slot />
</div>