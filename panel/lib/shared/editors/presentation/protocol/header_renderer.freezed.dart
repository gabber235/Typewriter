// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'header_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedHeaderItem {

 HeaderItemId get id; String get label; String get tooltip; int get declarationOrder; bool get visible; bool get enabled;
/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderItemCopyWith<_ResolvedHeaderItem> get copyWith => __$ResolvedHeaderItemCopyWithImpl<_ResolvedHeaderItem>(this as _ResolvedHeaderItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,tooltip,declarationOrder,visible,enabled);

@override
String toString() {
  return '_ResolvedHeaderItem(id: $id, label: $label, tooltip: $tooltip, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderItemCopyWith<$Res>  {
  factory _$ResolvedHeaderItemCopyWith(_ResolvedHeaderItem value, $Res Function(_ResolvedHeaderItem) _then) = __$ResolvedHeaderItemCopyWithImpl;
@useResult
$Res call({
 HeaderItemId id, String label, String tooltip, int declarationOrder, bool visible, bool enabled
});


$HeaderItemIdCopyWith<$Res> get id;

}
/// @nodoc
class __$ResolvedHeaderItemCopyWithImpl<$Res>
    implements _$ResolvedHeaderItemCopyWith<$Res> {
  __$ResolvedHeaderItemCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderItem _self;
  final $Res Function(_ResolvedHeaderItem) _then;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? tooltip = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {
  
  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}


/// Adds pattern-matching-related methods to [_ResolvedHeaderItem].
extension _ResolvedHeaderItemPatterns on _ResolvedHeaderItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ResolvedHeaderButtonItem value)?  button,TResult Function( _ResolvedHeaderBooleanToggleItem value)?  booleanToggle,TResult Function( _ResolvedHeaderReorderHandleItem value)?  reorderHandle,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem() when button != null:
return button(_that);case _ResolvedHeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that);case _ResolvedHeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ResolvedHeaderButtonItem value)  button,required TResult Function( _ResolvedHeaderBooleanToggleItem value)  booleanToggle,required TResult Function( _ResolvedHeaderReorderHandleItem value)  reorderHandle,}){
final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem():
return button(_that);case _ResolvedHeaderBooleanToggleItem():
return booleanToggle(_that);case _ResolvedHeaderReorderHandleItem():
return reorderHandle(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ResolvedHeaderButtonItem value)?  button,TResult? Function( _ResolvedHeaderBooleanToggleItem value)?  booleanToggle,TResult? Function( _ResolvedHeaderReorderHandleItem value)?  reorderHandle,}){
final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem() when button != null:
return button(_that);case _ResolvedHeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that);case _ResolvedHeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( HeaderItemId id,  IconValue icon,  String label,  String tooltip,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)?  button,TResult Function( HeaderItemId id,  String label,  String tooltip,  bool checked,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  _ResolvedConfirmation? confirmation)?  booleanToggle,TResult Function( HeaderItemId id,  String label,  String tooltip,  BindingReference source,  int index,  int itemCount,  int declarationOrder,  bool visible,  bool enabled)?  reorderHandle,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem() when button != null:
return button(_that.id,_that.icon,_that.label,_that.tooltip,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _ResolvedHeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that.id,_that.label,_that.tooltip,_that.checked,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.confirmation);case _ResolvedHeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that.id,_that.label,_that.tooltip,_that.source,_that.index,_that.itemCount,_that.declarationOrder,_that.visible,_that.enabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( HeaderItemId id,  IconValue icon,  String label,  String tooltip,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)  button,required TResult Function( HeaderItemId id,  String label,  String tooltip,  bool checked,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  _ResolvedConfirmation? confirmation)  booleanToggle,required TResult Function( HeaderItemId id,  String label,  String tooltip,  BindingReference source,  int index,  int itemCount,  int declarationOrder,  bool visible,  bool enabled)  reorderHandle,}) {final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem():
return button(_that.id,_that.icon,_that.label,_that.tooltip,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _ResolvedHeaderBooleanToggleItem():
return booleanToggle(_that.id,_that.label,_that.tooltip,_that.checked,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.confirmation);case _ResolvedHeaderReorderHandleItem():
return reorderHandle(_that.id,_that.label,_that.tooltip,_that.source,_that.index,_that.itemCount,_that.declarationOrder,_that.visible,_that.enabled);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( HeaderItemId id,  IconValue icon,  String label,  String tooltip,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)?  button,TResult? Function( HeaderItemId id,  String label,  String tooltip,  bool checked,  EditorAction action,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  _ResolvedConfirmation? confirmation)?  booleanToggle,TResult? Function( HeaderItemId id,  String label,  String tooltip,  BindingReference source,  int index,  int itemCount,  int declarationOrder,  bool visible,  bool enabled)?  reorderHandle,}) {final _that = this;
switch (_that) {
case _ResolvedHeaderButtonItem() when button != null:
return button(_that.id,_that.icon,_that.label,_that.tooltip,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _ResolvedHeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that.id,_that.label,_that.tooltip,_that.checked,_that.action,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.confirmation);case _ResolvedHeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that.id,_that.label,_that.tooltip,_that.source,_that.index,_that.itemCount,_that.declarationOrder,_that.visible,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedHeaderButtonItem extends _ResolvedHeaderItem {
  const _ResolvedHeaderButtonItem({required this.id, required this.icon, required this.label, required this.tooltip, required this.action, required this.priority, required this.declarationOrder, required this.visible, required this.enabled, required this.placement, required this.tone, required this.confirmation}): super._();
  

@override final  HeaderItemId id;
 final  IconValue icon;
@override final  String label;
@override final  String tooltip;
 final  EditorAction action;
 final  int priority;
@override final  int declarationOrder;
@override final  bool visible;
@override final  bool enabled;
 final  HeaderActionPlacement placement;
 final  HeaderActionTone tone;
 final  _ResolvedConfirmation? confirmation;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderButtonItemCopyWith<_ResolvedHeaderButtonItem> get copyWith => __$ResolvedHeaderButtonItemCopyWithImpl<_ResolvedHeaderButtonItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderButtonItem&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.action, action) || other.action == action)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,tooltip,action,priority,declarationOrder,visible,enabled,placement,tone,confirmation);

