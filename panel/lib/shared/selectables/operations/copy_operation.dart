import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises the text one selectable copies as, such as a join code's link
/// or a service's id.
class CopySelectionCapability extends SelectionCapability {
  CopySelectionCapability(this.value);

  /// The text the item puts on the clipboard.
  final String value;
}

/// Copies the values of its targets on C, one per line.
///
/// The key and the context menu say so with a toast, as no control shows
/// it; the inspector button types Copied instead.
class CopyOperation extends ActivatorShortcutOperation {
  const CopyOperation();

  @override
  String get name => "Copy";

  @override
  String get description => "Copy the selected items";

  @override
  OperationSection get section => OperationSection.organize;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyC),
  ];

  @override
  bool canExecuteOn(List<Selectable> targets) =>
      targets.allHaveCapability<CopySelectionCapability>();

  @override
  ActionRun run(OperationTargets targets) =>
      pressOn(targets, (ref, items) async {
        await _copy(items);
        ref
            .read(noticesProvider.notifier)
            .report(tone: NoticeTone.success, title: "Copied to the clipboard");
      });

  /// Puts the values of [targets] on the clipboard, one per line.
  static Future<void> _copy(List<Selectable> targets) => Clipboard.setData(
    ClipboardData(
      text: targets
          .collectCapabilities<CopySelectionCapability>()
          .map((capability) => capability.value)
          .join("\n"),
    ),
  );

  @override
  MenuItem menuItem(WidgetRef ref, OperationTargets targets) {
    return MenuItem.command(
      command: commandOn(targets),
      icon: const Icones(MaterialSymbols.content_copy_rounded),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      // The id of the key's command, so the key presses it too; the button
      // types Copied, so it raises no toast.
      command: commandOn(fixedTargets(selection))
          .copyWith(run: ActionRun.press((_) => _copy(selection))),
      face: emphasis.face,
      icon: const Icones(MaterialSymbols.content_copy_rounded, size: 16),
      label: selection.length > 1 ? "Copy ${selection.length}" : "Copy",
      doneLabel: "Copied",
    );
  }
}
