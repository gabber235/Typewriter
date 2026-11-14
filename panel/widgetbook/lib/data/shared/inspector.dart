/// Two members the inspector edits together: they share some fields and
/// differ in every kind of field it can show as mixed.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

/// A member who is online, unmuted, a builder on the red team.
final storyAda = RecordSelectableIdentifier(
  id: "ada",
  fields: {
    RecordField.nickname: skir.DataValue.wrapStringValue("Ada"),
    RecordField.level: skir.DataValue.wrapInteger("12"),
    RecordField.online: skir.DataValue.wrapBoolean(true),
    RecordField.role: skir.DataValue.wrapStringValue("builder"),
    RecordField.color: skir.DataValue.wrapInteger(0xFF009688.toString()),
    RecordField.joined: skir.DataValue.wrapTimestamp(DateTime.utc(2025, 3, 4)),
  },
);

/// A member who is offline and muted, a moderator on the blue team.
final storyGrace = RecordSelectableIdentifier(
  id: "grace",
  fields: {
    RecordField.nickname: skir.DataValue.wrapStringValue("Grace"),
    RecordField.level: skir.DataValue.wrapInteger("7"),
    RecordField.muted: skir.DataValue.wrapBoolean(true),
    RecordField.role: skir.DataValue.wrapStringValue("moderator"),
    RecordField.team: skir.DataValue.wrapStringValue("blue"),
    RecordField.color: skir.DataValue.wrapInteger(0xFFFF9800.toString()),
    RecordField.joined: skir.DataValue.wrapTimestamp(DateTime.utc(2025, 9, 1)),
  },
);

/// A member who agrees with [storyAda] on every field but the name.
final storyLin = RecordSelectableIdentifier(
  id: "lin",
  fields: {
    ...storyAda.fields,
    RecordField.nickname: skir.DataValue.wrapStringValue("Lin"),
  },
);
