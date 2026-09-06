import { parse } from "lossless-json";
import { assertReadOnly, quoteIdentifier } from "./sql.js";

export const MAX_OUTPUT_BYTES = 30_000;
const MAX_BODY_BYTES = 2_000_000;
export type QueryResult = { environment: "local"; database: string; queried_at: string; truncation_reason: string | null; columns: { name: string; data_type: string }[]; rows: unknown[][]; returned_rows: number; received_rows: number; truncated: boolean; execution_time_ms?: number };

/** One local HTTP endpoint. Credentials stay in the process environment. */
export class GreptimeClient {
    private readonly url: URL;
    private readonly headers: Record<string, string>;
    private readonly schemas = new Map<string, { expires: number; columns: QueryResult["columns"] }>();

    constructor(env: NodeJS.ProcessEnv = process.env, private readonly fetcher: typeof fetch = fetch) {
        this.url = new URL("/v1/sql", env.GREPTIME_URL || "https://observability.local.seamlezz.net");
        if (!["http:", "https:"].includes(this.url.protocol) || this.url.username || this.url.password) throw new Error("Use an HTTP URL without embedded credentials.");
        this.url.searchParams.set("db", env.GREPTIME_DATABASE || "public");
        this.headers = { "Content-Type": "application/x-www-form-urlencoded", "X-Greptime-Timeout": "30s" };
        if (env.GREPTIME_USERNAME || env.GREPTIME_PASSWORD) {
            if (!env.GREPTIME_USERNAME || !env.GREPTIME_PASSWORD) throw new Error("Set both GREPTIME_USERNAME and GREPTIME_PASSWORD.");
            this.headers.Authorization = `Basic ${Buffer.from(`${env.GREPTIME_USERNAME}:${env.GREPTIME_PASSWORD}`).toString("base64")}`;
        }
    }

    private async execute(sql: string, maxRows = 100, signal?: AbortSignal): Promise<QueryResult> {
        assertReadOnly(sql);
        if (!Number.isInteger(maxRows) || maxRows < 1 || maxRows > 500) throw new Error("max_rows must be between 1 and 500.");
        const timeout = AbortSignal.timeout(30_000);
        const response = await this.fetcher(this.url, {
            method: "POST", headers: this.headers, body: new URLSearchParams({ sql }),
            signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
            redirect: "error",
        });
        if (!response.ok) { await response.body?.cancel(); throw new Error(`Greptime HTTP ${response.status}.`); }
        if (!response.body) throw new Error("Greptime returned an empty response.");
        const reader = response.body.getReader();
        const chunks: Uint8Array[] = [];
        let bytes = 0;
        try {
            while (true) {
                const part = await reader.read();
                if (part.done) break;
                bytes += part.value.byteLength;
                if (bytes > MAX_BODY_BYTES) throw new Error("Greptime response exceeds 2 MB. Narrow the time window, columns, or SQL LIMIT.");
                chunks.push(part.value);
            }
        } finally { await reader.cancel().catch(() => undefined); reader.releaseLock(); }
        let data: any;
        try {
            data = parse(Buffer.concat(chunks).toString("utf8"), null, value => {
                const number = Number(value);
                return /^-?\d+$/.test(value) && !Number.isSafeInteger(number) ? value : number;
            });
        } catch { throw new Error("Greptime returned invalid JSON."); }
        if (data.error || data.code && data.code !== 0) {
            this.schemas.clear();
            throw new Error(`Greptime query failed (code ${data.code ?? "unknown"}). ${String(data.error ?? "").slice(0, 1000)}`);
        }
        const records = data.output?.[0]?.records;
        if (!records || !Array.isArray(records.rows) || !Array.isArray(records.schema?.column_schemas)) throw new Error("Greptime returned no tabular result.");
        const result: QueryResult = {
            environment: "local", database: this.url.searchParams.get("db")!, queried_at: new Date().toISOString(),
            truncation_reason: records.rows.length > maxRows ? "row_limit" : null,
            columns: records.schema.column_schemas.map((c: any) => ({ name: c.name, data_type: c.data_type })),
            rows: records.rows.slice(0, maxRows), received_rows: records.rows.length,
            returned_rows: Math.min(maxRows, records.rows.length), truncated: records.rows.length > maxRows,
            execution_time_ms: data.execution_time_ms,
        };
        return result;
    }

    async query(sql: string, maxRows = 100, signal?: AbortSignal): Promise<QueryResult> {
        try { return await this.execute(sql, maxRows, signal); }
        catch (error) {
            if (signal?.aborted) throw new Error("Query cancelled by caller.");
            if (error instanceof Error && error.name === "TimeoutError") throw new Error("Greptime query timed out after 30 seconds. Narrow the query.");
            throw error;
        }
    }

    async schema(table?: string, filter?: string, signal?: AbortSignal): Promise<unknown> {
        if (!table) return this.query("SHOW TABLES", 500, signal);
        const cached = this.schemas.get(table);
        let columns = cached && cached.expires > Date.now() ? cached.columns : undefined;
        if (!columns) {
            const result = await this.query(`DESCRIBE ${quoteIdentifier(table)}`, 500, signal);
            const nameIndex = result.columns.findIndex(c => /^(column|column_name|field)$/i.test(c.name));
            const typeIndex = result.columns.findIndex(c => /^(type|data_type)$/i.test(c.name));
            if (nameIndex < 0 || typeIndex < 0 || result.truncated) throw new Error("Unrecognized or incomplete DESCRIBE response.");
            columns = result.rows.map(row => ({ name: String(row[nameIndex]), data_type: String(row[typeIndex]) }));
            this.schemas.set(table, { columns, expires: Date.now() + 60_000 });
        }
        return { environment: "local", database: this.url.searchParams.get("db")!, queried_at: new Date().toISOString(), table, columns: columns.filter(c => !filter || c.name.toLowerCase().includes(filter.toLowerCase())), total_columns: columns.length };
    }

    async columns(table: string, signal?: AbortSignal): Promise<Set<string>> {
        const schema = await this.schema(table, undefined, signal) as { columns: QueryResult["columns"] };
        return new Set(schema.columns.map(c => c.name));
    }
}

/** Budget the entire MCP result, including duplicated text and structured payloads. */
export function toolResult(value: unknown): any {
    const payload = JSON.parse(JSON.stringify(value));
    const wrap = () => ({ content: [{ type: "text", text: JSON.stringify(payload) }], structuredContent: payload });
    let result = wrap();
    const trim = (node: any): boolean => {
        if (!node || typeof node !== "object") return false;
        for (const key of ["rows", "columns"]) {
            if (Array.isArray(node[key]) && node[key].length) {
                node[key].pop(); node.truncated = true; node.truncation_reason = "output_byte_limit";
                if (key === "rows") node.returned_rows = node.rows.length;
                return true;
            }
        }
        return Object.values(node).some(trim);
    };
    while (Buffer.byteLength(JSON.stringify(result)) > MAX_OUTPUT_BYTES) {
        if (!trim(payload)) throw new Error("Result metadata exceeds output budget. Narrow the query.");
        result = wrap();
    }
    return result;
}
