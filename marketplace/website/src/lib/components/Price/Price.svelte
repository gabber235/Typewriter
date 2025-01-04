<script lang="ts">
	import Currency from "$lib/components/Currency/Currency.svelte";

	interface Props {
		price: number;
		currency: string;
	}

	let { currency, price }: Props = $props();
</script>

<div class="flex items-center justify-center p-4 bg-gray-100 rounded-lg shadow text-lg font-semibold text-gray-700">
	<Currency amount={price} currency={currency} />
</div>
