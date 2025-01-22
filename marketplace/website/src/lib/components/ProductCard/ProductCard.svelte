<script lang="ts">
	import Rating from "$components/Rating/Rating.svelte";
	import Currency from "$components/Currency/Currency.svelte";
	interface Props {
		name: string;
		shortDescription: string;
		bannerImage: string;
		rating: number;
		price: number;
		currency: string;
		highlight: boolean;
		color: string
	}

	let { name, shortDescription, bannerImage, rating, price, currency, highlight, color }: Props = $props();
</script>

<div
	class="max-w-xs rounded-lg p-1 shadow-green-500 overflow-hidden bg-background dark:bg-[#101013]"
	class:shadow-glow={highlight}
	style="outline: 2px solid {color};"
>
	<img class="h-[128px] w-full rounded-md object-cover" src={bannerImage} alt="" />
	<div class="flex flex-col justify-between h-[calc(322px-128px)] p-4">
		<div>
			<span class="text-xl font-bold line-clamp-1 text-gray-950 dark:text-white">{name}</span>
			<p class="text-sm leading-tight text-gray-500 dark:text-gray-300 line-clamp-5">
				{shortDescription}
			</p>
		</div>
		<div class="mt-2 flex items-center justify-between">
			<span class="dark:text-white text-sm font-semibold text-primary">
				<Currency amount={price} {currency} />
			</span>
			<span class="text-sm">
				<Rating {rating} />
			</span>
		</div>
	</div>
</div>
