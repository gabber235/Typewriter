// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prepared_commit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PreparedCommit<T> {

 Object get id; String get label; Future<SubmissionResult<T>> Function() get send; Future<void> Function(SubmissionResult<T>)? get integrate; void Function()? get dispose; Set<Object> get resources; SubmissionReplay get replay;
/// Create a copy of PreparedCommit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedCommitCopyWith<T, PreparedCommit<T>> get copyWith => _$PreparedCommitCopyWithImpl<T, PreparedCommit<T>>(this as PreparedCommit<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PreparedCommit<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedCommit<T>&&const DeepCollectionEquality().equals(other.id, _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.send, _this.send) || other.send == _this.send)&&(identical(other.integrate, _this.integrate) || other.integrate == _this.integrate)&&(identical(other.dispose, _this.dispose) || other.dispose == _this.dispose)&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&(identical(other.replay, _this.replay) || other.replay == _this.replay));
}


@override
int get hashCode {
  final _this = this as PreparedCommit<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.id),_this.label,_this.send,_this.integrate,_this.dispose,const DeepCollectionEquality().hash(_this.resources),_this.replay);
}

@override
String toString() {
  final _this = this as PreparedCommit<T>;
  return 'PreparedCommit<$T>(id: ${_this.id}, label: ${_this.label}, send: ${_this.send}, integrate: ${_this.integrate}, dispose: ${_this.dispose}, resources: ${_this.resources}, replay: ${_this.replay})';
}


}

/// @nodoc
abstract mixin class $PreparedCommitCopyWith<T,$Res>  {
  factory $PreparedCommitCopyWith(PreparedCommit<T> value, $Res Function(PreparedCommit<T>) _then) = _$PreparedCommitCopyWithImpl;
@useResult
$Res call({
 Object id, String label, Future<SubmissionResult<T>> Function() send, Future<void> Function(SubmissionResult<T>)? integrate, void Function()? dispose, Set<Object> resources, SubmissionReplay replay
});




}
/// @nodoc
class _$PreparedCommitCopyWithImpl<T,$Res>
    implements $PreparedCommitCopyWith<T, $Res> {
  _$PreparedCommitCopyWithImpl(this._self, this._then);

  final PreparedCommit<T> _self;
  final $Res Function(PreparedCommit<T>) _then;

/// Create a copy of PreparedCommit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? send = null,Object? integrate = freezed,Object? dispose = freezed,Object? resources = null,Object? replay = null,}) {
  return _then(PreparedCommit(
id: null == id ? _self.id : id ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,send: null == send ? _self.send : send // ignore: cast_nullable_to_non_nullable
as Future<SubmissionResult<T>> Function(),integrate: freezed == integrate ? _self.integrate : integrate // ignore: cast_nullable_to_non_nullable
as Future<void> Function(SubmissionResult<T>)?,dispose: freezed == dispose ? _self.dispose : dispose // ignore: cast_nullable_to_non_nullable
as void Function()?,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Set<Object>,replay: null == replay ? _self.replay : replay // ignore: cast_nullable_to_non_nullable
as SubmissionReplay,
  ));
}

}


