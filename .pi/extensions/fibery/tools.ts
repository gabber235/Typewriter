import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
	BUG_PRIORITY_VALUES,
	BUG_STATUS_VALUES,
	DOMAIN_OPTIONS,
	FEATURE_IMPORTANCE_VALUES,
	FEATURE_SIZE_VALUES,
	FEATURE_STATUS_VALUES,
} from "./constants.ts";
import {
	createBug,
	createFeature,
	discoverDomains,
	findItems,
	getConfig,
	getDiscoverySummary,
	linkBugToFeature,
	listMilestones,
	listRecentBetas,
	refreshSchemaCache,
	updateBug,
	updateFeature,
} from "./fibery-client.ts";

const CreateBase = {
	title: Type.String({ description: "Item title" }),
	descriptionMarkdown: Type.String({ description: "Markdown description" }),
	milestone: Type.Optional(Type.String({ description: "Milestone name or id. Omit or pass empty to leave blank." })),
	beta: Type.Optional(Type.Union([Type.Number({ description: "Beta identifier such as 171" }), Type.Null()])),
	domains: Type.Optional(Type.Array(stringEnum(DOMAIN_OPTIONS), { description: "Domain names" })),
	discordIds: Type.Optional(Type.Array(Type.String({ description: "Discord entity id" }))),
	discordThreadId: Type.Optional(Type.String({ description: "Discord thread channel id" })),
};

const UpdateBase = {
	idOrName: Type.String({ description: "Fibery entity id or exact item title" }),
	title: Type.Optional(Type.String({ description: "New title" })),
	descriptionMarkdown: Type.Optional(Type.String({ description: "New markdown description" })),
	milestone: Type.Optional(Type.String({ description: "Milestone name or id. Empty clears it." })),
	beta: Type.Optional(Type.Number({ description: "Beta identifier such as 171" })),
	clearMilestone: Type.Optional(Type.Boolean({ description: "Clear milestone relation" })),
	clearBeta: Type.Optional(Type.Boolean({ description: "Clear beta relation" })),
	domains: Type.Optional(Type.Array(stringEnum(DOMAIN_OPTIONS), { description: "Domain names" })),
	discordIds: Type.Optional(Type.Array(Type.String({ description: "Discord entity id" }))),
	discordThreadId: Type.Optional(Type.String({ description: "Discord thread channel id" })),
};

function stringEnum<const T extends readonly string[]>(values: T) {
	return Type.Union(values.map((value) => Type.Literal(value)));
}

function textResult(text: string, details: unknown) {
	return {
		content: [{ type: "text" as const, text }],
		details,
	};
}

