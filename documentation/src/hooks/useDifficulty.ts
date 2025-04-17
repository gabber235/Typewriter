// filepath: d:\projects\typewriter\TypeWriter\documentation\src\hooks\useDifficulty.ts
import { useDoc } from "@docusaurus/plugin-content-docs/client";

/**
 * Custom hook to get the difficulty level from document frontmatter
 * @returns The difficulty level from the document's frontmatter or undefined
 */
export default function useDifficulty(): string | undefined {
  const { frontMatter } = useDoc();
  return (frontMatter as any)?.difficulty;
}
