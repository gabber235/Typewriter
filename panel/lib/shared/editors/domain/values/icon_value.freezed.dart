// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'icon_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IconValue {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IconValue()';
}


}

/// @nodoc
class $IconValueCopyWith<$Res>  {
$IconValueCopyWith(IconValue _, $Res Function(IconValue) __);
}


/// Adds pattern-matching-related methods to [IconValue].
extension IconValuePatterns on IconValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IconifyIconValue value)?  iconify,TResult Function( SvgIconValue value)?  svg,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IconifyIconValue() when iconify != null:
return iconify(_that);case SvgIconValue() when svg != null:
return svg(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IconifyIconValue value)  iconify,required TResult Function( SvgIconValue value)  svg,}){
final _that = this;
switch (_that) {
case IconifyIconValue():
return iconify(_that);case SvgIconValue():
return svg(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IconifyIconValue value)?  iconify,TResult? Function( SvgIconValue value)?  svg,}){
final _that = this;
switch (_that) {
case IconifyIconValue() when iconify != null:
return iconify(_that);case SvgIconValue() when svg != null:
return svg(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String value)?  iconify,TResult Function( String source)?  svg,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IconifyIconValue() when iconify != null:
return iconify(_that.value);case SvgIconValue() when svg != null:
return svg(_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String value)  iconify,required TResult Function( String source)  svg,}) {final _that = this;
switch (_that) {
case IconifyIconValue():
return iconify(_that.value);case SvgIconValue():
return svg(_that.source);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String value)?  iconify,TResult? Function( String source)?  svg,}) {final _that = this;
switch (_that) {
case IconifyIconValue() when iconify != null:
return iconify(_that.value);case SvgIconValue() when svg != null:
return svg(_that.source);case _:
  return null;

}
}

}

/// @nodoc


class IconifyIconValue implements IconValue {
  const IconifyIconValue(this.value): assert(value != "", 'Iconify value must not be empty.');
  

 final  String value;

/// Create a copy of IconValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconifyIconValueCopyWith<IconifyIconValue> get copyWith => _$IconifyIconValueCopyWithImpl<IconifyIconValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconifyIconValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'IconValue.iconify(value: $value)';
}


}

/// @nodoc
abstract mixin class $IconifyIconValueCopyWith<$Res> implements $IconValueCopyWith<$Res> {
  factory $IconifyIconValueCopyWith(IconifyIconValue value, $Res Function(IconifyIconValue) _then) = _$IconifyIconValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$IconifyIconValueCopyWithImpl<$Res>
    implements $IconifyIconValueCopyWith<$Res> {
  _$IconifyIconValueCopyWithImpl(this._self, this._then);

  final IconifyIconValue _self;
  final $Res Function(IconifyIconValue) _then;

/// Create a copy of IconValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(IconifyIconValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SvgIconValue implements IconValue {
  const SvgIconValue(this.source): assert(source != "", 'SVG source must not be empty.');
  

 final  String source;

/// Create a copy of IconValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SvgIconValueCopyWith<SvgIconValue> get copyWith => _$SvgIconValueCopyWithImpl<SvgIconValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SvgIconValue&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'IconValue.svg(source: $source)';
}


}

/// @nodoc
abstract mixin class $SvgIconValueCopyWith<$Res> implements $IconValueCopyWith<$Res> {
  factory $SvgIconValueCopyWith(SvgIconValue value, $Res Function(SvgIconValue) _then) = _$SvgIconValueCopyWithImpl;
@useResult
$Res call({
 String source
});




}
/// @nodoc
class _$SvgIconValueCopyWithImpl<$Res>
    implements $SvgIconValueCopyWith<$Res> {
  _$SvgIconValueCopyWithImpl(this._self, this._then);

  final SvgIconValue _self;
  final $Res Function(SvgIconValue) _then;

/// Create a copy of IconValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(SvgIconValue(
null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
