// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_interaction_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationInteraction {

 bool get selected; bool get hovered; bool get focused; bool get pressed; bool get disabled;
/// Create a copy of PresentationInteraction
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationInteractionCopyWith<PresentationInteraction> get copyWith => _$PresentationInteractionCopyWithImpl<PresentationInteraction>(this as PresentationInteraction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationInteraction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationInteraction&&(identical(other.selected, _this.selected) || other.selected == _this.selected)&&(identical(other.hovered, _this.hovered) || other.hovered == _this.hovered)&&(identical(other.focused, _this.focused) || other.focused == _this.focused)&&(identical(other.pressed, _this.pressed) || other.pressed == _this.pressed)&&(identical(other.disabled, _this.disabled) || other.disabled == _this.disabled));
}


@override
int get hashCode {
  final _this = this as PresentationInteraction;
  return Object.hash(runtimeType,_this.selected,_this.hovered,_this.focused,_this.pressed,_this.disabled);
}

@override
String toString() {
  final _this = this as PresentationInteraction;
  return 'PresentationInteraction(selected: ${_this.selected}, hovered: ${_this.hovered}, focused: ${_this.focused}, pressed: ${_this.pressed}, disabled: ${_this.disabled})';
}


}

/// @nodoc
abstract mixin class $PresentationInteractionCopyWith<$Res>  {
  factory $PresentationInteractionCopyWith(PresentationInteraction value, $Res Function(PresentationInteraction) _then) = _$PresentationInteractionCopyWithImpl;
@useResult
$Res call({
 bool selected, bool hovered, bool focused, bool pressed, bool disabled
});




}
/// @nodoc
class _$PresentationInteractionCopyWithImpl<$Res>
    implements $PresentationInteractionCopyWith<$Res> {
  _$PresentationInteractionCopyWithImpl(this._self, this._then);

  final PresentationInteraction _self;
  final $Res Function(PresentationInteraction) _then;

/// Create a copy of PresentationInteraction
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selected = null,Object? hovered = null,Object? focused = null,Object? pressed = null,Object? disabled = null,}) {
  return _then(PresentationInteraction(
selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,hovered: null == hovered ? _self.hovered : hovered // ignore: cast_nullable_to_non_nullable
as bool,focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,pressed: null == pressed ? _self.pressed : pressed // ignore: cast_nullable_to_non_nullable
as bool,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [PresentationInteraction].
extension PresentationInteractionPatterns on PresentationInteraction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationInteraction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationInteraction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationInteraction value)  $default,){
final _that = this;
switch (_that) {
case _PresentationInteraction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationInteraction value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationInteraction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool selected,  bool hovered,  bool focused,  bool pressed,  bool disabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationInteraction() when $default != null:
return $default(_that.selected,_that.hovered,_that.focused,_that.pressed,_that.disabled);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool selected,  bool hovered,  bool focused,  bool pressed,  bool disabled)  $default,) {final _that = this;
switch (_that) {
case _PresentationInteraction():
return $default(_that.selected,_that.hovered,_that.focused,_that.pressed,_that.disabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool selected,  bool hovered,  bool focused,  bool pressed,  bool disabled)?  $default,) {final _that = this;
switch (_that) {
case _PresentationInteraction() when $default != null:
return $default(_that.selected,_that.hovered,_that.focused,_that.pressed,_that.disabled);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationInteraction extends PresentationInteraction {
  const _PresentationInteraction({this.selected = false, this.hovered = false, this.focused = false, this.pressed = false, this.disabled = false}): super._();


@override@JsonKey() final  bool selected;
@override@JsonKey() final  bool hovered;
@override@JsonKey() final  bool focused;
@override@JsonKey() final  bool pressed;
@override@JsonKey() final  bool disabled;

/// Create a copy of PresentationInteraction
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationInteractionCopyWith<_PresentationInteraction> get copyWith => __$PresentationInteractionCopyWithImpl<_PresentationInteraction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationInteraction&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.hovered, hovered) || other.hovered == hovered)&&(identical(other.focused, focused) || other.focused == focused)&&(identical(other.pressed, pressed) || other.pressed == pressed)&&(identical(other.disabled, disabled) || other.disabled == disabled));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selected,hovered,focused,pressed,disabled);
}

@override
String toString() {
    return 'PresentationInteraction(selected: $selected, hovered: $hovered, focused: $focused, pressed: $pressed, disabled: $disabled)';
}


}

/// @nodoc
abstract mixin class _$PresentationInteractionCopyWith<$Res> implements $PresentationInteractionCopyWith<$Res> {
  factory _$PresentationInteractionCopyWith(_PresentationInteraction value, $Res Function(_PresentationInteraction) _then) = __$PresentationInteractionCopyWithImpl;
@override @useResult
$Res call({
 bool selected, bool hovered, bool focused, bool pressed, bool disabled
});




}
/// @nodoc
class __$PresentationInteractionCopyWithImpl<$Res>
    implements _$PresentationInteractionCopyWith<$Res> {
  __$PresentationInteractionCopyWithImpl(this._self, this._then);

  final _PresentationInteraction _self;
  final $Res Function(_PresentationInteraction) _then;

/// Create a copy of PresentationInteraction
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selected = null,Object? hovered = null,Object? focused = null,Object? pressed = null,Object? disabled = null,}) {
  return _then(_PresentationInteraction(
selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,hovered: null == hovered ? _self.hovered : hovered // ignore: cast_nullable_to_non_nullable
as bool,focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,pressed: null == pressed ? _self.pressed : pressed // ignore: cast_nullable_to_non_nullable
as bool,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
