<script lang="ts">
    import ProductCard from "$components/ProductCard/ProductCard.svelte";

    interface Product {
        id: string;
        name: string;
        shortDescription: string;
        bannerImage: string;
        rating: number;
        price: number;
        currency: string;
        highlight: boolean;
    }

    interface Props {
        products: Product[];
    }

    let { products }: Props = $props();
</script>

<div class="min-h-screen p-8">
    <div class="max-w-7xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-12 text-gray-900 dark:text-white">
            Have a look at the most popular products
        </h1>
        <div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4">
            {#each products as product (product.name)}
                <div class="relative group max-w-[250px]">
                    <div
                            class="transform transition-all duration-300 hover:scale-[1.02] hover:shadow-xl dark:shadow-gray-800">
                        <ProductCard
                                name={product.name}
                                shortDescription={product.shortDescription}
                                bannerImage={product.bannerImage}
                                rating={product.rating}
                                price={product.price}
                                currency={product.currency}
                                highlight={product.highlight}
                        />
                    </div>
                </div>
            {/each}
        </div>
    </div>
</div>
