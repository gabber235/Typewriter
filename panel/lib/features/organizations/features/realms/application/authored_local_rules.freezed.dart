// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authored_local_rules.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoredRuleProjection {

 Map<skir.ValueLocation, List<skir.OwnedRule>> get rules; List<PortablePresentationDiagnostic> get diagnostics;
/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredRuleProjectionCopyWith<AuthoredRuleProjection> get copyWith => _$AuthoredRuleProjectionCopyWithImpl<AuthoredRuleProjection>(this as AuthoredRuleProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredRuleProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredRuleProjection&&const DeepCollectionEquality().equals(other.rules, _this.rules)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as AuthoredRuleProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.rules),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as AuthoredRuleProjection;
  return 'AuthoredRuleProjection(rules: ${_this.rules}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $AuthoredRuleProjectionCopyWith<$Res>  {
  factory $AuthoredRuleProjectionCopyWith(AuthoredRuleProjection value, $Res Function(AuthoredRuleProjection) _then) = _$AuthoredRuleProjectionCopyWithImpl;
@useResult
$Res call({
 Map<skir.ValueLocation, List<skir.OwnedRule>> rules, List<PortablePresentationDiagnostic> diagnostics
});




}
/// @nodoc
class _$AuthoredRuleProjectionCopyWithImpl<$Res>
    implements $AuthoredRuleProjectionCopyWith<$Res> {
  _$AuthoredRuleProjectionCopyWithImpl(this._self, this._then);

  final AuthoredRuleProjection _self;
  final $Res Function(AuthoredRuleProjection) _then;

/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rules = null,Object? diagnostics = null,}) {
  return _then(AuthoredRuleProjection(
rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as Map<skir.ValueLocation, List<skir.OwnedRule>>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [AuthoredRuleProjection].
extension AuthoredRuleProjectionPatterns on AuthoredRuleProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredRuleProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredRuleProjection value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredRuleProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredRuleProjection value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<skir.ValueLocation, List<skir.OwnedRule>> rules,  List<PortablePresentationDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
return $default(_that.rules,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<skir.ValueLocation, List<skir.OwnedRule>> rules,  List<PortablePresentationDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection():
return $default(_that.rules,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<skir.ValueLocation, List<skir.OwnedRule>> rules,  List<PortablePresentationDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
return $default(_that.rules,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredRuleProjection extends AuthoredRuleProjection {
  const _AuthoredRuleProjection({ Map<skir.ValueLocation, List<skir.OwnedRule>> rules = const {},  List<PortablePresentationDiagnostic> diagnostics = const []}): _rules = rules,_diagnostics = diagnostics,super._();


 final  Map<skir.ValueLocation, List<skir.OwnedRule>> _rules;
@override@JsonKey() Map<skir.ValueLocation, List<skir.OwnedRule>> get rules {
  if (_rules is EqualUnmodifiableMapView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rules);
}

 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredRuleProjectionCopyWith<_AuthoredRuleProjection> get copyWith => __$AuthoredRuleProjectionCopyWithImpl<_AuthoredRuleProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredRuleProjection&&const DeepCollectionEquality().equals(other.rules, _rules)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rules),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'AuthoredRuleProjection(rules: $rules, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$AuthoredRuleProjectionCopyWith<$Res> implements $AuthoredRuleProjectionCopyWith<$Res> {
  factory _$AuthoredRuleProjectionCopyWith(_AuthoredRuleProjection value, $Res Function(_AuthoredRuleProjection) _then) = __$AuthoredRuleProjectionCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ValueLocation, List<skir.OwnedRule>> rules, List<PortablePresentationDiagnostic> diagnostics
});




}
/// @nodoc
class __$AuthoredRuleProjectionCopyWithImpl<$Res>
    implements _$AuthoredRuleProjectionCopyWith<$Res> {
  __$AuthoredRuleProjectionCopyWithImpl(this._self, this._then);

  final _AuthoredRuleProjection _self;
  final $Res Function(_AuthoredRuleProjection) _then;

/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rules = null,Object? diagnostics = null,}) {
  return _then(_AuthoredRuleProjection(
rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as Map<skir.ValueLocation, List<skir.OwnedRule>>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PatternMatch {

 skir.DataValue get value; List<skir.PathSegment> get path;
/// Create a copy of _PatternMatch
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternMatchCopyWith<_PatternMatch> get copyWith => __$PatternMatchCopyWithImpl<_PatternMatch>(this as _PatternMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _PatternMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternMatch&&(identical(other.value, _this.value) || other.value == _this.value)&&const DeepCollectionEquality().equals(other.path, _this.path));
}


@override
int get hashCode {
  final _this = this as _PatternMatch;
  return Object.hash(runtimeType,_this.value,const DeepCollectionEquality().hash(_this.path));
}

@override
String toString() {
  final _this = this as _PatternMatch;
  return '_PatternMatch(value: ${_this.value}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class _$PatternMatchCopyWith<$Res>  {
  factory _$PatternMatchCopyWith(_PatternMatch value, $Res Function(_PatternMatch) _then) = __$PatternMatchCopyWithImpl;
@useResult
$Res call({
 skir.DataValue value, List<skir.PathSegment> path
});




}
/// @nodoc
class __$PatternMatchCopyWithImpl<$Res>
    implements _$PatternMatchCopyWith<$Res> {
  __$PatternMatchCopyWithImpl(this._self, this._then);

  final _PatternMatch _self;
  final $Res Function(_PatternMatch) _then;

/// Create a copy of _PatternMatch
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? path = null,}) {
  return _then(_PatternMatch(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<skir.PathSegment>,
  ));
}

}


/// Adds pattern matching related methods to [_PatternMatch].
extension _PatternMatchPatterns on _PatternMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatternMatchValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatternMatchValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatternMatchValue value)  $default,){
final _that = this;
switch (_that) {
case _PatternMatchValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatternMatchValue value)?  $default,){
final _that = this;
switch (_that) {
case _PatternMatchValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.DataValue value,  List<skir.PathSegment> path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatternMatchValue() when $default != null:
return $default(_that.value,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.DataValue value,  List<skir.PathSegment> path)  $default,) {final _that = this;
switch (_that) {
case _PatternMatchValue():
return $default(_that.value,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.DataValue value,  List<skir.PathSegment> path)?  $default,) {final _that = this;
switch (_that) {
case _PatternMatchValue() when $default != null:
return $default(_that.value,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _PatternMatchValue implements _PatternMatch {
  const _PatternMatchValue({required this.value, required  List<skir.PathSegment> path}): _path = path;


@override final  skir.DataValue value;
 final  List<skir.PathSegment> _path;
@override List<skir.PathSegment> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}


/// Create a copy of _PatternMatch
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternMatchValueCopyWith<_PatternMatchValue> get copyWith => __$PatternMatchValueCopyWithImpl<_PatternMatchValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternMatchValue&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.path, _path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_path));
}

@override
String toString() {
    return '_PatternMatch(value: $value, path: $path)';
}


}

/// @nodoc
abstract mixin class _$PatternMatchValueCopyWith<$Res> implements _$PatternMatchCopyWith<$Res> {
  factory _$PatternMatchValueCopyWith(_PatternMatchValue value, $Res Function(_PatternMatchValue) _then) = __$PatternMatchValueCopyWithImpl;
@override @useResult
$Res call({
 skir.DataValue value, List<skir.PathSegment> path
});




}
/// @nodoc
class __$PatternMatchValueCopyWithImpl<$Res>
    implements _$PatternMatchValueCopyWith<$Res> {
  __$PatternMatchValueCopyWithImpl(this._self, this._then);

  final _PatternMatchValue _self;
  final $Res Function(_PatternMatchValue) _then;

/// Create a copy of _PatternMatch
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? path = null,}) {
  return _then(_PatternMatchValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<skir.PathSegment>,
  ));
}


}

// dart format on
