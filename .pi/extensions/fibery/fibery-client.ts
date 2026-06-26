import { access, readFile } from "node:fs/promises";
import {
	BETA_PUBLICATION_FIELD,
	BUG_PRIORITY_SORT,
	DEFAULT_STATUS_BY_KIND,
	DOMAIN_ID_BY_NAME,
	FEATURE_IMPORTANCE_SORT,
	MILESTONE_IN_DEVELOPMENT_STATE,
	type DomainName,
	type BugPriority,
	type BugStatus,
	type FeatureImportance,
	type FeatureSize,
	type FeatureStatus,
	type ItemKind,
	RELATED_TYPE_IDS,
	WORKFLOW_FIELD_IDS,
	WORKFLOW_TYPE_IDS,
} from "./constants.ts";

export type JsonValue =
	| string
	| number
	| boolean
	| null
	| JsonValue[]
	| { [key: string]: JsonValue };

export type FiberyConfig = {
	workspace: string;
	token: string;
	maxRetries: number;
	retryDelayMs: number;
};

export type FiberyCommand = {
	command: string;
	args?: Record<string, JsonValue>;
};

export type BaseCreateArgs = {
	title: string;
	descriptionMarkdown: string;
	milestone?: string;
	beta?: number | null;
	domains?: DomainName[];
	discordIds?: string[];
	discordThreadId?: string;
};

export type CreateBugArgs = BaseCreateArgs & {
	status?: BugStatus;
	priority?: BugPriority;
	linkedFeatureIdsOrNames?: string[];
};

export type CreateFeatureArgs = BaseCreateArgs & {
	status?: FeatureStatus;
	size?: FeatureSize;
	importance?: FeatureImportance;
	linkedBugIdsOrNames?: string[];
};

export type BaseUpdateArgs = {
	idOrName: string;
	title?: string;
	descriptionMarkdown?: string;
	milestone?: string;
	beta?: number;
	clearMilestone?: boolean;
	clearBeta?: boolean;
	domains?: DomainName[];
	discordIds?: string[];
	discordThreadId?: string;
};

export type UpdateBugArgs = BaseUpdateArgs & {
	status?: BugStatus;
	priority?: BugPriority;
	linkedFeatureIdsOrNames?: string[];
};

export type UpdateFeatureArgs = BaseUpdateArgs & {
	status?: FeatureStatus;
	size?: FeatureSize;
	importance?: FeatureImportance;
	linkedBugIdsOrNames?: string[];
};

type BaseMapping = {
	kind: ItemKind;
	typeId: string;
	nameField: string;
	statusField: string;
	descriptionField: string;
	milestoneField: string;
	betaField: string;
	domainsField: string;
	discordsField: string;
	linksField: string;
	fieldTypes: Record<string, string>;
};

type BugMapping = BaseMapping & {
	kind: "bug";
	priorityField: string;
};

type FeatureMapping = BaseMapping & {
	kind: "feature";
	sizeField: string;
	importanceField: string;
};

export type TypeMapping = BugMapping | FeatureMapping;

export type FindItemsResult = {
	kind: ItemKind;
	type: string;
	count: number;
	items: Array<{ id: string; title: string; score: number; isExact: boolean; raw: Record<string, unknown> }>;
};

export type CurrentTaskItem = {
	kind: ItemKind;
	id: string;
	title: string;
	status: string;
	milestoneName: string | null;
	milestoneState: string | null;
};

export type CurrentTasksResult = {
	count: number;
	items: CurrentTaskItem[];
	filters: {
		excludedStatuses: string[];
		includedMilestoneState: string;
	};
};

export type LinkedResult = {
	action: "linked";
	bugId: string;
	featureId: string;
	relationField: string;
	result: unknown;
};

export type DiscoverySummary = {
	source: "cache" | "api";
	typeCount: number;
	featureType: {
		id: string;
		displayName: string;
		fieldCount: number;
	};
	bugType: {
		id: string;
		displayName: string;
		fieldCount: number;
	};
};

let schemaCache: unknown | null = null;
let schemaCachedAt = 0;
const schemaTtlMs = 5 * 60 * 1000;

function parseDotEnv(content: string): Record<string, string> {
	const parsed: Record<string, string> = {};
	for (const line of content.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed || trimmed.startsWith("#")) continue;
		const separator = trimmed.indexOf("=");
		if (separator <= 0) continue;
		const key = trimmed.slice(0, separator).trim();
		const value = trimmed.slice(separator + 1).trim();
		if (key) parsed[key] = value;
	}
	return parsed;
}

async function loadDotEnv(cwd: string): Promise<Record<string, string>> {
	const path = `${cwd}/.env`;
	try {
		await access(path);
		return parseDotEnv(await readFile(path, "utf8"));
	} catch {
		return {};
	}
}

async function getEnv(name: string, cwd: string): Promise<string> {
	const direct = String(process.env[name] ?? "").trim();
	if (direct) return direct;
	const env = await loadDotEnv(cwd);
	return String(env[name] ?? "").trim();
}

async function required(name: string, cwd: string): Promise<string> {
	const value = await getEnv(name, cwd);
	if (!value) throw new Error(`Missing required environment variable: ${name}`);
	return value;
}

export async function getConfig(cwd: string): Promise<FiberyConfig> {
	return {
		workspace: await required("FIBERY_WORKSPACE", cwd),
		token: await required("FIBERY_API_TOKEN", cwd),
		maxRetries: Number((await getEnv("FIBERY_MAX_RETRIES", cwd)) || "3"),
		retryDelayMs: Number((await getEnv("FIBERY_RETRY_DELAY_MS", cwd)) || "400"),
	};
}

