<script lang="ts">

import {Checkbox} from "$components/ui/checkbox";
import {Label} from "$components/ui/label";
import FilterContainer from "$components/FilterContainer/FilterContainer.svelte";
</script>

<aside class="text-white">
    <div class="flex items-center justify-between">
        <h2 class="text-lg font-semibold">Filter</h2>
        <button class="text-sm text-gray-500">Clear</button>
    </div>
    <div class="mt-4">
        <FilterContainer name="Game Version">
            <Checkbox /><Label>1.20.6</Label>
            <Checkbox /><Label>1.20.5</Label>
        </FilterContainer>
    </div>
</aside>