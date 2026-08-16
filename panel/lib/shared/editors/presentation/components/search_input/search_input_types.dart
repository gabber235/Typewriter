part of "search_input.dart";

typedef PresentationSearchSourceBuilder =
    SearchSource Function(
      Ref ref,
      Stream<PresentationSearchSelectionEvent> selections,
    );
