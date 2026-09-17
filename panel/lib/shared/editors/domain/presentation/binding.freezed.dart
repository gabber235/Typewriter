// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BindingId {

 int get value;
/// Create a copy of BindingId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingIdCopyWith<BindingId> get copyWith => _$BindingIdCopyWithImpl<BindingId>(this as BindingId, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BindingId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingId&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as BindingId;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as BindingId;
  return 'BindingId(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $BindingIdCopyWith<$Res>  {
  factory $BindingIdCopyWith(BindingId value, $Res Function(BindingId) _then) = _$BindingIdCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$BindingIdCopyWithImpl<$Res>
    implements $BindingIdCopyWith<$Res> {
  _$BindingIdCopyWithImpl(this._self, this._then);

  final BindingId _self;
  final $Res Function(BindingId) _then;

/// Create a copy of BindingId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(BindingId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BindingId].
extension BindingIdPatterns on BindingId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BindingId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BindingId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BindingId value)  $default,){
final _that = this;
switch (_that) {
case _BindingId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BindingId value)?  $default,){
final _that = this;
switch (_that) {
case _BindingId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BindingId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value)  $default,) {final _that = this;
switch (_that) {
case _BindingId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value)?  $default,) {final _that = this;
switch (_that) {
case _BindingId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _BindingId implements BindingId {
  const _BindingId(this.value): assert(value >= 0, 'Binding ID must not be negative.');
  

@override final  int value;

/// Create a copy of BindingId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BindingIdCopyWith<_BindingId> get copyWith => __$BindingIdCopyWithImpl<_BindingId>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BindingId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'BindingId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$BindingIdCopyWith<$Res> implements $BindingIdCopyWith<$Res> {
  factory _$BindingIdCopyWith(_BindingId value, $Res Function(_BindingId) _then) = __$BindingIdCopyWithImpl;
@override @useResult
$Res call({
 int value
});




}
/// @nodoc
class __$BindingIdCopyWithImpl<$Res>
    implements _$BindingIdCopyWith<$Res> {
  __$BindingIdCopyWithImpl(this._self, this._then);

  final _BindingId _self;
  final $Res Function(_BindingId) _then;

/// Create a copy of BindingId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_BindingId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BindingReference {

 BindingId get bindingId; DataPath get path;
/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<BindingReference> get copyWith => _$BindingReferenceCopyWithImpl<BindingReference>(this as BindingReference, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BindingReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingReference&&(identical(other.bindingId, _this.bindingId) || other.bindingId == _this.bindingId)&&(identical(other.path, _this.path) || other.path == _this.path));
}


@override
int get hashCode {
  final _this = this as BindingReference;
  return Object.hash(runtimeType,_this.bindingId,_this.path);
}

@override
String toString() {
  final _this = this as BindingReference;
  return 'BindingReference(bindingId: ${_this.bindingId}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $BindingReferenceCopyWith<$Res>  {
  factory $BindingReferenceCopyWith(BindingReference value, $Res Function(BindingReference) _then) = _$BindingReferenceCopyWithImpl;
@useResult
$Res call({
 BindingId bindingId, DataPath path
});


$BindingIdCopyWith<$Res> get bindingId;$DataPathCopyWith<$Res> get path;

}
/// @nodoc
class _$BindingReferenceCopyWithImpl<$Res>
    implements $BindingReferenceCopyWith<$Res> {
  _$BindingReferenceCopyWithImpl(this._self, this._then);

  final BindingReference _self;
  final $Res Function(BindingReference) _then;

/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindingId = null,Object? path = null,}) {
  return _then(BindingReference(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,
  ));
}
/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}
}


