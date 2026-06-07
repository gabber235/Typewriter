import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/extension_l10n_provider.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/localized_entry_blueprint_provider.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/localized_entry_metadata.dart";

/// Helper widget that wraps localized entry blueprint rendering.
/// 
/// This is a convenience wrapper showing best practices for using the
/// localization system in your UI components.
class LocalizedEntryTitle extends ConsumerWidget {
  const LocalizedEntryTitle(
    this.blueprint, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final EntryBlueprint blueprint;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      entryBlueprintLocalizedTitleProvider(blueprint.id),
    );
    return Text(
      title,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Localized entry description widget
class LocalizedEntryDescription extends ConsumerWidget {
  const LocalizedEntryDescription(
    this.blueprint, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final EntryBlueprint blueprint;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref.watch(
      entryBlueprintLocalizedDescriptionProvider(blueprint.id),
    );
    return Text(
      description,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Localized field label widget
class LocalizedFieldLabel extends ConsumerWidget {
  const LocalizedFieldLabel(
    this.blueprintId,
    this.fieldPath, {
    this.style,
    super.key,
  });

  final String blueprintId;
  final String fieldPath;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(
      fieldLocalizedLabelProvider(blueprintId, fieldPath),
    );
    return Text(
      label,
      style: style,
    );
  }
}

/// Localized field help/tooltip widget
class LocalizedFieldHelp extends ConsumerWidget {
  const LocalizedFieldHelp(
    this.blueprintId,
    this.fieldPath, {
    this.style,
    super.key,
  });

  final String blueprintId;
  final String fieldPath;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = ref.watch(
      fieldLocalizedHelpProvider(blueprintId, fieldPath),
    );
    if (help == null) return const SizedBox.shrink();
    return Text(
      help,
      style: style,
    );
  }
}

/// Example showing how to manually resolve localization in custom widgets.
/// 
/// Use the pre-built providers (LocalizedEntryTitle, LocalizedFieldLabel, etc.)
/// unless you need very custom behavior.
class CustomLocalizedWidget extends ConsumerWidget {
  const CustomLocalizedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(extensionL10nResolverProvider);
    final locale = ref.watch(localeControllerProvider);

    // Example: resolve a custom key
    final customText = resolver.resolve(
      "my-extension",
      locale,
      "my.custom.key",
      fallback: "Default fallback text",
    );

    return Text(customText);
  }
}

/// Utility function to resolve field labels in bulk for enum options.
/// 
/// This is useful when rendering select/dropdown fields with multiple options.
Future<Map<String, String>> resolveOptionLabels(
  WidgetRef ref,
  String blueprintId,
  String fieldPath,
  List<String> optionValues,
) async {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) {
    return {for (final v in optionValues) v: v.formatted};
  }

  // Navigate to field
  var current = blueprint.dataBlueprint as DataBlueprint;
  final parts = fieldPath.split(".");

  for (final part in parts) {
    if (current is ObjectBlueprint) {
      final field = current.fields[part];
      if (field == null) {
        return {};
      }
      current = field;
    } else {
      return {};
    }
  }

  // Get option labels key prefix
  final keyPrefix = LocalizedEntryMetadata.getOptionLabelsKeyPrefix(current);
  if (keyPrefix == null) {
    return {for (final v in optionValues) v: v.formatted};
  }

  // Use resolver to get all labels
  final resolver = ref.watch(extensionL10nResolverProvider);
  return resolver.resolveOptionLabels(
    blueprint.extension,
    ref.watch(localeControllerProvider),
    keyPrefix,
    optionValues,
    fallbacks: {for (final v in optionValues) v: v.formatted},
  );
}
