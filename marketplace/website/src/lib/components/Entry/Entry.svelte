<script lang="ts">
	import Icon from "@iconify/svelte";
	export let color = "";
	export let icon = "";
	export let title = "";
	export let description = "";
</script>

<div class="mt-2 flex items-center rounded-lg bg-[#171719] text-lg text-[#e6e0e9] min-w-fit">
	<div 
		class="mr-2 flex items-center justify-center rounded p-4" 
		style="background-color: {color};"
	>
		<Icon 
			{icon} 
			color="#171719" 
			class="text-2xl" 
		/>
	</div>
	<div class="p-2">
		<div class="select-none text-base font-medium">
			{title}
		</div>
		<div class="select-none text-sm text-[#e6e0e9]">
			{description}
		</div>
	</div>
</div>
