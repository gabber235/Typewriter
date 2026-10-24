// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_drop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceDrag {

 AuthoringScope get scope; AuthoringResourceIdentifier get primary; List<skir.ResourceId> get subjects;/// Set when a tree group header is dragged: its members keep their path
/// below the group when they move into another group.
 DraggedGroup? get group;
/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceDragCopyWith<ResourceDrag> get copyWith => _$ResourceDragCopyWithImpl<ResourceDrag>(this as ResourceDrag, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceDrag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceDrag&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&const DeepCollectionEquality().equals(other.subjects, _this.subjects)&&(identical(other.group, _this.group) || other.group == _this.group));
}


@override
int get hashCode {
  final _this = this as ResourceDrag;
  return Object.hash(runtimeType,_this.scope,_this.primary,const DeepCollectionEquality().hash(_this.subjects),_this.group);
}

@override
String toString() {
  final _this = this as ResourceDrag;
  return 'ResourceDrag(scope: ${_this.scope}, primary: ${_this.primary}, subjects: ${_this.subjects}, group: ${_this.group})';
}


}

/// @nodoc
abstract mixin class $ResourceDragCopyWith<$Res>  {
  factory $ResourceDragCopyWith(ResourceDrag value, $Res Function(ResourceDrag) _then) = _$ResourceDragCopyWithImpl;
@useResult
$Res call({
 AuthoringScope scope, AuthoringResourceIdentifier primary, List<skir.ResourceId> subjects, DraggedGroup? group
});


$AuthoringScopeCopyWith<$Res> get scope;$AuthoringResourceIdentifierCopyWith<$Res> get primary;$DraggedGroupCopyWith<$Res>? get group;

}
/// @nodoc
class _$ResourceDragCopyWithImpl<$Res>
    implements $ResourceDragCopyWith<$Res> {
  _$ResourceDragCopyWithImpl(this._self, this._then);

  final ResourceDrag _self;
  final $Res Function(ResourceDrag) _then;

/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? primary = null,Object? subjects = null,Object? group = freezed,}) {
  return _then(ResourceDrag(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as AuthoringScope,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as DraggedGroup?,
  ));
}
/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<$Res> get scope {
  
  return $AuthoringScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get primary {
  
  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraggedGroupCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $DraggedGroupCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResourceDrag].
extension ResourceDragPatterns on ResourceDrag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceDrag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceDrag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceDrag value)  $default,){
final _that = this;
switch (_that) {
case _ResourceDrag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceDrag value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceDrag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringScope scope,  AuthoringResourceIdentifier primary,  List<skir.ResourceId> subjects,  DraggedGroup? group)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceDrag() when $default != null:
return $default(_that.scope,_that.primary,_that.subjects,_that.group);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringScope scope,  AuthoringResourceIdentifier primary,  List<skir.ResourceId> subjects,  DraggedGroup? group)  $default,) {final _that = this;
switch (_that) {
case _ResourceDrag():
return $default(_that.scope,_that.primary,_that.subjects,_that.group);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringScope scope,  AuthoringResourceIdentifier primary,  List<skir.ResourceId> subjects,  DraggedGroup? group)?  $default,) {final _that = this;
switch (_that) {
case _ResourceDrag() when $default != null:
return $default(_that.scope,_that.primary,_that.subjects,_that.group);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceDrag extends ResourceDrag {
  const _ResourceDrag({required this.scope, required this.primary, required  List<skir.ResourceId> subjects, this.group}): _subjects = subjects,super._();
  

@override final  AuthoringScope scope;
@override final  AuthoringResourceIdentifier primary;
 final  List<skir.ResourceId> _subjects;
@override List<skir.ResourceId> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}

/// Set when a tree group header is dragged: its members keep their path
/// below the group when they move into another group.
@override final  DraggedGroup? group;

/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceDragCopyWith<_ResourceDrag> get copyWith => __$ResourceDragCopyWithImpl<_ResourceDrag>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceDrag&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.primary, primary) || other.primary == primary)&&const DeepCollectionEquality().equals(other.subjects, _subjects)&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scope,primary,const DeepCollectionEquality().hash(_subjects),group);
}

