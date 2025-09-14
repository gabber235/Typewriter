import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:pub_semver/pub_semver.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/admonition.dart";
import "package:typewriter_panel/widgets/app/components/dropdown.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";
import "package:typewriter_panel/widgets/app/components/validated_text_field.dart";
import "package:typewriter_panel/widgets/app/components/version_filter.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

part "platforms_popup.g.dart";

@riverpod
class ProposedTargets extends _$ProposedTargets {
  @override
  Future<List<PlatformTarget>> build(String manualId) async {
    final manual = await ref.watch(manualProvider(manualId).future);
    if (manual == null) return [];
    return manual.platforms;
  }

  void add(PlatformTarget target) {
    if (!state.hasValue) return;
    state = AsyncValue.data([...state.requireValue, target]);
  }

  void insert(int index, PlatformTarget target) {
    if (!state.hasValue) return;
    final oldState = state.requireValue;
    state = AsyncValue.data([
      ...oldState.sublist(0, index),
      target,
      if (index < oldState.length - 1) ...oldState.sublist(index + 1),
    ]);
  }

  void removeAt(int index) {
    if (!state.hasValue) return;
    state = AsyncValue.data([...state.requireValue]..removeAt(index));
  }
}

/// Popup for changing the platform targets and constraints of a manual.
class ManualChangePlatformsPopup extends HookConsumerWidget {
  const ManualChangePlatformsPopup({required this.manualId, super.key});

  final String manualId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePlatforms = ref.watch(platformsProvider);
    final manualAsync = ref.watch(manualProvider(manualId));
    final proposedTargets = ref.watch(proposedTargetsProvider(manualId));

    final submitting = useState(false);
    final manualOperationResult = useState<ManualOperationResult?>(null);

