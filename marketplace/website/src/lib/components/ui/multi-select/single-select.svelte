<script lang="ts">
	import { createEventDispatcher } from "svelte";
	import SingleSelectItem from "./single-select-item.svelte";

	export let options: { value: string; label: string }[] = [];
	export let value: string = "";
	export let placeholder: string = "";
	export let class_: string | undefined = undefined;
	export let menuClass: string | undefined = undefined;

	// Rename due to class keyword conflict
	export { class_ as class };

	const dispatch = createEventDispatcher();

	// Function to stop propagation to keep dropdown open when selecting items
	function stopPropagation(event: Event) {
		event.stopPropagation();
	}

	// Select an item
	function selectItem(itemValue: string) {
		value = itemValue;
		dispatch('change', { value });
		
		// Close dropdown
		const button = document.activeElement as HTMLElement;
		if (button && button.tagName === 'BUTTON') {
			button.blur();
		}
		
		const wrapper = document.querySelector('.select-wrapper-single') as HTMLElement;
		if (wrapper) {
			const content = wrapper.querySelector('[role="listbox"]') as HTMLElement;
			const triggerButton = wrapper.querySelector('button') as HTMLElement;
			if (content && triggerButton) {
				content.classList.add('hidden');
				triggerButton.setAttribute('aria-expanded', 'false');
			}
		}
	}

	// Get the display text for the trigger
	$: triggerText = value === "" 
		? placeholder 
		: options.find(o => o.value === value)?.label || placeholder;
</script>

<div class={class_}>
	<div class="select-wrapper-single">
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
			<span class={value === "" ? "text-slate-500" : ""}>
				{triggerText}
			</span>
			<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 opacity-50"><path d="m6 9 6 6 6-6"></path></svg>
		</button>
		<div 
			class="hidden absolute z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md bg-background dark:bg-[#222328] text-foreground dark:text-white"
			role="listbox"
			on:click|stopPropagation
		>
			{#each options as option}
				<SingleSelectItem 
					value={option.value} 
					label={option.label}
					selected={value === option.value}
					on:click={(e) => {
						e.stopPropagation();
						selectItem(option.value);
					}}
				>
					{option.label}
				</SingleSelectItem>
			{/each}
		</div>
	</div>
</div>

<style>
	.select-wrapper-single {
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
