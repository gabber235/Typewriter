import "package:typewriter_panel/typewriter_panel.dart";

/// Reissues the last search context when a source's external inputs change.
///
/// The source initializes and disposes these listeners with its own lifetime.
/// [search] records the latest context without issuing it; change notifications
/// invoke the supplied search callback after the optional change hook.
class SearchRefresher {
  new(this.listerners, this._search, {this._onChange});

  final List<ValueListenable> listerners;
  final Function(SearchQueryContext) _search;
  final Function()? _onChange;

  SearchQueryContext _lastSearchContext = SearchQueryContext.empty;

  void initialize(SearchQueryContext initialContext) {
    _lastSearchContext = initialContext;
    for (final listener in listerners) {
      listener.addListener(_handleChange);
    }
  }

  void _handleChange() {
    _onChange?.call();
    _search(_lastSearchContext);
  }

  // ignore: use_setters_to_change_properties
  void search(SearchQueryContext context) {
    _lastSearchContext = context;
  }

  void dispose() {
    for (final listener in listerners) {
      listener.removeListener(_handleChange);
    }
  }
}
