// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_work.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalWorkScope implements DiagnosticableTreeMixin {

 String? get userId; RecordId? get organizationId;
/// Create a copy of LocalWorkScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalWorkScopeCopyWith<LocalWorkScope> get copyWith => _$LocalWorkScopeCopyWithImpl<LocalWorkScope>(this as LocalWorkScope, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as LocalWorkScope;
  properties
    ..add(DiagnosticsProperty('type', 'LocalWorkScope'))
    ..add(DiagnosticsProperty('userId', _this.userId))..add(DiagnosticsProperty('organizationId', _this.organizationId));
}

@override
bool operator ==(Object other) {
  final _this = this as LocalWorkScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalWorkScope&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId));
}


@override
int get hashCode {
  final _this = this as LocalWorkScope;
  return Object.hash(runtimeType,_this.userId,_this.organizationId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as LocalWorkScope;
  return 'LocalWorkScope(userId: ${_this.userId}, organizationId: ${_this.organizationId})';
}


}

/// @nodoc
abstract mixin class $LocalWorkScopeCopyWith<$Res>  {
  factory $LocalWorkScopeCopyWith(LocalWorkScope value, $Res Function(LocalWorkScope) _then) = _$LocalWorkScopeCopyWithImpl;
@useResult
$Res call({
 String? userId, RecordId? organizationId
});




}
/// @nodoc
class _$LocalWorkScopeCopyWithImpl<$Res>
    implements $LocalWorkScopeCopyWith<$Res> {
  _$LocalWorkScopeCopyWithImpl(this._self, this._then);

  final LocalWorkScope _self;
  final $Res Function(LocalWorkScope) _then;

/// Create a copy of LocalWorkScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = freezed,Object? organizationId = freezed,}) {
  return _then(LocalWorkScope(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as RecordId?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalWorkScope].
extension LocalWorkScopePatterns on LocalWorkScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalWorkScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalWorkScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalWorkScope value)  $default,){
final _that = this;
switch (_that) {
case _LocalWorkScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalWorkScope value)?  $default,){
final _that = this;
switch (_that) {
case _LocalWorkScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? userId,  RecordId? organizationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalWorkScope() when $default != null:
return $default(_that.userId,_that.organizationId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? userId,  RecordId? organizationId)  $default,) {final _that = this;
switch (_that) {
case _LocalWorkScope():
return $default(_that.userId,_that.organizationId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? userId,  RecordId? organizationId)?  $default,) {final _that = this;
switch (_that) {
case _LocalWorkScope() when $default != null:
return $default(_that.userId,_that.organizationId);case _:
  return null;

}
}

}

/// @nodoc


class _LocalWorkScope with DiagnosticableTreeMixin implements LocalWorkScope {
  const _LocalWorkScope({required this.userId, required this.organizationId});


@override final  String? userId;
@override final  RecordId? organizationId;

/// Create a copy of LocalWorkScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalWorkScopeCopyWith<_LocalWorkScope> get copyWith => __$LocalWorkScopeCopyWithImpl<_LocalWorkScope>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'LocalWorkScope'))
    ..add(DiagnosticsProperty('userId', userId))..add(DiagnosticsProperty('organizationId', organizationId));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalWorkScope&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,organizationId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'LocalWorkScope(userId: $userId, organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class _$LocalWorkScopeCopyWith<$Res> implements $LocalWorkScopeCopyWith<$Res> {
  factory _$LocalWorkScopeCopyWith(_LocalWorkScope value, $Res Function(_LocalWorkScope) _then) = __$LocalWorkScopeCopyWithImpl;
@override @useResult
$Res call({
 String? userId, RecordId? organizationId
});




}
/// @nodoc
class __$LocalWorkScopeCopyWithImpl<$Res>
    implements _$LocalWorkScopeCopyWith<$Res> {
  __$LocalWorkScopeCopyWithImpl(this._self, this._then);

  final _LocalWorkScope _self;
  final $Res Function(_LocalWorkScope) _then;

/// Create a copy of LocalWorkScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = freezed,Object? organizationId = freezed,}) {
  return _then(_LocalWorkScope(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as RecordId?,
  ));
}


}

