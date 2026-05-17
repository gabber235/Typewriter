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
	const initialContext = trimmed ? `\n\nUser-provided kickoff context:\n${trimmed}` : "";
	return [
		"Run the project Fibery intake workflow.",
		"",
		"Goals:",
		"- Help the user create or refine a Fibery bug or feature for this repository.",
		"- Infer bug vs feature from context, then show a quick override before proceeding.",
		"- Draft title, description, and intake notes instead of making the user write everything manually.",
		"- Use the deterministic Fibery tools only after the important fields are confirmed.",
		"- Support create, update, and link follow-up actions when needed.",
		"",
		"Workflow rules:",
		"1. Start by inferring whether this should be a bug or feature.",
		"2. Immediately present the inferred kind and offer an override.",
		"3. Infer likely domains from the repo context and changed paths when possible.",
		"4. Ask workflow fields separately when they are ambiguous.",
		"5. For bugs, always ask for priority before creation or final update. Priority is required.",
		"6. Always ask about Discord linking before creation or final update, even if there is no obvious thread id yet.",
		"7. The Discord question must allow a clear no option, but it should never be skipped.",
		"8. Treat comments as intake notes only. Do not post Fibery comments.",
		"9. Draft a short markdown description and let the user refine it.",
		"10. Before creation, check for duplicates with fibery_find_items when the title is settled.",
		"11. Only call create/update/link tools after the user has clearly approved the content.",
		"12. If related bugs/features should be linked, do it in the same flow.",
		"13. If the user requests final tweaks after creation, use update tools before finishing.",
		"",
		"Available Fibery tools you should prefer:",
		"- fibery_discover_domains",
		"- fibery_find_items",
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
