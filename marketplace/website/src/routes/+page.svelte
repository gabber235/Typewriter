<script lang="ts">
    import AppBar from "$components/AppBar/AppBar.svelte";
    import ProductCarousel from "$components/ProductCarousel/ProductCarousel.svelte";

    import type { PageData } from './$types';
    import SearchBar from "$components/SearchBar/SearchBar.svelte";
    import ProductOverview from "$components/ProductOverview/ProductOverview.svelte";

    let { data }: { data: PageData } = $props();

</script>

<div class="min-h-screen bg-background dark:bg-[#101013]">
    <header class="p-4 shadow-lg dark:shadow-none">
        <AppBar avatarUrl={data.avatarUrl} fallbackAvatar={data.fallbackAvatar} />
    </header>
    <main class="flex flex-col items-center justify-center py-16 text-gray-[#101013] dark:text-white">
        <h1 class="text-5xl font-bold mb-6">Welcome to Typewriter</h1>
        <p class="text-xl mb-12 text-center max-w-3xl">
            Explore all Typewriter products and find the perfect fit for your needs
        </p>
        <section class="w-full flex flex-col items-center">
            <div class="max-w-7xl w-full px-6">
                <SearchBar />
                <h2 class="text-3xl font-semibold mb-4">Featured Products</h2>
            </div>
            <ProductCarousel products={data.products} />
        </section>
    </main>
    <ProductOverview products={data.mostPopularProducts} type="most popular" color="#5579D444" />
    <ProductOverview products={data.trendingProducts} type="trending" color="#D4555544" />
    <ProductOverview products={data.newestProducts} type="newest" color="#55D46244" />
</div>