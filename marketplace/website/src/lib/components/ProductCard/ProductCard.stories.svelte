<script module>
	import { defineMeta } from '@storybook/addon-svelte-csf';

	import ProductCard from './ProductCard.svelte';

	const { Story } = defineMeta({
		component: ProductCard,
		tags: ['autodocs'],
		args: {
			bannerImage: 'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg',
		}
	});
</script>

<Story name="Default" />