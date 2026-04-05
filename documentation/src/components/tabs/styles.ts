export const tabStyles = {
  container: "not-content my-6",

  bar: "inline-flex items-center gap-1 rounded-full p-1 bg-[var(--surface-container)]/50",

  pill: "absolute top-1 bottom-1 left-0 rounded-full bg-[rgba(var(--color-primary-rgb),0.12)] transition-[transform,width] duration-300 ease-[cubic-bezier(0.4,0,0.2,1)]",

  button:
    "relative z-10 px-4 py-1.5 rounded-full text-sm font-semibold cursor-pointer select-none transition-colors duration-200 bg-transparent border-none whitespace-nowrap",
  buttonActive: "text-primary",
  buttonInactive:
    "text-[var(--on-surface-variant)] hover:text-[var(--sl-color-white)]",

  panels: "relative mt-4 min-h-[2rem]",

  panel: "transition-[opacity,transform] duration-200 ease-[cubic-bezier(0.4,0,0.2,1)]",
  panelActive: "opacity-100 translate-y-0",
  panelHidden: "opacity-0 translate-y-1 absolute inset-0 pointer-events-none",
} as const;
