import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

export const API_BASE = "https://discord.com/api/v10";
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const CLIENT_HOSTS = /^(?:(?:www|ptb|canary)\.)?(?:discord\.com|discordapp\.com)$/i;
const CDN_HOSTS = /^(?:cdn|media)\.discordapp\.(?:com|net)$/i;
const SNOWFLAKE = /^\d{2,20}$/;
const IMAGE_MIME_TYPES = new Set(["image/png", "image/jpeg", "image/gif", "image/webp"]);

export type FetchLike = typeof fetch;

export interface DiscordMessageLink {
	guildId: string;
	channelId: string;
	messageId?: string;
	url: string;
}

export interface DiscordConfig {
	token: string;
	apiBaseUrl: string;
	fetch?: FetchLike;
	maxRetries?: number;
}

export interface NormalizedAttachment {
	id: string;
	filename: string;
	description?: string;
	contentType?: string;
	size: number;
	url: string;
}

export interface NormalizedMessage {
	id: string;
	timestamp: string;
	editedTimestamp?: string;
	content: string;
	author: { id: string; username: string; displayName: string; bot?: boolean };
	attachments: NormalizedAttachment[];
	embeds: any[];
	stickers: any[];
	reactions: any[];
	reference?: any;
	pinned: boolean;
	type: number;
	url: string;
	linked: boolean;
}

export interface TranscriptOmission {
	afterMessageId?: string;
	beforeMessageId?: string;
	count: number;
	estimated: boolean;
}

export interface DiscordFetchResult {
	sourceUrl: string;
	link: DiscordMessageLink;
	channel: any;
	messages: NormalizedMessage[];
	linkedMessageId: string;
	truncated: boolean;
	omittedCount: number;
	omittedEstimated: boolean;
	omissions: TranscriptOmission[];
	images: { attachmentId: string; url: string; mimeType: string; base64: string }[];
	skippedImages: { attachmentId: string; url: string; reason: string }[];
	warnings: string[];
}

export function parseDiscordMessageUrl(value: string): DiscordMessageLink {
	if (value.trim() !== value || /\s/.test(value)) {
		throw new Error("Discord message URL must be a clean URL without surrounding text");
	}

	let parsed: URL;
	try {
		parsed = new URL(value);
	} catch {
		throw new Error("Invalid Discord message URL");
	}
	if (parsed.protocol !== "https:" || !CLIENT_HOSTS.test(parsed.hostname)) {
		throw new Error("Unsupported Discord message URL host");
	}

	const match = parsed.pathname.match(/^\/channels\/(@me|\d{2,20})\/(\d{2,20})(?:\/(\d{2,20}))?\/?$/);
	if (!match) {
		throw new Error("Discord URL must be /channels/{guild}/{thread} or /channels/{guild}/{channel}/{message} with decimal IDs");
	}

	const [, guildId, channelId, messageId] = match;
	if (
		(guildId !== "@me" && !SNOWFLAKE.test(guildId))
		|| !SNOWFLAKE.test(channelId)
		|| (messageId !== undefined && !SNOWFLAKE.test(messageId))
	) {
		throw new Error("Discord IDs must be decimal snowflakes");
	}
	return {
		guildId,
		channelId,
		messageId,
		url: `https://discord.com/channels/${guildId}/${channelId}${messageId ? `/${messageId}` : ""}`,
	};
}

export function isThreadChannel(type: number): boolean {
	return type === 10 || type === 11 || type === 12;
}

export function allocateTranscriptWindows(maxMessages: number, reserveLinked: boolean) {
	const available = Math.max(0, maxMessages - (reserveLinked ? 1 : 0));
	return {
		oldest: Math.ceil(available / 2),
		newest: Math.floor(available / 2),
		reserveLinked: reserveLinked ? 1 : 0,
	};
}

function compareIds(a: { id: string }, b: { id: string }): number {
	const left = BigInt(a.id);
	const right = BigInt(b.id);
	return left < right ? -1 : left > right ? 1 : 0;
}

function uniqueSorted<T extends { id: string }>(messages: T[]): T[] {
	return [...new Map(messages.map((message) => [String(message.id), message])).values()].sort(compareIds);
}

