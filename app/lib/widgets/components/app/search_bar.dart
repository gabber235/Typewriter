import "dart:math";

import "package:auto_size_text/auto_size_text.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:text_scroll/text_scroll.dart";
import "package:typewriter/hooks/staggered_animation_controllers.dart";
import "package:typewriter/hooks/ticker.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/staging.dart";
import "package:typewriter/utils/debouncer.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/page_search.dart";
import "package:typewriter/widgets/components/general/always_focused.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/decorated_text_field.dart";
import "package:typewriter/widgets/components/general/focused_notifier.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/shortcut_label.dart";

part "search_bar.freezed.dart";
part "search_bar.g.dart";

final searchProvider = StateNotifierProvider<SearchNotifier, Search?>(
  SearchNotifier.new,
  name: "searchProvider",
);

final _quantifierRegex = RegExp(r"!(\w+)");

@riverpod
Raw<FocusNode> searchBarFocus(Ref ref) {
  return FocusNode();
}

@riverpod
List<SearchElement> searchElements(Ref ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];

  final quantifiers =
      _quantifierRegex.allMatches(search.query).map((match) => match.group(0)!);

  final fullQuery = search.query;
  final query = quantifiers.fold(fullQuery, (query, quantifier) {
    return query.replaceFirst(quantifier, "");
  });

  final fetchers = search.fetchers.where((f) => f.canFetch(fullQuery));
  final actions = fetchers.expand((f) => f.fetch(ref.passing, query));
  final filtered =
      actions.where((e) => search.filters.every((f) => f.filter(e)));

  return filtered.toList();
}

@riverpod
List<SearchFetcher> searchFetchers(Ref ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];
  return search.fetchers;
}

@riverpod
List<SearchFilter> searchFilters(Ref ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];
  return search.filters;
}

@riverpod
List<FocusNode> searchFocusNodes(Ref ref) {
  final actionsCount =
      ref.watch(searchElementsProvider.select((value) => value.length));
  return List.generate(actionsCount, (_) => FocusNode());
}

@riverpod
List<GlobalKey> searchGlobalKeys(Ref ref) {
  final elements = ref.watch(searchElementsProvider);
  return elements.map((e) => GlobalKey(debugLabel: e.title)).toList();
}

@riverpod
SearchElement? _focusedElement(Ref ref) {
  final elements = ref.watch(searchElementsProvider);
  final focusNodes = ref.watch(searchFocusNodesProvider);

  final focusedIndex = focusNodes.indexWhere((node) => node.hasFocus);
  if (focusedIndex == -1) return null;

  return elements[focusedIndex];
}

@riverpod
List<SearchAction> _searchActions(Ref ref) {
  final focusedElement = ref.watch(_focusedElementProvider);

  return focusedElement?.actions(ref.passing) ?? [];
}

@riverpod
Set<ShortcutActivator> _searchActionShortcuts(Ref ref) {
  final elements = ref.watch(searchElementsProvider);
  final activators = elements
      .expand((e) => e.actions(ref.passing))
      .where((a) => a.onTrigger != null)
      .map((a) => a.shortcut)
      .toSet();
  return activators;
}

class ActivateActionIntent extends Intent {
  const ActivateActionIntent(this.shortcut);
  final ShortcutActivator shortcut;
}

enum FetchStatus {
  fetching,
  disabled,
  quantifierBlocked,
}

@freezed
class Search with _$Search {
  const factory Search({
    @Default("") String query,
    @Default([]) List<SearchFetcher> fetchers,
    @Default([]) List<SearchFilter> filters,
    Function()? onEnd,
  }) = _Search;
}

class SearchAction {
  const SearchAction(
    this.name,
    this.icon,
    this.shortcut, {
    this.color,
    this.onTrigger,
  });
  final String name;
  final String icon;

  final ShortcutActivator shortcut;
  final Color? color;
  final FutureOr<bool> Function(BuildContext, PassingRef ref)? onTrigger;
}

class SearchBar extends HookConsumerWidget {
  const SearchBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(_searchActionShortcutsProvider);

