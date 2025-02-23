<script lang="ts">
    import SidebarWidget from "./SidebarWidget.svelte";
    import {Download, File, Heart, ShoppingCart, Star} from "lucide-svelte";

    interface Props {
        views: number;
        downloads: number;
        rating: number;
        fileSize: string;
        isPaid: boolean;
    }

    let { views, downloads, rating, fileSize, isPaid }: Props = $props();
</script>

<SidebarWidget title="Statistics">
    <div class="space-y-3">
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <Heart class="w-4 h-4" /> Views
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{views}</span>
        </div>
        {#if isPaid}
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <ShoppingCart class="w-4 h-4" /> Purchases
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{downloads}</span>
        </div>
        {/if}
        {#if !isPaid}
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <Download class="w-4 h-4" /> Downloads
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{downloads}</span>
        </div>
        {/if}
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <Star class="w-4 h-4" /> Rating
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{rating}</span>
        </div>
        <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300">
                <File class="w-4 h-4" /> File Size
            </span>
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{fileSize}</span>
        </div>
    </div>
</SidebarWidget>