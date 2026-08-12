import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_header.freezed.dart";

@freezed
abstract class HeaderActionId with _$HeaderActionId {
  @Assert("namespace != \"\"", "Header action namespace must not be empty.")
  @Assert("name != \"\"", "Header action name must not be empty.")
  const factory HeaderActionId({
    required String namespace,
    required String name,
  }) = _HeaderActionId;

  const HeaderActionId._();

  String get qualified => "$namespace:$name";
}

const listAddHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "list.add",
);
const listItemRemoveHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "list.item.remove",
);
const listItemDuplicateHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "list.item.duplicate",
);
const listItemReorderHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "list.item.reorder",
);
const mapAddHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "map.add",
);
const mapEntryRemoveHeaderActionId = HeaderActionId(
  namespace: "typewriter",
  name: "map.entry.remove",
);

enum HeaderActionTone { neutral, destructive }

enum HeaderActionPlacement { beforeTitle, afterTitle, end }

@freezed
sealed class HeaderActionActivation with _$HeaderActionActivation {
  const factory HeaderActionActivation.invoke(EditorAction action) =
      InvokeHeaderAction;
  const factory HeaderActionActivation.reorderListItem({
    required BindingReference source,
  }) = ReorderListItemHeaderAction;
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
abstract class EditorHeaderAction with _$EditorHeaderAction {
  const factory EditorHeaderAction({
    required HeaderActionId id,
    required TypedExpression icon,
    required TypedExpression label,
    required HeaderActionActivation activation,
    TypedExpression? tooltip,
    TypedExpression? priority,
    TypedExpression? visibleIf,
    TypedExpression? enabledIf,
    @Default(HeaderActionPlacement.end) HeaderActionPlacement placement,
    @Default(HeaderActionTone.neutral) HeaderActionTone tone,
    HeaderActionConfirmation? confirmation,
  }) = _EditorHeaderAction;
}

@freezed
abstract class PresentationHeader with _$PresentationHeader {
  const factory PresentationHeader({
    BindingReference? binding,
    TypedExpression? title,
    TypedExpression? description,
    bool? initiallyExpanded,
    @Default([]) List<EditorHeaderAction> actions,
  }) = _PresentationHeader;
}
