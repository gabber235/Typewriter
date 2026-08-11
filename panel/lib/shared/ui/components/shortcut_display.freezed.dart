// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shortcut_display.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KeyStyle {

 Color? get foregroundColor;
/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyStyleCopyWith<KeyStyle> get copyWith => _$KeyStyleCopyWithImpl<KeyStyle>(this as KeyStyle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyStyle&&(identical(other.foregroundColor, foregroundColor) || other.foregroundColor == foregroundColor));
}


@override
int get hashCode => Object.hash(runtimeType,foregroundColor);

@override
String toString() {
  return 'KeyStyle(foregroundColor: $foregroundColor)';
}


}

/// @nodoc
abstract mixin class $KeyStyleCopyWith<$Res>  {
  factory $KeyStyleCopyWith(KeyStyle value, $Res Function(KeyStyle) _then) = _$KeyStyleCopyWithImpl;
@useResult
$Res call({
 Color? foregroundColor
});




}
/// @nodoc
class _$KeyStyleCopyWithImpl<$Res>
    implements $KeyStyleCopyWith<$Res> {
  _$KeyStyleCopyWithImpl(this._self, this._then);

  final KeyStyle _self;
  final $Res Function(KeyStyle) _then;

/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? foregroundColor = freezed,}) {
  return _then(_self.copyWith(
foregroundColor: freezed == foregroundColor ? _self.foregroundColor : foregroundColor // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}

}


/// Adds pattern-matching-related methods to [KeyStyle].
extension KeyStylePatterns on KeyStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SolidKeyStyle value)?  solid,TResult Function( OutlineKeyStyle value)?  outline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SolidKeyStyle() when solid != null:
return solid(_that);case OutlineKeyStyle() when outline != null:
return outline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SolidKeyStyle value)  solid,required TResult Function( OutlineKeyStyle value)  outline,}){
final _that = this;
switch (_that) {
case SolidKeyStyle():
return solid(_that);case OutlineKeyStyle():
return outline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SolidKeyStyle value)?  solid,TResult? Function( OutlineKeyStyle value)?  outline,}){
final _that = this;
switch (_that) {
case SolidKeyStyle() when solid != null:
return solid(_that);case OutlineKeyStyle() when outline != null:
return outline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Color? backgroundColor,  Color? foregroundColor,  Color? shadowColor)?  solid,TResult Function( Color? foregroundColor,  Color? borderColor)?  outline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SolidKeyStyle() when solid != null:
return solid(_that.backgroundColor,_that.foregroundColor,_that.shadowColor);case OutlineKeyStyle() when outline != null:
return outline(_that.foregroundColor,_that.borderColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Color? backgroundColor,  Color? foregroundColor,  Color? shadowColor)  solid,required TResult Function( Color? foregroundColor,  Color? borderColor)  outline,}) {final _that = this;
switch (_that) {
case SolidKeyStyle():
return solid(_that.backgroundColor,_that.foregroundColor,_that.shadowColor);case OutlineKeyStyle():
return outline(_that.foregroundColor,_that.borderColor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Color? backgroundColor,  Color? foregroundColor,  Color? shadowColor)?  solid,TResult? Function( Color? foregroundColor,  Color? borderColor)?  outline,}) {final _that = this;
switch (_that) {
case SolidKeyStyle() when solid != null:
return solid(_that.backgroundColor,_that.foregroundColor,_that.shadowColor);case OutlineKeyStyle() when outline != null:
return outline(_that.foregroundColor,_that.borderColor);case _:
  return null;

}
}

}

/// @nodoc


class SolidKeyStyle implements KeyStyle {
  const SolidKeyStyle({this.backgroundColor, this.foregroundColor, this.shadowColor});
  

 final  Color? backgroundColor;
@override final  Color? foregroundColor;
 final  Color? shadowColor;

/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SolidKeyStyleCopyWith<SolidKeyStyle> get copyWith => _$SolidKeyStyleCopyWithImpl<SolidKeyStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SolidKeyStyle&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.foregroundColor, foregroundColor) || other.foregroundColor == foregroundColor)&&(identical(other.shadowColor, shadowColor) || other.shadowColor == shadowColor));
}


@override
int get hashCode => Object.hash(runtimeType,backgroundColor,foregroundColor,shadowColor);

@override
String toString() {
  return 'KeyStyle.solid(backgroundColor: $backgroundColor, foregroundColor: $foregroundColor, shadowColor: $shadowColor)';
}


}

/// @nodoc
abstract mixin class $SolidKeyStyleCopyWith<$Res> implements $KeyStyleCopyWith<$Res> {
  factory $SolidKeyStyleCopyWith(SolidKeyStyle value, $Res Function(SolidKeyStyle) _then) = _$SolidKeyStyleCopyWithImpl;
@override @useResult
$Res call({
 Color? backgroundColor, Color? foregroundColor, Color? shadowColor
});




}
/// @nodoc
class _$SolidKeyStyleCopyWithImpl<$Res>
    implements $SolidKeyStyleCopyWith<$Res> {
  _$SolidKeyStyleCopyWithImpl(this._self, this._then);

  final SolidKeyStyle _self;
  final $Res Function(SolidKeyStyle) _then;

/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backgroundColor = freezed,Object? foregroundColor = freezed,Object? shadowColor = freezed,}) {
  return _then(SolidKeyStyle(
backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color?,foregroundColor: freezed == foregroundColor ? _self.foregroundColor : foregroundColor // ignore: cast_nullable_to_non_nullable
as Color?,shadowColor: freezed == shadowColor ? _self.shadowColor : shadowColor // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}

/// @nodoc


class OutlineKeyStyle implements KeyStyle {
  const OutlineKeyStyle({this.foregroundColor, this.borderColor});
  

@override final  Color? foregroundColor;
 final  Color? borderColor;

/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutlineKeyStyleCopyWith<OutlineKeyStyle> get copyWith => _$OutlineKeyStyleCopyWithImpl<OutlineKeyStyle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutlineKeyStyle&&(identical(other.foregroundColor, foregroundColor) || other.foregroundColor == foregroundColor)&&(identical(other.borderColor, borderColor) || other.borderColor == borderColor));
}


@override
int get hashCode => Object.hash(runtimeType,foregroundColor,borderColor);

@override
String toString() {
  return 'KeyStyle.outline(foregroundColor: $foregroundColor, borderColor: $borderColor)';
}


}

/// @nodoc
abstract mixin class $OutlineKeyStyleCopyWith<$Res> implements $KeyStyleCopyWith<$Res> {
  factory $OutlineKeyStyleCopyWith(OutlineKeyStyle value, $Res Function(OutlineKeyStyle) _then) = _$OutlineKeyStyleCopyWithImpl;
@override @useResult
$Res call({
 Color? foregroundColor, Color? borderColor
});




}
/// @nodoc
class _$OutlineKeyStyleCopyWithImpl<$Res>
    implements $OutlineKeyStyleCopyWith<$Res> {
  _$OutlineKeyStyleCopyWithImpl(this._self, this._then);

  final OutlineKeyStyle _self;
  final $Res Function(OutlineKeyStyle) _then;

/// Create a copy of KeyStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foregroundColor = freezed,Object? borderColor = freezed,}) {
  return _then(OutlineKeyStyle(
foregroundColor: freezed == foregroundColor ? _self.foregroundColor : foregroundColor // ignore: cast_nullable_to_non_nullable
as Color?,borderColor: freezed == borderColor ? _self.borderColor : borderColor // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}

// dart format on
