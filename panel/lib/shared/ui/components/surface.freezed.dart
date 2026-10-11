// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surface.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SurfaceAppearance {

 Color get color; Color get foreground; Color get secondaryForeground;
/// Create a copy of SurfaceAppearance
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurfaceAppearanceCopyWith<SurfaceAppearance> get copyWith => _$SurfaceAppearanceCopyWithImpl<SurfaceAppearance>(this as SurfaceAppearance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SurfaceAppearance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurfaceAppearance&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.foreground, _this.foreground) || other.foreground == _this.foreground)&&(identical(other.secondaryForeground, _this.secondaryForeground) || other.secondaryForeground == _this.secondaryForeground));
}


@override
int get hashCode {
  final _this = this as SurfaceAppearance;
  return Object.hash(runtimeType,_this.color,_this.foreground,_this.secondaryForeground);
}

@override
String toString() {
  final _this = this as SurfaceAppearance;
  return 'SurfaceAppearance(color: ${_this.color}, foreground: ${_this.foreground}, secondaryForeground: ${_this.secondaryForeground})';
}


}

/// @nodoc
abstract mixin class $SurfaceAppearanceCopyWith<$Res>  {
  factory $SurfaceAppearanceCopyWith(SurfaceAppearance value, $Res Function(SurfaceAppearance) _then) = _$SurfaceAppearanceCopyWithImpl;
@useResult
$Res call({
 Color color, Color foreground, Color secondaryForeground
});




}
/// @nodoc
class _$SurfaceAppearanceCopyWithImpl<$Res>
    implements $SurfaceAppearanceCopyWith<$Res> {
  _$SurfaceAppearanceCopyWithImpl(this._self, this._then);

  final SurfaceAppearance _self;
  final $Res Function(SurfaceAppearance) _then;

/// Create a copy of SurfaceAppearance
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = null,Object? foreground = null,Object? secondaryForeground = null,}) {
  return _then(SurfaceAppearance(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,foreground: null == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as Color,secondaryForeground: null == secondaryForeground ? _self.secondaryForeground : secondaryForeground // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern matching related methods to [SurfaceAppearance].
extension SurfaceAppearancePatterns on SurfaceAppearance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurfaceAppearance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurfaceAppearance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurfaceAppearance value)  $default,){
final _that = this;
switch (_that) {
case _SurfaceAppearance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurfaceAppearance value)?  $default,){
final _that = this;
switch (_that) {
case _SurfaceAppearance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Color color,  Color foreground,  Color secondaryForeground)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurfaceAppearance() when $default != null:
return $default(_that.color,_that.foreground,_that.secondaryForeground);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Color color,  Color foreground,  Color secondaryForeground)  $default,) {final _that = this;
switch (_that) {
case _SurfaceAppearance():
return $default(_that.color,_that.foreground,_that.secondaryForeground);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Color color,  Color foreground,  Color secondaryForeground)?  $default,) {final _that = this;
switch (_that) {
case _SurfaceAppearance() when $default != null:
return $default(_that.color,_that.foreground,_that.secondaryForeground);case _:
  return null;

}
}

}

/// @nodoc


class _SurfaceAppearance implements SurfaceAppearance {
  const _SurfaceAppearance({required this.color, required this.foreground, required this.secondaryForeground});


@override final  Color color;
@override final  Color foreground;
@override final  Color secondaryForeground;

/// Create a copy of SurfaceAppearance
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurfaceAppearanceCopyWith<_SurfaceAppearance> get copyWith => __$SurfaceAppearanceCopyWithImpl<_SurfaceAppearance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurfaceAppearance&&(identical(other.color, color) || other.color == color)&&(identical(other.foreground, foreground) || other.foreground == foreground)&&(identical(other.secondaryForeground, secondaryForeground) || other.secondaryForeground == secondaryForeground));
}


@override
int get hashCode {
    return Object.hash(runtimeType,color,foreground,secondaryForeground);
}

@override
String toString() {
    return 'SurfaceAppearance(color: $color, foreground: $foreground, secondaryForeground: $secondaryForeground)';
}


}

/// @nodoc
abstract mixin class _$SurfaceAppearanceCopyWith<$Res> implements $SurfaceAppearanceCopyWith<$Res> {
  factory _$SurfaceAppearanceCopyWith(_SurfaceAppearance value, $Res Function(_SurfaceAppearance) _then) = __$SurfaceAppearanceCopyWithImpl;
@override @useResult
$Res call({
 Color color, Color foreground, Color secondaryForeground
});




}
/// @nodoc
class __$SurfaceAppearanceCopyWithImpl<$Res>
    implements _$SurfaceAppearanceCopyWith<$Res> {
  __$SurfaceAppearanceCopyWithImpl(this._self, this._then);

  final _SurfaceAppearance _self;
  final $Res Function(_SurfaceAppearance) _then;

/// Create a copy of SurfaceAppearance
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = null,Object? foreground = null,Object? secondaryForeground = null,}) {
  return _then(_SurfaceAppearance(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,foreground: null == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as Color,secondaryForeground: null == secondaryForeground ? _self.secondaryForeground : secondaryForeground // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
