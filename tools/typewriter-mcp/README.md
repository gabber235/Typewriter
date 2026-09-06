# typewriter MCP

Local Greptime queries over HTTP, exposed to Codex through stdio. Owned by this repository; no sibling checkout or global installation required.

From this checkout, with Node 22 or newer:

```sh
npm ci --prefix tools/typewriter-mcp
npm run build --prefix tools/typewriter-mcp
npm test --prefix tools/typewriter-mcp
```

Open a new Codex session in this trusted repository after building. `.codex/config.toml` resolves the Git root at launch, including when started from a nested directory. The server writes protocol messages only to stdout. The project skill is in `.agents/skills/typewriter-investigation/`.

Default endpoint: `https://observability.local.seamlezz.net`, database `public`. Optional process environment: `GREPTIME_URL`, `GREPTIME_DATABASE`, and paired `GREPTIME_USERNAME` / `GREPTIME_PASSWORD`. The tracked Codex configuration uses the default anonymous local endpoint and does not forward credentials. Optional process environment settings require separate local configuration. Keep secrets outside tracked configuration. Overrides describe the local installation; this package has no production profile.

Queries use a 30 second timeout, a 2 MB HTTP response cap, at most 500 returned rows, and a 30000 byte cap across the entire MCP response. Output includes explicit truncation. SQL LIMIT and narrow time bounds remain necessary to control server work. Unsafe integer values, including epoch nanoseconds, stay exact as decimal strings.

The SQL parser accepts a deliberately limited read subset. Unsupported dialect syntax is rejected. This guard does not replace database permissions. The two repository adapters evolve independently; neither imports the other. Rebuild after source changes. `npm ci` restores the exact lockfile.