    Future<void> submit() async {
      manualOperationResult.value = null;
      submitting.value = true;
      final manual = manualAsync.value;
      if (manual == null) {
        manualOperationResult.value =
            ManualOperationResult.failure(reason: "Manual not found.");
        submitting.value = false;
        return;
      }
      final proposed = proposedTargets.value;
      if (proposed == null) {
        manualOperationResult.value =
            ManualOperationResult.failure(reason: "No proposed targets.");
        submitting.value = false;
        return;
      }
      final result = await ref
          .read(manualsProvider.notifier)
          .changePlatformTargets(manualId: manual.id, proposed: proposed);

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

    void addPlatformTarget() {
      if (availablePlatforms.isEmpty) {
        manualOperationResult.value = ManualOperationResult.failure(
          reason: "No platforms available",
        );
        return;
      }
      final platform = availablePlatforms.first;
      ref
          .read(proposedTargetsProvider(manualId).notifier)
          .add(PlatformTarget(platform: platform));
    }

    return AlertDialog(
      title: const Text("Change Platforms"),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(0, 800),
        child: manualAsync(
          name: "manual",
          builder: (manual) {
            if (manual == null) {
              return ErrorScreen(
                title: "Manual not found",
                message:
                    "The manual could not be found. Please try to refresh.",
              );
            }
            return proposedTargets(
              name: "proposed targets",
              builder: (targets) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(title: "Platforms & Constraints"),
                    const SizedBox(height: 8),
                    Text(
                      "Configure the target platform(s) and supported version ranges.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (targets.isEmpty)
                      Section(
                        margin: EdgeInsets.zero,
                        child: Text(
                          "No platforms configured yet.",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    Flexible(
                      child: ListView.builder(
                        itemCount: targets.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return _PlatformTargetEditor(
                            value: targets[index],
                            allPlatforms: availablePlatforms,
                            onChanged: (updated) {
                              ref
                                  .read(
                                    proposedTargetsProvider(manualId).notifier,
                                  )
                                  .insert(index, updated);
                            },
                            onRemove: () {
                              ref
                                  .read(
                                    proposedTargetsProvider(manualId).notifier,
                                  )
                                  .removeAt(index);
                            },
                          );
                        },
                      ),
                    ),
                    if (manualOperationResult.value != null)
                      manualOperationResult.value!.when(
                        success: (_) => const SizedBox(),
                        failure: (message, details) => Admonition.danger(
                          child: Column(
                            children: [
                              Text(message),
                              for (final detail in details)
                                Text(
                                  "‣ $detail",
                                  style: TextStyle(fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton.icon(
          onPressed: addPlatformTarget,
          icon: const Icon(Icons.add),
          label: const Text("Add Platform"),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          children: [
            TextButton(
              onPressed:
                  submitting.value ? null : () => Navigator.of(context).pop(),
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
  }
}

class _PlatformTargetEditor extends HookConsumerWidget {
  const _PlatformTargetEditor({
    required this.value,
    required this.allPlatforms,
    required this.onChanged,
    required this.onRemove,
  });

  final PlatformTarget value;
  final List<Platform> allPlatforms;
  final ValueChanged<PlatformTarget> onChanged;
  final VoidCallback onRemove;

  void updatePlatform(Platform platform) {
    onChanged(
      PlatformTarget.fromPlatform(platform),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plateformFocusNode = useFocusNode();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Section(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(title: "Platform"),
              Row(
                children: [
                  Expanded(
                    child: Dropdown<Platform>(
                      focusNode: plateformFocusNode,
                      selected: value.platform,
                      dropdownMenuEntries: [
                        for (final platform in allPlatforms)
                          DropdownMenuEntry(
                            value: platform,
                            label: platform.displayName,
                            labelWidget: Row(
                              children: [
                                Text(platform.displayName),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (platform) {
                        if (platform == null) return;
                        updatePlatform(platform);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: "Remove",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (value.platform.requirements.isNotEmpty) ...[
                const SectionTitle(title: "Requirements"),
                const SizedBox(height: 8),
                ...value.platform.requirements.map(
                  (req) => _RequirementEditor(
                    requirement: req,
                    target: value,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementEditor extends StatelessWidget {
  const _RequirementEditor({
    required this.requirement,
    required this.target,
    required this.onChanged,
  });

  final PlatformRequirement requirement;
  final PlatformTarget target;
  final ValueChanged<PlatformTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final child = switch (requirement.type) {
      PlatformConstraintType.version => _VersionRequirementEditor(
          requirement: requirement,
          target: target,
          onChanged: onChanged,
        ),
    };

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: child,
      ),
    );
  }
}

const maxVersions = 100;

class _VersionRequirementEditor extends HookWidget {
  const _VersionRequirementEditor({
    required this.requirement,
    required this.target,
    required this.onChanged,
  });

  final PlatformRequirement requirement;
  final PlatformTarget target;
  final ValueChanged<PlatformTarget> onChanged;

  PlatformVersionConstraint? get _versionConstraint =>
      target.constraints[requirement.name] as PlatformVersionConstraint?;

  List<Version> _parseVersionPattern(
    String input, {
    bool countExisting = true,
  }) {
    final text = input.trim();
    if (text.isEmpty) {
      throw const FormatException(
        "Enter a version like 1.2.3 or a range like 1.2.3-7",
      );
    }
    final filter = _VersionGeneratorParser.parse(query: text);
    final predictedExpansion = filter.predictExpansion();
    final existingCount =
        countExisting ? _versionConstraint?.versions.length ?? 0 : 0;
    if (predictedExpansion + existingCount > maxVersions) {
      throw FormatException(
        "You are only allowed to have $maxVersions versions (${predictedExpansion + existingCount}/100)",
      );
    }

    final versions = filter.expand();
    if (versions.isEmpty) {
      throw const FormatException("No versions resolved from input");
    }
    return versions;
  }

  @override
  Widget build(BuildContext context) {
    final existing = _versionConstraint?.versions ?? <Version>[];

    final controller = useTextEditingController(text: "");
    final focus = useFocusNode();

    final filter = useState(const VersionFilter());

    final hasEpoch = useMemoized(
      () {
        return existing.any((v) => v.major >= 1000);
      },
      [existing],
    );

    final filtered = useMemoized(
      () {
        final list = existing
            .where((v) => filter.value.matches(v))
            .sorted((a, b) => b.compareTo(a));
        return list;
      },
      [existing, filter.value],
    );

    void addVersions(List<Version> versions) {
      final map = <String, Version>{
        for (final v in existing) v.canonicalizedVersion: v,
      };
      for (final v in versions) {
        map[v.canonicalizedVersion] = v;
      }
      final next = map.values.toList()..sort();
      final updatedConstraints = {
        ...target.constraints,
        requirement.name: PlatformConstraint.version(versions: next),
      };
      onChanged(
        target.copyWith(constraints: updatedConstraints),
      );
    }

    void removeVersions(List<Version> versions) {
      final toRemove = {
        for (final v in versions) v.canonicalizedVersion,
      };
      final next = [
        for (final v in existing)
          if (!toRemove.contains(v.canonicalizedVersion)) v,
      ]..sort();
      final updatedConstraints = Map<String, PlatformConstraint>.from(
        target.constraints,
      )..[requirement.name] = PlatformConstraint.version(versions: next);
      onChanged(
        target.copyWith(constraints: updatedConstraints),
      );
    }

    void tryAdd() {
      final text = controller.text;
      List<Version> versions;
      try {
        versions = _parseVersionPattern(text);
      } on FormatException {
        focus.requestFocus();
        return;
      }
      addVersions(versions);
    }

    void tryRemove() {
      final text = controller.text;
      List<Version> versions;
      try {
        versions = _parseVersionPattern(text, countExisting: false);
      } on FormatException {
        focus.requestFocus();
        return;
      }
      removeVersions(versions);
    }

    Widget versionChip(Version version) {
      return InputChip(
        label: Text(version.canonicalizedVersion),
        onDeleted: () => removeVersions([version]),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: requirement.name.formatted),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          Text(
            "No versions yet.",
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          VersionFilterBar(
            filtered: existing,
            filter: filter,
            hasEpoch: hasEpoch,
            hintText: "Filter versions",
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: filtered.length <= 20
                  ? SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final v in filtered) versionChip(v),
                        ],
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 3.5,
                        ),
                        shrinkWrap: filtered.length < 50,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            versionChip(filtered[index]),
                      ),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ValidatedTextField<List<Version>?>(
          value: null,
          focusNode: focus,
          controller: controller,
          name: "version",
          keepValidVisibleWhileFocused: true,
          keepErrorVisibleWhenUnfocused: false,
          deserialize: (_) => "",
          serialize: _parseVersionPattern,
          // Prevent the focus from moving to the surrounding focus.
          onEditingComplete: () {},
          onSubmitted: (versions) {
            if (versions == null || versions.isEmpty) return;
            addVersions(versions);
          },
          surroundingActions: [
            if (controller.text.isNotEmpty) ...[
              ActionShortcut(
                id: "version_input_remove",
                label: "Remove",
                description: "Remove versions",
                activators: [
                  const SingleActivator(LogicalKeyboardKey.delete),
                  const SingleActivator(LogicalKeyboardKey.backspace),
                ],
                priority: 1001,
                onInvoke: (_) => tryRemove(),
              ),
              ActionShortcut(
                id: "version_input_add",
                label: "Add",
                description: "Add versions",
                activators: [
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    control: true,
                  ),
                  const SingleActivator(LogicalKeyboardKey.enter, meta: true),
                ],
                priority: 1000,
                onInvoke: (_) => tryAdd(),
              ),
            ],
          ],
          decoration: InputDecoration(
            hintText: "e.g. 1.2.3 • 4.24.32.3 • 12.3.4-7 • 12.3.4-12.3.7",
            isDense: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: "Remove",
                  onPressed: tryRemove,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Add",
                  onPressed: tryAdd,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ignore: avoid_classes_with_only_static_members
class _VersionGeneratorParser {
  static VersionFilter parse({
    required String query,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      throw FormatException("Input a valid version: major.minor.patch");
    }
    final parts = q.split(".").map(parsePart).toList();

    if (parts.length == 3) {
      parts.insert(0, const FixedPart(0));
    }

    if (parts.length != 4) {
      throw FormatException("Input a valid version: major.minor.patch");
    }

    final [epoch, major, minor, patch] = parts;
    return VersionFilter(
      epoch: epoch,
      semanticMajor: major,
      minor: minor,
      patch: patch,
    );
  }

  static VersionPartFilter parsePart(String part) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) {
      throw FormatException(
        "Invalid version part: either a number '8' or a range '8-10' is expected",
      );
    }

    if (trimmed == "*") throw FormatException("Wildcard '*' is not allowed");

    if (trimmed.contains("-")) {
      final parts =
          trimmed.split("-").map((e) => e.trim().asInt).toList(growable: false);
      if (parts.length != 2) {
        throw FormatException(
          "Invalid range, '$trimmed', expected 2 parts: 'low-high'",
        );
      }
      final low = parts[0];
      final high = parts[1];
      return RangePart(low, high);
    }

    final v = trimmed.asInt;
    if (v != null) return FixedPart(v);
    throw FormatException(
      "Invalid version part, '$trimmed', either a number '8' or a range '8-10' is expected",
    );
  }
}

/// Helper to present the platform change popup and return the updated manual when successful.
Future<Manual?> showManualChangePlatformsPopup(
  BuildContext context,
  String manualId,
) {
  return showAdvancedDialogue<Manual>(
    context: context,
    builder: (context) => ManualChangePlatformsPopup(manualId: manualId),
  );
}
