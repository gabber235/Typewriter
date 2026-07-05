export type IntroCtaIcon = "arrow" | "discord";

export interface IntroCta {
	label: string;
	href: string;
	icon?: IntroCtaIcon;
}

export interface IntroAnimationProps {
	primaryCta: IntroCta;
	secondaryCta?: IntroCta;
}
