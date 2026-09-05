import type { Cta } from "../shared/types";

export interface CtaBandProps {
	title: string;
	primaryCta: Cta;
	secondaryCta: Cta;
	/** Where "Sponsor the project" points. */
	sponsorHref: string;
}

export interface Sponsor {
	login: string;
	name: string;
	/** On the $10+/month tiers, the same cut-off the README workflow uses. */
	featured?: boolean;
}