function normalizeWorkspace(workspace: string): string {
	const normalized = workspace.replace(/^https?:\/\//, "").replace(/\/$/, "");
	if (normalized.includes(".")) return normalized;
	return `${normalized}.fibery.io`;
}

function commandUrl(workspace: string): string {
	return `https://${normalizeWorkspace(workspace)}/api/commands`;
}

async function wait(ms: number): Promise<void> {
	await new Promise((resolve) => setTimeout(resolve, ms));
}

export async function executeCommand<T = unknown>(
	config: FiberyConfig,
	payload: FiberyCommand,
): Promise<T> {
	let attempt = 0;
	while (attempt <= config.maxRetries) {
		const response = await fetch(commandUrl(config.workspace), {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Token ${config.token}`,
			},
			body: JSON.stringify([payload]),
		});

		if (response.status === 429 && attempt < config.maxRetries) {
			await wait(config.retryDelayMs * Math.pow(2, attempt));
			attempt += 1;
			continue;
		}

		const text = await response.text();
		let parsed: unknown = null;
		try {
			parsed = text ? JSON.parse(text) : null;
		} catch {
			parsed = { raw: text };
		}

		if (!response.ok) {
			throw new Error(`Fibery request failed (${response.status}): ${JSON.stringify(parsed)}`);
		}

		const first = Array.isArray(parsed) ? parsed[0] : parsed;
		if (first && typeof first === "object" && "success" in first) {
			const record = first as Record<string, unknown>;
			if (record.success === false) {
				throw new Error(`Fibery command failed: ${JSON.stringify(record)}`);
			}
			if ("result" in record) {
				return record.result as T;
			}
		}

		return first as T;
	}

	throw new Error("Fibery request failed after retries");
}

function asRecord(value: unknown): Record<string, unknown> {
	return value && typeof value === "object" ? (value as Record<string, unknown>) : {};
}

function extractTypes(schema: unknown): Array<Record<string, unknown>> {
	const root = asRecord(schema);
	const result = asRecord(root.result);
	for (const candidate of [root["fibery/types"], result["fibery/types"], root.types, result.types]) {
		if (Array.isArray(candidate)) return candidate.map(asRecord);
	}
	return [];
}

function extractFields(typeObject: Record<string, unknown>): Array<Record<string, unknown>> {
	for (const candidate of [typeObject["fibery/fields"], typeObject.fields]) {
		if (Array.isArray(candidate)) return candidate.map(asRecord);
	}
	return [];
}

function typeIdentifier(typeObject: Record<string, unknown>): string {
	return String(typeObject["fibery/name"] ?? typeObject["fibery/id"] ?? "");
}

function typeDisplayName(typeObject: Record<string, unknown>): string {
	return String(typeObject["fibery/display-name"] ?? typeObject["fibery/name"] ?? typeIdentifier(typeObject));
}

function fieldIdentifier(fieldObject: Record<string, unknown>): string {
	return String(fieldObject["fibery/name"] ?? fieldObject["fibery/id"] ?? "");
}

function fieldTypeById(fields: Array<Record<string, unknown>>): Record<string, string> {
	const result: Record<string, string> = {};
	for (const field of fields) {
		const id = fieldIdentifier(field);
		if (!id) continue;
		result[id] = String(field["fibery/type"] ?? field.type ?? "");
	}
	return result;
}

export async function getSchema(config: FiberyConfig, forceRefresh = false): Promise<unknown> {
	const fresh = !forceRefresh && schemaCache && Date.now() - schemaCachedAt < schemaTtlMs;
	if (fresh) return schemaCache;
	const schema = await executeCommand(config, {
		command: "fibery.schema/query",
		args: { "with-description?": false },
	});
	schemaCache = schema;
	schemaCachedAt = Date.now();
	return schema;
}

export async function refreshSchemaCache(config: FiberyConfig): Promise<{ refreshedAt: string }> {
	await getSchema(config, true);
	return { refreshedAt: new Date(schemaCachedAt).toISOString() };
}

export async function resolveTypeMapping(config: FiberyConfig, kind: ItemKind): Promise<TypeMapping> {
	const schema = await getSchema(config, false);
	const types = extractTypes(schema);
	const hardcodedTypeId = WORKFLOW_TYPE_IDS[kind];
	const hardcodedFields = WORKFLOW_FIELD_IDS[kind];
	const typeObject = types.find((candidate) => typeIdentifier(candidate) === hardcodedTypeId);
	if (!typeObject) {
		throw new Error(`Could not resolve hardcoded ${kind} type '${hardcodedTypeId}'`);
	}
	const fields = extractFields(typeObject);
	const fieldTypes = fieldTypeById(fields);
	if (kind === "bug") {
		return {
			kind,
			typeId: typeIdentifier(typeObject),
			nameField: hardcodedFields.nameField,
			statusField: hardcodedFields.statusField,
			priorityField: hardcodedFields.priorityField,
			descriptionField: hardcodedFields.descriptionField,
			milestoneField: hardcodedFields.milestoneField,
			betaField: hardcodedFields.betaField,
			domainsField: hardcodedFields.domainsField,
			discordsField: hardcodedFields.discordsField,
			linksField: hardcodedFields.linksField,
			fieldTypes,
		};
	}
	return {
		kind,
		typeId: typeIdentifier(typeObject),
		nameField: hardcodedFields.nameField,
		statusField: hardcodedFields.statusField,
		sizeField: hardcodedFields.sizeField,
		importanceField: hardcodedFields.importanceField,
		descriptionField: hardcodedFields.descriptionField,
		milestoneField: hardcodedFields.milestoneField,
		betaField: hardcodedFields.betaField,
		domainsField: hardcodedFields.domainsField,
		discordsField: hardcodedFields.discordsField,
		linksField: hardcodedFields.linksField,
		fieldTypes,
	};
}

function sanitizeMarkdown(text: string): string {
	return text.replace(/\r\n/g, "\n").trim();
}

function uniqueIds<T>(values: T[]): T[] {
	return [...new Set(values)];
}

function validateEntityIds(ids: string[] | undefined, fieldName: string): string[] {
	if (!ids) return [];
	const cleaned = ids.map((value) => value.trim()).filter(Boolean);
	for (const id of cleaned) {
		if (!isUuid(id)) throw new Error(`${fieldName} must contain Fibery entity ids. Invalid value: ${id}`);
	}
	return uniqueIds(cleaned);
}

function isUuid(value: string): boolean {
	return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function primaryId(entity: Record<string, unknown>): string {
	return String(entity["fibery/id"] ?? "");
}

function entityName(entity: Record<string, unknown>, nameField: string): string {
	return String(entity[nameField] ?? entity[RELATED_TYPE_IDS.nameField] ?? "");
}

async function queryTypeRecords(
	config: FiberyConfig,
	typeId: string,
	select: Record<string, string>,
	limit: number,
): Promise<Array<Record<string, unknown>>> {
	const result = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": typeId,
				"q/select": select,
				"q/limit": limit,
			},
		},
	});
	return Array.isArray(result) ? result.map(asRecord) : [];
}

function normalizeForSearch(value: string): string {
	return value.toLowerCase().trim().replace(/\s+/g, " ");
}

function levenshteinDistance(a: string, b: string): number {
	const al = a.length;
	const bl = b.length;
	if (al === 0) return bl;
	if (bl === 0) return al;
	const dp = Array.from({ length: al + 1 }, (_, i) => [i]);
	for (let j = 1; j <= bl; j += 1) dp[0][j] = j;
	for (let i = 1; i <= al; i += 1) {
		for (let j = 1; j <= bl; j += 1) {
			const cost = a[i - 1] === b[j - 1] ? 0 : 1;
			dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost);
		}
	}
	return dp[al][bl];
}

function scoreNameMatch(queryRaw: string, candidateRaw: string): { score: number; isExact: boolean } {
	const query = normalizeForSearch(queryRaw);
	const candidate = normalizeForSearch(candidateRaw);
	if (!query || !candidate) return { score: 0, isExact: false };
	if (query === candidate) return { score: 1, isExact: true };

	const queryTokens = query.split(" ").filter(Boolean);
	const candidateTokens = candidate.split(" ").filter(Boolean);
	const queryTokenSet = new Set(queryTokens);
	const candidateTokenSet = new Set(candidateTokens);
	const overlap = [...queryTokenSet].filter((token) => candidateTokenSet.has(token)).length;
	const tokenScore = queryTokenSet.size > 0 ? overlap / queryTokenSet.size : 0;
	const substringScore = candidate.includes(query) || query.includes(candidate) ? 1 : 0;
	const distance = levenshteinDistance(query, candidate);
	const maxLen = Math.max(query.length, candidate.length);
	const editScore = maxLen > 0 ? 1 - distance / maxLen : 0;
	const score = Math.max(0, Math.min(0.55 * tokenScore + 0.25 * substringScore + 0.2 * editScore, 0.999));
	return { score, isExact: false };
}

type RankedEntity = { entity: Record<string, unknown>; score: number; isExact: boolean };

async function queryByNameRanked(
	config: FiberyConfig,
	mapping: TypeMapping,
	title: string,
	limit = 10,
	minScore = 0.35,
): Promise<RankedEntity[]> {
	const rows = await queryTypeRecords(
		config,
		mapping.typeId,
		{
			"fibery/id": "fibery/id",
			[mapping.nameField]: mapping.nameField,
		},
		Math.max(limit * 25, 750),
	);
	const ranked = rows
		.map((entity) => {
			const match = scoreNameMatch(title, entityName(entity, mapping.nameField));
			return { entity, score: match.score, isExact: match.isExact };
		})
		.filter((entry) => entry.isExact || entry.score >= minScore)
		.sort((a, b) => {
			if (b.score !== a.score) return b.score - a.score;
			return entityName(a.entity, mapping.nameField).localeCompare(entityName(b.entity, mapping.nameField));
		});
	return ranked.slice(0, limit);
}

async function queryByNameExact(
	config: FiberyConfig,
	mapping: TypeMapping,
	title: string,
	limit = 10,
): Promise<Array<Record<string, unknown>>> {
	const ranked = await queryByNameRanked(config, mapping, title, Math.max(limit * 2, 20), 0);
	return ranked
		.filter((entry) => entry.isExact)
		.slice(0, limit)
		.map((entry) => entry.entity);
}

async function resolveEntityIdsByName(
	config: FiberyConfig,
	typeId: string,
	nameField: string,
	values: string[],
): Promise<string[]> {
	const ids = validateEntityIds(values.filter(isUuid), "ids");
	const names = values.map((value) => value.trim()).filter((value) => value && !isUuid(value));
	if (names.length === 0) return uniqueIds(ids);
	const rows = await queryTypeRecords(config, typeId, { "fibery/id": "fibery/id", [nameField]: nameField }, 2000);
	const matches = rows.filter((row) => names.includes(String(row[nameField] ?? ""))).map(primaryId).filter(Boolean);
	return uniqueIds([...ids, ...matches]);
}

function normalizeEnumLabel(enumTypeId: string, label: string): string {
	const normalized = label.trim();
	if (enumTypeId === "workflow/state_Development/Bugs" && normalized.toLowerCase() === "done") {
		return "Fixed";
	}
	return normalized;
}

async function resolveEnumOptionId(config: FiberyConfig, enumTypeId: string, label: string): Promise<string> {
	const rows = await queryTypeRecords(
		config,
		enumTypeId,
		{
			"fibery/id": "fibery/id",
			"enum/name": "enum/name",
		},
		500,
	);
	const target = normalizeEnumLabel(enumTypeId, label).toLowerCase();
	const match = rows.find((row) => String(row["enum/name"] ?? "").trim().toLowerCase() === target);
	if (!match) {
		const available = rows
			.map((row) => String(row["enum/name"] ?? "").trim())
			.filter((name) => name.length > 0);
		throw new Error(`Unknown value '${label}' for ${enumTypeId}. Allowed values: ${available.join(", ")}`);
	}
	return primaryId(match);
}

async function getDocumentSecret(
	config: FiberyConfig,
	typeId: string,
	entityId: string,
	field: string,
): Promise<string> {
	const result = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": typeId,
				"q/select": ["fibery/id", { [field]: ["Collaboration~Documents/secret"] }],
				"q/where": ["=", ["fibery/id"], "$id"],
				"q/limit": 1,
			},
			params: {
				$id: entityId,
			},
		},
	});
	if (!Array.isArray(result) || result.length === 0) {
		throw new Error(`Entity not found while reading document secret: ${entityId}`);
	}
	const row = asRecord(result[0]);
	const document = asRecord(row[field]);
	const secret = String(document["Collaboration~Documents/secret"] ?? document.secret ?? document["q/secret"] ?? "");
	if (!secret) throw new Error(`Could not resolve document secret for ${field}`);
	return secret;
}

async function writeDocumentMarkdown(config: FiberyConfig, secret: string, markdown: string): Promise<void> {
	let attempt = 0;
	while (attempt <= config.maxRetries) {
		const response = await fetch(`https://${normalizeWorkspace(config.workspace)}/api/documents/${secret}?format=md`, {
			method: "PUT",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Token ${config.token}`,
			},
			body: JSON.stringify({ content: sanitizeMarkdown(markdown) }),
		});
		if (response.status === 429 && attempt < config.maxRetries) {
			await wait(config.retryDelayMs * Math.pow(2, attempt));
			attempt += 1;
			continue;
		}
		if (!response.ok) {
			throw new Error(`Failed to update document (${response.status}): ${await response.text()}`);
		}
		return;
	}
	throw new Error("Failed to update document after retries");
}

async function setCollectionField(
	config: FiberyConfig,
	typeId: string,
	entityId: string,
	field: string,
	itemIds: string[],
): Promise<void> {
	await executeCommand(config, {
		command: "fibery.entity/set-collection-items",
		args: {
			type: typeId,
			field,
			entity: { "fibery/id": entityId },
			items: itemIds.map((id) => ({ "fibery/id": id })),
		},
	});
}

function mapDomainNamesToIds(domains: DomainName[] | undefined): string[] {
	if (!domains) return [];
	return uniqueIds(domains.map((domain) => DOMAIN_ID_BY_NAME[domain]));
}

async function listMilestonesInternal(config: FiberyConfig): Promise<Array<{ id: string; name: string }>> {
	const rows = await queryTypeRecords(
		config,
		RELATED_TYPE_IDS.milestone,
		{
			"fibery/id": "fibery/id",
			[RELATED_TYPE_IDS.milestoneNameField]: RELATED_TYPE_IDS.milestoneNameField,
		},
		500,
	);
	return rows
		.map((row) => ({ id: primaryId(row), name: String(row[RELATED_TYPE_IDS.milestoneNameField] ?? "") }))
		.filter((row) => row.id && row.name)
		.sort((a, b) => a.name.localeCompare(b.name));
}

export async function listMilestones(config: FiberyConfig): Promise<Array<{ id: string; name: string }>> {
	return listMilestonesInternal(config);
}

export type RecentBeta = {
	id: string;
	name: string;
	identifier: number;
	published: boolean;
	publicationDate: string | null;
};

export async function listRecentBetas(config: FiberyConfig, limit: number): Promise<RecentBeta[]> {
	const rows = await queryTypeRecords(
		config,
		RELATED_TYPE_IDS.beta,
		{
			"fibery/id": "fibery/id",
			[RELATED_TYPE_IDS.milestoneNameField]: RELATED_TYPE_IDS.milestoneNameField,
			[RELATED_TYPE_IDS.betaIdentifierField]: RELATED_TYPE_IDS.betaIdentifierField,
			[BETA_PUBLICATION_FIELD]: BETA_PUBLICATION_FIELD,
		},
		1000,
	);
	return rows
		.map((row) => {
			const publicationDate = row[BETA_PUBLICATION_FIELD];
			const publication =
				publicationDate === null || publicationDate === undefined
					? null
					: String(publicationDate);
			return {
				id: primaryId(row),
				name: String(row[RELATED_TYPE_IDS.milestoneNameField] ?? ""),
				identifier: Number(row[RELATED_TYPE_IDS.betaIdentifierField] ?? 0),
				published: publication !== null,
				publicationDate: publication,
			};
		})
		.filter((row) => row.id && Number.isFinite(row.identifier) && row.identifier > 0)
		.sort((a, b) => b.identifier - a.identifier)
		.slice(0, Math.max(1, Math.min(20, Math.floor(limit))));
}

async function resolveBetaIdByIdentifier(config: FiberyConfig, identifier: number): Promise<string> {
	const rows = await listRecentBetas(config, 1000);
	const match = rows.find((row) => row.identifier === identifier);
	if (!match) throw new Error(`Could not resolve beta with identifier ${identifier}`);
	return match.id;
}

async function upsertDiscordThread(config: FiberyConfig, threadId: string): Promise<string> {
	const normalized = threadId.trim();
	if (!normalized) throw new Error("discordThreadId must not be empty");
	const rows = await queryTypeRecords(
		config,
		RELATED_TYPE_IDS.discord,
		{
			"fibery/id": "fibery/id",
			[RELATED_TYPE_IDS.discordChannelIdField]: RELATED_TYPE_IDS.discordChannelIdField,
		},
		2000,
	);
	const existing = rows.find(
		(row) => String(row[RELATED_TYPE_IDS.discordChannelIdField] ?? "") === normalized,
	);
	if (existing) return primaryId(existing);
	const created = await executeCommand<Record<string, unknown>>(config, {
		command: "fibery.entity/create",
		args: {
			type: RELATED_TYPE_IDS.discord,
			entity: {
				[RELATED_TYPE_IDS.nameField]: `Thread ${normalized}`,
				[RELATED_TYPE_IDS.discordChannelIdField]: normalized,
			},
		},
	});
	return primaryId(asRecord(created));
}

async function createItemInternal(kind: "bug", config: FiberyConfig, args: CreateBugArgs): Promise<unknown>;
async function createItemInternal(
	kind: "feature",
	config: FiberyConfig,
	args: CreateFeatureArgs,
): Promise<unknown>;
async function createItemInternal(kind: ItemKind, config: FiberyConfig, args: CreateBugArgs | CreateFeatureArgs) {
	const mapping = await resolveTypeMapping(config, kind);
	const title = args.title.trim();
	if (!title) throw new Error("title must not be empty");
	if (!sanitizeMarkdown(args.descriptionMarkdown)) {
		throw new Error("descriptionMarkdown must not be empty");
	}
	const existing = await queryByNameExact(config, mapping, title, 10);
	if (existing.length > 0) {
		return {
			action: "duplicate_detected",
			message: "Matching item already exists. Creation is blocked.",
			matches: existing.map((entity) => ({ id: primaryId(entity), title: entityName(entity, mapping.nameField) })),
		};
	}

	const entity: Record<string, JsonValue> = { [mapping.nameField]: title };
	const statusValue = (args as CreateBugArgs).status || (args as CreateFeatureArgs).status || DEFAULT_STATUS_BY_KIND[kind];
	const statusTypeId = mapping.fieldTypes[mapping.statusField] ?? "";
	if (!statusTypeId) throw new Error(`Could not resolve enum type for ${mapping.statusField}`);
	entity[mapping.statusField] = { "fibery/id": await resolveEnumOptionId(config, statusTypeId, statusValue) };

	if (kind === "bug" && (args as CreateBugArgs).priority) {
		const priorityTypeId = mapping.fieldTypes[mapping.priorityField] ?? "";
		if (!priorityTypeId) throw new Error(`Could not resolve enum type for ${mapping.priorityField}`);
		entity[mapping.priorityField] = {
			"fibery/id": await resolveEnumOptionId(config, priorityTypeId, (args as CreateBugArgs).priority!),
		};
	}

	if (kind === "feature") {
		const featureArgs = args as CreateFeatureArgs;
		if (featureArgs.size) {
			const sizeTypeId = mapping.fieldTypes[mapping.sizeField] ?? "";
			if (!sizeTypeId) throw new Error(`Could not resolve enum type for ${mapping.sizeField}`);
			entity[mapping.sizeField] = { "fibery/id": await resolveEnumOptionId(config, sizeTypeId, featureArgs.size) };
		}
		if (featureArgs.importance) {
			const importanceTypeId = mapping.fieldTypes[mapping.importanceField] ?? "";
			if (!importanceTypeId) throw new Error(`Could not resolve enum type for ${mapping.importanceField}`);
			entity[mapping.importanceField] = {
				"fibery/id": await resolveEnumOptionId(config, importanceTypeId, featureArgs.importance),
			};
		}
	}

	const shouldClearMilestoneAfterCreate = args.milestone === undefined || args.milestone.trim().length === 0;
	const betaIdentifier = args.beta ?? undefined;
	const shouldClearBetaAfterCreate = betaIdentifier === undefined;

	if (args.milestone && args.milestone.trim()) {
		const milestoneIds = await resolveEntityIdsByName(
			config,
			RELATED_TYPE_IDS.milestone,
			RELATED_TYPE_IDS.milestoneNameField,
			[args.milestone],
		);
		if (milestoneIds.length > 0) entity[mapping.milestoneField] = { "fibery/id": milestoneIds[0] };
	}
	if (betaIdentifier !== undefined) {
		entity[mapping.betaField] = { "fibery/id": await resolveBetaIdByIdentifier(config, betaIdentifier) };
	}

	const created = await executeCommand<Record<string, unknown>>(config, {
		command: "fibery.entity/create",
		args: { type: mapping.typeId, entity },
	});
	const createdId = primaryId(asRecord(created));
	if (!createdId) throw new Error("Failed to extract created entity id");

	if (shouldClearMilestoneAfterCreate || shouldClearBetaAfterCreate) {
		const clearEntity: Record<string, JsonValue> = { "fibery/id": createdId };
		if (shouldClearMilestoneAfterCreate) clearEntity[mapping.milestoneField] = null;
		if (shouldClearBetaAfterCreate) clearEntity[mapping.betaField] = null;
		await executeCommand(config, {
			command: "fibery.entity/update",
			args: { type: mapping.typeId, entity: clearEntity },
		});
	}

	const descriptionType = mapping.fieldTypes[mapping.descriptionField] ?? "";
	if (!descriptionType.toLowerCase().includes("document")) {
		throw new Error(`Expected document field for ${mapping.descriptionField}`);
	}
	const secret = await getDocumentSecret(config, mapping.typeId, createdId, mapping.descriptionField);
	await writeDocumentMarkdown(config, secret, args.descriptionMarkdown);

	if (args.domains) {
		await setCollectionField(config, mapping.typeId, createdId, mapping.domainsField, mapDomainNamesToIds(args.domains));
	}

	const explicitDiscordIds = validateEntityIds(args.discordIds, "discordIds");
	const threadDiscordIds = args.discordThreadId ? [await upsertDiscordThread(config, args.discordThreadId)] : [];
	const discordIds = uniqueIds([...explicitDiscordIds, ...threadDiscordIds]);
	if (discordIds.length > 0) {
		await setCollectionField(config, mapping.typeId, createdId, mapping.discordsField, discordIds);
	}

	if (kind === "bug" && (args as CreateBugArgs).linkedFeatureIdsOrNames) {
		const linkIds = await resolveEntityIdsByName(
			config,
			WORKFLOW_TYPE_IDS.feature,
			RELATED_TYPE_IDS.nameField,
			(args as CreateBugArgs).linkedFeatureIdsOrNames!,
		);
		await setCollectionField(config, mapping.typeId, createdId, mapping.linksField, linkIds);
	}
	if (kind === "feature" && (args as CreateFeatureArgs).linkedBugIdsOrNames) {
		const linkIds = await resolveEntityIdsByName(
			config,
			WORKFLOW_TYPE_IDS.bug,
			RELATED_TYPE_IDS.nameField,
			(args as CreateFeatureArgs).linkedBugIdsOrNames!,
		);
		await setCollectionField(config, mapping.typeId, createdId, mapping.linksField, linkIds);
	}

	return { action: "created", kind, type: mapping.typeId, title, id: createdId };
}

export async function createBug(config: FiberyConfig, args: CreateBugArgs): Promise<unknown> {
	return createItemInternal("bug", config, args);
}

export async function createFeature(config: FiberyConfig, args: CreateFeatureArgs): Promise<unknown> {
	return createItemInternal("feature", config, args);
}

async function resolveTargetEntity(
	config: FiberyConfig,
	kind: ItemKind,
	idOrName: string,
): Promise<{ mapping: TypeMapping; id: string; matches?: Array<{ id: string; title: string }> }> {
	const mapping = await resolveTypeMapping(config, kind);
	const normalized = idOrName.trim();
	if (!normalized) throw new Error("idOrName must not be empty");
	if (isUuid(normalized)) return { mapping, id: normalized };
	const matches = await queryByNameRanked(config, mapping, normalized, 20);
	if (matches.length === 0) throw new Error(`No ${kind} found with name: ${normalized}`);
	if (matches.length > 1) {
		return {
			mapping,
			id: "",
			matches: matches.map((entry) => ({ id: primaryId(entry.entity), title: entityName(entry.entity, mapping.nameField) })),
		};
	}
	return { mapping, id: primaryId(matches[0].entity) };
}

async function updateItemInternal(kind: "bug", config: FiberyConfig, args: UpdateBugArgs): Promise<unknown>;
async function updateItemInternal(
	kind: "feature",
	config: FiberyConfig,
	args: UpdateFeatureArgs,
): Promise<unknown>;
async function updateItemInternal(kind: ItemKind, config: FiberyConfig, args: UpdateBugArgs | UpdateFeatureArgs) {
	const target = await resolveTargetEntity(config, kind, args.idOrName);
	if (!target.id && target.matches) {
		return {
			action: "needs_disambiguation",
			message: `Multiple ${kind}s match '${args.idOrName}'. Provide an id.`,
			matches: target.matches,
		};
	}
	const { mapping, id } = target;
	const entity: Record<string, JsonValue> = { "fibery/id": id };

	if (args.title?.trim()) entity[mapping.nameField] = args.title.trim();
	if (args.status) {
		const statusTypeId = mapping.fieldTypes[mapping.statusField] ?? "";
		if (!statusTypeId) throw new Error(`Could not resolve enum type for ${mapping.statusField}`);
		entity[mapping.statusField] = { "fibery/id": await resolveEnumOptionId(config, statusTypeId, args.status) };
	}
	if (kind === "bug" && (args as UpdateBugArgs).priority) {
		const priorityTypeId = mapping.fieldTypes[mapping.priorityField] ?? "";
		if (!priorityTypeId) throw new Error(`Could not resolve enum type for ${mapping.priorityField}`);
		entity[mapping.priorityField] = {
			"fibery/id": await resolveEnumOptionId(config, priorityTypeId, (args as UpdateBugArgs).priority!),
		};
	}
	if (kind === "feature") {
		const featureArgs = args as UpdateFeatureArgs;
		if (featureArgs.size) {
			const sizeTypeId = mapping.fieldTypes[mapping.sizeField] ?? "";
			if (!sizeTypeId) throw new Error(`Could not resolve enum type for ${mapping.sizeField}`);
			entity[mapping.sizeField] = { "fibery/id": await resolveEnumOptionId(config, sizeTypeId, featureArgs.size) };
		}
		if (featureArgs.importance) {
			const importanceTypeId = mapping.fieldTypes[mapping.importanceField] ?? "";
			if (!importanceTypeId) {
				throw new Error(`Could not resolve enum type for ${mapping.importanceField}`);
			}
			entity[mapping.importanceField] = {
				"fibery/id": await resolveEnumOptionId(config, importanceTypeId, featureArgs.importance),
			};
		}
	}

	if (args.clearMilestone) {
		entity[mapping.milestoneField] = null;
	} else if (args.milestone !== undefined) {
		const milestoneValue = args.milestone.trim();
		if (!milestoneValue) {
			entity[mapping.milestoneField] = null;
		} else {
			const milestoneIds = await resolveEntityIdsByName(
				config,
				RELATED_TYPE_IDS.milestone,
				RELATED_TYPE_IDS.milestoneNameField,
				[milestoneValue],
			);
			entity[mapping.milestoneField] = milestoneIds.length > 0 ? { "fibery/id": milestoneIds[0] } : null;
		}
	}

	if (args.clearBeta) {
		entity[mapping.betaField] = null;
	} else if (args.beta !== undefined) {
		entity[mapping.betaField] = { "fibery/id": await resolveBetaIdByIdentifier(config, args.beta) };
	}

	await executeCommand(config, {
		command: "fibery.entity/update",
		args: { type: mapping.typeId, entity },
	});

	if (args.descriptionMarkdown !== undefined) {
		const secret = await getDocumentSecret(config, mapping.typeId, id, mapping.descriptionField);
		await writeDocumentMarkdown(config, secret, args.descriptionMarkdown);
	}
	if (args.domains) {
		await setCollectionField(config, mapping.typeId, id, mapping.domainsField, mapDomainNamesToIds(args.domains));
	}
	const explicitDiscordIds = validateEntityIds(args.discordIds, "discordIds");
	const threadDiscordIds = args.discordThreadId ? [await upsertDiscordThread(config, args.discordThreadId)] : [];
	const discordIds = uniqueIds([...explicitDiscordIds, ...threadDiscordIds]);
	if (args.discordIds || args.discordThreadId) {
		await setCollectionField(config, mapping.typeId, id, mapping.discordsField, discordIds);
	}
	if (kind === "bug" && (args as UpdateBugArgs).linkedFeatureIdsOrNames) {
		const linkIds = await resolveEntityIdsByName(
			config,
			WORKFLOW_TYPE_IDS.feature,
			RELATED_TYPE_IDS.nameField,
			(args as UpdateBugArgs).linkedFeatureIdsOrNames!,
		);
		await setCollectionField(config, mapping.typeId, id, mapping.linksField, linkIds);
	}
	if (kind === "feature" && (args as UpdateFeatureArgs).linkedBugIdsOrNames) {
		const linkIds = await resolveEntityIdsByName(
			config,
			WORKFLOW_TYPE_IDS.bug,
			RELATED_TYPE_IDS.nameField,
			(args as UpdateFeatureArgs).linkedBugIdsOrNames!,
		);
		await setCollectionField(config, mapping.typeId, id, mapping.linksField, linkIds);
	}

	return { action: "updated", kind, type: mapping.typeId, id };
}

export async function updateBug(config: FiberyConfig, args: UpdateBugArgs): Promise<unknown> {
	return updateItemInternal("bug", config, args);
}

export async function updateFeature(config: FiberyConfig, args: UpdateFeatureArgs): Promise<unknown> {
	return updateItemInternal("feature", config, args);
}

async function resolveBugFeatureRelationField(
	bugMapping: TypeMapping,
	featureTypeId: string,
): Promise<string | null> {
	if (bugMapping.kind !== "bug") return null;
	const hardcoded = WORKFLOW_FIELD_IDS.bug.linksField;
	if (bugMapping.fieldTypes[hardcoded] === featureTypeId) return hardcoded;
	for (const [fieldId, fieldType] of Object.entries(bugMapping.fieldTypes)) {
		if (fieldType === featureTypeId) return fieldId;
	}
	return null;
}

export async function linkBugToFeature(
	config: FiberyConfig,
	bugIdOrName: string,
	featureIdOrName: string,
	relationField?: string,
): Promise<LinkedResult | { action: "needs_disambiguation"; message: string; matches: unknown[] }> {
	const bugTarget = await resolveTargetEntity(config, "bug", bugIdOrName);
	if (!bugTarget.id && bugTarget.matches) {
		return {
			action: "needs_disambiguation",
			message: `Multiple bugs match '${bugIdOrName}'. Provide bug id.`,
			matches: bugTarget.matches,
		};
	}
	const featureTarget = await resolveTargetEntity(config, "feature", featureIdOrName);
	if (!featureTarget.id && featureTarget.matches) {
		return {
			action: "needs_disambiguation",
			message: `Multiple features match '${featureIdOrName}'. Provide feature id.`,
			matches: featureTarget.matches,
		};
	}
	const resolvedField = relationField || (await resolveBugFeatureRelationField(bugTarget.mapping, featureTarget.mapping.typeId));
	if (!resolvedField) {
		throw new Error("relationField is required. Hardcoded mapping was not found on the bug type.");
	}
	const result = await executeCommand(config, {
		command: "fibery.entity/add-collection-items",
		args: {
			type: bugTarget.mapping.typeId,
			field: resolvedField,
			entity: { "fibery/id": bugTarget.id },
			items: [{ "fibery/id": featureTarget.id }],
		},
	});
	return {
		action: "linked",
		bugId: bugTarget.id,
		featureId: featureTarget.id,
		relationField: resolvedField,
		result,
	};
}

export async function findItems(
	config: FiberyConfig,
	kind: ItemKind,
	title: string,
	limit = 20,
): Promise<FindItemsResult> {
	const mapping = await resolveTypeMapping(config, kind);
	const ranked = await queryByNameRanked(config, mapping, title, limit);
	return {
		kind,
		type: mapping.typeId,
		count: ranked.length,
		items: ranked.map((entry) => ({
			id: primaryId(entry.entity),
			title: entityName(entry.entity, mapping.nameField),
			score: Number(entry.score.toFixed(4)),
			isExact: entry.isExact,
			raw: entry.entity,
		})),
	};
}

function normalizeStateName(value: unknown): string {
	const record = asRecord(value);
	return String(record["enum/name"] ?? record[RELATED_TYPE_IDS.nameField] ?? value ?? "").trim();
}

function toCurrentTaskItem(kind: ItemKind, row: Record<string, unknown>, mapping: TypeMapping): CurrentTaskItem {
	const milestone = asRecord(row[mapping.milestoneField]);
	const milestoneState = asRecord(milestone["workflow/state"]);
	return {
		kind,
		id: primaryId(row),
		title: entityName(row, mapping.nameField),
		status: normalizeStateName(row[mapping.statusField]),
		milestoneName: milestone ? String(milestone[RELATED_TYPE_IDS.milestoneNameField] ?? "").trim() || null : null,
		milestoneState: milestoneState ? normalizeStateName(milestoneState) || null : null,
	};
}

function isCurrentTask(item: CurrentTaskItem): boolean {
	if (["In Beta", "In Production"].includes(item.status)) return false;
	if (!item.milestoneName) return true;
	return item.milestoneState === "In Development";
}

async function queryCurrentTasksForKind(
	config: FiberyConfig,
	kind: ItemKind,
	limitPerKind: number,
): Promise<CurrentTaskItem[]> {
	const mapping = await resolveTypeMapping(config, kind);
	const rows = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": mapping.typeId,
				"q/select": [
					"fibery/id",
					mapping.nameField,
					{ [mapping.statusField]: ["fibery/id", "enum/name", RELATED_TYPE_IDS.nameField] },
					{
						[mapping.milestoneField]: [
							"fibery/id",
							RELATED_TYPE_IDS.milestoneNameField,
							{ "workflow/state": ["fibery/id", "enum/name", RELATED_TYPE_IDS.nameField] },
						],
					},
				],
				"q/limit": Math.max(limitPerKind, 500),
			},
		},
	});
	return (Array.isArray(rows) ? rows : []).map(asRecord).map((row) => toCurrentTaskItem(kind, row, mapping));
}

export async function listCurrentTasks(config: FiberyConfig, limit = 200): Promise<CurrentTasksResult> {
	const safeLimit = Math.max(1, Math.min(1000, Math.floor(limit)));
	const [bugs, features] = await Promise.all([
		queryCurrentTasksForKind(config, "bug", safeLimit),
		queryCurrentTasksForKind(config, "feature", safeLimit),
	]);
	const items = [...bugs, ...features]
		.filter(isCurrentTask)
		.sort((a, b) => a.title.localeCompare(b.title))
		.slice(0, safeLimit);
	return {
		count: items.length,
		items,
		filters: {
			excludedStatuses: ["In Beta", "In Production"],
			includedMilestoneState: "In Development",
		},
	};
}

function inferDomainsFromPaths(changedPaths: string[]): DomainName[] {
	const joined = changedPaths.join("\n").toLowerCase();
	const inferred: DomainName[] = [];
	if (joined.includes("extensions/questextension/")) inferred.push("Quest Extension");
	if (joined.includes("extensions/entityextension/")) inferred.push("Entity Extension");
	if (joined.includes("extensions/roadnetworkextension/")) inferred.push("RoadNetwork Extension");
	if (joined.includes("module-plugin/")) inferred.push("Module Plugin");
	if (joined.includes("discord_bot")) inferred.push("Discord Bot");
	if (joined.includes("engine/")) inferred.push("Engine Core");
	return uniqueIds(inferred);
}

export async function discoverDomains(
	config: FiberyConfig,
	changedPaths: string[] = [],
): Promise<{ count: number; domains: Array<{ id: string; name: string }>; inferredDomains: DomainName[] }> {
	const rows = await queryTypeRecords(
		config,
		RELATED_TYPE_IDS.domain,
		{ "fibery/id": "fibery/id", [RELATED_TYPE_IDS.nameField]: RELATED_TYPE_IDS.nameField },
		500,
	);
	const domains = rows
		.map((row) => ({ id: primaryId(row), name: String(row[RELATED_TYPE_IDS.nameField] ?? "") }))
		.filter((row) => row.id && row.name)
		.sort((a, b) => a.name.localeCompare(b.name));
	return {
		count: domains.length,
		domains,
		inferredDomains: inferDomainsFromPaths(changedPaths),
	};
}

export async function getDiscoverySummary(config: FiberyConfig): Promise<DiscoverySummary> {
	const schema = await getSchema(config, false);
	const types = extractTypes(schema);
	const featureType = types.find((candidate) => typeIdentifier(candidate) === WORKFLOW_TYPE_IDS.feature);
	const bugType = types.find((candidate) => typeIdentifier(candidate) === WORKFLOW_TYPE_IDS.bug);
	if (!featureType || !bugType) {
		throw new Error("Could not find hardcoded feature or bug type in schema");
	}
	return {
		source: schemaCache ? "cache" : "api",
		typeCount: types.length,
		featureType: {
			id: typeIdentifier(featureType),
			displayName: typeDisplayName(featureType),
			fieldCount: extractFields(featureType).length,
		},
		bugType: {
			id: typeIdentifier(bugType),
			displayName: typeDisplayName(bugType),
			fieldCount: extractFields(bugType).length,
		},
	};
}

export type ReleaseType = "beta" | "full";

export type ChangelogItem = {
	kind: "bug" | "feature";
	id: string;
	title: string;
	descriptionMarkdown: string;
	status: string;
	severity?: BugPriority;
	importance?: FeatureImportance;
};

export type ChangelogBetaTarget = {
	releaseType: "beta";
	id: string;
	name: string;
	identifier: number;
	published: false;
};

export type ChangelogMilestoneTarget = {
	releaseType: "full";
	id: string;
	name: string;
	state: string;
	published: false;
};

export type ChangelogTarget = ChangelogBetaTarget | ChangelogMilestoneTarget;

export type ChangelogItemsResult = {
	releaseType: ReleaseType;
	target: ChangelogTarget;
	bugs: ChangelogItem[];
	features: ChangelogItem[];
	counts: { bugs: number; features: number; total: number };
};

export type GetChangelogItemsArgs = {
	releaseType: ReleaseType;
	targetIdentifier?: number;
	targetName?: string;
	includeDescriptions?: boolean;
};

type RawChangelogItem = {
	kind: "bug" | "feature";
	id: string;
	title: string;
	status: string;
	severity?: BugPriority;
	importance?: FeatureImportance;
	descriptionSecret?: string;
};

const DESCRIPTION_BATCH_SIZE = 10;

async function readDocumentMarkdown(config: FiberyConfig, secret: string): Promise<string> {
	let attempt = 0;
	while (attempt <= config.maxRetries) {
		const response = await fetch(
			`https://${normalizeWorkspace(config.workspace)}/api/documents/${secret}?format=md`,
			{
				headers: { Authorization: `Token ${config.token}` },
			},
		);
		if (response.status === 429 && attempt < config.maxRetries) {
			await wait(config.retryDelayMs * Math.pow(2, attempt));
			attempt += 1;
			continue;
		}
		if (!response.ok) {
			throw new Error(`Failed to read document (${response.status}): ${await response.text()}`);
		}
		const payload = (await response.json()) as { content?: string };
		return String(payload.content ?? "").trim();
	}
	throw new Error("Failed to read document after retries");
}

async function fetchDescriptionsInBatches(
	config: FiberyConfig,
	items: RawChangelogItem[],
): Promise<Map<string, string>> {
	const secrets = items
		.map((item) => item.descriptionSecret)
		.filter((secret): secret is string => Boolean(secret));
	const uniqueSecrets = uniqueIds(secrets);
	const result = new Map<string, string>();
	for (let index = 0; index < uniqueSecrets.length; index += DESCRIPTION_BATCH_SIZE) {
		const batch = uniqueSecrets.slice(index, index + DESCRIPTION_BATCH_SIZE);
		const contents = await Promise.all(batch.map((secret) => readDocumentMarkdown(config, secret)));
		for (let batchIndex = 0; batchIndex < batch.length; batchIndex += 1) {
			result.set(batch[batchIndex], contents[batchIndex]);
		}
	}
	return result;
}

function extractDescriptionSecret(row: Record<string, unknown>, descriptionField: string): string | undefined {
	const document = asRecord(row[descriptionField]);
	const secret = String(document["Collaboration~Documents/secret"] ?? document.secret ?? "").trim();
	return secret || undefined;
}

function extractEnumName(row: Record<string, unknown>, field: string): string {
	return normalizeStateName(row[field]);
}

export async function resolveUnpublishedBeta(
	config: FiberyConfig,
	identifier?: number,
): Promise<ChangelogBetaTarget | { error: string }> {
	const betas = await listRecentBetas(config, 1000);
	const unpublished = betas.filter((beta) => !beta.published);
	if (identifier !== undefined) {
		const match = betas.find((beta) => beta.identifier === identifier);
		if (!match) {
			return { error: `No beta found with identifier ${identifier}` };
		}
		if (match.published) {
			return { error: `Beta ${identifier} is already published` };
		}
		return {
			releaseType: "beta",
			id: match.id,
			name: match.name,
			identifier: match.identifier,
			published: false,
		};
	}
	if (unpublished.length === 0) {
		return { error: "No unpublished beta found" };
	}
	const latest = unpublished.sort((a, b) => b.identifier - a.identifier)[0];
	return {
		releaseType: "beta",
		id: latest.id,
		name: latest.name,
		identifier: latest.identifier,
		published: false,
	};
}

type MilestoneRow = {
	id: string;
	name: string;
	publication: string | null;
	changes: number;
	state: string;
};

async function listMilestonesWithPublication(config: FiberyConfig): Promise<MilestoneRow[]> {
	const rows = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": RELATED_TYPE_IDS.milestone,
				"q/select": [
					"fibery/id",
					RELATED_TYPE_IDS.milestoneNameField,
					BETA_PUBLICATION_FIELD,
					"Milestone/Changes",
					{ "workflow/state": ["enum/name"] },
				],
				"q/limit": 500,
			},
		},
	});
	return (Array.isArray(rows) ? rows : []).map(asRecord).map((row) => {
		const publicationValue = row[BETA_PUBLICATION_FIELD];
		const publication =
			publicationValue === null || publicationValue === undefined ? null : String(publicationValue);
		return {
			id: primaryId(row),
			name: String(row[RELATED_TYPE_IDS.milestoneNameField] ?? ""),
			publication,
			changes: Number(row["Milestone/Changes"] ?? 0),
			state: extractEnumName(row, "workflow/state"),
		};
	});
}

