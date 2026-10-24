// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_editing_registration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValueEditingRegistration {

 Object get targetId; String get label; ValueEditPersistence get persistence; EditorSnapshot get snapshot; EditorCommitPolicy get commitPolicy; EditObservationAdmission get observations; PortablePresentationHostBuilder? get portablePresentation; VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? get observe;
/// Create a copy of ValueEditingRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueEditingRegistrationCopyWith<ValueEditingRegistration> get copyWith => _$ValueEditingRegistrationCopyWithImpl<ValueEditingRegistration>(this as ValueEditingRegistration, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ValueEditingRegistration;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueEditingRegistration&&const DeepCollectionEquality().equals(other.targetId, _this.targetId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.persistence, _this.persistence) || other.persistence == _this.persistence)&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot)&&(identical(other.commitPolicy, _this.commitPolicy) || other.commitPolicy == _this.commitPolicy)&&(identical(other.observations, _this.observations) || other.observations == _this.observations)&&(identical(other.portablePresentation, _this.portablePresentation) || other.portablePresentation == _this.portablePresentation)&&(identical(other.observe, _this.observe) || other.observe == _this.observe));
}


@override
int get hashCode {
  final _this = this as ValueEditingRegistration;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.targetId),_this.label,_this.persistence,_this.snapshot,_this.commitPolicy,_this.observations,_this.portablePresentation,_this.observe);
}

@override
String toString() {
  final _this = this as ValueEditingRegistration;
  return 'ValueEditingRegistration(targetId: ${_this.targetId}, label: ${_this.label}, persistence: ${_this.persistence}, snapshot: ${_this.snapshot}, commitPolicy: ${_this.commitPolicy}, observations: ${_this.observations}, portablePresentation: ${_this.portablePresentation}, observe: ${_this.observe})';
}


}

/// @nodoc
abstract mixin class $ValueEditingRegistrationCopyWith<$Res>  {
  factory $ValueEditingRegistrationCopyWith(ValueEditingRegistration value, $Res Function(ValueEditingRegistration) _then) = _$ValueEditingRegistrationCopyWithImpl;
@useResult
$Res call({
 Object targetId, String label, ValueEditPersistence persistence, EditorSnapshot snapshot, EditorCommitPolicy commitPolicy, EditObservationAdmission observations, PortablePresentationHostBuilder? portablePresentation, VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe
});




}
/// @nodoc
class _$ValueEditingRegistrationCopyWithImpl<$Res>
    implements $ValueEditingRegistrationCopyWith<$Res> {
  _$ValueEditingRegistrationCopyWithImpl(this._self, this._then);

  final ValueEditingRegistration _self;
  final $Res Function(ValueEditingRegistration) _then;

/// Create a copy of ValueEditingRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetId = null,Object? label = null,Object? persistence = null,Object? snapshot = null,Object? commitPolicy = null,Object? observations = null,Object? portablePresentation = freezed,Object? observe = freezed,}) {
  return _then(ValueEditingRegistration(
targetId: null == targetId ? _self.targetId : targetId ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,persistence: null == persistence ? _self.persistence : persistence // ignore: cast_nullable_to_non_nullable
as ValueEditPersistence,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EditorSnapshot,commitPolicy: null == commitPolicy ? _self.commitPolicy : commitPolicy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as EditObservationAdmission,portablePresentation: freezed == portablePresentation ? _self.portablePresentation : portablePresentation // ignore: cast_nullable_to_non_nullable
as PortablePresentationHostBuilder?,observe: freezed == observe ? _self.observe : observe // ignore: cast_nullable_to_non_nullable
as VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)?,
  ));
}

}