@override
String toString() {
    return 'ResourceDrag(scope: $scope, primary: $primary, subjects: $subjects, group: $group)';
}


}

/// @nodoc
abstract mixin class _$ResourceDragCopyWith<$Res> implements $ResourceDragCopyWith<$Res> {
  factory _$ResourceDragCopyWith(_ResourceDrag value, $Res Function(_ResourceDrag) _then) = __$ResourceDragCopyWithImpl;
@override @useResult
$Res call({
 AuthoringScope scope, AuthoringResourceIdentifier primary, List<skir.ResourceId> subjects, DraggedGroup? group
});


@override $AuthoringScopeCopyWith<$Res> get scope;@override $AuthoringResourceIdentifierCopyWith<$Res> get primary;@override $DraggedGroupCopyWith<$Res>? get group;

}
/// @nodoc
class __$ResourceDragCopyWithImpl<$Res>
    implements _$ResourceDragCopyWith<$Res> {
  __$ResourceDragCopyWithImpl(this._self, this._then);

  final _ResourceDrag _self;
  final $Res Function(_ResourceDrag) _then;

/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? primary = null,Object? subjects = null,Object? group = freezed,}) {
  return _then(_ResourceDrag(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as AuthoringScope,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as DraggedGroup?,
  ));
}

/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<$Res> get scope {
  
  return $AuthoringScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get primary {
  
  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}/// Create a copy of ResourceDrag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraggedGroupCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $DraggedGroupCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc
mixin _$DraggedGroup {

 skir.ValuePath get field; String get path;
/// Create a copy of DraggedGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraggedGroupCopyWith<DraggedGroup> get copyWith => _$DraggedGroupCopyWithImpl<DraggedGroup>(this as DraggedGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DraggedGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraggedGroup&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.path, _this.path) || other.path == _this.path));
}


@override
int get hashCode {
  final _this = this as DraggedGroup;
  return Object.hash(runtimeType,_this.field,_this.path);
}

@override
String toString() {
  final _this = this as DraggedGroup;
  return 'DraggedGroup(field: ${_this.field}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $DraggedGroupCopyWith<$Res>  {
  factory $DraggedGroupCopyWith(DraggedGroup value, $Res Function(DraggedGroup) _then) = _$DraggedGroupCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath field, String path
});




}
/// @nodoc
class _$DraggedGroupCopyWithImpl<$Res>
    implements $DraggedGroupCopyWith<$Res> {
  _$DraggedGroupCopyWithImpl(this._self, this._then);

  final DraggedGroup _self;
  final $Res Function(DraggedGroup) _then;

/// Create a copy of DraggedGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? path = null,}) {
  return _then(DraggedGroup(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DraggedGroup].
extension DraggedGroupPatterns on DraggedGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraggedGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraggedGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraggedGroup value)  $default,){
final _that = this;
switch (_that) {
case _DraggedGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraggedGroup value)?  $default,){
final _that = this;
switch (_that) {
case _DraggedGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValuePath field,  String path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraggedGroup() when $default != null:
return $default(_that.field,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValuePath field,  String path)  $default,) {final _that = this;
switch (_that) {
case _DraggedGroup():
return $default(_that.field,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValuePath field,  String path)?  $default,) {final _that = this;
switch (_that) {
case _DraggedGroup() when $default != null:
return $default(_that.field,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _DraggedGroup implements DraggedGroup {
  const _DraggedGroup({required this.field, required this.path});
  

@override final  skir.ValuePath field;
@override final  String path;

/// Create a copy of DraggedGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraggedGroupCopyWith<_DraggedGroup> get copyWith => __$DraggedGroupCopyWithImpl<_DraggedGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraggedGroup&&(identical(other.field, field) || other.field == field)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field,path);
}

@override
String toString() {
    return 'DraggedGroup(field: $field, path: $path)';
}


}

/// @nodoc
abstract mixin class _$DraggedGroupCopyWith<$Res> implements $DraggedGroupCopyWith<$Res> {
  factory _$DraggedGroupCopyWith(_DraggedGroup value, $Res Function(_DraggedGroup) _then) = __$DraggedGroupCopyWithImpl;
@override @useResult
$Res call({
 skir.ValuePath field, String path
});




}
/// @nodoc
class __$DraggedGroupCopyWithImpl<$Res>
    implements _$DraggedGroupCopyWith<$Res> {
  __$DraggedGroupCopyWithImpl(this._self, this._then);

  final _DraggedGroup _self;
  final $Res Function(_DraggedGroup) _then;

/// Create a copy of DraggedGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? path = null,}) {
  return _then(_DraggedGroup(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DropDestination {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DropDestination);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DropDestination()';
}


}

/// @nodoc
class $DropDestinationCopyWith<$Res>  {
$DropDestinationCopyWith(DropDestination _, $Res Function(DropDestination) __);
}


/// Adds pattern-matching-related methods to [DropDestination].
extension DropDestinationPatterns on DropDestination {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResourceDestination value)?  resource,TResult Function( LinkFieldDestination value)?  linkField,TResult Function( RegroupDestination value)?  regroup,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResourceDestination() when resource != null:
return resource(_that);case LinkFieldDestination() when linkField != null:
return linkField(_that);case RegroupDestination() when regroup != null:
return regroup(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResourceDestination value)  resource,required TResult Function( LinkFieldDestination value)  linkField,required TResult Function( RegroupDestination value)  regroup,}){
final _that = this;
switch (_that) {
case ResourceDestination():
return resource(_that);case LinkFieldDestination():
return linkField(_that);case RegroupDestination():
return regroup(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResourceDestination value)?  resource,TResult? Function( LinkFieldDestination value)?  linkField,TResult? Function( RegroupDestination value)?  regroup,}){
final _that = this;
switch (_that) {
case ResourceDestination() when resource != null:
return resource(_that);case LinkFieldDestination() when linkField != null:
return linkField(_that);case RegroupDestination() when regroup != null:
return regroup(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ResourceId id,  Offset? anchor)?  resource,TResult Function( skir.ValueLocation location,  Offset? anchor)?  linkField,TResult Function( skir.ValuePath field,  String value)?  regroup,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResourceDestination() when resource != null:
return resource(_that.id,_that.anchor);case LinkFieldDestination() when linkField != null:
return linkField(_that.location,_that.anchor);case RegroupDestination() when regroup != null:
return regroup(_that.field,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ResourceId id,  Offset? anchor)  resource,required TResult Function( skir.ValueLocation location,  Offset? anchor)  linkField,required TResult Function( skir.ValuePath field,  String value)  regroup,}) {final _that = this;
switch (_that) {
case ResourceDestination():
return resource(_that.id,_that.anchor);case LinkFieldDestination():
return linkField(_that.location,_that.anchor);case RegroupDestination():
return regroup(_that.field,_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ResourceId id,  Offset? anchor)?  resource,TResult? Function( skir.ValueLocation location,  Offset? anchor)?  linkField,TResult? Function( skir.ValuePath field,  String value)?  regroup,}) {final _that = this;
switch (_that) {
case ResourceDestination() when resource != null:
return resource(_that.id,_that.anchor);case LinkFieldDestination() when linkField != null:
return linkField(_that.location,_that.anchor);case RegroupDestination() when regroup != null:
return regroup(_that.field,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class ResourceDestination implements DropDestination {
  const ResourceDestination(this.id, {this.anchor});
  

 final  skir.ResourceId id;
 final  Offset? anchor;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceDestinationCopyWith<ResourceDestination> get copyWith => _$ResourceDestinationCopyWithImpl<ResourceDestination>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceDestination&&(identical(other.id, id) || other.id == id)&&(identical(other.anchor, anchor) || other.anchor == anchor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,anchor);
}

@override
String toString() {
    return 'DropDestination.resource(id: $id, anchor: $anchor)';
}


}

/// @nodoc
abstract mixin class $ResourceDestinationCopyWith<$Res> implements $DropDestinationCopyWith<$Res> {
  factory $ResourceDestinationCopyWith(ResourceDestination value, $Res Function(ResourceDestination) _then) = _$ResourceDestinationCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId id, Offset? anchor
});




}
/// @nodoc
class _$ResourceDestinationCopyWithImpl<$Res>
    implements $ResourceDestinationCopyWith<$Res> {
  _$ResourceDestinationCopyWithImpl(this._self, this._then);

  final ResourceDestination _self;
  final $Res Function(ResourceDestination) _then;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? anchor = freezed,}) {
  return _then(ResourceDestination(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,anchor: freezed == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Offset?,
  ));
}


}

/// @nodoc


class LinkFieldDestination implements DropDestination {
  const LinkFieldDestination(this.location, {this.anchor});
  

 final  skir.ValueLocation location;
 final  Offset? anchor;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkFieldDestinationCopyWith<LinkFieldDestination> get copyWith => _$LinkFieldDestinationCopyWithImpl<LinkFieldDestination>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkFieldDestination&&(identical(other.location, location) || other.location == location)&&(identical(other.anchor, anchor) || other.anchor == anchor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,location,anchor);
}

@override
String toString() {
    return 'DropDestination.linkField(location: $location, anchor: $anchor)';
}


}

