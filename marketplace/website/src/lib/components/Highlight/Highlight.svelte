<script lang="ts">
	import type { HTMLAttributes } from "svelte/elements";
	import type { Snippet } from "svelte";
	import { onMount } from "svelte";
	import { quintOut } from "svelte/easing";

	interface Props extends HTMLAttributes<HTMLDivElement> {
		class?: string;
		children?: Snippet;
		color?: string;
	}

	let { class: className = "", color = "#FFF176", children, ...rest }: Props = $props();
	let isVisible = $state(false);
	let element: HTMLElement;

	function markerIn(node: HTMLElement) {
		return {
			duration: 600,
			easing: quintOut,
			css: (t: number) => {
				const scale = t * 1.1;
				return `
					transform: scaleX(${scale}) scaleY(1.1) translateX(-0.5rem);
				`;
			}
		};
	}

	onMount(() => {
		let isInView = false;

		const triggerObserver = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						isVisible = true;
					}
				});
			},
			{
				threshold: 0.8,
				rootMargin: "-20% 0px -20% 0px"
			}
		);

		const visibilityObserver = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					isInView = entry.isIntersecting;
					if (!isInView) {
						isVisible = false;
					}
				});
			},
			{
				threshold: 0
			}
		);

		if (element) {
			triggerObserver.observe(element);
			visibilityObserver.observe(element);
		}

		return () => {
			if (element) {
				triggerObserver.unobserve(element);
				visibilityObserver.unobserve(element);
			}
		};
	});
</script>

<div class={`relative inline-block py-1 ${className}`} bind:this={element} {...rest}>
	<div class="relative z-10">
		{@render children?.()}
	</div>
	{#if isVisible}
		<div
			class="absolute inset-0 origin-left -translate-x-2 scale-110 rounded opacity-50"
			style="background-color: {color};"
			in:markerIn
		></div>
	{/if}
</div>
