<script lang="ts">
	import { createEventDispatcher } from "svelte";
	import * as Select from "$lib/components/ui/select";
	import MultiSelectItem from "./multi-select-item.svelte";

	export let options: { value: string; label: string }[] = [];
	export let selected: string[] = [];
	export let placeholder: string = "";
	export let showAnyOption: boolean = true;
	export let class_: string | undefined = undefined;
	export let menuClass: string | undefined = undefined;
	export let anyOptionLabel: string = "Any";
	export let multiSelectedFormat: (count: number) => string = (count) => `${count} selected`;

	// Rename due to class keyword conflict
	export { class_ as class };

	const dispatch = createEventDispatcher();

	// Function to stop propagation to keep dropdown open when selecting items
	function stopPropagation(event: Event) {
		event.stopPropagation();
	}

	// Toggle selection of an item
	function toggleItem(value: string) {
		const isSelected = selected.includes(value);
		let newSelected = [...selected];

		if (isSelected) {
			newSelected = newSelected.filter(v => v !== value);
		} else {
			newSelected = [...newSelected, value];
		}

		selected = newSelected;
		dispatch('change', { selected });
	}

	// Clear all selections when "Any" is clicked
	function clearSelections() {
		selected = [];
		dispatch('change', { selected });
	}

	// Get the display text for the trigger
	$: triggerText = selected.length === 0 
		? placeholder 
		: selected.length === 1 
			? options.find(o => o.value === selected[0])?.label || "" 
			: multiSelectedFormat(selected.length);
</script>

<div class={class_}>
	<div class="select-wrapper">
		<button 
			class="flex w-full justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
			type="button"
			aria-haspopup="listbox"
			aria-expanded="false"
			on:click|stopPropagation={(e) => {
				const el = e.currentTarget;
				const content = el.nextElementSibling;
				if (content) {
					content.classList.toggle('hidden');
					el.setAttribute('aria-expanded', content.classList.contains('hidden') ? 'false' : 'true');
				}
			}}
		>
			<span class={selected.length === 0 ? "text-slate-500" : ""}>
				{triggerText}
			</span>
			<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 opacity-50"><path d="m6 9 6 6 6-6"></path></svg>
		</button>
		<div 
			class="hidden absolute z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md bg-background dark:bg-[#222328] text-foreground dark:text-white"
			role="listbox"
			on:click|stopPropagation
		>
			{#if showAnyOption && selected.length > 0}
				<MultiSelectItem 
					value="any" 
					label={anyOptionLabel} 
					class="font-medium" 
					on:click={(e) => {
						e.stopPropagation();
						clearSelections();
					}}
				/>
			{/if}
			{#each options as option}
				<MultiSelectItem 
					value={option.value} 
					label={option.label}
					selected={selected.includes(option.value)}
					on:click={(e) => {
						e.stopPropagation();
						toggleItem(option.value);
					}}
				>
					{option.label}
				</MultiSelectItem>
			{/each}
		</div>
	</div>
</div>

<style>
	.select-wrapper {
		position: relative;
		width: 100%;
	}
	
	button {
		display: flex;
		justify-content: space-between;
		align-items: center;
		width: 100%;
		background: #222328;
		border: 1px solid #2e2e33;
		border-radius: 0.375rem;
		padding: 0.5rem 0.75rem;
		font-size: 0.875rem;
		height: 40px;
		transition: border-color 0.2s, box-shadow 0.2s;
		color: #E0E0E0;
	}
	
	button:focus {
		outline: none;
		border-color: #059EFC;
		box-shadow: 0 0 0 2px rgba(5, 158, 252, 0.2);
	}
	
	button[aria-expanded="true"] {
		border-color: #059EFC;
	}
	
	div[role="listbox"] {
		position: absolute;
		z-index: 50;
		min-width: 100%;
		margin-top: 0.25rem;
		overflow: hidden;
		background: #222328;
		border: 1px solid #2e2e33;
		border-radius: 0.375rem;
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3), 0 2px 4px -1px rgba(0, 0, 0, 0.2);
	}
</style>