/// @nodoc
abstract mixin class $LinkFieldDestinationCopyWith<$Res> implements $DropDestinationCopyWith<$Res> {
  factory $LinkFieldDestinationCopyWith(LinkFieldDestination value, $Res Function(LinkFieldDestination) _then) = _$LinkFieldDestinationCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation location, Offset? anchor
});




}
/// @nodoc
class _$LinkFieldDestinationCopyWithImpl<$Res>
    implements $LinkFieldDestinationCopyWith<$Res> {
  _$LinkFieldDestinationCopyWithImpl(this._self, this._then);

  final LinkFieldDestination _self;
  final $Res Function(LinkFieldDestination) _then;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? location = null,Object? anchor = freezed,}) {
  return _then(LinkFieldDestination(
null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,anchor: freezed == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Offset?,
  ));
}


}

/// @nodoc


class RegroupDestination implements DropDestination {
  const RegroupDestination(this.field, this.value);
  

 final  skir.ValuePath field;
 final  String value;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegroupDestinationCopyWith<RegroupDestination> get copyWith => _$RegroupDestinationCopyWithImpl<RegroupDestination>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RegroupDestination&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field,value);
}

@override
String toString() {
    return 'DropDestination.regroup(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class $RegroupDestinationCopyWith<$Res> implements $DropDestinationCopyWith<$Res> {
  factory $RegroupDestinationCopyWith(RegroupDestination value, $Res Function(RegroupDestination) _then) = _$RegroupDestinationCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath field, String value
});




}
/// @nodoc
class _$RegroupDestinationCopyWithImpl<$Res>
    implements $RegroupDestinationCopyWith<$Res> {
  _$RegroupDestinationCopyWithImpl(this._self, this._then);

  final RegroupDestination _self;
  final $Res Function(RegroupDestination) _then;

/// Create a copy of DropDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(RegroupDestination(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DropCandidateIndex {

 ResourceDrag get drag; Map<skir.ResourceOperationId, skir.DropCandidates> get byOperation;
/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DropCandidateIndexCopyWith<DropCandidateIndex> get copyWith => _$DropCandidateIndexCopyWithImpl<DropCandidateIndex>(this as DropCandidateIndex, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DropCandidateIndex;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropCandidateIndex&&(identical(other.drag, _this.drag) || other.drag == _this.drag)&&const DeepCollectionEquality().equals(other.byOperation, _this.byOperation));
}