/// Adds pattern-matching-related methods to [BindingReference].
extension BindingReferencePatterns on BindingReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BindingReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BindingReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BindingReference value)  $default,){
final _that = this;
switch (_that) {
case _BindingReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BindingReference value)?  $default,){
final _that = this;
switch (_that) {
case _BindingReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingId bindingId,  DataPath path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BindingReference() when $default != null:
return $default(_that.bindingId,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingId bindingId,  DataPath path)  $default,) {final _that = this;
switch (_that) {
case _BindingReference():
return $default(_that.bindingId,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingId bindingId,  DataPath path)?  $default,) {final _that = this;
switch (_that) {
case _BindingReference() when $default != null:
return $default(_that.bindingId,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _BindingReference extends BindingReference {
  const _BindingReference({required this.bindingId, this.path = DataPath.root}): super._();
  

@override final  BindingId bindingId;
@override@JsonKey() final  DataPath path;

/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BindingReferenceCopyWith<_BindingReference> get copyWith => __$BindingReferenceCopyWithImpl<_BindingReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BindingReference&&(identical(other.bindingId, bindingId) || other.bindingId == bindingId)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bindingId,path);
}

@override
String toString() {
    return 'BindingReference(bindingId: $bindingId, path: $path)';
}


}

/// @nodoc
abstract mixin class _$BindingReferenceCopyWith<$Res> implements $BindingReferenceCopyWith<$Res> {
  factory _$BindingReferenceCopyWith(_BindingReference value, $Res Function(_BindingReference) _then) = __$BindingReferenceCopyWithImpl;
@override @useResult
$Res call({
 BindingId bindingId, DataPath path
});


@override $BindingIdCopyWith<$Res> get bindingId;@override $DataPathCopyWith<$Res> get path;

}
/// @nodoc
class __$BindingReferenceCopyWithImpl<$Res>
    implements _$BindingReferenceCopyWith<$Res> {
  __$BindingReferenceCopyWithImpl(this._self, this._then);

  final _BindingReference _self;
  final $Res Function(_BindingReference) _then;

/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindingId = null,Object? path = null,}) {
  return _then(_BindingReference(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,
  ));
}

/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of BindingReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}
}

/// @nodoc
mixin _$BindingSnapshot {

 TypeExpression get type; DataValue get value; int get revision; bool get writable;
/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingSnapshotCopyWith<BindingSnapshot> get copyWith => _$BindingSnapshotCopyWithImpl<BindingSnapshot>(this as BindingSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BindingSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingSnapshot&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.writable, _this.writable) || other.writable == _this.writable));
}


@override
int get hashCode {
  final _this = this as BindingSnapshot;
  return Object.hash(runtimeType,_this.type,_this.value,_this.revision,_this.writable);
}

@override
String toString() {
  final _this = this as BindingSnapshot;
  return 'BindingSnapshot(type: ${_this.type}, value: ${_this.value}, revision: ${_this.revision}, writable: ${_this.writable})';
}


}

/// @nodoc
abstract mixin class $BindingSnapshotCopyWith<$Res>  {
  factory $BindingSnapshotCopyWith(BindingSnapshot value, $Res Function(BindingSnapshot) _then) = _$BindingSnapshotCopyWithImpl;
@useResult
$Res call({
 TypeExpression type, DataValue value, int revision, bool writable
});


$TypeExpressionCopyWith<$Res> get type;$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$BindingSnapshotCopyWithImpl<$Res>
    implements $BindingSnapshotCopyWith<$Res> {
  _$BindingSnapshotCopyWithImpl(this._self, this._then);

  final BindingSnapshot _self;
  final $Res Function(BindingSnapshot) _then;

/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(BindingSnapshot(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [BindingSnapshot].
extension BindingSnapshotPatterns on BindingSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BindingSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BindingSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BindingSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _BindingSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BindingSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _BindingSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeExpression type,  DataValue value,  int revision,  bool writable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BindingSnapshot() when $default != null:
return $default(_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeExpression type,  DataValue value,  int revision,  bool writable)  $default,) {final _that = this;
switch (_that) {
case _BindingSnapshot():
return $default(_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeExpression type,  DataValue value,  int revision,  bool writable)?  $default,) {final _that = this;
switch (_that) {
case _BindingSnapshot() when $default != null:
return $default(_that.type,_that.value,_that.revision,_that.writable);case _:
  return null;

}
}

}

/// @nodoc


class _BindingSnapshot extends BindingSnapshot {
  const _BindingSnapshot({required this.type, required this.value, required this.revision, this.writable = true}): assert(revision >= 0, 'Binding revision must not be negative.'),super._();
  

@override final  TypeExpression type;
@override final  DataValue value;
@override final  int revision;
@override@JsonKey() final  bool writable;

/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BindingSnapshotCopyWith<_BindingSnapshot> get copyWith => __$BindingSnapshotCopyWithImpl<_BindingSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BindingSnapshot&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.writable, writable) || other.writable == writable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,value,revision,writable);
}

@override
String toString() {
    return 'BindingSnapshot(type: $type, value: $value, revision: $revision, writable: $writable)';
}


}

