import {
	BUG_PRIORITY_VALUES,
	BUG_STATUS_VALUES,
	FEATURE_IMPORTANCE_VALUES,
	FEATURE_SIZE_VALUES,
	FEATURE_STATUS_VALUES,
} from "./constants.ts";

export type FiberyNewPromptOptions = {
	cwd: string;
	mode: "infer-kind-with-override";
};

export type FiberyMaintenancePromptOptions = {
	cwd: string;
	mode: "slash-command-only";
};

export function buildFiberyNewPrompt(args: string, options: FiberyNewPromptOptions): string {
	const trimmed = args.trim();
	const initialContext = trimmed ? `\n\nUser provided kickoff context:\n${trimmed}` : "";
	return [
		"Run project Fibery intake workflow.",
		"",
		"Core behavior:",
		"1. Infer kind first: bug or feature.",
		"2. Confirm inferred kind with ask_user override choice.",
		"3. Every user question must use ask_user tool. No plain chat questions.",
		"4. Ask one focused question per ask_user call.",
		"5. For choice prompts, use ask_user options with clear no option when relevant.",
		"",
		"Title workflow:",
		"6. Propose multiple title variants with ask_user options.",
		"7. User must select one title before duplicate check and before create.",
		"8. Run fibery_find_items once title is selected (fuzzy search is supported for rough titles).",
		"9. If duplicates found, show options with ask_user: create new, update existing, or link.",
		"",
		"Description workflow:",
		"10. Write structured description with zero implementation details.",
		"11. Never include fix proposals, technical approach, or architecture plan.",
		"12. Feature sections required: Capability now possible, Problem today, Why this matters, Usage moments, Success signal.",
		"13. Bug sections required: Expected behavior, Actual behavior, Impact, Scope.",
		"14. Show drafted description to user and confirm approval with ask_user before write actions.",
		"",
		"Required fields by kind:",
		"15. Bug requires Priority and Status before create or final update.",
		"16. Feature requires Size, Importance, and Status before create or final update.",
		"17. Ask Discord linking before create or final update for both kinds. Must allow explicit no.",
		"18. Infer domains using repo context and changed paths when possible, then confirm when ambiguous.",
		"",
		"Valid enum values (use these exact strings in ask_user options):",
		"Feature Size: " + FEATURE_SIZE_VALUES.join(", "),
		"Feature Importance: " + FEATURE_IMPORTANCE_VALUES.join(", "),
		"Feature Status: " + FEATURE_STATUS_VALUES.join(", "),
		"Bug Priority: " + BUG_PRIORITY_VALUES.join(", "),
		"Bug Status: " + BUG_STATUS_VALUES.join(", "),
		"",
		"Execution rules:",
		"19. Treat comments as intake notes only. Do not post Fibery comments.",
		"20. Call create, update, and link tools only after explicit user approval.",
		"21. If user asks post create tweaks, run update tools before finish.",
		"22. If related bugs and features should be linked, do linking in same flow.",
		"",
		"Preferred Fibery tools:",
		"- fibery_discover_domains",
		"- fibery_find_items",
		"- fibery_list_current_tasks",
		"- fibery_list_milestones",
		"- fibery_list_recent_betas",
		"- fibery_create_feature",
		"- fibery_create_bug",
		"- fibery_update_feature",
		"- fibery_update_bug",
		"- fibery_link_bug_to_feature",
		"",
		`Working directory: ${options.cwd}`,
		initialContext,
	].join("\n");
}

export type FiberyChangelogPromptOptions = {
	cwd: string;
};

export function buildFiberyChangelogPrompt(args: string, options: FiberyChangelogPromptOptions): string {
	const trimmed = args.trim().toLowerCase();
	const releaseHint =
		trimmed === "beta" || trimmed === "full"
			? trimmed
			: trimmed.includes("full") || trimmed.includes("milestone")
				? "full"
				: trimmed.includes("beta")
					? "beta"
					: "";
	const releaseLine = releaseHint
		? `Release type from command args: ${releaseHint}.`
		: "Release type not specified. Ask the user: beta or full.";
	return [
		"Generate a Discord-ready changelog from Fibery data.",
		"",
		"Follow the project skill at .pi/skills/fibery-changelog/SKILL.md and references/formatting.md.",
		releaseLine,
		"",
		"Workflow:",
		"1. If release type is missing, ask_user: beta vs full.",
		"2. Call fibery_get_changelog_items with the chosen releaseType.",
		"3. Distill user-facing prose from Fibery descriptions. Do not paste intake templates verbatim.",
		"4. Apply formatting rules: features first, bugs second (beta only), :mx: discord-font headings.",
		"5. Write docs/changelog.md in the repo root.",
		"6. Summarize what was included and omitted.",
		"",
		"Preferred tool:",
		"- fibery_get_changelog_items",
		"",
		`Working directory: ${options.cwd}`,
		trimmed && !releaseHint ? `\nUser provided context:\n${args.trim()}` : "",
	].join("\n");
}

export function buildFiberyMaintenancePrompt(args: string, options: FiberyMaintenancePromptOptions): string {
	const trimmed = args.trim();
	const extraScope = trimmed ? `\n\nExtra maintenance scope from user:\n${trimmed}` : "";
	return [
		"Run Fibery maintenance mode for the project-local Pi extension.",
		"",
		"This is not normal intake mode. Audit the hard-coded Fibery integration and produce an update plan.",
		"",
		"Maintenance procedure:",
		"1. Gather live evidence using read-only Fibery tools first.",
		"2. Inspect hard-coded assumptions in the Pi Fibery extension files.",
		"3. Compare type ids, field ids, domains, enum values, milestones, betas, duplicate handling, and linking behavior.",
		"4. Produce a concise drift report with exact proposed file changes.",
		"5. Ask the user for approval before editing any Pi extension files.",
		"6. If approved later, apply the edits and run validation.",
		"",
		"Evidence tools to use:",
		"- fibery_discovery_summary",
		"- fibery_discover_domains",
		"- fibery_list_milestones",
		"- fibery_list_recent_betas",
		"- fibery_refresh_schema_cache",
		"",
		"Files to audit:",
		"- .pi/extensions/fibery/constants.ts",
		"- .pi/extensions/fibery/fibery-client.ts",
		"- .pi/extensions/fibery/tools.ts",
		"- .pi/extensions/fibery/commands.ts",
		"- .pi/extensions/fibery/workflow.ts",
		"",
		`Working directory: ${options.cwd}`,
		extraScope,
	].join("\n");
}