    return Shortcuts(
      shortcuts: {
        for (final shortcut in shortcuts)
          shortcut: ActivateActionIntent(shortcut),
      },
      child: Stack(
        children: [
          const _Barrier(),
          Actions(
            actions: {
              DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                onInvoke: (intent) => intent.direction == TraversalDirection.up
                    ? _changeFocusUp(
                        context,
                        ref.passing,
                      )
                    : _changeFocusDown(
                        context,
                        ref.passing,
                      ),
              ),
              NextFocusIntent: CallbackAction<NextFocusIntent>(
                onInvoke: (intent) => _changeFocusDown(context, ref.passing),
              ),
              PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                onInvoke: (intent) => _changeFocusUp(context, ref.passing),
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) => _activateItem(
                  ref.read(searchElementsProvider),
                  ref
                      .read(searchFocusNodesProvider)
                      .indexWhere((n) => n.hasFocus),
                  context,
                  ref.passing,
                ),
              ),
            },
            child: const Center(
              child: _Modal(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activateItem(
    List<SearchElement> actions,
    int index,
    BuildContext context,
    PassingRef ref,
  ) async {
    if (index >= actions.length) return;
    if (index < 0) return;
    final canEnd = await actions[index].activate(context, ref);
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }

  /// Change focus to the next/previous search result.
  void _changeFocus(
    BuildContext context,
    PassingRef ref,
    int index,
  ) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    final keys = ref.read(searchGlobalKeysProvider);
    FocusScope.of(context).requestFocus(focusNodes[index]);
    ref.invalidate(_focusedElementProvider);

    final indexContext = keys[index].currentContext;
    if (indexContext == null) return;
    Scrollable.ensureVisible(
      indexContext,
      alignment: 0.5,
      duration: 300.ms,
    );
  }

  void _changeFocusDown(BuildContext context, PassingRef ref) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    if (focusNodes.isEmpty) return;
    var index = focusNodes.indexWhere((n) => n.hasFocus);

    index = (index + 1) % focusNodes.length;

    _changeFocus(context, ref, index);
  }

  void _changeFocusUp(BuildContext context, PassingRef ref) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    if (focusNodes.isEmpty) return;
    var index = focusNodes.indexWhere((n) => n.hasFocus);
    if (index == -1) index = 0;

    index = (index - 1 + focusNodes.length) % focusNodes.length;
    _changeFocus(context, ref, index);
  }
}

