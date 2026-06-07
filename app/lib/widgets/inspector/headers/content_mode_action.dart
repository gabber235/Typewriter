import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/segment.dart";
import "package:typewriter/models/staging.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/cinematic_view.dart";
import "package:typewriter/widgets/components/app/header_button.dart";
import "package:typewriter/widgets/components/general/toasts.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class ContentModeHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      (dataBlueprint.getModifier("contentMode")?.data as String?) != null;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      ContentModeHeaderAction(path: path, dataBlueprint: dataBlueprint);
}

class ContentModeHeaderAction extends HookConsumerWidget {
  const ContentModeHeaderAction({
    required this.path,
    required this.dataBlueprint,
    super.key,
  });

  final String path;
  final DataBlueprint dataBlueprint;

  Future<void> _requestContentMode(PassingRef ref, Header? header) async {
    final l10n = ref.l10n;
    final contentModeClassPath =
        dataBlueprint.getModifier("contentMode")?.data as String?;
    if (contentModeClassPath == null) return;

    /// ------- Entry ID -------
    final entryId = ref.read(inspectingEntryIdProvider);

    if (entryId == null) {
      Toasts.showError(
        ref,
        l10n.noEntrySelected,
        description: l10n.noEntrySelectedDescriptionContent,
      );
      return;
    }

    /// ------- Field Value -------
    final value = ref.read(fieldValueProvider(path, null));

    /// ------- Page name -------
    final pageId = ref.read(currentPageIdProvider);
    if (pageId == null) {
      Toasts.showError(
        ref,
        l10n.noPageSelected,
        description: l10n.noPageSelectedDescriptionContent,
      );
      return;
    }

    final data = {
      "entryId": entryId,
      "pageId": pageId,
      "fieldPath": path,
      "fieldValue": value,
    };

    /// ------- Start & End Frame -------
    final segment = ref.read(inspectingSegmentProvider);
    final range = segment?.range;
    if (range != null) {
      data["startFrame"] = range.from;
      data["endFrame"] = range.to;
    }

    // Publish the changes before requesting the content mode to ensure the
    // latest changes are captured. And all entries are published.
    if (ref.read(stagingStateProvider) == StagingState.staging) {
      await ref.read(communicatorProvider).publish();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (header != null && header.canExpand) {
      header.expanded.value = true;
    }

    await ref
        .read(communicatorProvider)
        .requestContentMode(contentModeClassPath, data);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final header = Header.maybeOf(context);
    return HeaderButton(
      tooltip: l10n.requestContentMode,
      icon: TWIcons.camera,
      onTap: () => _requestContentMode(ref.passing, header),
    );
  }
}
