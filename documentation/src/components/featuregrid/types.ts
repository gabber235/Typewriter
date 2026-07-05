import type { StarlightIcon } from "@astrojs/starlight/types";

export interface FeatureMedia {
	src: string;
	alt: string;
}

export interface FeatureCardProps {
	icon: StarlightIcon;
	title: string;
	description: string;
	media?: FeatureMedia;
	href?: string;
}

export interface DemoShowcaseProps {
	title: string;
	description: string;
}
