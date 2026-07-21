import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Operation to create a connection between the selected entry and another entry.
class EntryLinkWithOperation extends ActivatorShortcutOperation {
  const EntryLinkWithOperation();

  @override
  String get name => "Link with...";

  @override
  String get description => "Create a connection to another entry";

  Color get color => Colors.blue;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final definitions = selection
        .whereType<EntrySelection>()
        .map((e) => e.definition)
        .toList();

    final hasLinkablePaths = _linkablePaths(definitions).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entrySelections = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement link flow:
    // 1) Use the new selector popup to pick a target entry.
    // 2) If multiple paths are possible, show the selector for a path.
    // 3) Persist the link to the backend and refresh state.
  }

  List<String> _linkablePaths(List<EntryDefinition> definitions) {
    if (definitions.isEmpty) return [];
    final wildPaths = definitions
        .map((e) => e.blueprint.fieldsWithModifier<EntryReferenceModifier>())
        .reduce((acc, map) {
          return acc.entries
              .where((e) => listEquals(e.value, map[e.key]))
              .toMap();
        })
        .keys
        .toList();

    if (wildPaths.isEmpty) return [];

    return wildPaths.expand((wildPath) {
      return definitions
          .map((e) => e.data.newPaths(wildPath))
          .reduce(
            (acc, paths) => acc.intersection(paths).toList(growable: false),
          );
    }).toList();
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.link),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => LoadingButton.filledIcon(
      icon: const Icones(Fa6Solid.link),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to link with a duplicate of the selected/target entry.
class EntryLinkWithDuplicateOperation extends ActivatorShortcutOperation {
  const EntryLinkWithDuplicateOperation();

  @override
  String get name => "Link with Duplicate";

  @override
  String get description =>
      "Create a connection and duplicate the target entry";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL, shift: true),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final definitions = selection
        .whereType<EntrySelection>()
        .map((e) => e.definition)
        .toList();

    final hasLinkablePaths = _linkableDuplicatePaths(definitions).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement link-with-duplicate flow:
    // 1) Pick target entry.
    // 2) Duplicate it.
    // 3) Link to the duplicate on the chosen path.
    // 4) Persist + refresh.
  }

  List<String> _linkableDuplicatePaths(List<EntryDefinition> definitions) {
    if (definitions.isEmpty) return [];

    final possibleTags = definitions
        .map((e) => e.blueprint.tags)
        .reduce((acc, tags) => acc.intersection(tags).toList(growable: false));

    final wildPaths = definitions
        .map((e) => e.blueprint.fieldsWithModifier<EntryReferenceModifier>())
        .map((m) {
          return m.entries
              .where((e) => e.value.every((m) => possibleTags.contains(m.tag)))
              .toMap();
        })
        .reduce((acc, map) {
          return acc.entries
              .where((e) => listEquals(e.value, map[e.key]))
              .toMap();
        })
        .keys
        .toList();

    if (wildPaths.isEmpty) return [];

    return wildPaths.expand((wildPath) {
      return definitions
          .map((e) => e.data.newPaths(wildPath).toSet())
          .reduce((acc, paths) => acc.intersection(paths));
    }).toList();
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.copy),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => LoadingButton.filledIcon(
      icon: const Icones(Fa6Solid.copy),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to duplicate the selected entry.
class EntryDuplicateOperation extends ActivatorShortcutOperation {
  const EntryDuplicateOperation();

  @override
  String get name => "Duplicate";

  @override
  String get description => "Create a copy of this entry";

  Color get color => Colors.green;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyD),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement duplication:
    // 1) Create a copy with new ID.
    // 2) Add to current page.
    // 3) Select new entry and refresh.
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.clone),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => LoadingButton.filledIcon(
      icon: const Icones(Fa6Solid.clone),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to move the selected entry to another page.
class EntryMoveToPageOperation extends ActivatorShortcutOperation {
  const EntryMoveToPageOperation();

  @override
  String get name => "Move to...";

  @override
  String get description => "Move this entry to another page";

  Color get color => Colors.blueAccent;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyM),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement move:
    // 1) Open page selector.
    // 2) Persist move to selected page.
    // 3) Refresh UI.
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => LoadingButton.filledIcon(
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to replace the selected entry with another entry.
class EntryReplaceWithOperation extends ActivatorShortcutOperation {
  const EntryReplaceWithOperation();

  @override
  String get name => "Replace with...";

  @override
  String get description => "Replace this entry with another entry";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyR),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement replace:
    // 1) Select replacement entry (with confirmation).
    // 2) Rewire references to replacement.
    // 3) Persist and refresh.
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(MaterialSymbols.find_replace),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => LoadingButton.filledIcon(
      icon: const Icones(MaterialSymbols.find_replace),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}
