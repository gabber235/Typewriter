import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds one item in a selector content surface.
typedef SelectorItemBuilder<T> = Widget Function(T item);

/// Builds selector contents and closes the owning popup through [onSelect].
typedef SelectorContentBuilder<T> = Widget Function(
  List<T> items,
  T? selected,
  void Function(T) onSelect,
);

/// Displays asynchronous choices in an anchored desktop popup or a mobile
/// bottom sheet. Loading and failure states stay visible at the selector
/// boundary instead of being interpreted as an empty choice list.
class SelectorPopup<T> extends ConsumerWidget {
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
    final items = asyncValue;

    return items(
      name: name,
      builder: (itemsList) {
        return _SelectorButton<T>(
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

/// Selector variant that waits for both choices and the current selection
/// before opening the shared content surface.
class SelectorPopupWithSelection<T> extends ConsumerWidget {
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
    return selectedAsync(
      name: name,
      builder: (selected) {
        return itemsAsync(
          name: name,
          builder: (items) {
            return _SelectorButton<T>(
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

class _SelectorButton<T> extends StatelessWidget {
  const _SelectorButton({
    required this.buttonBuilder,
    required this.contentBuilder,
    required this.items,
    required this.selected,
    super.key,
  });

  final Widget Function(T? selected) buttonBuilder;
  final SelectorContentBuilder<T> contentBuilder;
  final List<T> items;
  final T? selected;

  @override
  Widget build(BuildContext context) => AnchoredPopup(
    popupBuilder: (ctx, close) => SelectionOperationsRoot(
      operations: SelectionOperationsRoot.of(context),
      child: GlobalModeShortcut(
        child: GlobalOperationShortcuts(
          child: contentBuilder(items, selected, (_) => close()),
        ),
      ),
    ),
    builder: (context, show) => Material(
      shape: RoundedRectangleBorder(
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      child: InkWell(
        onTap: () => context.isMobile ? _showMobileMenu(context) : show(),
        borderRadius: context.shapes.mediumBorderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: buttonBuilder(selected),
        ),
      ),
    ),
  );

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _MobileMenu<T>(
          contentBuilder: contentBuilder,
          items: items,
          selected: selected,
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

/// Search input whose value is owned by the surrounding selector content.
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
      padding: EdgeInsets.all(context.spacing.space3),
      child: EditorTextField(
        focusNode: focusNode,
        autofocus: EditorTextFieldAutoFocus.surroundingField,
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

/// Label for a grouped selector section.
class SelectorSectionHeader extends StatelessWidget {
  const SelectorSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        0,
        context.spacing.space4,
        context.spacing.space2,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
