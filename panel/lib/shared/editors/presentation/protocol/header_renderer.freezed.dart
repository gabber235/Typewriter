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
mixin _$ResolvedHeaderAction {

 HeaderActionId get id; IconValue get icon; String get label; String get tooltip; HeaderActionActivation get activation; int get priority; int get declarationOrder; bool get visible; bool get enabled; HeaderActionPlacement get placement; HeaderActionTone get tone; _ResolvedConfirmation? get confirmation;
/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderActionCopyWith<_ResolvedHeaderAction> get copyWith => __$ResolvedHeaderActionCopyWithImpl<_ResolvedHeaderAction>(this as _ResolvedHeaderAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderAction&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,tooltip,activation,priority,declarationOrder,visible,enabled,placement,tone,confirmation);

@override
String toString() {
  return '_ResolvedHeaderAction(id: $id, icon: $icon, label: $label, tooltip: $tooltip, activation: $activation, priority: $priority, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderActionCopyWith<$Res>  {
  factory _$ResolvedHeaderActionCopyWith(_ResolvedHeaderAction value, $Res Function(_ResolvedHeaderAction) _then) = __$ResolvedHeaderActionCopyWithImpl;
@useResult
$Res call({
 HeaderActionId id, IconValue icon, String label, String tooltip, HeaderActionActivation activation, int priority, int declarationOrder, bool visible, bool enabled, HeaderActionPlacement placement, HeaderActionTone tone, _ResolvedConfirmation? confirmation
});


$HeaderActionIdCopyWith<$Res> get id;$IconValueCopyWith<$Res> get icon;$HeaderActionActivationCopyWith<$Res> get activation;_$ResolvedConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class __$ResolvedHeaderActionCopyWithImpl<$Res>
    implements _$ResolvedHeaderActionCopyWith<$Res> {
  __$ResolvedHeaderActionCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderAction _self;
  final $Res Function(_ResolvedHeaderAction) _then;

/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? tooltip = null,Object? activation = null,Object? priority = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderActionId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as HeaderActionActivation,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as _ResolvedConfirmation?,
  ));
}
/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionIdCopyWith<$Res> get id {
  
  return $HeaderActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionActivationCopyWith<$Res> get activation {
  
  return $HeaderActionActivationCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}/// Create a copy of _ResolvedHeaderAction
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


/// Adds pattern-matching-related methods to [_ResolvedHeaderAction].
extension _ResolvedHeaderActionPatterns on _ResolvedHeaderAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedHeaderActionValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedHeaderActionValue value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedHeaderActionValue value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HeaderActionId id,  IconValue icon,  String label,  String tooltip,  HeaderActionActivation activation,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue() when $default != null:
return $default(_that.id,_that.icon,_that.label,_that.tooltip,_that.activation,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HeaderActionId id,  IconValue icon,  String label,  String tooltip,  HeaderActionActivation activation,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)  $default,) {final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue():
return $default(_that.id,_that.icon,_that.label,_that.tooltip,_that.activation,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HeaderActionId id,  IconValue icon,  String label,  String tooltip,  HeaderActionActivation activation,  int priority,  int declarationOrder,  bool visible,  bool enabled,  HeaderActionPlacement placement,  HeaderActionTone tone,  _ResolvedConfirmation? confirmation)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedHeaderActionValue() when $default != null:
return $default(_that.id,_that.icon,_that.label,_that.tooltip,_that.activation,_that.priority,_that.declarationOrder,_that.visible,_that.enabled,_that.placement,_that.tone,_that.confirmation);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedHeaderActionValue extends _ResolvedHeaderAction {
  const _ResolvedHeaderActionValue({required this.id, required this.icon, required this.label, required this.tooltip, required this.activation, required this.priority, required this.declarationOrder, required this.visible, required this.enabled, required this.placement, required this.tone, required this.confirmation}): super._();
  

@override final  HeaderActionId id;
@override final  IconValue icon;
@override final  String label;
@override final  String tooltip;
@override final  HeaderActionActivation activation;
@override final  int priority;
@override final  int declarationOrder;
@override final  bool visible;
@override final  bool enabled;
@override final  HeaderActionPlacement placement;
@override final  HeaderActionTone tone;
@override final  _ResolvedConfirmation? confirmation;

/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderActionValueCopyWith<_ResolvedHeaderActionValue> get copyWith => __$ResolvedHeaderActionValueCopyWithImpl<_ResolvedHeaderActionValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderActionValue&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.declarationOrder, declarationOrder) || other.declarationOrder == declarationOrder)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,tooltip,activation,priority,declarationOrder,visible,enabled,placement,tone,confirmation);

@override
String toString() {
  return '_ResolvedHeaderAction(id: $id, icon: $icon, label: $label, tooltip: $tooltip, activation: $activation, priority: $priority, declarationOrder: $declarationOrder, visible: $visible, enabled: $enabled, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderActionValueCopyWith<$Res> implements _$ResolvedHeaderActionCopyWith<$Res> {
  factory _$ResolvedHeaderActionValueCopyWith(_ResolvedHeaderActionValue value, $Res Function(_ResolvedHeaderActionValue) _then) = __$ResolvedHeaderActionValueCopyWithImpl;
@override @useResult
$Res call({
 HeaderActionId id, IconValue icon, String label, String tooltip, HeaderActionActivation activation, int priority, int declarationOrder, bool visible, bool enabled, HeaderActionPlacement placement, HeaderActionTone tone, _ResolvedConfirmation? confirmation
});


@override $HeaderActionIdCopyWith<$Res> get id;@override $IconValueCopyWith<$Res> get icon;@override $HeaderActionActivationCopyWith<$Res> get activation;@override _$ResolvedConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class __$ResolvedHeaderActionValueCopyWithImpl<$Res>
    implements _$ResolvedHeaderActionValueCopyWith<$Res> {
  __$ResolvedHeaderActionValueCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderActionValue _self;
  final $Res Function(_ResolvedHeaderActionValue) _then;

/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? tooltip = null,Object? activation = null,Object? priority = null,Object? declarationOrder = null,Object? visible = null,Object? enabled = null,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(_ResolvedHeaderActionValue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderActionId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tooltip: null == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as String,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as HeaderActionActivation,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,declarationOrder: null == declarationOrder ? _self.declarationOrder : declarationOrder // ignore: cast_nullable_to_non_nullable
as int,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as _ResolvedConfirmation?,
  ));
}

/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionIdCopyWith<$Res> get id {
  
  return $HeaderActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of _ResolvedHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionActivationCopyWith<$Res> get activation {
  
  return $HeaderActionActivationCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}/// Create a copy of _ResolvedHeaderAction
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
