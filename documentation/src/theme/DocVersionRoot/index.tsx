// filepath: d:\projects\typewriter\TypeWriter\documentation\src\theme\DocVersionRoot\index.tsx
import React from "react";
import { HtmlClassNameProvider, PageMetadata } from "@docusaurus/theme-common";
import {
  getDocsVersionSearchTag,
  DocsVersionProvider,
} from "@docusaurus/plugin-content-docs/client";
import renderRoutes from "@docusaurus/renderRoutes";
import SearchMetadata from "@theme/SearchMetadata";

// Define TypeScript interfaces
interface Version {
  version: string;
  pluginId: string;
  className: string;
  noIndex?: boolean;
  label: string;
  isLast: boolean;
  badge: boolean;
}

interface Route {
  routes: any[];
  path?: string;
}

interface DocVersionRootProps {
  version: Version;
  route: Route;
}

function DocVersionRootMetadata({
  version,
}: {
  version: Version;
}): JSX.Element {
  return (
    <>
      <SearchMetadata
        version={version.version}
        tag={getDocsVersionSearchTag(version.pluginId, version.version)}
      />
      <PageMetadata>
        {version.noIndex && <meta name="robots" content="noindex, nofollow" />}
      </PageMetadata>
    </>
  );
}

function DocVersionRootContent({
  version,
  route,
}: DocVersionRootProps): JSX.Element {
  return (
    <HtmlClassNameProvider className={version.className}>
      <DocsVersionProvider version={version}>
        <div className="doc-version-container">
          {renderRoutes(route.routes)}
        </div>
      </DocsVersionProvider>
    </HtmlClassNameProvider>
  );
}

export default function DocVersionRoot(
  props: DocVersionRootProps
): JSX.Element {
  // Make sure props.version exists before passing it down
  if (!props || !props.version || !props.route) {
    console.warn("DocVersionRoot: Missing required props");
    return <></>;
  }

  return (
    <>
      <DocVersionRootMetadata version={props.version} />
      <DocVersionRootContent {...props} />
    </>
  );
}