/// @nodoc
abstract mixin class _$BindingSnapshotCopyWith<$Res> implements $BindingSnapshotCopyWith<$Res> {
  factory _$BindingSnapshotCopyWith(_BindingSnapshot value, $Res Function(_BindingSnapshot) _then) = __$BindingSnapshotCopyWithImpl;
@override @useResult
$Res call({
 TypeExpression type, DataValue value, int revision, bool writable
});


@override $TypeExpressionCopyWith<$Res> get type;@override $DataValueCopyWith<$Res> get value;

}
/// @nodoc
class __$BindingSnapshotCopyWithImpl<$Res>
    implements _$BindingSnapshotCopyWith<$Res> {
  __$BindingSnapshotCopyWithImpl(this._self, this._then);

  final _BindingSnapshot _self;
  final $Res Function(_BindingSnapshot) _then;

/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(_BindingSnapshot(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of BindingSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$BindingSourceState {

 TypeExpression get type; EditorValue get value;
/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingSourceStateCopyWith<BindingSourceState> get copyWith => _$BindingSourceStateCopyWithImpl<BindingSourceState>(this as BindingSourceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BindingSourceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingSourceState&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as BindingSourceState;
  return Object.hash(runtimeType,_this.type,_this.value);
}

@override
String toString() {
  final _this = this as BindingSourceState;
  return 'BindingSourceState(type: ${_this.type}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $BindingSourceStateCopyWith<$Res>  {
  factory $BindingSourceStateCopyWith(BindingSourceState value, $Res Function(BindingSourceState) _then) = _$BindingSourceStateCopyWithImpl;
@useResult
$Res call({
 TypeExpression type, EditorValue value
});


$TypeExpressionCopyWith<$Res> get type;$EditorValueCopyWith<$Res> get value;

}
/// @nodoc
class _$BindingSourceStateCopyWithImpl<$Res>
    implements $BindingSourceStateCopyWith<$Res> {
  _$BindingSourceStateCopyWithImpl(this._self, this._then);

  final BindingSourceState _self;
  final $Res Function(BindingSourceState) _then;

/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,}) {
  return _then(BindingSourceState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EditorValue,
  ));
}
/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorValueCopyWith<$Res> get value {
  
  return $EditorValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [BindingSourceState].
extension BindingSourceStatePatterns on BindingSourceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BindingSourceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BindingSourceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BindingSourceState value)  $default,){
final _that = this;
switch (_that) {
case _BindingSourceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BindingSourceState value)?  $default,){
final _that = this;
switch (_that) {
case _BindingSourceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeExpression type,  EditorValue value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BindingSourceState() when $default != null:
return $default(_that.type,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeExpression type,  EditorValue value)  $default,) {final _that = this;
switch (_that) {
case _BindingSourceState():
return $default(_that.type,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeExpression type,  EditorValue value)?  $default,) {final _that = this;
switch (_that) {
case _BindingSourceState() when $default != null:
return $default(_that.type,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _BindingSourceState implements BindingSourceState {
  const _BindingSourceState({required this.type, required this.value});
  

@override final  TypeExpression type;
@override final  EditorValue value;

/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BindingSourceStateCopyWith<_BindingSourceState> get copyWith => __$BindingSourceStateCopyWithImpl<_BindingSourceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BindingSourceState&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,value);
}

@override
String toString() {
    return 'BindingSourceState(type: $type, value: $value)';
}


}

/// @nodoc
abstract mixin class _$BindingSourceStateCopyWith<$Res> implements $BindingSourceStateCopyWith<$Res> {
  factory _$BindingSourceStateCopyWith(_BindingSourceState value, $Res Function(_BindingSourceState) _then) = __$BindingSourceStateCopyWithImpl;
@override @useResult
$Res call({
 TypeExpression type, EditorValue value
});


@override $TypeExpressionCopyWith<$Res> get type;@override $EditorValueCopyWith<$Res> get value;

}
/// @nodoc
class __$BindingSourceStateCopyWithImpl<$Res>
    implements _$BindingSourceStateCopyWith<$Res> {
  __$BindingSourceStateCopyWithImpl(this._self, this._then);

  final _BindingSourceState _self;
  final $Res Function(_BindingSourceState) _then;

/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,}) {
  return _then(_BindingSourceState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EditorValue,
  ));
}

/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of BindingSourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorValueCopyWith<$Res> get value {
  
  return $EditorValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$InspectedBinding {

 BindingReference get reference; TypeExpression get type; EditorValue get value; int get revision; bool get writable;
/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectedBindingCopyWith<InspectedBinding> get copyWith => _$InspectedBindingCopyWithImpl<InspectedBinding>(this as InspectedBinding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InspectedBinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectedBinding&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.writable, _this.writable) || other.writable == _this.writable));
}


@override
int get hashCode {
  final _this = this as InspectedBinding;
  return Object.hash(runtimeType,_this.reference,_this.type,_this.value,_this.revision,_this.writable);
}

@override
String toString() {
  final _this = this as InspectedBinding;
  return 'InspectedBinding(reference: ${_this.reference}, type: ${_this.type}, value: ${_this.value}, revision: ${_this.revision}, writable: ${_this.writable})';
}


}

