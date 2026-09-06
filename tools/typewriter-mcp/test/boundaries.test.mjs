import { test } from "node:test";
import assert from "node:assert/strict";
import { assertReadOnly } from "../dist/sql.js";
import { GreptimeClient, toolResult, MAX_OUTPUT_BYTES } from "../dist/client.js";

test("SQL boundary accepts read forms and rejects disguised writes and batches", () => {
    for (const sql of ["SELECT 1", "WITH x AS (SELECT 1 AS n) SELECT * FROM x", "EXPLAIN SELECT * FROM t", 'DESCRIBE "opentelemetry_traces"', "SHOW TABLES", "SELECT 'drop; table' AS text"]) assert.doesNotThrow(() => assertReadOnly(sql), sql);
    for (const sql of ["/* safe */ DELETE FROM t", "-- read\nDROP TABLE t", "SELECT 1; DELETE FROM t", "WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x", "SELECT * INTO other FROM t", "COPY t TO 'file'", "SHOW TABLES; SELECT 1", "EXPLAIN DELETE FROM t", "SELECT * FROM t FOR UPDATE"]) assert.throws(() => assertReadOnly(sql), undefined, sql);
});

test("query rejects writes before HTTP and preserves nanoseconds exactly", async () => {
    let calls = 0;
    const client = new GreptimeClient({}, async () => {
        calls++;
        return new Response('{"output":[{"records":{"schema":{"column_schemas":[{"name":"timestamp","data_type":"TimestampNanosecond"}]},"rows":[[1788658637000000001]]}}]}');
    });
    await assert.rejects(client.query("/* disguise */ DELETE FROM t"));
    assert.equal(calls, 0);
    assert.equal((await client.query("SELECT timestamp FROM t")).rows[0][0], "1788658637000000001");
});

test("whole MCP output stays bounded and marks omitted rows", () => {
    const result = toolResult({ columns: [{ name: "body", data_type: "String" }], rows: [["x".repeat(50_000)]], returned_rows: 1, received_rows: 1, truncated: false });
    assert.ok(Buffer.byteLength(JSON.stringify(result)) <= MAX_OUTPUT_BYTES);
    assert.equal(result.structuredContent.truncated, true);
    assert.equal(result.structuredContent.returned_rows, 0);
});

test("HTTP body cap cancels response and gives actionable error", async () => {
    const client = new GreptimeClient({}, async () => new Response("x".repeat(2_000_001)));
    await assert.rejects(client.query("SELECT 1"), /exceeds 2 MB/);
});

test("cleanup failure cannot replace the body limit diagnosis", async () => {
    const body = new ReadableStream({
        start(controller) { controller.enqueue(new Uint8Array(2_000_001)); },
        cancel() { throw new Error("cancel failed"); },
    });
    const client = new GreptimeClient({}, async () => new Response(body));
    await assert.rejects(client.query("SELECT 1"), /exceeds 2 MB/);
});

test("timeout, caller cancellation, HTTP errors, SQL errors, and malformed JSON remain distinguishable", async () => {
    const timeout = new GreptimeClient({}, async () => { throw new DOMException("timeout", "TimeoutError"); });
    await assert.rejects(timeout.query("SELECT 1"), /timed out/);
    await assert.rejects(timeout.query("SELECT 1", 1, AbortSignal.abort()), /cancelled by caller/);
    const http = new GreptimeClient({}, async () => new Response("private response", { status: 401 }));
    await assert.rejects(http.query("SELECT 1"), /HTTP 401/);
    const malformed = new GreptimeClient({}, async () => new Response("not JSON"));
    await assert.rejects(malformed.query("SELECT 1"), /invalid JSON/);
    const sql = new GreptimeClient({}, async () => Response.json({ code: 3000, error: "unknown column" }));
    await assert.rejects(sql.query("SELECT 1"), /code 3000.*unknown column/);
});
