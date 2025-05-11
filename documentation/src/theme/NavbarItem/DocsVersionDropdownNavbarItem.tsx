import React from "react";
import {
  useVersions,
  useActiveDocContext,
  useDocsVersionCandidates,
  useDocsPreferredVersion,
} from "@docusaurus/plugin-content-docs/client";
import { translate } from "@docusaurus/Translate";
import { useLocation } from "@docusaurus/router";
import DefaultNavbarItem from "@theme/NavbarItem/DefaultNavbarItem";
import DropdownNavbarItem from "@theme/NavbarItem/DropdownNavbarItem";
import type { Props } from "@theme/NavbarItem/DocsVersionDropdownNavbarItem";
import type { LinkLikeNavbarItemProps } from "@theme/NavbarItem";
import type {
  GlobalVersion,
  GlobalDoc,
  ActiveDocContext,
} from "@docusaurus/plugin-content-docs/client";

function getVersionMainDoc(version: GlobalVersion): GlobalDoc {
  return version.docs.find((doc) => doc.id === version.mainDocId)!;
}

function getVersionTargetDoc(
  version: GlobalVersion,
  activeDocContext: ActiveDocContext
): GlobalDoc {
  // We try to link to the same doc, in another version
  // When not possible, fallback to the "main doc" of the version
  return (
    activeDocContext.alternateDocVersions[version.name] ??
    getVersionMainDoc(version)
  );
}

