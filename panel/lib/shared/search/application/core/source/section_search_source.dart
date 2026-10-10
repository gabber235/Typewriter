import "package:typewriter_panel/typewriter_panel.dart";

/// Wraps nonempty child results in one top level section.
///
/// Empty snapshots pass through unchanged so loading, idle, and error states do
/// not create an empty heading in the result tree.
final class SectionSearchSource extends DelegatingSearchSource {
  SectionSearchSource({
    required super.source,
    required this.id,
    required this.title,
    this.subtitle,
  }) : assert(id.isNotEmpty);

  final String id;
  final String Function(SearchQueryContext context) title;
  final String? subtitle;
  String _activeTitle = "";

  void _selectContext(SearchQueryContext context) {
    final resolved = title(context);
    if (resolved.isEmpty) {
      throw ArgumentError.value(resolved, "title", "must not be empty");
    }
    _activeTitle = resolved;
  }

  @override
  void initialize(SearchQueryContext context) {
    _selectContext(context);
    super.initialize(context);
  }

  @override
  void search(SearchQueryContext context) {
    _selectContext(context);
    super.search(context);
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    if (snapshot.nodes.isEmpty) {
      emit(snapshot);
      return;
    }

    emit(
      snapshot.copyWith(
        nodes: [
          SearchNode.section(
            id: id,
            title: _activeTitle,
            subtitle: subtitle,
            children: snapshot.nodes,
          ),
        ],
      ),
    );
  }
}

/// Adds a presentation section around a source's results.
extension SectionSearchSourceX on SearchSource {
  SearchSource inSection({
    required String id,
    required String Function(SearchQueryContext context) title,
    String? subtitle,
  }) {
    return SectionSearchSource(
      source: this,
      id: id,
      title: title,
      subtitle: subtitle,
    );
  }
}
