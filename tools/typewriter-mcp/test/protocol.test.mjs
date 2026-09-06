import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

test("stdio exposes local telemetry tools and rejects writes through MCP", async () => {
    const client = new Client({ name: "protocol-test", version: "1" });
    try {
        await client.connect(new StdioClientTransport({ command: process.execPath, args: [fileURLToPath(new URL("../dist/server.js", import.meta.url))] }));
        const { tools } = await client.listTools();
        assert.deepEqual(tools.map(t => t.name), ["telemetry_health", "telemetry_schema", "telemetry_query", "search_traces", "get_trace", "search_logs"]);
        assert.ok(tools.every(t => t.annotations.readOnlyHint === true));
        const rejected = await client.callTool({ name: "telemetry_query", arguments: { sql: "/* disguise */ DELETE FROM t" } });
        assert.equal(rejected.isError, true);
        const environment = tools[0].inputSchema.properties.environment;
        assert.deepEqual(environment.enum, ["local"]);
    } finally { await client.close(); }
});
