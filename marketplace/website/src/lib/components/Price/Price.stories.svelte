<script module>
	import { defineMeta } from "@storybook/addon-svelte-csf";
	import Price from "./Price.svelte";

	const { Story } = defineMeta({
		component: Price,
		tags: ["autodocs"],
		args: {
			price: 99,
			currency: "EUR"
		}
	});
</script>

<Story name="Default" />
