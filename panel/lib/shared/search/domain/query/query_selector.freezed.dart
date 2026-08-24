// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'query_selector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuerySelectorValue {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuerySelectorValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QuerySelectorValue()';
}


}

/// @nodoc
class $QuerySelectorValueCopyWith<$Res>  {
$QuerySelectorValueCopyWith(QuerySelectorValue _, $Res Function(QuerySelectorValue) __);
}


/// Adds pattern-matching-related methods to [QuerySelectorValue].
extension QuerySelectorValuePatterns on QuerySelectorValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FreeTextSelectorValue value)?  freeText,TResult Function( EnumSelectorValue value)?  enumValue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FreeTextSelectorValue() when freeText != null:
return freeText(_that);case EnumSelectorValue() when enumValue != null:
return enumValue(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FreeTextSelectorValue value)  freeText,required TResult Function( EnumSelectorValue value)  enumValue,}){
final _that = this;
switch (_that) {
case FreeTextSelectorValue():
return freeText(_that);case EnumSelectorValue():
return enumValue(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FreeTextSelectorValue value)?  freeText,TResult? Function( EnumSelectorValue value)?  enumValue,}){
final _that = this;
switch (_that) {
case FreeTextSelectorValue() when freeText != null:
return freeText(_that);case EnumSelectorValue() when enumValue != null:
return enumValue(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  freeText,TResult Function( List<String> possibleValues)?  enumValue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FreeTextSelectorValue() when freeText != null:
return freeText();case EnumSelectorValue() when enumValue != null:
return enumValue(_that.possibleValues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  freeText,required TResult Function( List<String> possibleValues)  enumValue,}) {final _that = this;
switch (_that) {
case FreeTextSelectorValue():
return freeText();case EnumSelectorValue():
return enumValue(_that.possibleValues);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  freeText,TResult? Function( List<String> possibleValues)?  enumValue,}) {final _that = this;
switch (_that) {
case FreeTextSelectorValue() when freeText != null:
return freeText();case EnumSelectorValue() when enumValue != null:
return enumValue(_that.possibleValues);case _:
  return null;

}
}

}

/// @nodoc


class FreeTextSelectorValue extends QuerySelectorValue {
  const FreeTextSelectorValue(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeTextSelectorValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QuerySelectorValue.freeText()';
}


}




/// @nodoc


class EnumSelectorValue extends QuerySelectorValue {
  const EnumSelectorValue(final  List<String> possibleValues): _possibleValues = possibleValues,super._();
  

 final  List<String> _possibleValues;
 List<String> get possibleValues {
  if (_possibleValues is EqualUnmodifiableListView) return _possibleValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_possibleValues);
}


/// Create a copy of QuerySelectorValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnumSelectorValueCopyWith<EnumSelectorValue> get copyWith => _$EnumSelectorValueCopyWithImpl<EnumSelectorValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnumSelectorValue&&const DeepCollectionEquality().equals(other._possibleValues, _possibleValues));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_possibleValues));

@override
String toString() {
  return 'QuerySelectorValue.enumValue(possibleValues: $possibleValues)';
}


}

/// @nodoc
abstract mixin class $EnumSelectorValueCopyWith<$Res> implements $QuerySelectorValueCopyWith<$Res> {
  factory $EnumSelectorValueCopyWith(EnumSelectorValue value, $Res Function(EnumSelectorValue) _then) = _$EnumSelectorValueCopyWithImpl;
@useResult
$Res call({
 List<String> possibleValues
});




}
/// @nodoc
class _$EnumSelectorValueCopyWithImpl<$Res>
    implements $EnumSelectorValueCopyWith<$Res> {
  _$EnumSelectorValueCopyWithImpl(this._self, this._then);

  final EnumSelectorValue _self;
  final $Res Function(EnumSelectorValue) _then;

/// Create a copy of QuerySelectorValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? possibleValues = null,}) {
  return _then(EnumSelectorValue(
null == possibleValues ? _self._possibleValues : possibleValues // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