/// Adds pattern-matching-related methods to [PreparedCommit].
extension PreparedCommitPatterns<T> on PreparedCommit<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreparedCommit<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreparedCommit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreparedCommit<T> value)  $default,){
final _that = this;
switch (_that) {
case _PreparedCommit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreparedCommit<T> value)?  $default,){
final _that = this;
switch (_that) {
case _PreparedCommit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object id,  String label,  Future<SubmissionResult<T>> Function() send,  Future<void> Function(SubmissionResult<T>)? integrate,  void Function()? dispose,  Set<Object> resources,  SubmissionReplay replay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreparedCommit() when $default != null:
return $default(_that.id,_that.label,_that.send,_that.integrate,_that.dispose,_that.resources,_that.replay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object id,  String label,  Future<SubmissionResult<T>> Function() send,  Future<void> Function(SubmissionResult<T>)? integrate,  void Function()? dispose,  Set<Object> resources,  SubmissionReplay replay)  $default,) {final _that = this;
switch (_that) {
case _PreparedCommit():
return $default(_that.id,_that.label,_that.send,_that.integrate,_that.dispose,_that.resources,_that.replay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object id,  String label,  Future<SubmissionResult<T>> Function() send,  Future<void> Function(SubmissionResult<T>)? integrate,  void Function()? dispose,  Set<Object> resources,  SubmissionReplay replay)?  $default,) {final _that = this;
switch (_that) {
case _PreparedCommit() when $default != null:
return $default(_that.id,_that.label,_that.send,_that.integrate,_that.dispose,_that.resources,_that.replay);case _:
  return null;

}
}

}

/// @nodoc


class _PreparedCommit<T> implements PreparedCommit<T> {
  const _PreparedCommit({required this.id, required this.label, required this.send, this.integrate, this.dispose,  Set<Object> resources = const {}, this.replay = SubmissionReplay.unsupported}): _resources = resources;
  

@override final  Object id;
@override final  String label;
@override final  Future<SubmissionResult<T>> Function() send;
@override final  Future<void> Function(SubmissionResult<T>)? integrate;
@override final  void Function()? dispose;
 final  Set<Object> _resources;
@override@JsonKey() Set<Object> get resources {
  if (_resources is EqualUnmodifiableSetView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resources);
}

@override@JsonKey() final  SubmissionReplay replay;

/// Create a copy of PreparedCommit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreparedCommitCopyWith<T, _PreparedCommit<T>> get copyWith => __$PreparedCommitCopyWithImpl<T, _PreparedCommit<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreparedCommit<T>&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.label, label) || other.label == label)&&(identical(other.send, send) || other.send == send)&&(identical(other.integrate, integrate) || other.integrate == integrate)&&(identical(other.dispose, dispose) || other.dispose == dispose)&&const DeepCollectionEquality().equals(other.resources, _resources)&&(identical(other.replay, replay) || other.replay == replay));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(id),label,send,integrate,dispose,const DeepCollectionEquality().hash(_resources),replay);
}

@override
String toString() {
    return 'PreparedCommit<$T>(id: $id, label: $label, send: $send, integrate: $integrate, dispose: $dispose, resources: $resources, replay: $replay)';
}


}

/// @nodoc
abstract mixin class _$PreparedCommitCopyWith<T,$Res> implements $PreparedCommitCopyWith<T, $Res> {
  factory _$PreparedCommitCopyWith(_PreparedCommit<T> value, $Res Function(_PreparedCommit<T>) _then) = __$PreparedCommitCopyWithImpl;
@override @useResult
$Res call({
 Object id, String label, Future<SubmissionResult<T>> Function() send, Future<void> Function(SubmissionResult<T>)? integrate, void Function()? dispose, Set<Object> resources, SubmissionReplay replay
});




}
/// @nodoc
class __$PreparedCommitCopyWithImpl<T,$Res>
    implements _$PreparedCommitCopyWith<T, $Res> {
  __$PreparedCommitCopyWithImpl(this._self, this._then);

  final _PreparedCommit<T> _self;
  final $Res Function(_PreparedCommit<T>) _then;

/// Create a copy of PreparedCommit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? send = null,Object? integrate = freezed,Object? dispose = freezed,Object? resources = null,Object? replay = null,}) {
  return _then(_PreparedCommit<T>(
id: null == id ? _self.id : id ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,send: null == send ? _self.send : send // ignore: cast_nullable_to_non_nullable
as Future<SubmissionResult<T>> Function(),integrate: freezed == integrate ? _self.integrate : integrate // ignore: cast_nullable_to_non_nullable
as Future<void> Function(SubmissionResult<T>)?,dispose: freezed == dispose ? _self.dispose : dispose // ignore: cast_nullable_to_non_nullable
as void Function()?,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Set<Object>,replay: null == replay ? _self.replay : replay // ignore: cast_nullable_to_non_nullable
as SubmissionReplay,
  ));
}


}

// dart format on
