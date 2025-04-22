import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { useColorMode } from "@docusaurus/theme-common";
import clsx from "clsx";

// Define the structure of a state in the flow
export interface StateFlowNode {
  id: string;
  title: string;
  facts: string[];
  className?: string;
  description?: string;
  transitions?: StateTransition[];
  icon?: string;
}

export interface StateTransition {
  targetId: string;
  label: string;
  icon?: string;
  description?: string;
}

interface StateNodeProps {
  node: StateFlowNode;
  isActive: boolean;
  isExpanded: boolean;
  onClick: () => void;
  onTransitionClick: (targetId: string) => void;
  animating?: boolean;
}

interface StateArrowProps {
  label: string;
  icon?: string;
  onClick?: () => void;
  isActive?: boolean;
  animating?: boolean;
}

function StateNode({
  node,
  isActive,
  isExpanded,
  onClick,
  onTransitionClick,
  animating = false,
}: StateNodeProps) {
  // Calculate dynamic styles based on JetBrains Mono and your custom colors
  const baseClasses = clsx(
    "border rounded-md transition-all duration-300 ease-in-out p-3",
    "hover:shadow-sm",
    "cursor-pointer"
  );

  // Dynamic active state styling
  const activeClasses = isActive
    ? "ring-1 ring-opacity-100"
    : "ring-1 ring-opacity-50";

  // Fixed width for consistent sizing
  const nodeWidth = "w-[250px]";

  // Use fixed height for unexpanded nodes to keep consistent sizing
  const nodeHeight = !isExpanded ? "min-h-[120px]" : "";

  const expandedClasses = isExpanded ? "w-[300px] z-10" : nodeWidth;

  const nodeIcon = node.icon || "ph:cube-duotone";

  return (
    <div
      className={clsx(
        baseClasses,
        activeClasses,
        expandedClasses,
        nodeHeight,
        node.className, // This will allow custom styling from MDX
        "transform transition-all duration-300",
        animating ? "scale-[1.01]" : "hover:scale-[1.01]" // Minimal scale effect
      )}
      onClick={onClick}
      role="button"
      tabIndex={0}
      aria-expanded={isExpanded}
    >
      <div className="flex items-center justify-between w-full mb-2">
        <div className="flex items-center">
          <Icon
            icon={nodeIcon}
            className={clsx(
              "mr-2 transition-all duration-500",
              isActive
                ? "text-[--ifm-color-primary] scale-110"
                : "text-gray-500 dark:text-gray-400"
            )}
            width={22}
            height={22}
          />
          <h4 className="m-0 text-sm font-bold">{node.title}</h4>
        </div>

        {node.description && (
          <div
            className="tooltip-container cursor-help relative group"
            title={node.description}
          >
            <Icon
              icon="heroicons:information-circle"
              className="text-gray-400 hover:text-[--ifm-color-primary] transition-colors duration-300"
              width={18}
              height={18}
              aria-hidden="true"
            />
            <div className="absolute right-0 -top-2 transform translate-y-[-100%] w-48 p-2 bg-white dark:bg-gray-800 rounded-md shadow-lg border border-gray-200 dark:border-gray-700 text-xs opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-300 z-20">
              {node.description}
            </div>
          </div>
        )}
      </div>

      <div className="w-full">
        {node.facts.map((fact, index) => (
          <div
            key={index}
            className={clsx(
              "flex items-center text-xs py-1.5 px-2 my-1 rounded-md",
              "bg-slate-400 bg-opacity-10 dark:bg-black dark:bg-opacity-50",
              "transition-all duration-300",
              "hover:bg-opacity-20 dark:hover:bg-opacity-65"
            )}
          >
            <Icon
              icon="ph:database-duotone"
              className="mr-1.5 text-[--ifm-color-primary] dark:text-[--ifm-color-primary-lighter]"
              width={14}
              height={14}
              aria-hidden="true"
            />
            <code className="text-xs bg-transparent">{fact}</code>
          </div>
        ))}
      </div>

      {isExpanded && node.transitions && node.transitions.length > 0 && (
        <div className="mt-3 pt-2 border-t border-gray-200 dark:border-gray-600 w-full">
          <div className="text-xs uppercase font-bold opacity-70 mb-2">
            Transitions
          </div>
          <div className="flex flex-wrap gap-1.5">
            {node.transitions.map((transition, index) => (
              <button
                key={index}
                className={clsx(
                  "flex items-center text-xs px-2 py-1 rounded-md",
                  "bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700",
                  "text-gray-800 dark:text-gray-200",
                  "hover:bg-gray-200 dark:hover:bg-gray-700",
                  "transition-colors duration-200"
                )}
                onClick={(e) => {
                  e.stopPropagation();
                  onTransitionClick(transition.targetId);
                }}
                title={transition.description}
              >
                <Icon
                  icon={transition.icon || "ph:arrow-right-bold"}
                  className="mr-1.5 text-[--ifm-color-primary]"
                  width={12}
                  height={12}
                  aria-hidden="true"
                />
                {transition.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function StateArrow({
  label,
  icon = "ph:arrow-down-bold",
  onClick,
  isActive = false,
  animating = false,
}: StateArrowProps) {
  const containerClasses = clsx(
    "flex items-center justify-center py-3 h-20",
    onClick && "cursor-pointer group"
  );

  const lineClasses = clsx(
    "transition-all duration-500",
    isActive
      ? "bg-[--ifm-color-primary] dark:bg-[--ifm-color-primary-lighter]"
      : "bg-gray-400 dark:bg-gray-600"
  );

  return (
    <div
      className={containerClasses}
      onClick={onClick}
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      <div className="relative flex items-center justify-center w-[2px] h-full">
        <div className={`h-full w-[2px] ${lineClasses}`}></div>

        {label && (
          <div
            className={clsx(
              "absolute flex items-center gap-1 text-xs px-2 py-1 min-w-max",
              "bg-white dark:bg-gray-800 rounded-md",
              "border border-gray-200 dark:border-gray-700 shadow-sm",
              "text-gray-800 dark:text-gray-200",
              "transition-opacity duration-300",
              "right-full mr-3",
              "opacity-0 group-hover:opacity-100",
              animating && "!opacity-100"
            )}
          >
            <Icon
              icon={icon}
              className="text-[--ifm-color-primary]"
              width={16}
              height={16}
              aria-hidden="true"
            />
            <span>{label}</span>
          </div>
        )}

        <div
          className={clsx(
            "absolute flex items-center justify-center rounded-full top-1/2 -translate-y-1/2",
            "w-7 h-7 bg-white dark:bg-gray-800 border",
            isActive
              ? "border-[--ifm-color-primary] text-[--ifm-color-primary]"
              : "border-gray-400 text-gray-400 dark:border-gray-600 dark:text-gray-500",
            "transition-all duration-300",
            animating ? "scale-105" : "group-hover:scale-105"
          )}
        >
          <Icon icon={icon} width={16} height={16} aria-hidden="true" />
        </div>
      </div>
    </div>
  );
}

export interface StateFlowProps {
  nodes: StateFlowNode[];
  initialActiveId?: string;
  expandable?: boolean;
  title?: string;
  description?: string;
  className?: string;
}

export default function StateFlow({
  nodes,
  initialActiveId,
  expandable = true,
  title,
  description,
  className,
}: StateFlowProps) {
  const [activeNodeId, setActiveNodeId] = useState<string>(
    initialActiveId || nodes[0]?.id || ""
  );
  const [expandedNodeId, setExpandedNodeId] = useState<string | null>(
    initialActiveId || nodes[0]?.id || null
  );
  const [animatingNodeId, setAnimatingNodeId] = useState<string | null>(null);
  const [animatingArrowIndex, setAnimatingArrowIndex] = useState<number | null>(
    null
  );

  useEffect(() => {
    if (!nodes || nodes.length <= 1) return;

    const interval = setInterval(() => {
      const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
      const nextIndex = (currentIndex + 1) % nodes.length;
      const nextNodeId = nodes[nextIndex].id;

      setAnimatingNodeId(nextNodeId);
      setAnimatingArrowIndex(currentIndex);

      setTimeout(() => {
        setActiveNodeId(nextNodeId);
        setExpandedNodeId(nextNodeId);

        setTimeout(() => {
          setAnimatingNodeId(null);
          setAnimatingArrowIndex(null);
        }, 4000);
      }, 100);
    }, 4000);

    return () => clearInterval(interval);
  }, [activeNodeId, nodes]);

  const handleNodeClick = (nodeId: string) => {
    if (nodeId === activeNodeId) {
      if (expandable) {
        setExpandedNodeId(expandedNodeId === nodeId ? null : nodeId);
      }
      return;
    }

    const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
    const targetIndex = nodes.findIndex((n) => n.id === nodeId);

    if (Math.abs(currentIndex - targetIndex) > 1) {
      const isForward = targetIndex > currentIndex;
      const sequentialActivation = (index) => {
        if (isForward && index > targetIndex) return;
        if (!isForward && index < targetIndex) return;

        const intermediateNodeId = nodes[index].id;

        setAnimatingNodeId(intermediateNodeId);
        setAnimatingArrowIndex(isForward ? index - 1 : index);

        setTimeout(() => {
          if (index !== targetIndex) {
            sequentialActivation(isForward ? index + 1 : index - 1);
          } else {
            setActiveNodeId(nodeId);
            if (expandable) {
              setExpandedNodeId(nodeId);
            }
          }

          setTimeout(
            () => {
              setAnimatingNodeId(null);
              setAnimatingArrowIndex(null);
            },
            index === targetIndex ? 1500 : 200
          );
        }, 150);
      };

      sequentialActivation(isForward ? currentIndex + 1 : currentIndex - 1);
      return;
    }

    setAnimatingNodeId(nodeId);
    if (Math.abs(currentIndex - targetIndex) === 1) {
      setAnimatingArrowIndex(Math.min(currentIndex, targetIndex));
    }

    setTimeout(() => {
      setActiveNodeId(nodeId);
      if (expandable) {
        setExpandedNodeId(nodeId);
      }

      setTimeout(() => {
        setAnimatingNodeId(null);
        setAnimatingArrowIndex(null);
      }, 1500);
    }, 100);
  };

  const handleTransitionClick = (targetId: string) => {
    const targetIndex = nodes.findIndex((n) => n.id === targetId);

    setAnimatingNodeId(targetId);

    const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
    if (currentIndex !== -1 && Math.abs(currentIndex - targetIndex) === 1) {
      setAnimatingArrowIndex(Math.min(currentIndex, targetIndex));
    }

    setTimeout(() => {
      setActiveNodeId(targetId);
      if (expandable) {
        setExpandedNodeId(targetId);
      }

      setTimeout(() => {
        setAnimatingNodeId(null);
        setAnimatingArrowIndex(null);
      }, 4500);
    }, 100);
  };

  return (
    <div className={clsx("my-6", className)}>
      {(title || description) && (
        <div className="mb-4">
          {title && <h3 className="text-lg font-bold m-0">{title}</h3>}
          {description && (
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-0">
              {description}
            </p>
          )}
        </div>
      )}

      <div className="flex flex-col items-center">
        {nodes.map((node, index) => {
          const isLast = index === nodes.length - 1;
          const isActive = node.id === activeNodeId;
          const isExpanded = node.id === expandedNodeId;
          const isAnimating = node.id === animatingNodeId;

          const nextNodeTransition = node.transitions?.find(
            (t) => t.targetId === nodes[index + 1]?.id
          );

          return (
            <React.Fragment key={node.id}>
              <StateNode
                node={node}
                isActive={isActive}
                isExpanded={isExpanded}
                onClick={() => handleNodeClick(node.id)}
                onTransitionClick={handleTransitionClick}
                animating={isAnimating}
              />

              {!isLast && (
                <StateArrow
                  label={nextNodeTransition?.label || ""}
                  icon={nextNodeTransition?.icon || "ph:arrow-down-bold"}
                  isActive={isActive || nodes[index + 1]?.id === activeNodeId}
                  animating={animatingArrowIndex === index}
                  onClick={() => handleNodeClick(nodes[index + 1]?.id)}
                />
              )}
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}
