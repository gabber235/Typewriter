import "dart:convert";

import "package:flutter/material.dart" hide FilledButton;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/string.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/section_title.dart";

class SkinEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "skin";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) =>
      SkinEditor(path: path, customBlueprint: dataBlueprint as CustomBlueprint);
}

class SkinEditor extends HookConsumerWidget {
  const SkinEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  String? _getSkinUrl(String textureData) {
    if (textureData.isEmpty) return null;
    try {
      // Decode base64 string
      final bytes = base64Decode(textureData);
      // Convert to a string and read the json
      final json = jsonDecode(utf8.decode(bytes));

      // Read the textures.SKIN.url field
      final url = json["textures"]["SKIN"]["url"];
      if (url is! String) {
        return null;
      }

      final id =
          url.replacePrefix("http://textures.minecraft.net/texture/", "");
      return "https://nmsr.nickac.dev/fullbody/$id";
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final texture = ref.watch(fieldValueProvider(path.join("texture"), ""));
    final url = useMemoized(() => _getSkinUrl(texture), [texture]);
    return FieldHeader(
      path: path,
      canExpand: true,
      child: Row(
        children: [
          if (url != null) ...[
            Image.network(
              url,
              width: 100,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.error,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                SectionTitle(title: l10n.texture),
                const SizedBox(height: 8),
                StringEditor(
                  path: path.join("texture"),
                  primitiveBlueprint:
                      const PrimitiveBlueprint(type: PrimitiveType.string),
                ),
                const SizedBox(height: 8),
                SectionTitle(title: l10n.signature),
                const SizedBox(height: 8),
                StringEditor(
                  path: path.join("signature"),
                  primitiveBlueprint:
                      const PrimitiveBlueprint(type: PrimitiveType.string),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
