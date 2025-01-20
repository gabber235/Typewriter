<script lang="ts">
    import AppBar from "$components/AppBar/AppBar.svelte";
    import ProductCarousel from "$components/ProductCarousel/ProductCarousel.svelte";

    import type { PageData } from './$types';

    let { data }: { data: PageData } = $props();

</script>

<AppBar avatarUrl={data.avatarUrl} fallbackAvatar={data.fallbackAvatar} />
<ProductCarousel products={data.products} />
