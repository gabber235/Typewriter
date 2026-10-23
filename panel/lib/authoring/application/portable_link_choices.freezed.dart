// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_link_choices.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedReference {

 skir.ConnectIntent get connection; List<ReferenceMaterialization> get materializations;
/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedReferenceCopyWith<ResolvedReference> get copyWith => _$ResolvedReferenceCopyWithImpl<ResolvedReference>(this as ResolvedReference, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedReference&&(identical(other.connection, _this.connection) || other.connection == _this.connection)&&const DeepCollectionEquality().equals(other.materializations, _this.materializations));
}


@override
int get hashCode {
  final _this = this as ResolvedReference;
  return Object.hash(runtimeType,_this.connection,const DeepCollectionEquality().hash(_this.materializations));
}

@override
String toString() {
  final _this = this as ResolvedReference;
  return 'ResolvedReference(connection: ${_this.connection}, materializations: ${_this.materializations})';
}


}

/// @nodoc
abstract mixin class $ResolvedReferenceCopyWith<$Res>  {
  factory $ResolvedReferenceCopyWith(ResolvedReference value, $Res Function(ResolvedReference) _then) = _$ResolvedReferenceCopyWithImpl;
@useResult
$Res call({
 skir.ConnectIntent connection, List<ReferenceMaterialization> materializations
});




}
/// @nodoc
class _$ResolvedReferenceCopyWithImpl<$Res>
    implements $ResolvedReferenceCopyWith<$Res> {
  _$ResolvedReferenceCopyWithImpl(this._self, this._then);

  final ResolvedReference _self;
  final $Res Function(ResolvedReference) _then;

/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connection = null,Object? materializations = null,}) {
  return _then(ResolvedReference(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as skir.ConnectIntent,materializations: null == materializations ? _self.materializations : materializations // ignore: cast_nullable_to_non_nullable
as List<ReferenceMaterialization>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedReference].
extension ResolvedReferencePatterns on ResolvedReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedReference value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedReference value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
return $default(_that.connection,_that.materializations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)  $default,) {final _that = this;
switch (_that) {
case _ResolvedReference():
return $default(_that.connection,_that.materializations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
return $default(_that.connection,_that.materializations);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedReference implements ResolvedReference {
  const _ResolvedReference({required this.connection,  List<ReferenceMaterialization> materializations = const []}): _materializations = materializations;
  

@override final  skir.ConnectIntent connection;
 final  List<ReferenceMaterialization> _materializations;
@override@JsonKey() List<ReferenceMaterialization> get materializations {
  if (_materializations is EqualUnmodifiableListView) return _materializations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_materializations);
}


/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedReferenceCopyWith<_ResolvedReference> get copyWith => __$ResolvedReferenceCopyWithImpl<_ResolvedReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedReference&&(identical(other.connection, connection) || other.connection == connection)&&const DeepCollectionEquality().equals(other.materializations, _materializations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,connection,const DeepCollectionEquality().hash(_materializations));
}

@override
String toString() {
    return 'ResolvedReference(connection: $connection, materializations: $materializations)';
}


}

/// @nodoc
abstract mixin class _$ResolvedReferenceCopyWith<$Res> implements $ResolvedReferenceCopyWith<$Res> {
  factory _$ResolvedReferenceCopyWith(_ResolvedReference value, $Res Function(_ResolvedReference) _then) = __$ResolvedReferenceCopyWithImpl;
@override @useResult
$Res call({
 skir.ConnectIntent connection, List<ReferenceMaterialization> materializations
});




}
/// @nodoc
class __$ResolvedReferenceCopyWithImpl<$Res>
    implements _$ResolvedReferenceCopyWith<$Res> {
  __$ResolvedReferenceCopyWithImpl(this._self, this._then);

  final _ResolvedReference _self;
  final $Res Function(_ResolvedReference) _then;

/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connection = null,Object? materializations = null,}) {
  return _then(_ResolvedReference(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as skir.ConnectIntent,materializations: null == materializations ? _self._materializations : materializations // ignore: cast_nullable_to_non_nullable
as List<ReferenceMaterialization>,
  ));
}


}

/// @nodoc
mixin _$ReferenceMaterialization {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceMaterialization);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReferenceMaterialization()';
}


}