export function registerFiberyTools(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "fibery_create_bug",
		label: "Fibery Create Bug",
		description: "Create a Fibery bug with duplicate detection",
		promptSnippet: "Create a Fibery bug after the user confirms the final title and description.",
		parameters: Type.Object({
			...CreateBase,
			status: Type.Optional(stringEnum(BUG_STATUS_VALUES)),
			priority: Type.Optional(stringEnum(BUG_PRIORITY_VALUES)),
			linkedFeatureIdsOrNames: Type.Optional(Type.Array(Type.String({ description: "Linked feature ids or names" }))),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await createBug(config, params);
			return textResult(`Fibery bug create result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_create_feature",
		label: "Fibery Create Feature",
		description: "Create a Fibery feature with duplicate detection",
		promptSnippet: "Create a Fibery feature after the user confirms the final title and description.",
		parameters: Type.Object({
			...CreateBase,
			status: Type.Optional(stringEnum(FEATURE_STATUS_VALUES)),
			size: Type.Optional(stringEnum(FEATURE_SIZE_VALUES)),
			importance: Type.Optional(stringEnum(FEATURE_IMPORTANCE_VALUES)),
			linkedBugIdsOrNames: Type.Optional(Type.Array(Type.String({ description: "Linked bug ids or names" }))),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await createFeature(config, params);
			return textResult(`Fibery feature create result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_update_bug",
		label: "Fibery Update Bug",
		description: "Update a Fibery bug by id or exact name",
		promptSnippet: "Update a Fibery bug when the user wants changes after creation or on an existing item.",
		parameters: Type.Object({
			...UpdateBase,
			status: Type.Optional(stringEnum(BUG_STATUS_VALUES)),
			priority: Type.Optional(stringEnum(BUG_PRIORITY_VALUES)),
			linkedFeatureIdsOrNames: Type.Optional(Type.Array(Type.String({ description: "Linked feature ids or names" }))),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await updateBug(config, params);
			return textResult(`Fibery bug update result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_update_feature",
		label: "Fibery Update Feature",
		description: "Update a Fibery feature by id or exact name",
		promptSnippet: "Update a Fibery feature when the user wants changes after creation or on an existing item.",
		parameters: Type.Object({
			...UpdateBase,
			status: Type.Optional(stringEnum(FEATURE_STATUS_VALUES)),
			size: Type.Optional(stringEnum(FEATURE_SIZE_VALUES)),
			importance: Type.Optional(stringEnum(FEATURE_IMPORTANCE_VALUES)),
			linkedBugIdsOrNames: Type.Optional(Type.Array(Type.String({ description: "Linked bug ids or names" }))),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await updateFeature(config, params);
			return textResult(`Fibery feature update result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_find_items",
		label: "Fibery Find Items",
		description: "Find Fibery bugs or features by exact title",
		promptSnippet: "Look for an existing Fibery bug or feature before creating a duplicate.",
		parameters: Type.Object({
			kind: stringEnum(["bug", "feature"] as const),
			title: Type.String({ description: "Exact title to search" }),
			limit: Type.Optional(Type.Number({ description: "Maximum results to return" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await findItems(config, params.kind, params.title, params.limit ?? 20);
			return textResult(`Fibery find result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_link_bug_to_feature",
		label: "Fibery Link Bug To Feature",
		description: "Link a bug to a feature",
		promptSnippet: "Link a related bug and feature in the same Fibery workflow when the user asks for it.",
		parameters: Type.Object({
			bugIdOrName: Type.String({ description: "Bug id or exact name" }),
			featureIdOrName: Type.String({ description: "Feature id or exact name" }),
			relationField: Type.Optional(Type.String({ description: "Override bug relation field id" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await linkBugToFeature(
				config,
				params.bugIdOrName,
				params.featureIdOrName,
				params.relationField,
			);
			return textResult(`Fibery link result: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_discover_domains",
		label: "Fibery Discover Domains",
		description: "Discover current Fibery domains and infer likely domains from changed paths",
		promptSnippet: "Use Fibery domain discovery when deciding which domains should be assigned.",
		parameters: Type.Object({
			changedPaths: Type.Optional(Type.Array(Type.String({ description: "Changed file path" }))),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await discoverDomains(config, params.changedPaths ?? []);
			return textResult(`Fibery domain discovery: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_list_milestones",
		label: "Fibery List Milestones",
		description: "List available milestones",
		promptSnippet: "List milestones before asking the user to choose one.",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const milestones = await listMilestones(config);
			const result = { count: milestones.length, milestones };
			return textResult(`Fibery milestones: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_list_recent_betas",
		label: "Fibery List Recent Betas",
		description: "List recent betas",
		promptSnippet: "List recent betas before asking the user to choose one.",
		parameters: Type.Object({
			limit: Type.Optional(Type.Number({ description: "How many recent betas to return" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const betas = await listRecentBetas(config, params.limit ?? 5);
			const result = { count: betas.length, betas };
			return textResult(`Fibery recent betas: ${JSON.stringify(result, null, 2)}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_refresh_schema_cache",
		label: "Fibery Refresh Schema Cache",
		description: "Refresh cached Fibery schema used by the extension",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await refreshSchemaCache(config);
			return textResult(`Fibery schema cache refreshed at ${result.refreshedAt}`, result);
		},
	});

	pi.registerTool({
		name: "fibery_discovery_summary",
		label: "Fibery Discovery Summary",
		description: "Get a compact live schema summary for maintenance mode",
		promptSnippet: "Use a compact schema summary before deeper maintenance work.",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
			const config = await getConfig(ctx.cwd);
			const result = await getDiscoverySummary(config);
			return textResult(`Fibery discovery summary: ${JSON.stringify(result, null, 2)}`, result);
		},
	});
}
