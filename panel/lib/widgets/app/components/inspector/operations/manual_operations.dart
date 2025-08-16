import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "package:iconify_flutter_plus/icons/mdi.dart";
import "package:iconify_flutter_plus/icons/tabler.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/manuals/popups.dart";
import "package:typewriter_panel/widgets/generic/components/context_menu.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";

class ManualChangePlatformTargetsOperation extends Operation {
  const ManualChangePlatformTargetsOperation();

  @override
  String get name => "Change Platforms";

  @override
  String get description => "Change the platforms of a manual";

  Color get color => Colors.blue;

  @override
  List<ShortcutActivator> get shortcutActivators => [
        SingleActivator(LogicalKeyboardKey.keyP),
      ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (selection.length != 1) return false;
    final selectable = selection.first;
    return selectable is ManualSelection;
  }

  @override
  FutureOr<void> executeOn(
    WidgetRef ref,
  ) async {
    final selection = ref.read(selectedProvider).requireValue;
    if (selection.isEmpty) return;
    final manual = selection.first as ManualSelection;
    await showManualChangePlatformsPopup(ref.context, manual.id.id);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: Icones(Tabler.exchange),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
        builder: (context, ref, _) => LoadingButton.filledIcon(
          icon: Icones(Tabler.exchange),
          label: Text(name),
          onPressed: () => executeOn(ref),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(color),
            foregroundColor: WidgetStateProperty.all(color.on(context)),
          ),
        ),
      );
}

class ManualChangeModulesOperation extends Operation {
  const ManualChangeModulesOperation();

  @override
  String get name => "Change Modules";

  @override
  String get description => "Change the modules of a manual";

  Color get color => Colors.orangeAccent;

  @override
  List<ShortcutActivator> get shortcutActivators => [
        SingleActivator(LogicalKeyboardKey.keyM),
      ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (selection.length != 1) return false;
    final selectable = selection.first;
    return selectable is ManualSelection;
  }

  @override
  FutureOr<void> executeOn(
    WidgetRef ref,
  ) async {
    final selection = ref.read(selectedProvider).requireValue;
    if (selection.isEmpty) return;
    final manual = selection.first as ManualSelection;
    await showManualChangeModulesPopup(ref.context, manual.id.id);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: Icones(Mdi.file_replace),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
        builder: (context, ref, _) => LoadingButton.filledIcon(
          icon: Icones(Mdi.file_replace),
          label: Text(name),
          onPressed: () => executeOn(ref),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(color),
            foregroundColor: WidgetStateProperty.all(color.on(context)),
          ),
        ),
      );
}
