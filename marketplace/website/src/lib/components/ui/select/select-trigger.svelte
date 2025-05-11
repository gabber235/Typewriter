<script lang="ts">
	import { Select as SelectPrimitive } from "bits-ui";
	import ChevronDown from "lucide-svelte/icons/chevron-down";
	import { cn } from "$lib/utils.js";

	type $$Props = SelectPrimitive.TriggerProps;
	type $$Events = SelectPrimitive.TriggerEvents;

	let className: $$Props["class"] = undefined;
	export { className as class };
</script>

<SelectPrimitive.Trigger
	class={cn(
		"w-full rounded-md bg-background dark:bg-[#222328] px-3 py-2 text-base dark:text-white border border-input focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#059EFC] focus-visible:ring-offset-2 transition-all duration-300 appearance-none cursor-pointer flex items-center justify-between h-10",
		className
	)}
	{...$$restProps}
	let:builder
	on:click
	on:keydown
>
	<slot {builder} />
	<div class="pointer-events-none text-[#666666] transition-colors ml-2">
		<ChevronDown class="h-5 w-5" />
	</div>
</SelectPrimitive.Trigger>
