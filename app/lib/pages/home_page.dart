import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart" hide FilledButton;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/utils/fonts.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/general/copyable_text.dart";
import "package:typewriter/widgets/components/general/filled_button.dart";
import "package:typewriter/widgets/components/general/iconify.dart";

@RoutePage()
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Expanded(
                flex: 2,
                child: RiveAnimation.asset(
                  "assets/game_character.riv",
                  stateMachines: ["State Machine"],
                ),
              ),
              Text(
                l10n.homeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              Text(
                l10n.homeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontVariations: [thinWeight],
                ),
              ),
              const SizedBox(height: 24),
              const CopyableText(text: "/typewriter connect"),
              const SizedBox(height: 24),
              const _ConnectButtons(),
              const SizedBox(height: 24),
              const Spacer(),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: currentLocale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                ],
                onChanged: (newLocale) {
                  if (newLocale != null) {
                    ref.read(localeControllerProvider.notifier).setLocale(newLocale);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectButtons extends HookConsumerWidget {
  const _ConnectButtons();

  void connectTo(
    WidgetRef ref,
    String hostname,
    int? port, {
    String token = "",
    bool secure = false,
  }) {
    ref.read(appRouter).replaceAll(
      [
        ConnectRoute(
          hostname: hostname,
          port: port,
          token: token,
          secure: secure,
        ),
      ],
    );
  }

  Future<void> customConnectToPopup(BuildContext context, WidgetRef ref) async {
    final l10n = ref.watch(l10nProvider);
    final controller = TextEditingController();
    final url = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.connectToTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.connectToHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              icon: const Iconify(TWIcons.externalLink),
              label: Text(l10n.connect),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );

    if (url == null) return;

    final uri = Uri.parse(url.replaceAll("#/", ""));
    // Get the hostname and port and token from the url query parameters
    // The token is optional and the hostname can be "hostname" or "host"
    final hostname =
        uri.queryParameters["host"] ?? uri.queryParameters["hostname"];
    final port = int.tryParse(uri.queryParameters["port"] ?? "");
    final token = uri.queryParameters["token"] ?? "";
    final secure = uri.queryParameters["secure"] == "true";

    debugPrint("Connecting to $hostname:$port with token $token");

    if (hostname == null) {
      return;
    }

    connectTo(ref, hostname, port, token: token, secure: secure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          color: Colors.green,
          icon: const Iconify(TWIcons.home),
          label: Text(l10n.connectLocalhost),
          onPressed: () => connectTo(ref, "localhost", 9092),
        ),
        const SizedBox(width: 24),
        FilledButton.icon(
          icon: const Iconify(TWIcons.connect),
          label: Text(l10n.connectCustom),
          onPressed: () => customConnectToPopup(context, ref),
        ),
      ],
    );
  }
}