export async function resolveUnpublishedMilestone(
	config: FiberyConfig,
	name?: string,
): Promise<ChangelogMilestoneTarget | { error: string }> {
	const milestones = await listMilestonesWithPublication(config);
	if (name?.trim()) {
		const match = milestones.find(
			(milestone) => milestone.name.toLowerCase() === name.trim().toLowerCase(),
		);
		if (!match) {
			return { error: `No milestone found with name '${name.trim()}'` };
		}
		if (match.publication !== null) {
			return { error: `Milestone '${match.name}' is already published` };
		}
		return {
			releaseType: "full",
			id: match.id,
			name: match.name,
			state: match.state,
			published: false,
		};
	}
	const candidates = milestones.filter(
		(milestone) =>
			milestone.publication === null && milestone.state === MILESTONE_IN_DEVELOPMENT_STATE,
	);
	if (candidates.length === 0) {
		return { error: "No unpublished in-development milestone found" };
	}
	const selected = candidates.sort((a, b) => {
		if (b.changes !== a.changes) return b.changes - a.changes;
		return a.name.localeCompare(b.name);
	})[0];
	return {
		releaseType: "full",
		id: selected.id,
		name: selected.name,
		state: selected.state,
		published: false,
	};
}

async function queryChangelogItemsForTarget(
	config: FiberyConfig,
	releaseType: ReleaseType,
	targetId: string,
): Promise<RawChangelogItem[]> {
	const bugMapping = await resolveTypeMapping(config, "bug");
	const featureMapping = await resolveTypeMapping(config, "feature");
	const linkField =
		releaseType === "beta" ? bugMapping.betaField : bugMapping.milestoneField;
	const featureLinkField =
		releaseType === "beta" ? featureMapping.betaField : featureMapping.milestoneField;

	const bugRows = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": bugMapping.typeId,
				"q/select": [
					"fibery/id",
					bugMapping.nameField,
					{ [bugMapping.statusField]: ["enum/name"] },
					{ [bugMapping.priorityField]: ["enum/name"] },
					{ [bugMapping.descriptionField]: ["Collaboration~Documents/secret"] },
				],
				"q/where": ["=", [linkField, "fibery/id"], "$targetId"],
				"q/limit": 500,
			},
			params: { $targetId: targetId },
		},
	});

	const featureRows = await executeCommand<Array<Record<string, unknown>>>(config, {
		command: "fibery.entity/query",
		args: {
			query: {
				"q/from": featureMapping.typeId,
				"q/select": [
					"fibery/id",
					featureMapping.nameField,
					{ [featureMapping.statusField]: ["enum/name"] },
					{ [featureMapping.importanceField]: ["enum/name"] },
					{ [featureMapping.descriptionField]: ["Collaboration~Documents/secret"] },
				],
				"q/where": ["=", [featureLinkField, "fibery/id"], "$targetId"],
				"q/limit": 500,
			},
			params: { $targetId: targetId },
		},
	});

	const bugs: RawChangelogItem[] = (Array.isArray(bugRows) ? bugRows : []).map(asRecord).map((row) => ({
		kind: "bug" as const,
		id: primaryId(row),
		title: entityName(row, bugMapping.nameField),
		status: extractEnumName(row, bugMapping.statusField),
		severity: extractEnumName(row, bugMapping.priorityField) as BugPriority,
		descriptionSecret: extractDescriptionSecret(row, bugMapping.descriptionField),
	}));

	const features: RawChangelogItem[] = (Array.isArray(featureRows) ? featureRows : [])
		.map(asRecord)
		.map((row) => ({
			kind: "feature" as const,
			id: primaryId(row),
			title: entityName(row, featureMapping.nameField),
			status: extractEnumName(row, featureMapping.statusField),
			importance: extractEnumName(row, featureMapping.importanceField) as FeatureImportance,
			descriptionSecret: extractDescriptionSecret(row, featureMapping.descriptionField),
		}));

	return [...bugs, ...features];
}

