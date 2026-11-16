import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns composite editors created while assembling one inspection model.
///
/// A build is provisional until [InspectionSession] installs its result. If a
/// definition fails or throws, editors created during that build are disposed
/// without affecting the previously installed graph. The session disposes the
/// committed context when the next graph replaces it.
final class InspectionBuildContext {
  InspectionBuildContext(this.owners);

  final InspectionBindingRefresh owners;
  final List<MultiEditOwner> _multiEditors = [];
  final Set<PortablePresentationHost> _hosts = {};

  InspectionContent ownHosts(InspectionContent content) {
    if (content.host case final host?) _hosts.add(host);
    _hosts.addAll(content.additionalHosts);
    return content;
  }

  void releaseHosts(Iterable<PortablePresentationHost> hosts) {
    _hosts.removeAll(hosts);
  }

  /// Creates and registers a composite owner over the selected [owners].
  ///
  /// The returned owner is valid for this build context only. The individual
  /// owners remain owned by the editor owner registry.
  MultiEditOwner multiEditorForOwners(
    Iterable<EditOwner> owners, {
    required skir.TypeUse rootType,
    required CheckedEditorCatalog catalog,
  }) {
    final editor = MultiEditOwner(
      owners: owners.toList(growable: false),
      rootType: rootType,
      catalog: catalog,
    );
    _multiEditors.add(editor);
    return editor;
  }

  void _rollbackTo(int checkpoint) {
    final abandoned = _multiEditors.sublist(checkpoint);
    _multiEditors.removeRange(checkpoint, _multiEditors.length);
    for (final editor in abandoned) {
      editor.dispose();
    }
  }

  /// Disposes every composite owner and portable host created by this context.
  void dispose() {
    _rollbackTo(0);
    for (final host in _hosts) {
      host.dispose();
    }
    _hosts.clear();
  }
}
