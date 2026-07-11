import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	MAX_IMAGE_BYTES,
	allocateTranscriptWindows,
	discordRequest,
	downloadImages,
	fetchDiscordContext,
	fetchMessagesPagewise,
	getDiscordConfig,
	isThreadChannel,
	mergeTranscriptWindows,
	parseDiscordMessageUrl,
} from "./discord-client.ts";

const signal = new AbortController().signal;
const messages = (start: number, end: number) => Array.from({ length: end - start + 1 }, (_, index) => ({ id: String(start + index) }));

function rawMessage(id: string, attachments: any[] = []) {
	return { id, timestamp: "2026-01-01T00:00:00.000Z", content: `message ${id}`, author: { id: "10", username: "user" }, attachments };
}

test("strict URL parsing accepts message and thread links but rejects malformed links", () => {
	for (const host of ["discord.com", "www.discord.com", "ptb.discord.com", "canary.discord.com", "discordapp.com"]) {
		assert.equal(parseDiscordMessageUrl(`https://${host}/channels/1234567890/2345678901/3456789012/?x=1#x`).messageId, "3456789012");
	}
	const thread = parseDiscordMessageUrl("https://discord.com/channels/1054708062520360960/1522596717437128714");
	assert.equal(thread.channelId, "1522596717437128714");
	assert.equal(thread.messageId, undefined);
	for (const url of [
		"https://evil.com/channels/1234567890/2345678901/3456789012",
		"https://discord.com/channels/1234567890",
		"https://discord.com/channels/1/2/3/extra",
		"x https://discord.com/channels/1234567890/2345678901/3456789012",
	]) assert.throws(() => parseDiscordMessageUrl(url));
});

test("config uses process env before quoted dotenv", async () => {
	const cwd = await mkdtemp(join(tmpdir(), "discord-config-"));
	await writeFile(join(cwd, ".env"), "DISCORD_TOKEN='file-token'\n");
	const previous = process.env.DISCORD_TOKEN;
	try {
		delete process.env.DISCORD_TOKEN;
		assert.equal((await getDiscordConfig(cwd)).token, "file-token");
		process.env.DISCORD_TOKEN = "process-token";
		assert.equal((await getDiscordConfig(cwd)).token, "process-token");
	} finally {
		if (previous === undefined) delete process.env.DISCORD_TOKEN;
		else process.env.DISCORD_TOKEN = previous;
	}
});

test("thread types and window allocations include tiny and odd caps", () => {
	assert.deepEqual([10, 11, 12].map(isThreadChannel), [true, true, true]);
	assert.equal(isThreadChannel(0), false);
	assert.deepEqual(allocateTranscriptWindows(1, true), { oldest: 0, newest: 0, reserveLinked: 1 });
	assert.deepEqual(allocateTranscriptWindows(6, true), { oldest: 3, newest: 2, reserveLinked: 1 });
});

test("selection retains linked oldest, newest, middle, dedupes overlap, and caps", () => {
	for (const linked of [{ id: "1" }, { id: "10" }, { id: "5" }]) {
		const result = mergeTranscriptWindows({ oldest: messages(1, 5), newest: messages(5, 10), linked, maxMessages: 7, totalCount: 10 });
		assert(result.messages.length <= 7);
		assert(result.messages.some((message) => message.id === linked.id));
		assert.equal(new Set(result.messages.map((message) => message.id)).size, result.messages.length);
	}
	const middle = mergeTranscriptWindows({ oldest: messages(1, 3), newest: messages(8, 10), linked: { id: "5" }, maxMessages: 5, totalCount: 10 });
	assert.equal(middle.messages.length, 5);
	assert.equal(middle.omissions.length, 2);
	assert.deepEqual(mergeTranscriptWindows({ oldest: messages(1, 3), newest: messages(1, 3), linked: { id: "2" }, maxMessages: 5, totalCount: 3 }).messages.map((m) => m.id), ["1", "2", "3"]);
});

test("pagination uses remaining limit, correct cursors, and chronological output", async () => {
	const urls: string[] = [];
	const pages = [messages(1, 100).reverse(), messages(101, 125).reverse()];
	const fetcher: any = async (url: string) => {
		urls.push(url);
		return Response.json(pages.shift() ?? []);
	};
	const result = await fetchMessagesPagewise({ token: "secret", apiBaseUrl: "https://api", fetch: fetcher }, "20", signal, 125, "oldest");
	assert.equal(result.length, 125);
	assert.deepEqual(result.slice(0, 2).map((m) => m.id), ["1", "2"]);
	assert.match(urls[0], /limit=100&after=0/);
	assert.match(urls[1], /limit=25&after=100/);
});