function sortChangelogItems(items: RawChangelogItem[]): { bugs: RawChangelogItem[]; features: RawChangelogItem[] } {
	const bugs = items
		.filter((item) => item.kind === "bug")
		.sort((a, b) => {
			const aRank = BUG_PRIORITY_SORT[a.severity ?? "Low"] ?? 99;
			const bRank = BUG_PRIORITY_SORT[b.severity ?? "Low"] ?? 99;
			if (aRank !== bRank) return aRank - bRank;
			return a.title.localeCompare(b.title);
		});
	const features = items
		.filter((item) => item.kind === "feature")
		.sort((a, b) => {
			const aRank = FEATURE_IMPORTANCE_SORT[a.importance ?? "Internal"] ?? 99;
			const bRank = FEATURE_IMPORTANCE_SORT[b.importance ?? "Internal"] ?? 99;
			if (aRank !== bRank) return aRank - bRank;
			return a.title.localeCompare(b.title);
		});
	return { bugs, features };
}

export async function getChangelogItems(
	config: FiberyConfig,
	args: GetChangelogItemsArgs,
): Promise<ChangelogItemsResult | { error: string }> {
	const releaseType = args.releaseType ?? "beta";
	const target =
		releaseType === "beta"
			? await resolveUnpublishedBeta(config, args.targetIdentifier)
			: await resolveUnpublishedMilestone(config, args.targetName);
	if ("error" in target) return target;

	const rawItems = await queryChangelogItemsForTarget(config, releaseType, target.id);
	const { bugs: rawBugs, features: rawFeatures } = sortChangelogItems(rawItems);

	let descriptionBySecret = new Map<string, string>();
	if (args.includeDescriptions !== false) {
		descriptionBySecret = await fetchDescriptionsInBatches(config, [...rawBugs, ...rawFeatures]);
	}

	const toChangelogItem = (item: RawChangelogItem): ChangelogItem => ({
		kind: item.kind,
		id: item.id,
		title: item.title,
		status: item.status,
		descriptionMarkdown: item.descriptionSecret
			? (descriptionBySecret.get(item.descriptionSecret) ?? "")
			: "",
		...(item.severity ? { severity: item.severity } : {}),
		...(item.importance ? { importance: item.importance } : {}),
	});

	const bugs = rawBugs.map(toChangelogItem);
	const features = rawFeatures.map(toChangelogItem);

	return {
		releaseType,
		target,
		bugs,
		features,
		counts: {
			bugs: bugs.length,
			features: features.length,
			total: bugs.length + features.length,
		},
	};
}
