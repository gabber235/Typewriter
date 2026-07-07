import { execFileSync } from "node:child_process";
import { BASE_PATH } from "./base-path";

const DEFAULT_BRANCH = "develop";

// Deployed sites encode their branch in the base path — a site served under
// /branches/features/v1/ was built from the features/v1 branch, and the root
// deploy serves the default branch. Local dev has no DOCS_BASE_PATH, so ask
// git for the checked-out branch instead.
function detectBranch(): string {
	const deployed = /^\/branches\/(.+?)\/$/.exec(BASE_PATH);
	if (deployed) return deployed[1];
	if (process.env.DOCS_BASE_PATH) return DEFAULT_BRANCH;
	try {
		const branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], {
			encoding: "utf8",
			windowsHide: true,
		}).trim();
		// Detached HEAD reports the literal string "HEAD".
		if (branch && branch !== "HEAD") return branch;
	} catch {
		// No git available; fall through to the default branch.
	}
	return DEFAULT_BRANCH;
}

// The docs live in documentation/ inside the monorepo; Starlight appends
// each page's project-relative path (src/content/docs/...) to this.
export const EDIT_BASE_URL = `https://github.com/gabber235/typewriter/edit/${detectBranch()}/documentation/`;
