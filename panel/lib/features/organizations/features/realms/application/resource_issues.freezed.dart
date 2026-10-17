// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_issues.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceIssue {

 PortablePresentationDiagnostic get diagnostic; bool get current; bool get saved; bool get blocksPublication; bool get outdated;
/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceIssueCopyWith<ResourceIssue> get copyWith => _$ResourceIssueCopyWithImpl<ResourceIssue>(this as ResourceIssue, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceIssue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceIssue&&(identical(other.diagnostic, _this.diagnostic) || other.diagnostic == _this.diagnostic)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.saved, _this.saved) || other.saved == _this.saved)&&(identical(other.blocksPublication, _this.blocksPublication) || other.blocksPublication == _this.blocksPublication)&&(identical(other.outdated, _this.outdated) || other.outdated == _this.outdated));
}


@override
int get hashCode {
  final _this = this as ResourceIssue;
  return Object.hash(runtimeType,_this.diagnostic,_this.current,_this.saved,_this.blocksPublication,_this.outdated);
}

@override
String toString() {
  final _this = this as ResourceIssue;
  return 'ResourceIssue(diagnostic: ${_this.diagnostic}, current: ${_this.current}, saved: ${_this.saved}, blocksPublication: ${_this.blocksPublication}, outdated: ${_this.outdated})';
}


}

