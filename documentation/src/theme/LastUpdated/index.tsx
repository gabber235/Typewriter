import { ReactElement } from "react";
import { useDoc } from "@docusaurus/plugin-content-docs/client";
import Link from "@docusaurus/Link";
import { useLocation } from "@docusaurus/router";
import { useDateTimeFormat } from "@docusaurus/theme-common/internal";
import clsx from "clsx";
import { ThemeClassNames } from "@docusaurus/theme-common";

// Cache GitHub avatar URLs to avoid unnecessary network requests
const avatarCache = new Map();

// Helper functions
function formatDate(timestamp: number): string {
  const dateTimeFormat = useDateTimeFormat({
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  });

  return dateTimeFormat.format(new Date(timestamp));
}

function createGitHubProfileUrl(username: string): string {
  const formattedUsername = username.replace(/\s+/g, "-");
  return `https://github.com/${formattedUsername}`;
}

function createGitHubAvatarUrl(username: string): string {
  if (avatarCache.has(username)) {
    return avatarCache.get(username);
  }

  const formattedUsername = username.replace(/\s+/g, "-");
  const avatarUrl = `https://github.com/${formattedUsername}.png?size=100`;
  avatarCache.set(username, avatarUrl);
  return avatarUrl;
}

// UI Components
function AuthorAvatar({ author }: { author: string }): ReactElement {
  const avatarUrl = createGitHubAvatarUrl(author);

  return (
    <div className="flex-shrink-0 w-6 h-6 rounded-full overflow-hidden border border-gray-200 dark:border-gray-700 shadow-sm transition-transform group-hover:scale-110">
      <img
        src={avatarUrl}
        alt={`${author}'s profile picture`}
        className="w-full h-full object-cover"
        onError={(e) => {
          // Fallback to generic icon if the avatar loading fails
          e.currentTarget.style.display = "none";
          e.currentTarget.parentElement.innerHTML =
            '<div class="flex items-center justify-center w-full h-full bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400">' +
            '<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">' +
            '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zm-4 7a7 7 0 00-7 7h14a7 7 0 00-7-7z" />' +
            "</svg></div>";
        }}
      />
    </div>
  );
}

function AuthorComponent({ author }: { author: string }): ReactElement {
  const githubUrl = createGitHubProfileUrl(author);

  return (
    <Link
      to={githubUrl}
      className="flex items-center gap-x-1.5 px-1.5 py-0.5 rounded-full transition-colors duration-200 hover:no-underline hover:bg-gray-100 dark:hover:bg-gray-800 group"
      target="_blank"
      rel="noopener noreferrer"
    >
      <AuthorAvatar author={author} />
      <span className="text-xs text-gray-600 dark:text-gray-400 p-1.5 font-medium group-hover:text-primary group-hover:dark:text-primary-lighter whitespace-nowrap">
        {author}
      </span>
    </Link>
  );
}

function UpdatedTimestamp({ date }: { date: number }): ReactElement {
  return (
    <span className="text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">
      <span>Last updated on {formatDate(date)} by</span>
    </span>
  );
}

function UpdateMessage({ message }: { message: string }): ReactElement | null {
  if (!message) return null;

  return (
    <span
      className="ml-1 text-xs text-gray-500 dark:text-gray-400 truncate italic hidden md:inline"
      title={message}
    >
      &mdash; {message}
    </span>
  );
}

// Main component
type Props = {
  lastUpdatedAt?: number;
  lastUpdatedBy?: string;
  formattedLastUpdatedAt?: string;
};

export default function LastUpdated(props: Props): ReactElement | null {
  const doc = useDoc();
  const location = useLocation();

  // Don't render on blog or devlog pages
  if (
    location?.pathname?.includes("/devlog") ||
    location?.pathname?.includes("/blog")
  ) {
    return null;
  }

  // Get the last updated timestamp and author
  const lastUpdatedAt =
    props.lastUpdatedAt || (doc?.metadata as any)?.lastUpdatedAt;

  const lastUpdatedBy =
    props.lastUpdatedBy ||
    (doc?.metadata as any)?.lastUpdatedBy ||
    "TypeWriter Team";

  // If no update timestamp is available, don't render
  if (!lastUpdatedAt) {
    return null;
  }

  const commitMessage = (doc?.frontMatter as any)?.commitMessage || "";

  return (
    <div
      className={clsx(
        ThemeClassNames.common.lastUpdated,
        "flex items-center gap-x-2 rounded-md py-0.5 px-1",
        "text-gray-500 dark:text-gray-400",
        "w-full sm:w-auto"
      )}
    >
      <div className="flex items-center gap-x-1 overflow-hidden">
        <UpdatedTimestamp date={lastUpdatedAt} />
        <UpdateMessage message={commitMessage} />
      </div>
      <AuthorComponent author={lastUpdatedBy} />
      {process.env.NODE_ENV === "development" && (
        <span className="text-gray-400 italic text-xs hidden lg:inline">
          (Dev)
        </span>
      )}
    </div>
  );
}
