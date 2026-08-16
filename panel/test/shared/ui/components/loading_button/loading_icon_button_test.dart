import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/ui/components/loading_button/loading_button_controller.dart";
import "package:typewriter_panel/shared/ui/components/loading_button/loading_icon_button.dart";

import "loading_button_test_support.dart";

enum _IconButtonVariant { standard, filled, outlined }

extension on _IconButtonVariant {
  Widget button({
    required Widget icon,
    required FutureOr<void> Function()? onPressed,
    LoadingButtonController? controller,
    double? iconSize,
  }) => switch (this) {
    _IconButtonVariant.standard => LoadingIconButton(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
      iconSize: iconSize,
    ),
    _IconButtonVariant.filled => LoadingIconButton.filled(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
      iconSize: iconSize,
    ),
    _IconButtonVariant.outlined => LoadingIconButton.outlined(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
      iconSize: iconSize,
    ),
  };
}

void main() {
  for (final variant in _IconButtonVariant.values) {
    group("LoadingIconButton.${variant.name}", () {
      testWidgets("shows a spinner while the action is running", (
        tester,
      ) async {
        final completer = Completer<void>();
        var invocations = 0;

        await tester.pumpLoadingButtonApp(
          child: Center(
            child: variant.button(
              icon: const Icon(Icons.add),
              onPressed: () async {
                invocations++;
                await completer.future;
                invocations++;
              },
            ),
          ),
        );

        await tester.tap(find.byType(IconButton));

        await tester.pumpUntil(() {
          expect(invocations, 1);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byIcon(Icons.add), findsNothing);
        });

        await tester.tap(find.byType(IconButton));
        expect(invocations, 1);

        completer.complete();

        await tester.pumpUntil(() {
          expect(invocations, 2);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byIcon(Icons.add), findsOneWidget);
        });
      });

      testWidgets("shows a snackbar and tooltip on failure", (tester) async {
        await tester.pumpLoadingButtonApp(
          child: Center(
            child: variant.button(
              icon: const Icon(Icons.warning),
              onPressed: () => throw Exception("Boom"),
            ),
          ),
        );

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Tooltip && widget.message == "Exception: Boom",
          ),
          findsOneWidget,
        );
      });
    });
  }

  testWidgets("supports programmatic triggering", (tester) async {
    final completer = Completer<void>();
    final controller = LoadingButtonController();
    var invoked = false;

    await tester.pumpLoadingButtonApp(
      child: Center(
        child: LoadingIconButton(
          controller: controller,
          icon: const Icon(Icons.save),
          onPressed: () async {
            invoked = true;
            await completer.future;
          },
        ),
      ),
    );

    expect(controller.trigger(), true);
    await tester.pump();

    expect(invoked, true);
    expect(controller.isLoading, true);
    expect(controller.trigger(), false);

    completer.complete();
    await tester.pumpAndSettle();

    expect(controller.isLoading, false);
  });

  testWidgets("matches the configured icon size while loading", (tester) async {
    final completer = Completer<void>();

    await tester.pumpLoadingButtonApp(
      child: Center(
        child: LoadingIconButton(
          iconSize: 32,
          icon: const Icon(Icons.refresh),
          onPressed: () => completer.future,
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpUntil(
      () => expect(find.byType(CircularProgressIndicator), findsOneWidget),
    );

    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size.square(32),
    );

    completer.complete();
    await tester.pumpAndSettle();
  });
}
