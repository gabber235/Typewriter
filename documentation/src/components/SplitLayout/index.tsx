import React, { ReactNode, createContext, useContext, useState, useEffect } from "react";
import clsx from "clsx";

// Create context to track if any section has middle divider
const HasMiddleDividerContext = createContext<{
  hasMiddleDivider: boolean;
  setHasMiddleDivider: React.Dispatch<React.SetStateAction<boolean>>;
}>({
  hasMiddleDivider: false,
  setHasMiddleDivider: () => {},
});

type SplitLayoutProps = {
  children: ReactNode;
  className?: string;
  columns?: 2 | 3; // Added columns prop to specify number of columns
};

/**
 * A component that arranges its children in a responsive grid layout.
 * On mobile, items stack vertically; on desktop, they arrange in columns.
 * @param columns - Number of columns (2 or 3), defaults to 2
 */
export function SplitLayout({
  children,
  className,
  columns = 2, // Default to 2 columns for backward compatibility
}: SplitLayoutProps): React.ReactElement {
  const [hasMiddleDivider, setHasMiddleDivider] = useState(false);
  
  return (
    <HasMiddleDividerContext.Provider value={{ hasMiddleDivider, setHasMiddleDivider }}>
      <div
        className={clsx(
          "grid grid-cols-1 my-6",
          // Apply smaller gap when a middle divider exists
          hasMiddleDivider ? "gap-1" : "gap-5",
          columns === 3 ? "md:grid-cols-3" : "md:grid-cols-2",
          className
        )}  
      >
        {children}
      </div>
    </HasMiddleDividerContext.Provider>
  );
}

type SectionProps = {
  children: ReactNode;
  divider?: "left" | "right" | "middle" | "none";
  className?: string;
};

/**
 * A section within the SplitLayout component.
 * Can optionally have a divider on left, right, or both sides (middle).
 * If any section in the SplitLayout has a middle divider, all sections will have centered text.
 */
export function Section({
  children,
  divider = "none",
  className,
}: SectionProps): React.ReactElement {
  const { hasMiddleDivider, setHasMiddleDivider } = useContext(HasMiddleDividerContext);
  
  // Report if this section has a middle divider
  useEffect(() => {
    if (divider === "middle") {
      setHasMiddleDivider(true);
    }
    
    // No cleanup needed as we don't want to "unregister" middle dividers
    // when components unmount, as this could cause UI flashing
  }, [divider, setHasMiddleDivider]);
  
  return (
    <div
      className={clsx(
        className,
        // Apply text-center in two cases:
        // 1. This specific section has divider="middle"
        // 2. Any section in the parent SplitLayout has a middle divider
        (divider === "middle" || hasMiddleDivider) && "text-center",
        divider === "left" && "border-l pl-6 md:pl-8",
        divider === "right" && "border-r pr-6 md:pr-8",
        divider === "middle" && "border-l border-r px-6 md:px-8"
      )}
    >
      {children}
    </div>
  );
}