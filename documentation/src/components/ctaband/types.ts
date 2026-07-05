export interface CtaBandCta {
	label: string;
	href: string;
}

export interface CtaBandProps {
	heading: string;
	body?: string;
	primaryCta: CtaBandCta;
	secondaryCta?: CtaBandCta;
}
