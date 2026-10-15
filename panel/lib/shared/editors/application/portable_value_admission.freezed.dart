// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_value_admission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableValueInspection {

 List<PortableValueProblem> get structuralProblems; List<skir.ValuePath> get unfinished;
/// Create a copy of PortableValueInspection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableValueInspectionCopyWith<PortableValueInspection> get copyWith => _$PortableValueInspectionCopyWithImpl<PortableValueInspection>(this as PortableValueInspection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableValueInspection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableValueInspection&&const DeepCollectionEquality().equals(other.structuralProblems, _this.structuralProblems)&&const DeepCollectionEquality().equals(other.unfinished, _this.unfinished));
}


@override
int get hashCode {
  final _this = this as PortableValueInspection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.structuralProblems),const DeepCollectionEquality().hash(_this.unfinished));
}

@override
String toString() {
  final _this = this as PortableValueInspection;
  return 'PortableValueInspection(structuralProblems: ${_this.structuralProblems}, unfinished: ${_this.unfinished})';
}


}

/// @nodoc
abstract mixin class $PortableValueInspectionCopyWith<$Res>  {
  factory $PortableValueInspectionCopyWith(PortableValueInspection value, $Res Function(PortableValueInspection) _then) = _$PortableValueInspectionCopyWithImpl;
@useResult
$Res call({
 List<PortableValueProblem> structuralProblems, List<skir.ValuePath> unfinished
});




}
/// @nodoc
class _$PortableValueInspectionCopyWithImpl<$Res>
    implements $PortableValueInspectionCopyWith<$Res> {
  _$PortableValueInspectionCopyWithImpl(this._self, this._then);

  final PortableValueInspection _self;
  final $Res Function(PortableValueInspection) _then;

/// Create a copy of PortableValueInspection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? structuralProblems = null,Object? unfinished = null,}) {
  return _then(PortableValueInspection(
structuralProblems: null == structuralProblems ? _self.structuralProblems : structuralProblems // ignore: cast_nullable_to_non_nullable
as List<PortableValueProblem>,unfinished: null == unfinished ? _self.unfinished : unfinished // ignore: cast_nullable_to_non_nullable
as List<skir.ValuePath>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableValueInspection].
extension PortableValueInspectionPatterns on PortableValueInspection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableValueInspection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableValueInspection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableValueInspection value)  $default,){
final _that = this;
switch (_that) {
case _PortableValueInspection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableValueInspection value)?  $default,){
final _that = this;
switch (_that) {
case _PortableValueInspection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PortableValueProblem> structuralProblems,  List<skir.ValuePath> unfinished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableValueInspection() when $default != null:
return $default(_that.structuralProblems,_that.unfinished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PortableValueProblem> structuralProblems,  List<skir.ValuePath> unfinished)  $default,) {final _that = this;
switch (_that) {
case _PortableValueInspection():
return $default(_that.structuralProblems,_that.unfinished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PortableValueProblem> structuralProblems,  List<skir.ValuePath> unfinished)?  $default,) {final _that = this;
switch (_that) {
case _PortableValueInspection() when $default != null:
return $default(_that.structuralProblems,_that.unfinished);case _:
  return null;

}
}

}

/// @nodoc


class _PortableValueInspection implements PortableValueInspection {
  const _PortableValueInspection({ List<PortableValueProblem> structuralProblems = const [],  List<skir.ValuePath> unfinished = const []}): _structuralProblems = structuralProblems,_unfinished = unfinished;


 final  List<PortableValueProblem> _structuralProblems;
@override@JsonKey() List<PortableValueProblem> get structuralProblems {
  if (_structuralProblems is EqualUnmodifiableListView) return _structuralProblems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_structuralProblems);
}

 final  List<skir.ValuePath> _unfinished;
@override@JsonKey() List<skir.ValuePath> get unfinished {
  if (_unfinished is EqualUnmodifiableListView) return _unfinished;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unfinished);
}


/// Create a copy of PortableValueInspection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableValueInspectionCopyWith<_PortableValueInspection> get copyWith => __$PortableValueInspectionCopyWithImpl<_PortableValueInspection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableValueInspection&&const DeepCollectionEquality().equals(other.structuralProblems, _structuralProblems)&&const DeepCollectionEquality().equals(other.unfinished, _unfinished));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_structuralProblems),const DeepCollectionEquality().hash(_unfinished));
}

@override
String toString() {
    return 'PortableValueInspection(structuralProblems: $structuralProblems, unfinished: $unfinished)';
}


}

