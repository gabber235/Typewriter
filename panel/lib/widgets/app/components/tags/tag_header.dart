import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";

class TagHeader extends HookConsumerWidget {
  const TagHeader({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColor = tag.color.value != 0
        ? Color(tag.color.value)
        : Colors.grey;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tag.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
