import { tool } from "@opencode-ai/plugin"

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue }

type FiberyCommand = {
  command: string
  args?: Record<string, JsonValue>
}

type ItemKind = "bug" | "feature"

const BUG_STATUS_VALUES = ["Rejected", "Unreproducible", "In Beta", "In Production", "Investigating", "In Progress", "Fixed"] as const
const BUG_PRIORITY_VALUES = ["Critical", "High", "Normal", "Low"] as const
const FEATURE_STATUS_VALUES = ["Backlog", "In Progress", "Done", "In Beta", "In Production"] as const
const FEATURE_SIZE_VALUES = ["Minutes", "Hours", "Days", "Weeks", "Months"] as const
const FEATURE_IMPORTANCE_VALUES = ["Major", "Notable", "Minor", "Internal"] as const

type BugStatus = (typeof BUG_STATUS_VALUES)[number]
type BugPriority = (typeof BUG_PRIORITY_VALUES)[number]
type FeatureStatus = (typeof FEATURE_STATUS_VALUES)[number]
type FeatureSize = (typeof FEATURE_SIZE_VALUES)[number]
type FeatureImportance = (typeof FEATURE_IMPORTANCE_VALUES)[number]

const DOMAIN_OPTIONS = [
  "Engine Core",
  "Engine Paper",
  "Module Plugin",
  "Basic Extension",
  "Entity Extension",
  "Marketplace",
  "Panel",
  "WorldGuard Extension",
  "Vault Extension",
  "RoadNetwork Extension",
  "Quest Extension",
  "Engine Loader",
  "Discord Bot",
  "Visibility Extension",
] as const

type DomainName = (typeof DOMAIN_OPTIONS)[number]

const DOMAIN_ID_BY_NAME: Record<DomainName, string> = {
  "Engine Core": "5cedf4a0-e3e1-11ef-88e6-1388263f3f2c",
  "Engine Paper": "68431bf0-e3e1-11ef-88e6-1388263f3f2c",
  "Module Plugin": "6c4431d0-e3e1-11ef-88e6-1388263f3f2c",
  "Basic Extension": "72b0a260-e3e1-11ef-88e6-1388263f3f2c",
  "Entity Extension": "74a40df0-e3e1-11ef-88e6-1388263f3f2c",
  "Marketplace": "7a23fba0-e3e1-11ef-88e6-1388263f3f2c",
  Panel: "7cd5ae20-e3e1-11ef-88e6-1388263f3f2c",
  "WorldGuard Extension": "841b67b0-e3e1-11ef-88e6-1388263f3f2c",
  "Vault Extension": "85bcbba0-e3e1-11ef-88e6-1388263f3f2c",
  "RoadNetwork Extension": "100c2f10-e3e3-11ef-88e6-1388263f3f2c",
  "Quest Extension": "12fd82a0-e3e3-11ef-88e6-1388263f3f2c",
  "Engine Loader": "39a87f00-e482-11ef-a5a4-f9c920bf52d9",
  "Discord Bot": "10012595-98f1-4ef9-842d-20a43b7421c0",
  "Visibility Extension": "f3f74f70-9e32-11f0-9626-9b858dc345a8",
}

type BaseMapping = {
  typeId: string
  nameField: string
  descriptionField: string
  milestoneField: string
  betaField: string
  domainsField: string
  discordsField: string
  linksField: string
  fieldTypes: Record<string, string>
}

type BugMapping = BaseMapping & {
  kind: "bug"
  statusField: string
  priorityField: string
}

type FeatureMapping = BaseMapping & {
  kind: "feature"
  statusField: string
  sizeField: string
  importanceField: string
}

type TypeMapping = BugMapping | FeatureMapping

type BaseCreateArgs = {
  title: string
  description_markdown: string
  milestone?: string
  beta?: number | null
  domains?: DomainName[]
  discord_ids?: string[]
  discord_thread_id?: string
}

type CreateBugArgs = BaseCreateArgs & {
  status?: BugStatus
  priority?: BugPriority
  linked_feature_ids_or_names?: string[]
}

type CreateFeatureArgs = BaseCreateArgs & {
  status?: FeatureStatus
  size?: FeatureSize
  importance?: FeatureImportance
  linked_bug_ids_or_names?: string[]
}

type BaseUpdateArgs = {
  id_or_name: string
  title?: string
  description_markdown?: string
  milestone?: string
  beta?: number
  clear_milestone?: boolean
  clear_beta?: boolean
  domains?: DomainName[]
  discord_ids?: string[]
  discord_thread_id?: string
}

type UpdateBugArgs = BaseUpdateArgs & {
  status?: BugStatus
  priority?: BugPriority
  linked_feature_ids_or_names?: string[]
}

type UpdateFeatureArgs = BaseUpdateArgs & {
  status?: FeatureStatus
  size?: FeatureSize
  importance?: FeatureImportance
  linked_bug_ids_or_names?: string[]
}

type FiberyConfig = {
  workspace: string
  token: string
  maxRetries: number
  retryDelayMs: number
}

let schemaCache: unknown | null = null
let schemaCachedAt = 0
const schemaTtlMs = 5 * 60 * 1000
let envBase = ""
let dotenvCache: Record<string, string> | null = null

const WORKFLOW_TYPE_IDS = {
  bug: "Development/Bugs",
  feature: "Development/Features",
} as const

const WORKFLOW_FIELD_IDS = {
  bug: {
    nameField: "Development/Name",
    statusField: "workflow/state",
    priorityField: "Development/Priority",
    descriptionField: "Development/Description",
    milestoneField: "Development/Milestone",
    betaField: "Milestone/Beta",
    domainsField: "Development/Domains",
    discordsField: "Development/Discords",
    linksField: "Development/Features",
  },
  feature: {
    nameField: "Development/Name",
    statusField: "workflow/state",
    sizeField: "Development/Size",
    importanceField: "Development/Importance",
    descriptionField: "Development/Description",
    milestoneField: "Development/Milestone",
    betaField: "Milestone/Beta",
    domainsField: "Development/Domains",
    discordsField: "Development/Discords",
    linksField: "Development/Bugs",
  },
} as const

