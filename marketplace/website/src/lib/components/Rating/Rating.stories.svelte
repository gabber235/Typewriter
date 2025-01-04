<script module>
	import { defineMeta } from "@storybook/addon-svelte-csf";

	import Rating from "./Rating.svelte";

	const { Story } = defineMeta({
		component: Rating,
		tags: ["autodocs"]
	});
</script>

<Story name="ZeroLarge" args={{ rating: 0, size: 'lg' }} />
<Story name="ThreeLarge" args={{ rating: 3, size: 'lg' }} />
<Story name="FiveLarge" args={{ rating: 5, size: 'lg' }} />

<Story name="Zero" args={{ rating: 0 }} />
<Story name="Three" args={{ rating: 3 }} />
<Story name="Five" args={{ rating: 5 }} />

<Story name="Small" args={{ rating: 3.5, size: 'sm' }} />
