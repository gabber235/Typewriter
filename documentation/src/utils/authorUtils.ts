import fs from "fs-extra";
import path from "path";
import { Endpoints } from "@octokit/types";
import { exec, execSync } from 'child_process';
import { Globby } from "@docusaurus/utils/src/globUtils";

type endpoint = Endpoints["GET /repos/{owner}/{repo}/commits/{ref}"];
export class GitNotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'GitNotFoundError';
  }
}

export class FileNotTrackedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FileNotTrackedError';
  }
}

function hasGit(): boolean {
  try {
    execSync('git --version', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

async function throwGitErrors(file: string) {
  if (!hasGit()) {
    throw new GitNotFoundError(
      `Failed to retrieve git history for "${file}" because git is not installed.`,
    );
  }

  if (!(await fs.pathExists(file))) {
    throw new FileNotTrackedError(
      `Failed to retrieve git history for "${file}" because the file does not exist.`,
    );
  }
}

async function runGitCommandOnFile(file: string, args: string): Promise<{ 
  code: number; 
  stdout: string; 
  stderr: string; 
}> {
  const command = `git -c log.showSignature=false log ${args} -- "${path.basename(file)}"`;
  const cwd = path.dirname(file);

  return new Promise((resolve, reject) => {
    exec(
      command,
      { cwd },
      (error, stdout, stderr) => {
        resolve({
          code: error?.code ?? 0,
          stdout,
          stderr,
        });
      },
    );
  });
}

export async function getFileCommitHash(file: string): Promise<{ commit: string }> {
  await throwGitErrors(file);
  const result = await runGitCommandOnFile(
    file,
    '--format=RESULT:%h --max-count=1'
  );

  if (result.code !== 0) {
    throw new FileNotTrackedError(
      `Failed to retrieve git history for "${file}" because the file is not tracked by git.`,
    );
  }

  const regex = /(?:^|\n)RESULT:(?<commit>\w+)(?:$|\n)/;
  const match = regex.exec(result.stdout.trim());

  if (!match?.groups?.commit) {
    throw new Error(
      `Failed to parse git output for "${file}": ${result.stdout}\n${result.stderr}`,
    );
  }

  return { commit: match.groups.commit };
}
const headers = {
  Accept: "application/vnd.github.v3+json",
  "User-Agent": "PaperMC-Docs",
};

if (process.env.GITHUB_TOKEN !== undefined) {
  headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
}

export type AuthorData = {
  username: string;
  commit: string;
};

export const AUTHOR_FALLBACK: AuthorData = {
  commit: "1b3d5f7",
  username: "ghost",
};

export const commitCache: Map<string, string> = new Map();

async function cacheUsernameFromCommit(commit: string) {
  try {
    const response = await fetch(`https://api.github.com/repos/PaperMC/docs/commits/${commit}`, {
      headers,
    });
    if (!response.ok) {
      console.error(await response.text());
      throw new Error(`Received error status code ${response.status} (${response.statusText})`);
    }

    const body = (await response.json()) as endpoint["response"];
    const username = body.author.login;

    commitCache.set(commit, username);
  } catch (error) {
    // silent
    console.error(error);
  }
}

export const getFileCommitHashSafe = async (file: string): Promise<{ commit: string } | null> => {
  try {
    return await getFileCommitHash(file);
  } catch (e) {
    if (e instanceof FileNotTrackedError) {
      return null;
    }

    throw e; // different error, rethrow
  }
};

export async function cacheAuthorData(isPreview: boolean) {
  // Only Render in Production and not cache in every invocation of importing docusaurus.config.ts
  if (isPreview || !new Error().stack.includes("async loadSite")) {
    return;
  }
  const docPath = path.resolve("docs/");

  if (!(await fs.pathExists(docPath))) {
    return null;
  }

  const pagesFiles = await Globby("docs/**/*.md*");
  const commits = await Promise.all(pagesFiles.map(getFileCommitHashSafe));
  const commitsSet = new Set(commits.filter(Boolean).map((value) => value.commit));

  await Promise.all(Array.from(commitsSet).map(cacheUsernameFromCommit));
}