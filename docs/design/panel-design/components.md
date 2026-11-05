# Components

Each job has one component. Where two exist today, the table names the one that stays. Every component has a
Widgetbook story showing its states (PA-01), uses tokens only, and follows [keyboard.md](keyboard.md).

| Job | Use | Retire |
| --- | --- | --- |
| Button with a busy state | `LoadingButton`, `LoadingIconButton` | Their three private spinners |
| Waiting | Caret and `Shimmer` | `CircularProgressIndicator` as a general wait |
| Menu or popover | `AnchoredPopup`, `ContextMenuRegion` | Raw `PopupMenuButton`, `MenuAnchor` |
| Select | `Dropdown`, `MultiselectDropdown` | Raw `DropdownButtonFormField` |
| Dialog | One dialog component | Raw `AlertDialog` at 11 sites |
| Permanent action | A hold to confirm component (new) | `showConfirmationDialogue` with its Shift bypass |
| Undo | An undo notice (new) | Confirmation on recoverable actions |
| Message | Snackbar helpers | Raw `ScaffoldMessenger` |
| Empty | One component with a playful line and a key | `EmptyState` and `EmptyScreen` as two |
| Headings | `PageHeading`, `SectionTitle`, at theme sizes | Their local size and weight overrides |
| Icon | One bundled set | `Icones` runtime fetching; five other sets |
| Status | `StatusIndicator` and one chip | `TypeBadge`, `SmallChip`, `PresetChip` as separate styles |
| Pane | `Pane`, gaining the active lift | Ad hoc pane colours |

## State matrix

| Component kind | Hover | Focus | Active | Disabled | Busy |
| --- | --- | --- | --- | --- | --- |
| Filled button | Lighter fill, at once | Ring | Carriage press | Muted fill and text, no press | Caret replaces icon; label stays |
| Quiet button | Faint fill | Ring | Carriage press | Muted text | Same |
| Row | Faint fill, at once | Ring | Selected fill stays beneath the ring | Muted text | Same as content loading |
| Field | Border lightens | Ring, Insert mode | Caret | Muted, no caret | Value stays |

### CM-01 MUST: Selected and focused look different, and can combine

Selection is a fill, and focus is the ring. A row can show both.

- Why: keyboard users need to see both at once.
- Check: `visual-llm`.
- Broken: severity 3.
- Don't: the Selected chip reading weaker than the Disabled one.

### CM-02 MUST: Every icon button has a label

- Why: without one, it has no tooltip and no name for assistive technology.
- Check: `semantics`.
- Broken: severity 3.
