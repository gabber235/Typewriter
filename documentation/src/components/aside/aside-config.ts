export type AsideVariant = 'info' | 'warning' | 'danger' | 'success' | 'tip' | 'note' | 'example' | 'experimental' | 'deprecated' | 'bug' | 'performance';

export const variants = new Set<string>(['info', 'warning', 'danger', 'success', 'tip', 'note', 'example', 'experimental', 'deprecated', 'bug', 'performance']);
export const isAsideVariant = (s: string): s is AsideVariant => variants.has(s);

export const defaultTitles: Record<AsideVariant, string> = {
  info: 'Info',
  warning: 'Warning',
  danger: 'Danger',
  success: 'Success',
  tip: 'Tip',
  note: 'Note',
  example: 'Example',
  experimental: 'Experimental',
  deprecated: 'Deprecated',
  bug: 'Known Issue',
  performance: 'Performance',
};

// Icons for each variant
export const icons: Record<AsideVariant, string> = {
  info: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>`,
  warning: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 256 256" fill="currentColor"><path d="M236.8,188.09,149.35,36.22h0a24.76,24.76,0,0,0-42.7,0L19.2,188.09a23.51,23.51,0,0,0,0,23.72A24.35,24.35,0,0,0,40.55,224h174.9a24.35,24.35,0,0,0,21.33-12.19A23.51,23.51,0,0,0,236.8,188.09ZM120,104a8,8,0,0,1,16,0v40a8,8,0,0,1-16,0Zm8,88a12,12,0,1,1,12-12A12,12,0,0,1,128,192Z"/></svg>`,
  danger: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 256 256" fill="currentColor"><path d="M227.31,80.24,175.76,28.69A16.13,16.13,0,0,0,164.45,24H91.55a16.13,16.13,0,0,0-11.31,4.69L28.69,80.24A16.13,16.13,0,0,0,24,91.55v72.9a16.13,16.13,0,0,0,4.69,11.31l51.55,51.55A16.13,16.13,0,0,0,91.55,232h72.9a16.13,16.13,0,0,0,11.31-4.69l51.55-51.55A16.13,16.13,0,0,0,232,164.45V91.55A16.13,16.13,0,0,0,227.31,80.24ZM120,80a8,8,0,0,1,16,0v56a8,8,0,0,1-16,0Zm8,104a12,12,0,1,1,12-12A12,12,0,0,1,128,184Z"/></svg>`,
  success: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>`,
  tip: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M9 21c0 .5.4 1 1 1h4c.6 0 1-.5 1-1v-1H9v1zm3-19C8.1 2 5 5.1 5 9c0 2.4 1.2 4.5 3 5.7V17c0 .5.4 1 1 1h6c.6 0 1-.5 1-1v-2.3c1.8-1.3 3-3.4 3-5.7 0-3.9-3.1-7-7-7z"/></svg>`,
  note: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M19 3H4.99c-1.11 0-1.98.89-1.98 2L3 19c0 1.1.88 2 1.99 2H19c1.1 0 2-.9 2-2V5c0-1.11-.9-2-2-2zm0 12h-4c0 1.66-1.35 3-3 3s-3-1.34-3-3H4.99V5H19v10z"/></svg>`,
  example: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M9.4 16.6L4.8 12l4.6-4.6L8 6l-6 6 6 6 1.4-1.4zm5.2 0l4.6-4.6-4.6-4.6L16 6l6 6-6 6-1.4-1.4z"/></svg>`,
  experimental: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M19.8 18.4L14 10.67V6.5l1.35-1.69c.26-.33.03-.81-.39-.81H9.04c-.42 0-.65.48-.39.81L10 6.5v4.17L4.2 18.4c-.49.66-.02 1.6.8 1.6h14c.82 0 1.29-.94.8-1.6z"/></svg>`,
  deprecated: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm4.2 14.2L11 13V7h1.5v5.2l4.5 2.7-.8 1.3z"/></svg>`,
  bug: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M20 8h-2.81c-.45-.78-1.07-1.45-1.82-1.96L17 4.41 15.59 3l-2.17 2.17C12.96 5.06 12.49 5 12 5c-.49 0-.96.06-1.41.17L8.41 3 7 4.41l1.62 1.63C7.88 6.55 7.26 7.22 6.81 8H4v2h2.09c-.05.33-.09.66-.09 1v1H4v2h2v1c0 .34.04.67.09 1H4v2h2.81c1.04 1.79 2.97 3 5.19 3s4.15-1.21 5.19-3H20v-2h-2.09c.05-.33.09-.66.09-1v-1h2v-2h-2v-1c0-.34-.04-.67-.09-1H20V8zm-6 8h-4v-2h4v2zm0-4h-4v-2h4v2z"/></svg>`,
  performance: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M11 21h-1l1-7H7.5c-.58 0-.57-.32-.38-.66.19-.34.05-.08.07-.12C8.48 10.94 10.42 7.54 13 3h1l-1 7h3.5c.49 0 .56.33.47.51l-.07.15C12.96 17.55 11 21 11 21z"/></svg>`,
};

// Using Material Design colors from colors.css
export const variantStyles: Record<AsideVariant, { border: string; bg: string; text: string }> = {
  info: {
    border: 'border-[var(--material-blue-500)]',
    bg: 'bg-[var(--material-blue-500)]/10',
    text: 'text-[var(--material-blue-500)]',
  },
  warning: {
    border: 'border-[var(--material-orange-500)]',
    bg: 'bg-[var(--material-orange-500)]/10',
    text: 'text-[var(--material-orange-500)]',
  },
  danger: {
    border: 'border-[var(--material-red-500)]',
    bg: 'bg-[var(--material-red-500)]/10',
    text: 'text-[var(--material-red-500)]',
  },
  success: {
    border: 'border-[var(--material-green-500)]',
    bg: 'bg-[var(--material-green-500)]/10',
    text: 'text-[var(--material-green-500)]',
  },
  tip: {
    border: 'border-[var(--material-cyan-500)]',
    bg: 'bg-[var(--material-cyan-500)]/10',
    text: 'text-[var(--material-cyan-500)]',
  },
  note: {
    border: 'border-[var(--material-blue-grey-500)]',
    bg: 'bg-[var(--material-blue-grey-500)]/10',
    text: 'text-[var(--material-blue-grey-500)]',
  },
  example: {
    border: 'border-[var(--material-purple-400)]',
    bg: 'bg-[var(--material-purple-400)]/10',
    text: 'text-[var(--material-purple-400)]',
  },
  experimental: {
    border: 'border-[var(--material-orange-700)]',
    bg: 'bg-[var(--material-orange-700)]/10',
    text: 'text-[var(--material-orange-700)]',
  },
  deprecated: {
    border: 'border-[var(--material-brown-200)]',
    bg: 'bg-[var(--material-brown-300)]/10',
    text: 'text-[var(--material-brown-200)]',
  },
  bug: {
    border: 'border-[var(--material-pink-500)]',
    bg: 'bg-[var(--material-pink-500)]/10',
    text: 'text-[var(--material-pink-500)]',
  },
  performance: {
    border: 'border-[var(--material-amber-500)]',
    bg: 'bg-[var(--material-amber-500)]/10',
    text: 'text-[var(--material-amber-500)]',
  },
};

// Shared class strings matching Flutter design (full border, rounded corners)
export const asideClasses = {
  container: 'my-4 rounded-lg border px-4 py-2.5',
  header: 'flex items-center gap-3',
  icon: 'flex-shrink-0',
  title: 'font-semibold',
  content: 'mt-2 [&>p]:my-0',
};
