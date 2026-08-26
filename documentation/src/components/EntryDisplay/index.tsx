import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";
import { ReactFlowProvider } from "reactflow";
import { PageLayout } from "./graph";
import { Page } from "../../libs/data";
import EntryInspector from "./inspector";
import { useMemo } from "react";

interface EntryDisplayProps {
    pages: Page[];
    /**
    * Pages that are not shown as a graph, but where entries can be referenced.
    */
    referencePages: Page[];
}

export function capitalize(value: string) {
    if (value.length === 0) return value;
    return value.charAt(0).toUpperCase() + value.slice(1);
}

/** Names come in as `snake_case` or `camelCase` paths, the panel shows them as words. */
export function format(value: string) {
    return value
        .split(".")
        .map((part) =>
            part
                .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
                .split(/[_\s]+/)
                .map((word) => capitalize(word))
                .join(" ")
        )
        .join(" | ");
}

export default function EntryDisplay({ pages = [], referencePages = [] }: EntryDisplayProps) {
    const totalPages = useMemo(() => pages.concat(referencePages), [pages, referencePages]);
    return (
        <Tabs lazy>
            {pages.map((page) => (
                <TabItem key={page.name} value={page.name} label={format(page.name)}>
                    <ReactFlowProvider>
                        <div className="flex flex-col sm:flex-row">
                            <PageLayout page={page} />
                            <div className="w-full h-1 sm:h-[35em] sm:w-1 bg-[#0000001F] dark:bg-[#FFFFFF1F] rounded-sm" />
                            <EntryInspector pages={totalPages} />
                        </div>
                    </ReactFlowProvider>
                </TabItem>
            ))}
        </Tabs>
    );
}
