import React, { ReactNode } from "react";
import clsx from "clsx";

type FeatureHighlightItem = {
  id: string;
  title: string;
  description?: string | ReactNode;
  icon?: string;
  color?: "blue" | "green" | "purple" | "orange" | "gray" | "sky" | "default";
  className?: string;
};

type FeatureHighlightsProps = {
  items: FeatureHighlightItem[];
  layout?: "horizontal" | "vertical" | "grid";
  compact?: boolean;
  className?: string;
};

const colorMap = {
  purple: {
    bg: "bg-purple-50 dark:bg-purple-900/20",
    ring: "ring-purple-500",
  },
  orange: {
    bg: "bg-[#fff8e6] dark:bg-[#4d3800]",
    ring: "ring-[#e6a700]",
  },
  gray: {
    bg: "bg-gray-100 dark:bg-zinc-600",
    ring: "ring-[#1f2937] dark:ring-white",
  },
  sky: {
    bg: "bg-sky-50 dark:bg-[#193c47]",
    ring: "ring-[#4cb3d4]",
  },
  default: {
    bg: "bg-green-50 dark:bg-[#003100]",
    ring: "ring-[#009400]",
  },
  grayish: {
    bg: "bg-gray-50 dark:bg-gray-700/60",
    ring: "ring-gray-200 dark:ring-zinc-300",
  },
};

export function FeatureHighlights({
  items,
  layout = "horizontal",
  compact = false,
  className,
}: FeatureHighlightsProps): JSX.Element {
  // Determine container layout class
  const containerClass = {
    horizontal: "flex flex-wrap justify-center gap-2",
    vertical: "flex flex-col gap-2",
    grid: "grid grid-cols-1 md:grid-cols-2 gap-2 auto-rows-fr",
  }[layout];

  return (
    <div className={clsx(containerClass, "my-4", className)}>
      {items.map((item) => {
        const colorStyle = colorMap[item.color || "default"];
        if (layout === "horizontal" || compact) {
          // Pill style (similar to QuestStates)
          return (
            <span
              key={item.id}
              className={clsx(
                "px-3 py-1 rounded font-medium ring-1",
                colorStyle.bg,
                colorStyle.ring,
                item.className
              )}
            >
              {item.icon && <span className="mr-1">{item.icon}</span>}
              {item.title}
            </span>
          );
        } else if (layout === "vertical") {
          // Card style with left border (for vertical/grid layouts)
          return (
            <div
              key={item.id}
              className={clsx(
                "p-2 border-l-4 pl-3 ring-1",
                colorStyle.bg,
                colorStyle.ring,
                item.className
              )}
            >
              <strong>
                {item.icon && <span className="mr-1">{item.icon}</span>}
                {item.title}
              </strong>
              {item.description && (
                <p className="text-sm m-0">
                  {typeof item.description === "string"
                    ? // Process string descriptions for code segments wrapped in backticks
                      item.description.split(/(`[^`]+`)/).map((part, index) => {
                        // If part starts and ends with backticks, render as code
                        if (part.startsWith("`") && part.endsWith("`")) {
                          return (
                            <code
                              key={index}
                              className="px-1 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs font-mono"
                            >
                              {part.slice(1, -1)}
                            </code>
                          );
                        }
                        return part;
                      })
                    : item.description}
                </p>
              )}
            </div>
          );
        } else if (layout === "grid") {
          return (
            <div
              key={item.id}
              className={clsx(
                "p-2 border-l-4 pl-3 ring-1 rounded-md h-full flex flex-col",
                colorStyle.bg,
                colorStyle.ring,
                item.className
              )}
            >
              <div className="flex flex-col h-full">
                <strong className="pt-1">
                  {item.icon && <span className="mr-1">{item.icon}</span>}
                  {item.title}
                </strong>
                {item.description && (
                  <p className="text-sm m-0 mt-auto mb-auto">
                    {typeof item.description === "string"
                      ? // Process string descriptions for code segments wrapped in backticks
                        item.description
                          .split(/(`[^`]+`)/)
                          .map((part, index) => {
                            // If part starts and ends with backticks, render as code
                            if (part.startsWith("`") && part.endsWith("`")) {
                              return (
                                <code
                                  key={index}
                                  className="px-1 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs font-mono"
                                >
                                  {part.slice(1, -1)}
                                </code>
                              );
                            }
                            return part;
                          })
                      : item.description}
                  </p>
                )}
              </div>
            </div>
          );
        }
      })}
    </div>
  );
}
