<script lang="ts">
	import Icon from '@iconify/svelte';
	export let checked: boolean = false;
	export let label: string = "";
	export let icon: string = "";
</script>

<style>
	/* Remove the existing CSS as we will use Tailwind CSS */
</style>

<button
		type="button"
		class="flex items-center p-2 rounded-lg cursor-pointer transition-colors w-64 text-gray-300 font-weight-500 hover:text-white"
		class:bg-transparent={!checked}
		class:bg-twblue="{checked}"
		class:text-white="{checked}"
		on:click={() => checked = !checked}
		aria-pressed={checked}
>
	{#if icon}
		<Icon icon={icon} class="mr-2" />
	{/if}
	<span>{label}</span>
</button>