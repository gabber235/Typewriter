// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_relation_index.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringOwnershipPath {

 List<skir.ResourceId> get owners; String? get problem;
/// Create a copy of AuthoringOwnershipPath
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringOwnershipPathCopyWith<AuthoringOwnershipPath> get copyWith => _$AuthoringOwnershipPathCopyWithImpl<AuthoringOwnershipPath>(this as AuthoringOwnershipPath, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringOwnershipPath;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringOwnershipPath&&const DeepCollectionEquality().equals(other.owners, _this.owners)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}


@override
int get hashCode {
  final _this = this as AuthoringOwnershipPath;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.owners),_this.problem);
}

@override
String toString() {
  final _this = this as AuthoringOwnershipPath;
  return 'AuthoringOwnershipPath(owners: ${_this.owners}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $AuthoringOwnershipPathCopyWith<$Res>  {
  factory $AuthoringOwnershipPathCopyWith(AuthoringOwnershipPath value, $Res Function(AuthoringOwnershipPath) _then) = _$AuthoringOwnershipPathCopyWithImpl;
@useResult
$Res call({
 List<skir.ResourceId> owners, String? problem
});




}
/// @nodoc
class _$AuthoringOwnershipPathCopyWithImpl<$Res>
    implements $AuthoringOwnershipPathCopyWith<$Res> {
  _$AuthoringOwnershipPathCopyWithImpl(this._self, this._then);

  final AuthoringOwnershipPath _self;
  final $Res Function(AuthoringOwnershipPath) _then;

/// Create a copy of AuthoringOwnershipPath
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owners = null,Object? problem = freezed,}) {
  return _then(AuthoringOwnershipPath(
owners: null == owners ? _self.owners : owners // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern matching related methods to [AuthoringOwnershipPath].
extension AuthoringOwnershipPathPatterns on AuthoringOwnershipPath {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringOwnershipPath value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringOwnershipPath() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringOwnershipPath value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringOwnershipPath():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringOwnershipPath value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringOwnershipPath() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.ResourceId> owners,  String? problem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringOwnershipPath() when $default != null:
return $default(_that.owners,_that.problem);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.ResourceId> owners,  String? problem)  $default,) {final _that = this;
switch (_that) {
case _AuthoringOwnershipPath():
return $default(_that.owners,_that.problem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.ResourceId> owners,  String? problem)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringOwnershipPath() when $default != null:
return $default(_that.owners,_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringOwnershipPath implements AuthoringOwnershipPath {
  const _AuthoringOwnershipPath({required  List<skir.ResourceId> owners, this.problem}): _owners = owners;


 final  List<skir.ResourceId> _owners;
@override List<skir.ResourceId> get owners {
  if (_owners is EqualUnmodifiableListView) return _owners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_owners);
}

@override final  String? problem;

/// Create a copy of AuthoringOwnershipPath
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringOwnershipPathCopyWith<_AuthoringOwnershipPath> get copyWith => __$AuthoringOwnershipPathCopyWithImpl<_AuthoringOwnershipPath>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringOwnershipPath&&const DeepCollectionEquality().equals(other.owners, _owners)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_owners),problem);
}

@override
String toString() {
    return 'AuthoringOwnershipPath(owners: $owners, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$AuthoringOwnershipPathCopyWith<$Res> implements $AuthoringOwnershipPathCopyWith<$Res> {
  factory _$AuthoringOwnershipPathCopyWith(_AuthoringOwnershipPath value, $Res Function(_AuthoringOwnershipPath) _then) = __$AuthoringOwnershipPathCopyWithImpl;
@override @useResult
$Res call({
 List<skir.ResourceId> owners, String? problem
});




}
/// @nodoc
class __$AuthoringOwnershipPathCopyWithImpl<$Res>
    implements _$AuthoringOwnershipPathCopyWith<$Res> {
  __$AuthoringOwnershipPathCopyWithImpl(this._self, this._then);

  final _AuthoringOwnershipPath _self;
  final $Res Function(_AuthoringOwnershipPath) _then;

/// Create a copy of AuthoringOwnershipPath
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owners = null,Object? problem = freezed,}) {
  return _then(_AuthoringOwnershipPath(
owners: null == owners ? _self._owners : owners // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AuthoringRelationIndex {

 Map<skir.ResourceId, List<skir.ResourceId>> get parents; Map<skir.ResourceId, List<skir.ResourceId>> get children; Set<skir.TypeDefinitionId> get ownedDefinitions; List<String> get problems; Map<skir.ResourceId, List<String>> get resourceProblems;
/// Create a copy of AuthoringRelationIndex
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringRelationIndexCopyWith<AuthoringRelationIndex> get copyWith => _$AuthoringRelationIndexCopyWithImpl<AuthoringRelationIndex>(this as AuthoringRelationIndex, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringRelationIndex;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringRelationIndex&&const DeepCollectionEquality().equals(other.parents, _this.parents)&&const DeepCollectionEquality().equals(other.children, _this.children)&&const DeepCollectionEquality().equals(other.ownedDefinitions, _this.ownedDefinitions)&&const DeepCollectionEquality().equals(other.problems, _this.problems)&&const DeepCollectionEquality().equals(other.resourceProblems, _this.resourceProblems));
}


@override
int get hashCode {
  final _this = this as AuthoringRelationIndex;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.parents),const DeepCollectionEquality().hash(_this.children),const DeepCollectionEquality().hash(_this.ownedDefinitions),const DeepCollectionEquality().hash(_this.problems),const DeepCollectionEquality().hash(_this.resourceProblems));
}

@override
String toString() {
  final _this = this as AuthoringRelationIndex;
  return 'AuthoringRelationIndex(parents: ${_this.parents}, children: ${_this.children}, ownedDefinitions: ${_this.ownedDefinitions}, problems: ${_this.problems}, resourceProblems: ${_this.resourceProblems})';
}


}

