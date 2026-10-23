// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authored_local_rules.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoredRuleProjection {

 List<AuthoredRuleCheck> get checks;
/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredRuleProjectionCopyWith<AuthoredRuleProjection> get copyWith => _$AuthoredRuleProjectionCopyWithImpl<AuthoredRuleProjection>(this as AuthoredRuleProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredRuleProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredRuleProjection&&const DeepCollectionEquality().equals(other.checks, _this.checks));
}


@override
int get hashCode {
  final _this = this as AuthoredRuleProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.checks));
}

@override
String toString() {
  final _this = this as AuthoredRuleProjection;
  return 'AuthoredRuleProjection(checks: ${_this.checks})';
}


}

/// @nodoc
abstract mixin class $AuthoredRuleProjectionCopyWith<$Res>  {
  factory $AuthoredRuleProjectionCopyWith(AuthoredRuleProjection value, $Res Function(AuthoredRuleProjection) _then) = _$AuthoredRuleProjectionCopyWithImpl;
@useResult
$Res call({
 List<AuthoredRuleCheck> checks
});




}
/// @nodoc
class _$AuthoredRuleProjectionCopyWithImpl<$Res>
    implements $AuthoredRuleProjectionCopyWith<$Res> {
  _$AuthoredRuleProjectionCopyWithImpl(this._self, this._then);

  final AuthoredRuleProjection _self;
  final $Res Function(AuthoredRuleProjection) _then;

/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? checks = null,}) {
  return _then(AuthoredRuleProjection(
checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as List<AuthoredRuleCheck>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoredRuleProjection].
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuthoredRuleCheck> checks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
return $default(_that.checks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuthoredRuleCheck> checks)  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection():
return $default(_that.checks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuthoredRuleCheck> checks)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleProjection() when $default != null:
return $default(_that.checks);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredRuleProjection extends AuthoredRuleProjection {
  const _AuthoredRuleProjection({ List<AuthoredRuleCheck> checks = const []}): _checks = checks,super._();
  

 final  List<AuthoredRuleCheck> _checks;
@override@JsonKey() List<AuthoredRuleCheck> get checks {
  if (_checks is EqualUnmodifiableListView) return _checks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checks);
}


/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredRuleProjectionCopyWith<_AuthoredRuleProjection> get copyWith => __$AuthoredRuleProjectionCopyWithImpl<_AuthoredRuleProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredRuleProjection&&const DeepCollectionEquality().equals(other.checks, _checks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_checks));
}

@override
String toString() {
    return 'AuthoredRuleProjection(checks: $checks)';
}


}

/// @nodoc
abstract mixin class _$AuthoredRuleProjectionCopyWith<$Res> implements $AuthoredRuleProjectionCopyWith<$Res> {
  factory _$AuthoredRuleProjectionCopyWith(_AuthoredRuleProjection value, $Res Function(_AuthoredRuleProjection) _then) = __$AuthoredRuleProjectionCopyWithImpl;
@override @useResult
$Res call({
 List<AuthoredRuleCheck> checks
});




}
/// @nodoc
class __$AuthoredRuleProjectionCopyWithImpl<$Res>
    implements _$AuthoredRuleProjectionCopyWith<$Res> {
  __$AuthoredRuleProjectionCopyWithImpl(this._self, this._then);

  final _AuthoredRuleProjection _self;
  final $Res Function(_AuthoredRuleProjection) _then;

/// Create a copy of AuthoredRuleProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? checks = null,}) {
  return _then(_AuthoredRuleProjection(
checks: null == checks ? _self._checks : checks // ignore: cast_nullable_to_non_nullable
as List<AuthoredRuleCheck>,
  ));
}


}

/// @nodoc
mixin _$AuthoredRuleCheck {

 skir.RuleId get rule; skir.ValueLocation get subject; skir.CheckOutcome get outcome; List<skir.Diagnostic> get findings;
/// Create a copy of AuthoredRuleCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredRuleCheckCopyWith<AuthoredRuleCheck> get copyWith => _$AuthoredRuleCheckCopyWithImpl<AuthoredRuleCheck>(this as AuthoredRuleCheck, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredRuleCheck;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredRuleCheck&&(identical(other.rule, _this.rule) || other.rule == _this.rule)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&const DeepCollectionEquality().equals(other.findings, _this.findings));
}


@override
int get hashCode {
  final _this = this as AuthoredRuleCheck;
  return Object.hash(runtimeType,_this.rule,_this.subject,_this.outcome,const DeepCollectionEquality().hash(_this.findings));
}

