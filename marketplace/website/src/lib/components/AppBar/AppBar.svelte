<script lang="ts">
	import Icon from "@iconify/svelte";
	import { Button } from "$components/ui/button";
	import * as Avatar from "$components/ui/avatar";
	import * as DropdownMenu from "$components/ui/dropdown-menu";

	interface Props {
		avatarUrl: string | null;
		fallbackAvatar: string | null;
	}

	const { avatarUrl, fallbackAvatar }: Props = $props();
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
				<span class="hidden text-sm font-bold 2xs:inline-block sm:hidden">Marketplace</span>
			</div>
		</a>
		{#if avatarUrl}
			<DropdownMenu.Root>
				<DropdownMenu.Trigger>
					<Avatar.Root>
						<Avatar.Image src={avatarUrl} alt="avatar" />
						{#if fallbackAvatar}
							<Avatar.Fallback>{fallbackAvatar}</Avatar.Fallback>
						{/if}
					</Avatar.Root>
				</DropdownMenu.Trigger>
				<DropdownMenu.Content class="w-56">
					<DropdownMenu.Group>
						<DropdownMenu.Item>
							<Icon icon="ph:files-fill" class="mr-2 h-4 w-4" />
							<span>Projects</span>
						</DropdownMenu.Item>
						<DropdownMenu.Item>
							<Icon icon="material-symbols:dashboard-rounded" class="mr-2 h-4 w-4" />
							<span>Panel</span>
							<DropdownMenu.Shortcut>
								<Icon icon="pajamas:external-link" class="ml-2 h-3 w-3" />
							</DropdownMenu.Shortcut>
						</DropdownMenu.Item>
						<DropdownMenu.Item>
							<Icon icon="material-symbols:person-2-rounded" class="mr-2 h-4 w-4" />
							<span>Profile</span>
							<DropdownMenu.Shortcut>
								<Icon icon="pajamas:external-link" class="ml-2 h-3 w-3" />
							</DropdownMenu.Shortcut>
						</DropdownMenu.Item>
					</DropdownMenu.Group>
					<DropdownMenu.Separator />
					<DropdownMenu.Group>
						<DropdownMenu.Item
							class="text-red-500 data-[highlighted]:bg-red-100 data-[highlighted]:text-red-500 dark:data-[highlighted]:bg-red-500 dark:data-[highlighted]:text-white"
						>
							<Icon icon="material-symbols:logout-rounded" class="mr-2 h-4 w-4" />
							<span>Logout</span>
						</DropdownMenu.Item>
					</DropdownMenu.Group>
				</DropdownMenu.Content>
			</DropdownMenu.Root>
		{:else}
			<div class="flex items-center space-x-4">
				<a href="/login" class="text-sm hover:underline">Login</a>
				<Button>Sign up</Button>
			</div>
		{/if}
	</div>
</header>
