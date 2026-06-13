export interface Chapter {
	time: number;
	label?: string;
}

export interface VideoPlayerProps {
	src: string;
	poster?: string;
	loop?: boolean;
	audio?: boolean;
	chapters?: Chapter[];
}
