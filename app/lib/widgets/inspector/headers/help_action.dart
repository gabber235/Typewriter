import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/extension_l10n_provider.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/localized_entry_metadata.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class HelpHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint.getModifier("help") != null;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.trailing;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HelpHeaderAction(path: path, dataBlueprint: dataBlueprint);
}

class HelpHeaderAction extends HookConsumerWidget {
  const HelpHeaderAction({
    required this.path,
    required this.dataBlueprint,
    super.key,
  });

  final String path;
  final DataBlueprint dataBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = dataBlueprint.getModifier("help");
    if (help == null) {
      return const SizedBox();
    }

    final blueprint = ref.watch(
      inspectingEntryDefinitionProvider.select((def) => def?.blueprint),
    );
    final (:key, :fallback) =
        LocalizedEntryMetadata.getHelpKeyAndFallback(dataBlueprint);
    final helpKey = blueprint == null
        ? key
        : key ?? LocalizedEntryMetadata.defaultFieldHelpKey(blueprint, path);
    final helpText = helpKey == null
        ? fallback
        : blueprint == null
            ? fallback
            : ref.watch(extensionL10nResolverProvider).resolve(
                  blueprint.extension,
                  ref.watch(localeControllerProvider),
                  helpKey,
                  fallback: fallback,
                );
    if (helpText == null) {
      return const SizedBox();
    }
    final formattedHelp =
        helpText.replaceAll("&lt;", "<").replaceAll("&gt;", ">");
    return Tooltip(
      message: formattedHelp,
      child: Icon(
        Icons.help_outline,
        size: 16,
        color: Theme.of(context)
            .textTheme
            .bodySmall
            ?.color
            ?.withValues(alpha: 0.6),
      ),
    );
  }
}
