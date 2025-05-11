<script lang="ts">
	import Check from "lucide-svelte/icons/check";
	import { cn } from "$lib/utils.js";

	export let value: string;
	export let label: string | undefined = undefined;
	export let disabled: boolean = false;
	export let selected: boolean = false;
	export let class_: string | undefined = undefined;
	
	// Rename due to class keyword conflict
	export { class_ as class };
</script>

<button
	type="button"
	class={cn(
		"relative flex w-full cursor-pointer select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none data-[disabled]:pointer-events-none data-[disabled]:opacity-50 transition-colors duration-200 hover:text-[#059EFC] hover:bg-[#2a2a30] data-[highlighted]:bg-accent dark:data-[highlighted]:bg-[#2a2a30] data-[highlighted]:text-[#059EFC]",
		selected ? "text-[#059EFC]" : "text-gray-300",
		class_
	)}
	data-state={selected ? "checked" : "unchecked"}
	data-disabled={disabled || undefined}
	role="option"
	aria-selected={selected}
	on:click
	{...$$restProps}
>
	<span class="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
		{#if selected}
			<Check class="h-4 w-4 text-[#059EFC]" />
		{/if}
	</span>
	<span class="text-left">
		<slot>
			{label || value}
		</slot>
	</span>
</button>
