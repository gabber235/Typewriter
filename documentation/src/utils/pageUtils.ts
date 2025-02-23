import { env } from "process";

export const preview = env.CI_ENV === "preview";

export const deploymentID: string =
  `${env.GITHUB_PR_HEAD_OWNER}-${env.GITHUB_HEAD_REF || env.GITHUB_REF_NAME}` // <PR head branch owner username>-<head branch name>
    .substring(0, 28) // capped to 28 characters
    .toLowerCase() // lowercase
    .replaceAll(/[/_.]/g, "-"); // sanitize characters in branch names