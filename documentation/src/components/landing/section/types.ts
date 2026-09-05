export type SectionAlign = "start" | "center";
export type SectionWidth = "full" | "narrow";

export interface SectionProps {
	id: string;
	title: string;
	eyebrow?: string;
	lead?: string;
	align?: SectionAlign;
	width?: SectionWidth;
	band?: boolean;
}
