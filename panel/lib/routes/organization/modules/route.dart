import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/generated/models/module.pb.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/logic/modules/module_type_extensions.dart";
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
class ModulesPage extends HookConsumerWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filtered = ref.watch(filteredModulesProvider(searchQuery.value));

    final padding = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "modules",
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.only(
          top: 8,
          left: 8,
          right: context.isMobile ? 8 : 0,
        ),
        child: Section(
          margin: EdgeInsets.zero,
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                  child: const PageHeading(
                    title: "Modules",
                    subtext:
                        "Modules are artifacts for the Typewriter system such as Engines or Extensions. Version release cycles can be managed here, while information about the module is handle inside the module setup itself, like in gradle.",
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (v) => searchQuery.value = v,
                  ),
                ),
                Expanded(
                  child: filtered(
                    name: "modules",
                    builder: (modules) {
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

const _moduleCardWidth = 200.0;
const _moduleCardHeight = 160.0;
const _moduleAspectRatio = _moduleCardWidth / _moduleCardHeight;

class _ModuleCard extends HookConsumerWidget {
  const _ModuleCard({required this.module});

  final Module module;

  Color _baseColor(BuildContext context) {
    return module.type.themedColor(context);
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
        return GridSelectableCard(
          title: module.name,
          baseColor: base,
          onBaseColor: onBase,
          isSelected: isSelected,
          isFocused: isFocused,
          isHovered: isHovered,
          width: _moduleCardWidth,
          height: _moduleCardHeight,
          badgeLabel: module.type.displayName,
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