@override
int get hashCode {
  final _this = this as DropCandidateIndex;
  return Object.hash(runtimeType,_this.drag,const DeepCollectionEquality().hash(_this.byOperation));
}

@override
String toString() {
  final _this = this as DropCandidateIndex;
  return 'DropCandidateIndex(drag: ${_this.drag}, byOperation: ${_this.byOperation})';
}


}

/// @nodoc
abstract mixin class $DropCandidateIndexCopyWith<$Res>  {
  factory $DropCandidateIndexCopyWith(DropCandidateIndex value, $Res Function(DropCandidateIndex) _then) = _$DropCandidateIndexCopyWithImpl;
@useResult
$Res call({
 ResourceDrag drag, Map<skir.ResourceOperationId, skir.DropCandidates> byOperation
});


$ResourceDragCopyWith<$Res> get drag;

}
/// @nodoc
class _$DropCandidateIndexCopyWithImpl<$Res>
    implements $DropCandidateIndexCopyWith<$Res> {
  _$DropCandidateIndexCopyWithImpl(this._self, this._then);

  final DropCandidateIndex _self;
  final $Res Function(DropCandidateIndex) _then;

/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drag = null,Object? byOperation = null,}) {
  return _then(DropCandidateIndex(
drag: null == drag ? _self.drag : drag // ignore: cast_nullable_to_non_nullable
as ResourceDrag,byOperation: null == byOperation ? _self.byOperation : byOperation // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceOperationId, skir.DropCandidates>,
  ));
}
/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceDragCopyWith<$Res> get drag {
  
  return $ResourceDragCopyWith<$Res>(_self.drag, (value) {
    return _then(_self.copyWith(drag: value));
  });
}
}


