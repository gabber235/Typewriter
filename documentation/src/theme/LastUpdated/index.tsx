import React from "react";
import Translate from "@docusaurus/Translate";
import { ThemeClassNames } from "@docusaurus/theme-common";
import { useDateTimeFormat } from "@docusaurus/theme-common/internal";
import { useDoc } from "@docusaurus/plugin-content-docs/client";
import type { Props } from "@theme/LastUpdated";
import Link from "@docusaurus/Link";

function LastUpdatedAtDate({ lastUpdatedAt }: { lastUpdatedAt: number }): JSX.Element {
  const atDate = new Date(lastUpdatedAt);

  const dateTimeFormat = useDateTimeFormat({
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  });

  const formattedLastUpdatedAt = dateTimeFormat.format(atDate);

  return (
    <Translate
      id="theme.lastUpdated.atDate"
      description="The words used to describe on which date a page has been last updated"
      values={{
        date: (
          <b>
            <time dateTime={atDate.toISOString()} itemProp="dateModified">
              {formattedLastUpdatedAt}
            </time>
          </b>
        ),
      }}
    >
      {" on {date}"}
    </Translate>
  );
}

function LastUpdatedByUser({
  lastUpdatedBy,
  username,
}: {
  lastUpdatedBy: string;
  username: string;
}): JSX.Element {
  return (
    <Translate
      id="theme.lastUpdated.byUser"
      description="The words used to describe by who the page has been last updated"
      values={{
        user: (
          <b>
            {username !== "ghost" ? (
              <Link to={"https://github.com/" + username}>{lastUpdatedBy}</Link>
            ) : (
              lastUpdatedBy
            )}
          </b>
        ),
      }}
    >
      {" by {user}"}
    </Translate>
  );
}

function LastUpdatedInCommit({ lastUpdatedIn }: { lastUpdatedIn: string }): JSX.Element {
  return (
    <>
      <span> in </span>
      <b>
        <Link to={"https://github.com/gabber235/TypeWriter/commit/" + lastUpdatedIn}>{lastUpdatedIn}</Link>
      </b>
    </>
  );
}

export default function LastUpdated({ lastUpdatedAt, lastUpdatedBy }: Props): JSX.Element {
  const doc = useDoc();

  const author = (doc.frontMatter as any).author as {
    commit: string;
    username: string;
  };

  return (
    <span className={ThemeClassNames.common.lastUpdated}>
      <Translate
        id="theme.lastUpdated.lastUpdatedAtBy"
        description="The sentence used to display when a page has been last updated, and by who"
        values={{
          atDate: lastUpdatedAt ? <LastUpdatedAtDate lastUpdatedAt={lastUpdatedAt} /> : "",
          byUser: lastUpdatedBy ? (
            <LastUpdatedByUser lastUpdatedBy={lastUpdatedBy} username={author.username} />
          ) : (
            ""
          ),
          inCommit: <LastUpdatedInCommit lastUpdatedIn={author.commit} />,
        }}
      >
        {"Last updated{atDate}{byUser}{inCommit}"}
      </Translate>
      {process.env.NODE_ENV === "development" && (
        <div>
          {/* eslint-disable-next-line @docusaurus/no-untranslated-text */}
          <small> (Simulated during dev for better perf)</small>
        </div>
      )}
    </span>
  );
}