export default function DocsVersionDropdownNavbarItem({
  mobile,
  docsPluginId,
  dropdownActiveClassDisabled,
  dropdownItemsBefore,
  dropdownItemsAfter,
  ...props
}: Props): JSX.Element {
  const { pathname, search, hash } = useLocation();
  const activeDocContext = useActiveDocContext(docsPluginId);
  const versions = useVersions(docsPluginId);
  const { savePreferredVersionName } = useDocsPreferredVersion(docsPluginId);

  // Helper function to extract the path without version prefix
  function getPathWithoutVersionPrefix(
    path: string,
    versionName?: string
  ): string {
    // Default paths to check
    const pathsToCheck = ["/beta/"];

    // Add the active version path if available
    if (versionName) {
      pathsToCheck.push(`/${versionName}/`);
    }

    // Also check for other version paths
    versions.forEach((version) => {
      pathsToCheck.push(`/${version.name}/`);
    });

    // Find the first matching prefix and remove it
    for (const prefix of pathsToCheck) {
      if (path.startsWith(prefix)) {
        return path.substring(prefix.length);
      }
    }

    // If no prefix matches, ensure we don't return a path starting with a slash
    // to avoid double slashes when constructing new paths
    if (path.startsWith("/")) {
      return path.substring(1);
    }

    // Return the original path
    return path;
  }

  function versionToLink(version: GlobalVersion): LinkLikeNavbarItemProps {
    const targetDoc = getVersionTargetDoc(version, activeDocContext);
    return {
      label: version.label,
      // preserve ?search#hash suffix on version switches
      to: `${targetDoc.path}${search}${hash}`,
      isActive: () => version === activeDocContext.activeVersion,
      onClick: () => savePreferredVersionName(version.name),
    };
  }

  // Modify dropdownItemsAfter to preserve the current path for archived versions
  const modifiedDropdownItemsAfter = [...dropdownItemsAfter];
  if (modifiedDropdownItemsAfter.length > 0 && activeDocContext.activeVersion) {
    // Extract the current path without version prefix using our helper
    const currentPath = getPathWithoutVersionPrefix(
      pathname,
      activeDocContext.activeVersion.name
    );

    // If we have a valid path, use it for archived versions
    if (currentPath) {
      // Find the index where archived versions start
      const archivedVersionsIndex = modifiedDropdownItemsAfter.findIndex(
        (item) =>
          item.type === "html" &&
          item.className === "dropdown-archived-versions"
      );

      if (
        archivedVersionsIndex !== -1 &&
        archivedVersionsIndex + 1 < modifiedDropdownItemsAfter.length
      ) {
        // Update the archived version links to preserve the current path structure
        for (
          let i = archivedVersionsIndex + 1;
          i < modifiedDropdownItemsAfter.length;
          i++
        ) {
          const item = modifiedDropdownItemsAfter[i];
          // Only process actual version links (not separators or other elements)
          if (item.to && typeof item.to === "string" && item.label) {
            const versionNumber = item.label.toString();

            // Replace with path to the equivalent document in archived version
            // Make sure we're not processing the "All versions" link at the end
            if (!item.to.includes("/versions")) {
              modifiedDropdownItemsAfter[i] = {
                ...item,
                to: `/${versionNumber}/docs/home`,
                href: undefined,
                target: "_self",
                onClick: (e) => {
                  e.preventDefault();

                  // Try to navigate to the equivalent path in the target version,
                  // with a fallback to the home page

                  // Ensure no double slashes when constructing the target path
                  const cleanPath = currentPath.startsWith("/")
                    ? currentPath.substring(1)
                    : currentPath;
                  const targetPath = cleanPath
                    ? `/${versionNumber}/${cleanPath}`
                    : `/${versionNumber}/docs/home`;
                  const fallbackPath = `/${versionNumber}/docs/home`;

                  // Create URL objects to handle path normalization
                  const targetUrl = new URL(targetPath, window.location.origin); // Use a HEAD request instead of fetch to check if the page exists
                  // This is more reliable for checking page existence in Docusaurus
                  const xhr = new XMLHttpRequest();
                  xhr.open("HEAD", targetUrl.href, true);

                  xhr.onreadystatechange = function () {
                    if (xhr.readyState === 4) {
                      if (xhr.status === 200) {
                        // Page exists, navigate to it
                        console.log(
                          `[Version Navigation] Target page exists: ${targetUrl.href}`
                        );
                        window.location.href = targetUrl.href + search + hash;
                      } else {
                        // If the target doesn't exist, try a common pattern in Docusaurus
                        // where URLs might end with /index.html
                        console.log(
                          `[Version Navigation] Target page doesn't exist: ${targetUrl.href}, status: ${xhr.status}. Trying index pattern.`
                        );
                        const indexPath = targetPath.endsWith("/")
                          ? `${targetPath}index.html`
                          : `${targetPath}/index.html`;

                        const indexXhr = new XMLHttpRequest();
                        indexXhr.open(
                          "HEAD",
                          new URL(indexPath, window.location.origin).href,
                          true
                        );
                        indexXhr.onreadystatechange = function () {
                          if (indexXhr.readyState === 4) {
                            if (indexXhr.status === 200) {
                              // Index page exists, navigate to it
                              console.log(
                                `[Version Navigation] Index page exists: ${indexPath}`
                              );
                              window.location.href =
                                new URL(indexPath, window.location.origin)
                                  .href +
                                search +
                                hash;
                            } else {
                              // Neither page exists, navigate to fallback
                              console.log(
                                `[Version Navigation] Index page doesn't exist: ${indexPath}, status: ${indexXhr.status}. Falling back to home.`
                              );
                              window.location.href =
                                new URL(fallbackPath, window.location.origin)
                                  .href +
                                search +
                                hash;
                            }
                          }
                        };
                        indexXhr.send();
                      }
                    }
                  };
                  xhr.send();
                },
              };
            }
          }
        }
      }
    }
  }

  // Build the version items for the dropdown
  const regularVersionItems = versions.map(versionToLink);

  // Combine all items
  const items: LinkLikeNavbarItemProps[] = [
    ...dropdownItemsBefore,
    ...regularVersionItems,
    ...modifiedDropdownItemsAfter,
  ];

  const dropdownVersion = useDocsVersionCandidates(docsPluginId)[0];

  // Mobile dropdown is handled a bit differently
  const dropdownLabel =
    mobile && items.length > 1
      ? translate({
          id: "theme.navbar.mobileVersionsDropdown.label",
          message: "Versions",
          description:
            "The label for the navbar versions dropdown on mobile view",
        })
      : dropdownVersion.label;
  const dropdownTo =
    mobile && items.length > 1
      ? undefined
      : getVersionTargetDoc(dropdownVersion, activeDocContext).path;

  // We don't want to render a version dropdown with 0 or 1 item. If we build
  // the site with a single docs version (onlyIncludeVersions: ['1.0.0']),
  // We'd rather render a button instead of a dropdown
  if (items.length <= 1) {
    return (
      <DefaultNavbarItem
        {...props}
        mobile={mobile}
        label={dropdownLabel}
        to={dropdownTo}
        isActive={dropdownActiveClassDisabled ? () => false : undefined}
      />
    );
  }

  return (
    <DropdownNavbarItem
      {...props}
      mobile={mobile}
      label={dropdownLabel}
      to={dropdownTo}
      items={items}
      isActive={dropdownActiveClassDisabled ? () => false : undefined}
    />
  );
}
