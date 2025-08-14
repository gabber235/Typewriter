import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/decorated_text_field.dart"
    hide useFocusNode;
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/retry_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/vertical_clipper.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

@RoutePage()
class ModulesPage extends HookConsumerWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filtered = ref.watch(filteredModulesProvider(searchQuery.value));

    final padding =
        context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "modules",
        borderRadius: BorderRadius.circular(12),
        margin:
            EdgeInsets.only(top: 8, left: 8, right: context.isMobile ? 8 : 0),
        child: Section(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: const PageHeading(
                  title: "Modules",
                  subtext:
                      "Engines and extensions available for this organization.",
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedTextField(
                  focusNode: useFocusNode(),
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search modules...",
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) => searchQuery.value = v,
                ),
              ),
              Expanded(
                child: filtered.when(
                  data: (modules) {
                    if (modules.isEmpty) {
                      return const Center(
                        child: Text(
                          "No modules match your search",
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }
                    return ClipPath(
                      clipper: VerticalClipper(additionalWidth: 100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: ResponsiveGridView.builder(
                          gridDelegate: const ResponsiveGridDelegate(
                            crossAxisExtent: _moduleCardWidth,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: _moduleAspectRatio,
                          ),
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          itemCount: modules.length,
                          itemBuilder: (context, index) {
                            final module = modules[index];
                            return _ModuleCard(module: module);
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LoadingIndicator(
                    message: "Loading modules...",
                  ),
                  error: (error, stack) => ErrorScreen(
                    title: "Failed to load modules",
                    message: error.toString(),
                    child: const RetryIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _moduleCardWidth = 200.0;
const _moduleCardHeight = 160.0;
const _moduleAspectRatio = _moduleCardWidth / _moduleCardHeight;

class _ModuleCard extends HookConsumerWidget {
  const _ModuleCard({required this.module});

  final Module module;

  Color _baseColor(BuildContext context) {
    return context.isDarkMode ? module.kind.darkColor : module.kind.lightColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectableId = ModuleSelector(module.id);
    final focusNode = useFocusNode();
    final base = _baseColor(context);
    final onBase = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastEaseInToSlowEaseOut,
          width: _moduleCardWidth,
          height: _moduleCardHeight,
          decoration: BoxDecoration(
            color: isSelected
                ? isFocused
                    ? base.withValues(alpha: 0.80)
                    : base
                : base.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 2,
              color: isFocused ? base : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModuleKindBadge(
                label: module.kind.name.toUpperCase(),
                isSelected: isSelected,
                color: base.withValues(alpha: 0.90),
                onColor: onBase,
              ),
              const Spacer(),
              Text(
                module.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:
                      context.responsive(mobile: 14, tablet: 15, desktop: 16),
                  color: isSelected ? onBase : base,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleKindBadge extends StatelessWidget {
  const _ModuleKindBadge({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onColor,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: ShapeDecoration(
        color: isSelected ? onColor : color,
        shape: StadiumBorder(),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontVariations: [boldWeight],
          letterSpacing: 0.7,
          color: isSelected ? color : onColor,
        ),
      ),
    );
  }
}
