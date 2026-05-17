import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerFiberyCommands } from "./commands.ts";
import { registerFiberyTools } from "./tools.ts";

export default function fiberyExtension(pi: ExtensionAPI) {
	registerFiberyTools(pi);
	registerFiberyCommands(pi);
}