export function mergeTranscriptWindows(input: {
	oldest: any[];
	newest: any[];
	linked: any;
	maxMessages: number;
	totalCount?: number;
}) {
	const oldest = uniqueSorted(input.oldest);
	const newest = uniqueSorted(input.newest);
	const fullAllocation = allocateTranscriptWindows(input.maxMessages, false);
	const fullWindow = uniqueSorted([
		...oldest.slice(0, fullAllocation.oldest),
		...newest.slice(-fullAllocation.newest),
	]);
	const linkedInWindows = fullWindow.some((message) => String(message.id) === String(input.linked.id));
	const allocation = allocateTranscriptWindows(input.maxMessages, !linkedInWindows);
	const selected = uniqueSorted([
		...oldest.slice(0, allocation.oldest),
		...(!linkedInWindows ? [input.linked] : []),
		...newest.slice(-allocation.newest),
	]);

	if (selected.length < input.maxMessages) {
		const extras = uniqueSorted([...oldest, ...newest]).filter(
			(message) => !selected.some((chosen) => String(chosen.id) === String(message.id)),
		);
		selected.push(...extras.slice(0, input.maxMessages - selected.length));
		selected.sort(compareIds);
	}

	const messages = selected.slice(0, input.maxMessages);
	const totalCount = Math.max(input.totalCount ?? messages.length, messages.length);
	const omittedCount = Math.max(0, totalCount - messages.length);
	const omissions: TranscriptOmission[] = [];
	if (omittedCount > 0 && messages.length > 1) {
		const linkedIndex = messages.findIndex((message) => String(message.id) === String(input.linked.id));
		const hasOld = linkedIndex > 0;
		const hasNew = linkedIndex >= 0 && linkedIndex < messages.length - 1;
		if (!linkedInWindows && hasOld && hasNew) {
			omissions.push({
				afterMessageId: messages[linkedIndex - 1].id,
				beforeMessageId: messages[linkedIndex].id,
				count: omittedCount,
				estimated: true,
			});
			omissions.push({
				afterMessageId: messages[linkedIndex].id,
				beforeMessageId: messages[linkedIndex + 1].id,
				count: omittedCount,
				estimated: true,
			});
		} else {
			const boundary = Math.max(1, Math.min(messages.length - 1, allocation.oldest));
			omissions.push({
				afterMessageId: messages[boundary - 1].id,
				beforeMessageId: messages[boundary].id,
				count: omittedCount,
				estimated: true,
			});
		}
	}
	return { messages, truncated: omittedCount > 0, omittedCount, omissions };
}

export async function getDiscordConfig(cwd: string): Promise<DiscordConfig> {
	const processToken = process.env.DISCORD_TOKEN?.trim();
	if (processToken) {
		return { token: processToken, apiBaseUrl: API_BASE };
	}

	let text = "";
	try {
		text = await readFile(resolve(cwd, ".env"), "utf8");
	} catch {}
	for (const line of text.split(/\r?\n/)) {
		const match = line.match(/^\s*(?:export\s+)?DISCORD_TOKEN\s*=\s*(.*?)\s*$/);
		if (!match) continue;
		let value = match[1];
		if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
			value = value.slice(1, -1);
		}
		if (value) return { token: value, apiBaseUrl: API_BASE };
	}
	throw new Error("Missing required environment variable DISCORD_TOKEN");
}

function abortableDelay(ms: number, signal: AbortSignal): Promise<void> {
	return new Promise((resolveDelay, reject) => {
		if (signal.aborted) {
			reject(signal.reason ?? new DOMException("Aborted", "AbortError"));
			return;
		}
		const timer = setTimeout(resolveDelay, ms);
		signal.addEventListener("abort", () => {
			clearTimeout(timer);
			reject(signal.reason ?? new DOMException("Aborted", "AbortError"));
		}, { once: true });
	});
}

export async function discordRequest<T>(config: DiscordConfig, route: string, signal: AbortSignal): Promise<T> {
	const fetcher = config.fetch ?? fetch;
	const retries = config.maxRetries ?? 3;
	for (let attempt = 0; ; attempt++) {
		const response = await fetcher(config.apiBaseUrl + route, {
			headers: { Authorization: `Bot ${config.token}`, "User-Agent": "TypeWriter-Pi-Discord/1.0" },
			signal,
			redirect: "error",
		});
		if (response.status === 429 && attempt < retries) {
			let body: any = {};
			try { body = await response.json(); } catch {}
			const headerSeconds = Number(response.headers.get("retry-after"));
			const bodySeconds = Number(body.retry_after);
			const seconds = Number.isFinite(bodySeconds) ? bodySeconds : Number.isFinite(headerSeconds) ? headerSeconds : 1;
			await abortableDelay(Math.max(0, seconds * 1_000), signal);
			continue;
		}
		if (!response.ok) {
			const labels: Record<number, string> = {
				401: "invalid bot token",
				403: "bot lacks access, permissions, or private-thread membership",
				404: "unknown or inaccessible channel or message",
			};
			let suffix = "";
			try {
				const body: any = await response.json();
				suffix = body?.message ? `: ${String(body.message).slice(0, 200)}` : "";
			} catch {}
			throw new Error(`Discord API ${response.status}: ${labels[response.status] ?? "request failed"}${suffix}`);
		}
		try {
			return await response.json() as T;
		} catch {
			throw new Error("Discord API returned malformed JSON");
		}
	}
}

