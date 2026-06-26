import {
	exitFullscreenIcon,
	fullscreenIcon,
	pauseIcon,
	playIcon,
	volumeHighIcon,
	volumeLowIcon,
	volumeMutedIcon,
} from "./icons";

function formatTime(seconds: number): string {
	const m = Math.floor(seconds / 60);
	const s = Math.floor(seconds % 60);
	return `${m}:${s.toString().padStart(2, "0")}`;
}

export function initVideoPlayer(container: HTMLElement) {
	// Guard against double-initialization (avoids duplicate event listeners).
	if (container.dataset.videoReady === "true") return;
	container.dataset.videoReady = "true";

	const video = container.querySelector<HTMLVideoElement>("[data-video]");
	const progressTrack = container.querySelector<HTMLElement>(
		"[data-progress-track]",
	);
	const progressFill = container.querySelector<HTMLElement>(
		"[data-progress-fill]",
	);
	const progressThumb = container.querySelector<HTMLElement>(
		"[data-progress-thumb]",
	);
	const playBtn = container.querySelector<HTMLElement>("[data-play-btn]");
	const playBtnIcon = container.querySelector<HTMLElement>("[data-play-icon]");
	const volumeBtn = container.querySelector<HTMLElement>("[data-volume-btn]");
	const volumeBtnIcon =
		container.querySelector<HTMLElement>("[data-volume-icon]");
	const volumeTrack = container.querySelector<HTMLElement>(
		"[data-volume-track]",
	);
	const volumeFill = container.querySelector<HTMLElement>("[data-volume-fill]");
	const fullscreenBtn = container.querySelector<HTMLElement>(
		"[data-fullscreen-btn]",
	);
	const fullscreenIcon_ = container.querySelector<HTMLElement>(
		"[data-fullscreen-icon]",
	);
	const timestamp = container.querySelector<HTMLElement>("[data-timestamp]");

	const centerIcon = container.querySelector<HTMLElement>("[data-center-icon]");

	if (!video || !progressTrack || !progressFill || !playBtn || !playBtnIcon)
		return;

	let savedVolume = 1;
	let indicatorTimeout: ReturnType<typeof setTimeout> | null = null;

	function showCenterIcon(icon: string, persist: boolean) {
		if (!centerIcon) return;
		centerIcon.innerHTML = icon;
		centerIcon.style.opacity = "1";
		centerIcon.style.transform = "scale(1)";

		if (indicatorTimeout) clearTimeout(indicatorTimeout);
		if (persist) return;

		indicatorTimeout = setTimeout(() => {
			centerIcon.style.opacity = "0";
			centerIcon.style.transform = "scale(1.2)";
		}, 400);
	}

	function updatePlayIcon() {
		if (!playBtnIcon || !video) return;
		playBtnIcon.innerHTML = video.paused ? playIcon : pauseIcon;
	}

	function updateVolumeIcon() {
		if (!volumeBtnIcon || !video) return;
		if (video.muted || video.volume === 0) {
			volumeBtnIcon.innerHTML = volumeMutedIcon;
		} else if (video.volume < 0.5) {
			volumeBtnIcon.innerHTML = volumeLowIcon;
		} else {
			volumeBtnIcon.innerHTML = volumeHighIcon;
		}
	}

	function updateProgress() {
		if (!video || !progressFill || !progressThumb) return;
		const pct = video.duration ? (video.currentTime / video.duration) * 100 : 0;
		progressFill.style.width = `${pct}%`;
		progressThumb.style.left = `${pct}%`;
	}

	function updateTimestamp() {
		if (!video || !timestamp) return;
		const current = formatTime(video.currentTime);
		const total = formatTime(video.duration || 0);
		timestamp.textContent = `${current} / ${total}`;
	}

	function updateFullscreenIcon() {
		if (!fullscreenIcon_) return;
		const isFs = document.fullscreenElement === container;
		fullscreenIcon_.innerHTML = isFs ? exitFullscreenIcon : fullscreenIcon;
	}

	// Play / Pause
	playBtn.addEventListener("click", () => {
		video.paused ? video.play() : video.pause();
	});

	video.addEventListener("click", () => {
		video.paused ? video.play() : video.pause();
	});

	video.addEventListener("play", () => {
		updatePlayIcon();
		showCenterIcon(pauseIcon, false);
	});
	video.addEventListener("pause", () => {
		updatePlayIcon();
		showCenterIcon(playIcon, true);
	});
	video.addEventListener("timeupdate", () => {
		updateProgress();
		updateTimestamp();
	});

	function onMetadataReady() {
		if (!video?.duration || Number.isNaN(video.duration)) return;
		updateTimestamp();
		renderChapterDividers();
	}

	// Chapters
	type ChapterEntry = { time: number; label?: string };
	let parsedChapters: ChapterEntry[] = [];

	const chapterLabelsContainer = container.querySelector<HTMLElement>(
		"[data-chapter-labels]",
	);

	let chaptersRendered = false;

	function renderChapterDividers() {
		if (chaptersRendered || !video || !progressTrack) return;
		const raw = progressTrack.dataset.chapters;
		if (!raw) return;

		chaptersRendered = true;

		parsedChapters = [...(JSON.parse(raw) as ChapterEntry[])].sort(
			(a, b) => a.time - b.time,
		);

		// Add divider lines
		for (const ch of parsedChapters) {
			if (ch.time <= 0 || ch.time >= video.duration) continue;
			const pct = (ch.time / video.duration) * 100;
			const div = document.createElement("div");
			div.className =
				"absolute top-0 h-full w-0.5 bg-black/80 pointer-events-none z-10";
			div.style.left = `${pct}%`;
			progressTrack.appendChild(div);
		}

		// Render labels above each segment
		if (!chapterLabelsContainer) return;

		// Build full segment list including the gap before the first chapter
		const allPoints = [
			{ time: 0, label: undefined as string | undefined },
			...parsedChapters,
		].sort((a, b) => a.time - b.time);

		for (let i = 0; i < allPoints.length; i++) {
			const ch = allPoints[i];
			const nextTime =
				i < allPoints.length - 1 ? allPoints[i + 1].time : video.duration;
			const midPct = ((ch.time + nextTime) / 2 / video.duration) * 100;

			if (!ch.label) continue;

			const label = document.createElement("span");
			label.className =
				"absolute -translate-x-1/2 whitespace-nowrap text-white/90 text-[10px] leading-tight cursor-pointer hover:text-white transition-colors duration-150 px-6 py-1 bg-black/40 hover:bg-black/20 rounded-sm";
			label.style.left = `${midPct}%`;
			label.textContent = ch.label;
			label.title = ch.label;

			const seekTime = ch.time;
			label.addEventListener("mousedown", (e) => e.stopPropagation());
			label.addEventListener("click", () => {
				if (video) video.currentTime = seekTime;
			});

			chapterLabelsContainer.appendChild(label);
		}
	}

	function getChapterAtTime(time: number): ChapterEntry | undefined {
		for (let i = parsedChapters.length - 1; i >= 0; i--) {
			if (parsedChapters[i].time <= time) return parsedChapters[i];
		}
		return undefined;
	}

	if (progressTrack) {
		progressTrack.addEventListener("mousemove", (e) => {
			if (!video?.duration) return;
			const rect = progressTrack.getBoundingClientRect();
			const pct = Math.max(
				0,
				Math.min(1, (e.clientX - rect.left) / rect.width),
			);
			const hoverTime = pct * video.duration;
			const chapter = getChapterAtTime(hoverTime);
			// Update timestamp to show hovered chapter name
			if (timestamp && chapter?.label) {
				timestamp.textContent = chapter.label;
			}
		});

		progressTrack.addEventListener("mouseleave", () => {
			updateTimestamp();
		});
	}

	// Init metadata (chapters + timestamp) — after all chapter code is defined
	video.addEventListener("loadedmetadata", onMetadataReady);
	video.addEventListener("durationchange", onMetadataReady);
	onMetadataReady();

	// Progress seeking
	function seekFromEvent(e: MouseEvent) {
		if (!video || !progressTrack) return;
		const rect = progressTrack.getBoundingClientRect();
		const pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
		// Update visual immediately for smooth feel
		if (progressFill) progressFill.style.width = `${pct * 100}%`;
		if (progressThumb) progressThumb.style.left = `${pct * 100}%`;
		video.currentTime = pct * video.duration;
	}

	let isSeeking = false;
	let wasPlaying = false;

	progressTrack.addEventListener("mousedown", (e) => {
		isSeeking = true;
		wasPlaying = !video.paused;
		if (wasPlaying) video.pause();
		seekFromEvent(e);
	});

	document.addEventListener("mousemove", (e) => {
		if (!isSeeking) return;
		seekFromEvent(e);
	});

	document.addEventListener("mouseup", () => {
		if (!isSeeking) return;
		isSeeking = false;
		if (wasPlaying) video.play();
	});

	// Volume
	if (volumeBtn && volumeBtnIcon) {
		volumeBtn.addEventListener("click", () => {
			if (video.muted || video.volume === 0) {
				video.muted = false;
				video.volume = savedVolume || 0.5;
			} else {
				savedVolume = video.volume;
				video.muted = true;
			}
			updateVolumeIcon();
			updateVolumeFill();
		});
	}

	function updateVolumeFill() {
		if (!volumeFill || !video) return;
		const vol = video.muted ? 0 : video.volume;
		volumeFill.style.width = `${vol * 100}%`;
	}

	if (volumeTrack) {
		volumeTrack.addEventListener("click", (e) => {
			const rect = volumeTrack.getBoundingClientRect();
			const pct = Math.max(
				0,
				Math.min(1, (e.clientX - rect.left) / rect.width),
			);
			video.volume = pct;
			video.muted = pct === 0;
			savedVolume = pct || savedVolume;
			updateVolumeIcon();
			updateVolumeFill();
		});
	}

	// Fullscreen
	if (fullscreenBtn) {
		fullscreenBtn.addEventListener("click", () => {
			if (document.fullscreenElement === container) {
				document.exitFullscreen();
			} else {
				container.requestFullscreen();
			}
		});

		document.addEventListener("fullscreenchange", updateFullscreenIcon);
	}

	// Viewport autoplay for muted (non-audio) videos
	const hasAudio = video.dataset.audio === "true";

	if (!hasAudio) {
		const observer = new IntersectionObserver(
			([entry]) => {
				if (!entry || !video) return;
				entry.isIntersecting ? video.play() : video.pause();
			},
			{ threshold: 0.5 },
		);
		observer.observe(video);
	}

	// Init state
	updatePlayIcon();
	updateVolumeIcon();
	updateVolumeFill();
	updateProgress();
}
