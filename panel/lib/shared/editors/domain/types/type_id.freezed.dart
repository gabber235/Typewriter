// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'type_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypeId {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeId);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $TypeIdCopyWith<$Res>  {
$TypeIdCopyWith(TypeId _, $Res Function(TypeId) __);
}


/// Adds pattern-matching-related methods to [TypeId].
extension TypeIdPatterns on TypeId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OptionTypeId value)?  option,TResult Function( SomeTypeId value)?  some,TResult Function( NoneTypeId value)?  none,TResult Function( DeclaredTypeId value)?  declared,TResult Function( QualifiedTypeId value)?  qualified,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OptionTypeId() when option != null:
return option(_that);case SomeTypeId() when some != null:
return some(_that);case NoneTypeId() when none != null:
return none(_that);case DeclaredTypeId() when declared != null:
return declared(_that);case QualifiedTypeId() when qualified != null:
return qualified(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OptionTypeId value)  option,required TResult Function( SomeTypeId value)  some,required TResult Function( NoneTypeId value)  none,required TResult Function( DeclaredTypeId value)  declared,required TResult Function( QualifiedTypeId value)  qualified,}){
final _that = this;
switch (_that) {
case OptionTypeId():
return option(_that);case SomeTypeId():
return some(_that);case NoneTypeId():
return none(_that);case DeclaredTypeId():
return declared(_that);case QualifiedTypeId():
return qualified(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OptionTypeId value)?  option,TResult? Function( SomeTypeId value)?  some,TResult? Function( NoneTypeId value)?  none,TResult? Function( DeclaredTypeId value)?  declared,TResult? Function( QualifiedTypeId value)?  qualified,}){
final _that = this;
switch (_that) {
case OptionTypeId() when option != null:
return option(_that);case SomeTypeId() when some != null:
return some(_that);case NoneTypeId() when none != null:
return none(_that);case DeclaredTypeId() when declared != null:
return declared(_that);case QualifiedTypeId() when qualified != null:
return qualified(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  option,TResult Function()?  some,TResult Function()?  none,TResult Function( String uuid)?  declared,TResult Function( String namespace,  String name)?  qualified,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OptionTypeId() when option != null:
return option();case SomeTypeId() when some != null:
return some();case NoneTypeId() when none != null:
return none();case DeclaredTypeId() when declared != null:
return declared(_that.uuid);case QualifiedTypeId() when qualified != null:
return qualified(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  option,required TResult Function()  some,required TResult Function()  none,required TResult Function( String uuid)  declared,required TResult Function( String namespace,  String name)  qualified,}) {final _that = this;
switch (_that) {
case OptionTypeId():
return option();case SomeTypeId():
return some();case NoneTypeId():
return none();case DeclaredTypeId():
return declared(_that.uuid);case QualifiedTypeId():
return qualified(_that.namespace,_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  option,TResult? Function()?  some,TResult? Function()?  none,TResult? Function( String uuid)?  declared,TResult? Function( String namespace,  String name)?  qualified,}) {final _that = this;
switch (_that) {
case OptionTypeId() when option != null:
return option();case SomeTypeId() when some != null:
return some();case NoneTypeId() when none != null:
return none();case DeclaredTypeId() when declared != null:
return declared(_that.uuid);case QualifiedTypeId() when qualified != null:
return qualified(_that.namespace,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class OptionTypeId extends TypeId {
  const OptionTypeId(): super._();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionTypeId);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class SomeTypeId extends TypeId {
  const SomeTypeId(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SomeTypeId);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class NoneTypeId extends TypeId {
  const NoneTypeId(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoneTypeId);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class DeclaredTypeId extends TypeId {
   DeclaredTypeId(this.uuid): assert(RegExp(r"^[0-9a-fA-F]{32}$").hasMatch(uuid), 'Declared type UUIDs must contain 32 hexadecimal characters.'),super._();


 final  String uuid;

/// Create a copy of TypeId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeclaredTypeIdCopyWith<DeclaredTypeId> get copyWith => _$DeclaredTypeIdCopyWithImpl<DeclaredTypeId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeclaredTypeId&&(identical(other.uuid, uuid) || other.uuid == uuid));
}


@override
int get hashCode => Object.hash(runtimeType,uuid);



}

/// @nodoc
abstract mixin class $DeclaredTypeIdCopyWith<$Res> implements $TypeIdCopyWith<$Res> {
  factory $DeclaredTypeIdCopyWith(DeclaredTypeId value, $Res Function(DeclaredTypeId) _then) = _$DeclaredTypeIdCopyWithImpl;
@useResult
$Res call({
 String uuid
});




}
/// @nodoc
class _$DeclaredTypeIdCopyWithImpl<$Res>
    implements $DeclaredTypeIdCopyWith<$Res> {
  _$DeclaredTypeIdCopyWithImpl(this._self, this._then);

  final DeclaredTypeId _self;
  final $Res Function(DeclaredTypeId) _then;

/// Create a copy of TypeId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uuid = null,}) {
  return _then(DeclaredTypeId(
null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class QualifiedTypeId extends TypeId {
  const QualifiedTypeId({required this.namespace, required this.name}): assert(namespace != "", 'Namespace must not be empty.'),assert(name != "", 'Name must not be empty.'),super._();
  

 final  String namespace;
 final  String name;

/// Create a copy of TypeId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QualifiedTypeIdCopyWith<QualifiedTypeId> get copyWith => _$QualifiedTypeIdCopyWithImpl<QualifiedTypeId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QualifiedTypeId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);



}

/// @nodoc
abstract mixin class $QualifiedTypeIdCopyWith<$Res> implements $TypeIdCopyWith<$Res> {
  factory $QualifiedTypeIdCopyWith(QualifiedTypeId value, $Res Function(QualifiedTypeId) _then) = _$QualifiedTypeIdCopyWithImpl;
@useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class _$QualifiedTypeIdCopyWithImpl<$Res>
    implements $QualifiedTypeIdCopyWith<$Res> {
  _$QualifiedTypeIdCopyWithImpl(this._self, this._then);

  final QualifiedTypeId _self;
  final $Res Function(QualifiedTypeId) _then;

/// Create a copy of TypeId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(QualifiedTypeId(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ResolvedTypeRef {

 TypeId get id; int get revision; List<TypeExpression> get arguments;
/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<ResolvedTypeRef> get copyWith => _$ResolvedTypeRefCopyWithImpl<ResolvedTypeRef>(this as ResolvedTypeRef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedTypeRef&&(identical(other.id, id) || other.id == id)&&(identical(other.revision, revision) || other.revision == revision)&&const DeepCollectionEquality().equals(other.arguments, arguments));
}


@override
int get hashCode => Object.hash(runtimeType,id,revision,const DeepCollectionEquality().hash(arguments));



}

/// @nodoc
abstract mixin class $ResolvedTypeRefCopyWith<$Res>  {
  factory $ResolvedTypeRefCopyWith(ResolvedTypeRef value, $Res Function(ResolvedTypeRef) _then) = _$ResolvedTypeRefCopyWithImpl;
@useResult
$Res call({
 TypeId id, int revision, List<TypeExpression> arguments
});


$TypeIdCopyWith<$Res> get id;

}
/// @nodoc
class _$ResolvedTypeRefCopyWithImpl<$Res>
    implements $ResolvedTypeRefCopyWith<$Res> {
  _$ResolvedTypeRefCopyWithImpl(this._self, this._then);

  final ResolvedTypeRef _self;
  final $Res Function(ResolvedTypeRef) _then;

/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? revision = null,Object? arguments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TypeId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<TypeExpression>,
  ));
}
/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeIdCopyWith<$Res> get id {
  
  return $TypeIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedTypeRef].
extension ResolvedTypeRefPatterns on ResolvedTypeRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedTypeRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedTypeRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedTypeRef value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedTypeRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedTypeRef value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedTypeRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeId id,  int revision,  List<TypeExpression> arguments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedTypeRef() when $default != null:
return $default(_that.id,_that.revision,_that.arguments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeId id,  int revision,  List<TypeExpression> arguments)  $default,) {final _that = this;
switch (_that) {
case _ResolvedTypeRef():
return $default(_that.id,_that.revision,_that.arguments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeId id,  int revision,  List<TypeExpression> arguments)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedTypeRef() when $default != null:
return $default(_that.id,_that.revision,_that.arguments);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedTypeRef extends ResolvedTypeRef {
  const _ResolvedTypeRef({required this.id, required this.revision, final  List<TypeExpression> arguments = const []}): assert(revision > 0, 'Revision must be positive.'),_arguments = arguments,super._();
  

@override final  TypeId id;
@override final  int revision;
 final  List<TypeExpression> _arguments;
@override@JsonKey() List<TypeExpression> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}


/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedTypeRefCopyWith<_ResolvedTypeRef> get copyWith => __$ResolvedTypeRefCopyWithImpl<_ResolvedTypeRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedTypeRef&&(identical(other.id, id) || other.id == id)&&(identical(other.revision, revision) || other.revision == revision)&&const DeepCollectionEquality().equals(other._arguments, _arguments));
}


@override
int get hashCode => Object.hash(runtimeType,id,revision,const DeepCollectionEquality().hash(_arguments));



}

/// @nodoc
abstract mixin class _$ResolvedTypeRefCopyWith<$Res> implements $ResolvedTypeRefCopyWith<$Res> {
  factory _$ResolvedTypeRefCopyWith(_ResolvedTypeRef value, $Res Function(_ResolvedTypeRef) _then) = __$ResolvedTypeRefCopyWithImpl;
@override @useResult
$Res call({
 TypeId id, int revision, List<TypeExpression> arguments
});


@override $TypeIdCopyWith<$Res> get id;

}
/// @nodoc
class __$ResolvedTypeRefCopyWithImpl<$Res>
    implements _$ResolvedTypeRefCopyWith<$Res> {
  __$ResolvedTypeRefCopyWithImpl(this._self, this._then);

  final _ResolvedTypeRef _self;
  final $Res Function(_ResolvedTypeRef) _then;

/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? revision = null,Object? arguments = null,}) {
  return _then(_ResolvedTypeRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TypeId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<TypeExpression>,
  ));
}

/// Create a copy of ResolvedTypeRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeIdCopyWith<$Res> get id {
  
  return $TypeIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}

// dart format on
