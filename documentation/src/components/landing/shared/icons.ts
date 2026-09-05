/** Inline 24×24 outline icons (stroke = currentColor), keyed by name. */
export const icons = {
	arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
	chat: '<path d="M4 5h16v11H9l-5 4z"/><path d="M8 9h8M8 12h5"/>',
	clapper:
		'<path d="M4 9h16v11H4z"/><path d="M4 9l2-5h12l2 5M8 4l2 5M14 4l2 5"/>',
	npc: '<circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/><path d="M17 3l1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/>',
	terminal: '<path d="M4 5h16v14H4z"/><path d="M8 9l3 3-3 3M13 15h4"/>',
	search: '<circle cx="11" cy="11" r="6"/><path d="m20 20-4.5-4.5"/>',
	keyboard:
		'<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 10h1M11 10h1M15 10h1M7 14h10"/>',
	phone:
		'<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/>',
	plug: '<path d="M9 3v5M15 3v5M6 8h12v3a6 6 0 0 1-12 0zM12 17v4"/>',
	pages:
		'<path d="M7 4h7l4 4v12H7z"/><path d="M14 4v4h4"/><path d="M4 8v13h11"/>',
	play: '<path d="M7 5v14l11-7z"/>',
	check: '<path d="m5 12 4 4L19 6"/>',
	book: '<path d="M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z"/><path d="M4 19V5M8 3v16"/>',
	code: '<path d="m8 8-4 4 4 4M16 8l4 4-4 4M14 5l-4 14"/>',
} as const;

export type IconName = keyof typeof icons;
