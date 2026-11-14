import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// The failures the panel reported, whether they still float as toasts or
/// already landed in Activity: settling lets a toast drain, so a test reads
/// what was reported rather than what is on screen.
extension ReportedFailures on PanelDriver {
  /// Each reported failure, oldest first, read as its title and its reason.
  List<String> get failures => [
    for (final notice in container.read(noticesProvider))
      if (notice.tone == NoticeTone.failure)
        [notice.title, ?notice.detail].join(". "),
  ];
}
