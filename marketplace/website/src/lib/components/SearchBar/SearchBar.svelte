<script>
    import { Search } from "lucide-svelte";
    import {Input} from "$components/ui/input";
</script>



<header>
    <nav class="flex items-center md:justify-between justify-center gap-8 flex-col md:flex-row">
        <div class="flex gap-8">
            <a
                href="/discover"
                class="text-gray-950 dark:text-white font-medium relative hover:text-twblue transition-colors"
            >
                Discover
                <div class="absolute bottom-[-12px] left-0 w-full h-[2px] bg-twaccent"></div>
            </a>
            <a
                href="/browse"
                class="text-gray-950 dark:text-white font-medium hover:text-twblue transition-colors"
            >
                Browse All
            </a>
        </div>

        <div class="relative flex-1 max-w-[630px]">
            <Input placeholder="Search for products"/>
            <button
                type="submit"
                class="absolute right-2 top-1/2 -translate-y-1/2 text-[#666666] hover:text-twaccent transition-colors"
                aria-label="Search"
            >
                <Search size={20} />
            </button>
        </div>
    </nav>
</header>


<style>
    header {
        background: transparent;
        width: 100%;
        padding-top: 2rem;
        padding-bottom: 2rem;
    }
</style>