const RELATED_TYPE_IDS = {
  domain: "Development/Domain",
  discord: "Development/Discord",
  discordChannelIdField: "Development/Discord Channel Id",
  milestone: "Milestone/Milestone",
  beta: "Milestone/Beta",
  betaIdentifierField: "Milestone/Identifier",
  nameField: "Development/Name",
  milestoneNameField: "Milestone/Name",
} as const

const DEFAULT_STATUS_BY_KIND: { bug: BugStatus; feature: FeatureStatus } = {
  bug: "Investigating",
  feature: "Backlog",
}

function setEnvBase(_worktree: unknown): void {
  if (typeof _worktree === "string" && _worktree.trim().length > 0) {
    envBase = _worktree
  }
}

function parseDotEnv(content: unknown): Record<string, string> {
  const parsed: Record<string, string> = {}
  const text = String(content ?? "")
  for (const line of text.split("\n")) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) {
      continue
    }
    const separator = trimmed.indexOf("=")
    if (separator <= 0) {
      continue
    }
    const key = trimmed.slice(0, separator).trim()
    const value = trimmed.slice(separator + 1).trim()
    if (key.length > 0) {
      parsed[key] = value
    }
  }
  return parsed
}

async function ensureDotenvLoaded(): Promise<void> {
  if (dotenvCache) {
    return
  }
  const filePath = envBase ? `${envBase}/.env` : ".env"
  try {
    const content = await Bun.file(filePath).text()
    dotenvCache = parseDotEnv(content)
  } catch {
    dotenvCache = {}
  }
}

async function getEnv(name: string): Promise<string> {
  const fromProcess = String(process.env[name] ?? "").trim()
  if (fromProcess) {
    return fromProcess
  }
  await ensureDotenvLoaded()
  return String(dotenvCache?.[name] ?? "").trim()
}

async function required(name: string): Promise<string> {
  const value = await getEnv(name)
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value
}

function normalizeWorkspace(workspace: string): string {
  const normalized = workspace.replace(/^https?:\/\//, "").replace(/\/$/, "")
  if (normalized.includes(".")) {
    return normalized
  }
  return `${normalized}.fibery.io`
}

async function getConfig(): Promise<FiberyConfig> {
  return {
    workspace: await required("FIBERY_WORKSPACE"),
    token: await required("FIBERY_API_TOKEN"),
    maxRetries: Number((await getEnv("FIBERY_MAX_RETRIES")) || "3"),
    retryDelayMs: Number((await getEnv("FIBERY_RETRY_DELAY_MS")) || "400"),
  }
}

function commandUrl(workspace: string): string {
  return `https://${normalizeWorkspace(workspace)}/api/commands`
}

async function wait(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms))
}

