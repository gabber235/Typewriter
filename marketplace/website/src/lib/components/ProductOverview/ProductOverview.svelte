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
        color: string
    }

    interface Props {
        products: Product[];
        type: string;
        color: string;
    }

    let { products, type, color }: Props = $props();
</script>

<div class="min-h-screen p-8">
    <div class="max-w-7xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-12 text-gray-900 dark:text-white">
            Have a look at the {type} products
        </h1>
        <br>

        <div class="relative">
            <div
                    class="absolute inset-0 m-auto h-3/5 w-4/5 bg-gradient-to-br from-transparent to-transparent blur-md"
                    style={`background: linear-gradient(135deg, ${color} 0%, ${color} 100%, ${color} 100%); box-shadow: 0px 0px 450px 80px ${color}; border-radius: 20px;`}
            > </div>
            <div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4 p-4 pt-8 pb-8 pl-12">
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
                                    color={product.color}
                            />
                        </div>
                    </div>
                {/each}
            </div>
        </div>
    </div>
</div>
