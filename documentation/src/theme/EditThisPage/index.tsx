import { ReactElement } from "react";
import Translate from "@docusaurus/Translate";
import { ThemeClassNames } from "@docusaurus/theme-common";
import Link from "@docusaurus/Link";
import type { Props } from "@theme/EditThisPage";

// Simple SVG edit icon component
function EditIcon(): ReactElement {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="inline-block mr-1.5 h-3.5 w-3.5 align-text-bottom transition-transform group-hover:scale-110"
    >
      <path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path>
    </svg>
  );
}

export default function EditThisPage({ editUrl }: Props): ReactElement {
  return (
    <Link
      to={editUrl}
      className={`${ThemeClassNames.common.editThisPage} group inline-flex items-center px-2 py-1 text-xs font-medium rounded-full transition-colors duration-200 
      text-gray-600 dark:text-gray-400
      hover:no-underline hover:bg-gray-100 dark:hover:bg-gray-800`}
    >
      <EditIcon />
      <span className="group-hover:text-primary group-hover:dark:text-primary-lighter p-1">
        <Translate
          id="theme.common.editThisPage"
          description="The link label to edit the current page"
        >
          Edit this page
        </Translate>
      </span>
    </Link>
  );
}
