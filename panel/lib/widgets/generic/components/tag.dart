import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/tag.dart" show Tag;
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/string.dart";

class TagWidget extends HookWidget {
  const TagWidget({
    required this.tag,
    this.backgroundColor,
    this.isExpanded = true,
    super.key,
  });

  final Tag tag;
  final Color? backgroundColor;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded
            ? backgroundColor ?? Theme.of(context).scaffoldBackgroundColor
            : tag.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tag.color.withValues(alpha: context.isDarkMode ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: tag.color,
            width: context.isDarkMode ? 1 : 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: isExpanded
              ? IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Text(
                        tag.name.formatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: tag.color,
                        ),
                      ),
                      for (final parent in tag.parents)
                        SizedBox(
                          width: double.infinity,
                          child: TagWidget(
                            tag: parent,
                            backgroundColor: backgroundColor,
                            isExpanded: isExpanded,
                            key: Key(parent.id),
                          ),
                        ),
                    ],
                  ),
                )
              : SizedBox(
                  width: 40,
                ),
        ),
      ),
    );
  }
}
