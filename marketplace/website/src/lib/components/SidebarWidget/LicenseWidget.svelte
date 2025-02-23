<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";
    import { FileText } from "lucide-svelte";

    interface Props {
        type: string;
    }

    let { type }: Props = $props();
</script>

<SidebarWidget title="License">
    <div class="flex items-center justify-between">
        <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
            <FileText class="w-4 h-4" /> Type
        </span>
        <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{type}</span>
    </div>
</SidebarWidget>