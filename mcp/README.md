# Typewriter MCP

MCP server for Typewriter. Lets AI tools like Cursor and Claude Desktop read and edit storylines over the same websocket the web panel uses or by editing page json files offline.

This folder is a proposal to ship MCP with Typewriter by default so people dont need a separate community tool.

## Modes

Socket mode talks to a running server. Changes go through staging like the web editor then you publish.

File mode edits `plugins/Typewriter/pages/*.json` directly. Run `/typewriter reload` after.

## Setup

```bash
cd mcp
npm install
npm run build
```

Needs Node 18+.

## Cursor config

```json
{
  "mcpServers": {
    "typewriter": {
      "command": "node",
      "args": ["PATH_TO_REPO/mcp/dist/index.js"],
      "env": {
        "TYPEWRITER_MODE": "socket",
        "TYPEWRITER_URL_FILE": "PATH_TO_REPO/mcp/.typewriter-session-url"
      }
    }
  }
}
```

Start Typewriter with websocket enabled. Run `/typewriter connect` in game. Paste the link to the agent. It calls `connect_live` and keeps the socket open.

Or put the url in `TYPEWRITER_URL` directly. Session tokens die when the player logs out.

File mode:

```json
"env": {
  "TYPEWRITER_MODE": "file",
  "TYPEWRITER_PAGES_DIR": "C:/server/plugins/Typewriter/pages"
}
```

## Plugin config

```yaml
enabled: true
websocket:
  port: 9092
  auth: session
```

## Example prompts

```
Here is my Typewriter connect URL: ...
Connect and list all pages.
```

```
Create a static page village_npcs with a simple_speaker named Mira.
Create a sequence page village_intro with a spoken_dialogue greeting.
Wire them with connect_entries then validate_storyline and publish.
```

```
Search for "old quest name" and update matching dialogue text. Dont break triggers.
```

## Tools

| Tool | What it does |
|------|--------------|
| `connection_status` | mode and connection state |
| `connect_live` | connect with a `/typewriter connect` url |
| `list_pages` | list pages |
| `read_page` | read a page |
| `create_page` | create page |
| `rename_page` | rename page |
| `delete_page` | delete page |
| `add_entry` | add entry |
| `update_entry` | update one field by path |
| `replace_entry` | replace whole entry |
| `delete_entry` | delete entry |
| `connect_entries` | link triggers |
| `search_entries` | search text |
| `validate_storyline` | find broken refs |
| `publish` | publish staging (socket only) |

## Env

| Var | Default | Meaning |
|-----|---------|---------|
| `TYPEWRITER_MODE` | `socket` | `socket` or `file` |
| `TYPEWRITER_URL` | | optional fixed connect url |
| `TYPEWRITER_URL_FILE` | `.typewriter-session-url` | saved connect url |
| `TYPEWRITER_PAGES_DIR` | `plugins/Typewriter/pages` | file mode pages dir |

Standalone community version lives at https://github.com/yurchik228336/TypeWriter-MCP if you want it outside this repo.
