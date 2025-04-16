import { ReactElement } from "react";
import clsx from "clsx";
import EditThisPage from "../EditThisPage/index";
import LastUpdated from "../LastUpdated/index";

type Props = {
  className?: string;
  editUrl?: string;
  lastUpdatedAt?: number;
  lastUpdatedBy?: string;
};

export default function EditMetaRow({
  className,
  editUrl,
  lastUpdatedAt,
  lastUpdatedBy,
}: Props): ReactElement {
  return (
    <div className={clsx("pt-1", className)}>
      <div className="h-[1px] w-full bg-gray-400 mb-4 rounded-full"></div>
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div className="self-start">
          {editUrl && <EditThisPage editUrl={editUrl} />}
        </div>
        <div className="self-end sm:self-center">
          {(lastUpdatedAt || lastUpdatedBy) && (
            <LastUpdated
              lastUpdatedAt={lastUpdatedAt}
              lastUpdatedBy={lastUpdatedBy}
            />
          )}
        </div>
      </div>
    </div>
  );
}