/// Adds pattern-matching-related methods to [DropCandidateIndex].
extension DropCandidateIndexPatterns on DropCandidateIndex {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DropCandidateIndex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DropCandidateIndex() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DropCandidateIndex value)  $default,){
final _that = this;
switch (_that) {
case _DropCandidateIndex():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DropCandidateIndex value)?  $default,){
final _that = this;
switch (_that) {
case _DropCandidateIndex() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResourceDrag drag,  Map<skir.ResourceOperationId, skir.DropCandidates> byOperation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DropCandidateIndex() when $default != null:
return $default(_that.drag,_that.byOperation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResourceDrag drag,  Map<skir.ResourceOperationId, skir.DropCandidates> byOperation)  $default,) {final _that = this;
switch (_that) {
case _DropCandidateIndex():
return $default(_that.drag,_that.byOperation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResourceDrag drag,  Map<skir.ResourceOperationId, skir.DropCandidates> byOperation)?  $default,) {final _that = this;
switch (_that) {
case _DropCandidateIndex() when $default != null:
return $default(_that.drag,_that.byOperation);case _:
  return null;

}
}

}

/// @nodoc


class _DropCandidateIndex extends DropCandidateIndex {
  const _DropCandidateIndex({required this.drag, required  Map<skir.ResourceOperationId, skir.DropCandidates> byOperation}): _byOperation = byOperation,super._();
  

@override final  ResourceDrag drag;
 final  Map<skir.ResourceOperationId, skir.DropCandidates> _byOperation;
@override Map<skir.ResourceOperationId, skir.DropCandidates> get byOperation {
  if (_byOperation is EqualUnmodifiableMapView) return _byOperation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byOperation);
}


/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DropCandidateIndexCopyWith<_DropCandidateIndex> get copyWith => __$DropCandidateIndexCopyWithImpl<_DropCandidateIndex>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DropCandidateIndex&&(identical(other.drag, drag) || other.drag == drag)&&const DeepCollectionEquality().equals(other.byOperation, _byOperation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,drag,const DeepCollectionEquality().hash(_byOperation));
}

@override
String toString() {
    return 'DropCandidateIndex(drag: $drag, byOperation: $byOperation)';
}


}

