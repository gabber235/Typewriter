<script lang="ts">
	import Autoplay from "embla-carousel-autoplay";
	import { WheelGesturesPlugin } from "embla-carousel-wheel-gestures";
	import ClassNames from "embla-carousel-class-names";
	import * as Carousel from "$components/ui/carousel";
	import CarouselCard from "$components/CarouselCard/CarouselCard.svelte";

	interface Product {
		id: string;
		name: string;
		shortDescription: string;
		bannerImage: string;
		rating: number;
		price: number;
		currency: string;
	}

	interface Props {
		products: Product[];
	}

	let { products }: Props = $props();

	const autoPlay = Autoplay({ delay: 4000 });
	const wheel = WheelGesturesPlugin();
	const classNames = ClassNames({});
</script>

<div class="w-full">
	<Carousel.Root
		opts={{
			align: "center",
			containScroll: "trimSnaps",
			dragFree: false,
			loop: true
		}}
		plugins={[autoPlay, wheel, classNames]}
		onmouseenter={() => autoPlay.stop()}
		onmouseleave={() => autoPlay.play()}
	>
		<Carousel.Content class="-mx-4 w-full">
			{#each products as product (product.id)}
				<Carousel.Item
					class="basis-[80%] px-2 opacity-40 transition-opacity duration-300 md:basis-[70%] lg:basis-[60%]"
				>
					<CarouselCard
						name={product.name}
						shortDescription={product.shortDescription}
						bannerImage={product.bannerImage}
						rating={product.rating}
						price={product.price}
						currency={product.currency}
					/>
				</Carousel.Item>
			{/each}
		</Carousel.Content>
	</Carousel.Root>
</div>

<style>
	:global(.is-snapped) {
		opacity: 1 !important;
	}
</style>
