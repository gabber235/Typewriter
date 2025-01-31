<script>
	import Icon from "@iconify/svelte";
	export let color = "";
	export let icon = "";
	export let title = "";
	export let description = "";
</script>

<div
	class={`mt-2 flex w-96 cursor-pointer items-center rounded-lg bg-[#171719] text-lg text-[#e6e0e9]`}
>
	<div class="mr-2 flex items-center justify-center rounded p-4 {color}">
		<Icon {icon} color="#171719" className={`text-2xl`} />
	</div>
	<div class="flex-grow">
		<div class={`select-none text-[16px] font-medium`}>
			Add {title}
		</div>
		<div class="select-none text-sm text-[#e6e0e9]">
			{description}
		</div>
	</div>
	<span class={`select-none pr-5 text-2xl`}>+</span>
</div>
