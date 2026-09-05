import type { Mockup } from "../shared/types";

export interface TileProps {
	title: string;
	/** Screenshot for the media area; omit to render the `media` slot instead. */
	mockup?: Mockup;
}