@override
String toString() {
  final _this = this as AuthoredRuleCheck;
  return 'AuthoredRuleCheck(rule: ${_this.rule}, subject: ${_this.subject}, outcome: ${_this.outcome}, findings: ${_this.findings})';
}


}

/// @nodoc
abstract mixin class $AuthoredRuleCheckCopyWith<$Res>  {
  factory $AuthoredRuleCheckCopyWith(AuthoredRuleCheck value, $Res Function(AuthoredRuleCheck) _then) = _$AuthoredRuleCheckCopyWithImpl;
@useResult
$Res call({
 skir.RuleId rule, skir.ValueLocation subject, skir.CheckOutcome outcome, List<skir.Diagnostic> findings
});




}
/// @nodoc
class _$AuthoredRuleCheckCopyWithImpl<$Res>
    implements $AuthoredRuleCheckCopyWith<$Res> {
  _$AuthoredRuleCheckCopyWithImpl(this._self, this._then);

  final AuthoredRuleCheck _self;
  final $Res Function(AuthoredRuleCheck) _then;

/// Create a copy of AuthoredRuleCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rule = null,Object? subject = null,Object? outcome = null,Object? findings = null,}) {
  return _then(AuthoredRuleCheck(
rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as skir.RuleId,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as skir.CheckOutcome,findings: null == findings ? _self.findings : findings // ignore: cast_nullable_to_non_nullable
as List<skir.Diagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoredRuleCheck].
extension AuthoredRuleCheckPatterns on AuthoredRuleCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredRuleCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredRuleCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredRuleCheck value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredRuleCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredRuleCheck value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredRuleCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RuleId rule,  skir.ValueLocation subject,  skir.CheckOutcome outcome,  List<skir.Diagnostic> findings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredRuleCheck() when $default != null:
return $default(_that.rule,_that.subject,_that.outcome,_that.findings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RuleId rule,  skir.ValueLocation subject,  skir.CheckOutcome outcome,  List<skir.Diagnostic> findings)  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleCheck():
return $default(_that.rule,_that.subject,_that.outcome,_that.findings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RuleId rule,  skir.ValueLocation subject,  skir.CheckOutcome outcome,  List<skir.Diagnostic> findings)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredRuleCheck() when $default != null:
return $default(_that.rule,_that.subject,_that.outcome,_that.findings);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredRuleCheck implements AuthoredRuleCheck {
  const _AuthoredRuleCheck({required this.rule, required this.subject, required this.outcome,  List<skir.Diagnostic> findings = const []}): _findings = findings;
  

@override final  skir.RuleId rule;
@override final  skir.ValueLocation subject;
@override final  skir.CheckOutcome outcome;
 final  List<skir.Diagnostic> _findings;
@override@JsonKey() List<skir.Diagnostic> get findings {
  if (_findings is EqualUnmodifiableListView) return _findings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_findings);
}


/// Create a copy of AuthoredRuleCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredRuleCheckCopyWith<_AuthoredRuleCheck> get copyWith => __$AuthoredRuleCheckCopyWithImpl<_AuthoredRuleCheck>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredRuleCheck&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&const DeepCollectionEquality().equals(other.findings, _findings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rule,subject,outcome,const DeepCollectionEquality().hash(_findings));
}

@override
String toString() {
    return 'AuthoredRuleCheck(rule: $rule, subject: $subject, outcome: $outcome, findings: $findings)';
}


}

/// @nodoc
abstract mixin class _$AuthoredRuleCheckCopyWith<$Res> implements $AuthoredRuleCheckCopyWith<$Res> {
  factory _$AuthoredRuleCheckCopyWith(_AuthoredRuleCheck value, $Res Function(_AuthoredRuleCheck) _then) = __$AuthoredRuleCheckCopyWithImpl;
@override @useResult
$Res call({
 skir.RuleId rule, skir.ValueLocation subject, skir.CheckOutcome outcome, List<skir.Diagnostic> findings
});




}
/// @nodoc
class __$AuthoredRuleCheckCopyWithImpl<$Res>
    implements _$AuthoredRuleCheckCopyWith<$Res> {
  __$AuthoredRuleCheckCopyWithImpl(this._self, this._then);

  final _AuthoredRuleCheck _self;
  final $Res Function(_AuthoredRuleCheck) _then;

/// Create a copy of AuthoredRuleCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rule = null,Object? subject = null,Object? outcome = null,Object? findings = null,}) {
  return _then(_AuthoredRuleCheck(
rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as skir.RuleId,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as skir.CheckOutcome,findings: null == findings ? _self._findings : findings // ignore: cast_nullable_to_non_nullable
as List<skir.Diagnostic>,
  ));
}


}

// dart format on
