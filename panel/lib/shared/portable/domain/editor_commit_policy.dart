/// Selects which local editor boundary triggers persistence.
///
/// [autosaveChanges] lets the owner flush eligible paths after local changes.
/// [applyResource] keeps the draft local until an explicit resource apply, so
/// the whole resource can be submitted as one consistency boundary.
enum EditorCommitPolicy { autosaveChanges, applyResource }
