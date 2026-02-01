import {
	calculateScrollProgress,
	getRootMargin,
	throttleRAF,
	updateCircularProgress,
	findParentLinks,
	smoothScrollToElement,
	getScrollOffset,
	getScrollContainer,
	onIdle
} from './utils';

const PAGE_TITLE_ID = '_top';

export class StarlightTOC extends HTMLElement {
	protected _current: HTMLAnchorElement | null = this.querySelector<HTMLAnchorElement>('a[aria-current="true"]');
	protected minH = parseInt(this.dataset.minH || '2', 10);
	protected maxH = parseInt(this.dataset.maxH || '3', 10);
	protected progressCircle = this.querySelector<SVGCircleElement>('.progress-circle');
	protected progressText = this.querySelector<HTMLSpanElement>('.progress-text');
	protected links: HTMLAnchorElement[] = [];
	protected headings: HTMLHeadingElement[] = [];
	protected observer: IntersectionObserver | undefined;
	protected resizeTimeout: ReturnType<typeof setTimeout> | null = null;
	protected scrollContainer: HTMLElement | null = null;
	
	protected get tocHeadingSelector(): string {
		const headingLevels = Array.from(
			{ length: 1 + this.maxH - this.minH },
			(_, i) => `h${this.minH + i}`
		).join(',');
		return `h1#${PAGE_TITLE_ID},:where(${headingLevels})[id]`;
	}

	protected set current(link: HTMLAnchorElement) {
		if (link === this._current) return;
		
		if (this._current) {
			this._current.removeAttribute('aria-current');
			this.toggleParentHighlights(this._current, false);
		}
		
		link.setAttribute('aria-current', 'true');
		this._current = link;
		this.toggleParentHighlights(link, true);
		this.updateProgress();
		this.scrollToActiveLink(link);
	}

	constructor() {
		super();
		onIdle(() => this.init());
	}

	protected init(): void {
		this.links = [...this.querySelectorAll<HTMLAnchorElement>('a')];
		this.headings = [...document.querySelectorAll<HTMLHeadingElement>(this.tocHeadingSelector)];
		this.scrollContainer = getScrollContainer();
		this.setupSmoothScroll();
		this.setupIntersectionObserver();
		this.setupScrollTracking();
		this.setupBackToTopButton();
		setTimeout(() => this.updateProgress(), 100);
	}

	protected setupSmoothScroll(): void {
		this.links.forEach(link => {
			link.addEventListener('click', (e) => {
				const targetElement = document.getElementById(decodeURIComponent(link.hash.slice(1)));
				if (targetElement) {
					e.preventDefault();
					smoothScrollToElement(targetElement, getScrollOffset(), this.scrollContainer);
					window.history.pushState(null, '', link.hash);
					targetElement.focus({ preventScroll: true });
				}
			});
		});
	}

	protected setupIntersectionObserver(): void {
		const toObserve = document.querySelectorAll(
			[
				`main :where(${this.tocHeadingSelector})`,
				`main :where(${this.tocHeadingSelector}, .sl-heading-wrapper) ~ *:not(:has(${this.tocHeadingSelector}))`,
				`main .sl-markdown-content > *:not(:has(${this.tocHeadingSelector}))`,
				`main > *:not(:has(${this.tocHeadingSelector}))`,
			].join(',')
		);

		const setCurrent: IntersectionObserverCallback = (entries) => {
			for (const { isIntersecting, target } of entries) {
				if (!isIntersecting) continue;
				const heading = this.getElementHeading(target);
				if (!heading) continue;
				const link = this.links.find(l => l.hash === '#' + encodeURIComponent(heading.id));
				if (link) {
					this.current = link;
					break;
				}
			}
		};

		this.observer = new IntersectionObserver(setCurrent, {
			rootMargin: getRootMargin('summary')
		});
		
		toObserve.forEach(el => this.observer!.observe(el));

		window.addEventListener('resize', () => {
			this.observer?.disconnect();
			this.observer = undefined;
			
			if (this.resizeTimeout) clearTimeout(this.resizeTimeout);
			
			this.resizeTimeout = setTimeout(() => {
				this.setupIntersectionObserver();
				this.updateProgress();
			}, 200);
		});
	}

