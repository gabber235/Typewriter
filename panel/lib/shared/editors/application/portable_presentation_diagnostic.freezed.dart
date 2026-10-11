// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_diagnostic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableDiagnosticTarget {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticTarget);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableDiagnosticTarget()';
}


}

/// @nodoc
class $PortableDiagnosticTargetCopyWith<$Res>  {
$PortableDiagnosticTargetCopyWith(PortableDiagnosticTarget _, $Res Function(PortableDiagnosticTarget) __);
}


/// Adds pattern matching related methods to [PortableDiagnosticTarget].
extension PortableDiagnosticTargetPatterns on PortableDiagnosticTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableBindingDiagnosticTarget value)?  binding,TResult Function( PortableValueDiagnosticTarget value)?  value,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget() when binding != null:
return binding(_that);case PortableValueDiagnosticTarget() when value != null:
return value(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableBindingDiagnosticTarget value)  binding,required TResult Function( PortableValueDiagnosticTarget value)  value,}){
final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget():
return binding(_that);case PortableValueDiagnosticTarget():
return value(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableBindingDiagnosticTarget value)?  binding,TResult? Function( PortableValueDiagnosticTarget value)?  value,}){
final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget() when binding != null:
return binding(_that);case PortableValueDiagnosticTarget() when value != null:
return value(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.BindingRef reference)?  binding,TResult Function( skir.ValueLocation location)?  value,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget() when binding != null:
return binding(_that.reference);case PortableValueDiagnosticTarget() when value != null:
return value(_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.BindingRef reference)  binding,required TResult Function( skir.ValueLocation location)  value,}) {final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget():
return binding(_that.reference);case PortableValueDiagnosticTarget():
return value(_that.location);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.BindingRef reference)?  binding,TResult? Function( skir.ValueLocation location)?  value,}) {final _that = this;
switch (_that) {
case PortableBindingDiagnosticTarget() when binding != null:
return binding(_that.reference);case PortableValueDiagnosticTarget() when value != null:
return value(_that.location);case _:
  return null;

}
}

}

/// @nodoc


class PortableBindingDiagnosticTarget extends PortableDiagnosticTarget {
  const PortableBindingDiagnosticTarget(this.reference): super._();


 final  skir.BindingRef reference;

/// Create a copy of PortableDiagnosticTarget
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableBindingDiagnosticTargetCopyWith<PortableBindingDiagnosticTarget> get copyWith => _$PortableBindingDiagnosticTargetCopyWithImpl<PortableBindingDiagnosticTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableBindingDiagnosticTarget&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference);
}

@override
String toString() {
    return 'PortableDiagnosticTarget.binding(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $PortableBindingDiagnosticTargetCopyWith<$Res> implements $PortableDiagnosticTargetCopyWith<$Res> {
  factory $PortableBindingDiagnosticTargetCopyWith(PortableBindingDiagnosticTarget value, $Res Function(PortableBindingDiagnosticTarget) _then) = _$PortableBindingDiagnosticTargetCopyWithImpl;
@useResult
$Res call({
 skir.BindingRef reference
});




}
/// @nodoc
class _$PortableBindingDiagnosticTargetCopyWithImpl<$Res>
    implements $PortableBindingDiagnosticTargetCopyWith<$Res> {
  _$PortableBindingDiagnosticTargetCopyWithImpl(this._self, this._then);

  final PortableBindingDiagnosticTarget _self;
  final $Res Function(PortableBindingDiagnosticTarget) _then;

/// Create a copy of PortableDiagnosticTarget
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(PortableBindingDiagnosticTarget(
null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as skir.BindingRef,
  ));
}


}

/// @nodoc


class PortableValueDiagnosticTarget extends PortableDiagnosticTarget {
  const PortableValueDiagnosticTarget(this.location): super._();


 final  skir.ValueLocation location;

/// Create a copy of PortableDiagnosticTarget
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableValueDiagnosticTargetCopyWith<PortableValueDiagnosticTarget> get copyWith => _$PortableValueDiagnosticTargetCopyWithImpl<PortableValueDiagnosticTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableValueDiagnosticTarget&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode {
    return Object.hash(runtimeType,location);
}

@override
String toString() {
    return 'PortableDiagnosticTarget.value(location: $location)';
}


}

/// @nodoc
abstract mixin class $PortableValueDiagnosticTargetCopyWith<$Res> implements $PortableDiagnosticTargetCopyWith<$Res> {
  factory $PortableValueDiagnosticTargetCopyWith(PortableValueDiagnosticTarget value, $Res Function(PortableValueDiagnosticTarget) _then) = _$PortableValueDiagnosticTargetCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation location
});




}
/// @nodoc
class _$PortableValueDiagnosticTargetCopyWithImpl<$Res>
    implements $PortableValueDiagnosticTargetCopyWith<$Res> {
  _$PortableValueDiagnosticTargetCopyWithImpl(this._self, this._then);

  final PortableValueDiagnosticTarget _self;
  final $Res Function(PortableValueDiagnosticTarget) _then;

/// Create a copy of PortableDiagnosticTarget
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? location = null,}) {
  return _then(PortableValueDiagnosticTarget(
null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,
  ));
}


}

/// @nodoc
mixin _$PortablePresentationDiagnostic {

 String get code; String get message; skir.DiagnosticSeverity get severity; List<PortableDiagnosticTarget> get targets; Map<String, String> get details; skir.DiagnosticId? get id; skir.RuleOrigin? get origin;
/// Create a copy of PortablePresentationDiagnostic
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationDiagnosticCopyWith<PortablePresentationDiagnostic> get copyWith => _$PortablePresentationDiagnosticCopyWithImpl<PortablePresentationDiagnostic>(this as PortablePresentationDiagnostic, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationDiagnostic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationDiagnostic&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&const DeepCollectionEquality().equals(other.targets, _this.targets)&&const DeepCollectionEquality().equals(other.details, _this.details)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.origin, _this.origin) || other.origin == _this.origin));
}


