import { GreptimeClient } from "./client.js";
import { quoteIdentifier as id, quoteString as str } from "./sql.js";

type Window = { from: string; to: string };
type TraceSearch = Window & { service?: string; operation?: string; host_id?: string; outcome?: string; limit: number };
type LogSearch = Window & { service?: string; severity?: string; trace_id?: string; text?: string; limit: number };

function windowSql({ from, to }: Window): string {
    if (!Number.isFinite(Date.parse(from)) || !Number.isFinite(Date.parse(to)) || Date.parse(from) >= Date.parse(to)) throw new Error("Use an ordered UTC time window: from < to.");
    return `timestamp >= ${str(from)} AND timestamp < ${str(to)}`;
}

export class Telemetry {
    constructor(private readonly client: GreptimeClient) {}

    async searchTraces(args: TraceSearch, signal?: AbortSignal) {
        const available = await this.client.columns("opentelemetry_traces", signal);
        const columns = ["timestamp", "timestamp_end", "duration_nano", "trace_id", "span_id", "parent_span_id", "service_name", "span_name", "span_status_code", "span_status_message", "span_attributes.host.id", "span_attributes.messaging.response.variant", "span_attributes.messaging.response.success", "span_attributes.exception.slug"];
        const where = [windowSql(args)];
        for (const [column, value] of [["service_name", args.service], ["span_name", args.operation], ["span_attributes.host.id", args.host_id], ["span_attributes.messaging.response.variant", args.outcome]]) {
            if (value === undefined) continue;
            if (!available.has(column!)) throw new Error(`Filter column is unavailable: ${column}. Inspect telemetry_schema.`);
            where.push(`${id(column!)} = ${str(value)}`);
        }
        return this.client.query(`SELECT ${columns.filter(c => available.has(c)).map(id).join(", ")} FROM opentelemetry_traces WHERE ${where.join(" AND ")} ORDER BY timestamp DESC LIMIT ${args.limit + 1}`, args.limit, signal);
    }

    async searchLogs(args: LogSearch, signal?: AbortSignal) {
        const available = await this.client.columns("opentelemetry_logs", signal);
        const service = available.has("service_name") ? id("service_name") : "json_get_string(resource_attributes, '$[\"service.name\"]')";
        const where = [windowSql(args)];
        for (const [column, value] of [[service, args.service], ["severity_text", args.severity], ["trace_id", args.trace_id]]) {
            if (value !== undefined) where.push(`${column} = ${str(value)}`);
        }
        if (args.text !== undefined) where.push(`strpos(body, ${str(args.text)}) > 0`);
        return this.client.query(`SELECT timestamp, trace_id, span_id, severity_text, body, ${service} AS service_name FROM opentelemetry_logs WHERE ${where.join(" AND ")} ORDER BY timestamp DESC LIMIT ${args.limit + 1}`, args.limit, signal);
    }

    async getTrace(args: Window & { trace_id: string; include_logs: boolean }, signal?: AbortSignal) {
        const available = await this.client.columns("opentelemetry_traces", signal);
        const columns = ["timestamp", "timestamp_end", "duration_nano", "trace_id", "span_id", "parent_span_id", "service_name", "span_name", "span_status_code", "span_status_message", "span_events", ...[...available].filter(c => c.startsWith("span_attributes.") && /host|response|exception|realm|service/.test(c))];
        const spans = await this.client.query(`SELECT ${columns.filter(c => available.has(c)).map(id).join(", ")} FROM opentelemetry_traces WHERE ${windowSql(args)} AND trace_id = ${str(args.trace_id)} ORDER BY timestamp LIMIT 501`, 500, signal);
        const logs = args.include_logs ? await this.searchLogs({ ...args, limit: 100 }, signal) : undefined;
        return { trace_id: args.trace_id, spans, logs, limit_notice: "Up to 500 spans and 100 logs. Reaching a SQL LIMIT may omit further records. Timestamps with TimestampNanosecond type are exact epoch nanoseconds." };
    }
}