/// @nodoc
class $ReferenceMaterializationCopyWith<$Res>  {
$ReferenceMaterializationCopyWith(ReferenceMaterialization _, $Res Function(ReferenceMaterialization) __);
}


/// Adds pattern-matching-related methods to [ReferenceMaterialization].
extension ReferenceMaterializationPatterns on ReferenceMaterialization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReferenceValueInsertion value)?  value,TResult Function( PreparedReferenceInsertion value)?  preparedItem,TResult Function( PreparedReferenceRecord value)?  preparedRecord,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReferenceValueInsertion value)  value,required TResult Function( PreparedReferenceInsertion value)  preparedItem,required TResult Function( PreparedReferenceRecord value)  preparedRecord,}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion():
return value(_that);case PreparedReferenceInsertion():
return preparedItem(_that);case PreparedReferenceRecord():
return preparedRecord(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReferenceValueInsertion value)?  value,TResult? Function( PreparedReferenceInsertion value)?  preparedItem,TResult? Function( PreparedReferenceRecord value)?  preparedRecord,}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.InsertIntent intent)?  value,TResult Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedItem,TResult Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedRecord,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that.intent);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that.at,_that.request,_that.prepared);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.InsertIntent intent)  value,required TResult Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)  preparedItem,required TResult Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)  preparedRecord,}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion():
return value(_that.intent);case PreparedReferenceInsertion():
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord():
return preparedRecord(_that.at,_that.request,_that.prepared);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.InsertIntent intent)?  value,TResult? Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedItem,TResult? Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedRecord,}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that.intent);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that.at,_that.request,_that.prepared);case _:
  return null;

}
}

}

/// @nodoc


class ReferenceValueInsertion implements ReferenceMaterialization {
  const ReferenceValueInsertion(this.intent);
  

 final  skir.InsertIntent intent;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceValueInsertionCopyWith<ReferenceValueInsertion> get copyWith => _$ReferenceValueInsertionCopyWithImpl<ReferenceValueInsertion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceValueInsertion&&(identical(other.intent, intent) || other.intent == intent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,intent);
}

@override
String toString() {
    return 'ReferenceMaterialization.value(intent: $intent)';
}


}

/// @nodoc
abstract mixin class $ReferenceValueInsertionCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $ReferenceValueInsertionCopyWith(ReferenceValueInsertion value, $Res Function(ReferenceValueInsertion) _then) = _$ReferenceValueInsertionCopyWithImpl;
@useResult
$Res call({
 skir.InsertIntent intent
});




}
/// @nodoc
class _$ReferenceValueInsertionCopyWithImpl<$Res>
    implements $ReferenceValueInsertionCopyWith<$Res> {
  _$ReferenceValueInsertionCopyWithImpl(this._self, this._then);

  final ReferenceValueInsertion _self;
  final $Res Function(ReferenceValueInsertion) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? intent = null,}) {
  return _then(ReferenceValueInsertion(
null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as skir.InsertIntent,
  ));
}


}

/// @nodoc


class PreparedReferenceInsertion implements ReferenceMaterialization {
  const PreparedReferenceInsertion({required this.at, required this.after, required this.item, required this.request, required this.prepared});
  

 final  skir.ValueLocation at;
 final  skir.ItemId? after;
 final  skir.ItemId item;
 final  skir.ValuePreparationRequest request;
 final  skir.PreparedValue prepared;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedReferenceInsertionCopyWith<PreparedReferenceInsertion> get copyWith => _$PreparedReferenceInsertionCopyWithImpl<PreparedReferenceInsertion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedReferenceInsertion&&(identical(other.at, at) || other.at == at)&&(identical(other.after, after) || other.after == after)&&(identical(other.item, item) || other.item == item)&&(identical(other.request, request) || other.request == request)&&(identical(other.prepared, prepared) || other.prepared == prepared));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,after,item,request,prepared);
}

@override
String toString() {
    return 'ReferenceMaterialization.preparedItem(at: $at, after: $after, item: $item, request: $request, prepared: $prepared)';
}


}

