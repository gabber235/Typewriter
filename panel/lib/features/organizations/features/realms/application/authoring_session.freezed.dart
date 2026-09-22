// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSessionAccess {

 AuthoringSession get notifier; AuthoringSessionState get state;
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionAccessCopyWith<AuthoringSessionAccess> get copyWith => _$AuthoringSessionAccessCopyWithImpl<AuthoringSessionAccess>(this as AuthoringSessionAccess, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionAccess;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionAccess&&(identical(other.notifier, _this.notifier) || other.notifier == _this.notifier)&&(identical(other.state, _this.state) || other.state == _this.state));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionAccess;
  return Object.hash(runtimeType,_this.notifier,_this.state);
}

@override
String toString() {
  final _this = this as AuthoringSessionAccess;
  return 'AuthoringSessionAccess(notifier: ${_this.notifier}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionAccessCopyWith<$Res>  {
  factory $AuthoringSessionAccessCopyWith(AuthoringSessionAccess value, $Res Function(AuthoringSessionAccess) _then) = _$AuthoringSessionAccessCopyWithImpl;
@useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


$AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class _$AuthoringSessionAccessCopyWithImpl<$Res>
    implements $AuthoringSessionAccessCopyWith<$Res> {
  _$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final AuthoringSessionAccess _self;
  final $Res Function(AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {

  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringSessionAccess].
extension AuthoringSessionAccessPatterns on AuthoringSessionAccess {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionAccess value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionAccess implements AuthoringSessionAccess {
  const _AuthoringSessionAccess({required this.notifier, required this.state});


@override final  AuthoringSession notifier;
@override final  AuthoringSessionState state;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionAccessCopyWith<_AuthoringSessionAccess> get copyWith => __$AuthoringSessionAccessCopyWithImpl<_AuthoringSessionAccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionAccess&&(identical(other.notifier, notifier) || other.notifier == notifier)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode {
    return Object.hash(runtimeType,notifier,state);
}

@override
String toString() {
    return 'AuthoringSessionAccess(notifier: $notifier, state: $state)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionAccessCopyWith<$Res> implements $AuthoringSessionAccessCopyWith<$Res> {
  factory _$AuthoringSessionAccessCopyWith(_AuthoringSessionAccess value, $Res Function(_AuthoringSessionAccess) _then) = __$AuthoringSessionAccessCopyWithImpl;
@override @useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


@override $AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class __$AuthoringSessionAccessCopyWithImpl<$Res>
    implements _$AuthoringSessionAccessCopyWith<$Res> {
  __$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final _AuthoringSessionAccess _self;
  final $Res Function(_AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(_AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {

  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$AuthoringValue<T> {

 T get value; int get revision;
/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringValueCopyWith<T, AuthoringValue<T>> get copyWith => _$AuthoringValueCopyWithImpl<T, AuthoringValue<T>>(this as AuthoringValue<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringValue<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringValue<T>&&const DeepCollectionEquality().equals(other.value, _this.value)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as AuthoringValue<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.value),_this.revision);
}

@override
String toString() {
  final _this = this as AuthoringValue<T>;
  return 'AuthoringValue<$T>(value: ${_this.value}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $AuthoringValueCopyWith<T,$Res>  {
  factory $AuthoringValueCopyWith(AuthoringValue<T> value, $Res Function(AuthoringValue<T>) _then) = _$AuthoringValueCopyWithImpl;
@useResult
$Res call({
 T value, int revision
});




}
/// @nodoc
class _$AuthoringValueCopyWithImpl<T,$Res>
    implements $AuthoringValueCopyWith<T, $Res> {
  _$AuthoringValueCopyWithImpl(this._self, this._then);

  final AuthoringValue<T> _self;
  final $Res Function(AuthoringValue<T>) _then;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? revision = null,}) {
  return _then(AuthoringValue(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringValue].
extension AuthoringValuePatterns<T> on AuthoringValue<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringValue<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringValue<T> value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringValue<T> value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T value,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
return $default(_that.value,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T value,  int revision)  $default,) {final _that = this;
switch (_that) {
case _AuthoringValue():
return $default(_that.value,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T value,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
return $default(_that.value,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringValue<T> implements AuthoringValue<T> {
  const _AuthoringValue({required this.value, required this.revision});


@override final  T value;
@override final  int revision;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringValueCopyWith<T, _AuthoringValue<T>> get copyWith => __$AuthoringValueCopyWithImpl<T, _AuthoringValue<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringValue<T>&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value),revision);
}

@override
String toString() {
    return 'AuthoringValue<$T>(value: $value, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$AuthoringValueCopyWith<T,$Res> implements $AuthoringValueCopyWith<T, $Res> {
  factory _$AuthoringValueCopyWith(_AuthoringValue<T> value, $Res Function(_AuthoringValue<T>) _then) = __$AuthoringValueCopyWithImpl;
@override @useResult
$Res call({
 T value, int revision
});




}
/// @nodoc
class __$AuthoringValueCopyWithImpl<T,$Res>
    implements _$AuthoringValueCopyWith<T, $Res> {
  __$AuthoringValueCopyWithImpl(this._self, this._then);

  final _AuthoringValue<T> _self;
  final $Res Function(_AuthoringValue<T>) _then;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? revision = null,}) {
  return _then(_AuthoringValue<T>(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AuthoringSessionState {

 skir.CatalogGeneration? get generation; int? get sequence; Map<skir.ResourceId, skir.AuthoringResource> get resources; Map<skir.AuthoringEdgeId, skir.AuthoringEdge> get edges; Map<skir.ResourceId, skir.PresentationSubject> get presentations; Map<skir.CompilationRoot, skir.CompiledResourceState> get compiledStatuses; Map<String, skir.GraphSelectionResult> get selections; List<skir.AuthoringDiagnostic> get diagnostics; bool get refreshing;
/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<AuthoringSessionState> get copyWith => _$AuthoringSessionStateCopyWithImpl<AuthoringSessionState>(this as AuthoringSessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionState&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&(identical(other.sequence, _this.sequence) || other.sequence == _this.sequence)&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&const DeepCollectionEquality().equals(other.edges, _this.edges)&&const DeepCollectionEquality().equals(other.presentations, _this.presentations)&&const DeepCollectionEquality().equals(other.compiledStatuses, _this.compiledStatuses)&&const DeepCollectionEquality().equals(other.selections, _this.selections)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionState;
  return Object.hash(runtimeType,_this.generation,_this.sequence,const DeepCollectionEquality().hash(_this.resources),const DeepCollectionEquality().hash(_this.edges),const DeepCollectionEquality().hash(_this.presentations),const DeepCollectionEquality().hash(_this.compiledStatuses),const DeepCollectionEquality().hash(_this.selections),const DeepCollectionEquality().hash(_this.diagnostics),_this.refreshing);
}

@override
String toString() {
  final _this = this as AuthoringSessionState;
  return 'AuthoringSessionState(generation: ${_this.generation}, sequence: ${_this.sequence}, resources: ${_this.resources}, edges: ${_this.edges}, presentations: ${_this.presentations}, compiledStatuses: ${_this.compiledStatuses}, selections: ${_this.selections}, diagnostics: ${_this.diagnostics}, refreshing: ${_this.refreshing})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionStateCopyWith<$Res>  {
  factory $AuthoringSessionStateCopyWith(AuthoringSessionState value, $Res Function(AuthoringSessionState) _then) = _$AuthoringSessionStateCopyWithImpl;
@useResult
$Res call({
 skir.CatalogGeneration? generation, int? sequence, Map<skir.ResourceId, skir.AuthoringResource> resources, Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges, Map<skir.ResourceId, skir.PresentationSubject> presentations, Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses, Map<String, skir.GraphSelectionResult> selections, List<skir.AuthoringDiagnostic> diagnostics, bool refreshing
});




}
/// @nodoc
class _$AuthoringSessionStateCopyWithImpl<$Res>
    implements $AuthoringSessionStateCopyWith<$Res> {
  _$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final AuthoringSessionState _self;
  final $Res Function(AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generation = freezed,Object? sequence = freezed,Object? resources = null,Object? edges = null,Object? presentations = null,Object? compiledStatuses = null,Object? selections = null,Object? diagnostics = null,Object? refreshing = null,}) {
  return _then(AuthoringSessionState(
generation: freezed == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as skir.CatalogGeneration?,sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as Map<skir.AuthoringEdgeId, skir.AuthoringEdge>,presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.PresentationSubject>,compiledStatuses: null == compiledStatuses ? _self.compiledStatuses : compiledStatuses // ignore: cast_nullable_to_non_nullable
as Map<skir.CompilationRoot, skir.CompiledResourceState>,selections: null == selections ? _self.selections : selections // ignore: cast_nullable_to_non_nullable
as Map<String, skir.GraphSelectionResult>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<skir.AuthoringDiagnostic>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringSessionState].
extension AuthoringSessionStatePatterns on AuthoringSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionState value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.CatalogGeneration? generation,  int? sequence,  Map<skir.ResourceId, skir.AuthoringResource> resources,  Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges,  Map<skir.ResourceId, skir.PresentationSubject> presentations,  Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,  Map<String, skir.GraphSelectionResult> selections,  List<skir.AuthoringDiagnostic> diagnostics,  bool refreshing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.generation,_that.sequence,_that.resources,_that.edges,_that.presentations,_that.compiledStatuses,_that.selections,_that.diagnostics,_that.refreshing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.CatalogGeneration? generation,  int? sequence,  Map<skir.ResourceId, skir.AuthoringResource> resources,  Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges,  Map<skir.ResourceId, skir.PresentationSubject> presentations,  Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,  Map<String, skir.GraphSelectionResult> selections,  List<skir.AuthoringDiagnostic> diagnostics,  bool refreshing)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState():
return $default(_that.generation,_that.sequence,_that.resources,_that.edges,_that.presentations,_that.compiledStatuses,_that.selections,_that.diagnostics,_that.refreshing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.CatalogGeneration? generation,  int? sequence,  Map<skir.ResourceId, skir.AuthoringResource> resources,  Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges,  Map<skir.ResourceId, skir.PresentationSubject> presentations,  Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,  Map<String, skir.GraphSelectionResult> selections,  List<skir.AuthoringDiagnostic> diagnostics,  bool refreshing)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.generation,_that.sequence,_that.resources,_that.edges,_that.presentations,_that.compiledStatuses,_that.selections,_that.diagnostics,_that.refreshing);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionState implements AuthoringSessionState {
  const _AuthoringSessionState({this.generation, this.sequence,  Map<skir.ResourceId, skir.AuthoringResource> resources = const {},  Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges = const {},  Map<skir.ResourceId, skir.PresentationSubject> presentations = const {},  Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses = const {},  Map<String, skir.GraphSelectionResult> selections = const {},  List<skir.AuthoringDiagnostic> diagnostics = const [], this.refreshing = false}): _resources = resources,_edges = edges,_presentations = presentations,_compiledStatuses = compiledStatuses,_selections = selections,_diagnostics = diagnostics;


@override final  skir.CatalogGeneration? generation;
@override final  int? sequence;
 final  Map<skir.ResourceId, skir.AuthoringResource> _resources;
@override@JsonKey() Map<skir.ResourceId, skir.AuthoringResource> get resources {
  if (_resources is EqualUnmodifiableMapView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resources);
}

 final  Map<skir.AuthoringEdgeId, skir.AuthoringEdge> _edges;
@override@JsonKey() Map<skir.AuthoringEdgeId, skir.AuthoringEdge> get edges {
  if (_edges is EqualUnmodifiableMapView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_edges);
}

 final  Map<skir.ResourceId, skir.PresentationSubject> _presentations;
@override@JsonKey() Map<skir.ResourceId, skir.PresentationSubject> get presentations {
  if (_presentations is EqualUnmodifiableMapView) return _presentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_presentations);
}

 final  Map<skir.CompilationRoot, skir.CompiledResourceState> _compiledStatuses;
@override@JsonKey() Map<skir.CompilationRoot, skir.CompiledResourceState> get compiledStatuses {
  if (_compiledStatuses is EqualUnmodifiableMapView) return _compiledStatuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_compiledStatuses);
}

 final  Map<String, skir.GraphSelectionResult> _selections;
@override@JsonKey() Map<String, skir.GraphSelectionResult> get selections {
  if (_selections is EqualUnmodifiableMapView) return _selections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selections);
}

 final  List<skir.AuthoringDiagnostic> _diagnostics;
@override@JsonKey() List<skir.AuthoringDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  bool refreshing;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionStateCopyWith<_AuthoringSessionState> get copyWith => __$AuthoringSessionStateCopyWithImpl<_AuthoringSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionState&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&const DeepCollectionEquality().equals(other.resources, _resources)&&const DeepCollectionEquality().equals(other.edges, _edges)&&const DeepCollectionEquality().equals(other.presentations, _presentations)&&const DeepCollectionEquality().equals(other.compiledStatuses, _compiledStatuses)&&const DeepCollectionEquality().equals(other.selections, _selections)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,generation,sequence,const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_presentations),const DeepCollectionEquality().hash(_compiledStatuses),const DeepCollectionEquality().hash(_selections),const DeepCollectionEquality().hash(_diagnostics),refreshing);
}

@override
String toString() {
    return 'AuthoringSessionState(generation: $generation, sequence: $sequence, resources: $resources, edges: $edges, presentations: $presentations, compiledStatuses: $compiledStatuses, selections: $selections, diagnostics: $diagnostics, refreshing: $refreshing)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionStateCopyWith<$Res> implements $AuthoringSessionStateCopyWith<$Res> {
  factory _$AuthoringSessionStateCopyWith(_AuthoringSessionState value, $Res Function(_AuthoringSessionState) _then) = __$AuthoringSessionStateCopyWithImpl;
@override @useResult
$Res call({
 skir.CatalogGeneration? generation, int? sequence, Map<skir.ResourceId, skir.AuthoringResource> resources, Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges, Map<skir.ResourceId, skir.PresentationSubject> presentations, Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses, Map<String, skir.GraphSelectionResult> selections, List<skir.AuthoringDiagnostic> diagnostics, bool refreshing
});




}
/// @nodoc
class __$AuthoringSessionStateCopyWithImpl<$Res>
    implements _$AuthoringSessionStateCopyWith<$Res> {
  __$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final _AuthoringSessionState _self;
  final $Res Function(_AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generation = freezed,Object? sequence = freezed,Object? resources = null,Object? edges = null,Object? presentations = null,Object? compiledStatuses = null,Object? selections = null,Object? diagnostics = null,Object? refreshing = null,}) {
  return _then(_AuthoringSessionState(
generation: freezed == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as skir.CatalogGeneration?,sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as Map<skir.AuthoringEdgeId, skir.AuthoringEdge>,presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.PresentationSubject>,compiledStatuses: null == compiledStatuses ? _self._compiledStatuses : compiledStatuses // ignore: cast_nullable_to_non_nullable
as Map<skir.CompilationRoot, skir.CompiledResourceState>,selections: null == selections ? _self._selections : selections // ignore: cast_nullable_to_non_nullable
as Map<String, skir.GraphSelectionResult>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<skir.AuthoringDiagnostic>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AuthoringSelectionLeaseState {

 skir.GraphSelection get selection; int get retainCount; skir.GraphSelectionResult? get result;
/// Create a copy of AuthoringSelectionLeaseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSelectionLeaseStateCopyWith<AuthoringSelectionLeaseState> get copyWith => _$AuthoringSelectionLeaseStateCopyWithImpl<AuthoringSelectionLeaseState>(this as AuthoringSelectionLeaseState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSelectionLeaseState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSelectionLeaseState&&(identical(other.selection, _this.selection) || other.selection == _this.selection)&&(identical(other.retainCount, _this.retainCount) || other.retainCount == _this.retainCount)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as AuthoringSelectionLeaseState;
  return Object.hash(runtimeType,_this.selection,_this.retainCount,_this.result);
}

@override
String toString() {
  final _this = this as AuthoringSelectionLeaseState;
  return 'AuthoringSelectionLeaseState(selection: ${_this.selection}, retainCount: ${_this.retainCount}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $AuthoringSelectionLeaseStateCopyWith<$Res>  {
  factory $AuthoringSelectionLeaseStateCopyWith(AuthoringSelectionLeaseState value, $Res Function(AuthoringSelectionLeaseState) _then) = _$AuthoringSelectionLeaseStateCopyWithImpl;
@useResult
$Res call({
 skir.GraphSelection selection, int retainCount, skir.GraphSelectionResult? result
});




}
/// @nodoc
class _$AuthoringSelectionLeaseStateCopyWithImpl<$Res>
    implements $AuthoringSelectionLeaseStateCopyWith<$Res> {
  _$AuthoringSelectionLeaseStateCopyWithImpl(this._self, this._then);

  final AuthoringSelectionLeaseState _self;
  final $Res Function(AuthoringSelectionLeaseState) _then;

/// Create a copy of AuthoringSelectionLeaseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selection = null,Object? retainCount = null,Object? result = freezed,}) {
  return _then(AuthoringSelectionLeaseState(
selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as skir.GraphSelection,retainCount: null == retainCount ? _self.retainCount : retainCount // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.GraphSelectionResult?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringSelectionLeaseState].
extension AuthoringSelectionLeaseStatePatterns on AuthoringSelectionLeaseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSelectionLeaseState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSelectionLeaseState value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSelectionLeaseState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.GraphSelection selection,  int retainCount,  skir.GraphSelectionResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState() when $default != null:
return $default(_that.selection,_that.retainCount,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.GraphSelection selection,  int retainCount,  skir.GraphSelectionResult? result)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState():
return $default(_that.selection,_that.retainCount,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.GraphSelection selection,  int retainCount,  skir.GraphSelectionResult? result)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSelectionLeaseState() when $default != null:
return $default(_that.selection,_that.retainCount,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSelectionLeaseState implements AuthoringSelectionLeaseState {
  const _AuthoringSelectionLeaseState({required this.selection, required this.retainCount, this.result});


@override final  skir.GraphSelection selection;
@override final  int retainCount;
@override final  skir.GraphSelectionResult? result;

/// Create a copy of AuthoringSelectionLeaseState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSelectionLeaseStateCopyWith<_AuthoringSelectionLeaseState> get copyWith => __$AuthoringSelectionLeaseStateCopyWithImpl<_AuthoringSelectionLeaseState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSelectionLeaseState&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.retainCount, retainCount) || other.retainCount == retainCount)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selection,retainCount,result);
}

@override
String toString() {
    return 'AuthoringSelectionLeaseState(selection: $selection, retainCount: $retainCount, result: $result)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSelectionLeaseStateCopyWith<$Res> implements $AuthoringSelectionLeaseStateCopyWith<$Res> {
  factory _$AuthoringSelectionLeaseStateCopyWith(_AuthoringSelectionLeaseState value, $Res Function(_AuthoringSelectionLeaseState) _then) = __$AuthoringSelectionLeaseStateCopyWithImpl;
@override @useResult
$Res call({
 skir.GraphSelection selection, int retainCount, skir.GraphSelectionResult? result
});




}
/// @nodoc
class __$AuthoringSelectionLeaseStateCopyWithImpl<$Res>
    implements _$AuthoringSelectionLeaseStateCopyWith<$Res> {
  __$AuthoringSelectionLeaseStateCopyWithImpl(this._self, this._then);

  final _AuthoringSelectionLeaseState _self;
  final $Res Function(_AuthoringSelectionLeaseState) _then;

/// Create a copy of AuthoringSelectionLeaseState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selection = null,Object? retainCount = null,Object? result = freezed,}) {
  return _then(_AuthoringSelectionLeaseState(
selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as skir.GraphSelection,retainCount: null == retainCount ? _self.retainCount : retainCount // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.GraphSelectionResult?,
  ));
}


}

// dart format on