@override
int get hashCode {
  final _this = this as PortablePresentationDiagnostic;
  return Object.hash(runtimeType,_this.code,_this.message,_this.severity,const DeepCollectionEquality().hash(_this.targets),const DeepCollectionEquality().hash(_this.details),_this.id,_this.origin);
}

@override
String toString() {
  final _this = this as PortablePresentationDiagnostic;
  return 'PortablePresentationDiagnostic(code: ${_this.code}, message: ${_this.message}, severity: ${_this.severity}, targets: ${_this.targets}, details: ${_this.details}, id: ${_this.id}, origin: ${_this.origin})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationDiagnosticCopyWith<$Res>  {
  factory $PortablePresentationDiagnosticCopyWith(PortablePresentationDiagnostic value, $Res Function(PortablePresentationDiagnostic) _then) = _$PortablePresentationDiagnosticCopyWithImpl;
@useResult
$Res call({
 String code, String message, skir.DiagnosticSeverity severity, List<PortableDiagnosticTarget> targets, Map<String, String> details, skir.DiagnosticId? id, skir.RuleOrigin? origin
});




}
/// @nodoc
class _$PortablePresentationDiagnosticCopyWithImpl<$Res>
    implements $PortablePresentationDiagnosticCopyWith<$Res> {
  _$PortablePresentationDiagnosticCopyWithImpl(this._self, this._then);

  final PortablePresentationDiagnostic _self;
  final $Res Function(PortablePresentationDiagnostic) _then;

/// Create a copy of PortablePresentationDiagnostic
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? severity = null,Object? targets = null,Object? details = null,Object? id = freezed,Object? origin = freezed,}) {
  return _then(PortablePresentationDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticSeverity,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticTarget>,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, String>,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticId?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as skir.RuleOrigin?,
  ));
}

}


/// Adds pattern matching related methods to [PortablePresentationDiagnostic].
extension PortablePresentationDiagnosticPatterns on PortablePresentationDiagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePresentationDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePresentationDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePresentationDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  skir.DiagnosticSeverity severity,  List<PortableDiagnosticTarget> targets,  Map<String, String> details,  skir.DiagnosticId? id,  skir.RuleOrigin? origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.severity,_that.targets,_that.details,_that.id,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  skir.DiagnosticSeverity severity,  List<PortableDiagnosticTarget> targets,  Map<String, String> details,  skir.DiagnosticId? id,  skir.RuleOrigin? origin)  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic():
return $default(_that.code,_that.message,_that.severity,_that.targets,_that.details,_that.id,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  skir.DiagnosticSeverity severity,  List<PortableDiagnosticTarget> targets,  Map<String, String> details,  skir.DiagnosticId? id,  skir.RuleOrigin? origin)?  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.severity,_that.targets,_that.details,_that.id,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePresentationDiagnostic implements PortablePresentationDiagnostic {
  const _PortablePresentationDiagnostic({required this.code, required this.message, required this.severity,  List<PortableDiagnosticTarget> targets = const [],  Map<String, String> details = const {}, this.id, this.origin}): _targets = targets,_details = details;


@override final  String code;
@override final  String message;
@override final  skir.DiagnosticSeverity severity;
 final  List<PortableDiagnosticTarget> _targets;
@override@JsonKey() List<PortableDiagnosticTarget> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

 final  Map<String, String> _details;
@override@JsonKey() Map<String, String> get details {
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_details);
}

@override final  skir.DiagnosticId? id;
@override final  skir.RuleOrigin? origin;

/// Create a copy of PortablePresentationDiagnostic
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationDiagnosticCopyWith<_PortablePresentationDiagnostic> get copyWith => __$PortablePresentationDiagnosticCopyWithImpl<_PortablePresentationDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.severity, severity) || other.severity == severity)&&const DeepCollectionEquality().equals(other.targets, _targets)&&const DeepCollectionEquality().equals(other.details, _details)&&(identical(other.id, id) || other.id == id)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,message,severity,const DeepCollectionEquality().hash(_targets),const DeepCollectionEquality().hash(_details),id,origin);
}

@override
String toString() {
    return 'PortablePresentationDiagnostic(code: $code, message: $message, severity: $severity, targets: $targets, details: $details, id: $id, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationDiagnosticCopyWith<$Res> implements $PortablePresentationDiagnosticCopyWith<$Res> {
  factory _$PortablePresentationDiagnosticCopyWith(_PortablePresentationDiagnostic value, $Res Function(_PortablePresentationDiagnostic) _then) = __$PortablePresentationDiagnosticCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, skir.DiagnosticSeverity severity, List<PortableDiagnosticTarget> targets, Map<String, String> details, skir.DiagnosticId? id, skir.RuleOrigin? origin
});




}
/// @nodoc
class __$PortablePresentationDiagnosticCopyWithImpl<$Res>
    implements _$PortablePresentationDiagnosticCopyWith<$Res> {
  __$PortablePresentationDiagnosticCopyWithImpl(this._self, this._then);

  final _PortablePresentationDiagnostic _self;
  final $Res Function(_PortablePresentationDiagnostic) _then;

/// Create a copy of PortablePresentationDiagnostic
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? severity = null,Object? targets = null,Object? details = null,Object? id = freezed,Object? origin = freezed,}) {
  return _then(_PortablePresentationDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticSeverity,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticTarget>,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, String>,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticId?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as skir.RuleOrigin?,
  ));
}


}

// dart format on
