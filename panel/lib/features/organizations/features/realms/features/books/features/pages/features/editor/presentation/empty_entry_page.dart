import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EmptyEntryPage extends StatelessWidget {
  const EmptyEntryPage({super.key});

  Future<String?> _showAddEntryDialog(BuildContext context) async =>
      throw UnimplementedError();

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "empty_graph_page",
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.only(top: 8, left: 8, right: context.isMobile ? 8 : 0),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "Add an entry",
          buttonText: "Add Entry",
          onPressed: () => _showAddEntryDialog(context),
        ),
      ),
    );
  }
}