/// @nodoc
abstract mixin class _$DropCandidateIndexCopyWith<$Res> implements $DropCandidateIndexCopyWith<$Res> {
  factory _$DropCandidateIndexCopyWith(_DropCandidateIndex value, $Res Function(_DropCandidateIndex) _then) = __$DropCandidateIndexCopyWithImpl;
@override @useResult
$Res call({
 ResourceDrag drag, Map<skir.ResourceOperationId, skir.DropCandidates> byOperation
});


@override $ResourceDragCopyWith<$Res> get drag;

}
/// @nodoc
class __$DropCandidateIndexCopyWithImpl<$Res>
    implements _$DropCandidateIndexCopyWith<$Res> {
  __$DropCandidateIndexCopyWithImpl(this._self, this._then);

  final _DropCandidateIndex _self;
  final $Res Function(_DropCandidateIndex) _then;

/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drag = null,Object? byOperation = null,}) {
  return _then(_DropCandidateIndex(
drag: null == drag ? _self.drag : drag // ignore: cast_nullable_to_non_nullable
as ResourceDrag,byOperation: null == byOperation ? _self._byOperation : byOperation // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceOperationId, skir.DropCandidates>,
  ));
}

/// Create a copy of DropCandidateIndex
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceDragCopyWith<$Res> get drag {
  
  return $ResourceDragCopyWith<$Res>(_self.drag, (value) {
    return _then(_self.copyWith(drag: value));
  });
}
}

/// @nodoc
mixin _$DropOffer {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DropOffer);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DropOffer()';
}


}

/// @nodoc
class $DropOfferCopyWith<$Res>  {
$DropOfferCopyWith(DropOffer _, $Res Function(DropOffer) __);
}


/// Adds pattern-matching-related methods to [DropOffer].
extension DropOfferPatterns on DropOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OperationDropOffer value)?  operation,TResult Function( LinkDropOffer value)?  link,TResult Function( RegroupDropOffer value)?  regroup,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OperationDropOffer() when operation != null:
return operation(_that);case LinkDropOffer() when link != null:
return link(_that);case RegroupDropOffer() when regroup != null:
return regroup(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OperationDropOffer value)  operation,required TResult Function( LinkDropOffer value)  link,required TResult Function( RegroupDropOffer value)  regroup,}){
final _that = this;
switch (_that) {
case OperationDropOffer():
return operation(_that);case LinkDropOffer():
return link(_that);case RegroupDropOffer():
return regroup(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OperationDropOffer value)?  operation,TResult? Function( LinkDropOffer value)?  link,TResult? Function( RegroupDropOffer value)?  regroup,}){
final _that = this;
switch (_that) {
case OperationDropOffer() when operation != null:
return operation(_that);case LinkDropOffer() when link != null:
return link(_that);case RegroupDropOffer() when regroup != null:
return regroup(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ResourceOperationDefinition operation,  skir.ResourceId destination,  Offset? anchor)?  operation,TResult Function( skir.ValueLocation location,  Offset? anchor)?  link,TResult Function( skir.ValuePath field,  String value)?  regroup,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OperationDropOffer() when operation != null:
return operation(_that.operation,_that.destination,_that.anchor);case LinkDropOffer() when link != null:
return link(_that.location,_that.anchor);case RegroupDropOffer() when regroup != null:
return regroup(_that.field,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ResourceOperationDefinition operation,  skir.ResourceId destination,  Offset? anchor)  operation,required TResult Function( skir.ValueLocation location,  Offset? anchor)  link,required TResult Function( skir.ValuePath field,  String value)  regroup,}) {final _that = this;
switch (_that) {
case OperationDropOffer():
return operation(_that.operation,_that.destination,_that.anchor);case LinkDropOffer():
return link(_that.location,_that.anchor);case RegroupDropOffer():
return regroup(_that.field,_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ResourceOperationDefinition operation,  skir.ResourceId destination,  Offset? anchor)?  operation,TResult? Function( skir.ValueLocation location,  Offset? anchor)?  link,TResult? Function( skir.ValuePath field,  String value)?  regroup,}) {final _that = this;
switch (_that) {
case OperationDropOffer() when operation != null:
return operation(_that.operation,_that.destination,_that.anchor);case LinkDropOffer() when link != null:
return link(_that.location,_that.anchor);case RegroupDropOffer() when regroup != null:
return regroup(_that.field,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class OperationDropOffer extends DropOffer {
  const OperationDropOffer({required this.operation, required this.destination, this.anchor}): super._();
  

 final  skir.ResourceOperationDefinition operation;
 final  skir.ResourceId destination;
 final  Offset? anchor;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationDropOfferCopyWith<OperationDropOffer> get copyWith => _$OperationDropOfferCopyWithImpl<OperationDropOffer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationDropOffer&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.anchor, anchor) || other.anchor == anchor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,operation,destination,anchor);
}

@override
String toString() {
    return 'DropOffer.operation(operation: $operation, destination: $destination, anchor: $anchor)';
}


}

