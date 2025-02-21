<script lang="ts">
	import AppBar from "$components/AppBar/AppBar.svelte";
	import SearchBar from "$components/SearchBar/SearchBar.svelte";
	import Filter from "$lib/components/Filter/Filter.svelte";
	import SearchProductListing from "$lib/components/SearchProductListing/SearchProductListing.svelte";
	import { onMount } from "svelte";
	import type { PageData } from "./$types";

	let { data }: { data: PageData } = $props();
	let isMobile = $state(false);

	onMount(() => {
		const checkWidth = () => {
			isMobile = window.innerWidth <= 639;
		};
		checkWidth();
		window.addEventListener("resize", checkWidth);
		return () => window.removeEventListener("resize", checkWidth);
	});
</script>

<div class="flex min-h-screen bg-background dark:bg-[#101013]">
	<div class="mr-1/4 flex-1">
		<header class="p-4 shadow-lg dark:shadow-none">
			<AppBar avatarUrl={data.avatarUrl} fallbackAvatar={data.fallbackAvatar} />
		</header>
		<div class="flex">
			<main
				class="text-gray-[#101013] flex flex-1 flex-col items-center justify-center py-16 dark:text-white"
			>
				<h1 class="mb-6 text-5xl font-bold">Welcome to Typewriter</h1>
				<p class="mb-12 max-w-3xl text-center text-xl">
					Explore all Typewriter products and find the perfect fit for your needs
				</p>
				<section class="flex w-full flex-col items-center">
					<div class="w-full max-w-7xl px-6">
						<SearchBar active="search" />
					</div>
				</section>
				<section
					id="ProductsSection"
					class="flex flex-col space-y-5 sm:flex-row sm:space-x-5 sm:space-y-0"
				>
					<div class={isMobile ? "w-full" : ""}>
						<Filter />
					</div>
					<div class="flex-1">
						<SearchProductListing {data} />
					</div>
				</section>
			</main>
		</div>
	</div>
</div>

