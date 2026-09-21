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
mixin _$OpenAuthoringBookEffect {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get bookId;
/// Create a copy of OpenAuthoringBookEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringBookEffectCopyWith<OpenAuthoringBookEffect> get copyWith => _$OpenAuthoringBookEffectCopyWithImpl<OpenAuthoringBookEffect>(this as OpenAuthoringBookEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringBookEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringBookEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringBookEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.bookId);
}

@override
String toString() {
  final _this = this as OpenAuthoringBookEffect;
  return 'OpenAuthoringBookEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, bookId: ${_this.bookId})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringBookEffectCopyWith<$Res>  {
  factory $OpenAuthoringBookEffectCopyWith(OpenAuthoringBookEffect value, $Res Function(OpenAuthoringBookEffect) _then) = _$OpenAuthoringBookEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId
});




}
/// @nodoc
class _$OpenAuthoringBookEffectCopyWithImpl<$Res>
    implements $OpenAuthoringBookEffectCopyWith<$Res> {
  _$OpenAuthoringBookEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringBookEffect _self;
  final $Res Function(OpenAuthoringBookEffect) _then;

/// Create a copy of OpenAuthoringBookEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,}) {
  return _then(OpenAuthoringBookEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAuthoringBookEffect].
extension OpenAuthoringBookEffectPatterns on OpenAuthoringBookEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringBookEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringBookEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringBookEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect():
return $default(_that.organizationId,_that.realmId,_that.bookId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringBookEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringBookEffect implements OpenAuthoringBookEffect {
  const _OpenAuthoringBookEffect({required this.organizationId, required this.realmId, required this.bookId});
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId bookId;

/// Create a copy of OpenAuthoringBookEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringBookEffectCopyWith<_OpenAuthoringBookEffect> get copyWith => __$OpenAuthoringBookEffectCopyWithImpl<_OpenAuthoringBookEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringBookEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.bookId, bookId) || other.bookId == bookId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,bookId);
}

@override
String toString() {
    return 'OpenAuthoringBookEffect(organizationId: $organizationId, realmId: $realmId, bookId: $bookId)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringBookEffectCopyWith<$Res> implements $OpenAuthoringBookEffectCopyWith<$Res> {
  factory _$OpenAuthoringBookEffectCopyWith(_OpenAuthoringBookEffect value, $Res Function(_OpenAuthoringBookEffect) _then) = __$OpenAuthoringBookEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId
});




}
/// @nodoc
class __$OpenAuthoringBookEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringBookEffectCopyWith<$Res> {
  __$OpenAuthoringBookEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringBookEffect _self;
  final $Res Function(_OpenAuthoringBookEffect) _then;

/// Create a copy of OpenAuthoringBookEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,}) {
  return _then(_OpenAuthoringBookEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc
mixin _$OpenAuthoringTagEffect {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get tagId;
/// Create a copy of OpenAuthoringTagEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringTagEffectCopyWith<OpenAuthoringTagEffect> get copyWith => _$OpenAuthoringTagEffectCopyWithImpl<OpenAuthoringTagEffect>(this as OpenAuthoringTagEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringTagEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringTagEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.tagId, _this.tagId) || other.tagId == _this.tagId));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringTagEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.tagId);
}

@override
String toString() {
  final _this = this as OpenAuthoringTagEffect;
  return 'OpenAuthoringTagEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, tagId: ${_this.tagId})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringTagEffectCopyWith<$Res>  {
  factory $OpenAuthoringTagEffectCopyWith(OpenAuthoringTagEffect value, $Res Function(OpenAuthoringTagEffect) _then) = _$OpenAuthoringTagEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId tagId
});




}
/// @nodoc
class _$OpenAuthoringTagEffectCopyWithImpl<$Res>
    implements $OpenAuthoringTagEffectCopyWith<$Res> {
  _$OpenAuthoringTagEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringTagEffect _self;
  final $Res Function(OpenAuthoringTagEffect) _then;

/// Create a copy of OpenAuthoringTagEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? tagId = null,}) {
  return _then(OpenAuthoringTagEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAuthoringTagEffect].
extension OpenAuthoringTagEffectPatterns on OpenAuthoringTagEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringTagEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringTagEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringTagEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId tagId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.tagId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId tagId)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect():
return $default(_that.organizationId,_that.realmId,_that.tagId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId tagId)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringTagEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.tagId);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringTagEffect implements OpenAuthoringTagEffect {
  const _OpenAuthoringTagEffect({required this.organizationId, required this.realmId, required this.tagId});
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId tagId;

/// Create a copy of OpenAuthoringTagEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringTagEffectCopyWith<_OpenAuthoringTagEffect> get copyWith => __$OpenAuthoringTagEffectCopyWithImpl<_OpenAuthoringTagEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringTagEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.tagId, tagId) || other.tagId == tagId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,tagId);
}

