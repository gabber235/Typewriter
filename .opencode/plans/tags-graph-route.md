# Tags Graph Route Plan

## Overview

Create a new Tags route under RealmRoute with a graph view for visualizing and managing tag hierarchies. Tags will be displayed in a top-to-bottom graph layout showing parent/child relationships, with an inspector for editing name. Tags are resizable on the graph.

## Part 1: Proto and Backend Changes

### 1.1 Update `proto/models/book.proto`

Add placement with coordinates and dimensions to Tag message:

```proto
message Tag {
  string id = 1;
  string name = 2;
  Color color = 3;
  repeated Tag parents = 4;
  Placement placement = 5;  // NEW: Position and size for graph
}

// NEW: Reusable placement message with position and dimensions
message Placement {
  int32 x = 1;
  int32 y = 2;
  int32 width = 3;
  int32 height = 4;
}
```

**Note**: The SurrealDB schema already has `placement` field defined for tags. We need to update it to include width/height.

### 1.2 Regenerate Proto

After proto changes:
- Run `task proto` in panel/ to regenerate Dart models
- Backend Rust code will auto-generate via build.rs

## Part 2: Routing and Navigation

### 2.1 Create Tags Route

**New file**: `panel/lib/routes/organization/tags/route.dart`

```dart
@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Inspector(
      child: Pane(
        title: "Tags",
        child: TagGraph(),
      ),
    );
  }
}
```

### 2.2 Register Route in `panel/lib/app_router.dart`

Add to RealmRoute children:

```dart
AutoRoute(
  page: RealmRoute.page,
  path: "realm/:realmId",
  children: [
    AutoRoute(page: LibraryRoute.page, path: "library", initial: true),
    AutoRoute(page: TagsRoute.page, path: "tags"),  // NEW
  ],
),
```

### 2.3 Add Sidebar Link in `panel/lib/routes/organization/route.dart`

Update `realmLinks` method to include Tags link.

## Part 3: Tag Logic Layer

### 3.1 Create Tags Provider

**New file**: `panel/lib/logic/tags.dart`

Methods:
- Fetch tags from the current book/realm
- createTag, updateTag, deleteTag
- moveTag(id, x, y) - update position
- resizeTag(id, width, height) - update dimensions

### 3.2 Create Tag Selectable

**New file**: `panel/lib/logic/tags/tag_selectable.dart`

- TagIdentifier extends SelectableIdentifier
- TagSelectable extends Selectable with name, objectBlueprint, operations

### 3.3 Create Tag Blueprint

For the inspector to edit tag properties:
- name: Text field for editing tag name

## Part 4: Tag Graph Widget

### 4.1 Create Tag Graph

**New file**: `panel/lib/widgets/app/components/graph/tag_graph.dart`

- Uses the Graph widget with GraphData
- Creates GraphElements from tags using placement (x, y, width, height)
- Creates GraphEdges from parent relationships (source: parent, target: child)
- Direction: GraphDirection.topToBottom
- Handles onElementsDragged and onElementsResize callbacks

### 4.2 Create Tag Node Widget

**New file**: `panel/lib/widgets/app/components/tag_node.dart`

- Wraps content in Selector for selection handling
- Shows tag name and color

### 4.3 Create Tag Graph Identifier

**New file**: `panel/lib/logic/graph/tag_graph_identifier.dart`

- TagGraphIdentifier extends GraphIdentifier

## Part 5: Tag Inspector Integration

### 5.1 Tag Header Widget

**New file**: `panel/lib/widgets/app/components/tags/tag_header.dart`

Shows tag color swatch and name in inspector header.

### 5.2 Tag Inspector Fields

Inspector renders fields based on TagSelectable.objectBlueprint:
- name: Text field for editing tag name

## Part 6: Create/Delete Tag Operations

### 6.1 Create Tag Action

Floating action button in TagGraph to create new tags with default placement.

### 6.2 Delete Tag Operation

TagSelectable includes DeleteSelectableOperation.

## Summary of Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `proto/models/book.proto` | MODIFY | Add Placement message (x, y, width, height) and placement field to Tag |
| `panel/lib/routes/organization/tags/route.dart` | CREATE | New TagsPage route |
| `panel/lib/app_router.dart` | MODIFY | Register TagsRoute under RealmRoute |
| `panel/lib/routes/organization/route.dart` | MODIFY | Add Tags sidebar link |
| `panel/lib/logic/tags.dart` | CREATE | Tags provider with CRUD + move/resize operations |
| `panel/lib/logic/tags/tag_selectable.dart` | CREATE | TagSelectable, TagIdentifier classes |
| `panel/lib/logic/graph/tag_graph_identifier.dart` | CREATE | TagGraphIdentifier for graph integration |
| `panel/lib/widgets/app/components/graph/tag_graph.dart` | CREATE | TagGraph widget with parent edges and resize support |
| `panel/lib/widgets/app/components/tag_node.dart` | CREATE | TagNode widget for graph |
| `panel/lib/widgets/app/components/tags/tag_header.dart` | CREATE | Tag inspector header |

## Implementation Order

1. Proto changes - Add Placement (x, y, width, height) to Tag, regenerate
2. Routing - Create TagsRoute, register in router, add sidebar link
3. Logic layer - Tags provider, TagSelectable, TagIdentifier
4. Graph layer - TagGraphIdentifier, TagGraph, TagNode
5. Inspector - TagHeader, blueprint for name field
6. Operations - Create/delete tag functionality

## Edge Cases and Considerations

