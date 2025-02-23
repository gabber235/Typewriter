<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";
    import { Calendar } from "lucide-svelte";

    interface Props {
        publishDate: string;
        updateDate: string;
    }

    let { publishDate, updateDate }: Props = $props();
</script>

<SidebarWidget title="Dates">
    <div class="space-y-3">
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <Calendar class="w-4 h-4" /> Published
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{publishDate}</span>
        </div>
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <Calendar class="w-4 h-4" /> Updated
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{updateDate}</span>
        </div>
    </div>
</SidebarWidget>