@override
String toString() {
  return '_ResolvedHeaderItem.button(id: $id, icon: $icon, label: $label, tooltip: $tooltip, action: $action, priority: $priority, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderButtonItemCopyWith<$Res> implements _$ResolvedHeaderItemCopyWith<$Res> {
  factory _$ResolvedHeaderButtonItemCopyWith(_ResolvedHeaderButtonItem value, $Res Function(_ResolvedHeaderButtonItem) _then) = __$ResolvedHeaderButtonItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, IconValue icon, String label, String tooltip, EditorAction action, int priority, int declarationOrder, bool visible, bool enabled, HeaderActionPlacement placement, HeaderActionTone tone, _ResolvedConfirmation? confirmation
});


@override $HeaderItemIdCopyWith<$Res> get id;$IconValueCopyWith<$Res> get icon;$EditorActionCopyWith<$Res> get action;_$ResolvedConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class __$ResolvedHeaderButtonItemCopyWithImpl<$Res>
    implements _$ResolvedHeaderButtonItemCopyWith<$Res> {
  __$ResolvedHeaderButtonItemCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderButtonItem _self;
  final $Res Function(_ResolvedHeaderButtonItem) _then;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? tooltip = null,Object? action = null,Object? priority = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(_ResolvedHeaderButtonItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as _ResolvedConfirmation?,
  ));
}

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {
  
  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
_$ResolvedConfirmationCopyWith<$Res>? get confirmation {
    if (_self.confirmation == null) {
    return null;
  }

  return _$ResolvedConfirmationCopyWith<$Res>(_self.confirmation!, (value) {
    return _then(_self.copyWith(confirmation: value));
  });
}
}

/// @nodoc


class _ResolvedHeaderBooleanToggleItem extends _ResolvedHeaderItem {
  const _ResolvedHeaderBooleanToggleItem({required this.id, required this.label, required this.tooltip, required this.checked, required this.action, required this.priority, required this.declarationOrder, required this.visible, required this.enabled, required this.placement, required this.confirmation}): super._();
  

@override final  HeaderItemId id;
@override final  String label;
@override final  String tooltip;
 final  bool checked;
 final  EditorAction action;
 final  int priority;
@override final  int declarationOrder;
@override final  bool visible;
@override final  bool enabled;
 final  HeaderActionPlacement placement;
 final  _ResolvedConfirmation? confirmation;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderBooleanToggleItemCopyWith<_ResolvedHeaderBooleanToggleItem> get copyWith => __$ResolvedHeaderBooleanToggleItemCopyWithImpl<_ResolvedHeaderBooleanToggleItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderBooleanToggleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.action, action) || other.action == action)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,tooltip,checked,action,priority,declarationOrder,visible,enabled,placement,confirmation);

