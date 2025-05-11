<script lang="ts">
	import { onMount } from "svelte";
	import { fly, fade, scale } from "svelte/transition";
	import { quintOut } from "svelte/easing";
	import type { PageData } from "./$types";
	import SearchBar from "$lib/components/SearchBar/SearchBar.svelte";
	import Filter from "$lib/components/Filter/Filter.svelte";
	import { Input } from "$lib/components/ui/input";
	import { Search, ArrowUpDown } from "lucide-svelte";
	import { MultiSelect, SingleSelect } from "$lib/components/ui/multi-select";
	
	// Add event listener to close dropdowns when clicking outside
	function setupOuterClickHandler() {
		document.addEventListener('click', (e) => {
			const selectWrappers = document.querySelectorAll('.select-wrapper');
			selectWrappers.forEach(wrapper => {
				const button = wrapper.querySelector('button');
				const content = wrapper.querySelector('div[role="listbox"]');
				if (content && button && !wrapper.contains(e.target as Node)) {
					content.classList.add('hidden');
					button.setAttribute('aria-expanded', 'false');
				}
			});
		});
	}
	
	// Define type options
	const typeOptions = [
		{ value: "extension", label: "Extension" },
		{ value: "resource", label: "Resource" },
		{ value: "other", label: "Other" }
	];
	
	// Define status options
	const statusOptions = [
		{ value: "approved", label: "Approved" },
		{ value: "new", label: "New" },
		{ value: "rejected", label: "Rejected" }
	];
	
	// Define rows per page options
	const rowsOptions = [
		{ value: "10", label: "10" },
		{ value: "20", label: "20" },
		{ value: "50", label: "50" }
	];
	
	// Define sort options
	const sortOptions = [
		{ value: "name_asc", label: "Name (A-Z)" },
		{ value: "name_desc", label: "Name (Z-A)" },
		{ value: "date_newest", label: "Newest first" },
		{ value: "date_oldest", label: "Oldest first" },
		{ value: "downloads_high", label: "Most downloads" },
		{ value: "downloads_low", label: "Least downloads" }
	];
	
	// Selected values for filters
	let selectedTypes = $state<string[]>([]);
	let selectedStatuses = $state<string[]>([]);
	let selectedSort = $state<string>("date_newest");

	let { data }: { data: PageData } = $props();
	let isMobile = $state(false);
	let isLoaded = $state(false);

	// Use products from data loaded by +page.ts
	const projects = data.products.map(product => ({
		name: product.name,
		type: "Extension",
		class: "Modpacks",
		dateCreated: "9 Nov 2022, 14:02",
		lastUpdated: "9 Nov 2022, 16:24",
		role: "Owner",
		status: "Approved",
		downloads: Math.floor(Math.random() * 500),
		bannerImage: product.bannerImage
	}));

	// Use reactive array to ensure updates are detected by Svelte
	let projectsState = $state(projects.map((p) => ({ 
		isImageLoaded: false, 
		imageError: false 
	})));
	
	// Pagination state
	let currentPage = $state(1);
	let itemsPerPage = $state("10"); // Use string format to match option values
	
	// MultiSelect component manages stopPropagation internally
	
	function handleImageLoad(index) {
		console.log(`Image ${index} loaded successfully`);
		projectsState[index].isImageLoaded = true;
	}
	
	function handleImageError(index) {
		console.log(`Image ${index} failed to load`);
		// Mark as loaded to hide the spinner even if there's an error
		projectsState[index].isImageLoaded = true;
		// Set a fallback for the image data
		projectsState[index].imageError = true;
	}
	
	// Preload images to ensure they're cached properly
	function preloadImages() {
		projects.forEach((project, index) => {
			if (project.bannerImage) {
				const img = new Image();
				
				// Set up event handlers before setting src to ensure they catch the events
				img.onload = () => handleImageLoad(index);
				img.onerror = () => handleImageError(index);
				
				// Use crossOrigin to avoid CORS issues with external images
				img.crossOrigin = "anonymous";
				
				// Check if image is already in cache
				img.addEventListener('load', function() {
					console.log(`Image ${index} loaded event triggered`);
					handleImageLoad(index);
				});
				
				// Force absolute URL to prevent relative path issues
				if (project.bannerImage.startsWith('http')) {
					img.src = project.bannerImage;
					
					// If image is already complete (cached), manually trigger the load handler
					if (img.complete) {
						console.log(`Image ${index} was already complete`);
						handleImageLoad(index);
					}
				} else {
					img.src = new URL(project.bannerImage, window.location.origin).href;
				}
			}
		});
	}

	onMount(() => {
		const checkWidth = () => {
			isMobile = window.innerWidth <= 639;
		};
		checkWidth();
		window.addEventListener("resize", checkWidth);
		
		// Setup handler to close dropdowns when clicking outside
		setupOuterClickHandler();
		
		// Add a small delay to simulate content loading
		setTimeout(() => {
			isLoaded = true;
			// Start preloading images immediately after content is marked as loaded
			preloadImages();
			
			// Force refresh if images haven't loaded after a timeout
			setTimeout(() => {
				projects.forEach((_, index) => {
					if (!projectsState[index].isImageLoaded) {
						console.log(`Forcing image ${index} to reload`);
						const img = new Image();
						img.onload = () => handleImageLoad(index);
						img.onerror = () => handleImageError(index);
						img.src = projects[index].bannerImage;
					}
				});
			}, 3000);
		}, 100);
		
		return () => window.removeEventListener("resize", checkWidth);
	});
