<script module>
	import { defineMeta } from "@storybook/addon-svelte-csf";

	import ProductCard from "./ProductCard.svelte";

	const { Story } = defineMeta({
		component: ProductCard,
		tags: ["autodocs"],
		args: {
			name: "BasicExtension",
			shortDescription: "For all the most basic entries",
			currency: "EUR",
			price: 10,
			bannerImage:
				"https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg",
			rating: 4,
			highlight: false,
            color: "green"
		}
	});
</script>

<Story name="Default" />

