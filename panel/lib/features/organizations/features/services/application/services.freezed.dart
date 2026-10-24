// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'services.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopologySelectOption {

 String get id; String get label; String get value;
/// Create a copy of _TopologySelectOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologySelectOptionCopyWith<_TopologySelectOption> get copyWith => __$TopologySelectOptionCopyWithImpl<_TopologySelectOption>(this as _TopologySelectOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _TopologySelectOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologySelectOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as _TopologySelectOption;
  return Object.hash(runtimeType,_this.id,_this.label,_this.value);
}

@override
String toString() {
  final _this = this as _TopologySelectOption;
  return '_TopologySelectOption(id: ${_this.id}, label: ${_this.label}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class _$TopologySelectOptionCopyWith<$Res>  {
  factory _$TopologySelectOptionCopyWith(_TopologySelectOption value, $Res Function(_TopologySelectOption) _then) = __$TopologySelectOptionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String value
});




}
/// @nodoc
class __$TopologySelectOptionCopyWithImpl<$Res>
    implements _$TopologySelectOptionCopyWith<$Res> {
  __$TopologySelectOptionCopyWithImpl(this._self, this._then);

  final _TopologySelectOption _self;
  final $Res Function(_TopologySelectOption) _then;

/// Create a copy of _TopologySelectOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(_TopologySelectOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [_TopologySelectOption].
extension _TopologySelectOptionPatterns on _TopologySelectOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __TopologySelectOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __TopologySelectOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __TopologySelectOption value)  $default,){
final _that = this;
switch (_that) {
case __TopologySelectOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __TopologySelectOption value)?  $default,){
final _that = this;
switch (_that) {
case __TopologySelectOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __TopologySelectOption() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String value)  $default,) {final _that = this;
switch (_that) {
case __TopologySelectOption():
return $default(_that.id,_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String value)?  $default,) {final _that = this;
switch (_that) {
case __TopologySelectOption() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class __TopologySelectOption implements _TopologySelectOption {
  const __TopologySelectOption({required this.id, required this.label, required this.value});
  

@override final  String id;
@override final  String label;
@override final  String value;

/// Create a copy of _TopologySelectOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_TopologySelectOptionCopyWith<__TopologySelectOption> get copyWith => __$_TopologySelectOptionCopyWithImpl<__TopologySelectOption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __TopologySelectOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,value);
}

@override
String toString() {
    return '_TopologySelectOption(id: $id, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$_TopologySelectOptionCopyWith<$Res> implements _$TopologySelectOptionCopyWith<$Res> {
  factory _$_TopologySelectOptionCopyWith(__TopologySelectOption value, $Res Function(__TopologySelectOption) _then) = __$_TopologySelectOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String value
});




}
/// @nodoc
class __$_TopologySelectOptionCopyWithImpl<$Res>
    implements _$_TopologySelectOptionCopyWith<$Res> {
  __$_TopologySelectOptionCopyWithImpl(this._self, this._then);

  final __TopologySelectOption _self;
  final $Res Function(__TopologySelectOption) _then;

/// Create a copy of _TopologySelectOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(__TopologySelectOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
