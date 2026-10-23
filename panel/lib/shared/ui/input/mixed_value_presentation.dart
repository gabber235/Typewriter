import "package:typewriter_panel/typewriter_panel.dart";

const mixedValueReplacementMessage =
    "Changing this replaces all selected values.";

extension MixedValueInputDecoration on InputDecoration {
  InputDecoration get forMixedValue => copyWith(
    hintText: hintText ?? "Multiple values",
    helperText: helperText ?? mixedValueReplacementMessage,
  );
}

class MixedValueMessage extends StatelessWidget {
  const MixedValueMessage({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: context.spacing.space2,
      top: context.spacing.space1,
    ),
    child: Text(
      mixedValueReplacementMessage,
      style: Theme.of(context).inputDecorationTheme.helperStyle,
    ),
  );
}
