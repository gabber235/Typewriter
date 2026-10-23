#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { promises as fs } from "node:fs";
import path from "node:path";
import { TypewriterStore } from "./typewriter.js";
import { TypewriterSocketClient, parseConnectUrl } from "./socket-client.js";
const MODE = (process.env.TYPEWRITER_MODE ?? "socket").toLowerCase();
const CONNECT_URL = process.env.TYPEWRITER_URL;
const CONNECT_URL_FILE = process.env.TYPEWRITER_URL_FILE ?? path.join(process.cwd(), ".typewriter-session-url");
const PAGES_DIR = process.env.TYPEWRITER_PAGES_DIR ?? path.join(process.cwd(), "plugins", "Typewriter", "pages");
const SOCKET_MODE = MODE === "socket";
const FILE_MODE = MODE === "file";
let socket = null;
if (!SOCKET_MODE && !FILE_MODE) {
    console.error(`Unsupported TYPEWRITER_MODE "${MODE}". Use "socket" or "file".`);
    process.exit(1);
}
const store = FILE_MODE ? new TypewriterStore(PAGES_DIR) : null;
const server = new McpServer({ name: "typewriter-mcp", version: "2.0.0" });
function ok(data) {
    return { content: [{ type: "text", text: typeof data === "string" ? data : JSON.stringify(data, null, 2) }] };
}
function fail(err) {
    const msg = err instanceof Error ? err.message : String(err);
    return { isError: true, content: [{ type: "text", text: "Error: " + msg }] };
}
async function readStoredConnectUrl() {
    const raw = (await fs.readFile(CONNECT_URL_FILE, "utf8").catch(() => "")).trim();
    return raw || undefined;
}
async function persistConnectUrl(url) {
    await fs.mkdir(path.dirname(CONNECT_URL_FILE), { recursive: true });
    await fs.writeFile(CONNECT_URL_FILE, `${url.trim()}\n`, "utf8");
}
async function ensureSocketConnected() {
    if (!SOCKET_MODE) {
        throw new Error("Live Typewriter socket is only available when TYPEWRITER_MODE=socket.");
    }
    if (!socket) {
        const savedUrl = CONNECT_URL ?? await readStoredConnectUrl();
        if (!savedUrl) {
            throw new Error("No live Typewriter session configured. Send the full /typewriter connect URL and call connect_live first.");
        }
        socket = new TypewriterSocketClient(parseConnectUrl(savedUrl));
    }
    await socket.connect();
    return socket;
}
async function connectLive(url, forceReconnect = false) {
    if (!SOCKET_MODE) {
        throw new Error("connect_live is only available when TYPEWRITER_MODE=socket.");
    }
    if (socket?.connected && !forceReconnect) {
        const pageCount = (await socket.fetchPages()).length;
        return { connected: true, pageCount, reusedExisting: true };
    }
    const nextSocket = new TypewriterSocketClient(parseConnectUrl(url));
    await nextSocket.connect();
    const pageCount = (await nextSocket.fetchPages()).length;
    if (forceReconnect) {
        socket?.close();
    }
    socket = nextSocket;
    await persistConnectUrl(url);
    return { connected: true, pageCount, reusedExisting: false };
}
async function pages() {
    if (SOCKET_MODE)
        return await (await ensureSocketConnected()).fetchPages();
    const infos = await store.listPages();
    const out = [];
    for (const i of infos)
        out.push((await store.readPage(i.name)));
    return out;
}
async function findPage(nameOrId) {
    const all = await pages();
    return all.find((p) => p.id === nameOrId || p.name === nameOrId);
}
server.tool("connection_status", "Show current Typewriter connection status and whether a saved connect URL exists.", {}, async () => {
    try {
        return ok({
            mode: MODE,
            connected: socket?.connected ?? false,
            hasConfiguredEnvUrl: Boolean(CONNECT_URL),
            hasSavedUrl: Boolean(await readStoredConnectUrl()),
            urlFile: CONNECT_URL_FILE,
            pagesDir: FILE_MODE ? PAGES_DIR : undefined,
        });
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("connect_live", "Connect to a live Typewriter websocket using the full URL from /typewriter connect.", {
    url: z.string(),
    forceReconnect: z.boolean().optional(),
}, async ({ url, forceReconnect }) => {
    try {
        const result = await connectLive(url, forceReconnect ?? false);
        return ok({
            ...result,
            message: result.reusedExisting
                ? "Already connected; kept the current live socket open."
                : "Connected to the live Typewriter socket and saved the URL for future reconnects.",
        });
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("list_pages", "List all pages (name, id, type, entry count).", {}, async () => {
    try {
        const all = await pages();
        return ok(all.map((p) => ({ id: p.id, name: p.name, type: p.type, entryCount: (p.entries ?? []).length })));
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("read_page", "Read a full page (all entries) by page name or id.", { page: z.string() }, async ({ page }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        return ok(p);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("create_page", "Create a new page. Types: sequence, static, cinematic, manifest.", { name: z.string(), type: z.enum(["sequence", "static", "cinematic", "manifest"]), chapter: z.string().optional(), priority: z.number().optional() }, async ({ name, type, chapter, priority }) => {
    try {
        if (SOCKET_MODE)
            return ok(await (await ensureSocketConnected()).createPage({ name, type, chapter, priority }));
        return ok(await store.createPage(name, type));
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("rename_page", "Rename a page.", { page: z.string(), newName: z.string() }, async ({ page, newName }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (SOCKET_MODE)
            await (await ensureSocketConnected()).renamePage(p.id, newName);
        else
            await store.renamePage(p.name, newName);
        return ok("Renamed to " + newName);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("delete_page", "Delete a page and all its entries.", { page: z.string() }, async ({ page }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (SOCKET_MODE)
            await (await ensureSocketConnected()).deletePage(p.id);
        else
            await store.deletePage(p.name);
        return ok("Deleted " + page);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("add_entry", "Add an entry to a page. fields = raw Typewriter entry JSON (needs 'name' and 'type'; id is generated). Common types: spoken_dialogue, option_dialogue, simple_speaker, permanent_fact.", { page: z.string(), fields: z.record(z.unknown()) }, async ({ page, fields }) => {
    try {
        if (typeof fields.name !== "string" || typeof fields.type !== "string")
            throw new Error("fields must contain string 'name' and 'type'");
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (SOCKET_MODE)
            return ok(await (await ensureSocketConnected()).createEntry(p.id, fields));
        return ok(await store.addEntry(p.name, fields));
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("update_entry", "Update a single field of an entry by dotted path (e.g. 'text', 'speaker', 'criteria.0.value').", { page: z.string(), entryId: z.string(), path: z.string(), value: z.unknown() }, async ({ page, entryId, path: fieldPath, value }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (SOCKET_MODE) {
            await (await ensureSocketConnected()).updateEntryField(p.id, entryId, fieldPath, value);
            return ok("Updated " + fieldPath);
        }
        const patch = {};
        patch[fieldPath] = value;
        return ok(await store.updateEntry(p.name, entryId, patch));
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("replace_entry", "Replace a whole entry with a new object (must keep the same id).", { page: z.string(), entry: z.record(z.unknown()) }, async ({ page, entry }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (typeof entry.id !== "string")
            throw new Error("entry must include its 'id'");
        if (SOCKET_MODE) {
            await (await ensureSocketConnected()).updateCompleteEntry(p.id, entry);
            return ok("Replaced " + entry.id);
        }
        return ok(await store.updateEntry(p.name, entry.id, entry));
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("delete_entry", "Delete an entry by id.", { page: z.string(), entryId: z.string() }, async ({ page, entryId }) => {
    try {
        const p = await findPage(page);
        if (!p)
            throw new Error("Page not found: " + page);
        if (SOCKET_MODE)
            await (await ensureSocketConnected()).deleteEntry(p.id, entryId);
        else
            await store.deleteEntry(p.name, entryId);
        return ok("Deleted entry " + entryId);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("connect_entries", "Wire story flow: append 'toEntryId' to the 'triggers' list of 'fromEntryId'.", { fromPage: z.string(), fromEntryId: z.string(), toEntryId: z.string() }, async ({ fromPage, fromEntryId, toEntryId }) => {
    try {
        const p = await findPage(fromPage);
        if (!p)
            throw new Error("Page not found: " + fromPage);
        const from = (p.entries ?? []).find((e) => e.id === fromEntryId);
        if (!from)
            throw new Error("Entry not found: " + fromEntryId);
        const triggers = Array.isArray(from.triggers) ? from.triggers.slice() : [];
        if (!triggers.includes(toEntryId))
            triggers.push(toEntryId);
        if (SOCKET_MODE)
            await (await ensureSocketConnected()).updateEntryField(p.id, fromEntryId, "triggers", triggers);
        else
            await store.updateEntry(p.name, fromEntryId, { triggers });
        return ok("Connected " + fromEntryId + " -> " + toEntryId);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("search_entries", "Full-text search across all pages/entries.", { query: z.string() }, async ({ query }) => {
    try {
        const q = query.toLowerCase();
        const hits = [];
        for (const p of await pages())
            for (const e of p.entries ?? [])
                if (JSON.stringify(e).toLowerCase().includes(q))
                    hits.push({ page: p.name, entry: e });
        return ok(hits);
    }
    catch (e) {
        return fail(e);
    }
});
server.tool("validate_storyline", "Find broken references (triggers/triggeredBy pointing to missing ids).", {}, async () => {
    try {
        const all = await pages();
        const ids = new Set();
        for (const p of all)
            for (const e of p.entries ?? [])
                ids.add(e.id);
        const problems = [];
        for (const p of all)
            for (const e of p.entries ?? []) {
                for (const f of ["triggers", "triggeredBy"]) {
                    const v = e[f];
                    if (Array.isArray(v))
                        for (const r of v)
                            if (typeof r === "string" && r && !ids.has(r))
                                problems.push(`"${e.name ?? e.id}" (page ${p.name}) -> missing "${r}" in ${f}`);
                }
            }
        return ok(problems.length ? problems : "OK: no problems found");
    }
    catch (e) {
        return fail(e);
    }
});
if (SOCKET_MODE) {
    server.tool("publish", "Publish staging changes to production (applies edits live in-game).", {}, async () => {
        try {
            const r = await (await ensureSocketConnected()).publish();
            return ok(r.message || "Published");
        }
        catch (e) {
            return fail(e);
        }
    });
}
async function main() {
    if (SOCKET_MODE) {
        const savedUrl = CONNECT_URL ?? await readStoredConnectUrl();
        if (savedUrl) {
            try {
                socket = new TypewriterSocketClient(parseConnectUrl(savedUrl));
                await socket.connect();
                console.error("typewriter-mcp: connected to live Typewriter socket.");
            }
            catch (err) {
                socket = null;
                console.error("typewriter-mcp: socket mode, saved URL failed; waiting for connect_live. " + (err instanceof Error ? err.message : String(err)));
            }
        }
        else {
            console.error("typewriter-mcp: socket mode, waiting for connect_live URL.");
        }
    }
    else {
        await store.ensureDir();
        console.error("typewriter-mcp: file mode, dir " + PAGES_DIR);
    }
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => { console.error("Fatal:", err); process.exit(1); });
