<script lang="ts">
	import Rating from "$components/Rating/Rating.svelte";
	interface Props {
		bannerImage: string;
	}

	let { bannerImage }: Props = $props();
</script>

<div class="max-w-xs rounded-lg bg-white outline outline-3 outline-green-500 p-1">
		<img
			class="rounded-md"
			src={bannerImage}
			alt=""
		/>

	<div class="flex flex-col justify-between p-2">
		<Rating rating={3.5} />
	</div>
</div>
