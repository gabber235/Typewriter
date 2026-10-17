// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canonical_reconciliation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CanonicalReconciliation<T> {

 List<T> get values; T get canonical;
/// Create a copy of CanonicalReconciliation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanonicalReconciliationCopyWith<T, CanonicalReconciliation<T>> get copyWith => _$CanonicalReconciliationCopyWithImpl<T, CanonicalReconciliation<T>>(this as CanonicalReconciliation<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CanonicalReconciliation<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanonicalReconciliation<T>&&const DeepCollectionEquality().equals(other.values, _this.values)&&const DeepCollectionEquality().equals(other.canonical, _this.canonical));
}


@override
int get hashCode {
  final _this = this as CanonicalReconciliation<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.values),const DeepCollectionEquality().hash(_this.canonical));
}

@override
String toString() {
  final _this = this as CanonicalReconciliation<T>;
  return 'CanonicalReconciliation<$T>(values: ${_this.values}, canonical: ${_this.canonical})';
}


}

/// @nodoc
abstract mixin class $CanonicalReconciliationCopyWith<T,$Res>  {
  factory $CanonicalReconciliationCopyWith(CanonicalReconciliation<T> value, $Res Function(CanonicalReconciliation<T>) _then) = _$CanonicalReconciliationCopyWithImpl;
@useResult
$Res call({
 List<T> values, T canonical
});




}
/// @nodoc
class _$CanonicalReconciliationCopyWithImpl<T,$Res>
    implements $CanonicalReconciliationCopyWith<T, $Res> {
  _$CanonicalReconciliationCopyWithImpl(this._self, this._then);

  final CanonicalReconciliation<T> _self;
  final $Res Function(CanonicalReconciliation<T>) _then;

/// Create a copy of CanonicalReconciliation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? values = null,Object? canonical = freezed,}) {
  return _then(CanonicalReconciliation(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<T>,canonical: freezed == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as T,
  ));
}

}


/// Adds pattern matching related methods to [CanonicalReconciliation].
extension CanonicalReconciliationPatterns<T> on CanonicalReconciliation<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanonicalReconciliation<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanonicalReconciliation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanonicalReconciliation<T> value)  $default,){
final _that = this;
switch (_that) {
case _CanonicalReconciliation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanonicalReconciliation<T> value)?  $default,){
final _that = this;
switch (_that) {
case _CanonicalReconciliation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> values,  T canonical)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanonicalReconciliation() when $default != null:
return $default(_that.values,_that.canonical);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> values,  T canonical)  $default,) {final _that = this;
switch (_that) {
case _CanonicalReconciliation():
return $default(_that.values,_that.canonical);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> values,  T canonical)?  $default,) {final _that = this;
switch (_that) {
case _CanonicalReconciliation() when $default != null:
return $default(_that.values,_that.canonical);case _:
  return null;

}
}

}

/// @nodoc


class _CanonicalReconciliation<T> implements CanonicalReconciliation<T> {
  const _CanonicalReconciliation({required  List<T> values, required this.canonical}): _values = values;


 final  List<T> _values;
@override List<T> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}

@override final  T canonical;

/// Create a copy of CanonicalReconciliation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanonicalReconciliationCopyWith<T, _CanonicalReconciliation<T>> get copyWith => __$CanonicalReconciliationCopyWithImpl<T, _CanonicalReconciliation<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanonicalReconciliation<T>&&const DeepCollectionEquality().equals(other.values, _values)&&const DeepCollectionEquality().equals(other.canonical, canonical));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_values),const DeepCollectionEquality().hash(canonical));
}

@override
String toString() {
    return 'CanonicalReconciliation<$T>(values: $values, canonical: $canonical)';
}


}

/// @nodoc
abstract mixin class _$CanonicalReconciliationCopyWith<T,$Res> implements $CanonicalReconciliationCopyWith<T, $Res> {
  factory _$CanonicalReconciliationCopyWith(_CanonicalReconciliation<T> value, $Res Function(_CanonicalReconciliation<T>) _then) = __$CanonicalReconciliationCopyWithImpl;
@override @useResult
$Res call({
 List<T> values, T canonical
});




}
/// @nodoc
class __$CanonicalReconciliationCopyWithImpl<T,$Res>
    implements _$CanonicalReconciliationCopyWith<T, $Res> {
  __$CanonicalReconciliationCopyWithImpl(this._self, this._then);

  final _CanonicalReconciliation<T> _self;
  final $Res Function(_CanonicalReconciliation<T>) _then;

/// Create a copy of CanonicalReconciliation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? values = null,Object? canonical = freezed,}) {
  return _then(_CanonicalReconciliation<T>(
values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<T>,canonical: freezed == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

// dart format on
