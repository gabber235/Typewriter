import "package:flutter/material.dart";

class LabeledDivider extends StatelessWidget {
  const LabeledDivider({
    super.key,
    this.text = "OR",
    this.direction = Axis.horizontal,
    this.textStyle,
    this.dividerColor,
    this.dividerThickness = 2.0,
  });

  final String text;
  final Axis direction;
  final TextStyle? textStyle;
  final Color? dividerColor;
  final double dividerThickness;

  @override
  Widget build(BuildContext context) {
    final dividerColor = this.dividerColor ??
        DividerTheme.of(context).color ??
        Theme.of(context).dividerColor;

    final divider = Expanded(
      child: direction == Axis.horizontal
          ? Divider(
              color: dividerColor,
              thickness: dividerThickness,
            )
          : VerticalDivider(
              color: dividerColor,
              thickness: dividerThickness,
            ),
    );
    final textWidget = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: direction == Axis.horizontal ? 8.0 : 0.0,
        vertical: direction == Axis.vertical ? 8.0 : 0.0,
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: dividerColor,
            ),
        child: Text(
          text,
          style: textStyle,
        ),
      ),
    );

    if (direction == Axis.horizontal) {
      return Row(
        children: [
          divider,
          textWidget,
          divider,
        ],
      );
    } else {
      return Column(
        children: [
          divider,
          textWidget,
          divider,
        ],
      );
    }
  }
}
