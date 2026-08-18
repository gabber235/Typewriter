import "package:typewriter_panel/typewriter_panel.dart";

final class SectionSearchSource extends DelegatingSearchSource {
  SectionSearchSource({
    required super.source,
    required this.id,
    required this.title,
    this.subtitle,
  }) : assert(id.isNotEmpty),
       assert(title.isNotEmpty);

  final String id;
  final String title;
  final String? subtitle;

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
            title: title,
            subtitle: subtitle,
            children: snapshot.nodes,
          ),
        ],
      ),
    );
  }
}

extension SectionSearchSourceX on SearchSource {
  SearchSource inSection({
    required String id,
    required String title,
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
