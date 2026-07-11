import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { fetchDiscordContext, getDiscordConfig } from "./discord-client.ts";
import { formatDiscordTranscript, toPublicDetails } from "./format.ts";

export function registerDiscordTools(pi: ExtensionAPI) {
	pi.registerTool({
		name: "discord_fetch_message",
		label: "Fetch Discord Message",
		description: "Fetch a Discord message or a bounded transcript from a thread/forum link",
		promptSnippet: "When the user gives a Discord message or thread link, fetch it to inspect the message or thread context.",
		parameters: Type.Object({
			url: Type.String({ description: "Discord message or thread URL" }),
			maxMessages: Type.Optional(Type.Integer({ minimum: 1, maximum: 5000 })),
			maxImages: Type.Optional(Type.Integer({ minimum: 0, maximum: 50 })),
		}),
		async execute(_id, params, signal, _update, ctx) {
			const result = await fetchDiscordContext(await getDiscordConfig(ctx.cwd), params, signal);
			return {
				content: [
					{ type: "text" as const, text: formatDiscordTranscript(result) },
					...result.images.map((image) => ({
						type: "image" as const,
						data: image.base64,
						mimeType: image.mimeType,
					})),
				],
				details: toPublicDetails(result),
			};
		},
	});
}