1. **Multiple inheritance**: Tags can have multiple parents, so edges will be drawn from each parent to the tag
2. **Graph direction**: Top-to-bottom means parents are above children (source: bottom, target: top)
3. **Initial placement**: New tags get default position (0,0) and dimensions (4 cells wide, 1 cell tall)
4. **Resizing**: Uses the existing Graph resize mechanism via onElementsResize callback
5. **Tag cycles**: Need to prevent circular parent relationships (validation in backend)

## Implementation Notes

- Use proper riverpod.dart utils (e.g., AsyncValueWidget) instead of .when() pattern

---

## Part 7: Mocks and Widgetbook Stories

### 7.1 Update Tag Mock

**File**: `panel/testkit/lib/src/mocks/tag.mock.dart`

The existing file has `generateRandomTag` and `ensureRandomTag` functions but does not include the `placement` field. Add placement to the Tag generation:

```dart
Tag? generateRandomTag([double change = 1, double decrease = 0.6]) {
  if (change <= epsilon) return null;
  final r = random.decimal();
  if (r > change) return null;
  final parents = <Tag>[];
  while (true) {
    final parent = generateRandomTag(change * decrease, decrease);
    if (parent == null) break;
    parents.add(parent);
  }
  return Tag(
    id: faker.guid.guid(),
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomElement().toProtoColor(),
    parents: parents,
    placement: Placement(
      x: random.integer(20),
      y: random.integer(10),
      width: random.integer(6, min: 2),
      height: random.integer(3, min: 1),
    ),
  );
}
```

Add the TagsMock class and provider overrides (following the ServicesMock pattern in `services.mock.dart`):

```dart
class TagsMock extends Tags {
  TagsMock({required this.displayState});
  final DisplayState displayState;

  @override
  Stream<List<Tag>> build() async* {
    yield await displayState.generate(ensureRandomTag);
  }

  @override
  Future<Tag?> createTag({...}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    final newTag = ensureRandomTag();
    state = AsyncData([...tags, newTag]);
    return newTag;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    state = AsyncData(tags.map((t) => t.id == tag.id ? tag : t).toList());
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    state = AsyncData(tags.where((t) => t.id != tagId).toList());
  }

  @override
  Future<void> moveTag(String tagId, int x, int y) async {
    // No-op for mock
  }

  @override
  Future<void> resizeTag(String tagId, int width, int height) async {
    // No-op for mock
  }
}

List<Override> tagsProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [tagsProvider.overrideWith(() => TagsMock(displayState: state))];
```

### 7.2 Create TagNode Story

**New file**: `panel/widgetbook/lib/stories/app/components/tags/tag_node.stories.dart`

```dart
import "package:flutter/material.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/app/components/tags/tag_node.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

@widgetbook.UseCase(name: "Default", type: TagNode)
Widget tagNodeDefault(BuildContext context) {
  final tag = ensureRandomTag();
  return FakeApp(
    overrides: [
      ...tagsProviderOverrides(state: DisplayState.fewItems),
    ],
    child: Center(
      child: SizedBox(
        width: 200,
        height: 50,
        child: TagNode(tagId: tag.id),
      ),
    ),
  );
}
```

### 7.3 Create TagGraph Story

**New file**: `panel/widgetbook/lib/stories/app/components/graph/tag_graph.stories.dart`

```dart
import "package:flutter/material.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/app/components/graph/tag_graph.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

@widgetbook.UseCase(name: "Default", type: TagGraph)
Widget tagGraphDefault(BuildContext context) {
  final displayState = context.knobs.displayState();
  return FakeApp(
    overrides: [
      ...realmProviderOverrides(),
      ...tagsProviderOverrides(state: displayState),
    ],
    child: const TagGraph(),
  );
}
```

### 7.4 Create TagsPage Route Story

**New file**: `panel/widgetbook/lib/stories/routes/organization/tags/route.stories.dart`

```dart
import "package:flutter/material.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/routes/organization/tags/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

@widgetbook.UseCase(name: "Default", type: TagsPage)
Widget tagsPageDefault(BuildContext context) {
  final displayState = context.knobs.displayState();
  return FakeApp(
    overrides: [
      ...realmProviderOverrides(),
      ...tagsProviderOverrides(state: displayState),
    ],
    child: const TagsPage(),
  );
}

@widgetbook.UseCase(name: "Empty", type: TagsPage)
Widget tagsPageEmpty(BuildContext context) {
  return FakeApp(
    overrides: [
      ...realmProviderOverrides(),
      ...tagsProviderOverrides(state: DisplayState.noItems),
    ],
    child: const TagsPage(),
  );
}
```

---

## Summary of Files to Create/Modify (Mocks and Widgetbook)

| File | Action | Description |
|------|--------|-------------|
| `panel/testkit/lib/src/mocks/tag.mock.dart` | MODIFY | Add placement to Tag generation, add TagsMock and tagsProviderOverrides |
| `panel/widgetbook/lib/stories/app/components/tags/tag_node.stories.dart` | CREATE | TagNode widgetbook story |
| `panel/widgetbook/lib/stories/app/components/graph/tag_graph.stories.dart` | CREATE | TagGraph widgetbook story |
| `panel/widgetbook/lib/stories/routes/organization/tags/route.stories.dart` | CREATE | TagsPage route widgetbook story |

## Implementation Order (Mocks and Widgetbook)

1. Update `tag.mock.dart` with placement field and TagsMock class
2. Create widgetbook story for TagNode
3. Create widgetbook story for TagGraph
4. Create widgetbook story for TagsPage route
5. Run widgetbook build to verify
