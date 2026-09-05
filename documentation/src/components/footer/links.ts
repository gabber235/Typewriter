import { getSiteVariables } from "@components/variables/site-variables";
import { BASE_PATH } from "@lib/base-path";

export interface FooterLink {
	label: string;
	href: string;
}

export interface FooterGroup {
	title: string;
	links: FooterLink[];
}

// Same source as `:var[]`, so a moved Discord or repo updates the footer too.
const vars = getSiteVariables();

export const footerGroups: FooterGroup[] = [
	{
		title: "Documentation",
		links: [
			{ label: "Get started", href: `${BASE_PATH}docs/` },
			{ label: "Writing syntax", href: `${BASE_PATH}docs/01-syntax/` },
			{ label: "Develop", href: `${BASE_PATH}develop/` },
			{ label: "Glossary", href: `${BASE_PATH}glossary/` },
		],
	},
	{
		title: "Community",
		links: [
			{ label: "Discord", href: vars.discord },
			{ label: "GitHub", href: vars.github },
			{ label: "Report a bug", href: vars.issues },
			{ label: "Sponsor", href: vars.sponsors },
		],
	},
	{
		title: "Project",
		links: [
			{ label: "Modrinth", href: vars.modrinth },
			{ label: "Releases", href: vars.releases },
			{ label: "License", href: `${vars.github}/blob/develop/LICENSE` },
			{ label: "PacketEvents", href: vars.packetevents },
		],
	},
];
