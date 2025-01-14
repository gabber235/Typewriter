import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/components/general/identifier.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:url_launcher/url_launcher_string.dart";

part "heading.g.dart";

@riverpod
String _entryId(Ref ref) {
  final def = ref.watch(inspectingEntryDefinitionProvider);
  return def?.entry.id ?? "";
}

@riverpod
String _entryName(Ref ref) {
  final def = ref.watch(inspectingEntryDefinitionProvider);
  return def?.entry.formattedName ?? "";
}

@riverpod
String _entryType(Ref ref) {
  final def = ref.watch(inspectingEntryDefinitionProvider);
  return def?.blueprint.id ?? "";
}

@riverpod
String _entryUrl(Ref ref) {
  final def = ref.watch(inspectingEntryDefinitionProvider);
  return def?.blueprint.wikiUrl ?? "";
}

@riverpod
Color _entryColor(Ref ref) {
  final def = ref.watch(inspectingEntryDefinitionProvider);
  return def?.blueprint.color ?? Colors.grey;
}

class Heading extends HookConsumerWidget {
  const Heading({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(_entryIdProvider);
    final name = ref.watch(_entryNameProvider);
    final type = ref.watch(_entryTypeProvider);
    final url = ref.watch(_entryUrlProvider);
    final color = ref.watch(_entryColorProvider);
    final deprecation = ref.watch(entryDeprecatedProvider(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(
          color: color,
          title: name,
          isDeprecated: deprecation != null,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          children: [
            EntryBlueprintDisplay(blueprintId: type, url: url, color: color),
            Identifier(id: id),
          ],
        ),
        if (deprecation != null) ...[
          const SizedBox(height: 8),
          _DeperecationWarning(url: url, reason: deprecation.reason),
        ],
      ],
    );
  }
}

class Title extends StatelessWidget {
  const Title({
    required this.title,
    required this.color,
    this.isDeprecated = false,
    super.key,
  });
  final String title;
  final Color color;
  final bool isDeprecated;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      title,
      style: TextStyle(
        color: color,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        decoration: isDeprecated ? TextDecoration.lineThrough : null,
        decorationThickness: 2.8,
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: color,
      ),
      maxLines: 1,
    );
  }
}

class EntryBlueprintDisplay extends HookConsumerWidget {
  const EntryBlueprintDisplay({
    required this.blueprintId,
    required this.url,
    required this.color,
    super.key,
  });
  final String blueprintId;
  final String url;
  final Color color;

  Future<void> _launceUrl() async {
    if (url.isEmpty) return;
    if (!await canLaunchUrlString(url)) return;
    await launchUrlString(url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintName =
        ref.watch(entryBlueprintProvider(blueprintId).select((e) => e?.name));
    if (blueprintName == null) return const SizedBox();

    final hovering = useState(false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: GestureDetector(
        onTap: url.isNotEmpty ? _launceUrl : null,
        child: Text(
          blueprintName.formatted,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.9),
                decoration: hovering.value ? TextDecoration.underline : null,
              ),
        ),
      ),
    );
  }
}

class _DeperecationWarning extends StatelessWidget {
  const _DeperecationWarning({
    required this.url,
    required this.reason,
  });

  final String url;
  final String reason;

  Future<void> _launceUrl() async {
    if (url.isEmpty) return;
    if (!await canLaunchUrlString(url)) return;
    await launchUrlString(url);
  }

  @override
  Widget build(BuildContext context) {
    return Admonition.danger(
      onTap: _launceUrl,
      child: Text.rich(
        TextSpan(
          text: "This entry has been marked as deprecated. Take a look at the ",
          children: [
            TextSpan(
              text: "documentation",
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.redAccent,
              ),
            ),
            TextSpan(text: " for more information."),
            if (reason.isNotEmpty) ...[
              TextSpan(
                text: "\n$reason",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
