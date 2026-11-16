import "package:typewriter_panel/typewriter_panel.dart";

part "motion_table.g.dart";

/// The token table every theme the panel builds installs.
@Riverpod(keepAlive: true)
TypewriterMotion motionTable(Ref ref) {
  return TypewriterMotion.standard();
}
