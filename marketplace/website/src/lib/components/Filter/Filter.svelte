<script lang="ts">
    import { CheckCard } from "./FilterCheckCard";
    import FilterContainer from "$components/Filter/FilterContainer/FilterContainer.svelte";
    import { onMount } from "svelte";
    import { writable } from "svelte/store";

    let isMenuOpen = writable(false);
    let isMobile = writable(false);

    function toggleMenu() {
        isMenuOpen.update(value => !value);
    }

    onMount(() => {
        const checkWidth = () => {
            isMobile.set(window.innerWidth <= 639);
        };
        checkWidth();
        window.addEventListener('resize', checkWidth);
        return () => window.removeEventListener('resize', checkWidth);
    });
</script>

<aside class="w-full rounded-lg text-white sm:w-80">
    {#if $isMobile}
        <button
                class="w-full p-2 bg-twblue text-white rounded-lg transition-colors hover:bg-twaccent"
                on:click={toggleMenu}
        >
            {#if $isMenuOpen} Close Filters {:else} Open Filters {/if}
        </button>
    {/if}
    {#if !$isMobile || $isMenuOpen}
        <div>
            <FilterContainer name="Loader">
                <div class="space-y-2">
                    <CheckCard label="Vanilla" icon="mdi:minecraft" />
                    <CheckCard label="Fabric" icon="file-icons:fabric" />
                    <CheckCard label="Forge" icon="simple-icons:curseforge" />
                    <CheckCard label="NeoForge" icon="iconoir:wolf" />
                </div>
            </FilterContainer>
            <FilterContainer name="Version">
                <div class="max-h-72 w-auto space-y-2 overflow-y-auto overflow-x-hidden">
                    <CheckCard label="1.20.6" />
                    <CheckCard label="1.20.5" />
                    <CheckCard label="1.20.4" />
                    <CheckCard label="1.20.3" />
                    <CheckCard label="1.20.2" />
                    <CheckCard label="1.20.1" />
                    <CheckCard label="1.20.0" />
                    <CheckCard label="1.19.4" />
                    <CheckCard label="1.19.3" />
                    <CheckCard label="1.19.2" />
                    <CheckCard label="1.19.1" />
                </div>
            </FilterContainer>
            <FilterContainer name="Category">
                <div class="space-y-2">
                    <CheckCard label="Mod" icon="mdi:cube" />
                    <CheckCard label="Resource Pack" icon="lucide:paintbrush" />
                    <CheckCard label="Data Pack" icon="mdi:database" />
                    <CheckCard label="Server" icon="mdi:server" />
                </div>
            </FilterContainer>
        </div>
    {/if}
</aside>