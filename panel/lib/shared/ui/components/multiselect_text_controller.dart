part of "multiselect_dropdown.dart";

class _MultiSelectTextEditingController extends TextEditingController {
  _MultiSelectTextEditingController({
    required this.onSetLabels,
    required this.labelWidgetBuilder,
    super.text,
  });
  _MultiSelectTextEditingController.fromValue(
    super.value,
    this.onSetLabels,
    this.labelWidgetBuilder,
  ) : super.fromValue();

  final ChangeTags onSetLabels;
  final LabelWidgetBuilder labelWidgetBuilder;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final ranges = labelRanges(text);
    final children = <InlineSpan>[];

    var currentPosition = 0;

    for (final range in ranges) {
      if (currentPosition < range.start) {
        children.add(
          TextSpan(text: text.substring(currentPosition, range.start)),
        );
      }

      final labelText = text.substring(range.start + 1, range.end - 1);
      children.add(WidgetSpan(child: labelWidgetBuilder(context, labelText)));

      // Add zero-width spaces to account for the remaining characters.
      // WidgetSpan counts as 1 character, but the original text (including brackets)
      // is longer. We need to pad with invisible characters to fix cursor positioning.
      // See: https://github.com/flutter/flutter/issues/107432
      final originalLength = range.end - range.start;
      if (originalLength > 1) {
        children.add(TextSpan(text: "\u200b" * (originalLength - 1)));
      }

      currentPosition = range.end;
    }

    if (currentPosition < text.length) {
      children.add(TextSpan(text: text.substring(currentPosition)));
    }

    return TextSpan(style: style, children: children);
  }

  @override
  set value(TextEditingValue newValue) {
    if (!newValue.selection.isValid) {
      super.value = newValue;
      return;
    }

    final isTextSame = text == newValue.text;

    if (isTextSame) {
      _skipTagMovement(value, newValue);
      return;
    }

    _modifyTags(value, newValue);
  }

  void _skipTagMovement(
    TextEditingValue previousValue,
    TextEditingValue newValue,
  ) {
    assert(newValue.text == value.text);

    final previousSelection = previousValue.selection;
    final newSelection = newValue.selection;

    final previousBase = previousSelection.baseOffset;
    final newBase = newSelection.baseOffset;
    final previousExtent = previousSelection.extentOffset;
    final newExtent = newSelection.extentOffset;

    if (previousExtent == newExtent && previousBase == newBase) {
      super.value = newValue;
      return;
    }
    final ranges = labelRanges(text);

    final correctExtent = expandIndex(previousExtent, newExtent, ranges);

    if (newValue.selection.isCollapsed) {
      super.value = newValue.copyWith(
        selection: newSelection.copyWith(
          baseOffset: correctExtent,
          extentOffset: correctExtent,
        ),
      );
      return;
    }

    final correctedBase = expandIndex(previousBase, newBase, ranges);

    super.value = newValue.copyWith(
      selection: newValue.selection.copyWith(
        baseOffset: correctedBase,
        extentOffset: correctExtent,
      ),
    );
  }

  int expandIndex(int previousIndex, int newIndex, List<TextRange> ranges) {
    final range = ranges.firstWhereOrNull(
      (range) => range.start <= newIndex && newIndex < range.end,
    );
    if (range == null) return newIndex;
    final moveRight = previousIndex < newIndex;
    return moveRight ? range.end : range.start;
  }

  void _modifyTags(TextEditingValue value, TextEditingValue newValue) {
    assert(newValue.text != value.text);

    final oldRanges = labelRanges(value.text);
    final newRanges = labelRanges(newValue.text);

    final allRangesTheSame =
        oldRanges.length == newRanges.length &&
        oldRanges.indexed.every((e) {
          final (index, oldRange) = e;
          final newRange = newRanges[index];
          return oldRange.start == newRange.start &&
              oldRange.end == newRange.end;
        });

    if (allRangesTheSame) {
      super.value = newValue;
      return;
    }

    final newLabels = newRanges.map((range) {
      final rangeText = range.textInside(newValue.text);
      return rangeText.substring(1, rangeText.length - 1);
    }).toList();

    super.value = newValue;
    onSetLabels(newLabels);
  }

  static final tagRegex = RegExp(r"\[[^\]\[]+\]");
  List<TextRange> labelRanges(String text) {
    final ranges = <TextRange>[];
    final Iterable<Match> matches = tagRegex.allMatches(text);

    for (final match in matches) {
      ranges.add(TextRange(start: match.start, end: match.end));
    }

    return ranges;
  }
}
