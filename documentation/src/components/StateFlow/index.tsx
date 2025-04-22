import React, { useState, useEffect, useRef, useMemo } from "react";
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
  transitionLabel: string | null;
  direction: "up" | "down";
  onClick?: () => void;
  isActive?: boolean;
  isAnimating?: boolean;
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

  // Track the description visibility with a state
  const [descriptionVisible, setDescriptionVisible] = React.useState(isActive);

  // Update description visibility when isActive changes
  React.useEffect(() => {
    let timer: NodeJS.Timeout;

    if (isActive) {
      timer = setTimeout(() => {
        setDescriptionVisible(true);
      }, 100);
    } else {
      // Delay hiding the description to allow for animation
      timer = setTimeout(() => {
        setDescriptionVisible(false);
      }, 0); // Match this to the CSS transition duration
    }

    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [isActive]);

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
      <div className="flex items-center justify-between w-full mb-1">
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

        {!isActive && node.description && (
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

      {/* Animated description when node is active or animating out */}
      <div
        className={clsx(
          "overflow-hidden transition-all duration-300 ease-out",
          "mb-2 text-xs",
          descriptionVisible ? "max-h-24 opacity-100" : "max-h-0 opacity-0"
        )}
      >
        {descriptionVisible && node.description && (
          <div
            style={{
              transform: isActive ? "translateY(0)" : "translateY(100%)",
              transition: isActive
                ? "transform 0.4s cubic-bezier(0.16, 1, 0.3, 1)"
                : "none", // No transition when hiding
              opacity: isActive ? 1 : 0,
            }}
            className={clsx(
              "text-xs py-1 px-2 mb-3 rounded-md",
              "bg-slate-400 bg-opacity-10 dark:bg-black dark:bg-opacity-50"
            )}
          >
            <div className="flex items-start">
              <Icon
                icon="heroicons:information-circle"
                className="mr-1 mt-0.5 flex-shrink-0"
                width={12}
                height={12}
                aria-hidden="true"
              />
              <span>{node.description}</span>
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
  transitionLabel,
  direction,
  onClick,
  isActive = false,
  isAnimating = false,
}: StateArrowProps) {
  const containerClasses = clsx(
    "flex items-center justify-center py-3 h-20",
    onClick && "cursor-pointer group"
  );

  const lineClasses = clsx(
    "transition-all duration-500 w-[3px] rounded-full", // Slightly thicker line
    isActive
      ? "bg-[--ifm-color-primary] dark:bg-[--ifm-color-primary-lighter]"
      : "bg-gray-300 dark:bg-gray-600"
  );

  const arrowIcon =
    direction === "up" ? "ph:arrow-up-bold" : "ph:arrow-down-bold";

  return (
    <div
      className={containerClasses}
      onClick={onClick}
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      <div className="relative flex items-center justify-center w-[3px] h-full">
        {/* Line */}
        <div className={`h-full ${lineClasses}`}></div>

        {/* Arrow Head Circle */}
        <div
          className={clsx(
            "absolute flex items-center justify-center rounded-full top-1/2 -translate-y-1/2",
            "w-6 h-6 bg-white dark:bg-gray-800 border-2", // Adjusted size and border
            isActive
              ? "border-[--ifm-color-primary] text-[--ifm-color-primary]"
              : "border-gray-300 text-gray-400 dark:border-gray-600 dark:text-gray-500",
            "transition-all duration-300 ease-in-out",
            isAnimating ? "scale-110 shadow-md" : "group-hover:scale-105"
          )}
        >
          <Icon icon={arrowIcon} width={14} height={14} aria-hidden="true" />
        </div>

        {/* Transition Label (only shown when animating) */}
        {isAnimating && transitionLabel && (
          <div
            className={clsx(
              "absolute text-xs px-2 py-1 min-w-max z-10",
              "bg-gray-700 dark:bg-gray-900 text-white rounded-md shadow-lg",
              "transition-opacity duration-200 ease-in-out",
              // Position label to the side, adjusting based on direction maybe?
              // For now, consistently to the right
              "left-full ml-3",
              "opacity-100" // Always visible when animating
            )}
          >
            {transitionLabel}
          </div>
        )}
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
  maxHeight?: number; // Optional custom max height
}

export default function StateFlow({
  nodes,
  initialActiveId,
  expandable = true,
  title,
  description,
  className,
  maxHeight,
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
  const [animatingDirection, setAnimatingDirection] = useState<
    "up" | "down" | null
  >(null);
  const [animatingLabel, setAnimatingLabel] = useState<string | null>(null);
  const [isPaused, setIsPaused] = useState<boolean>(false);

  const animationTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const stepTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Helper to clear existing animation timeouts
  const clearAnimationTimeouts = () => {
    if (animationTimeoutRef.current) clearTimeout(animationTimeoutRef.current);
    if (stepTimeoutRef.current) clearTimeout(stepTimeoutRef.current);
    animationTimeoutRef.current = null;
    stepTimeoutRef.current = null;
  };

  // Helper to find a transition between two nodes
  const findTransition = (
    sourceId: string,
    targetId: string
  ): StateTransition | undefined => {
    const sourceNode = nodes.find((n) => n.id === sourceId);
    return sourceNode?.transitions?.find((t) => t.targetId === targetId);
  };

  // --- Automatic Animation Effect ---
  useEffect(() => {
    if (!nodes || nodes.length <= 1 || isPaused) return;

    const interval = setInterval(() => {
      clearAnimationTimeouts(); // Clear any pending manual animations
      const currentNode = nodes.find((node) => node.id === activeNodeId);

      if (
        !currentNode ||
        !currentNode.transitions ||
        currentNode.transitions.length === 0
      ) {
        // Fallback: sequential navigation if no transitions defined
        const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
        const nextIndex = (currentIndex + 1) % nodes.length;
        const nextNodeId = nodes[nextIndex].id;
        const direction: "up" | "down" =
          nextIndex > currentIndex ? "down" : "up";
        const arrowIndex = direction === "down" ? currentIndex : nextIndex;

        // Double speed for downward transitions
        const animationSpeed = direction === "down" ? 350 : 700;

        setAnimatingNodeId(nextNodeId);
        setAnimatingArrowIndex(arrowIndex);
        setAnimatingDirection(direction);
        setAnimatingLabel(null);

        animationTimeoutRef.current = setTimeout(() => {
          setActiveNodeId(nextNodeId);
          setExpandedNodeId(expandable ? nextNodeId : null);
          animationTimeoutRef.current = setTimeout(() => {
            setAnimatingNodeId(null);
            setAnimatingArrowIndex(null);
            setAnimatingDirection(null);
            setAnimatingLabel(null);
          }, animationSpeed);
        }, 50);

        return;
      }

      // Use defined transitions with directional speed differences
      const randomTransition =
        currentNode.transitions[
          Math.floor(Math.random() * currentNode.transitions.length)
        ];
      const nextNodeId = randomTransition.targetId;
      const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
      const targetIndex = nodes.findIndex((n) => n.id === nextNodeId);

      if (targetIndex === -1) return; // Target node not found

      const direction: "up" | "down" =
        targetIndex > currentIndex ? "down" : "up";
      const arrowIndex = direction === "down" ? currentIndex : targetIndex;

      // Double speed for downward transitions
      const animationSpeed = direction === "down" ? 350 : 700;

      setAnimatingNodeId(nextNodeId);
      setAnimatingArrowIndex(arrowIndex);
      setAnimatingDirection(direction);
      setAnimatingLabel(randomTransition.label);

      animationTimeoutRef.current = setTimeout(() => {
        setActiveNodeId(nextNodeId);
        setExpandedNodeId(expandable ? nextNodeId : null);
        animationTimeoutRef.current = setTimeout(() => {
          setAnimatingNodeId(null);
          setAnimatingArrowIndex(null);
          setAnimatingDirection(null);
          setAnimatingLabel(null);
        }, animationSpeed);
      }, 50);
    }, 2000); // Faster interval between transitions

    return () => {
      clearInterval(interval);
      clearAnimationTimeouts();
    };
  }, [activeNodeId, nodes, expandable, isPaused]);

  // --- Manual Click Handler ---
  const handleNodeClick = (nodeId: string) => {
    if (nodeId === activeNodeId) {
      if (expandable) {
        setExpandedNodeId(expandedNodeId === nodeId ? null : nodeId);
      }
      return;
    }

    clearAnimationTimeouts(); // Clear auto animation and any previous click animation

    const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
    const targetIndex = nodes.findIndex((n) => n.id === nodeId);

    if (currentIndex === -1 || targetIndex === -1) return; // Should not happen

    const stepDifference = Math.abs(currentIndex - targetIndex);
    const isMultiStep = stepDifference > 1;
    const isForward = targetIndex > currentIndex;

    const singleStepDuration = 1000; // Slower for single step
    const multiStepDurationPerStep = 400; // Faster per step for multi-step

    if (!isMultiStep) {
      // Single Step Animation
      const direction: "up" | "down" = isForward ? "down" : "up";
      const arrowIndex = isForward ? currentIndex : targetIndex;
      const transition = findTransition(activeNodeId, nodeId);

      setAnimatingNodeId(nodeId);
      setAnimatingArrowIndex(arrowIndex);
      setAnimatingDirection(direction);
      setAnimatingLabel(transition?.label || null);

      animationTimeoutRef.current = setTimeout(() => {
        setActiveNodeId(nodeId);
        setExpandedNodeId(expandable ? nodeId : null);
        animationTimeoutRef.current = setTimeout(() => {
          setAnimatingNodeId(null);
          setAnimatingArrowIndex(null);
          setAnimatingDirection(null);
          setAnimatingLabel(null);
        }, singleStepDuration);
      }, 100);
    } else {
      // Multi-Step Animation
      const sequentialActivation = (stepIndex: number) => {
        const currentStepNodeId = nodes[stepIndex].id;
        const nextStepIndex = isForward ? stepIndex + 1 : stepIndex - 1;
        const nextStepNodeId = nodes[nextStepIndex].id;

        const direction: "up" | "down" = isForward ? "down" : "up";
        const arrowIndex = isForward ? stepIndex : nextStepIndex;
        const transition = findTransition(currentStepNodeId, nextStepNodeId);

        // Animate this step
        setAnimatingNodeId(nextStepNodeId); // Highlight the node we are moving *to*
        setAnimatingArrowIndex(arrowIndex); // Highlight the arrow being traversed
        setAnimatingDirection(direction);
        setAnimatingLabel(transition?.label || null);
        setActiveNodeId(currentStepNodeId); // Update active node visually *during* step
        setExpandedNodeId(null); // Collapse during multi-step animation

        stepTimeoutRef.current = setTimeout(() => {
          if (nextStepIndex === targetIndex) {
            // Last step completed
            setActiveNodeId(nextStepNodeId);
            setExpandedNodeId(expandable ? nextStepNodeId : null);
            // Final reveal timeout
            animationTimeoutRef.current = setTimeout(() => {
              setAnimatingNodeId(null);
              setAnimatingArrowIndex(null);
              setAnimatingDirection(null);
              setAnimatingLabel(null);
            }, multiStepDurationPerStep); // Use step duration for final pause
          } else {
            // Move to the next step
            sequentialActivation(nextStepIndex);
          }
        }, multiStepDurationPerStep); // Duration for this step
      };

      // Start the sequence from the current index
      sequentialActivation(currentIndex);
    }
  };

  // --- Transition Button Click Handler ---
  const handleTransitionClick = (targetId: string) => {
    clearAnimationTimeouts(); // Clear auto animation

    const currentIndex = nodes.findIndex((n) => n.id === activeNodeId);
    const targetIndex = nodes.findIndex((n) => n.id === targetId);

    if (currentIndex === -1 || targetIndex === -1) return;

    const direction: "up" | "down" = targetIndex > currentIndex ? "down" : "up";
    const arrowIndex = direction === "down" ? currentIndex : targetIndex;
    const transition = findTransition(activeNodeId, targetId);
    const transitionDuration = 1000; // Slower for deliberate transition clicks

    setAnimatingNodeId(targetId);
    setAnimatingArrowIndex(arrowIndex);
    setAnimatingDirection(direction);
    setAnimatingLabel(transition?.label || null);

    animationTimeoutRef.current = setTimeout(() => {
      setActiveNodeId(targetId);
      setExpandedNodeId(expandable ? targetId : null);
      animationTimeoutRef.current = setTimeout(() => {
        setAnimatingNodeId(null);
        setAnimatingArrowIndex(null);
        setAnimatingDirection(null);
        setAnimatingLabel(null);
      }, transitionDuration);
    }, 100);
  };

  // Calculate container height to prevent layout shifts
  const containerHeight = useMemo(() => {
    if (maxHeight) return maxHeight;

    // Base calculation - each node has a base height plus arrow height
    const nodeBaseHeight = 150; // Base height for a collapsed node
    const arrowHeight = 80; // Height of arrow component
    const headerHeight = title || description ? 80 : 0; // Additional height for header section
    const padding = 40; // Extra padding for safety

    // Calculate total height based on number of nodes
    const calculatedHeight =
      nodeBaseHeight * nodes.length +
      arrowHeight * (nodes.length - 1) +
      headerHeight +
      padding;

    // Cap at reasonable maximum if it gets too large
    return Math.min(calculatedHeight, 2160);
  }, [nodes.length, title, description, maxHeight]);

  // --- Rendering Logic ---
  return (
    <div className={clsx("my-6 relative", className)}>
      {/* Container with fixed height to prevent layout shifts */}
      <div
        className="overscroll-contain"
        style={{
          height: `${containerHeight}px`,
          maxHeight: "120vh", // Prevent extremely tall components
        }}
      >
        {/* Pause/Play button */}
        <div className="absolute top-0 right-0 z-10">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setIsPaused(!isPaused);
            }}
            className={clsx(
              "p-2 rounded-full transition-colors duration-300",
              "text-gray-600 hover:text-[--ifm-color-primary]",
              "bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700",
              "border-none"
            )}
            title={isPaused ? "Resume animation" : "Pause animation"}
            aria-label={isPaused ? "Resume animation" : "Pause animation"}
          >
            <Icon
              icon={isPaused ? "ph:play-fill" : "ph:pause-fill"}
              width={18}
              height={18}
              aria-hidden="true"
            />
          </button>
        </div>

        {/* ... Title and Description ... */}
        {(title || description) && (
          <div className="mb-6 text-center">
            {" "}
            {/* Centered title/desc */}
            {title && (
              <h3 className="text-xl font-semibold m-0 mb-1">{title}</h3>
            )}
            {description && (
              <p className="text-sm text-gray-600 dark:text-gray-400 max-w-md mx-auto">
                {description}
              </p>
            )}
          </div>
        )}

        <div className="flex flex-col items-center space-y-0">
          {" "}
          {/* Remove default spacing */}
          {nodes.map((node, index) => {
            const isLast = index === nodes.length - 1;
            const isActive = node.id === activeNodeId;
            const isExpanded = node.id === expandedNodeId;
            const isAnimating = node.id === animatingNodeId;

            // Determine arrow properties for the arrow *below* this node
            let arrowDirection: "up" | "down" = "down";
            let arrowLabel: string | null = null;
            let isArrowAnimating = false;
            let isArrowActive = false;

            if (!isLast) {
              const nextNodeId = nodes[index + 1]?.id;
              // Check if the *current* animation involves the arrow between index and index+1
              if (animatingArrowIndex === index) {
                isArrowAnimating = true;
                arrowDirection = animatingDirection || "down"; // Use animating direction
                arrowLabel = animatingLabel;
                isArrowActive = true; // Arrow is active if animating
              } else {
                // Default state: arrow points down, check if adjacent nodes are active
                arrowDirection = "down";
                const forwardTransition = findTransition(node.id, nextNodeId);
                // Show label only if animating? Or maybe default forward label?
                // Let's hide label when not animating for now.
                arrowLabel = null;
                isArrowActive =
                  isActive || nodes[index + 1]?.id === activeNodeId;
              }
            }

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
                    direction={arrowDirection}
                    transitionLabel={arrowLabel}
                    isActive={isArrowActive}
                    isAnimating={isArrowAnimating}
                    onClick={() => handleNodeClick(nodes[index + 1]?.id)} // Click arrow goes to next node
                  />
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>
    </div>
  );
}
