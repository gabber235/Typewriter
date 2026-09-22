// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_authoring_search_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenAuthoringResourceEffect {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get resourceId; ResourceDefinitionId get definition; skir.ResourceId? get bookId; skir.ResourceId? get ownerId; SelectableIdentifier? get nestedIdentifier;
/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringResourceEffectCopyWith<OpenAuthoringResourceEffect> get copyWith => _$OpenAuthoringResourceEffectCopyWithImpl<OpenAuthoringResourceEffect>(this as OpenAuthoringResourceEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringResourceEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringResourceEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId)&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.nestedIdentifier, _this.nestedIdentifier) || other.nestedIdentifier == _this.nestedIdentifier));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringResourceEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.resourceId,_this.definition,_this.bookId,_this.ownerId,_this.nestedIdentifier);
}

@override
String toString() {
  final _this = this as OpenAuthoringResourceEffect;
  return 'OpenAuthoringResourceEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, resourceId: ${_this.resourceId}, definition: ${_this.definition}, bookId: ${_this.bookId}, ownerId: ${_this.ownerId}, nestedIdentifier: ${_this.nestedIdentifier})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringResourceEffectCopyWith<$Res>  {
  factory $OpenAuthoringResourceEffectCopyWith(OpenAuthoringResourceEffect value, $Res Function(OpenAuthoringResourceEffect) _then) = _$OpenAuthoringResourceEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId resourceId, ResourceDefinitionId definition, skir.ResourceId? bookId, skir.ResourceId? ownerId, SelectableIdentifier? nestedIdentifier
});




}
/// @nodoc
class _$OpenAuthoringResourceEffectCopyWithImpl<$Res>
    implements $OpenAuthoringResourceEffectCopyWith<$Res> {
  _$OpenAuthoringResourceEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringResourceEffect _self;
  final $Res Function(OpenAuthoringResourceEffect) _then;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? resourceId = null,Object? definition = null,Object? bookId = freezed,Object? ownerId = freezed,Object? nestedIdentifier = freezed,}) {
  return _then(OpenAuthoringResourceEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as ResourceDefinitionId,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,nestedIdentifier: freezed == nestedIdentifier ? _self.nestedIdentifier : nestedIdentifier // ignore: cast_nullable_to_non_nullable
as SelectableIdentifier?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAuthoringResourceEffect].
extension OpenAuthoringResourceEffectPatterns on OpenAuthoringResourceEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringResourceEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringResourceEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringResourceEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId,  ResourceDefinitionId definition,  skir.ResourceId? bookId,  skir.ResourceId? ownerId,  SelectableIdentifier? nestedIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resourceId,_that.definition,_that.bookId,_that.ownerId,_that.nestedIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId,  ResourceDefinitionId definition,  skir.ResourceId? bookId,  skir.ResourceId? ownerId,  SelectableIdentifier? nestedIdentifier)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect():
return $default(_that.organizationId,_that.realmId,_that.resourceId,_that.definition,_that.bookId,_that.ownerId,_that.nestedIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId,  ResourceDefinitionId definition,  skir.ResourceId? bookId,  skir.ResourceId? ownerId,  SelectableIdentifier? nestedIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resourceId,_that.definition,_that.bookId,_that.ownerId,_that.nestedIdentifier);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringResourceEffect implements OpenAuthoringResourceEffect {
  const _OpenAuthoringResourceEffect({required this.organizationId, required this.realmId, required this.resourceId, required this.definition, required this.bookId, required this.ownerId, required this.nestedIdentifier});


@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId resourceId;
@override final  ResourceDefinitionId definition;
@override final  skir.ResourceId? bookId;
@override final  skir.ResourceId? ownerId;
@override final  SelectableIdentifier? nestedIdentifier;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringResourceEffectCopyWith<_OpenAuthoringResourceEffect> get copyWith => __$OpenAuthoringResourceEffectCopyWithImpl<_OpenAuthoringResourceEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringResourceEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.nestedIdentifier, nestedIdentifier) || other.nestedIdentifier == nestedIdentifier));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,resourceId,definition,bookId,ownerId,nestedIdentifier);
}

@override
String toString() {
    return 'OpenAuthoringResourceEffect(organizationId: $organizationId, realmId: $realmId, resourceId: $resourceId, definition: $definition, bookId: $bookId, ownerId: $ownerId, nestedIdentifier: $nestedIdentifier)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringResourceEffectCopyWith<$Res> implements $OpenAuthoringResourceEffectCopyWith<$Res> {
  factory _$OpenAuthoringResourceEffectCopyWith(_OpenAuthoringResourceEffect value, $Res Function(_OpenAuthoringResourceEffect) _then) = __$OpenAuthoringResourceEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId resourceId, ResourceDefinitionId definition, skir.ResourceId? bookId, skir.ResourceId? ownerId, SelectableIdentifier? nestedIdentifier
});




}
/// @nodoc
class __$OpenAuthoringResourceEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringResourceEffectCopyWith<$Res> {
  __$OpenAuthoringResourceEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringResourceEffect _self;
  final $Res Function(_OpenAuthoringResourceEffect) _then;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? resourceId = null,Object? definition = null,Object? bookId = freezed,Object? ownerId = freezed,Object? nestedIdentifier = freezed,}) {
  return _then(_OpenAuthoringResourceEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as ResourceDefinitionId,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,nestedIdentifier: freezed == nestedIdentifier ? _self.nestedIdentifier : nestedIdentifier // ignore: cast_nullable_to_non_nullable
as SelectableIdentifier?,
  ));
}


}

// dart format on
