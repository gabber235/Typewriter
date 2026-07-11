import test from "node:test";
import assert from "node:assert/strict";
import { formatDiscordTranscript, toPublicDetails } from "./format.ts";

function message(id: string, linked = false): any {
	return {
		id,
		timestamp: "2026-01-01",
		editedTimestamp: "2026-01-02",
		content: "hello",
		author: { id: "1", username: "user", displayName: "User", bot: true },
		attachments: [{ id: "a", filename: "file.pdf", contentType: "application/pdf", size: 2, url: "https://cdn.discordapp.com/file.pdf" }],
		embeds: [{ title: "Embed title", description: "Description", fields: [{ name: "Field", value: "Value" }] }],
		stickers: [{ id: "s", name: "Sticker" }],
		reactions: [{ emoji: { name: "ok" }, count: 2 }],
		reference: { message_id: "9", excerpt: "reply" },
		pinned: true,
		type: 0,
		url: `https://discord.com/${id}`,
		linked,
	};
}

function result(overrides: any = {}): any {
	return {
		sourceUrl: "https://discord.com/source",
		channel: { name: "thread", type: 11 },
		messages: [message("100", true), message("900")],
		linkedMessageId: "100",
		truncated: false,
		omittedCount: 0,
		omittedEstimated: false,
		omissions: [],
		images: [{ attachmentId: "a", url: "url", mimeType: "image/png", base64: "SECRETBASE64" }],
		skippedImages: [],
		warnings: [],
		link: {},
		...overrides,
	};
}

test("formatter includes rich message metadata and public details strip base64", () => {
	const text = formatDiscordTranscript(result());
	for (const expected of ["LINKED MESSAGE", "PINNED", "Edited:", "Reply to:", "Attachment:", "Embed:", "Field", "Sticker:", "Reaction:", "Message ID:", "URL:"]) {
		assert(text.includes(expected));
	}
	assert(!text.includes("Skipped image"));
	assert(!JSON.stringify(toPublicDetails(result())).includes("SECRETBASE64"));
});

test("formatter renders omission only at explicit boundary", () => {
	const formatted = formatDiscordTranscript(result({
		truncated: true,
		omittedCount: 7,
		omittedEstimated: true,
		omissions: [{ afterMessageId: "100", beforeMessageId: "900", count: 7, estimated: true }],
	}));
	assert.equal((formatted.match(/messages omitted from the middle/g) ?? []).length, 1);
	const noBoundary = formatDiscordTranscript(result({ truncated: true, omittedCount: 7, omissions: [] }));
	assert.equal((noBoundary.match(/--- .*omitted/g) ?? []).length, 0);
});

test("separately retained linked middle renders two truthful boundary markers", () => {
	const formatted = formatDiscordTranscript(result({
		messages: [message("100"), message("500", true), message("900")],
		linkedMessageId: "500",
		truncated: true,
		omittedCount: 50,
		omissions: [
			{ afterMessageId: "100", beforeMessageId: "500", count: 50, estimated: true },
			{ afterMessageId: "500", beforeMessageId: "900", count: 50, estimated: true },
		],
	}));
	assert.equal((formatted.match(/retained boundary/g) ?? []).length, 2);
});

test("non-image attachments remain attachments, not skipped images", () => {
	const text = formatDiscordTranscript(result());
	assert(text.includes("file.pdf"));
	assert(!text.includes("Skipped image"));
});

test("ordinary channel messages are not labeled as thread starts", () => {
	const text = formatDiscordTranscript(result({
		channel: { name: "general", type: 0 },
		messages: [message("100", true)],
	}));
	assert(text.startsWith("# Discord message: general"));
	assert(!text.includes("THREAD START"));
});
