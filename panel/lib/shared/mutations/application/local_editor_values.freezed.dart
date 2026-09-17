// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_editor_values.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalEditorValue {

 DataValue get value; Set<DataPath> get editedPaths;
/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalEditorValueCopyWith<LocalEditorValue> get copyWith => _$LocalEditorValueCopyWithImpl<LocalEditorValue>(this as LocalEditorValue, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalEditorValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalEditorValue&&(identical(other.value, _this.value) || other.value == _this.value)&&const DeepCollectionEquality().equals(other.editedPaths, _this.editedPaths));
}


@override
int get hashCode {
  final _this = this as LocalEditorValue;
  return Object.hash(runtimeType,_this.value,const DeepCollectionEquality().hash(_this.editedPaths));
}

@override
String toString() {
  final _this = this as LocalEditorValue;
  return 'LocalEditorValue(value: ${_this.value}, editedPaths: ${_this.editedPaths})';
}


}

/// @nodoc
abstract mixin class $LocalEditorValueCopyWith<$Res>  {
  factory $LocalEditorValueCopyWith(LocalEditorValue value, $Res Function(LocalEditorValue) _then) = _$LocalEditorValueCopyWithImpl;
@useResult
$Res call({
 DataValue value, Set<DataPath> editedPaths
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$LocalEditorValueCopyWithImpl<$Res>
    implements $LocalEditorValueCopyWith<$Res> {
  _$LocalEditorValueCopyWithImpl(this._self, this._then);

  final LocalEditorValue _self;
  final $Res Function(LocalEditorValue) _then;

/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? editedPaths = null,}) {
  return _then(LocalEditorValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,editedPaths: null == editedPaths ? _self.editedPaths : editedPaths // ignore: cast_nullable_to_non_nullable
as Set<DataPath>,
  ));
}
/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalEditorValue].
extension LocalEditorValuePatterns on LocalEditorValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalEditorValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalEditorValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalEditorValue value)  $default,){
final _that = this;
switch (_that) {
case _LocalEditorValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalEditorValue value)?  $default,){
final _that = this;
switch (_that) {
case _LocalEditorValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataValue value,  Set<DataPath> editedPaths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalEditorValue() when $default != null:
return $default(_that.value,_that.editedPaths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataValue value,  Set<DataPath> editedPaths)  $default,) {final _that = this;
switch (_that) {
case _LocalEditorValue():
return $default(_that.value,_that.editedPaths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataValue value,  Set<DataPath> editedPaths)?  $default,) {final _that = this;
switch (_that) {
case _LocalEditorValue() when $default != null:
return $default(_that.value,_that.editedPaths);case _:
  return null;

}
}

}

/// @nodoc


class _LocalEditorValue extends LocalEditorValue {
  const _LocalEditorValue({required this.value, required  Set<DataPath> editedPaths}): _editedPaths = editedPaths,super._();
  

@override final  DataValue value;
 final  Set<DataPath> _editedPaths;
@override Set<DataPath> get editedPaths {
  if (_editedPaths is EqualUnmodifiableSetView) return _editedPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_editedPaths);
}


/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalEditorValueCopyWith<_LocalEditorValue> get copyWith => __$LocalEditorValueCopyWithImpl<_LocalEditorValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalEditorValue&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.editedPaths, _editedPaths));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_editedPaths));
}

@override
String toString() {
    return 'LocalEditorValue(value: $value, editedPaths: $editedPaths)';
}


}

/// @nodoc
abstract mixin class _$LocalEditorValueCopyWith<$Res> implements $LocalEditorValueCopyWith<$Res> {
  factory _$LocalEditorValueCopyWith(_LocalEditorValue value, $Res Function(_LocalEditorValue) _then) = __$LocalEditorValueCopyWithImpl;
@override @useResult
$Res call({
 DataValue value, Set<DataPath> editedPaths
});


@override $DataValueCopyWith<$Res> get value;

}
/// @nodoc
class __$LocalEditorValueCopyWithImpl<$Res>
    implements _$LocalEditorValueCopyWith<$Res> {
  __$LocalEditorValueCopyWithImpl(this._self, this._then);

  final _LocalEditorValue _self;
  final $Res Function(_LocalEditorValue) _then;

/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? editedPaths = null,}) {
  return _then(_LocalEditorValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,editedPaths: null == editedPaths ? _self._editedPaths : editedPaths // ignore: cast_nullable_to_non_nullable
as Set<DataPath>,
  ));
}

/// Create a copy of LocalEditorValue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

// dart format on