/// @nodoc
mixin _$EditorResourceScope implements DiagnosticableTreeMixin {

 RecordId get organizationId; RecordId? get realmId;
/// Create a copy of EditorResourceScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorResourceScopeCopyWith<EditorResourceScope> get copyWith => _$EditorResourceScopeCopyWithImpl<EditorResourceScope>(this as EditorResourceScope, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as EditorResourceScope;
  properties
    ..add(DiagnosticsProperty('type', 'EditorResourceScope'))
    ..add(DiagnosticsProperty('organizationId', _this.organizationId))..add(DiagnosticsProperty('realmId', _this.realmId));
}

@override
bool operator ==(Object other) {
  final _this = this as EditorResourceScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorResourceScope&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId));
}


@override
int get hashCode {
  final _this = this as EditorResourceScope;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as EditorResourceScope;
  return 'EditorResourceScope(organizationId: ${_this.organizationId}, realmId: ${_this.realmId})';
}


}

/// @nodoc
abstract mixin class $EditorResourceScopeCopyWith<$Res>  {
  factory $EditorResourceScopeCopyWith(EditorResourceScope value, $Res Function(EditorResourceScope) _then) = _$EditorResourceScopeCopyWithImpl;
@useResult
$Res call({
 RecordId organizationId, RecordId? realmId
});




}
/// @nodoc
class _$EditorResourceScopeCopyWithImpl<$Res>
    implements $EditorResourceScopeCopyWith<$Res> {
  _$EditorResourceScopeCopyWithImpl(this._self, this._then);

  final EditorResourceScope _self;
  final $Res Function(EditorResourceScope) _then;

/// Create a copy of EditorResourceScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = freezed,}) {
  return _then(EditorResourceScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as RecordId,realmId: freezed == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as RecordId?,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorResourceScope].
extension EditorResourceScopePatterns on EditorResourceScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorResourceScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorResourceScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorResourceScope value)  $default,){
final _that = this;
switch (_that) {
case _EditorResourceScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorResourceScope value)?  $default,){
final _that = this;
switch (_that) {
case _EditorResourceScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RecordId organizationId,  RecordId? realmId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorResourceScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RecordId organizationId,  RecordId? realmId)  $default,) {final _that = this;
switch (_that) {
case _EditorResourceScope():
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RecordId organizationId,  RecordId? realmId)?  $default,) {final _that = this;
switch (_that) {
case _EditorResourceScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
  return null;

}
}

}

/// @nodoc


class _EditorResourceScope with DiagnosticableTreeMixin implements EditorResourceScope {
  const _EditorResourceScope({required this.organizationId, this.realmId});


@override final  RecordId organizationId;
@override final  RecordId? realmId;

/// Create a copy of EditorResourceScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorResourceScopeCopyWith<_EditorResourceScope> get copyWith => __$EditorResourceScopeCopyWithImpl<_EditorResourceScope>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'EditorResourceScope'))
    ..add(DiagnosticsProperty('organizationId', organizationId))..add(DiagnosticsProperty('realmId', realmId));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorResourceScope&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'EditorResourceScope(organizationId: $organizationId, realmId: $realmId)';
}


}

/// @nodoc
abstract mixin class _$EditorResourceScopeCopyWith<$Res> implements $EditorResourceScopeCopyWith<$Res> {
  factory _$EditorResourceScopeCopyWith(_EditorResourceScope value, $Res Function(_EditorResourceScope) _then) = __$EditorResourceScopeCopyWithImpl;
@override @useResult
$Res call({
 RecordId organizationId, RecordId? realmId
});




}
/// @nodoc
class __$EditorResourceScopeCopyWithImpl<$Res>
    implements _$EditorResourceScopeCopyWith<$Res> {
  __$EditorResourceScopeCopyWithImpl(this._self, this._then);

  final _EditorResourceScope _self;
  final $Res Function(_EditorResourceScope) _then;

/// Create a copy of EditorResourceScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = freezed,}) {
  return _then(_EditorResourceScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as RecordId,realmId: freezed == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as RecordId?,
  ));
}


}