export async function fetchMessagesPagewise(
	config: DiscordConfig,
	channelId: string,
	signal: AbortSignal,
	maxMessages: number,
	direction: "oldest" | "newest",
): Promise<any[]> {
	const messages: any[] = [];
	const seen = new Set<string>();
	let cursor: string | undefined = direction === "oldest" ? "0" : undefined;
	while (messages.length < maxMessages) {
		const limit = Math.min(100, maxMessages - messages.length);
		const query = new URLSearchParams({ limit: String(limit) });
		if (direction === "oldest") query.set("after", cursor!);
		if (direction === "newest" && cursor) query.set("before", cursor);
		const batch = await discordRequest<any[]>(config, `/channels/${channelId}/messages?${query}`, signal);
		if (!Array.isArray(batch)) throw new Error("Discord API returned malformed message list");
		let added = 0;
		for (const message of batch) {
			const id = String(message.id);
			if (seen.has(id)) continue;
			seen.add(id);
			messages.push(message);
			added++;
		}
		if (batch.length < limit || added === 0) break;
		const sorted = uniqueSorted(batch);
		const nextCursor = String(direction === "oldest" ? sorted.at(-1)!.id : sorted[0].id);
		if (nextCursor === cursor) break;
		cursor = nextCursor;
	}
	const sorted = uniqueSorted(messages);
	return direction === "oldest" ? sorted.slice(0, maxMessages) : sorted.slice(-maxMessages);
}

function normalize(raw: any, link: DiscordMessageLink): NormalizedMessage {
	return {
		id: String(raw.id),
		timestamp: raw.timestamp ?? new Date(Number(BigInt(raw.id) >> 22n) + 1420070400000).toISOString(),
		editedTimestamp: raw.edited_timestamp ?? undefined,
		content: raw.content ?? "",
		author: {
			id: String(raw.author?.id ?? "unknown"),
			username: raw.author?.username ?? "unknown",
			displayName: raw.author?.global_name ?? raw.member?.nick ?? raw.author?.username ?? "unknown",
			bot: raw.author?.bot,
		},
		attachments: (raw.attachments ?? []).map((attachment: any) => ({
			id: String(attachment.id),
			filename: attachment.filename,
			description: attachment.description,
			contentType: attachment.content_type,
			size: attachment.size,
			url: attachment.url,
		})),
		embeds: raw.embeds ?? [],
		stickers: raw.sticker_items ?? [],
		reactions: raw.reactions ?? [],
		reference: raw.message_reference ? {
			...raw.message_reference,
			excerpt: raw.referenced_message?.content?.slice(0, 200),
		} : undefined,
		pinned: !!raw.pinned,
		type: raw.type ?? 0,
		url: `https://discord.com/channels/${link.guildId}/${link.channelId}/${raw.id}`,
		linked: String(raw.id) === link.messageId,
	};
}

export async function downloadImages(
	result: DiscordFetchResult,
	maxImages: number,
	config: DiscordConfig,
	signal: AbortSignal,
): Promise<void> {
	const candidates = result.messages
		.flatMap((message) => message.attachments)
		.filter((attachment) => attachment.contentType?.startsWith("image/"));
	const deduplicated = [...new Map(candidates.map((attachment) => [attachment.id || attachment.url, attachment])).values()];
	let successful = 0;
	for (const attachment of deduplicated) {
		const base = { attachmentId: attachment.id, url: attachment.url };
		if (successful >= maxImages) {
			result.skippedImages.push({ ...base, reason: "image limit exceeded" });
			continue;
		}
		if (!IMAGE_MIME_TYPES.has(attachment.contentType!)) {
			result.skippedImages.push({ ...base, reason: "unsupported image MIME type" });
			continue;
		}
		let url: URL;
		try { url = new URL(attachment.url); } catch {
			result.skippedImages.push({ ...base, reason: "invalid URL" });
			continue;
		}
		if (url.protocol !== "https:" || !CDN_HOSTS.test(url.hostname)) {
			result.skippedImages.push({ ...base, reason: "unsafe attachment host" });
			continue;
		}
		if (attachment.size > MAX_IMAGE_BYTES) {
			result.skippedImages.push({ ...base, reason: "image exceeds 5 MiB" });
			continue;
		}
		try {
			const response = await (config.fetch ?? fetch)(url, { signal, redirect: "error" });
			if (!response.ok) throw new Error(`HTTP ${response.status}`);
			const mimeType = (response.headers.get("content-type") ?? "").split(";")[0];
			if (mimeType !== attachment.contentType) throw new Error("mismatched MIME type");
			if (Number(response.headers.get("content-length")) > MAX_IMAGE_BYTES) throw new Error("image exceeds 5 MiB");
			const bytes = new Uint8Array(await response.arrayBuffer());
			if (bytes.length > MAX_IMAGE_BYTES) throw new Error("image exceeds 5 MiB");
			result.images.push({ ...base, mimeType, base64: Buffer.from(bytes).toString("base64") });
			successful++;
		} catch (error) {
			if (signal.aborted) throw error;
			result.skippedImages.push({ ...base, reason: error instanceof Error ? error.message : "download failed" });
		}
	}
}

