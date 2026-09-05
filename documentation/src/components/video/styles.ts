export const videoStyles = {
	wrapper: "relative group/video w-full not-content overflow-hidden rounded-lg",
	video: "w-full block bg-black",

	// `group-focus-within/video` mirrors every hover reveal so keyboard users
	// tabbing into the controls see them; `touch-none` keeps pointer drags on
	// the sliders from scrolling the page.
	progressTrack:
		"absolute bottom-0 left-0 right-0 h-1 bg-white/20 cursor-pointer touch-none transition-all duration-200 z-20 translate-y-0 group-hover/video:h-1.5 group-hover/video:-translate-y-10 group-focus-within/video:h-1.5 group-focus-within/video:-translate-y-10",
	progressFill: "h-full bg-primary pointer-events-none",
	progressThumb:
		"absolute top-1/2 -translate-y-1/2 w-3 h-3 bg-primary rounded-full opacity-0 transition-opacity duration-150 pointer-events-none group-hover/video:opacity-100 group-focus-within/video:opacity-100",
	chapterDivider:
		"absolute top-0 h-full w-0.5 bg-black/50 pointer-events-none z-10",
	// bottom = lifted track offset (2.5rem) + track height (0.375rem) + the
	// 0.5rem gap the labels used to keep above it.
	chapterLabels:
		"absolute bottom-[3.375rem] left-0 right-0 h-4 opacity-0 transition-opacity duration-150 group-hover/video:opacity-100 group-focus-within/video:opacity-100 z-30",
	chapterLabel:
		"truncate text-center text-white/80 text-[10px] leading-tight cursor-pointer hover:text-white transition-colors duration-150",

	overlay:
		"absolute bottom-0 left-0 right-0 h-10 translate-y-full group-hover/video:translate-y-0 group-focus-within/video:translate-y-0 bg-black/30 transition-transform duration-200 pointer-events-none group-hover/video:pointer-events-auto group-focus-within/video:pointer-events-auto z-10",
	controls: "flex items-center justify-between px-3 pb-2 pt-1 h-full",
	controlsLeft: "flex items-center gap-2",
	controlsRight: "flex items-center gap-2",
	timestamp: "text-white/80 text-xs select-none",

	btn: "text-white/90 hover:text-white cursor-pointer bg-transparent border-none p-1 flex items-center justify-center transition-colors duration-150",
	btnIcon: "w-5 h-5",

	centerIndicator:
		"absolute inset-0 flex items-center justify-center pointer-events-none z-30",
	centerIcon:
		"w-24 h-24 text-white/90 bg-black/40 rounded-full p-6 opacity-0 scale-50 transition-all duration-300 [&>svg]:w-full [&>svg]:h-full",

	volumeGroup: "flex items-center gap-1",
	volumeSlider:
		"w-0 overflow-hidden transition-[width] duration-200 group-hover/vol:w-16 group-focus-within/vol:w-16",
	volumeTrack:
		"w-16 h-1 my-2 bg-white/20 rounded-full cursor-pointer touch-none relative",
	volumeFill: "h-full bg-white rounded-full pointer-events-none",
} as const;