/// @nodoc
abstract mixin class $OperationDropOfferCopyWith<$Res> implements $DropOfferCopyWith<$Res> {
  factory $OperationDropOfferCopyWith(OperationDropOffer value, $Res Function(OperationDropOffer) _then) = _$OperationDropOfferCopyWithImpl;
@useResult
$Res call({
 skir.ResourceOperationDefinition operation, skir.ResourceId destination, Offset? anchor
});




}
/// @nodoc
class _$OperationDropOfferCopyWithImpl<$Res>
    implements $OperationDropOfferCopyWith<$Res> {
  _$OperationDropOfferCopyWithImpl(this._self, this._then);

  final OperationDropOffer _self;
  final $Res Function(OperationDropOffer) _then;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? destination = null,Object? anchor = freezed,}) {
  return _then(OperationDropOffer(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as skir.ResourceOperationDefinition,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,anchor: freezed == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Offset?,
  ));
}


}

/// @nodoc


class LinkDropOffer extends DropOffer {
  const LinkDropOffer({required this.location, this.anchor}): super._();
  

 final  skir.ValueLocation location;
 final  Offset? anchor;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkDropOfferCopyWith<LinkDropOffer> get copyWith => _$LinkDropOfferCopyWithImpl<LinkDropOffer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkDropOffer&&(identical(other.location, location) || other.location == location)&&(identical(other.anchor, anchor) || other.anchor == anchor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,location,anchor);
}

@override
String toString() {
    return 'DropOffer.link(location: $location, anchor: $anchor)';
}


}

/// @nodoc
abstract mixin class $LinkDropOfferCopyWith<$Res> implements $DropOfferCopyWith<$Res> {
  factory $LinkDropOfferCopyWith(LinkDropOffer value, $Res Function(LinkDropOffer) _then) = _$LinkDropOfferCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation location, Offset? anchor
});




}
/// @nodoc
class _$LinkDropOfferCopyWithImpl<$Res>
    implements $LinkDropOfferCopyWith<$Res> {
  _$LinkDropOfferCopyWithImpl(this._self, this._then);

  final LinkDropOffer _self;
  final $Res Function(LinkDropOffer) _then;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? location = null,Object? anchor = freezed,}) {
  return _then(LinkDropOffer(
location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,anchor: freezed == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Offset?,
  ));
}


}

/// @nodoc


class RegroupDropOffer extends DropOffer {
  const RegroupDropOffer({required this.field, required this.value}): super._();
  

 final  skir.ValuePath field;
 final  String value;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegroupDropOfferCopyWith<RegroupDropOffer> get copyWith => _$RegroupDropOfferCopyWithImpl<RegroupDropOffer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RegroupDropOffer&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field,value);
}

@override
String toString() {
    return 'DropOffer.regroup(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class $RegroupDropOfferCopyWith<$Res> implements $DropOfferCopyWith<$Res> {
  factory $RegroupDropOfferCopyWith(RegroupDropOffer value, $Res Function(RegroupDropOffer) _then) = _$RegroupDropOfferCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath field, String value
});




}
/// @nodoc
class _$RegroupDropOfferCopyWithImpl<$Res>
    implements $RegroupDropOfferCopyWith<$Res> {
  _$RegroupDropOfferCopyWithImpl(this._self, this._then);

  final RegroupDropOffer _self;
  final $Res Function(RegroupDropOffer) _then;

/// Create a copy of DropOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(RegroupDropOffer(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
