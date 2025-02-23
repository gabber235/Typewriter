import fs from "fs-extra";
import path from "path";
import { Endpoints } from "@octokit/types";

import { getFileCommitHash, FileNotTrackedError } from "@docusaurus/utils/src/gitUtils";
import { Globby } from "@docusaurus/utils/src/globUtils";

type endpoint = Endpoints["GET /repos/{owner}/{repo}/commits/{ref}"];

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