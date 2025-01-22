<script lang="ts">
	import ProductCard from "$components/ProductCard/ProductCard.svelte";
	import Highlight from "$components/Highlight/Highlight.svelte";

	interface Product {
		id: string;
		name: string;
		shortDescription: string;
		bannerImage: string;
		rating: number;
		price: number;
		currency: string;
		highlight: boolean;
		color: string;
	}

	interface Props {
		products: Product[];
		type: string;
		color: string;
		highlightColor: string;
	}

	let { products, type, color, highlightColor }: Props = $props();
</script>

<div class="min-h-screen p-8">
	<div class="mx-auto max-w-7xl">
		<h1 class="mb-12 text-center text-4xl font-bold text-gray-900 dark:text-white">
			Have a look at the <Highlight color={highlightColor}>{type}</Highlight> products
		</h1>
		<br />

		<div class="relative">
			<div
				class="absolute inset-0 m-auto h-3/5 w-4/5 bg-gradient-to-br from-transparent to-transparent blur-md"
				style={`background: linear-gradient(135deg, ${color} 0%, ${color} 100%, ${color} 100%); box-shadow: 0px 0px 450px 80px ${color}; border-radius: 20px;`}
			></div>
			<div class="grid grid-cols-1 gap-8 p-4 pb-8 pl-12 pt-8 md:grid-cols-2 lg:grid-cols-4">
				{#each products as product (product.name)}
					<div class="group relative max-w-[250px]">
						<div
							class="transform transition-all duration-300 hover:scale-[1.02] hover:shadow-xl dark:shadow-gray-800"
						>
							<ProductCard
								name={product.name}
								shortDescription={product.shortDescription}
								bannerImage={product.bannerImage}
								rating={product.rating}
								price={product.price}
								currency={product.currency}
								highlight={product.highlight}
								color={product.color}
							/>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</div>
</div>
