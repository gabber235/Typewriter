import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Stable page identity in the navigation tree, independent of editor validity.
class PageNavigationLabel extends StatelessWidget {
  const PageNavigationLabel({
    required this.name,
    this.icon,
    this.expanded = true,
    this.issues = const [],
    this.checking = false,
    this.unavailable = false,
    super.key,
  });

  final String name;
  final skir.Icon? icon;
  final bool expanded;
  final List<ResourceIssue> issues;
  final bool checking;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final foreground = Surface.foregroundOf(context);
    final marker = icon?.iconValue == null
        ? Icon(Icons.description_outlined, size: 11, color: foreground)
        : ResourceIcon(icon: icon, size: 11, color: foreground);
    final badge = ResourceIssueBadge(
      issues: issues,
      checking: checking,
      unavailable: unavailable,
    );
    return Tooltip(
      message: name,
      triggerMode: TooltipTriggerMode.manual,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space2),
        child: expanded
            ? Row(
                children: [
                  SizedBox(width: context.spacing.space1),
                  marker,
                  SizedBox(width: context.spacing.space2),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.space2),
                  badge,
                  Icon(Icons.chevron_right, size: 16, color: foreground),
                ],
              )
            : Semantics(
                label: name,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [marker, badge],
                ),
              ),
      ),
    );
  }
}