/// @nodoc
abstract mixin class $AuthoringRelationIndexCopyWith<$Res>  {
  factory $AuthoringRelationIndexCopyWith(AuthoringRelationIndex value, $Res Function(AuthoringRelationIndex) _then) = _$AuthoringRelationIndexCopyWithImpl;
@useResult
$Res call({
 Map<skir.ResourceId, List<skir.ResourceId>> parents, Map<skir.ResourceId, List<skir.ResourceId>> children, Set<skir.TypeDefinitionId> ownedDefinitions, List<String> problems, Map<skir.ResourceId, List<String>> resourceProblems
});




}
/// @nodoc
class _$AuthoringRelationIndexCopyWithImpl<$Res>
    implements $AuthoringRelationIndexCopyWith<$Res> {
  _$AuthoringRelationIndexCopyWithImpl(this._self, this._then);

  final AuthoringRelationIndex _self;
  final $Res Function(AuthoringRelationIndex) _then;

/// Create a copy of AuthoringRelationIndex
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? parents = null,Object? children = null,Object? ownedDefinitions = null,Object? problems = null,Object? resourceProblems = null,}) {
  return _then(AuthoringRelationIndex(
parents: null == parents ? _self.parents : parents // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<skir.ResourceId>>,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<skir.ResourceId>>,ownedDefinitions: null == ownedDefinitions ? _self.ownedDefinitions : ownedDefinitions // ignore: cast_nullable_to_non_nullable
as Set<skir.TypeDefinitionId>,problems: null == problems ? _self.problems : problems // ignore: cast_nullable_to_non_nullable
as List<String>,resourceProblems: null == resourceProblems ? _self.resourceProblems : resourceProblems // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<String>>,
  ));
}

}


