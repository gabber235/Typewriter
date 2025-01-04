<script lang="ts">
	import Icon from "@iconify/svelte";

	interface Props {
		/** Can be a double from 0 to 5. */
		rating: number;
		/** Size of the rating. */
		size?: "sm" | "md" | "lg";
	}

	let { size = "md", rating }: Props = $props();
</script>

{#if size === 'sm'}
	<div class="inline-flex items-center space-x-1">
		<span class="text-xs text-gray-500">
			{rating.toFixed(1)}
		</span>
		<Icon icon="material-symbols:star-rounded" class="text-yellow-500 text-base" />
	</div>
{:else}
	<div class="flex items-center" class:text-xl={size === 'lg'}>
		{#each Array(5) as _, index}
			{#if rating >= index + 1}
				<Icon icon="material-symbols:star-rounded" class="text-yellow-500" />
			{:else}
				<Icon icon="material-symbols:star-rounded" class="text-gray-300" />
			{/if}
		{/each}
	</div>
{/if}