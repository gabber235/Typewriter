<script lang="ts">
    import ProductCard from "$components/ProductCard/ProductCard.svelte";

    export let data;
</script>

<div class="flex justify-center">
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 gap-4">
        {#each data.products as product}
            <ProductCard {...product} />
        {/each}
    </div>
</div>