/// Adds pattern-matching-related methods to [ValueEditingRegistration].
extension ValueEditingRegistrationPatterns on ValueEditingRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValueEditingRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueEditingRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValueEditingRegistration value)  $default,){
final _that = this;
switch (_that) {
case _ValueEditingRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValueEditingRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _ValueEditingRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object targetId,  String label,  ValueEditPersistence persistence,  EditorSnapshot snapshot,  EditorCommitPolicy commitPolicy,  EditObservationAdmission observations,  PortablePresentationHostBuilder? portablePresentation,  VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValueEditingRegistration() when $default != null:
return $default(_that.targetId,_that.label,_that.persistence,_that.snapshot,_that.commitPolicy,_that.observations,_that.portablePresentation,_that.observe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object targetId,  String label,  ValueEditPersistence persistence,  EditorSnapshot snapshot,  EditorCommitPolicy commitPolicy,  EditObservationAdmission observations,  PortablePresentationHostBuilder? portablePresentation,  VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe)  $default,) {final _that = this;
switch (_that) {
case _ValueEditingRegistration():
return $default(_that.targetId,_that.label,_that.persistence,_that.snapshot,_that.commitPolicy,_that.observations,_that.portablePresentation,_that.observe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object targetId,  String label,  ValueEditPersistence persistence,  EditorSnapshot snapshot,  EditorCommitPolicy commitPolicy,  EditObservationAdmission observations,  PortablePresentationHostBuilder? portablePresentation,  VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe)?  $default,) {final _that = this;
switch (_that) {
case _ValueEditingRegistration() when $default != null:
return $default(_that.targetId,_that.label,_that.persistence,_that.snapshot,_that.commitPolicy,_that.observations,_that.portablePresentation,_that.observe);case _:
  return null;

}
}

}

/// @nodoc


class _ValueEditingRegistration extends ValueEditingRegistration {
  const _ValueEditingRegistration({required this.targetId, required this.label, required this.persistence, required this.snapshot, this.commitPolicy = EditorCommitPolicy.autosaveChanges, this.observations = EditObservationAdmission.rebase, this.portablePresentation, this.observe}): super._();
  

@override final  Object targetId;
@override final  String label;
@override final  ValueEditPersistence persistence;
@override final  EditorSnapshot snapshot;
@override@JsonKey() final  EditorCommitPolicy commitPolicy;
@override@JsonKey() final  EditObservationAdmission observations;
@override final  PortablePresentationHostBuilder? portablePresentation;
@override final  VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe;

/// Create a copy of ValueEditingRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueEditingRegistrationCopyWith<_ValueEditingRegistration> get copyWith => __$ValueEditingRegistrationCopyWithImpl<_ValueEditingRegistration>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueEditingRegistration&&const DeepCollectionEquality().equals(other.targetId, targetId)&&(identical(other.label, label) || other.label == label)&&(identical(other.persistence, persistence) || other.persistence == persistence)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.commitPolicy, commitPolicy) || other.commitPolicy == commitPolicy)&&(identical(other.observations, observations) || other.observations == observations)&&(identical(other.portablePresentation, portablePresentation) || other.portablePresentation == portablePresentation)&&(identical(other.observe, observe) || other.observe == observe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(targetId),label,persistence,snapshot,commitPolicy,observations,portablePresentation,observe);
}

@override
String toString() {
    return 'ValueEditingRegistration(targetId: $targetId, label: $label, persistence: $persistence, snapshot: $snapshot, commitPolicy: $commitPolicy, observations: $observations, portablePresentation: $portablePresentation, observe: $observe)';
}


}

/// @nodoc
abstract mixin class _$ValueEditingRegistrationCopyWith<$Res> implements $ValueEditingRegistrationCopyWith<$Res> {
  factory _$ValueEditingRegistrationCopyWith(_ValueEditingRegistration value, $Res Function(_ValueEditingRegistration) _then) = __$ValueEditingRegistrationCopyWithImpl;
@override @useResult
$Res call({
 Object targetId, String label, ValueEditPersistence persistence, EditorSnapshot snapshot, EditorCommitPolicy commitPolicy, EditObservationAdmission observations, PortablePresentationHostBuilder? portablePresentation, VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)? observe
});




}
/// @nodoc
class __$ValueEditingRegistrationCopyWithImpl<$Res>
    implements _$ValueEditingRegistrationCopyWith<$Res> {
  __$ValueEditingRegistrationCopyWithImpl(this._self, this._then);

  final _ValueEditingRegistration _self;
  final $Res Function(_ValueEditingRegistration) _then;

/// Create a copy of ValueEditingRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetId = null,Object? label = null,Object? persistence = null,Object? snapshot = null,Object? commitPolicy = null,Object? observations = null,Object? portablePresentation = freezed,Object? observe = freezed,}) {
  return _then(_ValueEditingRegistration(
targetId: null == targetId ? _self.targetId : targetId ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,persistence: null == persistence ? _self.persistence : persistence // ignore: cast_nullable_to_non_nullable
as ValueEditPersistence,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EditorSnapshot,commitPolicy: null == commitPolicy ? _self.commitPolicy : commitPolicy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as EditObservationAdmission,portablePresentation: freezed == portablePresentation ? _self.portablePresentation : portablePresentation // ignore: cast_nullable_to_non_nullable
as PortablePresentationHostBuilder?,observe: freezed == observe ? _self.observe : observe // ignore: cast_nullable_to_non_nullable
as VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)?,
  ));
}


}

// dart format on
