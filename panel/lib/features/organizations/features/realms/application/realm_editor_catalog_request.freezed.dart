// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_editor_catalog_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmEditorSubtypeQuery {

 String get id; ResolvedTypeRef get target;
/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorSubtypeQueryCopyWith<RealmEditorSubtypeQuery> get copyWith => _$RealmEditorSubtypeQueryCopyWithImpl<RealmEditorSubtypeQuery>(this as RealmEditorSubtypeQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorSubtypeQuery&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode => Object.hash(runtimeType,id,target);

@override
String toString() {
  return 'RealmEditorSubtypeQuery(id: $id, target: $target)';
}


}

/// @nodoc
abstract mixin class $RealmEditorSubtypeQueryCopyWith<$Res>  {
  factory $RealmEditorSubtypeQueryCopyWith(RealmEditorSubtypeQuery value, $Res Function(RealmEditorSubtypeQuery) _then) = _$RealmEditorSubtypeQueryCopyWithImpl;
@useResult
$Res call({
 String id, ResolvedTypeRef target
});


$ResolvedTypeRefCopyWith<$Res> get target;

}
/// @nodoc
class _$RealmEditorSubtypeQueryCopyWithImpl<$Res>
    implements $RealmEditorSubtypeQueryCopyWith<$Res> {
  _$RealmEditorSubtypeQueryCopyWithImpl(this._self, this._then);

  final RealmEditorSubtypeQuery _self;
  final $Res Function(RealmEditorSubtypeQuery) _then;

/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? target = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}
/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get target {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmEditorSubtypeQuery].
extension RealmEditorSubtypeQueryPatterns on RealmEditorSubtypeQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmEditorSubtypeQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmEditorSubtypeQuery value)  $default,){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmEditorSubtypeQuery value)?  $default,){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ResolvedTypeRef target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery() when $default != null:
return $default(_that.id,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ResolvedTypeRef target)  $default,) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery():
return $default(_that.id,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ResolvedTypeRef target)?  $default,) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeQuery() when $default != null:
return $default(_that.id,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorSubtypeQuery implements RealmEditorSubtypeQuery {
  const _RealmEditorSubtypeQuery({required this.id, required this.target}): assert(id != "", 'Query ID must not be empty.');
  

@override final  String id;
@override final  ResolvedTypeRef target;

/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorSubtypeQueryCopyWith<_RealmEditorSubtypeQuery> get copyWith => __$RealmEditorSubtypeQueryCopyWithImpl<_RealmEditorSubtypeQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorSubtypeQuery&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode => Object.hash(runtimeType,id,target);

@override
String toString() {
  return 'RealmEditorSubtypeQuery(id: $id, target: $target)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorSubtypeQueryCopyWith<$Res> implements $RealmEditorSubtypeQueryCopyWith<$Res> {
  factory _$RealmEditorSubtypeQueryCopyWith(_RealmEditorSubtypeQuery value, $Res Function(_RealmEditorSubtypeQuery) _then) = __$RealmEditorSubtypeQueryCopyWithImpl;
@override @useResult
$Res call({
 String id, ResolvedTypeRef target
});


@override $ResolvedTypeRefCopyWith<$Res> get target;

}
/// @nodoc
class __$RealmEditorSubtypeQueryCopyWithImpl<$Res>
    implements _$RealmEditorSubtypeQueryCopyWith<$Res> {
  __$RealmEditorSubtypeQueryCopyWithImpl(this._self, this._then);

  final _RealmEditorSubtypeQuery _self;
  final $Res Function(_RealmEditorSubtypeQuery) _then;

/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? target = null,}) {
  return _then(_RealmEditorSubtypeQuery(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}

/// Create a copy of RealmEditorSubtypeQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get target {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$RealmEditorCatalogRequest {

 Set<ResolvedTypeRef> get types; Set<PresentationId> get presentations; Set<RealmEditorSubtypeQuery> get subtypeQueries;
/// Create a copy of RealmEditorCatalogRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogRequestCopyWith<RealmEditorCatalogRequest> get copyWith => _$RealmEditorCatalogRequestCopyWithImpl<RealmEditorCatalogRequest>(this as RealmEditorCatalogRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogRequest&&const DeepCollectionEquality().equals(other.types, types)&&const DeepCollectionEquality().equals(other.presentations, presentations)&&const DeepCollectionEquality().equals(other.subtypeQueries, subtypeQueries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(types),const DeepCollectionEquality().hash(presentations),const DeepCollectionEquality().hash(subtypeQueries));

@override
String toString() {
  return 'RealmEditorCatalogRequest(types: $types, presentations: $presentations, subtypeQueries: $subtypeQueries)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogRequestCopyWith<$Res>  {
  factory $RealmEditorCatalogRequestCopyWith(RealmEditorCatalogRequest value, $Res Function(RealmEditorCatalogRequest) _then) = _$RealmEditorCatalogRequestCopyWithImpl;
@useResult
$Res call({
 Set<ResolvedTypeRef> types, Set<PresentationId> presentations, Set<RealmEditorSubtypeQuery> subtypeQueries
});




}
/// @nodoc
class _$RealmEditorCatalogRequestCopyWithImpl<$Res>
    implements $RealmEditorCatalogRequestCopyWith<$Res> {
  _$RealmEditorCatalogRequestCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogRequest _self;
  final $Res Function(RealmEditorCatalogRequest) _then;

/// Create a copy of RealmEditorCatalogRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? types = null,Object? presentations = null,Object? subtypeQueries = null,}) {
  return _then(_self.copyWith(
types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as Set<PresentationId>,subtypeQueries: null == subtypeQueries ? _self.subtypeQueries : subtypeQueries // ignore: cast_nullable_to_non_nullable
as Set<RealmEditorSubtypeQuery>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmEditorCatalogRequest].
extension RealmEditorCatalogRequestPatterns on RealmEditorCatalogRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmEditorCatalogRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmEditorCatalogRequest value)  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmEditorCatalogRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<ResolvedTypeRef> types,  Set<PresentationId> presentations,  Set<RealmEditorSubtypeQuery> subtypeQueries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest() when $default != null:
return $default(_that.types,_that.presentations,_that.subtypeQueries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<ResolvedTypeRef> types,  Set<PresentationId> presentations,  Set<RealmEditorSubtypeQuery> subtypeQueries)  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest():
return $default(_that.types,_that.presentations,_that.subtypeQueries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<ResolvedTypeRef> types,  Set<PresentationId> presentations,  Set<RealmEditorSubtypeQuery> subtypeQueries)?  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogRequest() when $default != null:
return $default(_that.types,_that.presentations,_that.subtypeQueries);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorCatalogRequest extends RealmEditorCatalogRequest {
  const _RealmEditorCatalogRequest({final  Set<ResolvedTypeRef> types = const {}, final  Set<PresentationId> presentations = const {}, final  Set<RealmEditorSubtypeQuery> subtypeQueries = const {}}): _types = types,_presentations = presentations,_subtypeQueries = subtypeQueries,super._();
  

 final  Set<ResolvedTypeRef> _types;
@override@JsonKey() Set<ResolvedTypeRef> get types {
  if (_types is EqualUnmodifiableSetView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_types);
}

 final  Set<PresentationId> _presentations;
@override@JsonKey() Set<PresentationId> get presentations {
  if (_presentations is EqualUnmodifiableSetView) return _presentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_presentations);
}

 final  Set<RealmEditorSubtypeQuery> _subtypeQueries;
@override@JsonKey() Set<RealmEditorSubtypeQuery> get subtypeQueries {
  if (_subtypeQueries is EqualUnmodifiableSetView) return _subtypeQueries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_subtypeQueries);
}


/// Create a copy of RealmEditorCatalogRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorCatalogRequestCopyWith<_RealmEditorCatalogRequest> get copyWith => __$RealmEditorCatalogRequestCopyWithImpl<_RealmEditorCatalogRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorCatalogRequest&&const DeepCollectionEquality().equals(other._types, _types)&&const DeepCollectionEquality().equals(other._presentations, _presentations)&&const DeepCollectionEquality().equals(other._subtypeQueries, _subtypeQueries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_types),const DeepCollectionEquality().hash(_presentations),const DeepCollectionEquality().hash(_subtypeQueries));

@override
String toString() {
  return 'RealmEditorCatalogRequest(types: $types, presentations: $presentations, subtypeQueries: $subtypeQueries)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorCatalogRequestCopyWith<$Res> implements $RealmEditorCatalogRequestCopyWith<$Res> {
  factory _$RealmEditorCatalogRequestCopyWith(_RealmEditorCatalogRequest value, $Res Function(_RealmEditorCatalogRequest) _then) = __$RealmEditorCatalogRequestCopyWithImpl;
@override @useResult
$Res call({
 Set<ResolvedTypeRef> types, Set<PresentationId> presentations, Set<RealmEditorSubtypeQuery> subtypeQueries
});




}
/// @nodoc
class __$RealmEditorCatalogRequestCopyWithImpl<$Res>
    implements _$RealmEditorCatalogRequestCopyWith<$Res> {
  __$RealmEditorCatalogRequestCopyWithImpl(this._self, this._then);

  final _RealmEditorCatalogRequest _self;
  final $Res Function(_RealmEditorCatalogRequest) _then;

/// Create a copy of RealmEditorCatalogRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? types = null,Object? presentations = null,Object? subtypeQueries = null,}) {
  return _then(_RealmEditorCatalogRequest(
types: null == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as Set<PresentationId>,subtypeQueries: null == subtypeQueries ? _self._subtypeQueries : subtypeQueries // ignore: cast_nullable_to_non_nullable
as Set<RealmEditorSubtypeQuery>,
  ));
}


}

/// @nodoc
mixin _$RealmEditorSubtypeResult {

 String get queryId; List<ResolvedTypeRef> get matches;
/// Create a copy of RealmEditorSubtypeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorSubtypeResultCopyWith<RealmEditorSubtypeResult> get copyWith => _$RealmEditorSubtypeResultCopyWithImpl<RealmEditorSubtypeResult>(this as RealmEditorSubtypeResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorSubtypeResult&&(identical(other.queryId, queryId) || other.queryId == queryId)&&const DeepCollectionEquality().equals(other.matches, matches));
}


@override
int get hashCode => Object.hash(runtimeType,queryId,const DeepCollectionEquality().hash(matches));

@override
String toString() {
  return 'RealmEditorSubtypeResult(queryId: $queryId, matches: $matches)';
}


}

/// @nodoc
abstract mixin class $RealmEditorSubtypeResultCopyWith<$Res>  {
  factory $RealmEditorSubtypeResultCopyWith(RealmEditorSubtypeResult value, $Res Function(RealmEditorSubtypeResult) _then) = _$RealmEditorSubtypeResultCopyWithImpl;
@useResult
$Res call({
 String queryId, List<ResolvedTypeRef> matches
});




}
/// @nodoc
class _$RealmEditorSubtypeResultCopyWithImpl<$Res>
    implements $RealmEditorSubtypeResultCopyWith<$Res> {
  _$RealmEditorSubtypeResultCopyWithImpl(this._self, this._then);

  final RealmEditorSubtypeResult _self;
  final $Res Function(RealmEditorSubtypeResult) _then;

/// Create a copy of RealmEditorSubtypeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queryId = null,Object? matches = null,}) {
  return _then(_self.copyWith(
queryId: null == queryId ? _self.queryId : queryId // ignore: cast_nullable_to_non_nullable
as String,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmEditorSubtypeResult].
extension RealmEditorSubtypeResultPatterns on RealmEditorSubtypeResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmEditorSubtypeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmEditorSubtypeResult value)  $default,){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmEditorSubtypeResult value)?  $default,){
final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String queryId,  List<ResolvedTypeRef> matches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult() when $default != null:
return $default(_that.queryId,_that.matches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String queryId,  List<ResolvedTypeRef> matches)  $default,) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult():
return $default(_that.queryId,_that.matches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String queryId,  List<ResolvedTypeRef> matches)?  $default,) {final _that = this;
switch (_that) {
case _RealmEditorSubtypeResult() when $default != null:
return $default(_that.queryId,_that.matches);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorSubtypeResult implements RealmEditorSubtypeResult {
  const _RealmEditorSubtypeResult({required this.queryId, required final  List<ResolvedTypeRef> matches}): assert(queryId != "", 'Query ID must not be empty.'),_matches = matches;
  

@override final  String queryId;
 final  List<ResolvedTypeRef> _matches;
@override List<ResolvedTypeRef> get matches {
  if (_matches is EqualUnmodifiableListView) return _matches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matches);
}


/// Create a copy of RealmEditorSubtypeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorSubtypeResultCopyWith<_RealmEditorSubtypeResult> get copyWith => __$RealmEditorSubtypeResultCopyWithImpl<_RealmEditorSubtypeResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorSubtypeResult&&(identical(other.queryId, queryId) || other.queryId == queryId)&&const DeepCollectionEquality().equals(other._matches, _matches));
}


@override
int get hashCode => Object.hash(runtimeType,queryId,const DeepCollectionEquality().hash(_matches));

@override
String toString() {
  return 'RealmEditorSubtypeResult(queryId: $queryId, matches: $matches)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorSubtypeResultCopyWith<$Res> implements $RealmEditorSubtypeResultCopyWith<$Res> {
  factory _$RealmEditorSubtypeResultCopyWith(_RealmEditorSubtypeResult value, $Res Function(_RealmEditorSubtypeResult) _then) = __$RealmEditorSubtypeResultCopyWithImpl;
@override @useResult
$Res call({
 String queryId, List<ResolvedTypeRef> matches
});




}
/// @nodoc
class __$RealmEditorSubtypeResultCopyWithImpl<$Res>
    implements _$RealmEditorSubtypeResultCopyWith<$Res> {
  __$RealmEditorSubtypeResultCopyWithImpl(this._self, this._then);

  final _RealmEditorSubtypeResult _self;
  final $Res Function(_RealmEditorSubtypeResult) _then;

/// Create a copy of RealmEditorSubtypeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queryId = null,Object? matches = null,}) {
  return _then(_RealmEditorSubtypeResult(
queryId: null == queryId ? _self.queryId : queryId // ignore: cast_nullable_to_non_nullable
as String,matches: null == matches ? _self._matches : matches // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}


}

// dart format on
