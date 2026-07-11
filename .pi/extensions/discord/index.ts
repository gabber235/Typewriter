import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerDiscordTools } from "./tools.ts";

export default function discordExtension(pi: ExtensionAPI) {
	registerDiscordTools(pi);
}
