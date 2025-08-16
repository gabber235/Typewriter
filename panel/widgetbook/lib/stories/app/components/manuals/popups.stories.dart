import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";

import "package:typewriter_panel/logic/manuals/manuals.dart";

import "package:typewriter_panel/utils/riverpod.dart";

import "package:typewriter_panel/widgets/app/components/manuals/popups.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

class _PopupScaffold extends HookConsumerWidget {
  const _PopupScaffold({
    required this.title,
    required this.openPopup,
    this.autoOpen = false,
  });

  final String title;
  final Future<void> Function(BuildContext, String) openPopup;
  final bool autoOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuals = ref.watch(manualsProvider);
    final opened = useState(false);

    useEffect(
      () {
        if (!opened.value &&
            autoOpen &&
            manuals.hasValue &&
            (manuals.asData?.value ?? const <Manual>[]).isNotEmpty) {
          opened.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final list = manuals.value!;
            final index = 0;
            openPopup(context, list[index].id);
          });
        }
        return null;
      },
      [manuals, autoOpen, opened.value],
    );

    return Scaffold(
      body: Center(
        child: manuals(
          name: "manuals",
          builder: (list) {
            if (list.isEmpty) {
              return const Text("No manuals to test with.");
            }
            final index = 0;
            final manual = list[index];
            ref.watch(proposedModulesProvider(manual.id));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text("Using manual: ${manual.name} (${manual.id})"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => openPopup(context, manual.id),
                  child: const Text("Open Popup"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Override> _overridesFor({
  required Outcome modulesOutcome,
  required Outcome platformsOutcome,
}) {
  return [
    ...manualModulesInfoProviderOverrides(),
    ...manualsProviderOverrides(
      state: DisplayState.fewItems,
      modulesOutcome: modulesOutcome,
      platformsOutcome: platformsOutcome,
    ),
    ...modulesProviderOverrides(
      state: DisplayState.fewItems,
    ),
    ...organizationProviderOverrides(),
    ...organizationsProviderOverrides(
      state: DisplayState.fewItems,
    ),
    ...authProviderOverrides(),
    ...appearanceProviderOverrides(),
  ];
}

@widgetbook.UseCase(
  name: "Change Platforms Popup",
  type: ManualChangePlatformsPopup,
)
Widget manualChangePlatformsPopupUseCase(BuildContext context) {
  final outcome = context.knobs.outcome();

  final autoOpen = context.knobs.boolean(
    label: "Auto-open",
    initialValue: false,
  );

  return FakeApp(
    overrides: _overridesFor(
      platformsOutcome: outcome,
      modulesOutcome: outcome,
    ),
    child: _PopupScaffold(
      title: "Manual — Change Platforms",
      autoOpen: autoOpen,
      openPopup: (ctx, id) =>
          showManualChangePlatformsPopup(ctx, id).then((_) {}),
    ),
  );
}

@widgetbook.UseCase(
  name: "Change Modules Popup",
  type: ManualChangeModulesPopup,
)
Widget manualChangeModulesPopupUseCase(BuildContext context) {
  final outcome = context.knobs.outcome();

  final autoOpen = context.knobs.boolean(
    label: "Auto-open",
    initialValue: false,
  );

  return FakeApp(
    overrides: _overridesFor(
      platformsOutcome: outcome,
      modulesOutcome: outcome,
    ),
    child: _PopupScaffold(
      title: "Manual — Change Modules",
      autoOpen: autoOpen,
      openPopup: (ctx, id) =>
          showManualChangeModulesPopup(ctx, id).then((_) {}),
    ),
  );
}
