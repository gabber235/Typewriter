import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/widgets/generic/components/sign_out_button.dart";

@RoutePage()
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(
              "${ref.watch(accessTokenProvider).requireValue?.token}",
            ),
            SizedBox(height: 10),
            SignOutButton(),
          ],
        ),
      ),
    );
  }
}
