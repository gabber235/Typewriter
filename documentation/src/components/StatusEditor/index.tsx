import React, { useState, useEffect } from "react";
import clsx from "clsx";
import { Icon } from "@iconify/react";

type QuestStatus = "inactive" | "active" | "completed";

interface StatusEditorProps {
    defaultValue?: number;
    className?: string;
    compact?: boolean;
}

export default function StatusEditor({
    defaultValue = 0,
    className,
    compact = false,
}: StatusEditorProps): JSX.Element {
    const [value, setValue] = useState<number>(defaultValue);
    const [status, setStatus] = useState<QuestStatus>("inactive");

    useEffect(() => {

        let newStatus: QuestStatus = "inactive";
        if (value <= 0) {
            newStatus = "inactive";
        } else if (value === 5) {
            newStatus = "completed";
        } else {
            newStatus = "active";
        }

        setStatus(newStatus);

        const timer = setTimeout(() => {
        }, 300);

        return () => clearTimeout(timer);
    }, [value]);

    // Define status colors and icons
    const statusConfig = {
        inactive: {
            bg: "bg-gray-100 dark:bg-zinc-600",
            ring: "ring-[#1f2937] dark:ring-white",
            icon: "ph:circle-dot",
            label: "Inactive",
            description: "Quest is not yet started or is unavailable.",
            details: [
                "Waiting for activation trigger",
            ],
        },
        active: {
            bg: "bg-[#eef9fd] dark:bg-[#193c47]",
            ring: "ring-[#4cb3d4]",
            icon: "ph:search",
            label: "Active",
            description:
                "Quest is currently active and in progress. Quest will automatically be tracked to show up.",
            details: [
                "Players can track progress",
                "Objectives are displayed",
                "Players actions can progress the quest",
            ],
        },
        completed: {
            bg: "bg-[#e6f6e6] dark:bg-[#003100]",
            ring: "ring-[#009400]",
            icon: "ph:check-circle",
            label: "Completed",
            description:
                "Quest has been completed. Quest will automatically hide and get untracked.",
            details: [
                "Players won't see the quest anymore",
            ],
        },
    };

    // Define fact strings based on value
    const getFact = (val: number): string => {
        if (val <= 0) return `Permanent Fact = ${val} (Inactive)`;
        if (val === 5) return `Permanent Fact = ${val} (Complete)`;
        return `Permanent Fact = ${val}`;
    };

    const handleIncrement = () => {
        setValue((prev) => prev + 1);
    };

    const handleDecrement = () => {
        setValue((prev) => prev - 1);
    };

    const config = statusConfig[status];

    return (
        <div className={clsx("w-full my-4", className)}>
            <div className="flex flex-col items-stretch gap-3">
                <div
                    className={clsx(
                        "w-full flex flex-col",
                        compact ? "max-w-xs mx-auto" : ""
                    )}
                >
                    <div
                        className={clsx(
                            "flex-grow border rounded-md p-4 transition-all duration-300 flex flex-col h-[375px]",
                            "hover:shadow-md",
                            "ring-1",
                            config.bg,
                            config.ring,
                        )}
                    >
                        {/* Header section */}
                        <div className="flex items-center justify-between mb-3">
                            <div className="flex items-center">
                                <Icon
                                    icon={config.icon}
                                    className="mr-2 text-[--ifm-color-primary]"
                                    width={22}
                                    height={22}
                                />
                                <h4 className="m-0 text-sm font-bold">{config.label} Quest</h4>
                            </div>
                            <div className="px-2 py-0.5 rounded-full text-xs font-medium bg-black bg-opacity-5 dark:bg-white dark:bg-opacity-10">
                                State: {status}
                            </div>
                        </div>

                        {/* Content section */}
                        <div className="flex-grow flex flex-col">
                            <div className="text-xs flex items-center p-2 mb-2 rounded-md bg-slate-400 bg-opacity-10 dark:bg-black dark:bg-opacity-50 hover:bg-opacity-15 dark:hover:bg-opacity-60 transition-colors">
                                <div className="flex items-start">
                                    <span>{config.description}</span>
                                </div>
                            </div>

                            <div className="flex items-center text-xs py-1.5 px-2 my-1 rounded-md bg-slate-400 bg-opacity-10 dark:bg-black dark:bg-opacity-50 hover:bg-opacity-15 dark:hover:bg-opacity-60 transition-colors">
                                <Icon
                                    icon="ph:database-duotone"
                                    className="mr-1.5 text-[--ifm-color-primary] dark:text-[--ifm-color-primary-lighter]"
                                    width={14}
                                    height={14}
                                />
                                <code className="text-xs bg-transparent">{getFact(value)}</code>
                            </div>

                            <div className="mt-4">
                                <div className="text-xs uppercase font-bold opacity-70 mb-2">
                                    Status Details
                                </div>
                                <div className="space-y-2">
                                    {config.details.map((detail, index) => (
                                        <div
                                            key={index}
                                            className="flex items-center text-xs p-2 rounded-md bg-white bg-opacity-50 dark:bg-black dark:bg-opacity-30 hover:bg-opacity-70 dark:hover:bg-opacity-40 transition-colors"
                                        >
                                            <Icon
                                                icon="ph:check"
                                                className="mr-1.5 flex-shrink-0 text-[--ifm-color-primary]"
                                                width={14}
                                                height={14}
                                            />
                                            <span>{detail}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>

                        {/* Controls section - Now positioned at the bottom with mt-auto */}
                        <div className="flex items-center justify-between mt-auto pt-3 border-t border-gray-200 dark:border-gray-700">
                            <div className="flex items-center">
                                <button
                                    onClick={handleDecrement}
                                    className="p-2 bg-gray-200 dark:bg-gray-700 rounded-l-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                    aria-label="Decrease value"
                                >
                                    <Icon icon="ph:minus" />
                                </button>

                                <div className="flex items-center justify-center min-w-[80px] h-[34px] text-xs bg-black bg-opacity-5 dark:bg-white dark:bg-opacity-10 py-2 px-3">
                                    Value: {value}
                                </div>

                                <button
                                    onClick={handleIncrement}
                                    className="p-2 bg-gray-200 dark:bg-gray-700 rounded-r-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                    aria-label="Increase value"
                                >
                                    <Icon icon="ph:plus" />
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
