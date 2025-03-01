<script module>
	import { defineMeta } from "@storybook/addon-svelte-csf";

	import DevModeBaner from "./DevModeBanner.svelte";

	const { Story } = defineMeta({
		component: DevModeBaner,
		tags: ["autodocs"],
		argTypes: {}
	});
</script>

<Story name="Development Banner">
	<DevModeBaner />
</Story>
