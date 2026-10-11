import "package:typewriter_panel/typewriter_panel.dart";

/// Controller scoped to one search surface.
///
/// The nullable default allows the provider to exist as a dependency anchor;
/// [SearchRoot] supplies the actual controller for its subtree.
/// This provider stays manual because each SearchRoot supplies a scoped
/// ChangeNotifier value.
final searchProvider = ChangeNotifierProvider<SearchController<dynamic>?>(
  (ref) => null,
  dependencies: [],
  disposeNotifier: false,
);

/// Creates and owns the controller visible to [child].
///
/// The default constructor owns the created controller and disposes it with the
/// scope. [SearchRoot.borrowed] only publishes a controller whose caller owns
/// its complete lifetime.
class SearchRoot extends StatefulWidget {
  const SearchRoot({required this.create, required this.child, super.key})
    : controller = null;

  const SearchRoot.borrowed({
    required SearchController<dynamic> this.controller,
    required this.child,
    super.key,
  }) : create = null;

  final Widget child;
  final SearchController<dynamic> Function(Ref ref)? create;
  final SearchController<dynamic>? controller;

  @override
  State<SearchRoot> createState() => _SearchRootState();
}

final class _SearchRootState extends State<SearchRoot> {
  SearchController<dynamic>? _owned;

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        searchProvider.overrideWith(
          (ref) => widget.controller ?? (_owned ??= widget.create!(ref)),
        ),
      ],
      child: widget.child,
    );
  }
}