class SearchBarWrapper extends HookConsumerWidget {
  const SearchBarWrapper({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        SmartSingleActivator(LogicalKeyboardKey.keyK, control: true):
            SearchIntent(),
        SmartSingleActivator(LogicalKeyboardKey.space, control: true):
            SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            const PreviousFocusIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const NextFocusIntent(),
        SmartSingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): const PublishPagesIntent(),
      },
      child: Actions(
        actions: {
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              ref.read(searchProvider.notifier).startGlobalSearch();
              return null;
            },
          ),
          PublishPagesIntent: CallbackAction<PublishPagesIntent>(
            onInvoke: (intent) {
              ref.read(communicatorProvider).publish();
              return null;
            },
          ),
        },
        child: AlwaysFocused(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              children: [
                child,
                const SearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchBuilder {
  SearchBuilder(this.notifier);
  var _currentSearch = const Search();
  final SearchNotifier notifier;

  void fetch(SearchFetcher fetcher) {
    _currentSearch = _currentSearch
        .copyWith(fetchers: [..._currentSearch.fetchers, fetcher]);
  }

  void filter(SearchFilter filter) {
    _currentSearch =
        _currentSearch.copyWith(filters: [..._currentSearch.filters, filter]);
  }

  void filters(List<SearchFilter> filters) {
    _currentSearch = _currentSearch.copyWith(filters: filters);
  }

  void open() {
    notifier.start(_currentSearch);
  }

  void query(String query) {
    _currentSearch = _currentSearch.copyWith(query: query);
  }
}

abstract class SearchElement {
  const SearchElement();

  String get title;

  List<SearchAction> actions(PassingRef ref);

  /// Runs when the element is activated.
  ///
  /// Returns true if the search should be closed.
  Future<bool> activate(BuildContext context, PassingRef ref);

  Color color(BuildContext context);

  String description(BuildContext context);

  Widget icon(BuildContext context);

  Widget suffixIcon(BuildContext context);
}

abstract class SearchFetcher {
  const SearchFetcher();

  Color get color => Colors.blueAccent;
  bool get disabled;
  String get icon => TWIcons.magnifyingGlass;

  /// Quantifiers are used to disable the fetcher using !\<quantifier>.
  /// When a quantifier is used, the fetcher will only be used if the search contains the quantifier.
  List<String> get quantifiers => const [];

  String get title;

  bool canFetch(String query) {
    return getFetchStatus(query) == FetchStatus.fetching;
  }

  SearchFetcher copyWith({
    bool? disabled,
  });

  List<SearchElement> fetch(PassingRef ref, String query) {
    return [];
  }

  FetchStatus getFetchStatus(String query) {
    if (!matchesQuantifier(query)) return FetchStatus.quantifierBlocked;
    if (disabled) return FetchStatus.disabled;
    return FetchStatus.fetching;
  }

  bool matchesQuantifier(String query) {
    final quantifiers =
        _quantifierRegex.allMatches(query).map((match) => match.group(1)!);
    return quantifiers.isEmpty || quantifiers.any(this.quantifiers.contains);
  }
}

abstract class SearchFilter {
  const SearchFilter();

  bool get canRemove;
  Color get color;
  String get icon;
  String get title;

  bool filter(SearchElement action) {
    return true;
  }
}

abstract class HiddenSearchFilter extends SearchFilter {
  const HiddenSearchFilter();
  @override
  Color get color => Colors.transparent;

  @override
  String get icon => TWIcons.asterisk;

  @override
  String get title => "";
}

/// When the user wants to search for nodes.
class SearchIntent extends Intent {}

class SearchNotifier extends StateNotifier<Search?> {
  SearchNotifier(this.ref) : super(null) {
    _debouncer = Debouncer<String>(duration: 200.ms, callback: _updateQuery);
  }
  final Ref ref;
  late Debouncer<String> _debouncer;

  SearchBuilder asBuilder() {
    return SearchBuilder(this);
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }

  void endSearch() {
    state?.onEnd?.call();
    state = null;
    _debouncer.cancel();
  }

  void removeFilter(SearchFilter filter) {
    state = state!
        .copyWith(filters: state!.filters.where((f) => f != filter).toList());
  }

  // ignore: use_setters_to_change_properties
  void start(Search search) {
    state = search;
  }

  void startAddSearch() => asBuilder()
    ..fetchNewEntry()
    ..fetchAddPage()
    ..nonGenericAddEntry(canRemove: false)
    ..open();

  void startGlobalSearch() => asBuilder()
    ..fetchNewEntry()
    ..fetchEntry()
    ..fetchPage()
    ..fetchAddPage()
    ..nonGenericAddEntry(canRemove: false)
    ..open();

  void toggleFetcher(SearchFetcher fetcher) {
    final fetchers = state?.fetchers;
    if (fetchers == null) return;
    final newFetchers = fetchers.map((f) {
      if (f.runtimeType == fetcher.runtimeType) {
        return f.copyWith(disabled: !f.disabled);
      }
      return f;
    }).toList();
    state = state!.copyWith(fetchers: newFetchers);
  }

  void updateQuery(String query) {
    _debouncer.run(query);
  }

  void _updateQuery(String query) {
    state = state!.copyWith(query: query);
  }
}

class VerticalClipper extends CustomClipper<Path> {
  const VerticalClipper({this.additionalWidth = 0});
  final double additionalWidth;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(-additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, size.height)
      ..lineTo(-additionalWidth, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is VerticalClipper) {
      return oldClipper.additionalWidth != additionalWidth;
    }
    return true;
  }
}

class _Barrier extends HookConsumerWidget {
  const _Barrier();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching =
        ref.watch(searchProvider.select((value) => value != null));

    return Positioned.fill(
      child: ModalBarrier(
        dismissible: true,
        color: Colors.black.withValues(alpha: 0.5),
        onDismiss: () {
          ref.read(searchProvider.notifier).endSearch();
        },
      )
          .animate(target: isSearching ? 1 : 0)
          .visibility(end: true, maintain: false, duration: 1.ms)
          .then()
          .fadeIn(duration: 300.ms),
    );
  }
}

class _Modal extends HookConsumerWidget {
  const _Modal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching =
        ref.watch(searchProvider.select((value) => value != null));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchFilters(),
                SizedBox(height: 12),
                _SearchBar(),
                SizedBox(height: 12),
                _SearchResults(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SearchActions(),
        ],
      )
          .animate(target: isSearching ? 1 : 0)
          .visibility(end: true, maintain: false, duration: 1.ms)
          .then()
          .scaleXY(duration: 200.ms, begin: 0.9, curve: Curves.easeOut)
          .fadeIn(),
    );
  }
}

class _FetcherChip extends HookConsumerWidget {
  const _FetcherChip({
    required this.fetcher,
  });

  final SearchFetcher fetcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query =
        ref.watch(searchProvider.select((value) => value?.query ?? ""));

    final status = fetcher.getFetchStatus(query);

