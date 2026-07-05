export interface HeroBackgroundProps {
	src: string;
	poster?: string;
}

export interface HeroCta {
	label: string;
	href: string;
}

export interface HeroSectionProps {
	title: string;
	tagline: string;
	backgroundSrc: string;
	primaryCta: HeroCta;
	secondaryCta?: HeroCta;
}
