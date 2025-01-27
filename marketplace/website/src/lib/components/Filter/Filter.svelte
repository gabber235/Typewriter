<script lang="ts">
    import { CheckCard } from "./FilterCheckCard";
    import FilterContainer from "$components/Filter/FilterContainer/FilterContainer.svelte";
</script>

<aside class="text-white p-1 rounded-lg w-80 ml-2">
        <FilterContainer name="Loader">
            <div class="space-y-2">
                <CheckCard label="Vanilla" icon="mdi:minecraft"/>
                <CheckCard label="Fabric" icon="file-icons:fabric"/>
                <CheckCard label="Forge" icon="simple-icons:curseforge"/>
                <CheckCard label="NeoForge" icon="iconoir:wolf"/>
            </div>
        </FilterContainer>
        <FilterContainer name="Version">
            <div class="space-y-2 max-h-72 overflow-y-auto overflow-x-hidden w-auto">
                <CheckCard label="1.20.6"/>
                <CheckCard label="1.20.5"/>
                <CheckCard label="1.20.4"/>
                <CheckCard label="1.20.3"/>
                <CheckCard label="1.20.2"/>
                <CheckCard label="1.20.1"/>
                <CheckCard label="1.20.0"/>
                <CheckCard label="1.19.4"/>
                <CheckCard label="1.19.3"/>
                <CheckCard label="1.19.2"/>
                <CheckCard label="1.19.1"/>
            </div>
        </FilterContainer>
</aside>

<style>
    /* Custom Tailwind utilities are embedded in the class attributes. */
</style>
