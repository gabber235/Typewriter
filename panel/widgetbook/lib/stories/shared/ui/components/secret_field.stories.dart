import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// What generating a secret answers in the story.
enum _Generation {
  valid("Valid for 10 minutes"),
  urgent("Expires in 45 seconds"),
  expired("Expires at once"),
  fails("Fails"),
  neverAnswers("Never answers");

  const _Generation(this.label);

  final String label;

  Future<SecretFieldRevealed> run() async {
    if (this == neverAnswers) return Completer<SecretFieldRevealed>().future;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final lifetime = switch (this) {
      valid => const Duration(minutes: 10),
      urgent => const Duration(seconds: 45),
      _ => const Duration(seconds: 2),
    };
    if (this == fails) throw StateError("The server refused the request");
    return SecretFieldRevealed(
      value: "q7Lm2xKe9Rz4",
      expiresAt: DateTime.now().add(lifetime),
    );
  }
}

/// The join code [SecretField] of the join codes page: generate it, then
/// watch it count down, expire or fail the way the Generation knob says.
@widgetbook.UseCase(name: "Default", type: SecretField)
Widget secretFieldUseCase(BuildContext context) {
  final generation = context.knobs.object.dropdown(
    label: "Generation",
    options: _Generation.values,
    labelBuilder: (generation) => generation.label,
    initialOption: _Generation.valid,
  );
  final prefix = context.knobs.boolean(label: "Link prefix");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 600,
        child: SecretField(
          title: "Join Code",
          description:
              "Generate a unique join code to invite new members to your "
              "organization.",
          prefix: prefix ? joinCodeUrlPrefix : null,
          onGenerate: generation.run,
          generateButtonText: "Generate Join Code",
          regenerateButtonText: "New Join Code",
          copyButtonText: "Copy Join Code",
          copiedSnackbarText: "Join code copied to clipboard",
        ),
      ),
    ),
  );
}
