import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/global_mode_shortcut.dart";
import "package:typewriter_panel/widgets/generic/components/modal_header.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";

typedef SelectorItemBuilder<T> = Widget Function(T item);
typedef SelectorContentBuilder<T> =
    Widget Function(List<T> items, T? selected, void Function(T) onSelect);

class SelectorPopup<T> extends HookConsumerWidget {
  const SelectorPopup({
    required this.asyncValue,
    required this.buttonBuilder,
    required this.contentBuilder,
    this.name = "items",
    super.key,
  });

  final AsyncValue<List<T>> asyncValue;
  final Widget Function(T? selected) buttonBuilder;
  final SelectorContentBuilder<T> contentBuilder;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = useRef(LayerLink());
    final items = asyncValue;

    return items(
      name: name,
      builder: (itemsList) {
        return _SelectorButton<T>(
          link: link.value,
          buttonBuilder: buttonBuilder,
          contentBuilder: contentBuilder,
          items: itemsList,
          selected: null,
        );
      },
      loading: (_) => ShimmerBox.rectangle(width: 200, height: 40),
      error: (title, error) => Text(error),
    );
  }
}

class SelectorPopupWithSelection<T> extends HookConsumerWidget {
  const SelectorPopupWithSelection({
    required this.itemsAsync,
    required this.selectedAsync,
    required this.buttonBuilder,
    required this.contentBuilder,
    this.name = "items",
    super.key,
  });

  final AsyncValue<List<T>> itemsAsync;
  final AsyncValue<T?> selectedAsync;
  final Widget Function(T? selected) buttonBuilder;
  final SelectorContentBuilder<T> contentBuilder;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = useRef(LayerLink());

    return selectedAsync(
      name: name,
      builder: (selected) {
        return itemsAsync(
          name: name,
          builder: (items) {
            return _SelectorButton<T>(
              link: link.value,
              buttonBuilder: buttonBuilder,
              contentBuilder: contentBuilder,
              items: items,
              selected: selected,
            );
          },
          loading: (_) => ShimmerBox.rectangle(width: 200, height: 40),
          error: (title, error) => Text(error),
        );
      },
      loading: (_) => ShimmerBox.rectangle(width: 200, height: 40),
      error: (title, error) => Text(error),
    );
  }
}

class _SelectorButton<T> extends HookWidget {
  const _SelectorButton({
    required this.link,
    required this.buttonBuilder,
    required this.contentBuilder,
    required this.items,
    required this.selected,
    super.key,
  });

  final LayerLink link;
  final Widget Function(T? selected) buttonBuilder;
  final SelectorContentBuilder<T> contentBuilder;
  final List<T> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: CompositedTransformTarget(
        link: link,
        child: InkWell(
          onTap: () => _showMenu(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: buttonBuilder(selected),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    if (context.isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return UncontrolledProviderScope(
            container: ProviderScope.containerOf(context),
            child: _MobileMenu<T>(
              contentBuilder: contentBuilder,
              items: items,
              selected: selected,
            ),
          );
        },
      );
      return;
    }
    Navigator.of(context).push(
      _PopupRoute<T>(
        link: link,
        themes: InheritedTheme.capture(
          from: context,
          to: Navigator.of(context).context,
        ),
        child: UncontrolledProviderScope(
          container: ProviderScope.containerOf(context),
          child: GlobalModeShortcut(
            child: GlobalOperationShortcuts(
              child: contentBuilder(
                items,
                selected,
                (item) => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenu<T> extends StatelessWidget {
  const _MobileMenu({
    required this.contentBuilder,
    required this.items,
    required this.selected,
    super.key,
  });

  final SelectorContentBuilder<T> contentBuilder;
  final List<T> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalHeader(),
            Expanded(
              child: contentBuilder(
                items,
                selected,
                (item) => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupRoute<T> extends PopupRoute<void> {
  _PopupRoute({required this.link, required this.child, required this.themes});

  final LayerLink link;
  final Widget child;
  final CapturedThemes themes;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 60);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(
      Stack(
        children: [
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            followerAnchor: Alignment.topLeft,
            targetAnchor: Alignment.bottomLeft,
            child: FadeTransition(
              opacity: animation,
              child: Builder(
                builder: (context) {
                  return Material(
                    elevation: 4,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                        maxHeight: 420,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectorSearchField extends HookWidget {
  const SelectorSearchField({
    required this.searchQuery,
    required this.hintText,
    super.key,
  });

  final ValueNotifier<String> searchQuery;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DecoratedTextField(
        focusNode: focusNode,
        autofocus: DecoratedTextFieldAutoFocus.surroundingField,
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class SelectorSectionHeader extends StatelessWidget {
  const SelectorSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