export async function fetchDiscordContext(
	config: DiscordConfig,
	input: { url: string; maxMessages?: number; maxImages?: number },
	signal: AbortSignal,
): Promise<DiscordFetchResult> {
	const link = parseDiscordMessageUrl(input.url);
	const maxMessages = Math.min(5_000, Math.max(1, input.maxMessages ?? 500));
	let channel: any;
	let linked: any;
	if (link.messageId) {
		[linked, channel] = await Promise.all([
			discordRequest<any>(config, `/channels/${link.channelId}/messages/${link.messageId}`, signal),
			discordRequest<any>(config, `/channels/${link.channelId}`, signal),
		]);
	} else {
		channel = await discordRequest<any>(config, `/channels/${link.channelId}`, signal);
		if (!isThreadChannel(channel.type)) {
			throw new Error("Discord channel-only URLs are supported only for threads and forum posts");
		}
		const firstMessages = await fetchMessagesPagewise(config, link.channelId, signal, 1, "oldest");
		if (!firstMessages.length) throw new Error("Discord thread contains no accessible messages");
		linked = firstMessages[0];
		link.messageId = String(linked.id);
	}
	const linkedMessageId = link.messageId!;
	let rawMessages = [linked];
	let truncated = false;
	let omittedCount = 0;
	let omissions: TranscriptOmission[] = [];
	if (isThreadChannel(channel.type)) {
		const totalCount = Number(channel.total_message_sent ?? channel.message_count ?? 0);
		if (totalCount <= maxMessages) {
			rawMessages = await fetchMessagesPagewise(config, link.channelId, signal, maxMessages, "oldest");
			if (!rawMessages.some((message) => String(message.id) === link.messageId) && rawMessages.length < maxMessages) {
				rawMessages.push(linked);
			}
			rawMessages = uniqueSorted(rawMessages).slice(0, maxMessages);
		} else if (maxMessages === 1) {
			rawMessages = [linked];
			truncated = true;
			omittedCount = Math.max(0, totalCount - 1);
		} else {
			const allocation = allocateTranscriptWindows(maxMessages, false);
			const [oldest, newest] = await Promise.all([
				fetchMessagesPagewise(config, link.channelId, signal, allocation.oldest, "oldest"),
				fetchMessagesPagewise(config, link.channelId, signal, allocation.newest, "newest"),
			]);
			const merged = mergeTranscriptWindows({ oldest, newest, linked, maxMessages, totalCount });
			rawMessages = merged.messages;
			truncated = merged.truncated;
			omittedCount = merged.omittedCount;
			omissions = merged.omissions;
		}
	}
	const messages = rawMessages.map((raw) => normalize(raw, link)).sort(compareIds);
	const warnings: string[] = [];
	const normalMessages = messages.filter((message) => message.type === 0);
	if (normalMessages.length >= 2 && normalMessages.every(
		(message) => !message.content && !message.embeds.length && !message.attachments.length,
	)) {
		warnings.push("Message content may be unavailable because Message Content intent is disabled.");
	}
	const result: DiscordFetchResult = {
		sourceUrl: link.url,
		link,
		channel: {
			id: String(channel.id),
			name: channel.name ?? "unknown",
			type: channel.type,
			parentId: channel.parent_id ?? undefined,
		},
		messages,
		linkedMessageId,
		truncated,
		omittedCount,
		omittedEstimated: truncated,
		omissions,
		images: [],
		skippedImages: [],
		warnings,
	};
	await downloadImages(result, Math.min(50, Math.max(0, input.maxImages ?? 10)), config, signal);
	return result;
}
