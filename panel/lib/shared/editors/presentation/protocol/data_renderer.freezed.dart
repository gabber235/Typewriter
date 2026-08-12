// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RepeatedItem {

 TypeExpression get type; DataValue get value; int get revision; BindingReference? get canonical;
/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepeatedItemCopyWith<_RepeatedItem> get copyWith => __$RepeatedItemCopyWithImpl<_RepeatedItem>(this as _RepeatedItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepeatedItem&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.canonical, canonical) || other.canonical == canonical));
}


@override
int get hashCode => Object.hash(runtimeType,type,value,revision,canonical);

@override
String toString() {
  return '_RepeatedItem(type: $type, value: $value, revision: $revision, canonical: $canonical)';
}


}

/// @nodoc
abstract mixin class _$RepeatedItemCopyWith<$Res>  {
  factory _$RepeatedItemCopyWith(_RepeatedItem value, $Res Function(_RepeatedItem) _then) = __$RepeatedItemCopyWithImpl;
@useResult
$Res call({
 TypeExpression type, DataValue value, int revision, BindingReference? canonical
});


$TypeExpressionCopyWith<$Res> get type;$DataValueCopyWith<$Res> get value;$BindingReferenceCopyWith<$Res>? get canonical;

}
/// @nodoc
class __$RepeatedItemCopyWithImpl<$Res>
    implements _$RepeatedItemCopyWith<$Res> {
  __$RepeatedItemCopyWithImpl(this._self, this._then);

  final _RepeatedItem _self;
  final $Res Function(_RepeatedItem) _then;

/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,Object? revision = null,Object? canonical = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,canonical: freezed == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as BindingReference?,
  ));
}
/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res>? get canonical {
    if (_self.canonical == null) {
    return null;
  }

  return $BindingReferenceCopyWith<$Res>(_self.canonical!, (value) {
    return _then(_self.copyWith(canonical: value));
  });
}
}


/// Adds pattern-matching-related methods to [_RepeatedItem].
extension _RepeatedItemPatterns on _RepeatedItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepeatedItemValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepeatedItemValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepeatedItemValue value)  $default,){
final _that = this;
switch (_that) {
case _RepeatedItemValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepeatedItemValue value)?  $default,){
final _that = this;
switch (_that) {
case _RepeatedItemValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeExpression type,  DataValue value,  int revision,  BindingReference? canonical)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepeatedItemValue() when $default != null:
return $default(_that.type,_that.value,_that.revision,_that.canonical);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeExpression type,  DataValue value,  int revision,  BindingReference? canonical)  $default,) {final _that = this;
switch (_that) {
case _RepeatedItemValue():
return $default(_that.type,_that.value,_that.revision,_that.canonical);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeExpression type,  DataValue value,  int revision,  BindingReference? canonical)?  $default,) {final _that = this;
switch (_that) {
case _RepeatedItemValue() when $default != null:
return $default(_that.type,_that.value,_that.revision,_that.canonical);case _:
  return null;

}
}

}

/// @nodoc


class _RepeatedItemValue implements _RepeatedItem {
  const _RepeatedItemValue({required this.type, required this.value, required this.revision, required this.canonical});
  

@override final  TypeExpression type;
@override final  DataValue value;
@override final  int revision;
@override final  BindingReference? canonical;

/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepeatedItemValueCopyWith<_RepeatedItemValue> get copyWith => __$RepeatedItemValueCopyWithImpl<_RepeatedItemValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepeatedItemValue&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.canonical, canonical) || other.canonical == canonical));
}


@override
int get hashCode => Object.hash(runtimeType,type,value,revision,canonical);

@override
String toString() {
  return '_RepeatedItem(type: $type, value: $value, revision: $revision, canonical: $canonical)';
}


}

/// @nodoc
abstract mixin class _$RepeatedItemValueCopyWith<$Res> implements _$RepeatedItemCopyWith<$Res> {
  factory _$RepeatedItemValueCopyWith(_RepeatedItemValue value, $Res Function(_RepeatedItemValue) _then) = __$RepeatedItemValueCopyWithImpl;
@override @useResult
$Res call({
 TypeExpression type, DataValue value, int revision, BindingReference? canonical
});


@override $TypeExpressionCopyWith<$Res> get type;@override $DataValueCopyWith<$Res> get value;@override $BindingReferenceCopyWith<$Res>? get canonical;

}
/// @nodoc
class __$RepeatedItemValueCopyWithImpl<$Res>
    implements _$RepeatedItemValueCopyWith<$Res> {
  __$RepeatedItemValueCopyWithImpl(this._self, this._then);

  final _RepeatedItemValue _self;
  final $Res Function(_RepeatedItemValue) _then;

/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,Object? revision = null,Object? canonical = freezed,}) {
  return _then(_RepeatedItemValue(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,canonical: freezed == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as BindingReference?,
  ));
}

/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}/// Create a copy of _RepeatedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res>? get canonical {
    if (_self.canonical == null) {
    return null;
  }

  return $BindingReferenceCopyWith<$Res>(_self.canonical!, (value) {
    return _then(_self.copyWith(canonical: value));
  });
}
}

// dart format on
