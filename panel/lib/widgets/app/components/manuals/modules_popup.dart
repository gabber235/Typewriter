import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:pub_semver/pub_semver.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/widget_state.dart";
import "package:typewriter_panel/widgets/generic/components/admonition.dart";
import "package:typewriter_panel/widgets/generic/components/dropdown.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/notification_bubble.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

part "modules_popup.freezed.dart";
part "modules_popup.g.dart";

@riverpod
class ProposedModules extends _$ProposedModules {
  @override
  Future<List<ManualModuleReference>> build(String manualId) async {
    final manual = await ref.watch(manualProvider(manualId).future);
    if (manual == null) return [];
    return manual.modules;
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<ManualModuleReference>> previous,
    AsyncValue<List<ManualModuleReference>> next,
  ) =>
      !previous.matches(next, listEquals);

  void add(ManualModuleReference module) {
    if (!state.hasValue) return;
    state = AsyncValue.data([...state.requireValue, module]);
  }

  void updateAt(int index, ManualModuleReference updated) {
    if (!state.hasValue) return;
    final list = [...state.requireValue];
    if (index < 0) return;
    if (index >= list.length) return;

    list[index] = updated;
    state = AsyncValue.data(list);
  }

  int _indexOf(String moduleId) {
    if (!state.hasValue) return -1;
    return state.requireValue
        .indexWhere((module) => module.moduleId == moduleId);
  }

  void updateVersion(String moduleId, Version version) {
    if (!state.hasValue) return;
    final list = state.requireValue;
    final index = _indexOf(moduleId);
    if (index < 0) return;
    if (index >= list.length) return;
    updateAt(index, list[index].copyWith(version: version));
  }

  void removeAt(int index) {
    if (!state.hasValue) return;
    final list = state.requireValue;
    if (index < 0) return;
    if (index >= list.length) return;
    state = AsyncValue.data([...list]..removeAt(index));
  }

  void remove(String moduleId) {
    if (!state.hasValue) return;
    final index = _indexOf(moduleId);
    removeAt(index);
  }
}

@riverpod
class ProposedModulesIds extends _$ProposedModulesIds {
  @override
  FutureOr<List<String>> build(String manualId) async {
    final modules = await ref.watch(proposedModulesProvider(manualId).future);
    return modules.map((module) => module.moduleId).sorted().toList();
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<String>> previous,
    AsyncValue<List<String>> next,
  ) {
    return !previous.matches(next, listEquals);
  }
}

@freezed
abstract class ManualModuleInformation with _$ManualModuleInformation {
  @Assert(
    "compatibleVersions.isNotEmpty",
    "The module has no compatible versions.",
  )
  @Assert(
    "compatibleVersions.contains(version)",
    "The module is not compatible with the current version.",
  )
  factory ManualModuleInformation({
    required String moduleId,
    required String name,
    required String description,
    required String author,
    required ModuleType type,
    @SemverJsonConverter() required Version version,
    @SemverListJsonConverter() required List<Version> compatibleVersions,
    @Default(true) bool canBeRemoved,
  }) = _ManualModuleInformation;

  factory ManualModuleInformation.fromJson(Map<String, dynamic> json) =>
      _$ManualModuleInformationFromJson(json);
}

@riverpod
Future<List<ManualModuleInformation>> manualModulesInfo(
  Ref ref,
  String manualId,
) async {
  throw UnimplementedError();
}

/// Popup for changing a manual's modules (engines and extensions).
class ManualChangeModulesPopup extends HookConsumerWidget {
  const ManualChangeModulesPopup({required this.manualId, super.key});

  final String manualId;

