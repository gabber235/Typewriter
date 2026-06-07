import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:http/http.dart" as http;
import "package:ktx/collections.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/header_button.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/components/general/dropdown.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/loading_button.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class SkinFetchFromUUIDHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "skin";

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
      SkinFetchFromUUIDHeaderAction(
        path: path,
      );
}

class SkinFetchFromUUIDHeaderAction extends HookConsumerWidget {
  const SkinFetchFromUUIDHeaderAction({
    required this.path,
    super.key,
  });

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return HeaderButton(
      tooltip: l10n.fetchFromUUID,
      icon: TWIcons.accountTag,
      color: Colors.orange,
      onTap: () => showDialog(
        context: context,
        builder: (context) => _FetchFromMineSkinDialogue(
          path: path,
          bodyKey: "user",
          icon: TWIcons.accountTag,
        ),
      ),
    );
  }
}

class SkinFetchFromURLHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "skin";

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
      SkinFetchFromURLHeaderAction(
        path: path,
      );
}

class SkinFetchFromURLHeaderAction extends HookConsumerWidget {
  const SkinFetchFromURLHeaderAction({
    required this.path,
    super.key,
  });

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return HeaderButton(
      tooltip: l10n.fetchFromURL,
      icon: TWIcons.url,
      color: Colors.blue,
      onTap: () => showDialog(
        context: context,
        builder: (context) => _FetchFromMineSkinDialogue(
          path: path,
          bodyKey: "url",
          icon: TWIcons.url,
        ),
      ),
    );
  }
}

enum SkinVariant {
  classic,
  slim,
  unknown,
}

class _FetchFromMineSkinDialogue extends HookConsumerWidget {
  const _FetchFromMineSkinDialogue({
    required this.path,
    required this.bodyKey,
    required this.icon,
  });

  final String path;
  final String bodyKey;
  final String icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final controller = useTextEditingController();
    final focus = useFocusNode();
    final error = useState<String?>(null);
    final selectedVariant = useState<SkinVariant>(SkinVariant.unknown);

    return AlertDialog(
      title: Text(l10n.fetchSkin),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error.value != null) ...[
            Admonition.danger(
              child: Text(error.value!),
            ),
            const SizedBox(height: 8),
          ],
          FormattedTextField(
            focus: focus,
            controller: controller,
            icon: icon,
            hintText: l10n.fetchSkinHint(bodyKey),
          ),
          const SizedBox(height: 16),
          Dropdown<SkinVariant>(
            value: selectedVariant.value,
            values: SkinVariant.values,
            icon: TWIcons.skin,
            onChanged: (value) {
              selectedVariant.value = value;
            },
            builder: (context, value) {
              return Text(value.name.formatted);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        LoadingButton.icon(
          icon: const Iconify(TWIcons.download),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final result = await _fetchSkin(
              ref.passing,
              controller.text,
              selectedVariant.value,
            );
            if (result == null) {
              navigator.pop();
              return;
            }
            focus.requestFocus();
            error.value = result;
          },
          label: Text(l10n.fetch),
        ),
      ],
    );
  }

  Future<String?> _fetchSkin(
    PassingRef ref,
    String data,
    SkinVariant variant,
  ) async {
    final headers = {
      "User-Agent": "Typewriter/1.0",
      "Content-Type": "application/json",
    };

    final body = {
      "visibility": "public",
      bodyKey: data,
      "variant": variant.name,
    };

    final response = await http.post(
      Uri.parse("https://api.mineskin.org/v2/generate"),
      headers: headers,
      body: jsonEncode(body),
    );

    final l10n = ref.l10n;

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey("errors")) {
        final errors = data["errors"];
        if (errors is List<dynamic> && errors.isNotEmpty) {
          return errors.mapNotNull((e) {
            if (e is Map<String, dynamic> && e.containsKey("message")) {
              return e["message"];
            }
            return null;
          }).join("\n");
        }
      }
      return l10n.unexpectedError;
    }

    final result = jsonDecode(response.body);
    if (result is! Map<String, dynamic>) {
      return l10n.unexpectedError;
    }

    if (!result.containsKey("skin")) {
      return l10n.noSkinDataError;
    }

    final textureObject = result["skin"]["texture"];
    if (textureObject == null || textureObject is! Map<String, dynamic>) {
      return l10n.invalidTextureDataError;
    }

    final textureData = textureObject["data"];
    if (textureData == null || textureData is! Map<String, dynamic>) {
      return l10n.invalidTextureDataError;
    }

    final texture = textureData["value"];
    final signature = textureData["signature"];

    if (texture is! String || signature is! String) {
      return l10n.textureAndSignatureMustBeStrings;
    }

    final definition = ref.read(inspectingEntryDefinitionProvider);
    if (definition == null) {
      return l10n.noEntryChecked;
    }

    await definition.updateField(ref, path, {
      "texture": texture,
      "signature": signature,
    });

    return null;
  }
}
