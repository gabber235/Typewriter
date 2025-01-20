<script lang="ts">
    import { browser } from "$app/environment";

	interface Props {
		amount: number;
		currency: string;
	}

	let { amount, currency }: Props = $props();
	let locale = browser ? navigator.language : "en-US";
	let price = $derived.by(() =>
		new Intl.NumberFormat(locale, {
			style: "currency",
			currency
		}).format(amount)
	);
</script>

<span>{price}</span>
