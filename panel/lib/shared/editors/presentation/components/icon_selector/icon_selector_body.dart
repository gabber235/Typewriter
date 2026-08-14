part of "icon_selector.dart";

typedef _IconTraversal =
    void Function(SearchController controller, {required bool backwards});

class _IconSelectorBody extends HookConsumerWidget {
  const _IconSelectorBody({
    required this.value,
    required this.enabled,
    required this.readOnly,
    required this.editing,
    required this.inputController,
    required this.validationMessage,
    required this.onStartEditing,
    required this.onPreview,
    required this.onSubmit,
    required this.onDismiss,
    required this.onDone,
    required this.onAcceptTraversal,
  });

  final String value;
  final bool enabled;
  final bool readOnly;
  final bool editing;
  final InputFieldController inputController;
  final String? validationMessage;
  final VoidCallback onStartEditing;
  final ValueChanged<String> onPreview;
  final void Function(String text, SearchController? controller) onSubmit;
  final VoidCallback onDismiss;
  final ValueChanged<String> onDone;
  final _IconTraversal onAcceptTraversal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final scrollController = useScrollController();
    final icon = IconValue.from(value);
    final rows = controller.snapshot.nodes
        .walk()
        .whereType<SearchResultNode>()
        .map((node) => node.result)
        .toList(growable: false);

    void navigate(int Function(int current, int length) destination) {
      if (rows.isEmpty) return;
      final current = rows.indexWhere(
        (result) => result.id == controller.currentPreview?.id,
      );
      final index = destination(current, rows.length).clamp(0, rows.length - 1);
      final result = rows[index];
      controller.preview(result);
      final payload = result.payload;
      if (payload is IconSearchResultPayload) onPreview(payload.identifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final target = (index * _iconResultExtent).clamp(
          0.0,
          scrollController.position.maxScrollExtent,
        );
        scrollController.animateTo(
          target,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : 200.ms,
          curve: Curves.easeOutCubic,
        );
      });
    }

    return ManagedActionSet(
      shortcuts: editing
          ? _iconNavigationShortcuts(
              controller: controller,
              navigate: navigate,
              onSubmit: onSubmit,
              onAcceptTraversal: onAcceptTraversal,
            )
          : const [],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editing)
            DecoratedTextField(
              key: const ValueKey("icon_selector_idle"),
              inputFieldController: inputController,
              text: icon is SvgIconValue ? "Custom SVG" : value,
              readOnly: true,
              enabled: enabled,
              onInputFocus: onStartEditing,
              decoration: InputDecoration(
                prefixIcon: _IconFieldPreview(icon: icon),
              ),
            )
          else
            QueryBar(
              key: const ValueKey("icon_selector_query"),
              inputFieldController: inputController,
              query: controller.query,
              selectors: controller.selectors,
              onQueryChanged: controller.updateQuery,
              onSubmitted: (text) => onSubmit(text, controller),
              onEditingComplete: () {},
              onDone: onDone,
              onDismiss: onDismiss,
              onInputFocus: controller.refresh,
              selectAllOnFocus: true,
              inputDecoration: InputDecoration(
                hintText: "Search icons",
                errorText: validationMessage,
                prefixIcon: _IconFieldPreview(icon: icon),
                suffixIcon: _IconSearchStatus(controller: controller),
              ),
            ),
          _IconSelectorResults(
            visible: editing,
            controller: scrollController,
            results: rows,
          ),
        ],
      ),
    );
  }
}

List<ActionShortcut> _iconNavigationShortcuts({
  required SearchController controller,
  required void Function(int Function(int current, int length)) navigate,
  required void Function(String text, SearchController? controller) onSubmit,
  required _IconTraversal onAcceptTraversal,
}) => [
  _navigationShortcut("icon_accept", const [
    SingleActivator(LogicalKeyboardKey.enter),
  ], () => onSubmit(controller.query, controller)),
  _navigationShortcut(
    "icon_previous",
    const [
      SingleActivator(LogicalKeyboardKey.arrowUp),
      SingleActivator(LogicalKeyboardKey.keyP, control: true),
    ],
    () => navigate((current, length) => current < 0 ? length - 1 : current - 1),
  ),
  _navigationShortcut("icon_next", const [
    SingleActivator(LogicalKeyboardKey.arrowDown),
    SingleActivator(LogicalKeyboardKey.keyN, control: true),
  ], () => navigate((current, length) => current < 0 ? 0 : current + 1)),
  _navigationShortcut("icon_first", const [
    SingleActivator(LogicalKeyboardKey.home),
  ], () => navigate((current, length) => 0)),
  _navigationShortcut("icon_last", const [
    SingleActivator(LogicalKeyboardKey.end),
  ], () => navigate((current, length) => length - 1)),
  _navigationShortcut("icon_page_previous", const [
    SingleActivator(LogicalKeyboardKey.pageUp),
  ], () => navigate((current, length) => current < 0 ? 0 : current - 5)),
  _navigationShortcut("icon_page_next", const [
    SingleActivator(LogicalKeyboardKey.pageDown),
  ], () => navigate((current, length) => current < 0 ? 4 : current + 5)),
  _navigationShortcut("icon_accept_next", const [
    SingleActivator(LogicalKeyboardKey.tab),
  ], () => onAcceptTraversal(controller, backwards: false)),
  _navigationShortcut("icon_accept_previous", const [
    SingleActivator(LogicalKeyboardKey.tab, shift: true),
  ], () => onAcceptTraversal(controller, backwards: true)),
];
