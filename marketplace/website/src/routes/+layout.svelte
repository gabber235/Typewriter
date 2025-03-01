<script lang="ts">
	import { dev } from "$app/environment";
	import "../app.css";
	import AppBar from "$components/AppBar/AppBar.svelte";
	import DevModeBanner from "$components/DevModeBanner/DevModeBanner.svelte";
	import { ModeWatcher } from "mode-watcher";
	let { children, data } = $props();
	let avatarUrl = data.user?.picture ?? null; // Makes the types correct.
	let fallbackAvatar = data.user?.username ?? null;
</script>

<ModeWatcher />
<div class="min-h-screen bg-background dark:bg-[#101013]">
	{#if dev}
		<DevModeBanner />
	{/if}
	<AppBar {avatarUrl} {fallbackAvatar} />

	{@render children()}
</div>
