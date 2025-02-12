<script lang="ts">
	import Icon from "@iconify/svelte";
	export let checked: boolean = false;
	export let label: string = "";
	export let icon: string = "";
</script>

<button
	type="button"
	class="font-weight-500 flex w-64 cursor-pointer items-center rounded-lg p-2 text-gray-300 transition-colors hover:text-white"
	class:bg-transparent={!checked}
	class:bg-twblue={checked}
	class:text-white={checked}
	on:click={() => (checked = !checked)}
	aria-pressed={checked}
>
	{#if icon}
		<Icon {icon} class="mr-2" />
	{/if}
	<span>{label}</span>
</button>

<style>
	/* Remove the existing CSS as we will use Tailwind CSS */
</style>
