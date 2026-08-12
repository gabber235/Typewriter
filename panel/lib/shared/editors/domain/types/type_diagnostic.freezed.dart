// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'type_diagnostic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypeDiagnosticDetail {

 String get key; String get value;
/// Create a copy of TypeDiagnosticDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeDiagnosticDetailCopyWith<TypeDiagnosticDetail> get copyWith => _$TypeDiagnosticDetailCopyWithImpl<TypeDiagnosticDetail>(this as TypeDiagnosticDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeDiagnosticDetail&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'TypeDiagnosticDetail(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $TypeDiagnosticDetailCopyWith<$Res>  {
  factory $TypeDiagnosticDetailCopyWith(TypeDiagnosticDetail value, $Res Function(TypeDiagnosticDetail) _then) = _$TypeDiagnosticDetailCopyWithImpl;
@useResult
$Res call({
 String key, String value
});




}
/// @nodoc
class _$TypeDiagnosticDetailCopyWithImpl<$Res>
    implements $TypeDiagnosticDetailCopyWith<$Res> {
  _$TypeDiagnosticDetailCopyWithImpl(this._self, this._then);

  final TypeDiagnosticDetail _self;
  final $Res Function(TypeDiagnosticDetail) _then;

/// Create a copy of TypeDiagnosticDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? value = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TypeDiagnosticDetail].
extension TypeDiagnosticDetailPatterns on TypeDiagnosticDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeDiagnosticDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeDiagnosticDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeDiagnosticDetail value)  $default,){
final _that = this;
switch (_that) {
case _TypeDiagnosticDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeDiagnosticDetail value)?  $default,){
final _that = this;
switch (_that) {
case _TypeDiagnosticDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeDiagnosticDetail() when $default != null:
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String value)  $default,) {final _that = this;
switch (_that) {
case _TypeDiagnosticDetail():
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String value)?  $default,) {final _that = this;
switch (_that) {
case _TypeDiagnosticDetail() when $default != null:
return $default(_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _TypeDiagnosticDetail implements TypeDiagnosticDetail {
  const _TypeDiagnosticDetail({required this.key, required this.value});
  

@override final  String key;
@override final  String value;

/// Create a copy of TypeDiagnosticDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeDiagnosticDetailCopyWith<_TypeDiagnosticDetail> get copyWith => __$TypeDiagnosticDetailCopyWithImpl<_TypeDiagnosticDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeDiagnosticDetail&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'TypeDiagnosticDetail(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$TypeDiagnosticDetailCopyWith<$Res> implements $TypeDiagnosticDetailCopyWith<$Res> {
  factory _$TypeDiagnosticDetailCopyWith(_TypeDiagnosticDetail value, $Res Function(_TypeDiagnosticDetail) _then) = __$TypeDiagnosticDetailCopyWithImpl;
@override @useResult
$Res call({
 String key, String value
});




}
/// @nodoc
class __$TypeDiagnosticDetailCopyWithImpl<$Res>
    implements _$TypeDiagnosticDetailCopyWith<$Res> {
  __$TypeDiagnosticDetailCopyWithImpl(this._self, this._then);

  final _TypeDiagnosticDetail _self;
  final $Res Function(_TypeDiagnosticDetail) _then;

/// Create a copy of TypeDiagnosticDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(_TypeDiagnosticDetail(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TypeDiagnostic {

 TypeDiagnosticCode get code; String get message; DataPath get path; ResolvedTypeRef? get type; TypeDiagnosticSeverity get severity; String? get relatedType; List<TypeDiagnosticDetail> get details; bool get pathPresent;
/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeDiagnosticCopyWith<TypeDiagnostic> get copyWith => _$TypeDiagnosticCopyWithImpl<TypeDiagnostic>(this as TypeDiagnostic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.relatedType, relatedType) || other.relatedType == relatedType)&&const DeepCollectionEquality().equals(other.details, details)&&(identical(other.pathPresent, pathPresent) || other.pathPresent == pathPresent));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,path,type,severity,relatedType,const DeepCollectionEquality().hash(details),pathPresent);



}