    return Material(
      color: switch (status) {
        FetchStatus.fetching => fetcher.color,
        FetchStatus.quantifierBlocked => fetcher.color.withValues(alpha: 0.3),
        FetchStatus.disabled => Theme.of(context).cardColor,
      },
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: status != FetchStatus.quantifierBlocked
            ? () => ref.read(searchProvider.notifier).toggleFetcher(fetcher)
            : null,
        borderRadius: BorderRadius.circular(30),
        child: MouseRegion(
          cursor: status != FetchStatus.quantifierBlocked
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Iconify(
                  fetcher.icon,
                  color: status != FetchStatus.quantifierBlocked
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  fetcher.title,
                  style: TextStyle(
                    color: status != FetchStatus.quantifierBlocked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends HookConsumerWidget {
  const _ResultTile({
    required this.focusNode,
    required this.onPressed,
    this.color = Colors.white,
    this.icon = const Icon(Icons.search),
    this.suffixIcon = const Icon(Icons.arrow_forward_ios),
    this.title = "",
    this.description = "",
    this.actions = const [],
    super.key,
  });
  final FocusNode focusNode;
  final VoidCallback onPressed;
  final Color color;
  final Widget icon;

  final Widget suffixIcon;
  final String title;
  final String description;
  final List<SearchAction> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = useState(false);
    final hover = useState(false);
    return ContextMenuRegion(
      builder: (context) {
        return [
          for (final action
              in actions.where((action) => action.onTrigger != null))
            ContextMenuTile.button(
              title: action.name,
              icon: action.icon,
              color: action.color,
              onTap: () => _invokeAction(
                context,
                ref.passing,
                ActivateActionIntent(action.shortcut),
              ),
            ),
        ];
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) =>
                ref.read(searchBarFocusProvider).requestFocus(),
          ),
          ActivateActionIntent: CallbackAction<ActivateActionIntent>(
            onInvoke: (intent) => _invokeAction(context, ref.passing, intent),
          ),
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Material(
              color: Theme.of(context).cardColor,
              elevation: 2,
              child: AnimatedContainer(
                duration: 200.ms,
                curve: Curves.fastLinearToSlowEaseIn,
                height: 56.0,
                width: 400,
                color: focused.value
                    ? color.withValues(alpha: 0.6)
                    : Colors.transparent,
                child: Focus(
                  focusNode: focusNode,
                  autofocus: true,
                  canRequestFocus: true,
                  onFocusChange: (f) => focused.value = f,
                  child: FocusedNotifier(
                    focusNode: focusNode,
                    child: InkWell(
                      canRequestFocus: false,
                      onTap: onPressed,
                      onHover: (h) => hover.value = h,
                      child: Row(
                        children: [
                          Container(
                            height: double.infinity,
                            color: color.withValues(
                              alpha: color.a.clamp(0, 0.8),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: IconTheme(
                                data: const IconThemeData(color: Colors.white),
                                child: icon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  maxLines: 1,
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color:
                                            focused.value ? Colors.white : null,
                                        fontWeight: focused.value
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                ),
                                if (focused.value || hover.value)
                                  TextScroll(
                                    description,
                                    delayBefore: 1.seconds,
                                    pauseBetween: 3.seconds,
                                    intervalSpaces: 5,
                                    velocity: const Velocity(
                                      pixelsPerSecond: Offset(30, 0),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: focused.value
                                              ? Colors.white
                                              : null,
                                          fontWeight: focused.value
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                  )
                                else
                                  AutoSizeText(
                                    maxLines: 1,
                                    description,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: focused.value
                                              ? Colors.white
                                              : null,
                                          fontWeight: focused.value
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconTheme(
                            data: IconThemeData(
                              size: 14,
                              color: focused.value ? Colors.white : Colors.grey,
                            ),
                            child: suffixIcon,
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _invokeAction(
    BuildContext context,
    PassingRef ref,
    ActivateActionIntent intent,
  ) async {
    final action = actions
        .firstWhereOrNull((action) => action.shortcut == intent.shortcut);
    if (action == null) return;
    final canEnd = await action.onTrigger?.call(context, ref) ?? false;
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }
}

class _SearchActions extends HookConsumerWidget {
  const _SearchActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(_searchActionsProvider);

    if (actions.isEmpty) {
      return const SizedBox(height: 50);
    }

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Actions",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions) _SearchBarAction(action: action),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).animate().scaleXY(
          duration: 500.ms,
          begin: 0.95,
          end: 1,
          curve: Curves.elasticOut,
        );
  }
}

class _SearchBar extends HookConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchProvider);
    final controller = useTextEditingController(text: search?.query ?? "");
    final focusNode = ref.watch(searchBarFocusProvider);

    useEffect(
      () {
        focusNode.requestFocus();

        void listener() {
          ref.invalidate(_focusedElementProvider);
        }

        focusNode.addListener(listener);
        return () => focusNode.removeListener(listener);
      },
      [focusNode],
    );

    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (intent) => ref.read(searchProvider.notifier).endSearch(),
        ),
      },
      child: Material(
        elevation: 3.0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Iconify(
              TWIcons.magnifyingGlass,
              color: Theme.of(context).iconTheme.color,
            ),
            Expanded(
              child: DecoratedTextField(
                text: search?.query,
                controller: controller,
                focus: focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter search query...",
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (query) {
                  ref.read(searchProvider.notifier).updateQuery(query);
                },
                onSubmitted: (query) =>
                    ref.read(searchProvider.notifier).endSearch(),
              ),
            ),
            IconButton(
              icon: const Iconify(TWIcons.x),
              onPressed: () => ref.read(searchProvider.notifier).endSearch(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _SearchBarAction extends HookConsumerWidget {
  const _SearchBarAction({required this.action});
  final SearchAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = action.color ?? Theme.of(context).dividerColor;
    return Material(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: action.onTrigger != null
            ? () => _invokeAction(context, ref.passing)
            : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Iconify(
                action.icon,
                color: borderColor,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(action.name),
              const SizedBox(width: 6),
              ShortcutLabel(activator: action.shortcut),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _invokeAction(
    BuildContext context,
    PassingRef ref,
  ) async {
    final canEnd = await action.onTrigger?.call(context, ref) ?? false;
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }
}

class _SearchFilters extends HookConsumerWidget {
  const _SearchFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetchers = ref.watch(searchFetchersProvider);
    final filters = ref.watch(searchFiltersProvider);

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).cardColor,
          child: Iconify(
            TWIcons.filter,
            color: Theme.of(context).iconTheme.color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final fetcher in fetchers) _FetcherChip(fetcher: fetcher),
              for (final filter
                  in filters.where((f) => f is! HiddenSearchFilter))
                Material(
                  color: filter.color,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Iconify(
                          filter.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            filter.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        if (filter.canRemove) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            iconSize: 12,
                            splashRadius: 12,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              maxHeight: 24,
                              maxWidth: 24,
                            ),
                            onPressed: () => ref
                                .read(searchProvider.notifier)
                                .removeFilter(filter),
                            icon: const Iconify(
                              TWIcons.x,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatefulHookConsumerWidget {
  const _SearchResults();

  @override
  ConsumerState<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<_SearchResults> {
  @override
  Widget build(BuildContext context) {
    final animatedResults = min(8, ref.watch(searchElementsProvider).length);
    final elements = ref.watch(searchElementsProvider);
    final ticker = useTickerProvider();
    final controllers = useStaggeredAnimationControllers(
      count: animatedResults,
      duration: 1.seconds,
      interval: 50.ms,
      vsync: ticker,
    );
    final focusNodes = ref.watch(searchFocusNodesProvider);
    final globalKeys = ref.watch(searchGlobalKeysProvider);

    return Flexible(
      child: ClipPath(
        clipper: const VerticalClipper(additionalWidth: 100),
        child: ListView.builder(
          itemCount: elements.length,
          itemBuilder: (_, i) {
            final child = _ResultTile(
              key: globalKeys[i],
              onPressed: () => _activateItem(elements, i, context, ref.passing),
              focusNode: focusNodes[i],
              title: elements[i].title,
              color: elements[i].color(context),
              description: elements[i].description(context),
              icon: elements[i].icon(context),
              suffixIcon: elements[i].suffixIcon(context),
              actions: elements[i].actions(ref.passing),
            );

            if (i >= animatedResults) {
              return child;
            }

            return child
                .animate(controller: controllers[i], autoPlay: false)
                .scaleXY(
                  begin: 0.9,
                  curve: Curves.elasticOut,
                  duration: 1.seconds,
                )
                .fadeIn(duration: 500.ms);
          },
        ),
      ),
    );
  }

  Future<void> _activateItem(
    List<SearchElement> actions,
    int index,
    BuildContext context,
    PassingRef ref,
  ) async {
    if (index >= actions.length) return;
    if (index < 0) return;
    final canEnd = await actions[index].activate(context, ref);
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }
}
