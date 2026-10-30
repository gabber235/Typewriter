import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The confirmations destructive actions ask for.
enum _Confirmation {
  removeMember("Remove member"),
  revokeCode("Revoke join code"),
  unbind("Unbind resource"),
  longText("Long text");

  const _Confirmation(this.label);

  final String label;

  Future<bool> show(BuildContext context) => switch (this) {
    removeMember => showConfirmationDialogue(
      context: context,
      title: "Remove Grace?",
      content: "Grace loses access to Acme and every Realm in it.",
      confirmText: "Remove",
    ),
    revokeCode => showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content: "Nobody can join with it anymore.",
      confirmText: "Revoke",
      delayConfirm: const Duration(seconds: 3),
    ),
    unbind => showConfirmationDialogue(
      context: context,
      title: "Unbind The Lost Village?",
      titleColor: Colors.orange,
      body: const Admonition.warning(
        child: Text("Pages placed in this Book keep their content."),
      ),
      confirmText: "Unbind",
      confirmColor: Colors.orange,
    ),
    longText => showConfirmationDialogue(
      context: context,
      title:
          "Delete every page of The Lost Village, including its chapters, "
          "placed entries and tags?",
      content:
          "This removes 48 pages, 312 entries and the tags only they use. "
          "Other Books that link to these pages show the links as missing "
          "until you point them elsewhere. This action cannot be undone.",
      confirmText: "Delete everything",
    ),
  };
}

/// A [ConfirmationDialogue] as each destructive action opens it: destructive,
/// delayed confirm, custom body and title color, and long text.
@widgetbook.UseCase(name: "Default", type: ConfirmationDialogue)
Widget confirmationDialogueUseCase(BuildContext context) {
  final confirmation = context.knobs.object.dropdown(
    label: "Confirmation",
    options: _Confirmation.values,
    labelBuilder: (confirmation) => confirmation.label,
    initialOption: _Confirmation.removeMember,
  );
  return Story(const [], at: PanelLocation.component(_Opener(confirmation)));
}

/// Opens [confirmation] at once, and again from its button once closed.
class _Opener extends HookWidget {
  const _Opener(this.confirmation);

  final _Confirmation confirmation;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(confirmation.show(context));
      });
      return null;
    }, [confirmation]);
    return FilledButton(
      onPressed: () => confirmation.show(context),
      child: Text(confirmation.label),
    );
  }
}