/// @nodoc
abstract mixin class _$PortableValueInspectionCopyWith<$Res> implements $PortableValueInspectionCopyWith<$Res> {
  factory _$PortableValueInspectionCopyWith(_PortableValueInspection value, $Res Function(_PortableValueInspection) _then) = __$PortableValueInspectionCopyWithImpl;
@override @useResult
$Res call({
 List<PortableValueProblem> structuralProblems, List<skir.ValuePath> unfinished
});




}
/// @nodoc
class __$PortableValueInspectionCopyWithImpl<$Res>
    implements _$PortableValueInspectionCopyWith<$Res> {
  __$PortableValueInspectionCopyWithImpl(this._self, this._then);

  final _PortableValueInspection _self;
  final $Res Function(_PortableValueInspection) _then;

/// Create a copy of PortableValueInspection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? structuralProblems = null,Object? unfinished = null,}) {
  return _then(_PortableValueInspection(
structuralProblems: null == structuralProblems ? _self._structuralProblems : structuralProblems // ignore: cast_nullable_to_non_nullable
as List<PortableValueProblem>,unfinished: null == unfinished ? _self._unfinished : unfinished // ignore: cast_nullable_to_non_nullable
as List<skir.ValuePath>,
  ));
}


}

/// @nodoc
mixin _$PortableValueProblem {

 skir.ValuePath get path; String get code;
/// Create a copy of PortableValueProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableValueProblemCopyWith<PortableValueProblem> get copyWith => _$PortableValueProblemCopyWithImpl<PortableValueProblem>(this as PortableValueProblem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableValueProblem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableValueProblem&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.code, _this.code) || other.code == _this.code));
}


@override
int get hashCode {
  final _this = this as PortableValueProblem;
  return Object.hash(runtimeType,_this.path,_this.code);
}

@override
String toString() {
  final _this = this as PortableValueProblem;
  return 'PortableValueProblem(path: ${_this.path}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $PortableValueProblemCopyWith<$Res>  {
  factory $PortableValueProblemCopyWith(PortableValueProblem value, $Res Function(PortableValueProblem) _then) = _$PortableValueProblemCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath path, String code
});




}
/// @nodoc
class _$PortableValueProblemCopyWithImpl<$Res>
    implements $PortableValueProblemCopyWith<$Res> {
  _$PortableValueProblemCopyWithImpl(this._self, this._then);

  final PortableValueProblem _self;
  final $Res Function(PortableValueProblem) _then;

/// Create a copy of PortableValueProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? code = null,}) {
  return _then(PortableValueProblem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableValueProblem].
extension PortableValueProblemPatterns on PortableValueProblem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableValueProblem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableValueProblem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableValueProblem value)  $default,){
final _that = this;
switch (_that) {
case _PortableValueProblem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableValueProblem value)?  $default,){
final _that = this;
switch (_that) {
case _PortableValueProblem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValuePath path,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableValueProblem() when $default != null:
return $default(_that.path,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValuePath path,  String code)  $default,) {final _that = this;
switch (_that) {
case _PortableValueProblem():
return $default(_that.path,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValuePath path,  String code)?  $default,) {final _that = this;
switch (_that) {
case _PortableValueProblem() when $default != null:
return $default(_that.path,_that.code);case _:
  return null;

}
}

}

/// @nodoc


class _PortableValueProblem implements PortableValueProblem {
  const _PortableValueProblem({required this.path, required this.code});


@override final  skir.ValuePath path;
@override final  String code;

/// Create a copy of PortableValueProblem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableValueProblemCopyWith<_PortableValueProblem> get copyWith => __$PortableValueProblemCopyWithImpl<_PortableValueProblem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableValueProblem&&(identical(other.path, path) || other.path == path)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,code);
}

@override
String toString() {
    return 'PortableValueProblem(path: $path, code: $code)';
}


}

/// @nodoc
abstract mixin class _$PortableValueProblemCopyWith<$Res> implements $PortableValueProblemCopyWith<$Res> {
  factory _$PortableValueProblemCopyWith(_PortableValueProblem value, $Res Function(_PortableValueProblem) _then) = __$PortableValueProblemCopyWithImpl;
@override @useResult
$Res call({
 skir.ValuePath path, String code
});




}
/// @nodoc
class __$PortableValueProblemCopyWithImpl<$Res>
    implements _$PortableValueProblemCopyWith<$Res> {
  __$PortableValueProblemCopyWithImpl(this._self, this._then);

  final _PortableValueProblem _self;
  final $Res Function(_PortableValueProblem) _then;

/// Create a copy of PortableValueProblem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? code = null,}) {
  return _then(_PortableValueProblem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