test("newest pagination omits initial before and terminates repeated page", async () => {
	const urls: string[] = [];
	const page = messages(101, 200).reverse();
	const fetcher: any = async (url: string) => { urls.push(url); return Response.json(page); };
	const result = await fetchMessagesPagewise({ token: "x", apiBaseUrl: "https://api", fetch: fetcher }, "20", signal, 150, "newest");
	assert.equal(result.length, 100);
	assert(!urls[0].includes("before="));
	assert.match(urls[1], /limit=50&before=101/);
});

test("API statuses, generic errors, malformed JSON, and token secrecy", async () => {
	for (const [status, text] of [[401, "invalid bot token"], [403, "lacks access"], [404, "unknown or inaccessible"]] as const) {
		const fetcher: any = async () => Response.json({ message: "safe" }, { status });
		await assert.rejects(discordRequest({ token: "TOPSECRET", apiBaseUrl: "x", fetch: fetcher }, "/x", signal), new RegExp(text));
	}
	const generic: any = async () => Response.json({ message: "broken" }, { status: 500 });
	await assert.rejects(discordRequest({ token: "TOPSECRET", apiBaseUrl: "x", fetch: generic }, "/x", signal), (error: Error) => !error.message.includes("TOPSECRET"));
	const malformed: any = async () => new Response("not-json");
	await assert.rejects(discordRequest({ token: "x", apiBaseUrl: "x", fetch: malformed }, "/x", signal), /malformed JSON/);
});

test("429 retries are bounded and retry delay is cancellable", async () => {
	let calls = 0;
	const fetcher: any = async () => { calls++; return Response.json({ retry_after: 0 }, { status: 429 }); };
	await assert.rejects(discordRequest({ token: "x", apiBaseUrl: "x", fetch: fetcher, maxRetries: 2 }, "/x", signal), /429/);
	assert.equal(calls, 3);
	const controller = new AbortController();
	const delayed: any = async () => Response.json({ retry_after: 10 }, { status: 429 });
	const pending = discordRequest({ token: "x", apiBaseUrl: "x", fetch: delayed }, "/x", controller.signal);
	controller.abort();
	await assert.rejects(pending);
});

test("images ignore non-images, dedupe, count successes, and mark excess", async () => {
	const attachments = [
		{ id: "file", url: "https://cdn.discordapp.com/a.pdf", contentType: "application/pdf", size: 1 },
		{ id: "bad", url: "https://cdn.discordapp.com/a.bmp", contentType: "image/bmp", size: 1 },
		{ id: "one", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 2 },
		{ id: "one", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 2 },
		{ id: "two", url: "https://cdn.discordapp.com/b.png", contentType: "image/png", size: 2 },
	];
	const result: any = { messages: [{ attachments }], images: [], skippedImages: [] };
	const fetcher: any = async () => new Response(new Uint8Array([1, 2]), { headers: { "content-type": "image/png", "content-length": "2" } });
	await downloadImages(result, 1, { token: "x", apiBaseUrl: "x", fetch: fetcher }, signal);
	assert.equal(result.images.length, 1);
	assert.equal(result.images[0].base64, "AQI=");
	assert(!result.skippedImages.some((item: any) => item.attachmentId === "file"));
	assert(result.skippedImages.some((item: any) => item.attachmentId === "bad"));
	assert(result.skippedImages.some((item: any) => item.attachmentId === "two" && item.reason.includes("limit")));
});

test("image downloads honor cancellation", async () => {
	const controller = new AbortController();
	const result: any = {
		messages: [{ attachments: [{ id: "one", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 2 }] }],
		images: [],
		skippedImages: [],
	};
	const fetcher: any = async (_url: URL, init: RequestInit) => new Promise((_resolve, reject) => {
		init.signal?.addEventListener("abort", () => reject(init.signal?.reason), { once: true });
	});
	const pending = downloadImages(result, 1, { token: "x", apiBaseUrl: "x", fetch: fetcher }, controller.signal);
	controller.abort(new DOMException("Aborted", "AbortError"));
	await assert.rejects(pending, /Aborted/);
	assert.equal(result.skippedImages.length, 0);
});

