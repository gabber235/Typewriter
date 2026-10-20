// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_appearance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceAppearance {

 String get label; Color get accent; skir.Icon get icon;
/// Create a copy of ResourceAppearance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceAppearanceCopyWith<ResourceAppearance> get copyWith => _$ResourceAppearanceCopyWithImpl<ResourceAppearance>(this as ResourceAppearance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceAppearance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceAppearance&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.accent, _this.accent) || other.accent == _this.accent)&&(identical(other.icon, _this.icon) || other.icon == _this.icon));
}


@override
int get hashCode {
  final _this = this as ResourceAppearance;
  return Object.hash(runtimeType,_this.label,_this.accent,_this.icon);
}

@override
String toString() {
  final _this = this as ResourceAppearance;
  return 'ResourceAppearance(label: ${_this.label}, accent: ${_this.accent}, icon: ${_this.icon})';
}


}

/// @nodoc
abstract mixin class $ResourceAppearanceCopyWith<$Res>  {
  factory $ResourceAppearanceCopyWith(ResourceAppearance value, $Res Function(ResourceAppearance) _then) = _$ResourceAppearanceCopyWithImpl;
@useResult
$Res call({
 String label, Color accent, skir.Icon icon
});




}
/// @nodoc
class _$ResourceAppearanceCopyWithImpl<$Res>
    implements $ResourceAppearanceCopyWith<$Res> {
  _$ResourceAppearanceCopyWithImpl(this._self, this._then);

  final ResourceAppearance _self;
  final $Res Function(ResourceAppearance) _then;

/// Create a copy of ResourceAppearance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? accent = null,Object? icon = null,}) {
  return _then(ResourceAppearance(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as skir.Icon,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceAppearance].
extension ResourceAppearancePatterns on ResourceAppearance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceAppearance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceAppearance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceAppearance value)  $default,){
final _that = this;
switch (_that) {
case _ResourceAppearance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceAppearance value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceAppearance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  Color accent,  skir.Icon icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceAppearance() when $default != null:
return $default(_that.label,_that.accent,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  Color accent,  skir.Icon icon)  $default,) {final _that = this;
switch (_that) {
case _ResourceAppearance():
return $default(_that.label,_that.accent,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  Color accent,  skir.Icon icon)?  $default,) {final _that = this;
switch (_that) {
case _ResourceAppearance() when $default != null:
return $default(_that.label,_that.accent,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceAppearance implements ResourceAppearance {
  const _ResourceAppearance({required this.label, required this.accent, required this.icon});
  

@override final  String label;
@override final  Color accent;
@override final  skir.Icon icon;

/// Create a copy of ResourceAppearance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceAppearanceCopyWith<_ResourceAppearance> get copyWith => __$ResourceAppearanceCopyWithImpl<_ResourceAppearance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceAppearance&&(identical(other.label, label) || other.label == label)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,accent,icon);
}

@override
String toString() {
    return 'ResourceAppearance(label: $label, accent: $accent, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$ResourceAppearanceCopyWith<$Res> implements $ResourceAppearanceCopyWith<$Res> {
  factory _$ResourceAppearanceCopyWith(_ResourceAppearance value, $Res Function(_ResourceAppearance) _then) = __$ResourceAppearanceCopyWithImpl;
@override @useResult
$Res call({
 String label, Color accent, skir.Icon icon
});




}
/// @nodoc
class __$ResourceAppearanceCopyWithImpl<$Res>
    implements _$ResourceAppearanceCopyWith<$Res> {
  __$ResourceAppearanceCopyWithImpl(this._self, this._then);

  final _ResourceAppearance _self;
  final $Res Function(_ResourceAppearance) _then;

/// Create a copy of ResourceAppearance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? accent = null,Object? icon = null,}) {
  return _then(_ResourceAppearance(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as skir.Icon,
  ));
}


}

// dart format on
