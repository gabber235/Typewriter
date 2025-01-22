<script lang="ts">
	import type { HTMLInputAttributes } from "svelte/elements";
	import type { WithElementRef } from "bits-ui";
	import { cn } from "$lib/utils.js";

	let {
		ref = $bindable(null),
		value = $bindable(),
		placeholder,
		class: className,
		...restProps
	}: WithElementRef<HTMLInputAttributes> & { placeholder?: string } = $props();
</script>

<input
	bind:this={ref}
	class={cn(
		"border-input bg-background dark:bg-[#222328] ring-offset-background dark:ring-offset-dark-background placeholder:text-muted-foreground dark:placeholder:text-muted-dark-foreground focus-visible:ring-ring focus-visible:ring-[#059EFC] dark:focus-visible:ring-[#059EFC] flex h-10 w-full rounded-md border px-3 py-2 text-base file:border-0 file:bg-transparent file:text-sm file:font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm max-w-[630px]",
		className
	)}
	bind:value
	placeholder={placeholder}
	{...restProps}
/>