/// @nodoc
abstract mixin class $PreparedReferenceInsertionCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $PreparedReferenceInsertionCopyWith(PreparedReferenceInsertion value, $Res Function(PreparedReferenceInsertion) _then) = _$PreparedReferenceInsertionCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation at, skir.ItemId? after, skir.ItemId item, skir.ValuePreparationRequest request, skir.PreparedValue prepared
});




}
/// @nodoc
class _$PreparedReferenceInsertionCopyWithImpl<$Res>
    implements $PreparedReferenceInsertionCopyWith<$Res> {
  _$PreparedReferenceInsertionCopyWithImpl(this._self, this._then);

  final PreparedReferenceInsertion _self;
  final $Res Function(PreparedReferenceInsertion) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,Object? after = freezed,Object? item = null,Object? request = null,Object? prepared = null,}) {
  return _then(PreparedReferenceInsertion(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as skir.ItemId?,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as skir.ItemId,request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.ValuePreparationRequest,prepared: null == prepared ? _self.prepared : prepared // ignore: cast_nullable_to_non_nullable
as skir.PreparedValue,
  ));
}


}

/// @nodoc


class PreparedReferenceRecord implements ReferenceMaterialization {
  const PreparedReferenceRecord({required this.at, required this.request, required this.prepared});
  

 final  skir.ValueLocation at;
 final  skir.ValuePreparationRequest request;
 final  skir.PreparedValue prepared;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedReferenceRecordCopyWith<PreparedReferenceRecord> get copyWith => _$PreparedReferenceRecordCopyWithImpl<PreparedReferenceRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedReferenceRecord&&(identical(other.at, at) || other.at == at)&&(identical(other.request, request) || other.request == request)&&(identical(other.prepared, prepared) || other.prepared == prepared));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,request,prepared);
}

@override
String toString() {
    return 'ReferenceMaterialization.preparedRecord(at: $at, request: $request, prepared: $prepared)';
}


}

/// @nodoc
abstract mixin class $PreparedReferenceRecordCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $PreparedReferenceRecordCopyWith(PreparedReferenceRecord value, $Res Function(PreparedReferenceRecord) _then) = _$PreparedReferenceRecordCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation at, skir.ValuePreparationRequest request, skir.PreparedValue prepared
});




}
/// @nodoc
class _$PreparedReferenceRecordCopyWithImpl<$Res>
    implements $PreparedReferenceRecordCopyWith<$Res> {
  _$PreparedReferenceRecordCopyWithImpl(this._self, this._then);

  final PreparedReferenceRecord _self;
  final $Res Function(PreparedReferenceRecord) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,Object? request = null,Object? prepared = null,}) {
  return _then(PreparedReferenceRecord(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.ValuePreparationRequest,prepared: null == prepared ? _self.prepared : prepared // ignore: cast_nullable_to_non_nullable
as skir.PreparedValue,
  ));
}


}

/// @nodoc
mixin _$ReferenceChoice {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceChoice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReferenceChoice()';
}


}

/// @nodoc
class $ReferenceChoiceCopyWith<$Res>  {
$ReferenceChoiceCopyWith(ReferenceChoice _, $Res Function(ReferenceChoice) __);
}


/// Adds pattern-matching-related methods to [ReferenceChoice].
extension ReferenceChoicePatterns on ReferenceChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExistingReference value)?  existing,TResult Function( NewResourceReference value)?  createResource,TResult Function( NewEmbeddedCounterpart value)?  createCounterpart,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that);case NewResourceReference() when createResource != null:
return createResource(_that);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExistingReference value)  existing,required TResult Function( NewResourceReference value)  createResource,required TResult Function( NewEmbeddedCounterpart value)  createCounterpart,}){
final _that = this;
switch (_that) {
case ExistingReference():
return existing(_that);case NewResourceReference():
return createResource(_that);case NewEmbeddedCounterpart():
return createCounterpart(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExistingReference value)?  existing,TResult? Function( NewResourceReference value)?  createResource,TResult? Function( NewEmbeddedCounterpart value)?  createCounterpart,}){
final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that);case NewResourceReference() when createResource != null:
return createResource(_that);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ResolvedReference reference)?  existing,TResult Function( ResourceCreationTemplate template)?  createResource,TResult Function( PortableNewCounterpartChoice slot)?  createCounterpart,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that.reference);case NewResourceReference() when createResource != null:
return createResource(_that.template);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that.slot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ResolvedReference reference)  existing,required TResult Function( ResourceCreationTemplate template)  createResource,required TResult Function( PortableNewCounterpartChoice slot)  createCounterpart,}) {final _that = this;
switch (_that) {
case ExistingReference():
return existing(_that.reference);case NewResourceReference():
return createResource(_that.template);case NewEmbeddedCounterpart():
return createCounterpart(_that.slot);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ResolvedReference reference)?  existing,TResult? Function( ResourceCreationTemplate template)?  createResource,TResult? Function( PortableNewCounterpartChoice slot)?  createCounterpart,}) {final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that.reference);case NewResourceReference() when createResource != null:
return createResource(_that.template);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that.slot);case _:
  return null;

}
}

}

