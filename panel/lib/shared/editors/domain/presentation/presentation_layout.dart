part of "presentation_element.dart";

enum PresentationMainAxisAlignment {
  start,
  center,
  end,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum PresentationCrossAxisAlignment { start, center, end, stretch }

abstract interface class ChildrenLayoutElement {
  List<PresentationNode> get children;
  double get spacing;
  PresentationMainAxisAlignment get mainAxisAlignment;
  PresentationCrossAxisAlignment get crossAxisAlignment;
}

abstract interface class SingleChildLayoutElement {
  PresentationNode get child;
}

@freezed
sealed class PresentationChildrenLayout with _$PresentationChildrenLayout {
  @Assert("spacing >= 0", "Spacing must not be negative.")
  const factory PresentationChildrenLayout.column({
    @Default(0) double spacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.stretch)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = PresentationColumnLayout;

  @Assert("spacing >= 0", "Spacing must not be negative.")
  const factory PresentationChildrenLayout.row({
    @Default(0) double spacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.center)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = PresentationRowLayout;

  @Assert("spacing >= 0", "Spacing must not be negative.")
  @Assert("runSpacing >= 0", "Run spacing must not be negative.")
  const factory PresentationChildrenLayout.wrap({
    @Default(0) double spacing,
    @Default(0) double runSpacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.start)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = PresentationWrapLayout;

  @Assert("columns > 0", "Column count must be positive.")
  @Assert("horizontalSpacing >= 0", "Horizontal spacing must not be negative.")
  @Assert("verticalSpacing >= 0", "Vertical spacing must not be negative.")
  const factory PresentationChildrenLayout.grid({
    required int columns,
    @Default(0) double horizontalSpacing,
    @Default(0) double verticalSpacing,
  }) = PresentationGridLayout;

  const factory PresentationChildrenLayout.stack() = PresentationStackLayout;
}

extension PresentationChildrenLayoutElement on PresentationChildrenLayout {
  PresentationElement element(List<PresentationNode> children) =>
      switch (this) {
        PresentationColumnLayout(
          :final spacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          ColumnElement(
            children: children,
            spacing: spacing,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
          ),
        PresentationRowLayout(
          :final spacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          RowElement(
            children: children,
            spacing: spacing,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
          ),
        PresentationWrapLayout(
          :final spacing,
          :final runSpacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          WrapElement(
            children: children,
            spacing: spacing,
            runSpacing: runSpacing,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
          ),
        PresentationGridLayout(
          :final columns,
          :final horizontalSpacing,
          :final verticalSpacing,
        ) =>
          GridElement(
            children: children,
            columns: columns,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
          ),
        PresentationStackLayout() => StackElement(children: children),
      };
}

@freezed
abstract class TabItem with _$TabItem {
  @Assert("id != \"\"", "Tab ID must not be empty.")
  const factory TabItem({
    required String id,
    required TypedExpression label,
    required PresentationNode child,
  }) = _TabItem;
}