/// @nodoc
abstract mixin class $InspectedBindingCopyWith<$Res>  {
  factory $InspectedBindingCopyWith(InspectedBinding value, $Res Function(InspectedBinding) _then) = _$InspectedBindingCopyWithImpl;
@useResult
$Res call({
 BindingReference reference, TypeExpression type, EditorValue value, int revision, bool writable
});


$BindingReferenceCopyWith<$Res> get reference;$TypeExpressionCopyWith<$Res> get type;$EditorValueCopyWith<$Res> get value;

}
/// @nodoc
class _$InspectedBindingCopyWithImpl<$Res>
    implements $InspectedBindingCopyWith<$Res> {
  _$InspectedBindingCopyWithImpl(this._self, this._then);

  final InspectedBinding _self;
  final $Res Function(InspectedBinding) _then;

/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(InspectedBinding(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BindingReference,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EditorValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get reference {
  
  return $BindingReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorValueCopyWith<$Res> get value {
  
  return $EditorValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [InspectedBinding].
extension InspectedBindingPatterns on InspectedBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectedBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectedBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectedBinding value)  $default,){
final _that = this;
switch (_that) {
case _InspectedBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectedBinding value)?  $default,){
final _that = this;
switch (_that) {
case _InspectedBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingReference reference,  TypeExpression type,  EditorValue value,  int revision,  bool writable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectedBinding() when $default != null:
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingReference reference,  TypeExpression type,  EditorValue value,  int revision,  bool writable)  $default,) {final _that = this;
switch (_that) {
case _InspectedBinding():
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingReference reference,  TypeExpression type,  EditorValue value,  int revision,  bool writable)?  $default,) {final _that = this;
switch (_that) {
case _InspectedBinding() when $default != null:
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
  return null;

}
}

}

/// @nodoc


class _InspectedBinding implements InspectedBinding {
  const _InspectedBinding({required this.reference, required this.type, required this.value, required this.revision, required this.writable});
  

@override final  BindingReference reference;
@override final  TypeExpression type;
@override final  EditorValue value;
@override final  int revision;
@override final  bool writable;

/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectedBindingCopyWith<_InspectedBinding> get copyWith => __$InspectedBindingCopyWithImpl<_InspectedBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectedBinding&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.writable, writable) || other.writable == writable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference,type,value,revision,writable);
}

@override
String toString() {
    return 'InspectedBinding(reference: $reference, type: $type, value: $value, revision: $revision, writable: $writable)';
}


}

