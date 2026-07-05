export type AudienceAccent = "primary" | "secondary";

export interface AudienceCta {
	label: string;
	href: string;
}

export interface AudienceCardProps {
	eyebrow: string;
	heading: string;
	body: string;
	accent: AudienceAccent;
	cta: AudienceCta;
}
