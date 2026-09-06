import { test } from "node:test";
import assert from "node:assert/strict";
import { Telemetry } from "../dist/telemetry.js";
import { GreptimeClient } from "../dist/client.js";
import { assertReadOnly } from "../dist/sql.js";

test("log service uses a quoted JSON key and overfetches to detect omitted rows", async () => {
    const queries = [];
    const telemetry = new Telemetry({
        columns: async () => new Set(["timestamp", "resource_attributes", "body"]),
        query: async (sql, limit) => { assertReadOnly(sql); queries.push({ sql, limit }); return {}; },
    });
    await telemetry.searchLogs({ from: "2026-09-06T01:30:00Z", to: "2026-09-06T02:00:00Z", service: "loader", text: "can't_%", limit: 2 });
    assert.match(queries[0].sql, /json_get_string\(resource_attributes, '\$\["service.name"\]'\)/);
    assert.match(queries[0].sql, /strpos\(body, 'can''t_%'\)/);
    assert.match(queries[0].sql, /LIMIT 3$/);
    assert.equal(queries[0].limit, 2);
});

test("HTTP query marks row truncation and includes reproducible query context", async () => {
    const client = new GreptimeClient({}, async () => Response.json({ output: [{ records: { schema: { column_schemas: [{ name: "n", data_type: "Int64" }] }, rows: [[1], [2], [3]] } }] }));
    const result = await client.query("SELECT n FROM t LIMIT 3", 2);
    assert.equal(result.truncated, true);
    assert.equal(result.truncation_reason, "row_limit");
    assert.equal(result.environment, "local");
    assert.equal(result.database, "public");
    assert.ok(Date.parse(result.queried_at));
    assert.deepEqual(result.rows, [[1], [2]]);
});