/// @nodoc


class ExistingReference implements ReferenceChoice {
  const ExistingReference(this.reference);
  

 final  ResolvedReference reference;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExistingReferenceCopyWith<ExistingReference> get copyWith => _$ExistingReferenceCopyWithImpl<ExistingReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExistingReference&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference);
}

@override
String toString() {
    return 'ReferenceChoice.existing(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $ExistingReferenceCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $ExistingReferenceCopyWith(ExistingReference value, $Res Function(ExistingReference) _then) = _$ExistingReferenceCopyWithImpl;
@useResult
$Res call({
 ResolvedReference reference
});


$ResolvedReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$ExistingReferenceCopyWithImpl<$Res>
    implements $ExistingReferenceCopyWith<$Res> {
  _$ExistingReferenceCopyWithImpl(this._self, this._then);

  final ExistingReference _self;
  final $Res Function(ExistingReference) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(ExistingReference(
null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ResolvedReference,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedReferenceCopyWith<$Res> get reference {
  
  return $ResolvedReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

/// @nodoc


class NewResourceReference implements ReferenceChoice {
  const NewResourceReference(this.template);
  

 final  ResourceCreationTemplate template;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewResourceReferenceCopyWith<NewResourceReference> get copyWith => _$NewResourceReferenceCopyWithImpl<NewResourceReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NewResourceReference&&(identical(other.template, template) || other.template == template));
}


@override
int get hashCode {
    return Object.hash(runtimeType,template);
}

@override
String toString() {
    return 'ReferenceChoice.createResource(template: $template)';
}


}

/// @nodoc
abstract mixin class $NewResourceReferenceCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $NewResourceReferenceCopyWith(NewResourceReference value, $Res Function(NewResourceReference) _then) = _$NewResourceReferenceCopyWithImpl;
@useResult
$Res call({
 ResourceCreationTemplate template
});


$ResourceCreationTemplateCopyWith<$Res> get template;

}
/// @nodoc
class _$NewResourceReferenceCopyWithImpl<$Res>
    implements $NewResourceReferenceCopyWith<$Res> {
  _$NewResourceReferenceCopyWithImpl(this._self, this._then);

  final NewResourceReference _self;
  final $Res Function(NewResourceReference) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? template = null,}) {
  return _then(NewResourceReference(
null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as ResourceCreationTemplate,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceCreationTemplateCopyWith<$Res> get template {
  
  return $ResourceCreationTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

/// @nodoc


class NewEmbeddedCounterpart implements ReferenceChoice {
  const NewEmbeddedCounterpart(this.slot);
  

 final  PortableNewCounterpartChoice slot;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewEmbeddedCounterpartCopyWith<NewEmbeddedCounterpart> get copyWith => _$NewEmbeddedCounterpartCopyWithImpl<NewEmbeddedCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NewEmbeddedCounterpart&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slot);
}

@override
String toString() {
    return 'ReferenceChoice.createCounterpart(slot: $slot)';
}


}

/// @nodoc
abstract mixin class $NewEmbeddedCounterpartCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $NewEmbeddedCounterpartCopyWith(NewEmbeddedCounterpart value, $Res Function(NewEmbeddedCounterpart) _then) = _$NewEmbeddedCounterpartCopyWithImpl;
@useResult
$Res call({
 PortableNewCounterpartChoice slot
});


$PortableNewCounterpartChoiceCopyWith<$Res> get slot;

}
/// @nodoc
class _$NewEmbeddedCounterpartCopyWithImpl<$Res>
    implements $NewEmbeddedCounterpartCopyWith<$Res> {
  _$NewEmbeddedCounterpartCopyWithImpl(this._self, this._then);

  final NewEmbeddedCounterpart _self;
  final $Res Function(NewEmbeddedCounterpart) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? slot = null,}) {
  return _then(NewEmbeddedCounterpart(
null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res> get slot {
  
  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

// dart format on