/// @nodoc
mixin _$EditorResourceKey implements DiagnosticableTreeMixin {

 Object? get scope; Object get identity;
/// Create a copy of EditorResourceKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorResourceKeyCopyWith<EditorResourceKey> get copyWith => _$EditorResourceKeyCopyWithImpl<EditorResourceKey>(this as EditorResourceKey, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as EditorResourceKey;
  properties
    ..add(DiagnosticsProperty('type', 'EditorResourceKey'))
    ..add(DiagnosticsProperty('scope', _this.scope))..add(DiagnosticsProperty('identity', _this.identity));
}

@override
bool operator ==(Object other) {
  final _this = this as EditorResourceKey;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorResourceKey&&const DeepCollectionEquality().equals(other.scope, _this.scope)&&const DeepCollectionEquality().equals(other.identity, _this.identity));
}


@override
int get hashCode {
  final _this = this as EditorResourceKey;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.scope),const DeepCollectionEquality().hash(_this.identity));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as EditorResourceKey;
  return 'EditorResourceKey(scope: ${_this.scope}, identity: ${_this.identity})';
}


}

/// @nodoc
abstract mixin class $EditorResourceKeyCopyWith<$Res>  {
  factory $EditorResourceKeyCopyWith(EditorResourceKey value, $Res Function(EditorResourceKey) _then) = _$EditorResourceKeyCopyWithImpl;
@useResult
$Res call({
 Object? scope, Object identity
});




}
/// @nodoc
class _$EditorResourceKeyCopyWithImpl<$Res>
    implements $EditorResourceKeyCopyWith<$Res> {
  _$EditorResourceKeyCopyWithImpl(this._self, this._then);

  final EditorResourceKey _self;
  final $Res Function(EditorResourceKey) _then;

/// Create a copy of EditorResourceKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = freezed,Object? identity = null,}) {
  return _then(EditorResourceKey(
scope: freezed == scope ? _self.scope : scope ,identity: null == identity ? _self.identity : identity ,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorResourceKey].
extension EditorResourceKeyPatterns on EditorResourceKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorResourceKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorResourceKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorResourceKey value)  $default,){
final _that = this;
switch (_that) {
case _EditorResourceKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorResourceKey value)?  $default,){
final _that = this;
switch (_that) {
case _EditorResourceKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object? scope,  Object identity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorResourceKey() when $default != null:
return $default(_that.scope,_that.identity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object? scope,  Object identity)  $default,) {final _that = this;
switch (_that) {
case _EditorResourceKey():
return $default(_that.scope,_that.identity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object? scope,  Object identity)?  $default,) {final _that = this;
switch (_that) {
case _EditorResourceKey() when $default != null:
return $default(_that.scope,_that.identity);case _:
  return null;

}
}

}

/// @nodoc


class _EditorResourceKey with DiagnosticableTreeMixin implements EditorResourceKey {
  const _EditorResourceKey({required this.scope, required this.identity});


@override final  Object? scope;
@override final  Object identity;

/// Create a copy of EditorResourceKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorResourceKeyCopyWith<_EditorResourceKey> get copyWith => __$EditorResourceKeyCopyWithImpl<_EditorResourceKey>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'EditorResourceKey'))
    ..add(DiagnosticsProperty('scope', scope))..add(DiagnosticsProperty('identity', identity));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorResourceKey&&const DeepCollectionEquality().equals(other.scope, scope)&&const DeepCollectionEquality().equals(other.identity, identity));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(scope),const DeepCollectionEquality().hash(identity));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'EditorResourceKey(scope: $scope, identity: $identity)';
}


}

/// @nodoc
abstract mixin class _$EditorResourceKeyCopyWith<$Res> implements $EditorResourceKeyCopyWith<$Res> {
  factory _$EditorResourceKeyCopyWith(_EditorResourceKey value, $Res Function(_EditorResourceKey) _then) = __$EditorResourceKeyCopyWithImpl;
@override @useResult
$Res call({
 Object? scope, Object identity
});




}
/// @nodoc
class __$EditorResourceKeyCopyWithImpl<$Res>
    implements _$EditorResourceKeyCopyWith<$Res> {
  __$EditorResourceKeyCopyWithImpl(this._self, this._then);

  final _EditorResourceKey _self;
  final $Res Function(_EditorResourceKey) _then;

/// Create a copy of EditorResourceKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = freezed,Object? identity = null,}) {
  return _then(_EditorResourceKey(
scope: freezed == scope ? _self.scope : scope ,identity: null == identity ? _self.identity : identity ,
  ));
}


}

// dart format on
