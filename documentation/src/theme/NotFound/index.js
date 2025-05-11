import React, { useEffect } from "react";
import { useHistory } from "@docusaurus/router";
import NotFound from "@theme-original/NotFound";

// This component wraps the original NotFound component and adds logic to redirect
// to a fallback page if we're coming from a version switch navigation
export default function NotFoundWrapper(props) {
  const history = useHistory();

  useEffect(() => {
    // Check if we have a version fallback path in sessionStorage
    try {
      const fallbackData = sessionStorage.getItem("docusaurus.versionFallback");
      if (fallbackData) {
        const { targetPath, fallbackPath, timestamp } =
          JSON.parse(fallbackData);

        // Only use the fallback if it's recent (within the last 5 seconds)
        // and if the current path matches the targetPath
        const currentPath = window.location.pathname;
        const isRecent = Date.now() - timestamp < 5000;

        if (isRecent && currentPath === targetPath) {
          // Clear the fallback data and redirect to the fallback path
          sessionStorage.removeItem("docusaurus.versionFallback");
          history.replace(fallbackPath);
          return;
        }
      }
    } catch (e) {
      console.error("Error handling version fallback:", e);
      // Clear any corrupted data
      sessionStorage.removeItem("docusaurus.versionFallback");
    }
  }, [history]);

  // Render the original NotFound component
  return <NotFound {...props} />;
}
