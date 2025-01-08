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
	}

	let { name, shortDescription, bannerImage, rating, price, currency, highlight }: Props = $props();
</script>

<div
	class="max-w-xs rounded-lg bg-card p-1 shadow-green-500 outline outline-2 outline-green-500"
	class:shadow-glow={highlight}
>
	<img class="max-h-48 rounded-md object-cover" src={bannerImage} alt="" />

	<div class="flex flex-col justify-center p-4">
		<span class="text-xl font-bold">{name}</span>
		<p class="text-sm leading-tight text-gray-500 dark:text-gray-300">{shortDescription}</p>
		<div class="mt-2 flex items-center justify-between">
			<span class="dark:text-primary-dark text-sm font-semibold text-primary">
				<Currency amount={price} {currency} />
			</span>
			<span class="text-sm">
				<Rating {rating} />
			</span>
		</div>
	</div>
</div>
