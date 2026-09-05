import type { ImageMetadata } from "astro";

export interface Cta {
	label: string;
	href: string;
}

/** Which part of a mockup a zoomed crop centres on, in percent of the image. */
export interface Focus {
	x: number;
	y: number;
	zoom: number;
}

export interface Mockup {
	src: ImageMetadata;
	alt: string;
	focus?: Focus;
	/** `object-position` for frames whose aspect ratio differs from the image. */
	position?: string;
}