	protected setupScrollTracking(): void {
		const throttledUpdate = throttleRAF(() => this.updateProgress());
		const target = this.scrollContainer || window;
		target.addEventListener('scroll', throttledUpdate, { passive: true });
	}

	protected updateProgress(): void {
		const progress = this.calculateHeadingBasedProgress();
		updateCircularProgress(this.progressCircle, this.progressText, progress);
	}

	protected calculateHeadingBasedProgress(): number {
		if (this.headings.length === 0) {
			return calculateScrollProgress(this.scrollContainer);
		}

		// Get current scroll position
		const scrollTop = this.scrollContainer ? this.scrollContainer.scrollTop : window.scrollY;
		const clientHeight = this.scrollContainer ? this.scrollContainer.clientHeight : window.innerHeight;
		const scrollHeight = this.scrollContainer ? this.scrollContainer.scrollHeight : document.documentElement.scrollHeight;
		
		// Check if we're at the bottom of the scrollable area
		const isAtBottom = scrollTop + clientHeight >= scrollHeight - 5; // 5px threshold
		if (isAtBottom) {
			return 1.0; // Force 100% when at the bottom
		}
		
		// Build array of heading positions
		const headingPositions = this.headings.map(heading => {
			if (this.scrollContainer) {
				// For scroll containers, use offsetTop
				return heading.offsetTop;
			} else {
				// For window scrolling, get absolute position
				return heading.getBoundingClientRect().top + window.scrollY;
			}
		});
		
		// Find current viewport center position
		const viewportCenter = scrollTop + (clientHeight / 2);
		
		// Find which heading section we're in
		let currentIndex = 0;
		for (let i = 0; i < headingPositions.length; i++) {
			if (viewportCenter >= headingPositions[i]) {
				currentIndex = i;
			} else {
				break;
			}
		}
		
		// Calculate total content length (from first heading to end of scrollable area)
		const contentStart = headingPositions[0] || 0;
		const contentEnd = scrollHeight;
		const totalContentLength = contentEnd - contentStart;
		
		if (totalContentLength <= 0) {
			return scrollTop >= contentStart ? 1 : 0;
		}
		
		// Calculate progress for current section
		const currentHeadingPos = headingPositions[currentIndex];
		const nextHeadingPos = currentIndex < headingPositions.length - 1 
			? headingPositions[currentIndex + 1]
			: contentEnd;
		
		const sectionLength = nextHeadingPos - currentHeadingPos;
		const positionInSection = viewportCenter - currentHeadingPos;
		const sectionProgress = sectionLength > 0 ? positionInSection / sectionLength : 1;
		
		// Calculate overall progress
		// Weight each section by its actual length in the document
		let progressSum = 0;
		let totalWeight = 0;
		
		for (let i = 0; i < headingPositions.length; i++) {
			const sectionStart = headingPositions[i];
			const sectionEnd = i < headingPositions.length - 1 
				? headingPositions[i + 1]
				: contentEnd;
			const weight = sectionEnd - sectionStart;
			
			totalWeight += weight;
			
			if (i < currentIndex) {
				// Fully completed section
				progressSum += weight;
			} else if (i === currentIndex) {
				// Current section - partial progress
				progressSum += weight * Math.min(sectionProgress, 1);
			}
			// Future sections contribute 0
		}
		
		const progress = totalWeight > 0 ? progressSum / totalWeight : 0;
		
		return Math.min(Math.max(progress, 0), 1);
	}

	protected toggleParentHighlights(link: HTMLAnchorElement, active: boolean): void {
		findParentLinks(link, this).forEach(parent => {
			active 
				? parent.setAttribute('data-parent-active', 'true')
				: parent.removeAttribute('data-parent-active');
		});
	}