/// @nodoc
abstract mixin class $TypeDiagnosticCopyWith<$Res>  {
  factory $TypeDiagnosticCopyWith(TypeDiagnostic value, $Res Function(TypeDiagnostic) _then) = _$TypeDiagnosticCopyWithImpl;
@useResult
$Res call({
 TypeDiagnosticCode code, String message, DataPath path, ResolvedTypeRef? type, TypeDiagnosticSeverity severity, String? relatedType, List<TypeDiagnosticDetail> details, bool pathPresent
});


$DataPathCopyWith<$Res> get path;$ResolvedTypeRefCopyWith<$Res>? get type;

}
/// @nodoc
class _$TypeDiagnosticCopyWithImpl<$Res>
    implements $TypeDiagnosticCopyWith<$Res> {
  _$TypeDiagnosticCopyWithImpl(this._self, this._then);

  final TypeDiagnostic _self;
  final $Res Function(TypeDiagnostic) _then;

/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? path = null,Object? type = freezed,Object? severity = null,Object? relatedType = freezed,Object? details = null,Object? pathPresent = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as TypeDiagnosticCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as TypeDiagnosticSeverity,relatedType: freezed == relatedType ? _self.relatedType : relatedType // ignore: cast_nullable_to_non_nullable
as String?,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnosticDetail>,pathPresent: null == pathPresent ? _self.pathPresent : pathPresent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $ResolvedTypeRefCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeDiagnostic].
extension TypeDiagnosticPatterns on TypeDiagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeDiagnostic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _TypeDiagnostic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _TypeDiagnostic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeDiagnosticCode code,  String message,  DataPath path,  ResolvedTypeRef? type,  TypeDiagnosticSeverity severity,  String? relatedType,  List<TypeDiagnosticDetail> details,  bool pathPresent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.path,_that.type,_that.severity,_that.relatedType,_that.details,_that.pathPresent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeDiagnosticCode code,  String message,  DataPath path,  ResolvedTypeRef? type,  TypeDiagnosticSeverity severity,  String? relatedType,  List<TypeDiagnosticDetail> details,  bool pathPresent)  $default,) {final _that = this;
switch (_that) {
case _TypeDiagnostic():
return $default(_that.code,_that.message,_that.path,_that.type,_that.severity,_that.relatedType,_that.details,_that.pathPresent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeDiagnosticCode code,  String message,  DataPath path,  ResolvedTypeRef? type,  TypeDiagnosticSeverity severity,  String? relatedType,  List<TypeDiagnosticDetail> details,  bool pathPresent)?  $default,) {final _that = this;
switch (_that) {
case _TypeDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.path,_that.type,_that.severity,_that.relatedType,_that.details,_that.pathPresent);case _:
  return null;

}
}

}

/// @nodoc


class _TypeDiagnostic extends TypeDiagnostic {
  const _TypeDiagnostic({required this.code, required this.message, this.path = DataPath.root, this.type, this.severity = TypeDiagnosticSeverity.error, this.relatedType, final  List<TypeDiagnosticDetail> details = const [], this.pathPresent = true}): _details = details,super._();
  

@override final  TypeDiagnosticCode code;
@override final  String message;
@override@JsonKey() final  DataPath path;
@override final  ResolvedTypeRef? type;
@override@JsonKey() final  TypeDiagnosticSeverity severity;
@override final  String? relatedType;
 final  List<TypeDiagnosticDetail> _details;
@override@JsonKey() List<TypeDiagnosticDetail> get details {
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_details);
}

@override@JsonKey() final  bool pathPresent;

/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeDiagnosticCopyWith<_TypeDiagnostic> get copyWith => __$TypeDiagnosticCopyWithImpl<_TypeDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.relatedType, relatedType) || other.relatedType == relatedType)&&const DeepCollectionEquality().equals(other._details, _details)&&(identical(other.pathPresent, pathPresent) || other.pathPresent == pathPresent));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,path,type,severity,relatedType,const DeepCollectionEquality().hash(_details),pathPresent);



}