/// @nodoc
abstract mixin class _$InspectedBindingCopyWith<$Res> implements $InspectedBindingCopyWith<$Res> {
  factory _$InspectedBindingCopyWith(_InspectedBinding value, $Res Function(_InspectedBinding) _then) = __$InspectedBindingCopyWithImpl;
@override @useResult
$Res call({
 BindingReference reference, TypeExpression type, EditorValue value, int revision, bool writable
});


@override $BindingReferenceCopyWith<$Res> get reference;@override $TypeExpressionCopyWith<$Res> get type;@override $EditorValueCopyWith<$Res> get value;

}
/// @nodoc
class __$InspectedBindingCopyWithImpl<$Res>
    implements _$InspectedBindingCopyWith<$Res> {
  __$InspectedBindingCopyWithImpl(this._self, this._then);

  final _InspectedBinding _self;
  final $Res Function(_InspectedBinding) _then;

/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(_InspectedBinding(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BindingReference,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EditorValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get reference {
  
  return $BindingReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of InspectedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorValueCopyWith<$Res> get value {
  
  return $EditorValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$ResolvedBinding {

 BindingReference get reference; TypeExpression get type; DataValue get value; int get revision; bool get writable;
/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedBindingCopyWith<ResolvedBinding> get copyWith => _$ResolvedBindingCopyWithImpl<ResolvedBinding>(this as ResolvedBinding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedBinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedBinding&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.writable, _this.writable) || other.writable == _this.writable));
}


@override
int get hashCode {
  final _this = this as ResolvedBinding;
  return Object.hash(runtimeType,_this.reference,_this.type,_this.value,_this.revision,_this.writable);
}

@override
String toString() {
  final _this = this as ResolvedBinding;
  return 'ResolvedBinding(reference: ${_this.reference}, type: ${_this.type}, value: ${_this.value}, revision: ${_this.revision}, writable: ${_this.writable})';
}


}

/// @nodoc
abstract mixin class $ResolvedBindingCopyWith<$Res>  {
  factory $ResolvedBindingCopyWith(ResolvedBinding value, $Res Function(ResolvedBinding) _then) = _$ResolvedBindingCopyWithImpl;
@useResult
$Res call({
 BindingReference reference, TypeExpression type, DataValue value, int revision, bool writable
});


$BindingReferenceCopyWith<$Res> get reference;$TypeExpressionCopyWith<$Res> get type;$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$ResolvedBindingCopyWithImpl<$Res>
    implements $ResolvedBindingCopyWith<$Res> {
  _$ResolvedBindingCopyWithImpl(this._self, this._then);

  final ResolvedBinding _self;
  final $Res Function(ResolvedBinding) _then;

/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(ResolvedBinding(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BindingReference,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get reference {
  
  return $BindingReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedBinding].
extension ResolvedBindingPatterns on ResolvedBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedBinding value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedBinding value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingReference reference,  TypeExpression type,  DataValue value,  int revision,  bool writable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedBinding() when $default != null:
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingReference reference,  TypeExpression type,  DataValue value,  int revision,  bool writable)  $default,) {final _that = this;
switch (_that) {
case _ResolvedBinding():
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingReference reference,  TypeExpression type,  DataValue value,  int revision,  bool writable)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedBinding() when $default != null:
return $default(_that.reference,_that.type,_that.value,_that.revision,_that.writable);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedBinding implements ResolvedBinding {
  const _ResolvedBinding({required this.reference, required this.type, required this.value, required this.revision, required this.writable});
  

@override final  BindingReference reference;
@override final  TypeExpression type;
@override final  DataValue value;
@override final  int revision;
@override final  bool writable;

/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedBindingCopyWith<_ResolvedBinding> get copyWith => __$ResolvedBindingCopyWithImpl<_ResolvedBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedBinding&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.writable, writable) || other.writable == writable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference,type,value,revision,writable);
}

@override
String toString() {
    return 'ResolvedBinding(reference: $reference, type: $type, value: $value, revision: $revision, writable: $writable)';
}


}

/// @nodoc
abstract mixin class _$ResolvedBindingCopyWith<$Res> implements $ResolvedBindingCopyWith<$Res> {
  factory _$ResolvedBindingCopyWith(_ResolvedBinding value, $Res Function(_ResolvedBinding) _then) = __$ResolvedBindingCopyWithImpl;
@override @useResult
$Res call({
 BindingReference reference, TypeExpression type, DataValue value, int revision, bool writable
});


@override $BindingReferenceCopyWith<$Res> get reference;@override $TypeExpressionCopyWith<$Res> get type;@override $DataValueCopyWith<$Res> get value;

}
/// @nodoc
class __$ResolvedBindingCopyWithImpl<$Res>
    implements _$ResolvedBindingCopyWith<$Res> {
  __$ResolvedBindingCopyWithImpl(this._self, this._then);

  final _ResolvedBinding _self;
  final $Res Function(_ResolvedBinding) _then;

/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? type = null,Object? value = null,Object? revision = null,Object? writable = null,}) {
  return _then(_ResolvedBinding(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BindingReference,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get reference {
  
  return $BindingReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of ResolvedBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$BindingEnvironment {

 Map<BindingId, BindingSource> get bindings;
/// Create a copy of BindingEnvironment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingEnvironmentCopyWith<BindingEnvironment> get copyWith => _$BindingEnvironmentCopyWithImpl<BindingEnvironment>(this as BindingEnvironment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BindingEnvironment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingEnvironment&&const DeepCollectionEquality().equals(other.bindings, _this.bindings));
}


@override
int get hashCode {
  final _this = this as BindingEnvironment;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bindings));
}

@override
String toString() {
  final _this = this as BindingEnvironment;
  return 'BindingEnvironment(bindings: ${_this.bindings})';
}


}

/// @nodoc
abstract mixin class $BindingEnvironmentCopyWith<$Res>  {
  factory $BindingEnvironmentCopyWith(BindingEnvironment value, $Res Function(BindingEnvironment) _then) = _$BindingEnvironmentCopyWithImpl;
@useResult
$Res call({
 Map<BindingId, BindingSource> bindings
});




}
/// @nodoc
class _$BindingEnvironmentCopyWithImpl<$Res>
    implements $BindingEnvironmentCopyWith<$Res> {
  _$BindingEnvironmentCopyWithImpl(this._self, this._then);

  final BindingEnvironment _self;
  final $Res Function(BindingEnvironment) _then;

/// Create a copy of BindingEnvironment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,}) {
  return _then(BindingEnvironment(
null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingSource>,
  ));
}

}


/// Adds pattern-matching-related methods to [BindingEnvironment].
extension BindingEnvironmentPatterns on BindingEnvironment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BindingEnvironment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BindingEnvironment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BindingEnvironment value)  $default,){
final _that = this;
switch (_that) {
case _BindingEnvironment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BindingEnvironment value)?  $default,){
final _that = this;
switch (_that) {
case _BindingEnvironment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<BindingId, BindingSource> bindings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BindingEnvironment() when $default != null:
return $default(_that.bindings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<BindingId, BindingSource> bindings)  $default,) {final _that = this;
switch (_that) {
case _BindingEnvironment():
return $default(_that.bindings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<BindingId, BindingSource> bindings)?  $default,) {final _that = this;
switch (_that) {
case _BindingEnvironment() when $default != null:
return $default(_that.bindings);case _:
  return null;

}
}

}

/// @nodoc


class _BindingEnvironment extends BindingEnvironment {
  const _BindingEnvironment( Map<BindingId, BindingSource> bindings): _bindings = bindings,super._();
  

 final  Map<BindingId, BindingSource> _bindings;
@override Map<BindingId, BindingSource> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}


/// Create a copy of BindingEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BindingEnvironmentCopyWith<_BindingEnvironment> get copyWith => __$BindingEnvironmentCopyWithImpl<_BindingEnvironment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BindingEnvironment&&const DeepCollectionEquality().equals(other.bindings, _bindings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bindings));
}

@override
String toString() {
    return 'BindingEnvironment(bindings: $bindings)';
}


}

/// @nodoc
abstract mixin class _$BindingEnvironmentCopyWith<$Res> implements $BindingEnvironmentCopyWith<$Res> {
  factory _$BindingEnvironmentCopyWith(_BindingEnvironment value, $Res Function(_BindingEnvironment) _then) = __$BindingEnvironmentCopyWithImpl;
@override @useResult
$Res call({
 Map<BindingId, BindingSource> bindings
});




}
/// @nodoc
class __$BindingEnvironmentCopyWithImpl<$Res>
    implements _$BindingEnvironmentCopyWith<$Res> {
  __$BindingEnvironmentCopyWithImpl(this._self, this._then);

  final _BindingEnvironment _self;
  final $Res Function(_BindingEnvironment) _then;

/// Create a copy of BindingEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,}) {
  return _then(_BindingEnvironment(
null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingSource>,
  ));
}


}

// dart format on
