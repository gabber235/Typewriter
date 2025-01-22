<script lang="ts">
	import AppBar from "$components/AppBar/AppBar.svelte";
	import ProductCarousel from "$components/ProductCarousel/ProductCarousel.svelte";

	import type { PageData } from "./$types";
	import SearchBar from "$components/SearchBar/SearchBar.svelte";
	import ProductOverview from "$components/ProductOverview/ProductOverview.svelte";

	let { data }: { data: PageData } = $props();
</script>

<div class="min-h-screen bg-background dark:bg-[#101013]">
	<header class="p-4 shadow-lg dark:shadow-none">
		<AppBar avatarUrl={data.avatarUrl} fallbackAvatar={data.fallbackAvatar} />
	</header>
	<main class="text-gray-[#101013] flex flex-col items-center justify-center py-16 dark:text-white">
		<h1 class="mb-6 text-5xl font-bold">Welcome to Typewriter</h1>
		<p class="mb-12 max-w-3xl text-center text-xl">
			Explore all Typewriter products and find the perfect fit for your needs
		</p>
		<section class="flex w-full flex-col items-center">
			<div class="w-full max-w-7xl px-6">
				<SearchBar />
				<h2 class="mb-4 text-3xl font-semibold">Featured Products</h2>
			</div>
			<ProductCarousel products={data.products} />
		</section>
	</main>
	<ProductOverview
		products={data.mostPopularProducts}
		type="popular"
		color="#5579D444"
		highlightColor="#5579D4"
	/>
	<ProductOverview
		products={data.trendingProducts}
		type="trending"
		color="#D4555544"
		highlightColor="#D45555"
	/>
	<ProductOverview
		products={data.newestProducts}
		type="newest"
		color="#55D46244"
		highlightColor="#55D462"
	/>
</div>

