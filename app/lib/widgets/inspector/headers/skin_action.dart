import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:http/http.dart" as http;
import "package:ktx/collections.dart";
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
    return HeaderButton(
      tooltip: "Fetch From UUID",
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
    return HeaderButton(
      tooltip: "Fetch From URL",
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
    final l10n = context.l10n;
    final controller = useTextEditingController();
    final focus = useFocusNode();
    final error = useState<String?>(null);
    final selectedVariant = useState<SkinVariant>(SkinVariant.unknown);

    return AlertDialog(
      title: const Text("Fetch Skin"),
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
            hintText: "Enter the $bodyKey to fetch the skin",
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
          label: const Text("Fetch"),
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
      return "An unknown error occurred";
    }

    final result = jsonDecode(response.body);
    if (result is! Map<String, dynamic>) {
      return "An unknown error occurred";
    }

    if (!result.containsKey("skin")) {
      return "Could not find the skin data in the response";
    }

    final textureObject = result["skin"]["texture"];
    if (textureObject == null || textureObject is! Map<String, dynamic>) {
      return "Invalid texture data in response";
    }

    final textureData = textureObject["data"];
    if (textureData == null || textureData is! Map<String, dynamic>) {
      return "Invalid texture data in response";
    }

    final texture = textureData["value"];
    final signature = textureData["signature"];

    if (texture is! String || signature is! String) {
      return "Invalid texture or signature in response";
    }

    final definition = ref.read(inspectingEntryDefinitionProvider);
    if (definition == null) {
      return "Currently not inspecting an entry";
    }

    await definition.updateField(ref, path, {
      "texture": texture,
      "signature": signature,
    });

    return null;
  }
}
