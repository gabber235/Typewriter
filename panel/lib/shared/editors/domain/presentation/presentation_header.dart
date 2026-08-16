import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_header.freezed.dart";

@freezed
abstract class HeaderItemId with _$HeaderItemId {
  @Assert("namespace != \"\"", "Header item namespace must not be empty.")
  @Assert("name != \"\"", "Header item name must not be empty.")
  const factory HeaderItemId({
    required String namespace,
    required String name,
  }) = _HeaderItemId;

  const HeaderItemId._();

  String get qualified => "$namespace:$name";
}

const listAddHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "list.add",
);
const listItemRemoveHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "list.item.remove",
);
const listItemDuplicateHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "list.item.duplicate",
);
const listItemReorderHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "list.item.reorder",
);
const mapAddHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "map.add",
);
const mapEntryRemoveHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "map.entry.remove",
);
const booleanToggleHeaderItemId = HeaderItemId(
  namespace: "typewriter",
  name: "boolean.toggle",
);

enum HeaderItemCommand {
  activate,
  moveBefore,
  moveAfter,
  moveToStart,
  moveToEnd,
}

@freezed
abstract class HeaderItemCommandId with _$HeaderItemCommandId {
  const factory HeaderItemCommandId({
    required HeaderItemId itemId,
    required HeaderItemCommand command,
  }) = _HeaderItemCommandId;
}

enum HeaderActionTone { neutral, destructive }

enum HeaderActionPlacement { beforeTitle, afterTitle, end }

@freezed
sealed class PresentationHeaderTitle with _$PresentationHeaderTitle {
  const factory PresentationHeaderTitle.text(TypedExpression value) =
      PresentationHeaderTextTitle;

  const factory PresentationHeaderTitle.presentation(PresentationNode node) =
      PresentationHeaderNodeTitle;
}

extension PresentationHeaderTextAuthoring on TypedExpression {
  PresentationHeaderTitle get asHeaderTitle =>
      PresentationHeaderTitle.text(this);
}

@freezed
abstract class HeaderActionConfirmation with _$HeaderActionConfirmation {
  const factory HeaderActionConfirmation({
    required TypedExpression title,
    required TypedExpression message,
    required TypedExpression confirmationLabel,
  }) = _HeaderActionConfirmation;
}

@freezed
sealed class HeaderItem with _$HeaderItem {
  const factory HeaderItem.button({
    required HeaderItemId id,
    required TypedExpression icon,
    required TypedExpression label,
    required EditorAction action,
    TypedExpression? tooltip,
    TypedExpression? priority,
    TypedExpression? visibleIf,
    TypedExpression? enabledIf,
    @Default(HeaderActionPlacement.end) HeaderActionPlacement placement,
    @Default(HeaderActionTone.neutral) HeaderActionTone tone,
    HeaderActionConfirmation? confirmation,
  }) = HeaderButtonItem;

  const factory HeaderItem.booleanToggle({
    required HeaderItemId id,
    required TypedExpression label,
    required TypedExpression checked,
    required EditorAction action,
    TypedExpression? tooltip,
    TypedExpression? priority,
    TypedExpression? visibleIf,
    TypedExpression? enabledIf,
    @Default(HeaderActionPlacement.end) HeaderActionPlacement placement,
    HeaderActionConfirmation? confirmation,
  }) = HeaderBooleanToggleItem;

  const factory HeaderItem.reorderHandle({
    required HeaderItemId id,
    required TypedExpression label,
    required BindingReference source,
    TypedExpression? tooltip,
    TypedExpression? visibleIf,
    TypedExpression? enabledIf,
  }) = HeaderReorderHandleItem;
}

@freezed
abstract class PresentationHeader with _$PresentationHeader {
  const factory PresentationHeader({
    BindingReference? binding,
    PresentationHeaderTitle? title,
    TypedExpression? description,
    bool? initiallyExpanded,
    @Default([]) List<HeaderItem> items,
  }) = _PresentationHeader;
}
