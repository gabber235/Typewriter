import "package:flutter/material.dart";

class Identifier extends StatelessWidget {
  const Identifier({
    required this.id,
    super.key,
  });
  final String id;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      id,
      style:
          Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
    );
  }
}
