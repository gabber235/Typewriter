// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_diagnostic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorDiagnostic {

 EditorDiagnosticCode get code; String get message; skir.ValuePath? get path; EditorDiagnosticSeverity get severity; Map<String, String> get details;
/// Create a copy of EditorDiagnostic
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorDiagnosticCopyWith<EditorDiagnostic> get copyWith => _$EditorDiagnosticCopyWithImpl<EditorDiagnostic>(this as EditorDiagnostic, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorDiagnostic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorDiagnostic&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&const DeepCollectionEquality().equals(other.details, _this.details));
}


@override
int get hashCode {
  final _this = this as EditorDiagnostic;
  return Object.hash(runtimeType,_this.code,_this.message,_this.path,_this.severity,const DeepCollectionEquality().hash(_this.details));
}

@override
String toString() {
  final _this = this as EditorDiagnostic;
  return 'EditorDiagnostic(code: ${_this.code}, message: ${_this.message}, path: ${_this.path}, severity: ${_this.severity}, details: ${_this.details})';
}


}

/// @nodoc
abstract mixin class $EditorDiagnosticCopyWith<$Res>  {
  factory $EditorDiagnosticCopyWith(EditorDiagnostic value, $Res Function(EditorDiagnostic) _then) = _$EditorDiagnosticCopyWithImpl;
@useResult
$Res call({
 EditorDiagnosticCode code, String message, skir.ValuePath? path, EditorDiagnosticSeverity severity, Map<String, String> details
});




}
/// @nodoc
class _$EditorDiagnosticCopyWithImpl<$Res>
    implements $EditorDiagnosticCopyWith<$Res> {
  _$EditorDiagnosticCopyWithImpl(this._self, this._then);

  final EditorDiagnostic _self;
  final $Res Function(EditorDiagnostic) _then;

/// Create a copy of EditorDiagnostic
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? path = freezed,Object? severity = null,Object? details = null,}) {
  return _then(EditorDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as EditorDiagnosticCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as EditorDiagnosticSeverity,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern matching related methods to [EditorDiagnostic].
extension EditorDiagnosticPatterns on EditorDiagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorDiagnostic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _EditorDiagnostic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _EditorDiagnostic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorDiagnosticCode code,  String message,  skir.ValuePath? path,  EditorDiagnosticSeverity severity,  Map<String, String> details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.path,_that.severity,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorDiagnosticCode code,  String message,  skir.ValuePath? path,  EditorDiagnosticSeverity severity,  Map<String, String> details)  $default,) {final _that = this;
switch (_that) {
case _EditorDiagnostic():
return $default(_that.code,_that.message,_that.path,_that.severity,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorDiagnosticCode code,  String message,  skir.ValuePath? path,  EditorDiagnosticSeverity severity,  Map<String, String> details)?  $default,) {final _that = this;
switch (_that) {
case _EditorDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.path,_that.severity,_that.details);case _:
  return null;

}
}

}

/// @nodoc


class _EditorDiagnostic extends EditorDiagnostic {
  const _EditorDiagnostic({required this.code, required this.message, this.path, this.severity = EditorDiagnosticSeverity.error,  Map<String, String> details = const {}}): _details = details,super._();


@override final  EditorDiagnosticCode code;
@override final  String message;
@override final  skir.ValuePath? path;
@override@JsonKey() final  EditorDiagnosticSeverity severity;
 final  Map<String, String> _details;
@override@JsonKey() Map<String, String> get details {
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_details);
}


/// Create a copy of EditorDiagnostic
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorDiagnosticCopyWith<_EditorDiagnostic> get copyWith => __$EditorDiagnosticCopyWithImpl<_EditorDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.path, path) || other.path == path)&&(identical(other.severity, severity) || other.severity == severity)&&const DeepCollectionEquality().equals(other.details, _details));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,message,path,severity,const DeepCollectionEquality().hash(_details));
}

@override
String toString() {
    return 'EditorDiagnostic(code: $code, message: $message, path: $path, severity: $severity, details: $details)';
}


}

/// @nodoc
abstract mixin class _$EditorDiagnosticCopyWith<$Res> implements $EditorDiagnosticCopyWith<$Res> {
  factory _$EditorDiagnosticCopyWith(_EditorDiagnostic value, $Res Function(_EditorDiagnostic) _then) = __$EditorDiagnosticCopyWithImpl;
@override @useResult
$Res call({
 EditorDiagnosticCode code, String message, skir.ValuePath? path, EditorDiagnosticSeverity severity, Map<String, String> details
});




}
/// @nodoc
class __$EditorDiagnosticCopyWithImpl<$Res>
    implements _$EditorDiagnosticCopyWith<$Res> {
  __$EditorDiagnosticCopyWithImpl(this._self, this._then);

  final _EditorDiagnostic _self;
  final $Res Function(_EditorDiagnostic) _then;

/// Create a copy of EditorDiagnostic
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? path = freezed,Object? severity = null,Object? details = null,}) {
  return _then(_EditorDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as EditorDiagnosticCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as EditorDiagnosticSeverity,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
