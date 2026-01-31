import type { CollapseState } from './types';

export function getScrollContainer(): HTMLElement | null {
	return document.querySelector<HTMLElement>('.content-pane');
}

export function calculateScrollProgress(scrollContainer?: HTMLElement | null): number {
	const { scrollTop, scrollHeight, clientHeight } = scrollContainer || {
		scrollTop: window.scrollY,
		scrollHeight: document.documentElement.scrollHeight,
		clientHeight: window.innerHeight
	};
	
	const maxScroll = scrollHeight - clientHeight;
	return maxScroll <= 0 ? (scrollTop > 0 ? 1 : 0) : Math.min(Math.max(scrollTop / maxScroll, 0), 1);
}

export function getRootMargin(mobileTocSelector = 'summary'): `-${number}px 0% ${number}px` {
	const navBarHeight = document.querySelector('header')?.getBoundingClientRect().height || 0;
	const mobileTocHeight = document.querySelector(mobileTocSelector)?.getBoundingClientRect().height || 0;
	const top = navBarHeight + mobileTocHeight + 32;
	const bottom = top + 53;
	
	return `-${top}px 0% ${bottom - document.documentElement.clientHeight}px`;
}

export function throttleRAF(callback: () => void): () => void {
	let rafId: number | null = null;
	return () => {
		if (rafId !== null) window.cancelAnimationFrame(rafId);
		rafId = window.requestAnimationFrame(() => {
			callback();
			rafId = null;
		});
	};
}

export function smoothScrollToElement(
	element: HTMLElement,
	offset = 0,
	scrollContainer?: HTMLElement | null
): void {
	if (scrollContainer) {
		const containerRect = scrollContainer.getBoundingClientRect();
		const elementRect = element.getBoundingClientRect();
		scrollContainer.scrollTo({
			top: scrollContainer.scrollTop + elementRect.top - containerRect.top - offset,
			behavior: 'smooth'
		});
	} else {
		window.scrollTo({
			top: element.getBoundingClientRect().top + window.scrollY - offset,
			behavior: 'smooth'
		});
	}
}

export function getScrollOffset(): number {
	const header = document.querySelector('header');
	return header ? header.getBoundingClientRect().height + 16 : 80;
}

export const storage = {
	getCollapseState(key: string): CollapseState {
		try {
			const stored = localStorage.getItem(key);
			return stored ? JSON.parse(stored) : {};
		} catch {
			return {};
		}
	},
	
	setCollapseState(key: string, state: CollapseState): void {
		try {
			localStorage.setItem(key, JSON.stringify(state));
		} catch {}
	},
	
	toggleCollapse(key: string, slug: string): boolean {
		const state = this.getCollapseState(key);
		const newValue = !state[slug];
		state[slug] = newValue;
		this.setCollapseState(key, state);
		return newValue;
	}
};

export function findParentLinks(currentLink: HTMLAnchorElement, tocElement: HTMLElement): HTMLAnchorElement[] {
	const parents: HTMLAnchorElement[] = [];
	let listItem = currentLink.closest('li');
	
	while (listItem) {
		const parentList = listItem.parentElement?.closest('li');
		if (!parentList) break;
		
		const parentLink = parentList.querySelector<HTMLAnchorElement>(':scope > div > a, :scope > a');
		if (parentLink) parents.push(parentLink);
		
		listItem = parentList;
	}
	
	return parents;
}

export function updateCircularProgress(
	circle: SVGCircleElement | null,
	text: HTMLSpanElement | null,
	progress: number
): void {
	const validProgress = Math.min(Math.max(progress || 0, 0), 1);
	// Circumference = 2 * π * radius, where radius = 15.5
	const circumference = 2 * Math.PI * 15.5; // ≈ 97.39
	
	if (circle) {
		// Cap visual at 95% to prevent appearing fully closed
		const visualProgress = Math.min(validProgress, 0.95);
		const offset = circumference * (1 - visualProgress);
		circle.style.strokeDashoffset = `${offset}`;
	}
	
	if (text) {
		const percentage = Math.round(validProgress * 100);
		text.textContent = `${percentage}%`;
	}
}

export const onIdle = (cb: IdleRequestCallback): number =>
	(window.requestIdleCallback || ((cb) => setTimeout(cb, 1)))(cb);
