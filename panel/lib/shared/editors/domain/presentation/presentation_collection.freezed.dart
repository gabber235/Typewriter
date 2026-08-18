// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationCollectionSourceId {

 String get value;
/// Create a copy of PresentationCollectionSourceId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionSourceIdCopyWith<PresentationCollectionSourceId> get copyWith => _$PresentationCollectionSourceIdCopyWithImpl<PresentationCollectionSourceId>(this as PresentationCollectionSourceId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionSourceId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class $PresentationCollectionSourceIdCopyWith<$Res>  {
  factory $PresentationCollectionSourceIdCopyWith(PresentationCollectionSourceId value, $Res Function(PresentationCollectionSourceId) _then) = _$PresentationCollectionSourceIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$PresentationCollectionSourceIdCopyWithImpl<$Res>
    implements $PresentationCollectionSourceIdCopyWith<$Res> {
  _$PresentationCollectionSourceIdCopyWithImpl(this._self, this._then);

  final PresentationCollectionSourceId _self;
  final $Res Function(PresentationCollectionSourceId) _then;

/// Create a copy of PresentationCollectionSourceId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationCollectionSourceId].
extension PresentationCollectionSourceIdPatterns on PresentationCollectionSourceId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionSourceId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionSourceId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionSourceId value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSourceId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionSourceId value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSourceId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionSourceId() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSourceId():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSourceId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionSourceId extends PresentationCollectionSourceId {
  const _PresentationCollectionSourceId(this.value): assert(value != "", 'Collection source ID must not be empty.'),super._();


@override final  String value;

/// Create a copy of PresentationCollectionSourceId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionSourceIdCopyWith<_PresentationCollectionSourceId> get copyWith => __$PresentationCollectionSourceIdCopyWithImpl<_PresentationCollectionSourceId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionSourceId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class _$PresentationCollectionSourceIdCopyWith<$Res> implements $PresentationCollectionSourceIdCopyWith<$Res> {
  factory _$PresentationCollectionSourceIdCopyWith(_PresentationCollectionSourceId value, $Res Function(_PresentationCollectionSourceId) _then) = __$PresentationCollectionSourceIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$PresentationCollectionSourceIdCopyWithImpl<$Res>
    implements _$PresentationCollectionSourceIdCopyWith<$Res> {
  __$PresentationCollectionSourceIdCopyWithImpl(this._self, this._then);

  final _PresentationCollectionSourceId _self;
  final $Res Function(_PresentationCollectionSourceId) _then;

/// Create a copy of PresentationCollectionSourceId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_PresentationCollectionSourceId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PresentationCollectionRelationId {

 String get value;
/// Create a copy of PresentationCollectionRelationId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionRelationIdCopyWith<PresentationCollectionRelationId> get copyWith => _$PresentationCollectionRelationIdCopyWithImpl<PresentationCollectionRelationId>(this as PresentationCollectionRelationId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionRelationId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class $PresentationCollectionRelationIdCopyWith<$Res>  {
  factory $PresentationCollectionRelationIdCopyWith(PresentationCollectionRelationId value, $Res Function(PresentationCollectionRelationId) _then) = _$PresentationCollectionRelationIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$PresentationCollectionRelationIdCopyWithImpl<$Res>
    implements $PresentationCollectionRelationIdCopyWith<$Res> {
  _$PresentationCollectionRelationIdCopyWithImpl(this._self, this._then);

  final PresentationCollectionRelationId _self;
  final $Res Function(PresentationCollectionRelationId) _then;

/// Create a copy of PresentationCollectionRelationId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationCollectionRelationId].
extension PresentationCollectionRelationIdPatterns on PresentationCollectionRelationId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionRelationId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionRelationId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionRelationId value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRelationId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionRelationId value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRelationId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionRelationId() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRelationId():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRelationId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionRelationId extends PresentationCollectionRelationId {
  const _PresentationCollectionRelationId(this.value): assert(value != "", 'Collection relation ID must not be empty.'),super._();


@override final  String value;

/// Create a copy of PresentationCollectionRelationId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionRelationIdCopyWith<_PresentationCollectionRelationId> get copyWith => __$PresentationCollectionRelationIdCopyWithImpl<_PresentationCollectionRelationId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionRelationId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);



}

/// @nodoc
abstract mixin class _$PresentationCollectionRelationIdCopyWith<$Res> implements $PresentationCollectionRelationIdCopyWith<$Res> {
  factory _$PresentationCollectionRelationIdCopyWith(_PresentationCollectionRelationId value, $Res Function(_PresentationCollectionRelationId) _then) = __$PresentationCollectionRelationIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$PresentationCollectionRelationIdCopyWithImpl<$Res>
    implements _$PresentationCollectionRelationIdCopyWith<$Res> {
  __$PresentationCollectionRelationIdCopyWithImpl(this._self, this._then);

  final _PresentationCollectionRelationId _self;
  final $Res Function(_PresentationCollectionRelationId) _then;

/// Create a copy of PresentationCollectionRelationId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_PresentationCollectionRelationId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PresentationCollectionSchema {

 TypeExpression get rowType; TypeExpression get keyType; BindingId get rowBindingId; TypedExpression get key; List<PresentationCollectionRelation> get relations;
/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionSchemaCopyWith<PresentationCollectionSchema> get copyWith => _$PresentationCollectionSchemaCopyWithImpl<PresentationCollectionSchema>(this as PresentationCollectionSchema, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionSchema&&(identical(other.rowType, rowType) || other.rowType == rowType)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.rowBindingId, rowBindingId) || other.rowBindingId == rowBindingId)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.relations, relations));
}


@override
int get hashCode => Object.hash(runtimeType,rowType,keyType,rowBindingId,key,const DeepCollectionEquality().hash(relations));

@override
String toString() {
  return 'PresentationCollectionSchema(rowType: $rowType, keyType: $keyType, rowBindingId: $rowBindingId, key: $key, relations: $relations)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionSchemaCopyWith<$Res>  {
  factory $PresentationCollectionSchemaCopyWith(PresentationCollectionSchema value, $Res Function(PresentationCollectionSchema) _then) = _$PresentationCollectionSchemaCopyWithImpl;
@useResult
$Res call({
 TypeExpression rowType, TypeExpression keyType, BindingId rowBindingId, TypedExpression key, List<PresentationCollectionRelation> relations
});


$TypeExpressionCopyWith<$Res> get rowType;$TypeExpressionCopyWith<$Res> get keyType;$BindingIdCopyWith<$Res> get rowBindingId;$TypedExpressionCopyWith<$Res> get key;

}
/// @nodoc
class _$PresentationCollectionSchemaCopyWithImpl<$Res>
    implements $PresentationCollectionSchemaCopyWith<$Res> {
  _$PresentationCollectionSchemaCopyWithImpl(this._self, this._then);

  final PresentationCollectionSchema _self;
  final $Res Function(PresentationCollectionSchema) _then;

/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowType = null,Object? keyType = null,Object? rowBindingId = null,Object? key = null,Object? relations = null,}) {
  return _then(_self.copyWith(
rowType: null == rowType ? _self.rowType : rowType // ignore: cast_nullable_to_non_nullable
as TypeExpression,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as TypeExpression,rowBindingId: null == rowBindingId ? _self.rowBindingId : rowBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,relations: null == relations ? _self.relations : relations // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRelation>,
  ));
}
/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get rowType {

  return $TypeExpressionCopyWith<$Res>(_self.rowType, (value) {
    return _then(_self.copyWith(rowType: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get keyType {

  return $TypeExpressionCopyWith<$Res>(_self.keyType, (value) {
    return _then(_self.copyWith(keyType: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get rowBindingId {

  return $BindingIdCopyWith<$Res>(_self.rowBindingId, (value) {
    return _then(_self.copyWith(rowBindingId: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {

  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationCollectionSchema].
extension PresentationCollectionSchemaPatterns on PresentationCollectionSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionSchema value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionSchema value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeExpression rowType,  TypeExpression keyType,  BindingId rowBindingId,  TypedExpression key,  List<PresentationCollectionRelation> relations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionSchema() when $default != null:
return $default(_that.rowType,_that.keyType,_that.rowBindingId,_that.key,_that.relations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeExpression rowType,  TypeExpression keyType,  BindingId rowBindingId,  TypedExpression key,  List<PresentationCollectionRelation> relations)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSchema():
return $default(_that.rowType,_that.keyType,_that.rowBindingId,_that.key,_that.relations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeExpression rowType,  TypeExpression keyType,  BindingId rowBindingId,  TypedExpression key,  List<PresentationCollectionRelation> relations)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSchema() when $default != null:
return $default(_that.rowType,_that.keyType,_that.rowBindingId,_that.key,_that.relations);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionSchema implements PresentationCollectionSchema {
  const _PresentationCollectionSchema({required this.rowType, required this.keyType, required this.rowBindingId, required this.key, final  List<PresentationCollectionRelation> relations = const <PresentationCollectionRelation>[]}): _relations = relations;


@override final  TypeExpression rowType;
@override final  TypeExpression keyType;
@override final  BindingId rowBindingId;
@override final  TypedExpression key;
 final  List<PresentationCollectionRelation> _relations;
@override@JsonKey() List<PresentationCollectionRelation> get relations {
  if (_relations is EqualUnmodifiableListView) return _relations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relations);
}


/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionSchemaCopyWith<_PresentationCollectionSchema> get copyWith => __$PresentationCollectionSchemaCopyWithImpl<_PresentationCollectionSchema>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionSchema&&(identical(other.rowType, rowType) || other.rowType == rowType)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.rowBindingId, rowBindingId) || other.rowBindingId == rowBindingId)&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other._relations, _relations));
}


@override
int get hashCode => Object.hash(runtimeType,rowType,keyType,rowBindingId,key,const DeepCollectionEquality().hash(_relations));

@override
String toString() {
  return 'PresentationCollectionSchema(rowType: $rowType, keyType: $keyType, rowBindingId: $rowBindingId, key: $key, relations: $relations)';
}


}

/// @nodoc
abstract mixin class _$PresentationCollectionSchemaCopyWith<$Res> implements $PresentationCollectionSchemaCopyWith<$Res> {
  factory _$PresentationCollectionSchemaCopyWith(_PresentationCollectionSchema value, $Res Function(_PresentationCollectionSchema) _then) = __$PresentationCollectionSchemaCopyWithImpl;
@override @useResult
$Res call({
 TypeExpression rowType, TypeExpression keyType, BindingId rowBindingId, TypedExpression key, List<PresentationCollectionRelation> relations
});


@override $TypeExpressionCopyWith<$Res> get rowType;@override $TypeExpressionCopyWith<$Res> get keyType;@override $BindingIdCopyWith<$Res> get rowBindingId;@override $TypedExpressionCopyWith<$Res> get key;

}
/// @nodoc
class __$PresentationCollectionSchemaCopyWithImpl<$Res>
    implements _$PresentationCollectionSchemaCopyWith<$Res> {
  __$PresentationCollectionSchemaCopyWithImpl(this._self, this._then);

  final _PresentationCollectionSchema _self;
  final $Res Function(_PresentationCollectionSchema) _then;

/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowType = null,Object? keyType = null,Object? rowBindingId = null,Object? key = null,Object? relations = null,}) {
  return _then(_PresentationCollectionSchema(
rowType: null == rowType ? _self.rowType : rowType // ignore: cast_nullable_to_non_nullable
as TypeExpression,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as TypeExpression,rowBindingId: null == rowBindingId ? _self.rowBindingId : rowBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,relations: null == relations ? _self._relations : relations // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRelation>,
  ));
}

/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get rowType {

  return $TypeExpressionCopyWith<$Res>(_self.rowType, (value) {
    return _then(_self.copyWith(rowType: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get keyType {

  return $TypeExpressionCopyWith<$Res>(_self.keyType, (value) {
    return _then(_self.copyWith(keyType: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get rowBindingId {

  return $BindingIdCopyWith<$Res>(_self.rowBindingId, (value) {
    return _then(_self.copyWith(rowBindingId: value));
  });
}/// Create a copy of PresentationCollectionSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {

  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}

/// @nodoc
mixin _$PresentationCollectionRelation {

 PresentationCollectionRelationId get id; TypedExpression get targets;
/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionRelationCopyWith<PresentationCollectionRelation> get copyWith => _$PresentationCollectionRelationCopyWithImpl<PresentationCollectionRelation>(this as PresentationCollectionRelation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionRelation&&(identical(other.id, id) || other.id == id)&&(identical(other.targets, targets) || other.targets == targets));
}


@override
int get hashCode => Object.hash(runtimeType,id,targets);

@override
String toString() {
  return 'PresentationCollectionRelation(id: $id, targets: $targets)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionRelationCopyWith<$Res>  {
  factory $PresentationCollectionRelationCopyWith(PresentationCollectionRelation value, $Res Function(PresentationCollectionRelation) _then) = _$PresentationCollectionRelationCopyWithImpl;
@useResult
$Res call({
 PresentationCollectionRelationId id, TypedExpression targets
});


$PresentationCollectionRelationIdCopyWith<$Res> get id;$TypedExpressionCopyWith<$Res> get targets;

}
/// @nodoc
class _$PresentationCollectionRelationCopyWithImpl<$Res>
    implements $PresentationCollectionRelationCopyWith<$Res> {
  _$PresentationCollectionRelationCopyWithImpl(this._self, this._then);

  final PresentationCollectionRelation _self;
  final $Res Function(PresentationCollectionRelation) _then;

/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targets = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationCollectionRelationId,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}
/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationCollectionRelationIdCopyWith<$Res> get id {

  return $PresentationCollectionRelationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get targets {

  return $TypedExpressionCopyWith<$Res>(_self.targets, (value) {
    return _then(_self.copyWith(targets: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationCollectionRelation].
extension PresentationCollectionRelationPatterns on PresentationCollectionRelation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionRelation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionRelation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionRelation value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRelation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionRelation value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRelation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationCollectionRelationId id,  TypedExpression targets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionRelation() when $default != null:
return $default(_that.id,_that.targets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationCollectionRelationId id,  TypedExpression targets)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRelation():
return $default(_that.id,_that.targets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationCollectionRelationId id,  TypedExpression targets)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRelation() when $default != null:
return $default(_that.id,_that.targets);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionRelation implements PresentationCollectionRelation {
  const _PresentationCollectionRelation({required this.id, required this.targets});


@override final  PresentationCollectionRelationId id;
@override final  TypedExpression targets;

/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionRelationCopyWith<_PresentationCollectionRelation> get copyWith => __$PresentationCollectionRelationCopyWithImpl<_PresentationCollectionRelation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionRelation&&(identical(other.id, id) || other.id == id)&&(identical(other.targets, targets) || other.targets == targets));
}


@override
int get hashCode => Object.hash(runtimeType,id,targets);

@override
String toString() {
  return 'PresentationCollectionRelation(id: $id, targets: $targets)';
}


}

/// @nodoc
abstract mixin class _$PresentationCollectionRelationCopyWith<$Res> implements $PresentationCollectionRelationCopyWith<$Res> {
  factory _$PresentationCollectionRelationCopyWith(_PresentationCollectionRelation value, $Res Function(_PresentationCollectionRelation) _then) = __$PresentationCollectionRelationCopyWithImpl;
@override @useResult
$Res call({
 PresentationCollectionRelationId id, TypedExpression targets
});


@override $PresentationCollectionRelationIdCopyWith<$Res> get id;@override $TypedExpressionCopyWith<$Res> get targets;

}
/// @nodoc
class __$PresentationCollectionRelationCopyWithImpl<$Res>
    implements _$PresentationCollectionRelationCopyWith<$Res> {
  __$PresentationCollectionRelationCopyWithImpl(this._self, this._then);

  final _PresentationCollectionRelation _self;
  final $Res Function(_PresentationCollectionRelation) _then;

/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targets = null,}) {
  return _then(_PresentationCollectionRelation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationCollectionRelationId,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationCollectionRelationIdCopyWith<$Res> get id {

  return $PresentationCollectionRelationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationCollectionRelation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get targets {

  return $TypedExpressionCopyWith<$Res>(_self.targets, (value) {
    return _then(_self.copyWith(targets: value));
  });
}
}

/// @nodoc
mixin _$PresentationCollectionQuery {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionQuery);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresentationCollectionQuery()';
}


}

/// @nodoc
class $PresentationCollectionQueryCopyWith<$Res>  {
$PresentationCollectionQueryCopyWith(PresentationCollectionQuery _, $Res Function(PresentationCollectionQuery) __);
}


/// Adds pattern-matching-related methods to [PresentationCollectionQuery].
extension PresentationCollectionQueryPatterns on PresentationCollectionQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PresentationCollectionAll value)?  all,TResult Function( PresentationCollectionKeys value)?  keys,TResult Function( PresentationCollectionSearch value)?  search,TResult Function( PresentationCollectionGraph value)?  graph,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PresentationCollectionAll() when all != null:
return all(_that);case PresentationCollectionKeys() when keys != null:
return keys(_that);case PresentationCollectionSearch() when search != null:
return search(_that);case PresentationCollectionGraph() when graph != null:
return graph(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PresentationCollectionAll value)  all,required TResult Function( PresentationCollectionKeys value)  keys,required TResult Function( PresentationCollectionSearch value)  search,required TResult Function( PresentationCollectionGraph value)  graph,}){
final _that = this;
switch (_that) {
case PresentationCollectionAll():
return all(_that);case PresentationCollectionKeys():
return keys(_that);case PresentationCollectionSearch():
return search(_that);case PresentationCollectionGraph():
return graph(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PresentationCollectionAll value)?  all,TResult? Function( PresentationCollectionKeys value)?  keys,TResult? Function( PresentationCollectionSearch value)?  search,TResult? Function( PresentationCollectionGraph value)?  graph,}){
final _that = this;
switch (_that) {
case PresentationCollectionAll() when all != null:
return all(_that);case PresentationCollectionKeys() when keys != null:
return keys(_that);case PresentationCollectionSearch() when search != null:
return search(_that);case PresentationCollectionGraph() when graph != null:
return graph(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  all,TResult Function( List<DataValue> keys)?  keys,TResult Function( SearchQueryContext query)?  search,TResult Function( List<DataValue> roots,  PresentationCollectionRelationId relation,  CollectionGraphDirection direction,  int? maximumDepth)?  graph,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PresentationCollectionAll() when all != null:
return all();case PresentationCollectionKeys() when keys != null:
return keys(_that.keys);case PresentationCollectionSearch() when search != null:
return search(_that.query);case PresentationCollectionGraph() when graph != null:
return graph(_that.roots,_that.relation,_that.direction,_that.maximumDepth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  all,required TResult Function( List<DataValue> keys)  keys,required TResult Function( SearchQueryContext query)  search,required TResult Function( List<DataValue> roots,  PresentationCollectionRelationId relation,  CollectionGraphDirection direction,  int? maximumDepth)  graph,}) {final _that = this;
switch (_that) {
case PresentationCollectionAll():
return all();case PresentationCollectionKeys():
return keys(_that.keys);case PresentationCollectionSearch():
return search(_that.query);case PresentationCollectionGraph():
return graph(_that.roots,_that.relation,_that.direction,_that.maximumDepth);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  all,TResult? Function( List<DataValue> keys)?  keys,TResult? Function( SearchQueryContext query)?  search,TResult? Function( List<DataValue> roots,  PresentationCollectionRelationId relation,  CollectionGraphDirection direction,  int? maximumDepth)?  graph,}) {final _that = this;
switch (_that) {
case PresentationCollectionAll() when all != null:
return all();case PresentationCollectionKeys() when keys != null:
return keys(_that.keys);case PresentationCollectionSearch() when search != null:
return search(_that.query);case PresentationCollectionGraph() when graph != null:
return graph(_that.roots,_that.relation,_that.direction,_that.maximumDepth);case _:
  return null;

}
}

}

/// @nodoc


class PresentationCollectionAll implements PresentationCollectionQuery {
  const PresentationCollectionAll();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresentationCollectionQuery.all()';
}


}




/// @nodoc


class PresentationCollectionKeys implements PresentationCollectionQuery {
  const PresentationCollectionKeys(final  List<DataValue> keys): _keys = keys;


 final  List<DataValue> _keys;
 List<DataValue> get keys {
  if (_keys is EqualUnmodifiableListView) return _keys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keys);
}


/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionKeysCopyWith<PresentationCollectionKeys> get copyWith => _$PresentationCollectionKeysCopyWithImpl<PresentationCollectionKeys>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionKeys&&const DeepCollectionEquality().equals(other._keys, _keys));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_keys));

@override
String toString() {
  return 'PresentationCollectionQuery.keys(keys: $keys)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionKeysCopyWith<$Res> implements $PresentationCollectionQueryCopyWith<$Res> {
  factory $PresentationCollectionKeysCopyWith(PresentationCollectionKeys value, $Res Function(PresentationCollectionKeys) _then) = _$PresentationCollectionKeysCopyWithImpl;
@useResult
$Res call({
 List<DataValue> keys
});




}
/// @nodoc
class _$PresentationCollectionKeysCopyWithImpl<$Res>
    implements $PresentationCollectionKeysCopyWith<$Res> {
  _$PresentationCollectionKeysCopyWithImpl(this._self, this._then);

  final PresentationCollectionKeys _self;
  final $Res Function(PresentationCollectionKeys) _then;

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? keys = null,}) {
  return _then(PresentationCollectionKeys(
null == keys ? _self._keys : keys // ignore: cast_nullable_to_non_nullable
as List<DataValue>,
  ));
}


}

/// @nodoc


class PresentationCollectionSearch implements PresentationCollectionQuery {
  const PresentationCollectionSearch(this.query);


 final  SearchQueryContext query;

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionSearchCopyWith<PresentationCollectionSearch> get copyWith => _$PresentationCollectionSearchCopyWithImpl<PresentationCollectionSearch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionSearch&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'PresentationCollectionQuery.search(query: $query)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionSearchCopyWith<$Res> implements $PresentationCollectionQueryCopyWith<$Res> {
  factory $PresentationCollectionSearchCopyWith(PresentationCollectionSearch value, $Res Function(PresentationCollectionSearch) _then) = _$PresentationCollectionSearchCopyWithImpl;
@useResult
$Res call({
 SearchQueryContext query
});


$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$PresentationCollectionSearchCopyWithImpl<$Res>
    implements $PresentationCollectionSearchCopyWith<$Res> {
  _$PresentationCollectionSearchCopyWithImpl(this._self, this._then);

  final PresentationCollectionSearch _self;
  final $Res Function(PresentationCollectionSearch) _then;

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(PresentationCollectionSearch(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {

  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc


class PresentationCollectionGraph implements PresentationCollectionQuery {
  const PresentationCollectionGraph({required final  List<DataValue> roots, required this.relation, required this.direction, this.maximumDepth}): assert(maximumDepth == null || maximumDepth > 0, 'Maximum depth must be positive.'),_roots = roots;


 final  List<DataValue> _roots;
 List<DataValue> get roots {
  if (_roots is EqualUnmodifiableListView) return _roots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roots);
}

 final  PresentationCollectionRelationId relation;
 final  CollectionGraphDirection direction;
 final  int? maximumDepth;

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionGraphCopyWith<PresentationCollectionGraph> get copyWith => _$PresentationCollectionGraphCopyWithImpl<PresentationCollectionGraph>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionGraph&&const DeepCollectionEquality().equals(other._roots, _roots)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.maximumDepth, maximumDepth) || other.maximumDepth == maximumDepth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_roots),relation,direction,maximumDepth);

@override
String toString() {
  return 'PresentationCollectionQuery.graph(roots: $roots, relation: $relation, direction: $direction, maximumDepth: $maximumDepth)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionGraphCopyWith<$Res> implements $PresentationCollectionQueryCopyWith<$Res> {
  factory $PresentationCollectionGraphCopyWith(PresentationCollectionGraph value, $Res Function(PresentationCollectionGraph) _then) = _$PresentationCollectionGraphCopyWithImpl;
@useResult
$Res call({
 List<DataValue> roots, PresentationCollectionRelationId relation, CollectionGraphDirection direction, int? maximumDepth
});


$PresentationCollectionRelationIdCopyWith<$Res> get relation;

}
/// @nodoc
class _$PresentationCollectionGraphCopyWithImpl<$Res>
    implements $PresentationCollectionGraphCopyWith<$Res> {
  _$PresentationCollectionGraphCopyWithImpl(this._self, this._then);

  final PresentationCollectionGraph _self;
  final $Res Function(PresentationCollectionGraph) _then;

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roots = null,Object? relation = null,Object? direction = null,Object? maximumDepth = freezed,}) {
  return _then(PresentationCollectionGraph(
roots: null == roots ? _self._roots : roots // ignore: cast_nullable_to_non_nullable
as List<DataValue>,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as PresentationCollectionRelationId,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CollectionGraphDirection,maximumDepth: freezed == maximumDepth ? _self.maximumDepth : maximumDepth // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PresentationCollectionQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationCollectionRelationIdCopyWith<$Res> get relation {

  return $PresentationCollectionRelationIdCopyWith<$Res>(_self.relation, (value) {
    return _then(_self.copyWith(relation: value));
  });
}
}

/// @nodoc
mixin _$PresentationCollectionRow {

 DataValue get key; DataValue get value;
/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionRowCopyWith<PresentationCollectionRow> get copyWith => _$PresentationCollectionRowCopyWithImpl<PresentationCollectionRow>(this as PresentationCollectionRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionRow&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'PresentationCollectionRow(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionRowCopyWith<$Res>  {
  factory $PresentationCollectionRowCopyWith(PresentationCollectionRow value, $Res Function(PresentationCollectionRow) _then) = _$PresentationCollectionRowCopyWithImpl;
@useResult
$Res call({
 DataValue key, DataValue value
});


$DataValueCopyWith<$Res> get key;$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$PresentationCollectionRowCopyWithImpl<$Res>
    implements $PresentationCollectionRowCopyWith<$Res> {
  _$PresentationCollectionRowCopyWithImpl(this._self, this._then);

  final PresentationCollectionRow _self;
  final $Res Function(PresentationCollectionRow) _then;

/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? value = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as DataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}
/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get key {

  return $DataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {

  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationCollectionRow].
extension PresentationCollectionRowPatterns on PresentationCollectionRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionRow value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionRow value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataValue key,  DataValue value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionRow() when $default != null:
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataValue key,  DataValue value)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRow():
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataValue key,  DataValue value)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionRow() when $default != null:
return $default(_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionRow implements PresentationCollectionRow {
  const _PresentationCollectionRow({required this.key, required this.value});


@override final  DataValue key;
@override final  DataValue value;

/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionRowCopyWith<_PresentationCollectionRow> get copyWith => __$PresentationCollectionRowCopyWithImpl<_PresentationCollectionRow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionRow&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'PresentationCollectionRow(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$PresentationCollectionRowCopyWith<$Res> implements $PresentationCollectionRowCopyWith<$Res> {
  factory _$PresentationCollectionRowCopyWith(_PresentationCollectionRow value, $Res Function(_PresentationCollectionRow) _then) = __$PresentationCollectionRowCopyWithImpl;
@override @useResult
$Res call({
 DataValue key, DataValue value
});


@override $DataValueCopyWith<$Res> get key;@override $DataValueCopyWith<$Res> get value;

}
/// @nodoc
class __$PresentationCollectionRowCopyWithImpl<$Res>
    implements _$PresentationCollectionRowCopyWith<$Res> {
  __$PresentationCollectionRowCopyWithImpl(this._self, this._then);

  final _PresentationCollectionRow _self;
  final $Res Function(_PresentationCollectionRow) _then;

/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(_PresentationCollectionRow(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as DataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of PresentationCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get key {

  return $DataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of PresentationCollectionRow
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
mixin _$PresentationCollectionPath {

 List<DataValue> get keys;
/// Create a copy of PresentationCollectionPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionPathCopyWith<PresentationCollectionPath> get copyWith => _$PresentationCollectionPathCopyWithImpl<PresentationCollectionPath>(this as PresentationCollectionPath, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionPath&&const DeepCollectionEquality().equals(other.keys, keys));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(keys));

@override
String toString() {
  return 'PresentationCollectionPath(keys: $keys)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionPathCopyWith<$Res>  {
  factory $PresentationCollectionPathCopyWith(PresentationCollectionPath value, $Res Function(PresentationCollectionPath) _then) = _$PresentationCollectionPathCopyWithImpl;
@useResult
$Res call({
 List<DataValue> keys
});




}
/// @nodoc
class _$PresentationCollectionPathCopyWithImpl<$Res>
    implements $PresentationCollectionPathCopyWith<$Res> {
  _$PresentationCollectionPathCopyWithImpl(this._self, this._then);

  final PresentationCollectionPath _self;
  final $Res Function(PresentationCollectionPath) _then;

/// Create a copy of PresentationCollectionPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keys = null,}) {
  return _then(_self.copyWith(
keys: null == keys ? _self.keys : keys // ignore: cast_nullable_to_non_nullable
as List<DataValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationCollectionPath].
extension PresentationCollectionPathPatterns on PresentationCollectionPath {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionPath value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionPath() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionPath value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionPath():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionPath value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionPath() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DataValue> keys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionPath() when $default != null:
return $default(_that.keys);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DataValue> keys)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionPath():
return $default(_that.keys);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DataValue> keys)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionPath() when $default != null:
return $default(_that.keys);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionPath implements PresentationCollectionPath {
  const _PresentationCollectionPath(final  List<DataValue> keys): _keys = keys;


 final  List<DataValue> _keys;
@override List<DataValue> get keys {
  if (_keys is EqualUnmodifiableListView) return _keys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keys);
}


/// Create a copy of PresentationCollectionPath
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionPathCopyWith<_PresentationCollectionPath> get copyWith => __$PresentationCollectionPathCopyWithImpl<_PresentationCollectionPath>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionPath&&const DeepCollectionEquality().equals(other._keys, _keys));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_keys));

@override
String toString() {
  return 'PresentationCollectionPath(keys: $keys)';
}


}

/// @nodoc
abstract mixin class _$PresentationCollectionPathCopyWith<$Res> implements $PresentationCollectionPathCopyWith<$Res> {
  factory _$PresentationCollectionPathCopyWith(_PresentationCollectionPath value, $Res Function(_PresentationCollectionPath) _then) = __$PresentationCollectionPathCopyWithImpl;
@override @useResult
$Res call({
 List<DataValue> keys
});




}
/// @nodoc
class __$PresentationCollectionPathCopyWithImpl<$Res>
    implements _$PresentationCollectionPathCopyWith<$Res> {
  __$PresentationCollectionPathCopyWithImpl(this._self, this._then);

  final _PresentationCollectionPath _self;
  final $Res Function(_PresentationCollectionPath) _then;

/// Create a copy of PresentationCollectionPath
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keys = null,}) {
  return _then(_PresentationCollectionPath(
null == keys ? _self._keys : keys // ignore: cast_nullable_to_non_nullable
as List<DataValue>,
  ));
}


}

/// @nodoc
mixin _$PresentationCollectionSnapshot {

 List<PresentationCollectionRow> get rootRows; List<PresentationCollectionRow> get rows; List<PresentationCollectionPath> get paths; List<TypeDiagnostic> get diagnostics; bool get loading;
/// Create a copy of PresentationCollectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationCollectionSnapshotCopyWith<PresentationCollectionSnapshot> get copyWith => _$PresentationCollectionSnapshotCopyWithImpl<PresentationCollectionSnapshot>(this as PresentationCollectionSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationCollectionSnapshot&&const DeepCollectionEquality().equals(other.rootRows, rootRows)&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.paths, paths)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics)&&(identical(other.loading, loading) || other.loading == loading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rootRows),const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(paths),const DeepCollectionEquality().hash(diagnostics),loading);

@override
String toString() {
  return 'PresentationCollectionSnapshot(rootRows: $rootRows, rows: $rows, paths: $paths, diagnostics: $diagnostics, loading: $loading)';
}


}

/// @nodoc
abstract mixin class $PresentationCollectionSnapshotCopyWith<$Res>  {
  factory $PresentationCollectionSnapshotCopyWith(PresentationCollectionSnapshot value, $Res Function(PresentationCollectionSnapshot) _then) = _$PresentationCollectionSnapshotCopyWithImpl;
@useResult
$Res call({
 List<PresentationCollectionRow> rootRows, List<PresentationCollectionRow> rows, List<PresentationCollectionPath> paths, List<TypeDiagnostic> diagnostics, bool loading
});




}
/// @nodoc
class _$PresentationCollectionSnapshotCopyWithImpl<$Res>
    implements $PresentationCollectionSnapshotCopyWith<$Res> {
  _$PresentationCollectionSnapshotCopyWithImpl(this._self, this._then);

  final PresentationCollectionSnapshot _self;
  final $Res Function(PresentationCollectionSnapshot) _then;

/// Create a copy of PresentationCollectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootRows = null,Object? rows = null,Object? paths = null,Object? diagnostics = null,Object? loading = null,}) {
  return _then(_self.copyWith(
rootRows: null == rootRows ? _self.rootRows : rootRows // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRow>,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRow>,paths: null == paths ? _self.paths : paths // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionPath>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationCollectionSnapshot].
extension PresentationCollectionSnapshotPatterns on PresentationCollectionSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationCollectionSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationCollectionSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationCollectionSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PresentationCollectionRow> rootRows,  List<PresentationCollectionRow> rows,  List<PresentationCollectionPath> paths,  List<TypeDiagnostic> diagnostics,  bool loading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot() when $default != null:
return $default(_that.rootRows,_that.rows,_that.paths,_that.diagnostics,_that.loading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PresentationCollectionRow> rootRows,  List<PresentationCollectionRow> rows,  List<PresentationCollectionPath> paths,  List<TypeDiagnostic> diagnostics,  bool loading)  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot():
return $default(_that.rootRows,_that.rows,_that.paths,_that.diagnostics,_that.loading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PresentationCollectionRow> rootRows,  List<PresentationCollectionRow> rows,  List<PresentationCollectionPath> paths,  List<TypeDiagnostic> diagnostics,  bool loading)?  $default,) {final _that = this;
switch (_that) {
case _PresentationCollectionSnapshot() when $default != null:
return $default(_that.rootRows,_that.rows,_that.paths,_that.diagnostics,_that.loading);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationCollectionSnapshot extends PresentationCollectionSnapshot {
  const _PresentationCollectionSnapshot({final  List<PresentationCollectionRow> rootRows = const <PresentationCollectionRow>[], final  List<PresentationCollectionRow> rows = const <PresentationCollectionRow>[], final  List<PresentationCollectionPath> paths = const <PresentationCollectionPath>[], final  List<TypeDiagnostic> diagnostics = const <TypeDiagnostic>[], this.loading = false}): _rootRows = rootRows,_rows = rows,_paths = paths,_diagnostics = diagnostics,super._();


 final  List<PresentationCollectionRow> _rootRows;
@override@JsonKey() List<PresentationCollectionRow> get rootRows {
  if (_rootRows is EqualUnmodifiableListView) return _rootRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rootRows);
}

 final  List<PresentationCollectionRow> _rows;
@override@JsonKey() List<PresentationCollectionRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  List<PresentationCollectionPath> _paths;
@override@JsonKey() List<PresentationCollectionPath> get paths {
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paths);
}

 final  List<TypeDiagnostic> _diagnostics;
@override@JsonKey() List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  bool loading;

/// Create a copy of PresentationCollectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationCollectionSnapshotCopyWith<_PresentationCollectionSnapshot> get copyWith => __$PresentationCollectionSnapshotCopyWithImpl<_PresentationCollectionSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationCollectionSnapshot&&const DeepCollectionEquality().equals(other._rootRows, _rootRows)&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._paths, _paths)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics)&&(identical(other.loading, loading) || other.loading == loading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rootRows),const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_paths),const DeepCollectionEquality().hash(_diagnostics),loading);

@override
String toString() {
  return 'PresentationCollectionSnapshot(rootRows: $rootRows, rows: $rows, paths: $paths, diagnostics: $diagnostics, loading: $loading)';
}


}

/// @nodoc
abstract mixin class _$PresentationCollectionSnapshotCopyWith<$Res> implements $PresentationCollectionSnapshotCopyWith<$Res> {
  factory _$PresentationCollectionSnapshotCopyWith(_PresentationCollectionSnapshot value, $Res Function(_PresentationCollectionSnapshot) _then) = __$PresentationCollectionSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<PresentationCollectionRow> rootRows, List<PresentationCollectionRow> rows, List<PresentationCollectionPath> paths, List<TypeDiagnostic> diagnostics, bool loading
});




}
/// @nodoc
class __$PresentationCollectionSnapshotCopyWithImpl<$Res>
    implements _$PresentationCollectionSnapshotCopyWith<$Res> {
  __$PresentationCollectionSnapshotCopyWithImpl(this._self, this._then);

  final _PresentationCollectionSnapshot _self;
  final $Res Function(_PresentationCollectionSnapshot) _then;

/// Create a copy of PresentationCollectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootRows = null,Object? rows = null,Object? paths = null,Object? diagnostics = null,Object? loading = null,}) {
  return _then(_PresentationCollectionSnapshot(
rootRows: null == rootRows ? _self._rootRows : rootRows // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRow>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionRow>,paths: null == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<PresentationCollectionPath>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
