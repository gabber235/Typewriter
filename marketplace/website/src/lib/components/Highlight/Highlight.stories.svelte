<script module>
	import { defineMeta } from "@storybook/addon-svelte-csf";
	import Icon from "@iconify/svelte";

	import Highlight from "./Highlight.svelte";

	const { Story } = defineMeta({
		component: Highlight,
		tags: ["autodocs"],
		argTypes: {
			color: {
				control: "color",
				defaultValue: "#FFF176"
			}
		}
	});
</script>

<Story name="SimpleText">
	<Highlight>Simple highlighted text</Highlight>
</Story>

<Story name="Inline">
	<div class="flex items-center gap-2">
		Here is
		<Highlight>
			<span class="text-yellow-500">⭐</span>
			Highlighted
		</Highlight>
		with icon
	</div>
</Story>

<Story name="Colors">
	<div class="space-y-4">
		<Highlight color="#FFF176">Yellow highlight</Highlight>
		<Highlight color="#81C784">Green highlight</Highlight>
		<Highlight color="#64B5F6">Blue highlight</Highlight>
		<Highlight color="#F06292">Pink highlight</Highlight>
	</div>
</Story>

<Story name="CustomClass">
	<Highlight class="text-lg font-bold">Custom styled highlight</Highlight>
</Story>