/// @nodoc
abstract mixin class _$TypeDiagnosticCopyWith<$Res> implements $TypeDiagnosticCopyWith<$Res> {
  factory _$TypeDiagnosticCopyWith(_TypeDiagnostic value, $Res Function(_TypeDiagnostic) _then) = __$TypeDiagnosticCopyWithImpl;
@override @useResult
$Res call({
 TypeDiagnosticCode code, String message, DataPath path, ResolvedTypeRef? type, TypeDiagnosticSeverity severity, String? relatedType, List<TypeDiagnosticDetail> details, bool pathPresent
});


@override $DataPathCopyWith<$Res> get path;@override $ResolvedTypeRefCopyWith<$Res>? get type;

}
/// @nodoc
class __$TypeDiagnosticCopyWithImpl<$Res>
    implements _$TypeDiagnosticCopyWith<$Res> {
  __$TypeDiagnosticCopyWithImpl(this._self, this._then);

  final _TypeDiagnostic _self;
  final $Res Function(_TypeDiagnostic) _then;

/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? path = null,Object? type = freezed,Object? severity = null,Object? relatedType = freezed,Object? details = null,Object? pathPresent = null,}) {
  return _then(_TypeDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as TypeDiagnosticCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as TypeDiagnosticSeverity,relatedType: freezed == relatedType ? _self.relatedType : relatedType // ignore: cast_nullable_to_non_nullable
as String?,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnosticDetail>,pathPresent: null == pathPresent ? _self.pathPresent : pathPresent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of TypeDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $ResolvedTypeRefCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc
mixin _$TypeResult<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeResult<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeResult<$T>()';
}


}

/// @nodoc
class $TypeResultCopyWith<T,$Res>  {
$TypeResultCopyWith(TypeResult<T> _, $Res Function(TypeResult<T>) __);
}


/// Adds pattern-matching-related methods to [TypeResult].
extension TypeResultPatterns<T> on TypeResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TypeSuccess<T> value)?  success,TResult Function( TypeFailure<T> value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TypeSuccess() when success != null:
return success(_that);case TypeFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TypeSuccess<T> value)  success,required TResult Function( TypeFailure<T> value)  failure,}){
final _that = this;
switch (_that) {
case TypeSuccess():
return success(_that);case TypeFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TypeSuccess<T> value)?  success,TResult? Function( TypeFailure<T> value)?  failure,}){
final _that = this;
switch (_that) {
case TypeSuccess() when success != null:
return success(_that);case TypeFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T value)?  success,TResult Function( List<TypeDiagnostic> diagnostics)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TypeSuccess() when success != null:
return success(_that.value);case TypeFailure() when failure != null:
return failure(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T value)  success,required TResult Function( List<TypeDiagnostic> diagnostics)  failure,}) {final _that = this;
switch (_that) {
case TypeSuccess():
return success(_that.value);case TypeFailure():
return failure(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T value)?  success,TResult? Function( List<TypeDiagnostic> diagnostics)?  failure,}) {final _that = this;
switch (_that) {
case TypeSuccess() when success != null:
return success(_that.value);case TypeFailure() when failure != null:
return failure(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class TypeSuccess<T> extends TypeResult<T> {
  const TypeSuccess(this.value): super._();
  

 final  T value;

/// Create a copy of TypeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeSuccessCopyWith<T, TypeSuccess<T>> get copyWith => _$TypeSuccessCopyWithImpl<T, TypeSuccess<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeSuccess<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'TypeResult<$T>.success(value: $value)';
}


}

/// @nodoc
abstract mixin class $TypeSuccessCopyWith<T,$Res> implements $TypeResultCopyWith<T, $Res> {
  factory $TypeSuccessCopyWith(TypeSuccess<T> value, $Res Function(TypeSuccess<T>) _then) = _$TypeSuccessCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$TypeSuccessCopyWithImpl<T,$Res>
    implements $TypeSuccessCopyWith<T, $Res> {
  _$TypeSuccessCopyWithImpl(this._self, this._then);

  final TypeSuccess<T> _self;
  final $Res Function(TypeSuccess<T>) _then;

/// Create a copy of TypeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(TypeSuccess<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class TypeFailure<T> extends TypeResult<T> {
   TypeFailure(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.length > 0, 'Diagnostics must not be empty.'),_diagnostics = diagnostics,super._();
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of TypeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeFailureCopyWith<T, TypeFailure<T>> get copyWith => _$TypeFailureCopyWithImpl<T, TypeFailure<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeFailure<T>&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'TypeResult<$T>.failure(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $TypeFailureCopyWith<T,$Res> implements $TypeResultCopyWith<T, $Res> {
  factory $TypeFailureCopyWith(TypeFailure<T> value, $Res Function(TypeFailure<T>) _then) = _$TypeFailureCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$TypeFailureCopyWithImpl<T,$Res>
    implements $TypeFailureCopyWith<T, $Res> {
  _$TypeFailureCopyWithImpl(this._self, this._then);

  final TypeFailure<T> _self;
  final $Res Function(TypeFailure<T>) _then;

/// Create a copy of TypeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(TypeFailure<T>(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
