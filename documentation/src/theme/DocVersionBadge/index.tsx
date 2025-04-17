// filepath: d:\projects\typewriter\TypeWriter\documentation\src\theme\DocVersionBadge\index.tsx
import React from "react";
import { Icon } from "@iconify/react";
import Translate from "@docusaurus/Translate";
import { ThemeClassNames } from "@docusaurus/theme-common";
import { useDocsVersion } from "@docusaurus/plugin-content-docs/client";
import useDifficulty from "../../hooks/useDifficulty";

type DifficultyLevel = "easy" | "normal" | "hard" | string;

export default function DocVersionBadge(): JSX.Element | null {
  const versionMetadata = useDocsVersion();
  const difficultyLevel = useDifficulty();

  // Function to get the appropriate icon based on difficulty level
  const getDifficultyIcon = (difficulty: DifficultyLevel): string => {
    switch (difficulty?.toLowerCase()) {
      case "easy":
        return "mdi:check-circle-outline"; // Simplified icon for easy
      case "normal":
        return "mdi:star-outline"; // Star icon for normal
      case "hard":
        return "mdi:alert-octagram-outline"; // Lightning bolt for hard
      default:
        return "mdi:help-circle"; // Question mark for unknown
    }
  };

  // Function to determine badge class based on difficulty level
  const getBadgeClasses = (difficulty: DifficultyLevel): string => {
    switch (difficulty?.toLowerCase()) {
      case "easy":
        return "bg-green-200 dark:bg-[#003100] text-green-800 dark:text-green-300 border-green-200 dark:border-green-800/50";
      case "normal":
        return "bg-yellow-100 dark:bg-[#4d3800] text-yellow-800 dark:text-yellow-300 border-yellow-200 dark:border-yellow-800/50";
      case "hard":
        return "bg-red-100 dark:bg-[#4b1113] text-red-800 dark:text-red-300 border-red-200 dark:border-red-800/50";
      default:
        return "bg-gray-100 dark:bg-gray-800/50 text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-700/50";
    }
  };

  if (!versionMetadata?.badge) {
    return null;
  }

  return (
    <div className="flex flex-wrap gap-2 mb-1">
      <div className="inline-flex p-[5px] pr-0 pb-0 pt-0">
        <span
          className={`${ThemeClassNames.docs.docVersionBadge} group inline-flex items-center px-2 py-1 text-xs font-medium rounded-full border 
          bg-blue-100 dark:bg-[#193c47] text-blue-800 dark:text-blue-300 border-blue-200 dark:border-blue-800/50
          transition-colors duration-200`}
        >
          <Icon
            icon="mdi:information-outline"
            className="inline-block mr-1 h-3.5 w-3.5 align-text-bottom"
          />
          <Translate
            id="theme.docs.versionBadge.label"
            values={{ versionLabel: versionMetadata.label }}
          >
            {"Version: {versionLabel}"}
          </Translate>
        </span>
      </div>

      {difficultyLevel && (
        <div className="inline-flex p-[5px] pr-0 pb-0 pt-0">
          <span
            className={`group inline-flex items-center px-2 py-1 text-xs font-medium rounded-full border
            transition-colors duration-200 ${getBadgeClasses(difficultyLevel)}`}
          >
            <Icon
              icon={getDifficultyIcon(difficultyLevel)}
              className={`inline-block mr-1 h-3.5 w-3.5 align-text-bottom ${
                difficultyLevel?.toLowerCase() === "easy"
                  ? "text-green-500 dark:text-green-400"
                  : difficultyLevel?.toLowerCase() === "normal"
                  ? "text-yellow-500 dark:text-yellow-400"
                  : difficultyLevel?.toLowerCase() === "hard"
                  ? "text-red-500 dark:text-red-400"
                  : ""
              }`}
            />
            <Translate
              id="theme.docs.difficultyBadge.label"
              values={{ difficultyLevel }}
            >
              {"Difficulty: {difficultyLevel}"}
            </Translate>
          </span>
        </div>
      )}
    </div>
  );
}
