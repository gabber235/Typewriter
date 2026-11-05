import "package:typewriter_panel/typewriter_panel.dart";

/// A work driver of [domain] in the scope `same realm` holding one retained
/// entry "Retained work" while [dirty]; saving, discarding or retrying it
/// settles it. It counts its disposals and calls [onDispose] on each.
final class FakeWorkDriver extends ChangeNotifier implements WorkDriver {
  FakeWorkDriver({this.domain = "fixture", this.dirty = true});
  final String domain;
  bool dirty;
  int disposals = 0;
  VoidCallback? onDispose;
  @override
  WorkDriverId get id => WorkDriverId(domain: domain, scope: "same realm");
  @override
  WorkDriverSnapshot get snapshot => WorkDriverSnapshot(
    entries: [
      if (dirty)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: "entry"),
          label: "Retained work",
          phase: "Local changes",
          retained: dirty,
          hasWork: dirty,
        ),
    ],
  );
  void settled() {
    dirty = false;
    notifyListeners();
  }

  @override
  Future<void> save(WorkEntryId entry) async => settled();
  @override
  bool discard(WorkEntryId entry) {
    settled();
    return true;
  }

  @override
  Future<void> retry(WorkEntryId entry) async => settled();
  @override
  void dispose() {
    disposals++;
    onDispose?.call();
    super.dispose();
  }
}