	protected scrollToActiveLink(link: HTMLAnchorElement): void {
		// Find the scrollable TOC container
		const tocScrollContainer = this.querySelector<HTMLElement>('.toc-scroll-container');
		if (!tocScrollContainer) return;

		// Get positions
		const linkRect = link.getBoundingClientRect();
		const containerRect = tocScrollContainer.getBoundingClientRect();

		// Calculate scroll position to center the link
		const relativeTop = linkRect.top - containerRect.top;
		const currentScroll = tocScrollContainer.scrollTop;
		const containerHeight = tocScrollContainer.clientHeight;
		const linkHeight = linkRect.height;
		
		// Calculate target scroll to center the link
		const targetScroll = currentScroll + relativeTop - (containerHeight / 2) + (linkHeight / 2);

		// Scroll the container
		tocScrollContainer.scrollTo({
			top: Math.max(0, targetScroll),
			behavior: 'smooth'
		});
	}

	protected setupBackToTopButton(): void {
		const backToTopFixedBtn = document.querySelector<HTMLButtonElement>(
			'.back-to-top-pill-fixed'
		);

		if (!backToTopFixedBtn) return;

		let lastScrollY = 0;

		// Hide button initially
		backToTopFixedBtn.classList.add('hidden');

		// Handle scroll direction for fixed button
		const handleScroll = () => {
			const currentScrollY = this.scrollContainer 
				? this.scrollContainer.scrollTop 
				: window.scrollY;

			// Only show when scrolling up AND not at top
			if (currentScrollY < lastScrollY && currentScrollY > 0) {
				// Scrolling up and not at top
				backToTopFixedBtn.classList.remove('hidden');
			} else if (currentScrollY === 0 || currentScrollY > lastScrollY) {
				// At top or scrolling down
				backToTopFixedBtn.classList.add('hidden');
			}

			lastScrollY = currentScrollY;
		};

		// Use throttled scroll handler for performance
		const throttledScroll = throttleRAF(handleScroll);
		
		const scrollTarget = this.scrollContainer || window;
		scrollTarget.addEventListener('scroll', throttledScroll, { passive: true });

		// Setup click handlers
		const backToTopButtons = document.querySelectorAll<HTMLButtonElement>(
			'.back-to-top-pill, .back-to-top-pill-fixed'
		);

		backToTopButtons.forEach((button) => {
			button.addEventListener('click', () => {
				// Hide the button with animation
				backToTopFixedBtn.classList.add('hidden');

				if (this.scrollContainer) {
					this.scrollContainer.scrollTo({
						top: 0,
						behavior: 'smooth',
					});
				} else {
					window.scrollTo({
						top: 0,
						behavior: 'smooth',
					});
				}

				// Focus the main heading for accessibility
				const mainHeading = document.querySelector('h1');
				if (mainHeading) {
					mainHeading.focus({ preventScroll: true });
				}
			});
		});
	}

	protected isHeading(el: Element): el is HTMLHeadingElement {
		return el.matches(this.tocHeadingSelector);
	}

	protected getElementHeading(el: Element | null): HTMLHeadingElement | null {
		if (!el) return null;
		const origin = el;
		
		while (el) {
			if (el.matches('.sl-markdown-content, main > *')) {
				return document.getElementById(PAGE_TITLE_ID) as HTMLHeadingElement;
			}
			
			if (this.isHeading(el)) return el;
			
			const childHeading = el.querySelector<HTMLHeadingElement>(this.tocHeadingSelector);
			if (childHeading) return childHeading;
			
			el = el.previousElementSibling;
			while (el?.lastElementChild) {
				el = el.lastElementChild;
			}
			
			const h = this.getElementHeading(el);
			if (h) return h;
		}
		
		return this.getElementHeading(origin.parentElement);
	}
}

customElements.define('starlight-toc', StarlightTOC);
