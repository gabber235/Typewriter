import "package:typewriter_panel/typewriter_panel.dart";

/// Asks whether protected local work may be discarded with its current scope.
Future<bool> showWorkSessionLossConfirmation(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Leave this work session?"),
        content: const Text(
          "Some local work has not reached a safe state. Leaving this account "
          "or organization will discard it.",
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Stay"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Leave"),
          ),
        ],
      ),
    ) ??
    false;
