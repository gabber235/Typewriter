import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { buildFiberyMaintenancePrompt, buildFiberyNewPrompt } from "./prompts.ts";

export function registerFiberyCommands(pi: ExtensionAPI): void {
	pi.registerCommand("fibery-new", {
		description: "Start the guided Fibery bug/feature flow",
		handler: async (args, ctx) => {
			if (!ctx.isIdle()) {
				ctx.ui.notify("Wait for the current agent turn before starting Fibery intake.", "warning");
				return;
			}
			pi.sendUserMessage(
				buildFiberyNewPrompt(args, {
					cwd: ctx.cwd,
					mode: "infer-kind-with-override",
				}),
			);
		},
	});

	pi.registerCommand("fibery-maintain", {
		description: "Audit the Pi Fibery extension against the live workspace",
		handler: async (args, ctx) => {
			if (!ctx.isIdle()) {
				ctx.ui.notify("Wait for the current agent turn before starting Fibery maintenance.", "warning");
				return;
			}
			pi.sendUserMessage(
				buildFiberyMaintenancePrompt(args, {
					cwd: ctx.cwd,
					mode: "slash-command-only",
				}),
			);
		},
	});
}
