<script lang="ts">
	import { Button } from "$components/ui/button";
</script>

<header class="w-full">
	<div
		class="mx-auto flex h-16 items-center justify-between px-4 md:max-w-screen-sm lg:max-w-screen-md xl:max-w-screen-xl"
	>
		<a href="/" class="flex items-center space-x-4" aria-label="Home">
			<div class="flex items-center space-x-4">
				<enhanced:img src="./typewriter-icon.png" alt="Typewriter" class="h-8 w-8" />
				<span class="hidden text-sm font-bold sm:inline-block lg:text-xl"
					>Typewriter Marketplace</span
				>
				<span class="2xs:inline-block hidden text-sm font-bold sm:hidden">Marketplace</span>
			</div>
		</a>
		<div class="flex items-center space-x-4">
			<a href="/login" class="text-sm hover:underline">Login</a>
			<Button>Sign up</Button>
		</div>
	</div>
</header>
