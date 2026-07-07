import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";

export interface Editor {
	name: string;
	email: string;
	/** GitHub username, when it can be derived from the commit email. */
	login?: string;
	commits: number;
	/** Unix seconds of this editor's most recent commit to the page. */
	lastTimestamp: number;
}

interface Attribution {
	name: string;
	email: string;
}

// Automation noise: CI bots and AI co-author trailers don't belong in the
// page credits.
const IGNORED = [
	/\[bot\]/i,
	/^actions@github\.com$/i,
	/^noreply@anthropic\.com$/i,
];

const GITHUB_NOREPLY = /^(?:\d+\+)?([a-z\d-]+)@users\.noreply\.github\.com$/i;

// GitHub username rules: alphanumeric with single interior hyphens, max 39
// characters. Real-name authors ("John Doe") never match.
const GITHUB_USERNAME = /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i;

export function avatarUrl(login: string): string {
	return `https://github.com/${login}.png?size=64`;
}

// Profile links and avatars are derived from the anonymized GitHub noreply
// address when present, else from handle-shaped author names (git user.name
// set to the GitHub username, the convention in this repo). Private emails
// are never mapped or published — unresolved editors render as an unlinked
// initial instead.
function loginFor({ name, email }: Attribution): string | undefined {
	const noreply = GITHUB_NOREPLY.exec(email)?.[1];
	if (noreply) return noreply;
	return GITHUB_USERNAME.test(name) ? name : undefined;
}

function isIgnored({ name, email }: Attribution): boolean {
	return IGNORED.some((pattern) => pattern.test(name) || pattern.test(email));
}

function parseCoAuthor(value: string): Attribution | undefined {
	const match = /^(.+?)\s*<([^>]*)>$/.exec(value.trim());
	if (!match) return undefined;
	return { name: match[1], email: match[2] };
}

// One commit per line, newest first: name \0 email \0 unix-seconds \0
// co-authored-by trailer values joined with \x01.
function aggregate(output: string): Editor[] {
	const editors = new Map<string, Editor>();
	for (const line of output.split("\n")) {
		if (!line) continue;
		const [name, email, timestamp, trailers] = line.split("\0");
		if (!name || email === undefined || timestamp === undefined) continue;

		const attributions: Attribution[] = [{ name, email }];
		if (trailers) {
			for (const value of trailers.split("\u0001")) {
				const coAuthor = parseCoAuthor(value);
				if (coAuthor) attributions.push(coAuthor);
			}
		}

		for (const attribution of attributions) {
			if (isIgnored(attribution)) continue;
			const login = loginFor(attribution);
			const key = (
				login ??
				attribution.email ??
				attribution.name
			).toLowerCase();
			const existing = editors.get(key);
			if (existing) {
				existing.commits += 1;
			} else {
				editors.set(key, {
					...attribution,
					login,
					commits: 1,
					lastTimestamp: Number(timestamp),
				});
			}
		}
	}
	return [...editors.values()].sort(
		(a, b) => b.commits - a.commits || b.lastTimestamp - a.lastTimestamp,
	);
}

const cache = new Map<string, Editor[]>();

/**
 * Everyone who ever committed to the page, from local git history. `git log`
 * rather than blame: rewriting a page shouldn't erase earlier editors from
 * the credits. Paths are relative to the project root, which is also where
 * the astro CLI runs.
 */
export function getEditors(filePath: string): Editor[] {
	const cached = cache.get(filePath);
	if (cached) return cached;

	let editors: Editor[] = [];
	try {
		if (existsSync(filePath)) {
			const output = execFileSync(
				"git",
				[
					"log",
					"--follow",
					"--use-mailmap",
					"--format=%an%x00%ae%x00%at%x00%(trailers:key=Co-authored-by,valueonly,separator=%x01)",
					"--",
					filePath,
				],
				{ encoding: "utf8", windowsHide: true },
			);
			editors = aggregate(output);
		}
	} catch {
		// No git binary or shallow/absent history: skip the credits rather
		// than fail the build.
	}
	cache.set(filePath, editors);
	return editors;
}
