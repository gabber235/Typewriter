import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/finders.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The save activity: the status control in the app bar and the list of
/// drafts and submissions it opens.
final class SaveActivityDriver extends ComponentDriver {
  SaveActivityDriver(super.tester);

  /// Whether the activity list is open.
  bool get isOpen => shows("Save activity");

  /// Opens the activity list through the status control that reads [status],
  /// such as `Needs attention` or `1 draft`.
  Future<void> open(String status) => tapOn(labeled(status).first);

  /// Closes the activity list with its close button.
  Future<void> close() async {
    if (!isOpen) throw TestFailure("The save activity is not open");
    await tapOn(find.tooltip("Close").last);
  }

  /// The entry whose title reads [title].
  SaveActivityEntryDriver entry(String title) =>
      SaveActivityEntryDriver(tester, title);
}

/// One draft or submission in the open save activity.
final class SaveActivityEntryDriver extends ComponentDriver {
  SaveActivityEntryDriver(super.tester, this.title);

  final String title;

  /// The semantics node the entry's title belongs to: its header.
  ///
  /// Read from the visible title, since the semantics finder does not reach
  /// into the desktop popup the activity opens in.
  SemanticsNode get _header => tester.getSemantics(find.text(title).first);

  /// The header when it discloses details; its label reads the title and the
  /// summary.
  SemanticsNode? get _disclosure {
    final header = _header;
    return header.isButton && header.spoken.startsWith("$title. ")
        ? header
        : null;
  }

  /// Whether the entry offers details to expand.
  bool get hasDetails => _disclosure != null;

  /// Whether the entry shows its details.
  bool get isExpanded =>
      _disclosure?.getSemanticsData().flagsCollection.isExpanded ==
      Tristate.isTrue;

  /// Expands or collapses the details, the way a click on the header does.
  Future<void> toggleDetails() async {
    final header =
        _disclosure ??
        (throw TestFailure("The activity entry $title has no details"));
    await tester.tapAt(header.screenRect.center);
    await settle();
  }

  /// Copies the entry's problem report to the clipboard.
  Future<void> copyReport() => tapOn(find.tooltip("Copy problem report").first);
}

/// The save activity of [session] in an app bar, for work that lives in a
/// session of its own rather than the panel's local work.
PanelLocation saveActivityOf(ScopedWorkSession session) =>
    PanelLocation.component(
      Scaffold(
        appBar: AppBar(
          actions: [ScopedWorkSessionActivityView(controller: session)],
        ),
      ),
    );

/// The save activity of the panel.
extension SaveActivityOnPanel on PanelDriver {
  /// The save activity in the app bar.
  SaveActivityDriver get activity => SaveActivityDriver(tester);
}
