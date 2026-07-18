import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";

class Title extends StatelessWidget {
  const Title({
    required this.title,
    required this.color,
    this.isDeprecated = false,
    super.key,
  });
  final String title;
  final Color color;
  final bool isDeprecated;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      title,
      style: TextStyle(
        color: color,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        decoration: isDeprecated ? TextDecoration.lineThrough : null,
        decorationThickness: 2.8,
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: color,
      ),
      maxLines: 1,
    );
  }
}