@override
String toString() {
  return '_ResolvedHeaderItem.booleanToggle(id: $id, label: $label, tooltip: $tooltip, checked: $checked, action: $action, priority: $priority, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled, placement: $placement, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderBooleanToggleItemCopyWith<$Res> implements _$ResolvedHeaderItemCopyWith<$Res> {
  factory _$ResolvedHeaderBooleanToggleItemCopyWith(_ResolvedHeaderBooleanToggleItem value, $Res Function(_ResolvedHeaderBooleanToggleItem) _then) = __$ResolvedHeaderBooleanToggleItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, String label, String tooltip, bool checked, EditorAction action, int priority, int declarationOrder, bool visible, bool enabled, HeaderActionPlacement placement, _ResolvedConfirmation? confirmation
});


@override $HeaderItemIdCopyWith<$Res> get id;$EditorActionCopyWith<$Res> get action;_$ResolvedConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class __$ResolvedHeaderBooleanToggleItemCopyWithImpl<$Res>
    implements _$ResolvedHeaderBooleanToggleItemCopyWith<$Res> {
  __$ResolvedHeaderBooleanToggleItemCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderBooleanToggleItem _self;
  final $Res Function(_ResolvedHeaderBooleanToggleItem) _then;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? tooltip = null,Object? checked = null,Object? action = null,Object? priority = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,Object? placement = null,Object? confirmation = freezed,}) {
  return _then(_ResolvedHeaderBooleanToggleItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as _ResolvedConfirmation?,
  ));
}

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {
  
  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
_$ResolvedConfirmationCopyWith<$Res>? get confirmation {
    if (_self.confirmation == null) {
    return null;
  }

  return _$ResolvedConfirmationCopyWith<$Res>(_self.confirmation!, (value) {
    return _then(_self.copyWith(confirmation: value));
  });
}
}

/// @nodoc


class _ResolvedHeaderReorderHandleItem extends _ResolvedHeaderItem {
  const _ResolvedHeaderReorderHandleItem({required this.id, required this.label, required this.tooltip, required this.source, required this.index, required this.itemCount, required this.declarationOrder, required this.visible, required this.enabled}): super._();
  

@override final  HeaderItemId id;
@override final  String label;
@override final  String tooltip;
 final  BindingReference source;
 final  int index;
 final  int itemCount;
@override final  int declarationOrder;
@override final  bool visible;
@override final  bool enabled;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderReorderHandleItemCopyWith<_ResolvedHeaderReorderHandleItem> get copyWith => __$ResolvedHeaderReorderHandleItemCopyWithImpl<_ResolvedHeaderReorderHandleItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderReorderHandleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.source, source) || other.source == source)&&(identical(other.index, index) || other.index == index)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,tooltip,source,index,itemCount,declarationOrder,visible,enabled);

@override
String toString() {
  return '_ResolvedHeaderItem.reorderHandle(id: $id, label: $label, tooltip: $tooltip, source: $source, index: $index, itemCount: $itemCount, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderReorderHandleItemCopyWith<$Res> implements _$ResolvedHeaderItemCopyWith<$Res> {
  factory _$ResolvedHeaderReorderHandleItemCopyWith(_ResolvedHeaderReorderHandleItem value, $Res Function(_ResolvedHeaderReorderHandleItem) _then) = __$ResolvedHeaderReorderHandleItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, String label, String tooltip, BindingReference source, int index, int itemCount, int declarationOrder, bool visible, bool enabled
});


