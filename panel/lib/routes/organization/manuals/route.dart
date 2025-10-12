import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/floating_button.dart";
import "package:typewriter_panel/widgets/generic/components/grid_selectable_card.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/vertical_clipper.dart";

@RoutePage()
class ManualsPage extends HookConsumerWidget {
  const ManualsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filtered = ref.watch(filteredManualsProvider(searchQuery.value));

    final padding =
        context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Inspector(
      margin: const EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "manuals",
        borderRadius: BorderRadius.circular(12),
        margin:
            EdgeInsets.only(top: 8, left: 8, right: context.isMobile ? 8 : 0),
        child: Section(
          margin: EdgeInsets.zero,
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: ref.read(manualsProvider.notifier).create,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                  child: const PageHeading(
                    title: "Manuals",
                    subtext:
                        "A manual defines the configuration for a Book (or a group of Books). It is restricted to certain Platform(s) with their Minecraft version targets. Additionally, it contains information about the Engine (version), which Extensions it has and their version.",
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DecoratedTextField(
                    focusNode: useFocusNode(),
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search manuals...",
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => searchQuery.value = v,
                  ),
                ),
                Expanded(
                  child: filtered(
                    name: "manuals",
                    builder: (manuals) {
                      if (manuals.isEmpty) {
                        return const Center(
                          child: Text(
                            "No manuals match your search",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }
                      return ClipPath(
                        clipper: const VerticalClipper(additionalWidth: 100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          child: ResponsiveGridView.builder(
                            gridDelegate: const ResponsiveGridDelegate(
                              crossAxisExtent: _manualCardWidth,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: _manualAspectRatio,
                            ),
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            itemCount: manuals.length,
                            itemBuilder: (context, index) {
                              final manual = manuals[index];
                              return _ManualCard(manual: manual);
                            },
                          ),
                        ),
                      );
                    },
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

const _manualCardWidth = 200.0;
const _manualCardHeight = 160.0;
const _manualAspectRatio = _manualCardWidth / _manualCardHeight;

class _ManualCard extends HookConsumerWidget {
  const _ManualCard({required this.manual});

  final Manual manual;

  Color _baseColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  String? _badgeLabel() {
    if (manual.platforms.isEmpty) return null;
    if (manual.platforms.length == 1) {
      return manual.platforms.first.platform.displayName.toUpperCase();
    }
    return "MULTI-PLATFORM";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectableId = ManualSelector(manual.id);
    final focusNode = useFocusNode();
    final base = _baseColor(context);
    final onBase = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return GridSelectableCard(
          title: manual.name,
          baseColor: base,
          onBaseColor: onBase,
          isSelected: isSelected,
          isFocused: isFocused,
          isHovered: isHovered,
          width: _manualCardWidth,
          height: _manualCardHeight,
          badgeLabel: _badgeLabel(),
          badgeColor: base.withValues(alpha: 0.90),
          badgeOnColor: onBase,
          titleStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(mobile: 14, tablet: 15, desktop: 16),
          ),
        );
      },
    );
  }
}