</script>

<main
	class="text-gray-[#E0E0E0] flex flex-1 flex-col items-center py-16 dark:text-white"
>
	<div class="w-full max-w-7xl px-6" in:fly="{{ y: 20, duration: 400, delay: 200 }}">
		<div class="mb-6 flex items-center justify-between">
			<h1 class="text-4xl font-bold text-white" in:fly="{{ x: -20, duration: 500, delay: 300 }}">Projects</h1>
			<button 
				class="rounded-lg bg-twblue px-4 py-2 text-white hover:bg-twaccent transition-all duration-300 transform hover:scale-105 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-twaccent focus:ring-opacity-50"
				in:fly="{{ x: 20, duration: 500, delay: 300 }}"
			>
				Start a project
			</button>
		</div>
		<p class="mb-8 text-lg text-gray-300" in:fade="{{ duration: 400, delay: 400 }}">
			These are all of your projects and the different updates to their status.
			New changes, such as a project being approved or rejected, will be reflected here.
		</p>

		<div 
			class="w-full overflow-x-auto rounded-lg bg-[#1B1B1D] p-4 shadow-xl transition-all duration-300 hover:shadow-2xl"
			in:fly="{{ y: 30, duration: 600, delay: 500, easing: quintOut }}"
		>
			<div class="mb-6" in:fade="{{ duration: 400, delay: 600 }}">
				<div class="flex flex-col md:flex-row md:items-center gap-3">
					<!-- Search bar with styled Input component -->
					<div class="relative flex-1 md:max-w-[630px]">
						<Input 
							placeholder="Search projects"
							class="w-full"
						/>
						<button
							type="submit"
							class="absolute right-3 top-1/2 -translate-y-1/2 text-[#666666] hover:text-[#059EFC] transition-colors"
							aria-label="Search"
						>
							<Search size={20} />
						</button>
					</div>
					
					<!-- Filter component with MultiSelect -->
					<div class="flex flex-row gap-3">
						<div class="w-[200px]">
							<MultiSelect
								options={typeOptions}
								bind:selected={selectedTypes}
								placeholder="Type"
								showAnyOption={true}
								anyOptionLabel="Any"
								multiSelectedFormat={(count) => `${count} types selected`}
							/>					</div>
					<div class="w-[200px]">
						<MultiSelect
							options={statusOptions}
							bind:selected={selectedStatuses}
							placeholder="Project status"
							showAnyOption={true}
							anyOptionLabel="Any"
							multiSelectedFormat={(count) => `${count} statuses selected`}
						/>
					</div>
					<div class="w-[200px]">
						<SingleSelect
							options={sortOptions}
							bind:value={selectedSort}
							placeholder="Sort by"
						/>
					</div>
				</div>
				</div>
			</div>

			<table class="w-full min-w-full table-auto border-collapse">
				<thead>
					<tr class="border-b border-gray-700 text-left" in:fly="{{ y: -10, duration: 400, delay: 700 }}">
						<th class="pb-3 pr-4 text-twblue font-medium">Name</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Type</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Class</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Date Created</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Last Updated</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Role</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Status</th>
						<th class="pb-3 pr-4 text-twblue font-medium">Downloads</th>
						<th class="pb-3 text-twblue font-medium">Actions</th>
					</tr>
				</thead>
				<tbody>
					{#if !isLoaded}
						<tr>
							<td colspan="9" class="py-8 text-center">
								<div class="flex flex-col items-center justify-center space-y-4" in:fade="{{ duration: 300 }}">
									<div class="h-10 w-10 animate-spin rounded-full border-4 border-gray-700 border-t-twblue"></div>
									<p class="text-gray-400">Loading projects...</p>
								</div>
							</td>
						</tr>
					{:else if projects.length > 0}
						{#each projects as project, i}
						<tr 
							class="border-b border-gray-800 hover:bg-gray-800/70 transition-all duration-200 cursor-pointer"
							in:fly="{{ y: 10, duration: 300, delay: 100 + (i * 50) }}"
						>
							<td class="py-4 pr-4">
								<div class="flex items-center">
									<div class="relative mr-3 h-10 w-10 overflow-hidden rounded bg-gray-700">
										{#if project.bannerImage}
											<img 
												src={project.bannerImage} 
												alt={project.name} 
												class="h-full w-full object-cover" 
												on:error={(e) => { e.currentTarget.src = ''; e.currentTarget.classList.add('bg-gray-700'); }}
												loading="lazy" 
											/>
										{/if}
									</div>
									<span class="font-medium text-white">{project.name}</span>
								</div>
							</td>
							<td class="py-4 pr-4 text-gray-300">{project.type}</td>
							<td class="py-4 pr-4 text-gray-300">{project.class}</td>
							<td class="py-4 pr-4 text-gray-300">{project.dateCreated}</td>
							<td class="py-4 pr-4 text-gray-300">{project.lastUpdated}</td>
							<td class="py-4 pr-4 text-gray-300">{project.role}</td>
							<td class="py-4 pr-4">
								<span class="inline-flex items-center">
									<span 
										class="mr-2 h-2 w-2 rounded-full {project.status === 'Approved' ? 'bg-green-500' : project.status === 'New' ? 'bg-blue-500' : 'bg-yellow-500'} animate-pulse"
									></span>
									<span class="font-medium {project.status === 'Approved' ? 'text-green-400' : project.status === 'New' ? 'text-blue-400' : 'text-yellow-400'}">
										{project.status}
									</span>
								</span>
							</td>
							<td class="py-4 pr-4">
								<div class="flex items-center">
									<svg xmlns="http://www.w3.org/2000/svg" class="mr-1 h-4 w-4 text-twblue" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
										<path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"></path>
										<polyline points="7 10 12 15 17 10"></polyline>
										<line x1="12" y1="15" x2="12" y2="3"></line>
									</svg>
									<span class="font-medium text-white">{project.downloads}</span>
								</div>
							</td>
							<td class="py-4">
								<button class="ml-2 p-1 rounded-full hover:bg-gray-700 transition-colors duration-200">
									<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
										<circle cx="12" cy="12" r="1"></circle>
										<circle cx="12" cy="5" r="1"></circle>
										<circle cx="12" cy="19" r="1"></circle>
									</svg>
								</button>
							</td>
						</tr>
					{/each}
				{:else}
					<tr>
						<td colspan="9" class="py-8 text-center">
							<div class="flex flex-col items-center justify-center space-y-4" in:fade="{{ duration: 300 }}">
								<svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-600 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
								</svg>
								<p class="text-gray-400 text-lg">No projects found</p>
								<button class="mt-2 rounded-lg bg-twblue px-4 py-2 text-white hover:bg-twaccent transition-all duration-300 transform hover:scale-105">
									Create your first project
								</button>
							</div>
						</td>
					</tr>
				{/if}
			</tbody>
		</table>

		<div class="mt-4 flex items-center justify-between text-sm" in:fade="{{ duration: 400, delay: 1000 }}">
			<div class="flex items-center">
				<span class="mr-3">Rows per page:</span>
				<div class="w-[70px]">
					<SingleSelect 
						options={rowsOptions}
						bind:value={itemsPerPage}
						class="h-8 text-xs"
					/>
				</div>
			</div>
			<div class="flex items-center">
				{#if projects.length > 0}
					{#if projects.length <= parseInt(itemsPerPage)}
						<span>1-{projects.length} of {projects.length}</span>
					{:else}
						{@const startItem = (currentPage - 1) * parseInt(itemsPerPage) + 1}
						{@const endItem = Math.min(currentPage * parseInt(itemsPerPage), projects.length)}
						<span>{startItem}-{endItem} of {projects.length}</span>
					{/if}
				{:else}
					<span>0 projects</span>
				{/if}
				<div class="ml-4 flex">
					<button 
						class="p-1 rounded-full {currentPage === 1 ? 'text-gray-600 cursor-not-allowed' : 'hover:bg-gray-700 transition-colors duration-200'}"
						disabled={currentPage === 1}
						on:click={() => {
							if (currentPage > 1) {
								currentPage -= 1;
							}
						}}
					>
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
							<polyline points="15 18 9 12 15 6"></polyline>
						</svg>
					</button>
					<button 
						class="p-1 rounded-full {currentPage * parseInt(itemsPerPage) >= projects.length ? 'text-gray-600 cursor-not-allowed' : 'hover:bg-gray-700 transition-colors duration-200'}"
						disabled={currentPage * parseInt(itemsPerPage) >= projects.length}
						on:click={() => {
							if (currentPage * parseInt(itemsPerPage) < projects.length) {
								currentPage += 1;
							}
						}}
					>
						<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
							<polyline points="9 18 15 12 9 6"></polyline>
						</svg>
					</button>
				</div>
			</div>
		</div>
	</div>
	</div>
</main>