@override
String toString() {
    return 'OpenAuthoringTagEffect(organizationId: $organizationId, realmId: $realmId, tagId: $tagId)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringTagEffectCopyWith<$Res> implements $OpenAuthoringTagEffectCopyWith<$Res> {
  factory _$OpenAuthoringTagEffectCopyWith(_OpenAuthoringTagEffect value, $Res Function(_OpenAuthoringTagEffect) _then) = __$OpenAuthoringTagEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId tagId
});




}
/// @nodoc
class __$OpenAuthoringTagEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringTagEffectCopyWith<$Res> {
  __$OpenAuthoringTagEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringTagEffect _self;
  final $Res Function(_OpenAuthoringTagEffect) _then;

/// Create a copy of OpenAuthoringTagEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? tagId = null,}) {
  return _then(_OpenAuthoringTagEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc
mixin _$OpenAuthoringPageEffect {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get bookId; skir.ResourceId get pageId;
/// Create a copy of OpenAuthoringPageEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringPageEffectCopyWith<OpenAuthoringPageEffect> get copyWith => _$OpenAuthoringPageEffectCopyWithImpl<OpenAuthoringPageEffect>(this as OpenAuthoringPageEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringPageEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringPageEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.pageId, _this.pageId) || other.pageId == _this.pageId));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringPageEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.bookId,_this.pageId);
}

@override
String toString() {
  final _this = this as OpenAuthoringPageEffect;
  return 'OpenAuthoringPageEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, bookId: ${_this.bookId}, pageId: ${_this.pageId})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringPageEffectCopyWith<$Res>  {
  factory $OpenAuthoringPageEffectCopyWith(OpenAuthoringPageEffect value, $Res Function(OpenAuthoringPageEffect) _then) = _$OpenAuthoringPageEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId, skir.ResourceId pageId
});




}
/// @nodoc
class _$OpenAuthoringPageEffectCopyWithImpl<$Res>
    implements $OpenAuthoringPageEffectCopyWith<$Res> {
  _$OpenAuthoringPageEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringPageEffect _self;
  final $Res Function(OpenAuthoringPageEffect) _then;

/// Create a copy of OpenAuthoringPageEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,Object? pageId = null,}) {
  return _then(OpenAuthoringPageEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAuthoringPageEffect].
extension OpenAuthoringPageEffectPatterns on OpenAuthoringPageEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringPageEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringPageEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringPageEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect():
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringPageEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringPageEffect implements OpenAuthoringPageEffect {
  const _OpenAuthoringPageEffect({required this.organizationId, required this.realmId, required this.bookId, required this.pageId});
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId bookId;
@override final  skir.ResourceId pageId;

/// Create a copy of OpenAuthoringPageEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringPageEffectCopyWith<_OpenAuthoringPageEffect> get copyWith => __$OpenAuthoringPageEffectCopyWithImpl<_OpenAuthoringPageEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringPageEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.pageId, pageId) || other.pageId == pageId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,bookId,pageId);
}

@override
String toString() {
    return 'OpenAuthoringPageEffect(organizationId: $organizationId, realmId: $realmId, bookId: $bookId, pageId: $pageId)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringPageEffectCopyWith<$Res> implements $OpenAuthoringPageEffectCopyWith<$Res> {
  factory _$OpenAuthoringPageEffectCopyWith(_OpenAuthoringPageEffect value, $Res Function(_OpenAuthoringPageEffect) _then) = __$OpenAuthoringPageEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId, skir.ResourceId pageId
});




}
/// @nodoc
class __$OpenAuthoringPageEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringPageEffectCopyWith<$Res> {
  __$OpenAuthoringPageEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringPageEffect _self;
  final $Res Function(_OpenAuthoringPageEffect) _then;

/// Create a copy of OpenAuthoringPageEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,Object? pageId = null,}) {
  return _then(_OpenAuthoringPageEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc
mixin _$OpenAuthoringElementEffect {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get bookId; skir.ResourceId get pageId; SelectableIdentifier? get elementIdentifier;
/// Create a copy of OpenAuthoringElementEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringElementEffectCopyWith<OpenAuthoringElementEffect> get copyWith => _$OpenAuthoringElementEffectCopyWithImpl<OpenAuthoringElementEffect>(this as OpenAuthoringElementEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringElementEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringElementEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.pageId, _this.pageId) || other.pageId == _this.pageId)&&(identical(other.elementIdentifier, _this.elementIdentifier) || other.elementIdentifier == _this.elementIdentifier));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringElementEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.bookId,_this.pageId,_this.elementIdentifier);
}

@override
String toString() {
  final _this = this as OpenAuthoringElementEffect;
  return 'OpenAuthoringElementEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, bookId: ${_this.bookId}, pageId: ${_this.pageId}, elementIdentifier: ${_this.elementIdentifier})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringElementEffectCopyWith<$Res>  {
  factory $OpenAuthoringElementEffectCopyWith(OpenAuthoringElementEffect value, $Res Function(OpenAuthoringElementEffect) _then) = _$OpenAuthoringElementEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId, skir.ResourceId pageId, SelectableIdentifier? elementIdentifier
});




}
/// @nodoc
class _$OpenAuthoringElementEffectCopyWithImpl<$Res>
    implements $OpenAuthoringElementEffectCopyWith<$Res> {
  _$OpenAuthoringElementEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringElementEffect _self;
  final $Res Function(OpenAuthoringElementEffect) _then;

/// Create a copy of OpenAuthoringElementEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,Object? pageId = null,Object? elementIdentifier = freezed,}) {
  return _then(OpenAuthoringElementEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,elementIdentifier: freezed == elementIdentifier ? _self.elementIdentifier : elementIdentifier // ignore: cast_nullable_to_non_nullable
as SelectableIdentifier?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAuthoringElementEffect].
extension OpenAuthoringElementEffectPatterns on OpenAuthoringElementEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringElementEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringElementEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringElementEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId,  SelectableIdentifier? elementIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId,_that.elementIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId,  SelectableIdentifier? elementIdentifier)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect():
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId,_that.elementIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId bookId,  skir.ResourceId pageId,  SelectableIdentifier? elementIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringElementEffect() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.bookId,_that.pageId,_that.elementIdentifier);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringElementEffect implements OpenAuthoringElementEffect {
  const _OpenAuthoringElementEffect({required this.organizationId, required this.realmId, required this.bookId, required this.pageId, required this.elementIdentifier});
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId bookId;
@override final  skir.ResourceId pageId;
@override final  SelectableIdentifier? elementIdentifier;

/// Create a copy of OpenAuthoringElementEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringElementEffectCopyWith<_OpenAuthoringElementEffect> get copyWith => __$OpenAuthoringElementEffectCopyWithImpl<_OpenAuthoringElementEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringElementEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.elementIdentifier, elementIdentifier) || other.elementIdentifier == elementIdentifier));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,bookId,pageId,elementIdentifier);
}

@override
String toString() {
    return 'OpenAuthoringElementEffect(organizationId: $organizationId, realmId: $realmId, bookId: $bookId, pageId: $pageId, elementIdentifier: $elementIdentifier)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringElementEffectCopyWith<$Res> implements $OpenAuthoringElementEffectCopyWith<$Res> {
  factory _$OpenAuthoringElementEffectCopyWith(_OpenAuthoringElementEffect value, $Res Function(_OpenAuthoringElementEffect) _then) = __$OpenAuthoringElementEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId bookId, skir.ResourceId pageId, SelectableIdentifier? elementIdentifier
});




}
/// @nodoc
class __$OpenAuthoringElementEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringElementEffectCopyWith<$Res> {
  __$OpenAuthoringElementEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringElementEffect _self;
  final $Res Function(_OpenAuthoringElementEffect) _then;

/// Create a copy of OpenAuthoringElementEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? bookId = null,Object? pageId = null,Object? elementIdentifier = freezed,}) {
  return _then(_OpenAuthoringElementEffect(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,elementIdentifier: freezed == elementIdentifier ? _self.elementIdentifier : elementIdentifier // ignore: cast_nullable_to_non_nullable
as SelectableIdentifier?,
  ));
}


}

// dart format on