  void updateAll(WidgetRef ref, List<ManualModuleInformation> modules) {
    final notifier = ref.read(proposedModulesProvider(manualId).notifier);
    modules
        .where(
      (module) => module.version != module.compatibleVersions.last,
    )
        .forEach((module) {
      notifier.updateVersion(module.moduleId, module.compatibleVersions.last);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesInfo = ref.watch(manualModulesInfoProvider(manualId));

    final groupedModules = useMemoized(
      () => modulesInfo.whenData((modules) {
        return modules.groupListsBy((module) => module.type);
      }),
      [modulesInfo],
    );

    final submitting = useState(false);
    final manualOperationResult = useState<ManualOperationResult?>(null);

    Future<void> submit() async {
      manualOperationResult.value = null;
      submitting.value = true;

      final proposed = await ref.read(proposedModulesProvider(manualId).future);

      final result = await ref
          .read(manualsProvider.notifier)
          .changeModules(manualId: manualId, proposed: proposed);

      result.when(
        success: (m) {
          Navigator.of(context).pop<Manual>(m);
        },
        failure: (reason, details) {
          manualOperationResult.value =
              ManualOperationResult.failure(reason: reason, details: details);
          submitting.value = false;
        },
      );
    }

    void addModule() {
      // TODO: Implement adding a new module
    }

    return groupedModules(
      name: "modules information",
      builder: (groupedModules) {
        final modules = useMemoized(
          () => groupedModules.values.flattened.toList(),
        );
        final showCanUpdateAll = useMemoized(
          () => modules.any(
            (module) => module.version != module.compatibleVersions.last,
          ),
          [modules],
        );
        return AlertDialog(
          title: const Text("Change Modules"),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width.clamp(0, 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "Modules"),
                        const SizedBox(height: 8),
                        Text(
                          "Configure the modules used by this manual.",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (showCanUpdateAll)
                      TextButton(
                        onPressed: () => updateAll(ref, modules),
                        child: Text(
                          "Update All",
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (modules.isEmpty)
                  Section(
                    margin: EdgeInsets.zero,
                    child: Text(
                      "No modules configured yet.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 500),
                    child: CustomScrollView(
                      shrinkWrap: modules.length < 10,
                      slivers: [
                        for (final (type, modules) in ModuleType.values
                            .where((type) => groupedModules.containsKey(type))
                            .map(
                              (type) => (type, groupedModules[type]!),
                            )) ...[
                          SliverToBoxAdapter(
                            child: SectionTitle(title: type.displayName),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: modules.length,
                              (context, index) {
                                return _ModuleEditor(
                                  manualId: manualId,
                                  module: modules[index],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (manualOperationResult.value != null) ...[
                  const SizedBox(height: 8),
                  manualOperationResult.value!.when(
                    success: (_) => const SizedBox(),
                    failure: (message, details) => Admonition.danger(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message),
                          for (final detail in details)
                            Text(
                              "‣ $detail",
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton.icon(
              onPressed: addModule,
              icon: const Icon(Icons.add),
              label: const Text("Add Module"),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: submitting.value
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                LoadingButton.filled(
                  onPressed: submit,
                  child: const Text("Validate & Save"),
                ),
              ],
            ),
          ],
        );
      },
      error: (title, message) {
        return AlertDialog(
          content: ErrorScreen.small(title: title, message: message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
      loading: (name) {
        return AlertDialog(
          title: Text("Loading $name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class _ModuleEditor extends HookConsumerWidget {
  const _ModuleEditor({
    required this.manualId,
    required this.module,
  });

  final String manualId;
  final ManualModuleInformation module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final colorScheme = Theme.of(context).colorScheme;

    return Section(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    // TODO: Open module search popup to pick a different module
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("TODO: Module search selector"),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    alignment: Alignment.centerLeft,
                    foregroundColor: WidgetStateProperty.all(
                      module.type.themedColor(context),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      module.type.themedColor(context).on(context),
                    ),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 16),
                    ),
                    shape: WidgetStateOutlinedBorder.resolveWith((state) {
                      return RoundedRectangleBorder(
                        side: BorderSide(
                          color: state.isFocused
                              ? module.type.themedColor(context)
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      );
                    }),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            module.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            module.author,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            NotificationBubble.custom(
              show: module.compatibleVersions.last != module.version,
              overlap: 4,
              bubble: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icones(
                  MaterialSymbols.keyboard_double_arrow_up_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
              child: Dropdown<Version>(
                focusNode: focusNode,
                selected: module.version,
                dropdownMenuEntries: [
                  for (final version in module.compatibleVersions)
                    DropdownMenuEntry(
                      value: version,
                      label: version.canonicalizedVersion,
                      labelWidget: Text(version.canonicalizedVersion),
                    ),
                ],
                onSelected: (version) {
                  if (version == null) return;
                  ref
                      .read(proposedModulesProvider(manualId).notifier)
                      .updateVersion(module.moduleId, version);
                },
                // inputDecorationTheme: InputDecorationTheme(
                //   fillColor: Colors.red,
                //   focusColor: Colors.blue,
                //   hoverColor: Colors.green,
                //   // border: OutlineInputBorder(
                //   //   borderRadius: BorderRadius.circular(4),
                //   //   borderSide: BorderSide.none,
                //   // ),
                // ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: module.canBeRemoved
                  ? () {
                      ref
                          .read(proposedModulesProvider(manualId).notifier)
                          .remove(module.moduleId);
                    }
                  : null,
              icon: const Icon(Icons.delete),
              color: colorScheme.error,
              tooltip: module.canBeRemoved ? "Remove" : "Cannot be removed",
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Helper to present the modules change popup and return the updated manual when successful.
Future<Manual?> showManualChangeModulesPopup(
  BuildContext context,
  String manualId,
) {
  return showAdvancedDialogue<Manual>(
    context: context,
    builder: (context) => ManualChangeModulesPopup(manualId: manualId),
  );
}
