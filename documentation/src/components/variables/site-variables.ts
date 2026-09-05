import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "yaml";
import type { SiteVariables } from "./types";

const RELATIVE_PATH = "src/content/variables.yml";

let cached: SiteVariables | null = null;

export function getSiteVariables(): SiteVariables {
	if (cached) return cached;
	cached = load();
	return cached;
}

function load(): SiteVariables {
	const path = resolvePath();
	if (!path) {
		console.warn(
			`[remark-variables] ${RELATIVE_PATH} not found; every :var[] will render as a missing-variable marker`,
		);
		return {};
	}

	const parsed: unknown = parse(readFileSync(path, "utf8"));
	if (!parsed || typeof parsed !== "object") return {};

	const values: Record<string, string> = {};
	for (const [name, value] of Object.entries(parsed)) {
		if (value === null || typeof value === "object") continue;
		values[name] = String(value);
	}
	return values;
}

function resolvePath(): string | null {
	const candidates = [join(process.cwd(), RELATIVE_PATH), moduleRelativePath()];
	return candidates.find((path) => path !== null && existsSync(path)) ?? null;
}

function moduleRelativePath(): string | null {
	try {
		return fileURLToPath(
			new URL("../../content/variables.yml", import.meta.url),
		);
	} catch {
		return null;
	}
}
