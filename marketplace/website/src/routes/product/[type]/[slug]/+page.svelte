<script lang="ts">
    import {page} from "$app/state";
    import type {PageData} from './$types';
    import {Button} from "$lib/components/ui/button";
    import {Tabs, TabsContent, TabsList, TabsTrigger} from "$lib/components/ui/tabs";
    import {Download, Flag, Heart, Share2} from "lucide-svelte";
    import CompatibilityWidget from "$lib/components/SidebarWidget/CompatibilityWidget.svelte";
    import CreatorWidget from "$lib/components/SidebarWidget/CreatorWidget.svelte";
    import ItemListWidget from "$lib/components/SidebarWidget/ItemListWidget.svelte";
    import StatsWidget from "$lib/components/SidebarWidget/StatsWidget.svelte";
    import DateInfoWidget from "$lib/components/SidebarWidget/DateInfoWidget.svelte";
    import LicenseWidget from "$lib/components/SidebarWidget/LicenseWidget.svelte";
    import Entry from "$components/Entry/Entry.svelte";
    import {DropdownMenuTrigger, DropdownMenuItem, DropdownMenu, DropdownMenuContent, SubTrigger, SubContent, Sub} from "$components/ui/dropdown-menu";

    export let data: PageData;
    $: product = data.product;

    let searchQuery = "";
    let selectedType = "";

    $: entryTypes = product.content?.reduce((acc, entry) => {
        if (!('type' in entry)) return acc;
        const [category, subType] = entry.type.split('.');
        
        const formattedCategory = category
            .split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
        
        if (!acc[formattedCategory]) {
            acc[formattedCategory] = new Set();
        }
        
        if (subType) {
            const formattedSubType = subType
                .replace(/Entry$/, '')
                .split('_')
                .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ');
            acc[formattedCategory].add(formattedSubType);
        }
        return acc;
    }, {} as Record<string, Set<string>>) ?? {};

    $: filteredEntries = product.content?.filter(entry => {
        if (!('type' in entry)) return false;
        
        const matchesSearch = searchQuery.toLowerCase() === '' || 
            entry.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
            entry.description.toLowerCase().includes(searchQuery.toLowerCase());

        if (selectedType === '') return matchesSearch;

        const [entryCategory, entrySubType] = entry.type.split('.');
        const formattedEntryCategory = entryCategory
            .split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');

        const formattedEntrySubType = entrySubType
            ? entrySubType
                .replace(/Entry$/, '')
                .split('_')
                .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ')
            : '';

        const formattedEntryType = formattedEntrySubType 
            ? `${formattedEntryCategory}.${formattedEntrySubType}`
            : formattedEntryCategory;

        return matchesSearch && (formattedEntryType === selectedType);

    }) ?? [];
</script>

