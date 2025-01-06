<script lang="ts">
	interface Props {
		amount: number;
		currency: string;
	}

	let { amount, currency }: Props = $props();
	let locale = navigator.language;
	let price = $derived.by(() =>
		new Intl.NumberFormat(locale, {
			style: "currency",
			currency
		}).format(amount)
	);
</script>

<span>{price}</span>
