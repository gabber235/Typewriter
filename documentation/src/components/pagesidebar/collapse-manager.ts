import { storage } from "./utils";

const STORAGE_KEY = "starlight-toc-collapse-state";

class TocCollapseManager {
	private toggleButtons: NodeListOf<HTMLButtonElement>;

	constructor() {
		this.toggleButtons = document.querySelectorAll(".collapse-toggle");
		this.init();
	}

	private init(): void {
		const savedState = storage.getCollapseState(STORAGE_KEY);
		Object.entries(savedState).forEach(([slug, isCollapsed]) => {
			if (isCollapsed) this.setCollapsedState(slug, true);
		});

		this.toggleButtons.forEach((button) => {
			button.addEventListener("click", (e) => {
				e.preventDefault();
				e.stopPropagation();
				const slug = button.dataset.slug;
				if (slug) this.toggleCollapse(slug);
			});

			button.addEventListener("keydown", (e) => {
				const slug = button.dataset.slug;
				if (!slug) return;

				if (e.key === "Enter" || e.key === " ") {
					e.preventDefault();
					this.toggleCollapse(slug);
				}
			});
		});
	}

	private toggleCollapse(slug: string): void {
		const listItem = document.querySelector(`li[data-heading-slug="${slug}"]`);
		if (!listItem) return;

		const isCollapsed = listItem.getAttribute("data-collapsed") === "true";
		this.setCollapsedState(slug, !isCollapsed);
		storage.toggleCollapse(STORAGE_KEY, slug);
	}

	private setCollapsedState(slug: string, isCollapsed: boolean): void {
		const listItem = document.querySelector(`li[data-heading-slug="${slug}"]`);
		if (!listItem) return;

		isCollapsed
			? listItem.setAttribute("data-collapsed", "true")
			: listItem.removeAttribute("data-collapsed");
	}
}

function initManager() {
	new TocCollapseManager();
}

if (document.readyState === "loading") {
	document.addEventListener("DOMContentLoaded", initManager);
} else {
	initManager();
}

document.addEventListener("astro:page-load", initManager);
