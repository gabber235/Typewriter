import "package:flutter/material.dart";
import "package:typewriter_panel/hooks/auto_scroll.dart";
import "package:typewriter_panel/widgets/generic/components/auto_scroller.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: AutoScroller)
Widget autoScrollerUseCase(BuildContext context) {
  final scrollController = ScrollController();
  return AutoScroller(
    scrollController: scrollController,
    loopingMode: context.knobs.list(
      label: "Looping",
      initialOption: AutoScrollLoopingMode.jumpToMin,
      options: AutoScrollLoopingMode.values,
      labelBuilder: (option) => option.name,
    ),
    delay: context.knobs.duration(
      label: "Delay",
      initialValue: Duration(milliseconds: 2000),
    ),
    velocity: context.knobs.double.input(label: "Velocity", initialValue: .1),
    child: ListView.builder(
      controller: scrollController,
      itemCount: context.knobs.int.input(
        label: "Item Count",
        initialValue: 100,
      ),
      itemBuilder: (context, index) {
        return ListTile(title: Text("Item $index"));
      },
    ),
  );
}
