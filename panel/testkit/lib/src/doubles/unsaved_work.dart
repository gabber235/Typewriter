import "package:typewriter_panel/typewriter_panel.dart";

/// An edit the user has not saved yet, which protects the work session: the
/// panel asks before navigation or sign out discards it.
///
/// It never saves or discards on its own, so the protection lasts until the
/// work session it belongs to ends.
final class UnsavedWork extends ChangeNotifier implements WorkDriver {
  @override
  final id = const WorkDriverId(domain: "test", scope: "unsaved");

  @override
  WorkDriverSnapshot get snapshot => WorkDriverSnapshot(
    entries: [
      WorkEntryState(
        id: WorkEntryId(driver: id, identity: "edit"),
        label: "Rename book",
        phase: "Unsaved",
        hasWork: true,
        blocksNavigation: true,
      ),
    ],
  );

  @override
  Future<void> save(WorkEntryId entry) async {}

  @override
  bool discard(WorkEntryId entry) => false;

  @override
  Future<void> retry(WorkEntryId entry) async {}
}
