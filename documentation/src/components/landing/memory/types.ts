export interface LedgerRow {
	key: string;
	value: string;
	/** Written or changed by this beat; earlier rows are carried over. */
	changed?: boolean;
}

export interface ScriptProps {
	label: string;
}

export interface BeatProps {
	/** Scene heading: "Day 1" and "The forge". */
	when: string;
	where: string;
	speaker: string;
	line: string;
	reply: string;
	remembers: LedgerRow[];
}

export interface RecallItem {
	title: string;
	text: string;
}

export interface RecallProps {
	title: string;
	lead: string;
	items: RecallItem[];
}
