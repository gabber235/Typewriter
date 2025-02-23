<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";

    interface Props {
        avatarUrl: string;
        name: string;
    }

    let { avatarUrl, name }: Props = $props();
</script>

<SidebarWidget title="Creator">
    <div class="flex items-center gap-2">
        <img src={avatarUrl} alt="Creator avatar" class="w-8 h-8 rounded-full">
        <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{name}</span>
    </div>
</SidebarWidget>