import type { DiscordFetchResult, NormalizedMessage } from "./discord-client.ts";

function clean(value: unknown): string {
	return String(value ?? "").replace(/\r/g, "");
}

function formatMessage(message: NormalizedMessage, isThreadStart: boolean): string {
	const tags = [
		isThreadStart ? "THREAD START" : "",
		message.linked ? "LINKED MESSAGE" : "",
		message.pinned ? "PINNED" : "",
		message.type ? `SYSTEM TYPE ${message.type}` : "",
	].filter(Boolean).map((tag) => `[${tag}]`).join(" ");
	const lines = [
		`## ${message.timestamp} — ${clean(message.author.displayName)} (@${clean(message.author.username)}, ${message.author.id}) ${tags}`,
		`Message ID: ${message.id}${message.author.bot ? " (bot)" : ""}`,
		`URL: ${message.url}`,
	];
	if (message.editedTimestamp) lines.push(`Edited: ${message.editedTimestamp}`);
	if (message.content) lines.push("", message.content);
	if (message.reference) {
		lines.push("", `Reply to: ${message.reference.message_id ?? "unknown"}${message.reference.excerpt ? ` — ${message.reference.excerpt}` : ""}`);
	}
	for (const embed of message.embeds) {
		lines.push("", `Embed: ${clean(embed.title || embed.type)}`);
		if (embed.url) lines.push(`URL: ${embed.url}`);
		if (embed.description) lines.push(clean(embed.description));
		for (const field of embed.fields ?? []) lines.push(`- ${clean(field.name)}: ${clean(field.value)}`);
	}
	for (const attachment of message.attachments) {
		lines.push(
			"",
			`Attachment: ${attachment.filename} (${attachment.contentType ?? "unknown"}, ${attachment.size ?? 0} bytes)${attachment.description ? ` — ${attachment.description}` : ""}`,
			attachment.url,
		);
	}
	for (const sticker of message.stickers) lines.push(`Sticker: ${sticker.name} (${sticker.id})`);
	for (const reaction of message.reactions) lines.push(`Reaction: ${reaction.emoji?.name ?? reaction.emoji?.id} × ${reaction.count}`);
	return lines.join("\n");
}

export function formatDiscordTranscript(result: DiscordFetchResult): string {
	const threadTypes: Record<number, string> = { 10: "news thread", 11: "public thread", 12: "private thread" };
	const isThread = result.channel.type in threadTypes;
	const lines = [
		`# Discord ${isThread ? "thread" : "message"}: ${result.channel.name}`,
		`Source: ${result.sourceUrl}`,
		`Channel type: ${threadTypes[result.channel.type] ?? result.channel.type}`,
		`Messages returned: ${result.messages.length}${result.truncated ? ` (transcript truncated; estimated ${result.omittedCount} omitted)` : ""}`,
		`Linked message: ${result.linkedMessageId}`,
		"",
	];
	for (let index = 0; index < result.messages.length; index++) {
		const message = result.messages[index];
		const previous = result.messages[index - 1];
		const omission = previous && result.omissions.find(
			(item) => item.afterMessageId === previous.id && item.beforeMessageId === message.id,
		);
		if (omission) {
			const quantity = result.omissions.length > 1
				? "messages omitted at this retained boundary"
				: `${omission.count} messages omitted from the middle`;
			lines.push(`--- ${quantity}${omission.estimated ? " (estimated)" : ""} ---`, "");
		}
		lines.push(formatMessage(message, isThread && index === 0), "");
	}
	for (const skipped of result.skippedImages) lines.push(`Skipped image ${skipped.url}: ${skipped.reason}`);
	for (const warning of result.warnings) lines.push(`Warning: ${warning}`);
	return lines.join("\n").trim();
}

export function toPublicDetails(result: DiscordFetchResult) {
	const { images, ...rest } = result;
	return { ...rest, images: images.map(({ base64, ...metadata }) => metadata) };
}