async function executeCommand(config: FiberyConfig, payload: FiberyCommand): Promise<unknown> {
  const url = commandUrl(config.workspace)
  let attempt = 0

  while (attempt <= config.maxRetries) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Token ${config.token}`,
      },
      body: JSON.stringify([payload]),
    })

    if (response.status === 429 && attempt < config.maxRetries) {
      const delay = config.retryDelayMs * Math.pow(2, attempt)
      attempt += 1
      await wait(delay)
      continue
    }

    const text = await response.text()
    let parsed: unknown = null
    try {
      parsed = text ? JSON.parse(text) : null
    } catch {
      parsed = { raw: text }
    }

    if (!response.ok) {
      throw new Error(`Fibery request failed (${response.status}): ${JSON.stringify(parsed)}`)
    }

    const first = Array.isArray(parsed) ? parsed[0] : parsed
    if (first && typeof first === "object" && "success" in first) {
      const success = (first as { success?: boolean }).success
      if (success === false) {
        throw new Error(`Fibery command failed: ${JSON.stringify(first)}`)
      }
      if ("result" in (first as Record<string, unknown>)) {
        return (first as Record<string, unknown>).result
      }
    }

    return first
  }

  throw new Error("Fibery request failed after retries")
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" ? (value as Record<string, unknown>) : {}
}

function stringifyToolOutput(value: unknown): string {
  if (typeof value === "string") {
    return value
  }
  try {
    return JSON.stringify(value, null, 2)
  } catch {
    return String(value)
  }
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
}

function extractTypes(schema: unknown): Array<Record<string, unknown>> {
  const root = asRecord(schema)
  const candidates: unknown[] = [
    root["fibery/types"],
    root.typeObjects,
    root.types,
    asRecord(root.result)["fibery/types"],
    asRecord(root.result).typeObjects,
    asRecord(root.result).types,
  ]
  for (const candidate of candidates) {
    if (Array.isArray(candidate)) {
      return candidate.map(asRecord)
    }
  }
  return []
}

function typeIdentifier(typeObject: Record<string, unknown>): string {
  const name = typeObject["fibery/name"]
  if (typeof name === "string" && name.length > 0) return name
  const id = typeObject["fibery/id"]
  if (typeof id === "string" && id.length > 0) return id
  return ""
}

function extractFields(typeObject: Record<string, unknown>): Array<Record<string, unknown>> {
  const candidates: unknown[] = [
    typeObject["fibery/fields"],
    typeObject.fields,
    typeObject["fibery/type-fields"],
  ]
  for (const candidate of candidates) {
    if (Array.isArray(candidate)) {
      return candidate.map(asRecord)
    }
  }
  return []
}

function fieldIdentifier(fieldObject: Record<string, unknown>): string {
  const name = fieldObject["fibery/name"]
  if (typeof name === "string" && name.length > 0) return name
  const id = fieldObject["fibery/id"]
  if (typeof id === "string" && id.length > 0) return id
  return ""
}

async function getSchema(config: FiberyConfig, forceRefresh: boolean): Promise<unknown> {
  if (!forceRefresh && schemaCache && Date.now() - schemaCachedAt < schemaTtlMs) {
    return schemaCache
  }
  const schema = await executeCommand(config, {
    command: "fibery.schema/query",
    args: {},
  })
  schemaCache = schema
  schemaCachedAt = Date.now()
  return schema
}

function fieldTypeById(fields: Array<Record<string, unknown>>): Record<string, string> {
  const result: Record<string, string> = {}
  for (const field of fields) {
    const id = fieldIdentifier(field)
    if (!id) {
      continue
    }
    result[id] = String(field["fibery/type"] ?? field.type ?? "")
  }
  return result
}

async function resolveTypeMapping(config: FiberyConfig, kind: ItemKind): Promise<TypeMapping> {
  const hardcodedTypeId = WORKFLOW_TYPE_IDS[kind]
  const hardcodedFields = WORKFLOW_FIELD_IDS[kind]
  const schema = await getSchema(config, false)
  const types = extractTypes(schema)

  const typeObject = types.find((candidate) => {
    const id = typeIdentifier(candidate)
    const name = String(candidate["fibery/name"] ?? "")
    return id === hardcodedTypeId || name === hardcodedTypeId
  })

  if (!typeObject) {
    throw new Error(`Could not resolve hardcoded ${kind} type '${hardcodedTypeId}'`)
  }

  const typeId = typeIdentifier(typeObject)
  const fields = extractFields(typeObject)
  const fieldTypes = fieldTypeById(fields)

  if (kind === "bug") {
    return {
      kind,
      typeId,
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
    }
  }

  return {
    kind,
    typeId,
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
  }
}

async function queryByName(
  config: FiberyConfig,
  mapping: TypeMapping,
  title: string,
  limit = 10,
): Promise<Array<Record<string, unknown>>> {
  const scanLimit = Math.max(limit * 20, 500)
  const result = await executeCommand(config, {
    command: "fibery.entity/query",
    args: {
      query: {
        "q/from": mapping.typeId,
        "q/select": {
          "fibery/id": "fibery/id",
          [mapping.nameField]: mapping.nameField,
        },
        "q/limit": scanLimit,
      },
    },
  })

  if (!Array.isArray(result)) {
    return []
  }
  const foldedTitle = title.trim().toLowerCase()
  return result
    .map(asRecord)
    .filter((entity) => entityName(entity, mapping.nameField).trim().toLowerCase() === foldedTitle)
    .slice(0, limit)
}

function primaryId(entity: Record<string, unknown>): string {
  const id = entity["fibery/id"]
  return typeof id === "string" ? id : ""
}

function entityName(entity: Record<string, unknown>, fieldId: string): string {
  const value = entity[fieldId]
  return typeof value === "string" ? value : ""
}

function uniqueIds(ids: string[]): string[] {
  return Array.from(new Set(ids.filter((id) => id.length > 0)))
}

async function queryTypeRecords(
  config: FiberyConfig,
  typeId: string,
  select: Record<string, JsonValue>,
  limit = 300,
): Promise<Array<Record<string, unknown>>> {
  const result = await executeCommand(config, {
    command: "fibery.entity/query",
    args: {
      query: {
        "q/from": typeId,
        "q/select": select,
        "q/limit": limit,
      },
    },
  })
  if (!Array.isArray(result)) {
    return []
  }
  return result.map(asRecord)
}

async function resolveEnumOptionId(
  config: FiberyConfig,
  enumTypeId: string,
  optionName: string,
): Promise<string> {
  const rows = await queryTypeRecords(config, enumTypeId, {
    "fibery/id": "fibery/id",
    "enum/name": "enum/name",
  })
  const match = rows.find((row) => String(row["enum/name"] ?? "").toLowerCase() === optionName.trim().toLowerCase())
  if (!match) {
    const available = rows.map((row) => String(row["enum/name"] ?? "")).filter((name) => name.length > 0)
    throw new Error(`Unknown value '${optionName}' for ${enumTypeId}. Allowed values: ${available.join(", ")}`)
  }
  return String(match["fibery/id"] ?? "")
}

async function resolveEntityIdsByName(
  config: FiberyConfig,
  typeId: string,
  nameField: string,
  values: string[],
): Promise<string[]> {
  const normalized = values.map((value) => value.trim()).filter((value) => value.length > 0)
  if (normalized.length === 0) {
    return []
  }

  const directIds = normalized.filter(isUuid)
  const names = normalized.filter((value) => !isUuid(value))
  if (names.length === 0) {
    return uniqueIds(directIds)
  }

  const rows = await queryTypeRecords(config, typeId, {
    "fibery/id": "fibery/id",
    [nameField]: nameField,
  }, 1000)

  const ids: string[] = [...directIds]
  for (const name of names) {
    const match = rows.find((row) => String(row[nameField] ?? "").toLowerCase() === name.toLowerCase())
    if (!match) {
      throw new Error(`Could not resolve '${name}' in ${typeId}`)
    }
    ids.push(String(match["fibery/id"] ?? ""))
  }
  return uniqueIds(ids)
}

function validateEntityIds(ids: string[], label: string): string[] {
  const normalized = ids.map((id) => id.trim()).filter((id) => id.length > 0)
  const invalid = normalized.filter((id) => !isUuid(id))
  if (invalid.length > 0) {
    throw new Error(`${label} must contain Fibery ids only. Invalid values: ${invalid.join(", ")}`)
  }
  return uniqueIds(normalized)
}

function mapDomainNamesToIds(domains: DomainName[]): string[] {
  return uniqueIds(domains.map((domain) => DOMAIN_ID_BY_NAME[domain]))
}

function inferDomainsFromPaths(paths: string[]): DomainName[] {
  const joined = paths.join(" ").toLowerCase()
  const inferred: DomainName[] = []

  if (joined.includes("questextension") || joined.includes("quest/")) {
    inferred.push("Quest Extension")
  }
  if (joined.includes("entityextension") || joined.includes("entity/")) {
    inferred.push("Entity Extension")
  }
  if (joined.includes("roadnetwork")) {
    inferred.push("RoadNetwork Extension")
  }
  if (joined.includes("module-plugin")) {
    inferred.push("Module Plugin")
  }
  if (joined.includes("discord_bot")) {
    inferred.push("Discord Bot")
  }
  if (joined.includes("engine/")) {
    inferred.push("Engine Core")
  }

  return uniqueIds(inferred) as DomainName[]
}

function renderDomainConstants(rows: Array<{ id: string; name: string }>): string {
  const ordered = [...rows].sort((a, b) => a.name.localeCompare(b.name))
  const optionsLines = ordered.map((row) => `  "${row.name}",`).join("\n")
  const mappingLines = ordered.map((row) => `  "${row.name}": "${row.id}",`).join("\n")
  return [
    "const DOMAIN_OPTIONS = [",
    optionsLines,
    "] as const",
    "",
    "const DOMAIN_ID_BY_NAME: Record<DomainName, string> = {",
    mappingLines,
    "}",
  ].join("\n")
}

async function listMilestones(config: FiberyConfig): Promise<Array<{ id: string; name: string }>> {
  const rows = await queryTypeRecords(config, RELATED_TYPE_IDS.milestone, {
    "fibery/id": "fibery/id",
    [RELATED_TYPE_IDS.milestoneNameField]: RELATED_TYPE_IDS.milestoneNameField,
  }, 500)
  return rows
    .map((row) => ({
      id: String(row["fibery/id"] ?? ""),
      name: String(row[RELATED_TYPE_IDS.milestoneNameField] ?? ""),
    }))
    .filter((row) => row.id.length > 0 && row.name.length > 0)
    .sort((a, b) => a.name.localeCompare(b.name))
}

async function listRecentBetas(config: FiberyConfig, limit: number): Promise<Array<{ id: string; name: string; identifier: number }>> {
  const rows = await queryTypeRecords(config, RELATED_TYPE_IDS.beta, {
    "fibery/id": "fibery/id",
    [RELATED_TYPE_IDS.milestoneNameField]: RELATED_TYPE_IDS.milestoneNameField,
    [RELATED_TYPE_IDS.betaIdentifierField]: RELATED_TYPE_IDS.betaIdentifierField,
  }, 1000)
  return rows
    .map((row) => ({
      id: String(row["fibery/id"] ?? ""),
      name: String(row[RELATED_TYPE_IDS.milestoneNameField] ?? ""),
      identifier: Number(row[RELATED_TYPE_IDS.betaIdentifierField] ?? 0),
    }))
    .filter((row) => row.id.length > 0 && Number.isFinite(row.identifier) && row.identifier > 0)
    .sort((a, b) => b.identifier - a.identifier)
    .slice(0, Math.max(1, Math.min(20, Math.floor(limit))))
}

async function resolveBetaIdByIdentifier(config: FiberyConfig, identifier: number): Promise<string> {
  const rows = await queryTypeRecords(config, RELATED_TYPE_IDS.beta, {
    "fibery/id": "fibery/id",
    [RELATED_TYPE_IDS.betaIdentifierField]: RELATED_TYPE_IDS.betaIdentifierField,
  }, 1000)
  const match = rows.find((row) => Number(row[RELATED_TYPE_IDS.betaIdentifierField]) === identifier)
  if (!match) {
    throw new Error(`Could not resolve beta with identifier ${identifier}`)
  }
  return String(match["fibery/id"] ?? "")
}

async function upsertDiscordThread(config: FiberyConfig, threadId: string): Promise<string> {
  const normalized = threadId.trim()
  if (!normalized) {
    throw new Error("discord_thread_id must not be empty")
  }

  const rows = await queryTypeRecords(config, RELATED_TYPE_IDS.discord, {
    "fibery/id": "fibery/id",
    [RELATED_TYPE_IDS.discordChannelIdField]: RELATED_TYPE_IDS.discordChannelIdField,
  }, 2000)
  const existing = rows.find((row) => String(row[RELATED_TYPE_IDS.discordChannelIdField] ?? "") === normalized)
  if (existing) {
    return String(existing["fibery/id"] ?? "")
  }

  const created = await executeCommand(config, {
    command: "fibery.entity/create",
    args: {
      type: RELATED_TYPE_IDS.discord,
      entity: {
        [RELATED_TYPE_IDS.nameField]: `Thread ${normalized}`,
        [RELATED_TYPE_IDS.discordChannelIdField]: normalized,
      },
    },
  })
  const createdEntity = asRecord(created)
  const createdId = String(createdEntity["fibery/id"] ?? "")
  if (!createdId) {
    throw new Error(`Failed to create discord thread entity for ${normalized}`)
  }
  return createdId
}

async function getDocumentSecret(
  config: FiberyConfig,
  typeId: string,
  entityId: string,
  descriptionField: string,
): Promise<string> {
  const result = await executeCommand(config, {
    command: "fibery.entity/query",
    args: {
      query: {
        "q/from": typeId,
        "q/select": [
          "fibery/id",
          { [descriptionField]: ["Collaboration~Documents/secret"] },
        ],
        "q/where": ["=", ["fibery/id"], "$id"],
        "q/limit": 1,
      },
      params: {
        "$id": entityId,
      },
    },
  })

  if (!Array.isArray(result) || result.length === 0) {
    throw new Error(`Entity not found while reading document secret: ${entityId}`)
  }
  const row = asRecord(result[0])
  const descriptionObject = asRecord(row[descriptionField])
  const secret = String(descriptionObject["Collaboration~Documents/secret"] ?? "")
  if (!secret) {
    throw new Error(`Document secret not found for field ${descriptionField}`)
  }
  return secret
}

async function writeDocumentMarkdown(config: FiberyConfig, secret: string, markdown: string): Promise<void> {
  const workspace = normalizeWorkspace(config.workspace)
  const response = await fetch(`https://${workspace}/api/documents/${secret}?format=md`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Token ${config.token}`,
    },
    body: JSON.stringify({ content: markdown }),
  })
  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Failed to update document (${response.status}): ${text}`)
  }
}

async function setCollectionField(
  config: FiberyConfig,
  typeId: string,
  entityId: string,
  fieldId: string,
  itemIds: string[],
): Promise<void> {
  const queryResult = await executeCommand(config, {
    command: "fibery.entity/query",
    args: {
      query: {
        "q/from": typeId,
        "q/select": [
          "fibery/id",
          {
            [fieldId]: {
              "q/select": ["fibery/id"],
              "q/limit": "q/no-limit",
            },
          },
        ],
        "q/where": ["=", ["fibery/id"], "$id"],
        "q/limit": 1,
      },
      params: {
        "$id": entityId,
      },
    },
  })

  let existingIds: string[] = []
  if (Array.isArray(queryResult) && queryResult.length > 0) {
    const entity = asRecord(queryResult[0])
    const items = entity[fieldId]
    if (Array.isArray(items)) {
      existingIds = items.map((item) => String(asRecord(item)["fibery/id"] ?? "")).filter((id) => id.length > 0)
    }
  }

  const unique = uniqueIds(itemIds)
  const uniqueExisting = uniqueIds(existingIds)
  if (uniqueExisting.length > 0) {
    await executeCommand(config, {
      command: "fibery.entity/remove-collection-items",
      args: {
        type: typeId,
        field: fieldId,
        entity: {
          "fibery/id": entityId,
        },
        items: uniqueExisting.map((id) => ({ "fibery/id": id })),
      },
    })
  }

  if (unique.length === 0) {
    return
  }
  await executeCommand(config, {
    command: "fibery.entity/add-collection-items",
    args: {
      type: typeId,
      field: fieldId,
      entity: {
        "fibery/id": entityId,
      },
      items: unique.map((id) => ({ "fibery/id": id })),
    },
  })
}

async function createItem(kind: "bug", args: CreateBugArgs): Promise<Record<string, unknown>>
async function createItem(kind: "feature", args: CreateFeatureArgs): Promise<Record<string, unknown>>
async function createItem(kind: ItemKind, args: CreateBugArgs | CreateFeatureArgs): Promise<Record<string, unknown>> {
  const config = await getConfig()
  const mapping = await resolveTypeMapping(config, kind)
  const title = args.title.trim()
  if (!title) {
    throw new Error("title must not be empty")
  }
  if (!args.description_markdown.trim()) {
    throw new Error("description_markdown must not be empty")
  }

  const existing = await queryByName(config, mapping, title, 10)
  if (existing.length > 0) {
    return {
      action: "duplicate_detected",
      message: "Matching item already exists. Creation is blocked.",
      matches: existing.map((entity) => ({
        id: primaryId(entity),
        title: entityName(entity, mapping.nameField),
      })),
    }
  }

  const defaultStatus = DEFAULT_STATUS_BY_KIND[kind]
  const shouldClearMilestoneAfterCreate = args.milestone === undefined || args.milestone.trim().length === 0
  const betaIdentifier = args.beta ?? undefined
  const shouldClearBetaAfterCreate = betaIdentifier === undefined
  const entity: Record<string, JsonValue> = {
    [mapping.nameField]: title,
  }
  const statusValue = args.status || defaultStatus
  const statusTypeId = mapping.fieldTypes[mapping.statusField] ?? ""
  if (!statusTypeId) {
    throw new Error(`Could not resolve enum type for ${mapping.statusField}`)
  }
  const statusId = await resolveEnumOptionId(config, statusTypeId, statusValue)
  entity[mapping.statusField] = { "fibery/id": statusId }

  if (kind === "bug") {
    if (args.priority) {
      const priorityTypeId = mapping.fieldTypes[mapping.priorityField] ?? ""
      if (!priorityTypeId) {
        throw new Error(`Could not resolve enum type for ${mapping.priorityField}`)
      }
      const priorityId = await resolveEnumOptionId(config, priorityTypeId, args.priority)
      entity[mapping.priorityField] = { "fibery/id": priorityId }
    }
  }

  if (kind === "feature") {
    if (args.size) {
      const sizeTypeId = mapping.fieldTypes[mapping.sizeField] ?? ""
      if (!sizeTypeId) {
        throw new Error(`Could not resolve enum type for ${mapping.sizeField}`)
      }
      const sizeId = await resolveEnumOptionId(config, sizeTypeId, args.size)
      entity[mapping.sizeField] = { "fibery/id": sizeId }
    }
    if (args.importance) {
      const importanceTypeId = mapping.fieldTypes[mapping.importanceField] ?? ""
      if (!importanceTypeId) {
        throw new Error(`Could not resolve enum type for ${mapping.importanceField}`)
      }
      const importanceId = await resolveEnumOptionId(config, importanceTypeId, args.importance)
      entity[mapping.importanceField] = { "fibery/id": importanceId }
    }
  }

  if (args.milestone) {
    const milestoneIds = await resolveEntityIdsByName(config, RELATED_TYPE_IDS.milestone, RELATED_TYPE_IDS.milestoneNameField, [args.milestone])
    if (milestoneIds.length > 0) {
      entity[mapping.milestoneField] = { "fibery/id": milestoneIds[0] }
    }
  }
  if (betaIdentifier !== undefined) {
    const betaId = await resolveBetaIdByIdentifier(config, betaIdentifier)
    entity[mapping.betaField] = { "fibery/id": betaId }
  }

  const created = await executeCommand(config, {
    command: "fibery.entity/create",
    args: {
      type: mapping.typeId,
      entity,
    },
  })

  const createdEntity = asRecord(created)
  const createdId = String(createdEntity["fibery/id"] ?? "")
  if (!createdId) {
    throw new Error("Failed to extract created entity id")
  }

  if (shouldClearMilestoneAfterCreate || shouldClearBetaAfterCreate) {
    const clearEntity: Record<string, JsonValue> = {
      "fibery/id": createdId,
    }
    if (shouldClearMilestoneAfterCreate) {
      clearEntity[mapping.milestoneField] = null
    }
    if (shouldClearBetaAfterCreate) {
      clearEntity[mapping.betaField] = null
    }
    await executeCommand(config, {
      command: "fibery.entity/update",
      args: {
        type: mapping.typeId,
        entity: clearEntity,
      },
    })
  }

  const descriptionType = mapping.fieldTypes[mapping.descriptionField] ?? ""
  if (!descriptionType.toLowerCase().includes("document")) {
    throw new Error(`Expected document field for ${mapping.descriptionField}`)
  }
  const secret = await getDocumentSecret(config, mapping.typeId, createdId, mapping.descriptionField)
  await writeDocumentMarkdown(config, secret, args.description_markdown)

  if (args.domains) {
    const domainIds = mapDomainNamesToIds(args.domains)
    await setCollectionField(config, mapping.typeId, createdId, mapping.domainsField, domainIds)
  }

  const explicitDiscordIds = args.discord_ids ? validateEntityIds(args.discord_ids, "discord_ids") : []
  const threadDiscordIds = args.discord_thread_id ? [await upsertDiscordThread(config, args.discord_thread_id)] : []
  const discordIds = uniqueIds([...explicitDiscordIds, ...threadDiscordIds])
  if (discordIds.length > 0) {
    await setCollectionField(config, mapping.typeId, createdId, mapping.discordsField, discordIds)
  }

  if (kind === "bug" && args.linked_feature_ids_or_names) {
    const linkIds = await resolveEntityIdsByName(config, WORKFLOW_TYPE_IDS.feature, RELATED_TYPE_IDS.nameField, args.linked_feature_ids_or_names)
    await setCollectionField(config, mapping.typeId, createdId, mapping.linksField, linkIds)
  }
  if (kind === "feature" && args.linked_bug_ids_or_names) {
    const linkIds = await resolveEntityIdsByName(config, WORKFLOW_TYPE_IDS.bug, RELATED_TYPE_IDS.nameField, args.linked_bug_ids_or_names)
    await setCollectionField(config, mapping.typeId, createdId, mapping.linksField, linkIds)
  }

  return {
    action: "created",
    kind,
    type: mapping.typeId,
    title,
    id: createdId,
    result: created,
  }
}

async function resolveTargetEntity(
  kind: ItemKind,
  idOrName: string,
): Promise<{ mapping: TypeMapping; id: string; title?: string; matches?: Array<Record<string, unknown>> }> {
  const config = await getConfig()
  const mapping = await resolveTypeMapping(config, kind)
  const normalized = idOrName.trim()
  if (!normalized) {
    throw new Error("id_or_name must not be empty")
  }

  if (isUuid(normalized)) {
    return { mapping, id: normalized }
  }

  const matches = await queryByName(config, mapping, normalized, 20)
  if (matches.length === 0) {
    throw new Error(`No ${kind} found with name: ${normalized}`)
  }
  if (matches.length > 1) {
    return {
      mapping,
      id: "",
      matches: matches.map((entity) => ({
        id: primaryId(entity),
        title: entityName(entity, mapping.nameField),
      })),
    }
  }

  const target = matches[0]
  return {
    mapping,
    id: primaryId(target),
    title: entityName(target, mapping.nameField),
  }
}

async function updateItem(kind: "bug", args: UpdateBugArgs): Promise<Record<string, unknown>>
async function updateItem(kind: "feature", args: UpdateFeatureArgs): Promise<Record<string, unknown>>
async function updateItem(kind: ItemKind, args: UpdateBugArgs | UpdateFeatureArgs): Promise<Record<string, unknown>> {
  const config = await getConfig()
  const target = await resolveTargetEntity(kind, args.id_or_name)

  if (!target.id && target.matches) {
    return {
      action: "needs_disambiguation",
      message: `Multiple ${kind} items match '${args.id_or_name}'. Provide an id instead.`,
      matches: target.matches,
    }
  }

  const entity: Record<string, JsonValue> = {
    "fibery/id": target.id,
  }
  if (args.title) {
    entity[target.mapping.nameField] = args.title
  }

  if (args.status) {
    const statusTypeId = target.mapping.fieldTypes[target.mapping.statusField] ?? ""
    const statusId = await resolveEnumOptionId(config, statusTypeId, args.status)
    entity[target.mapping.statusField] = { "fibery/id": statusId }
  }

  if (kind === "bug" && args.priority) {
    const priorityTypeId = target.mapping.fieldTypes[target.mapping.priorityField] ?? ""
    const priorityId = await resolveEnumOptionId(config, priorityTypeId, args.priority)
    entity[target.mapping.priorityField] = { "fibery/id": priorityId }
  }

  if (kind === "feature" && args.size) {
    const sizeTypeId = target.mapping.fieldTypes[target.mapping.sizeField] ?? ""
    const sizeId = await resolveEnumOptionId(config, sizeTypeId, args.size)
    entity[target.mapping.sizeField] = { "fibery/id": sizeId }
  }

  if (kind === "feature" && args.importance) {
    const importanceTypeId = target.mapping.fieldTypes[target.mapping.importanceField] ?? ""
    const importanceId = await resolveEnumOptionId(config, importanceTypeId, args.importance)
    entity[target.mapping.importanceField] = { "fibery/id": importanceId }
  }

  if (args.clear_milestone) {
    entity[target.mapping.milestoneField] = null
  } else if (args.milestone !== undefined) {
    const milestoneValue = args.milestone.trim()
    if (milestoneValue.length === 0) {
      entity[target.mapping.milestoneField] = null
    } else {
      const milestoneIds = await resolveEntityIdsByName(config, RELATED_TYPE_IDS.milestone, RELATED_TYPE_IDS.milestoneNameField, [milestoneValue])
      if (milestoneIds.length > 0) {
        entity[target.mapping.milestoneField] = { "fibery/id": milestoneIds[0] }
      }
    }
  }

  if (args.clear_beta) {
    entity[target.mapping.betaField] = null
  } else if (args.beta !== undefined) {
    const betaId = await resolveBetaIdByIdentifier(config, args.beta)
    entity[target.mapping.betaField] = { "fibery/id": betaId }
  }

  const hasEntityUpdates = Object.keys(entity).length > 1
  const hasCollectionUpdates =
    Boolean(args.domains) || Boolean(args.discord_ids) || Boolean(args.discord_thread_id) ||
    (kind === "bug" ? Boolean(args.linked_feature_ids_or_names) : Boolean(args.linked_bug_ids_or_names))
  const hasDescriptionUpdate = Boolean(args.description_markdown)

  if (!hasEntityUpdates && !hasCollectionUpdates && !hasDescriptionUpdate) {
    throw new Error("At least one update field is required")
  }

  if (hasEntityUpdates) {
    await executeCommand(config, {
      command: "fibery.entity/update",
      args: {
        type: target.mapping.typeId,
        entity,
      },
    })
  }

  if (target.mapping.descriptionField && args.description_markdown) {
    const descriptionType = target.mapping.fieldTypes[target.mapping.descriptionField] ?? ""
    if (descriptionType.toLowerCase().includes("document")) {
      const secret = await getDocumentSecret(config, target.mapping.typeId, target.id, target.mapping.descriptionField)
      await writeDocumentMarkdown(config, secret, args.description_markdown)
    } else {
      throw new Error(`Expected document field for ${target.mapping.descriptionField}`)
    }
  }

  if (target.mapping.domainsField && args.domains) {
    const domainIds = mapDomainNamesToIds(args.domains)
    await setCollectionField(config, target.mapping.typeId, target.id, target.mapping.domainsField, domainIds)
  }

  const explicitDiscordIds = args.discord_ids ? validateEntityIds(args.discord_ids, "discord_ids") : []
  const threadDiscordIds = args.discord_thread_id ? [await upsertDiscordThread(config, args.discord_thread_id)] : []
  const discordIds = uniqueIds([...explicitDiscordIds, ...threadDiscordIds])
  if (target.mapping.discordsField && discordIds.length > 0) {
    await setCollectionField(config, target.mapping.typeId, target.id, target.mapping.discordsField, discordIds)
  }

  if (kind === "bug" && args.linked_feature_ids_or_names) {
    const linkIds = await resolveEntityIdsByName(config, WORKFLOW_TYPE_IDS.feature, RELATED_TYPE_IDS.nameField, args.linked_feature_ids_or_names)
    await setCollectionField(config, target.mapping.typeId, target.id, target.mapping.linksField, linkIds)
  }
  if (kind === "feature" && args.linked_bug_ids_or_names) {
    const linkIds = await resolveEntityIdsByName(config, WORKFLOW_TYPE_IDS.bug, RELATED_TYPE_IDS.nameField, args.linked_bug_ids_or_names)
    await setCollectionField(config, target.mapping.typeId, target.id, target.mapping.linksField, linkIds)
  }

  return {
    action: "updated",
    kind,
    type: target.mapping.typeId,
    id: target.id,
    result: "ok",
  }
}

async function resolveBugFeatureRelationField(
  bugMapping: TypeMapping,
  featureTypeId: string,
): Promise<string | null> {
  const hardcoded = WORKFLOW_FIELD_IDS.bug.linksField
  if (hardcoded in bugMapping.fieldTypes) {
    return hardcoded
  }
  for (const [fieldId, valueType] of Object.entries(bugMapping.fieldTypes)) {
    if (valueType === featureTypeId) {
      return fieldId
    }
  }
  return null
}

export const create_bug = tool({
  description: "Create a Fibery bug with duplicate check",
  args: {
    title: tool.schema.string().describe("Bug title"),
    description_markdown: tool.schema.string().describe("Bug description markdown"),
    status: tool.schema.enum(BUG_STATUS_VALUES).optional().describe("Status value"),
    priority: tool.schema.enum(BUG_PRIORITY_VALUES).optional().describe("Priority value"),
    milestone: tool.schema.string().optional().describe("Milestone name or id"),
    beta: tool.schema.number().describe("Beta identifier such as 171").nullable().optional(),
    domains: tool.schema.array(tool.schema.enum(DOMAIN_OPTIONS)).optional().describe("Domain names"),
    discord_ids: tool.schema.array(tool.schema.string()).optional().describe("Discord entity ids"),
    discord_thread_id: tool.schema.string().optional().describe("Discord thread channel id"),
    linked_feature_ids_or_names: tool.schema.array(tool.schema.string()).optional().describe("Linked feature ids or names"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    return stringifyToolOutput(await createItem("bug", args as CreateBugArgs))
  },
})

export const create_feature = tool({
  description: "Create a Fibery feature with duplicate check",
  args: {
    title: tool.schema.string().describe("Feature title"),
    description_markdown: tool.schema.string().describe("Feature description markdown"),
    status: tool.schema.enum(FEATURE_STATUS_VALUES).optional().describe("Status value"),
    size: tool.schema.enum(FEATURE_SIZE_VALUES).optional().describe("Feature size value"),
    importance: tool.schema.enum(FEATURE_IMPORTANCE_VALUES).optional().describe("Feature importance value"),
    milestone: tool.schema.string().optional().describe("Milestone name or id"),
    beta: tool.schema.number().describe("Beta identifier such as 171").nullable().optional(),
    domains: tool.schema.array(tool.schema.enum(DOMAIN_OPTIONS)).optional().describe("Domain names"),
    discord_ids: tool.schema.array(tool.schema.string()).optional().describe("Discord entity ids"),
    discord_thread_id: tool.schema.string().optional().describe("Discord thread channel id"),
    linked_bug_ids_or_names: tool.schema.array(tool.schema.string()).optional().describe("Linked bug ids or names"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    return stringifyToolOutput(await createItem("feature", args as CreateFeatureArgs))
  },
})

export const update_bug = tool({
  description: "Update a Fibery bug by id or exact name",
  args: {
    id_or_name: tool.schema.string().describe("Bug id or exact name"),
    title: tool.schema.string().optional().describe("New title"),
    description_markdown: tool.schema.string().optional().describe("New description markdown"),
    status: tool.schema.enum(BUG_STATUS_VALUES).optional().describe("New status"),
    priority: tool.schema.enum(BUG_PRIORITY_VALUES).optional().describe("New priority"),
    milestone: tool.schema.string().optional().describe("Milestone name or id"),
    beta: tool.schema.number().optional().describe("Beta identifier such as 171"),
    clear_milestone: tool.schema.boolean().optional().describe("Clear milestone relation"),
    clear_beta: tool.schema.boolean().optional().describe("Clear beta relation"),
    domains: tool.schema.array(tool.schema.enum(DOMAIN_OPTIONS)).optional().describe("Domain names"),
    discord_ids: tool.schema.array(tool.schema.string()).optional().describe("Discord entity ids"),
    discord_thread_id: tool.schema.string().optional().describe("Discord thread channel id"),
    linked_feature_ids_or_names: tool.schema.array(tool.schema.string()).optional().describe("Linked feature ids or names"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    return stringifyToolOutput(await updateItem("bug", args as UpdateBugArgs))
  },
})

export const update_feature = tool({
  description: "Update a Fibery feature by id or exact name",
  args: {
    id_or_name: tool.schema.string().describe("Feature id or exact name"),
    title: tool.schema.string().optional().describe("New title"),
    description_markdown: tool.schema.string().optional().describe("New description markdown"),
    status: tool.schema.enum(FEATURE_STATUS_VALUES).optional().describe("New status"),
    size: tool.schema.enum(FEATURE_SIZE_VALUES).optional().describe("New size"),
    importance: tool.schema.enum(FEATURE_IMPORTANCE_VALUES).optional().describe("New importance"),
    milestone: tool.schema.string().optional().describe("Milestone name or id"),
    beta: tool.schema.number().optional().describe("Beta identifier such as 171"),
    clear_milestone: tool.schema.boolean().optional().describe("Clear milestone relation"),
    clear_beta: tool.schema.boolean().optional().describe("Clear beta relation"),
    domains: tool.schema.array(tool.schema.enum(DOMAIN_OPTIONS)).optional().describe("Domain names"),
    discord_ids: tool.schema.array(tool.schema.string()).optional().describe("Discord entity ids"),
    discord_thread_id: tool.schema.string().optional().describe("Discord thread channel id"),
    linked_bug_ids_or_names: tool.schema.array(tool.schema.string()).optional().describe("Linked bug ids or names"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    return stringifyToolOutput(await updateItem("feature", args as UpdateFeatureArgs))
  },
})

export const find_items = tool({
  description: "Find Fibery bugs or features by exact title",
  args: {
    kind: tool.schema.enum(["bug", "feature"]).describe("Item kind to search"),
    title: tool.schema.string().describe("Exact title to search"),
    limit: tool.schema.number().optional().describe("Max results"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    const mapping = await resolveTypeMapping(config, args.kind)
    const limit = Number.isFinite(args.limit) && args.limit && args.limit > 0 ? Math.floor(args.limit) : 20
    const entities = await queryByName(config, mapping, args.title, limit)
    return stringifyToolOutput({
      kind: args.kind,
      type: mapping.typeId,
      count: entities.length,
      items: entities.map((entity) => ({
        id: primaryId(entity),
        title: entityName(entity, mapping.nameField),
        raw: entity,
      })),
    })
  },
})

export const link_bug_to_feature = tool({
  description: "Link a bug to a feature using a configured relation field",
  args: {
    bug_id_or_name: tool.schema.string().describe("Bug id or exact name"),
    feature_id_or_name: tool.schema.string().describe("Feature id or exact name"),
    relation_field: tool.schema.string().optional().describe("Bug relation field id"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    const bugTarget = await resolveTargetEntity("bug", args.bug_id_or_name)
    if (!bugTarget.id && bugTarget.matches) {
      return stringifyToolOutput({
        action: "needs_disambiguation",
        message: `Multiple bugs match '${args.bug_id_or_name}'. Provide bug id.`,
        matches: bugTarget.matches,
      })
    }

    const featureTarget = await resolveTargetEntity("feature", args.feature_id_or_name)
    if (!featureTarget.id && featureTarget.matches) {
      return stringifyToolOutput({
        action: "needs_disambiguation",
        message: `Multiple features match '${args.feature_id_or_name}'. Provide feature id.`,
        matches: featureTarget.matches,
      })
    }

    const relationField =
      args.relation_field || (await resolveBugFeatureRelationField(bugTarget.mapping, featureTarget.mapping.typeId))
    if (!relationField) {
      throw new Error("relation_field is required. Hardcoded mapping was not found on the bug type.")
    }

    const result = await executeCommand(config, {
      command: "fibery.entity/add-collection-items",
      args: {
        type: bugTarget.mapping.typeId,
        field: relationField,
        entity: {
          "fibery/id": bugTarget.id,
        },
        items: [
          {
            "fibery/id": featureTarget.id,
          },
        ],
      },
    })

    return stringifyToolOutput({
      action: "linked",
      bug_id: bugTarget.id,
      feature_id: featureTarget.id,
      relation_field: relationField,
      result,
    })
  },
})

export const discover_domains = tool({
  description: "Discover current Fibery domains and suggested constants",
  args: {
    changed_paths: tool.schema.array(tool.schema.string()).optional().describe("Changed file paths for domain inference"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    const rows = await queryTypeRecords(config, RELATED_TYPE_IDS.domain, {
      "fibery/id": "fibery/id",
      [RELATED_TYPE_IDS.nameField]: RELATED_TYPE_IDS.nameField,
    }, 500)

    const domains = rows
      .map((row) => ({
        id: String(row["fibery/id"] ?? ""),
        name: String(row[RELATED_TYPE_IDS.nameField] ?? ""),
      }))
      .filter((row) => row.id.length > 0 && row.name.length > 0)
      .sort((a, b) => a.name.localeCompare(b.name))

    const inferred = args.changed_paths ? inferDomainsFromPaths(args.changed_paths) : []
    return stringifyToolOutput({
      count: domains.length,
      domains,
      inferred_domains: inferred,
      suggested_constants: renderDomainConstants(domains),
    })
  },
})

export const list_milestones = tool({
  description: "List available milestones for workflow selection",
  args: {},
  async execute(_args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    const milestones = await listMilestones(config)
    return stringifyToolOutput({
      count: milestones.length,
      milestones,
    })
  },
})

export const list_recent_betas = tool({
  description: "List recent betas for workflow selection",
  args: {
    limit: tool.schema.number().optional().describe("Number of recent betas to return"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    const limit = Number.isFinite(args.limit) && args.limit && args.limit > 0 ? Math.floor(args.limit) : 5
    const betas = await listRecentBetas(config, limit)
    return stringifyToolOutput({
      count: betas.length,
      betas,
    })
  },
})

export const refresh_schema_cache = tool({
  description: "Refresh cached Fibery schema used by workflow tools",
  args: {},
  async execute(_args, context) {
    setEnvBase(context?.worktree)
    const config = await getConfig()
    await getSchema(config, true)
    return stringifyToolOutput({
      refreshed_at: new Date(schemaCachedAt).toISOString(),
    })
  },
})
