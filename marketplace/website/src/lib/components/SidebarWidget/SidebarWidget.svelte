<script lang="ts">
	import type { Snippet } from "svelte";
	interface Props {
		title: string;
		children: Snippet;
	}

	let { title, children }: Props = $props();
</script>

<div class="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-900">
	<h3 class="mb-2 font-semibold text-zinc-900 dark:text-zinc-50">{title}</h3>
	{@render children?.()}
</div>
