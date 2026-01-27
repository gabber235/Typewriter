# Badge System

Simple badge system for documentation pages. Supports three variants: `new`, `experimental`, and `deprecated`.

## Usage in Frontmatter

```markdown
---
title: My Page
badge: new
---
```

```markdown
---
title: Experimental Feature
badge: experimental
---
```

```markdown
---
title: Old API
badge: deprecated
---
```

## Available Variants

| Variant | Text | Color |
|---------|------|-------|
| `new` | New | Indigo |
| `experimental` | Experimental | Amber |
| `deprecated` | Deprecated | Red |

## Files

- `types.ts` - Badge variants and Zod schema
- `styles.ts` - Badge configuration and CSS classes
- `processor.ts` - Sidebar badge processing logic
- `index.ts` - Re-exports

## Importing

```typescript
import { badgeSchema, getBadge, getBadgeClasses, processSidebarBadges } from '../components/badge';
import type { Badge, BadgeVariant } from '../components/badge';
```