@override $HeaderItemIdCopyWith<$Res> get id;$BindingReferenceCopyWith<$Res> get source;

}
/// @nodoc
class __$ResolvedHeaderReorderHandleItemCopyWithImpl<$Res>
    implements _$ResolvedHeaderReorderHandleItemCopyWith<$Res> {
  __$ResolvedHeaderReorderHandleItemCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderReorderHandleItem _self;
  final $Res Function(_ResolvedHeaderReorderHandleItem) _then;

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? tooltip = null,Object? source = null,Object? index = null,Object? itemCount = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,}) {
  return _then(_ResolvedHeaderReorderHandleItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BindingReference,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {
  
  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of _ResolvedHeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get source {
  
  return $BindingReferenceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc
mixin _$ResolvedPresentationHeader {

 PresentationHeaderTitle? get title; String get description; List<_ResolvedHeaderItem> get items;
/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPresentationHeaderCopyWith<_ResolvedPresentationHeader> get copyWith => __$ResolvedPresentationHeaderCopyWithImpl<_ResolvedPresentationHeader>(this as _ResolvedPresentationHeader, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPresentationHeader&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return '_ResolvedPresentationHeader(title: $title, description: $description, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPresentationHeaderCopyWith<$Res>  {
  factory _$ResolvedPresentationHeaderCopyWith(_ResolvedPresentationHeader value, $Res Function(_ResolvedPresentationHeader) _then) = __$ResolvedPresentationHeaderCopyWithImpl;
@useResult
$Res call({
 PresentationHeaderTitle? title, String description, List<_ResolvedHeaderItem> items
});


$PresentationHeaderTitleCopyWith<$Res>? get title;

}
/// @nodoc
class __$ResolvedPresentationHeaderCopyWithImpl<$Res>
    implements _$ResolvedPresentationHeaderCopyWith<$Res> {
  __$ResolvedPresentationHeaderCopyWithImpl(this._self, this._then);

  final _ResolvedPresentationHeader _self;
  final $Res Function(_ResolvedPresentationHeader) _then;

/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = null,Object? items = null,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as PresentationHeaderTitle?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<_ResolvedHeaderItem>,
  ));
}
/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationHeaderTitleCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $PresentationHeaderTitleCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}


/// Adds pattern-matching-related methods to [_ResolvedPresentationHeader].
extension _ResolvedPresentationHeaderPatterns on _ResolvedPresentationHeader {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedPresentationHeaderValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedPresentationHeaderValue value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedPresentationHeaderValue value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationHeaderTitle? title,  String description,  List<_ResolvedHeaderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue() when $default != null:
return $default(_that.title,_that.description,_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationHeaderTitle? title,  String description,  List<_ResolvedHeaderItem> items)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue():
return $default(_that.title,_that.description,_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationHeaderTitle? title,  String description,  List<_ResolvedHeaderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationHeaderValue() when $default != null:
return $default(_that.title,_that.description,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPresentationHeaderValue implements _ResolvedPresentationHeader {
  const _ResolvedPresentationHeaderValue({required this.title, required this.description, required final  List<_ResolvedHeaderItem> items}): _items = items;
  

@override final  PresentationHeaderTitle? title;
@override final  String description;
 final  List<_ResolvedHeaderItem> _items;
@override List<_ResolvedHeaderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPresentationHeaderValueCopyWith<_ResolvedPresentationHeaderValue> get copyWith => __$ResolvedPresentationHeaderValueCopyWithImpl<_ResolvedPresentationHeaderValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPresentationHeaderValue&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return '_ResolvedPresentationHeader(title: $title, description: $description, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPresentationHeaderValueCopyWith<$Res> implements _$ResolvedPresentationHeaderCopyWith<$Res> {
  factory _$ResolvedPresentationHeaderValueCopyWith(_ResolvedPresentationHeaderValue value, $Res Function(_ResolvedPresentationHeaderValue) _then) = __$ResolvedPresentationHeaderValueCopyWithImpl;
@override @useResult
$Res call({
 PresentationHeaderTitle? title, String description, List<_ResolvedHeaderItem> items
});


@override $PresentationHeaderTitleCopyWith<$Res>? get title;

}
/// @nodoc
class __$ResolvedPresentationHeaderValueCopyWithImpl<$Res>
    implements _$ResolvedPresentationHeaderValueCopyWith<$Res> {
  __$ResolvedPresentationHeaderValueCopyWithImpl(this._self, this._then);

  final _ResolvedPresentationHeaderValue _self;
  final $Res Function(_ResolvedPresentationHeaderValue) _then;

/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = null,Object? items = null,}) {
  return _then(_ResolvedPresentationHeaderValue(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as PresentationHeaderTitle?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<_ResolvedHeaderItem>,
  ));
}

/// Create a copy of _ResolvedPresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationHeaderTitleCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $PresentationHeaderTitleCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

/// @nodoc
mixin _$ResolvedConfirmation {

 String get title; String get message; String get confirmationLabel;
/// Create a copy of _ResolvedConfirmation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedConfirmationCopyWith<_ResolvedConfirmation> get copyWith => __$ResolvedConfirmationCopyWithImpl<_ResolvedConfirmation>(this as _ResolvedConfirmation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedConfirmation&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.confirmationLabel, confirmationLabel) || other.confirmationLabel == confirmationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,title,message,confirmationLabel);

@override
String toString() {
  return '_ResolvedConfirmation(title: $title, message: $message, confirmationLabel: $confirmationLabel)';
}


}

/// @nodoc
abstract mixin class _$ResolvedConfirmationCopyWith<$Res>  {
  factory _$ResolvedConfirmationCopyWith(_ResolvedConfirmation value, $Res Function(_ResolvedConfirmation) _then) = __$ResolvedConfirmationCopyWithImpl;
@useResult
$Res call({
 String title, String message, String confirmationLabel
});




}
/// @nodoc
class __$ResolvedConfirmationCopyWithImpl<$Res>
    implements _$ResolvedConfirmationCopyWith<$Res> {
  __$ResolvedConfirmationCopyWithImpl(this._self, this._then);

  final _ResolvedConfirmation _self;
  final $Res Function(_ResolvedConfirmation) _then;

/// Create a copy of _ResolvedConfirmation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? message = null,Object? confirmationLabel = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,confirmationLabel: null == confirmationLabel ? _self.confirmationLabel : confirmationLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [_ResolvedConfirmation].
extension _ResolvedConfirmationPatterns on _ResolvedConfirmation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedConfirmationValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedConfirmationValue() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedConfirmationValue value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedConfirmationValue():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedConfirmationValue value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedConfirmationValue() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String message,  String confirmationLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedConfirmationValue() when $default != null:
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String message,  String confirmationLabel)  $default,) {final _that = this;
switch (_that) {
case _ResolvedConfirmationValue():
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String message,  String confirmationLabel)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedConfirmationValue() when $default != null:
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedConfirmationValue implements _ResolvedConfirmation {
  const _ResolvedConfirmationValue({required this.title, required this.message, required this.confirmationLabel});
  

@override final  String title;
@override final  String message;
@override final  String confirmationLabel;

/// Create a copy of _ResolvedConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedConfirmationValueCopyWith<_ResolvedConfirmationValue> get copyWith => __$ResolvedConfirmationValueCopyWithImpl<_ResolvedConfirmationValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedConfirmationValue&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.confirmationLabel, confirmationLabel) || other.confirmationLabel == confirmationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,title,message,confirmationLabel);

@override
String toString() {
  return '_ResolvedConfirmation(title: $title, message: $message, confirmationLabel: $confirmationLabel)';
}


}

/// @nodoc
abstract mixin class _$ResolvedConfirmationValueCopyWith<$Res> implements _$ResolvedConfirmationCopyWith<$Res> {
  factory _$ResolvedConfirmationValueCopyWith(_ResolvedConfirmationValue value, $Res Function(_ResolvedConfirmationValue) _then) = __$ResolvedConfirmationValueCopyWithImpl;
@override @useResult
$Res call({
 String title, String message, String confirmationLabel
});




}
/// @nodoc
class __$ResolvedConfirmationValueCopyWithImpl<$Res>
    implements _$ResolvedConfirmationValueCopyWith<$Res> {
  __$ResolvedConfirmationValueCopyWithImpl(this._self, this._then);

  final _ResolvedConfirmationValue _self;
  final $Res Function(_ResolvedConfirmationValue) _then;

/// Create a copy of _ResolvedConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? message = null,Object? confirmationLabel = null,}) {
  return _then(_ResolvedConfirmationValue(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,confirmationLabel: null == confirmationLabel ? _self.confirmationLabel : confirmationLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