/// @nodoc
abstract mixin class $ResourceIssueCopyWith<$Res>  {
  factory $ResourceIssueCopyWith(ResourceIssue value, $Res Function(ResourceIssue) _then) = _$ResourceIssueCopyWithImpl;
@useResult
$Res call({
 PortablePresentationDiagnostic diagnostic, bool current, bool saved, bool blocksPublication, bool outdated
});


$PortablePresentationDiagnosticCopyWith<$Res> get diagnostic;

}
/// @nodoc
class _$ResourceIssueCopyWithImpl<$Res>
    implements $ResourceIssueCopyWith<$Res> {
  _$ResourceIssueCopyWithImpl(this._self, this._then);

  final ResourceIssue _self;
  final $Res Function(ResourceIssue) _then;

/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? diagnostic = null,Object? current = null,Object? saved = null,Object? blocksPublication = null,Object? outdated = null,}) {
  return _then(ResourceIssue(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as PortablePresentationDiagnostic,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,blocksPublication: null == blocksPublication ? _self.blocksPublication : blocksPublication // ignore: cast_nullable_to_non_nullable
as bool,outdated: null == outdated ? _self.outdated : outdated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationDiagnosticCopyWith<$Res> get diagnostic {

  return $PortablePresentationDiagnosticCopyWith<$Res>(_self.diagnostic, (value) {
    return _then(_self.copyWith(diagnostic: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResourceIssue].
extension ResourceIssuePatterns on ResourceIssue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceIssue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceIssue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceIssue value)  $default,){
final _that = this;
switch (_that) {
case _ResourceIssue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceIssue value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceIssue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortablePresentationDiagnostic diagnostic,  bool current,  bool saved,  bool blocksPublication,  bool outdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceIssue() when $default != null:
return $default(_that.diagnostic,_that.current,_that.saved,_that.blocksPublication,_that.outdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortablePresentationDiagnostic diagnostic,  bool current,  bool saved,  bool blocksPublication,  bool outdated)  $default,) {final _that = this;
switch (_that) {
case _ResourceIssue():
return $default(_that.diagnostic,_that.current,_that.saved,_that.blocksPublication,_that.outdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortablePresentationDiagnostic diagnostic,  bool current,  bool saved,  bool blocksPublication,  bool outdated)?  $default,) {final _that = this;
switch (_that) {
case _ResourceIssue() when $default != null:
return $default(_that.diagnostic,_that.current,_that.saved,_that.blocksPublication,_that.outdated);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceIssue extends ResourceIssue {
  const _ResourceIssue({required this.diagnostic, this.current = false, this.saved = false, this.blocksPublication = false, this.outdated = false}): super._();


@override final  PortablePresentationDiagnostic diagnostic;
@override@JsonKey() final  bool current;
@override@JsonKey() final  bool saved;
@override@JsonKey() final  bool blocksPublication;
@override@JsonKey() final  bool outdated;

/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceIssueCopyWith<_ResourceIssue> get copyWith => __$ResourceIssueCopyWithImpl<_ResourceIssue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceIssue&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic)&&(identical(other.current, current) || other.current == current)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.blocksPublication, blocksPublication) || other.blocksPublication == blocksPublication)&&(identical(other.outdated, outdated) || other.outdated == outdated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,diagnostic,current,saved,blocksPublication,outdated);
}

@override
String toString() {
    return 'ResourceIssue(diagnostic: $diagnostic, current: $current, saved: $saved, blocksPublication: $blocksPublication, outdated: $outdated)';
}


}

/// @nodoc
abstract mixin class _$ResourceIssueCopyWith<$Res> implements $ResourceIssueCopyWith<$Res> {
  factory _$ResourceIssueCopyWith(_ResourceIssue value, $Res Function(_ResourceIssue) _then) = __$ResourceIssueCopyWithImpl;
@override @useResult
$Res call({
 PortablePresentationDiagnostic diagnostic, bool current, bool saved, bool blocksPublication, bool outdated
});


@override $PortablePresentationDiagnosticCopyWith<$Res> get diagnostic;

}
/// @nodoc
class __$ResourceIssueCopyWithImpl<$Res>
    implements _$ResourceIssueCopyWith<$Res> {
  __$ResourceIssueCopyWithImpl(this._self, this._then);

  final _ResourceIssue _self;
  final $Res Function(_ResourceIssue) _then;

/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? diagnostic = null,Object? current = null,Object? saved = null,Object? blocksPublication = null,Object? outdated = null,}) {
  return _then(_ResourceIssue(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as PortablePresentationDiagnostic,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,blocksPublication: null == blocksPublication ? _self.blocksPublication : blocksPublication // ignore: cast_nullable_to_non_nullable
as bool,outdated: null == outdated ? _self.outdated : outdated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ResourceIssue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationDiagnosticCopyWith<$Res> get diagnostic {

  return $PortablePresentationDiagnosticCopyWith<$Res>(_self.diagnostic, (value) {
    return _then(_self.copyWith(diagnostic: value));
  });
}
}

/// @nodoc
mixin _$ResourceIssues {

 List<ResourceIssue> get findings; bool get checking; bool get unavailable;
/// Create a copy of ResourceIssues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceIssuesCopyWith<ResourceIssues> get copyWith => _$ResourceIssuesCopyWithImpl<ResourceIssues>(this as ResourceIssues, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceIssues;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceIssues&&const DeepCollectionEquality().equals(other.findings, _this.findings)&&(identical(other.checking, _this.checking) || other.checking == _this.checking)&&(identical(other.unavailable, _this.unavailable) || other.unavailable == _this.unavailable));
}


@override
int get hashCode {
  final _this = this as ResourceIssues;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.findings),_this.checking,_this.unavailable);
}

@override
String toString() {
  final _this = this as ResourceIssues;
  return 'ResourceIssues(findings: ${_this.findings}, checking: ${_this.checking}, unavailable: ${_this.unavailable})';
}


}

/// @nodoc
abstract mixin class $ResourceIssuesCopyWith<$Res>  {
  factory $ResourceIssuesCopyWith(ResourceIssues value, $Res Function(ResourceIssues) _then) = _$ResourceIssuesCopyWithImpl;
@useResult
$Res call({
 List<ResourceIssue> findings, bool checking, bool unavailable
});




}
/// @nodoc
class _$ResourceIssuesCopyWithImpl<$Res>
    implements $ResourceIssuesCopyWith<$Res> {
  _$ResourceIssuesCopyWithImpl(this._self, this._then);

  final ResourceIssues _self;
  final $Res Function(ResourceIssues) _then;

/// Create a copy of ResourceIssues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? findings = null,Object? checking = null,Object? unavailable = null,}) {
  return _then(ResourceIssues(
findings: null == findings ? _self.findings : findings // ignore: cast_nullable_to_non_nullable
as List<ResourceIssue>,checking: null == checking ? _self.checking : checking // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceIssues].
extension ResourceIssuesPatterns on ResourceIssues {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceIssues value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceIssues() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceIssues value)  $default,){
final _that = this;
switch (_that) {
case _ResourceIssues():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceIssues value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceIssues() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ResourceIssue> findings,  bool checking,  bool unavailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceIssues() when $default != null:
return $default(_that.findings,_that.checking,_that.unavailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ResourceIssue> findings,  bool checking,  bool unavailable)  $default,) {final _that = this;
switch (_that) {
case _ResourceIssues():
return $default(_that.findings,_that.checking,_that.unavailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ResourceIssue> findings,  bool checking,  bool unavailable)?  $default,) {final _that = this;
switch (_that) {
case _ResourceIssues() when $default != null:
return $default(_that.findings,_that.checking,_that.unavailable);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceIssues extends ResourceIssues {
  const _ResourceIssues({ List<ResourceIssue> findings = const [], this.checking = false, this.unavailable = false}): _findings = findings,super._();


 final  List<ResourceIssue> _findings;
@override@JsonKey() List<ResourceIssue> get findings {
  if (_findings is EqualUnmodifiableListView) return _findings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_findings);
}

@override@JsonKey() final  bool checking;
@override@JsonKey() final  bool unavailable;

/// Create a copy of ResourceIssues
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceIssuesCopyWith<_ResourceIssues> get copyWith => __$ResourceIssuesCopyWithImpl<_ResourceIssues>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceIssues&&const DeepCollectionEquality().equals(other.findings, _findings)&&(identical(other.checking, checking) || other.checking == checking)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_findings),checking,unavailable);
}

@override
String toString() {
    return 'ResourceIssues(findings: $findings, checking: $checking, unavailable: $unavailable)';
}


}

/// @nodoc
abstract mixin class _$ResourceIssuesCopyWith<$Res> implements $ResourceIssuesCopyWith<$Res> {
  factory _$ResourceIssuesCopyWith(_ResourceIssues value, $Res Function(_ResourceIssues) _then) = __$ResourceIssuesCopyWithImpl;
@override @useResult
$Res call({
 List<ResourceIssue> findings, bool checking, bool unavailable
});




}
/// @nodoc
class __$ResourceIssuesCopyWithImpl<$Res>
    implements _$ResourceIssuesCopyWith<$Res> {
  __$ResourceIssuesCopyWithImpl(this._self, this._then);

  final _ResourceIssues _self;
  final $Res Function(_ResourceIssues) _then;

/// Create a copy of ResourceIssues
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? findings = null,Object? checking = null,Object? unavailable = null,}) {
  return _then(_ResourceIssues(
findings: null == findings ? _self._findings : findings // ignore: cast_nullable_to_non_nullable
as List<ResourceIssue>,checking: null == checking ? _self.checking : checking // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
