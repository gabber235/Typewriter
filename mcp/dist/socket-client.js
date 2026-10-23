/**
 * Live client for the Typewriter plugin websocket (the same protocol the
 * official web editor "app" uses).
 *
 * Server side (plugin): netty-socketio v1.7.x => Socket.IO v2 protocol.
 * Events (all payloads are JSON strings, responses come via ack):
 *   fetch("pages" | "extensions")            -> ack: JSON string
 *   createPage(pageJson)                     -> ack: {success, message}
 *   renamePage({pageId, new})                -> ack
 *   changePageValue({pageId, path, value})   -> ack
 *   deletePage(pageId)                       -> ack
 *   createEntry({pageId, entry})             -> ack
 *   updateEntry({pageId, entryId, path, value}) -> ack
 *   updateCompleteEntry({pageId, entry})     -> ack
 *   reorderEntry({pageId, entryId, newIndex})-> ack
 *   moveEntry({entryId, fromPageId, toPageId}) -> ack
 *   deleteEntry({pageId, entryId})           -> ack
 *   publish("")                              -> ack
 *
 * Connect URL: ws://host:9092/?token=<uuid>  (token from `/typewriter connect` link)
 */
import ioFactory from "socket.io-client";
import crypto from "node:crypto";
/** Typewriter ids: 15 random chars [A-Za-z0-9] (see app getRandomString()). */
export function twRandomId(length = 15) {
    const chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890";
    let out = "";
    const bytes = crypto.randomBytes(length);
    for (let i = 0; i < length; i++)
        out += chars[bytes[i] % chars.length];
    return out;
}
export class TypewriterSocketClient {
    socket = null;
    opts;
    constructor(opts) {
        this.opts = {
            connectTimeoutMs: 10_000,
            secure: false,
            ...opts,
        };
    }
    get connected() {
        return this.socket?.connected ?? false;
    }
    async connect() {
        if (this.connected)
            return;
        const scheme = this.opts.secure ? "wss" : "ws";
        let url = `${scheme}://${this.opts.host}:${this.opts.port}`;
        if (this.opts.token)
            url += `?token=${this.opts.token}`;
        this.socket?.close();
        const socket = ioFactory(url, {
            transports: ["websocket"],
            reconnection: true,
            reconnectionAttempts: 3,
            timeout: this.opts.connectTimeoutMs,
        });
        this.socket = socket;
        await new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                socket.close();
                reject(new Error(`Timed out connecting to Typewriter at ${url}. Is 'enabled: true' in plugins/Typewriter/config.yml and the token fresh (run /typewriter connect)?`));
            }, this.opts.connectTimeoutMs);
            socket.once("connect", () => {
                clearTimeout(timer);
                resolve();
            });
            socket.once("connect_error", (err) => {
                clearTimeout(timer);
                socket.close();
                reject(new Error(`Connect error: ${err.message}. Check host/port/token (token expires when the player logs out).`));
            });
        });
    }
    close() {
        this.socket?.close();
        this.socket = null;
    }
    async emitAck(event, data) {
        if (!this.socket?.connected) {
            await this.connect();
        }
        const socket = this.socket;
        return await new Promise((resolve, reject) => {
            const timer = setTimeout(() => reject(new Error(`Ack timeout for "${event}"`)), 15_000);
            socket.emit(event, data, (resp) => {
                clearTimeout(timer);
                resolve(typeof resp === "string" ? resp : JSON.stringify(resp));
            });
        });
    }
    parseAck(raw) {
        try {
            const json = JSON.parse(raw);
            if (typeof json.success === "boolean")
                return json;
            return { success: true, message: raw };
        }
        catch {
            return { success: true, message: raw };
        }
    }
    async emitChecked(event, data) {
        const resp = this.parseAck(await this.emitAck(event, data));
        if (!resp.success) {
            throw new Error(`Typewriter rejected "${event}": ${resp.message}`);
        }
        return resp;
    }
    // ---------- protocol ops ----------
    async fetchPages() {
        const raw = await this.emitAck("fetch", "pages");
        return JSON.parse(raw);
    }
    async fetchExtensions() {
        const raw = await this.emitAck("fetch", "extensions");
        return JSON.parse(raw);
    }
    async createPage(page) {
        const full = {
            id: twRandomId(),
            name: page.name,
            type: page.type,
            chapter: page.chapter ?? "",
            priority: page.priority ?? 0,
            entries: [],
        };
        await this.emitChecked("createPage", JSON.stringify(full));
        return full;
    }
    async renamePage(pageId, newName) {
        await this.emitChecked("renamePage", JSON.stringify({ pageId, new: newName }));
    }
    async changePageValue(pageId, path, value) {
        await this.emitChecked("changePageValue", JSON.stringify({ pageId, path, value }));
    }
    async deletePage(pageId) {
        await this.emitChecked("deletePage", pageId);
    }
    async createEntry(pageId, entry) {
        const full = { id: entry.id ?? twRandomId(), ...entry };
        await this.emitChecked("createEntry", JSON.stringify({ pageId, entry: full }));
        return full;
    }
    async updateEntryField(pageId, entryId, path, value) {
        await this.emitChecked("updateEntry", JSON.stringify({ pageId, entryId, path, value }));
    }
    async updateCompleteEntry(pageId, entry) {
        await this.emitChecked("updateCompleteEntry", JSON.stringify({ pageId, entry }));
    }
    async reorderEntry(pageId, entryId, newIndex) {
        await this.emitChecked("reorderEntry", JSON.stringify({ pageId, entryId, newIndex }));
    }
    async moveEntry(entryId, fromPageId, toPageId) {
        await this.emitChecked("moveEntry", JSON.stringify({ entryId, fromPageId, toPageId }));
    }
    async deleteEntry(pageId, entryId) {
        await this.emitChecked("deleteEntry", JSON.stringify({ pageId, entryId }));
    }
    /** Publish staging changes to production. */
    async publish() {
        return await this.emitChecked("publish", "");
    }
}
/**
 * Parse a Typewriter connect URL like:
 *   http://host:8080/#/connect?host=1.2.3.4&port=9092&token=<uuid>&secure=true
 * or a plain ws url, into connection options.
 */
export function parseConnectUrl(url) {
    // Hash-fragment style (web panel link from /typewriter connect)
    const hashIdx = url.indexOf("#/connect");
    if (hashIdx !== -1) {
        const query = url.slice(url.indexOf("?", hashIdx) + 1);
        const params = new URLSearchParams(query);
        const host = params.get("host");
        if (!host)
            throw new Error("Connect URL is missing 'host' parameter");
        return {
            host,
            port: parseInt(params.get("port") ?? "9092", 10),
            token: params.get("token") ?? undefined,
            secure: params.get("secure") === "true",
        };
    }
    // ws://host:port?token=...
    const u = new URL(url);
    return {
        host: u.hostname,
        port: u.port ? parseInt(u.port, 10) : u.protocol === "wss:" ? 443 : 9092,
        token: u.searchParams.get("token") ?? undefined,
        secure: u.protocol === "wss:",
    };
}
