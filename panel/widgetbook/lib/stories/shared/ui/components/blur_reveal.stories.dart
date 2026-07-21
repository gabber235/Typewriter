import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Text", type: BlurReveal)
Widget blurRevealTextUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: "Text",
    initialValue: "Hover to reveal this secret message",
  );
  final blurSigma = context.knobs.double.slider(
    label: "Blur Sigma",
    initialValue: 6.0,
    min: 1.0,
    max: 15.0,
  );
  final animationDurationMs = context.knobs.int.slider(
    label: "Animation Duration (ms)",
    initialValue: 200,
    min: 50,
    max: 1000,
  );

  return FakeApp(
    child: Center(
      child: BlurReveal(
        blurSigma: blurSigma,
        animationDuration: Duration(milliseconds: animationDurationMs),
        child: Text(text),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Icon", type: BlurReveal)
Widget blurRevealIconUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: BlurReveal(
        blurSigma: 8.0,
        child: Icon(
          Icons.lock,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Card", type: BlurReveal)
Widget blurRevealCardUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: BlurReveal(
        blurSigma: 10.0,
        animationDuration: const Duration(milliseconds: 300),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card, size: 48),
                const SizedBox(height: 8),
                Text(
                  "4242 4242 4242 4242",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: "JetBrainsMono",
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Expires 12/25",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Image", type: BlurReveal)
Widget blurRevealImageUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: BlurReveal(
        blurSigma: 12.0,
        animationDuration: const Duration(milliseconds: 400),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 64, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}
