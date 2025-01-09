<script lang="ts">
	import { Button } from "$components/ui/button";
	import Rating from "$components/Rating/Rating.svelte";
	import Currency from "$components/Currency/Currency.svelte";

	interface Props {
		name: string;
		shortDescription: string;
		bannerImage: string;
		rating: number;
		price: number;
		currency: string;
	}

	let { name, shortDescription, bannerImage, rating, price, currency }: Props = $props();
</script>

<div
	class="group relative aspect-video w-full overflow-hidden rounded-lg"
	style:background-image="url({bannerImage})"
	style:background-size="cover"
	style:background-position="center"
>
	<!-- Gradient overlay -->
	<div
		class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-black/30 transition-opacity xs:to-transparent"
	></div>

	<!-- Content -->
	<div class="absolute bottom-0 flex w-full flex-col gap-2 p-6 text-white">
		<div class="flex items-center justify-between">
			<h3 class="text-lg font-bold md:text-2xl">{name}</h3>
			<div class="flex items-center gap-4">
				<span class="hidden text-lg font-semibold md:flex">
					<Currency amount={price} {currency} />
				</span>
				<div class="hidden md:flex">
					<Rating {rating} size="lg" />
				</div>
				<div class="md:hidden">
					<Rating {rating} size="sm" />
				</div>
			</div>
		</div>
		<div class="flex items-center justify-between space-x-2">
			<p class="line-clamp-2 text-xs text-gray-200 md:text-sm">{shortDescription}</p>
			<Button variant="secondary" size="sm" class="hidden md:flex">View</Button>
		</div>
	</div>
</div>