<div class="h-full mx-auto px-24 py-8 dark:bg-[#101013]">
    <div class="flex flex-col lg:flex-row gap-8">

        <!-- Main Content -->
        <div class="flex-1 lg:w-2/3">
            <div class="flex items-center gap-6 mb-8">
                <div class="flex-shrink-0">
                    <img src={product.bannerImage} alt="Product banner"
                         class="w-36 h-36 rounded-lg shadow-md dark:shadow-[#1E1E24]">
                </div>
                <div class="flex-1">
                    <div class="flex justify-between items-center gap-4 mb-2">
                        <div>
                            <h1 class="text-3xl font-bold mb-2 dark:text-[#EEF9FC]">{product.name}</h1>
                            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{product.shortDescription}</span>
                        </div>
                        <div class="flex items-center gap-2">
                            <Button size="icon" style="border-color: {product.color}; border-width: 0.115rem;">
                                <Flag class="w-4 h-4 text-white"/>
                            </Button>
                            <Button size="icon" style="border-color: {product.color}; border-width: 0.115rem;">
                                <Share2 class="w-4 h-4 text-white"/>
                            </Button>
                            <Button size="icon" style="border-color: {product.color}; border-width: 0.115rem;">
                                <Heart class="w-4 h-4 text-white"/>
                            </Button>
                            <Button variant="default" class="gap-2" style="background-color: {product.color}">
                                <Download
                                        class="w-4 h-4"/> {product.price === 0 ? 'Download' : `${product.price} ${product.currency}`}
                            </Button>
                        </div>
                    </div>
                    <div class="flex items-center gap-2">
                        <img src={product.creator.avatarUrl} alt="Creator avatar" class="w-8 h-8 rounded-full">
                        <span class="text-sm font-medium text-zinc-900 dark:text-zinc-50">{product.creator.name}</span>
                    </div>
                </div>
            </div>

            <Tabs value="description" class="w-full">
                <TabsList class="bg-[#1E1E24] rounded-lg p-1">
                    <TabsTrigger
                            value="description"
                            class="px-4 py-2 text-sm font-medium text-gray-400 hover:text-gray-300 data-[state=active]:bg-[#2A2A30] data-[state=active]:text-white transition-colors rounded"
                    >
                        Description
                    </TabsTrigger>
                    <TabsTrigger
                            value="gallery"
                            class="px-4 py-2 text-sm font-medium text-gray-400 hover:text-gray-300 data-[state=active]:bg-[#2A2A30] data-[state=active]:text-white transition-colors rounded"
                    >
                        Gallery
                    </TabsTrigger>
                    <TabsTrigger
                            value="changelog"
                            class="px-4 py-2 text-sm font-medium text-gray-400 hover:text-gray-300 data-[state=active]:bg-[#2A2A30] data-[state=active]:text-white transition-colors rounded"
                    >
                        Changelog
                    </TabsTrigger>
                    {#if page.params.type === 'extension'}
                        <TabsTrigger
                                value="entries"
                                class="px-4 py-2 text-sm font-medium text-gray-400 hover:text-gray-300 data-[state=active]:bg-[#2A2A30] data-[state=active]:text-white transition-colors rounded"
                        >
                            Entries
                        </TabsTrigger>
                    {/if}
                </TabsList>
                <TabsContent value="description" class="prose dark:prose-invert max-w-none dark:text-[#EEF9FC]">
                    <p class="dark:text-gray-300 bg-white dark:bg-zinc-900 text-muted-foreground w-full h-10 flex items-center justify-start rounded-md py-6 px-4">{product.shortDescription}</p>
                </TabsContent>
                <TabsContent value="gallery" class="prose dark:prose-invert max-w-none dark:text-[#EEF9FC]">
                    <p class="dark:text-gray-300 bg-white dark:bg-zinc-900 text-muted-foreground w-full h-10 flex items-center justify-start rounded-md py-6 px-4">
                        Gallery images will be displayed here</p>
                </TabsContent>
                <TabsContent value="changelog" class="prose dark:prose-invert max-w-none dark:text-[#EEF9FC]">
                    <p class="dark:text-gray-300 bg-white dark:bg-zinc-900 text-muted-foreground w-full h-10 flex items-center justify-start rounded-md py-6 px-4">
                        Version history and changelog will be displayed here</p>
                </TabsContent>
                {#if page.params.type === 'extension'}
                    <TabsContent value="entries" class="prose dark:prose-invert max-w-none dark:text-[#EEF9FC]">
                        <div class="space-y-6">
                            <!-- Search and Filter Section -->
                            <div class="flex items-center gap-4">
                                <div class="relative flex-1">
                                    <input
                                        type="text"
                                        placeholder="Search entries..."
                                        bind:value={searchQuery}
                                        class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 pr-10 text-sm dark:border-gray-600 dark:bg-zinc-900 dark:text-gray-300 dark:placeholder-gray-400"
                                    />
                                    <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                                        <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                        </svg>
                                    </div>
                                </div>
                                
                                <!-- Filter Options -->
                                <DropdownMenu>
                                    <DropdownMenuTrigger class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm dark:border-gray-600 dark:bg-zinc-900 dark:text-gray-300">
                                        {selectedType || 'Type'}
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent>
                                        <DropdownMenuItem on:click={() => selectedType = ''}>All Types</DropdownMenuItem>
                                        {#each Object.entries(entryTypes) as [category, subTypes]}
                                            <Sub>
                                                <SubTrigger>{category}</SubTrigger>
                                                <SubContent>
                                                    {#each [...subTypes] as subType}
                                                        <DropdownMenuItem on:click={() => selectedType = `${category}.${subType}`}>
                                                            {subType}
                                                        </DropdownMenuItem>
                                                    {/each}
                                                </SubContent>
                                            </Sub>
                                        {/each}
                                    </DropdownMenuContent>
                                </DropdownMenu>
                            </div>
                            <!-- Entry Grid -->
                            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
                                {#each filteredEntries as entry}
                                    <Entry
                                        title={entry.name}
                                        description={entry.description}
                                        icon={entry.icon}
                                        color={entry.color}
                                    />
                                {/each}
                            </div>
                        </div>
                    </TabsContent>
                {/if}
            </Tabs>
        </div>

        <!-- Sidebar -->
        <div class="lg:w-1/3 space-y-4 dark:text-[#EEF9FC]">
            <CreatorWidget
                    avatarUrl={product.creator.avatarUrl}
                    name={product.creator.name}
            />
            <StatsWidget
                    views={product.views}
                    downloads={product.downloads}
                    rating={product.rating}
                    fileSize={product.fileSize}
                    isPaid={product.price !== 0}
            />

            <CompatibilityWidget
                    gameEdition={product.compatibility.gameEdition}
                    versions={product.compatibility.versions}
            />
            <DateInfoWidget
                    publishDate={product.publishDate}
                    updateDate={product.updateDate}
            />
            <LicenseWidget
                    type={product.license.type}
            />
            <ItemListWidget
                    title="Tags"
                    items={product.tags}
            />
            <ItemListWidget
                    title="Platforms"
                    items={product.platforms}
            />
        </div>
    </div>
</div>