test("images reject zero cap, unsafe host, metadata/body oversize, mismatch, and failure", async () => {
	const cases = [
		[{ id: "zero", url: "https://cdn.discordapp.com/0.png", contentType: "image/png", size: 1 }, 0, async () => { throw new Error("unused"); }],
		[{ id: "host", url: "https://evil.test/a.png", contentType: "image/png", size: 1 }, 1, async () => Response.json({})],
		[{ id: "meta", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: MAX_IMAGE_BYTES + 1 }, 1, async () => Response.json({})],
		[{ id: "length", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 1 }, 1, async () => new Response("x", { headers: { "content-type": "image/png", "content-length": String(MAX_IMAGE_BYTES + 1) } })],
		[{ id: "body", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 1 }, 1, async () => new Response(new Uint8Array(MAX_IMAGE_BYTES + 1), { headers: { "content-type": "image/png" } })],
		[{ id: "mime", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 1 }, 1, async () => new Response("x", { headers: { "content-type": "image/jpeg" } })],
		[{ id: "fail", url: "https://cdn.discordapp.com/a.png", contentType: "image/png", size: 1 }, 1, async () => new Response("x", { status: 500 })],
	] as const;
	for (const [attachment, cap, fetcher] of cases) {
		const result: any = { messages: [{ attachments: [attachment] }], images: [], skippedImages: [] };
		await downloadImages(result, cap, { token: "x", apiBaseUrl: "x", fetch: fetcher as any }, signal);
		assert.equal(result.images.length, 0);
		assert.equal(result.skippedImages.length, 1);
	}
});

test("ordinary channel returns linked only while every thread type paginates", async () => {
	for (const type of [0, 10, 11, 12]) {
		let listCalls = 0;
		const fetcher: any = async (url: string) => {
			if (url.includes("/messages/")) return Response.json(rawMessage("50"));
			if (url.endsWith("/channels/20")) return Response.json({ id: "20", type, name: "channel", total_message_sent: 3 });
			listCalls++;
			return Response.json([rawMessage("1"), rawMessage("50"), rawMessage("99")]);
		};
		const result = await fetchDiscordContext(
			{ token: "x", apiBaseUrl: "https://api", fetch: fetcher },
			{ url: "https://discord.com/channels/10/20/50", maxMessages: 5, maxImages: 0 },
			signal,
		);
		assert(result.messages.some((message) => message.linked));
		assert.equal(result.messages.length, type === 0 ? 1 : 3);
		assert.equal(listCalls, type === 0 ? 0 : 1);
	}
});

test("thread-only links use the first message as the linked message", async () => {
	let listCalls = 0;
	const fetcher: any = async (url: string) => {
		if (url.endsWith("/channels/1522596717437128714")) {
			return Response.json({ id: "1522596717437128714", type: 11, name: "support", total_message_sent: 2 });
		}
		listCalls++;
		return Response.json([rawMessage("1522596717437128715"), rawMessage("1522596717437128716")]);
	};
	const result = await fetchDiscordContext(
		{ token: "x", apiBaseUrl: "https://api", fetch: fetcher },
		{ url: "https://discord.com/channels/1054708062520360960/1522596717437128714", maxImages: 0 },
		signal,
	);
	assert.equal(result.linkedMessageId, "1522596717437128715");
	assert(result.messages[0].linked);
	assert.equal(result.messages.length, 2);
	assert.equal(listCalls, 2);
});

test("channel-only links reject non-thread channels", async () => {
	const fetcher: any = async () => Response.json({ id: "20", type: 0, name: "general" });
	await assert.rejects(
		fetchDiscordContext(
			{ token: "x", apiBaseUrl: "https://api", fetch: fetcher },
			{ url: "https://discord.com/channels/1234567890/2345678901", maxImages: 0 },
			signal,
		),
		/only for threads/,
	);
});

test("maxMessages one keeps the linked message and stays capped", async () => {
	const fetcher: any = async (url: string) => {
		if (url.includes("/messages/")) return Response.json(rawMessage("50"));
		return Response.json({ id: "20", type: 11, name: "thread", total_message_sent: 10 });
	};
	const result = await fetchDiscordContext(
		{ token: "x", apiBaseUrl: "https://api", fetch: fetcher },
		{ url: "https://discord.com/channels/10/20/50", maxMessages: 1, maxImages: 0 },
		signal,
	);
	assert.equal(result.messages.length, 1);
	assert(result.messages[0].linked);
	assert(result.truncated);
});

test("intent warning only applies to multiple empty normal messages", async () => {
	const fetcher: any = async (url: string) => {
		if (url.includes("/messages/")) return Response.json({ ...rawMessage("50"), content: "" });
		if (url.endsWith("/channels/20")) return Response.json({ id: "20", type: 11, total_message_sent: 2 });
		return Response.json([{ ...rawMessage("40"), content: "" }, { ...rawMessage("50"), content: "" }]);
	};
	const result = await fetchDiscordContext({ token: "x", apiBaseUrl: "https://api", fetch: fetcher }, { url: "https://discord.com/channels/10/20/50", maxImages: 0 }, signal);
	assert.equal(result.warnings.length, 1);
});