/// Adds pattern matching related methods to [AuthoringRelationIndex].
extension AuthoringRelationIndexPatterns on AuthoringRelationIndex {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringRelationIndex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringRelationIndex() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringRelationIndex value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringRelationIndex():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringRelationIndex value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringRelationIndex() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<skir.ResourceId, List<skir.ResourceId>> parents,  Map<skir.ResourceId, List<skir.ResourceId>> children,  Set<skir.TypeDefinitionId> ownedDefinitions,  List<String> problems,  Map<skir.ResourceId, List<String>> resourceProblems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringRelationIndex() when $default != null:
return $default(_that.parents,_that.children,_that.ownedDefinitions,_that.problems,_that.resourceProblems);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<skir.ResourceId, List<skir.ResourceId>> parents,  Map<skir.ResourceId, List<skir.ResourceId>> children,  Set<skir.TypeDefinitionId> ownedDefinitions,  List<String> problems,  Map<skir.ResourceId, List<String>> resourceProblems)  $default,) {final _that = this;
switch (_that) {
case _AuthoringRelationIndex():
return $default(_that.parents,_that.children,_that.ownedDefinitions,_that.problems,_that.resourceProblems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<skir.ResourceId, List<skir.ResourceId>> parents,  Map<skir.ResourceId, List<skir.ResourceId>> children,  Set<skir.TypeDefinitionId> ownedDefinitions,  List<String> problems,  Map<skir.ResourceId, List<String>> resourceProblems)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringRelationIndex() when $default != null:
return $default(_that.parents,_that.children,_that.ownedDefinitions,_that.problems,_that.resourceProblems);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringRelationIndex extends AuthoringRelationIndex {
  const _AuthoringRelationIndex({required  Map<skir.ResourceId, List<skir.ResourceId>> parents, required  Map<skir.ResourceId, List<skir.ResourceId>> children, required  Set<skir.TypeDefinitionId> ownedDefinitions, required  List<String> problems, required  Map<skir.ResourceId, List<String>> resourceProblems}): _parents = parents,_children = children,_ownedDefinitions = ownedDefinitions,_problems = problems,_resourceProblems = resourceProblems,super._();


 final  Map<skir.ResourceId, List<skir.ResourceId>> _parents;
@override Map<skir.ResourceId, List<skir.ResourceId>> get parents {
  if (_parents is EqualUnmodifiableMapView) return _parents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parents);
}

 final  Map<skir.ResourceId, List<skir.ResourceId>> _children;
@override Map<skir.ResourceId, List<skir.ResourceId>> get children {
  if (_children is EqualUnmodifiableMapView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_children);
}

 final  Set<skir.TypeDefinitionId> _ownedDefinitions;
@override Set<skir.TypeDefinitionId> get ownedDefinitions {
  if (_ownedDefinitions is EqualUnmodifiableSetView) return _ownedDefinitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_ownedDefinitions);
}

 final  List<String> _problems;
@override List<String> get problems {
  if (_problems is EqualUnmodifiableListView) return _problems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_problems);
}

 final  Map<skir.ResourceId, List<String>> _resourceProblems;
@override Map<skir.ResourceId, List<String>> get resourceProblems {
  if (_resourceProblems is EqualUnmodifiableMapView) return _resourceProblems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resourceProblems);
}


/// Create a copy of AuthoringRelationIndex
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringRelationIndexCopyWith<_AuthoringRelationIndex> get copyWith => __$AuthoringRelationIndexCopyWithImpl<_AuthoringRelationIndex>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringRelationIndex&&const DeepCollectionEquality().equals(other.parents, _parents)&&const DeepCollectionEquality().equals(other.children, _children)&&const DeepCollectionEquality().equals(other.ownedDefinitions, _ownedDefinitions)&&const DeepCollectionEquality().equals(other.problems, _problems)&&const DeepCollectionEquality().equals(other.resourceProblems, _resourceProblems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_parents),const DeepCollectionEquality().hash(_children),const DeepCollectionEquality().hash(_ownedDefinitions),const DeepCollectionEquality().hash(_problems),const DeepCollectionEquality().hash(_resourceProblems));
}

@override
String toString() {
    return 'AuthoringRelationIndex(parents: $parents, children: $children, ownedDefinitions: $ownedDefinitions, problems: $problems, resourceProblems: $resourceProblems)';
}


}

/// @nodoc
abstract mixin class _$AuthoringRelationIndexCopyWith<$Res> implements $AuthoringRelationIndexCopyWith<$Res> {
  factory _$AuthoringRelationIndexCopyWith(_AuthoringRelationIndex value, $Res Function(_AuthoringRelationIndex) _then) = __$AuthoringRelationIndexCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ResourceId, List<skir.ResourceId>> parents, Map<skir.ResourceId, List<skir.ResourceId>> children, Set<skir.TypeDefinitionId> ownedDefinitions, List<String> problems, Map<skir.ResourceId, List<String>> resourceProblems
});




}
/// @nodoc
class __$AuthoringRelationIndexCopyWithImpl<$Res>
    implements _$AuthoringRelationIndexCopyWith<$Res> {
  __$AuthoringRelationIndexCopyWithImpl(this._self, this._then);

  final _AuthoringRelationIndex _self;
  final $Res Function(_AuthoringRelationIndex) _then;

/// Create a copy of AuthoringRelationIndex
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? parents = null,Object? children = null,Object? ownedDefinitions = null,Object? problems = null,Object? resourceProblems = null,}) {
  return _then(_AuthoringRelationIndex(
parents: null == parents ? _self._parents : parents // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<skir.ResourceId>>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<skir.ResourceId>>,ownedDefinitions: null == ownedDefinitions ? _self._ownedDefinitions : ownedDefinitions // ignore: cast_nullable_to_non_nullable
as Set<skir.TypeDefinitionId>,problems: null == problems ? _self._problems : problems // ignore: cast_nullable_to_non_nullable
as List<String>,resourceProblems: null == resourceProblems ? _self._resourceProblems : resourceProblems // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<String>>,
  ));
}


}

// dart format on
