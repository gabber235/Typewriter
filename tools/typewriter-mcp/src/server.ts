import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { GreptimeClient, toolResult } from "./client.js";
import { Telemetry } from "./telemetry.js";

const client = new GreptimeClient();
const telemetry = new Telemetry(client);
const server = new McpServer({ name: "typewriter", version: "0.1.0" }, {
    instructions: "Query local Typewriter telemetry only. Inspect schema before assuming attributes. Bound queries by UTC time and SQL LIMIT. Preserve opaque IDs exactly. Transport success is not lifecycle completion. Data can be stale or missing. This adapter enforces a SQL subset, not database permissions.",
});
const environment = z.enum(["local"]).default("local");
const limit = z.number().int().min(1).max(500).default(100);
const window = { from: z.iso.datetime(), to: z.iso.datetime() };

function register(name: string, description: string, inputSchema: Record<string, z.ZodType>, run: (args: any, signal: AbortSignal) => Promise<unknown>) {
    server.registerTool(name, { description, inputSchema: { environment, ...inputSchema }, annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false } }, async (args, extra) => {
        try { return toolResult(await run(args, extra.signal)); }
        catch (error) { return { isError: true, content: [{ type: "text", text: error instanceof Error ? error.message.slice(0, 1500) : "Telemetry query failed." }] }; }
    });
}

register("telemetry_health", "Check local Greptime connectivity and database version.", {}, (_, signal) => client.query("SELECT version() AS version, current_timestamp() AS server_time", 1, signal));
register("telemetry_schema", "List tables or inspect columns. column_filter is a case insensitive substring. Schema cache lasts 60 seconds.", { table: z.string().max(200).optional(), column_filter: z.string().max(200).optional() }, (args, signal) => client.schema(args.table, args.column_filter, signal));
register("telemetry_query", "Run one supported read SQL statement. Use explicit columns, UTC time bounds and LIMIT. max_rows caps returned rows, not server scan cost. Large results fail or are marked truncated.", { sql: z.string().max(32_000), max_rows: limit }, (args, signal) => client.query(args.sql, args.max_rows, signal));
register("search_traces", "Search spans by UTC window and exact optional filters. outcome filters messaging.response.variant, not span status. Results newest first; SQL LIMIT may omit further spans.", { ...window, service: z.string().max(300).optional(), operation: z.string().max(300).optional(), host_id: z.string().max(300).optional(), outcome: z.string().max(100).optional(), limit }, (args, signal) => telemetry.searchTraces(args, signal));
register("get_trace", "Fetch spans and optional correlated logs for an exact opaque trace ID within a UTC window. Bounded results may be incomplete.", { ...window, trace_id: z.string().min(1).max(200), include_logs: z.boolean().default(true) }, (args, signal) => telemetry.getTrace(args, signal));
register("search_logs", "Search logs within a UTC window, with exact service, severity or trace ID and literal body substring. Results newest first; SQL LIMIT may omit further logs.", { ...window, service: z.string().max(300).optional(), severity: z.string().max(50).optional(), trace_id: z.string().max(200).optional(), text: z.string().max(1000).optional(), limit }, (args, signal) => telemetry.searchLogs(args, signal));

await server.connect(new StdioServerTransport());
