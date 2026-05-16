import { tool } from "@opencode-ai/plugin"

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue }

type FiberyConfig = {
  workspace: string
  token: string
  maxRetries: number
  retryDelayMs: number
}

type FiberyCommand = {
  command: string
  args?: Record<string, JsonValue>
}

let schemaCache: unknown | null = null
let schemaCachedAt = 0

const defaultCacheTtlMs = 5 * 60 * 1000
let envBase = ""
let dotenvCache: Record<string, string> | null = null

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

async function getConfig(): Promise<FiberyConfig> {
  return {
    workspace: await required("FIBERY_WORKSPACE"),
    token: await required("FIBERY_API_TOKEN"),
    maxRetries: Number((await getEnv("FIBERY_MAX_RETRIES")) || "3"),
    retryDelayMs: Number((await getEnv("FIBERY_RETRY_DELAY_MS")) || "400"),
  }
}

async function wait(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms))
}

function normalizeWorkspace(workspace: string): string {
  const normalized = workspace.replace(/^https?:\/\//, "").replace(/\/$/, "")
  if (normalized.includes(".")) {
    return normalized
  }
  return `${normalized}.fibery.io`
}

function commandUrl(workspace: string): string {
  const host = normalizeWorkspace(workspace)
  return `https://${host}/api/commands`
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

function typeDisplayName(typeObject: Record<string, unknown>): string {
  const displayName = typeObject["fibery/display-name"]
  const name = typeObject["fibery/name"]
  if (typeof displayName === "string" && displayName.length > 0) return displayName
  if (typeof name === "string" && name.length > 0) return name
  return typeIdentifier(typeObject)
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

function fieldDisplayName(fieldObject: Record<string, unknown>): string {
  const displayName = fieldObject["fibery/display-name"]
  const name = fieldObject["fibery/name"]
  if (typeof displayName === "string" && displayName.length > 0) return displayName
  if (typeof name === "string" && name.length > 0) return name
  return fieldIdentifier(fieldObject)
}

function extractEnumValues(fieldObject: Record<string, unknown>): string[] {
  const enumLists: unknown[] = [
    fieldObject["fibery/enum-values"],
    fieldObject["fibery/enum-items"],
    fieldObject.enum,
  ]
  for (const candidate of enumLists) {
    if (Array.isArray(candidate)) {
      return candidate
        .map((item) => {
          if (typeof item === "string") return item
          const record = asRecord(item)
          const id = record["fibery/id"]
          const display = record["fibery/display-name"]
          const name = record["fibery/name"]
          if (typeof display === "string") return display
          if (typeof name === "string") return name
          if (typeof id === "string") return id
          return ""
        })
        .filter((value) => value.length > 0)
    }
  }
  return []
}

function pickTypeByIdentifier(schema: unknown, typeId: string): Record<string, unknown> | null {
  const types = extractTypes(schema)
  const exact = types.find((typeObject) => {
    const id = typeIdentifier(typeObject)
    const name = String(typeObject["fibery/name"] ?? "")
    return id === typeId || name === typeId
  })
  return exact ?? null
}

function includesFolded(value: string, query: string): boolean {
  return value.toLowerCase().includes(query.toLowerCase())
}

async function getSchema(forceRefresh: boolean): Promise<{ schema: unknown; source: string }> {
  if (!forceRefresh && schemaCache && Date.now() - schemaCachedAt < defaultCacheTtlMs) {
    return { schema: schemaCache, source: "cache" }
  }
  const config = await getConfig()
  const schema = await executeCommand(config, {
    command: "fibery.schema/query",
    args: {},
  })
  schemaCache = schema
  schemaCachedAt = Date.now()
  return { schema, source: "api" }
}

export const discover_schema = tool({
  description: "Fetch and cache Fibery schema for discovery",
  args: {
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const forceRefresh = Boolean(args.force_refresh)
    const { schema, source } = await getSchema(forceRefresh)
    const types = extractTypes(schema)
    return stringifyToolOutput({
      source,
      fetched_at: new Date(schemaCachedAt).toISOString(),
      type_count: types.length,
      types: types.slice(0, 200).map((typeObject) => ({
        id: typeIdentifier(typeObject),
        display_name: typeDisplayName(typeObject),
      })),
    })
  },
})

export const list_types = tool({
  description: "List Fibery types by optional text filter",
  args: {
    filter: tool.schema.string().optional().describe("Substring filter for type id or display name"),
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const { schema, source } = await getSchema(Boolean(args.force_refresh))
    const filter = (args.filter ?? "").trim()
    const types = extractTypes(schema)
      .map((typeObject) => ({
        id: typeIdentifier(typeObject),
        name: String(typeObject["fibery/name"] ?? ""),
        display_name: typeDisplayName(typeObject),
      }))
      .filter((typeObject) => typeObject.id.length > 0)

    const filtered = filter
      ? types.filter(
          (typeObject) =>
            includesFolded(typeObject.id, filter) ||
            includesFolded(typeObject.name, filter) ||
            includesFolded(typeObject.display_name, filter),
        )
      : types

    return stringifyToolOutput({
      source,
      count: filtered.length,
      items: filtered,
    })
  },
})

export const list_fields = tool({
  description: "List fields for a Fibery type",
  args: {
    type_id: tool.schema.string().describe("Type id or name, example Product/Bug"),
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const { schema, source } = await getSchema(Boolean(args.force_refresh))
    const typeObject = pickTypeByIdentifier(schema, args.type_id)
    if (!typeObject) {
      return stringifyToolOutput({
        source,
        error: `Type not found: ${args.type_id}`,
      })
    }

    const fields = extractFields(typeObject).map((fieldObject) => ({
      id: fieldIdentifier(fieldObject),
      name: String(fieldObject["fibery/name"] ?? ""),
      display_name: fieldDisplayName(fieldObject),
      value_type: String(fieldObject["fibery/type"] ?? fieldObject.type ?? ""),
      relation: String(fieldObject["fibery/relation"] ?? ""),
    }))

    return stringifyToolOutput({
      source,
      type: {
        id: typeIdentifier(typeObject),
        display_name: typeDisplayName(typeObject),
      },
      count: fields.length,
      fields,
    })
  },
})

export const list_enum_values = tool({
  description: "List enum values for a type field",
  args: {
    type_id: tool.schema.string().describe("Type id or name"),
    field_id: tool.schema.string().describe("Field id or name"),
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const { schema, source } = await getSchema(Boolean(args.force_refresh))
    const typeObject = pickTypeByIdentifier(schema, args.type_id)
    if (!typeObject) {
      return stringifyToolOutput({
        source,
        error: `Type not found: ${args.type_id}`,
      })
    }

    const fieldObject = extractFields(typeObject).find((field) => {
      const id = fieldIdentifier(field)
      const name = String(field["fibery/name"] ?? "")
      return id === args.field_id || name === args.field_id
    })

    if (!fieldObject) {
      return stringifyToolOutput({
        source,
        error: `Field not found: ${args.field_id}`,
      })
    }

    const values = extractEnumValues(fieldObject)
    return stringifyToolOutput({
      source,
      type: typeIdentifier(typeObject),
      field: fieldIdentifier(fieldObject),
      count: values.length,
      values,
    })
  },
})

export const find_type_by_name = tool({
  description: "Find Fibery types by fuzzy name match",
  args: {
    query: tool.schema.string().describe("Partial type name to search"),
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const query = args.query.trim()
    if (!query) {
      throw new Error("query must not be empty")
    }

    const { schema, source } = await getSchema(Boolean(args.force_refresh))
    const matches = extractTypes(schema)
      .map((typeObject) => ({
        id: typeIdentifier(typeObject),
        name: String(typeObject["fibery/name"] ?? ""),
        display_name: typeDisplayName(typeObject),
      }))
      .filter(
        (typeObject) =>
          includesFolded(typeObject.id, query) ||
          includesFolded(typeObject.name, query) ||
          includesFolded(typeObject.display_name, query),
      )

    return stringifyToolOutput({
      source,
      query,
      count: matches.length,
      matches,
    })
  },
})

export const discovery_summary = tool({
  description: "Summarize likely Feature and Bug setup from Fibery schema",
  args: {
    feature_hint: tool.schema.string().optional().describe("Type name hint for feature"),
    bug_hint: tool.schema.string().optional().describe("Type name hint for bug"),
    status_hint: tool.schema.string().optional().describe("Field name hint for status"),
    priority_hint: tool.schema.string().optional().describe("Field name hint for priority"),
    force_refresh: tool.schema.boolean().optional().describe("Skip cache and fetch from API"),
  },
  async execute(args, context) {
    setEnvBase(context?.worktree)
    const featureHint = (args.feature_hint ?? "Feature").trim()
    const bugHint = (args.bug_hint ?? "Bug").trim()
    const statusHint = (args.status_hint ?? "Status").trim()
    const priorityHint = (args.priority_hint ?? "Priority").trim()
    const { schema, source } = await getSchema(Boolean(args.force_refresh))

    const types = extractTypes(schema)
    const pickByHint = (hint: string): Record<string, unknown> | null => {
      const lower = hint.toLowerCase()
      const matches = types.filter((typeObject) => {
        const id = typeIdentifier(typeObject)
        const display = typeDisplayName(typeObject)
        return id.toLowerCase().includes(lower) || display.toLowerCase().includes(lower)
      })
      return matches[0] ?? null
    }

    const featureType = pickByHint(featureHint)
    const bugType = pickByHint(bugHint)

    const summarizeType = (typeObject: Record<string, unknown> | null) => {
      if (!typeObject) {
        return null
      }
      const fields = extractFields(typeObject)
      const byFieldHint = (hint: string) =>
        fields.find((fieldObject) => {
          const id = fieldIdentifier(fieldObject)
          const display = fieldDisplayName(fieldObject)
          const name = String(fieldObject["fibery/name"] ?? "")
          const lower = hint.toLowerCase()
          return (
            id.toLowerCase().includes(lower) ||
            display.toLowerCase().includes(lower) ||
            name.toLowerCase().includes(lower)
          )
        })

      const statusField = byFieldHint(statusHint)
      const priorityField = byFieldHint(priorityHint)

      return {
        id: typeIdentifier(typeObject),
        display_name: typeDisplayName(typeObject),
        status_field: statusField
          ? {
              id: fieldIdentifier(statusField),
              display_name: fieldDisplayName(statusField),
              values: extractEnumValues(statusField),
            }
          : null,
        priority_field: priorityField
          ? {
              id: fieldIdentifier(priorityField),
              display_name: fieldDisplayName(priorityField),
              values: extractEnumValues(priorityField),
            }
          : null,
        field_count: fields.length,
      }
    }

    return stringifyToolOutput({
      source,
      hints: {
        feature: featureHint,
        bug: bugHint,
        status: statusHint,
        priority: priorityHint,
      },
      feature_type: summarizeType(featureType),
      bug_type: summarizeType(bugType),
      type_count: types.length,
    })
  },
})
