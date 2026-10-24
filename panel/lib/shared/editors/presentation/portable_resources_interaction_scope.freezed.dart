// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_resources_interaction_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableResourcesView {

 List<PortableResourceMember> get members; PortablePresentationScope get scope; PortableResourcesLayoutKind get layout;/// The link field the members are linked at, when the binding has one.
 skir.ValueLocation? get location;
/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourcesViewCopyWith<PortableResourcesView> get copyWith => _$PortableResourcesViewCopyWithImpl<PortableResourcesView>(this as PortableResourcesView, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourcesView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourcesView&&const DeepCollectionEquality().equals(other.members, _this.members)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.layout, _this.layout) || other.layout == _this.layout)&&(identical(other.location, _this.location) || other.location == _this.location));
}


@override
int get hashCode {
  final _this = this as PortableResourcesView;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.members),_this.scope,_this.layout,_this.location);
}

@override
String toString() {
  final _this = this as PortableResourcesView;
  return 'PortableResourcesView(members: ${_this.members}, scope: ${_this.scope}, layout: ${_this.layout}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $PortableResourcesViewCopyWith<$Res>  {
  factory $PortableResourcesViewCopyWith(PortableResourcesView value, $Res Function(PortableResourcesView) _then) = _$PortableResourcesViewCopyWithImpl;
@useResult
$Res call({
 List<PortableResourceMember> members, PortablePresentationScope scope, PortableResourcesLayoutKind layout, skir.ValueLocation? location
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$PortableResourcesViewCopyWithImpl<$Res>
    implements $PortableResourcesViewCopyWith<$Res> {
  _$PortableResourcesViewCopyWithImpl(this._self, this._then);

  final PortableResourcesView _self;
  final $Res Function(PortableResourcesView) _then;

/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? members = null,Object? scope = null,Object? layout = null,Object? location = freezed,}) {
  return _then(PortableResourcesView(
members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as PortableResourcesLayoutKind,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}
/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableResourcesView].
extension PortableResourcesViewPatterns on PortableResourcesView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableResourcesView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableResourcesView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableResourcesView value)  $default,){
final _that = this;
switch (_that) {
case _PortableResourcesView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableResourcesView value)?  $default,){
final _that = this;
switch (_that) {
case _PortableResourcesView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PortableResourceMember> members,  PortablePresentationScope scope,  PortableResourcesLayoutKind layout,  skir.ValueLocation? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableResourcesView() when $default != null:
return $default(_that.members,_that.scope,_that.layout,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PortableResourceMember> members,  PortablePresentationScope scope,  PortableResourcesLayoutKind layout,  skir.ValueLocation? location)  $default,) {final _that = this;
switch (_that) {
case _PortableResourcesView():
return $default(_that.members,_that.scope,_that.layout,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PortableResourceMember> members,  PortablePresentationScope scope,  PortableResourcesLayoutKind layout,  skir.ValueLocation? location)?  $default,) {final _that = this;
switch (_that) {
case _PortableResourcesView() when $default != null:
return $default(_that.members,_that.scope,_that.layout,_that.location);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourcesView implements PortableResourcesView {
  const _PortableResourcesView({required  List<PortableResourceMember> members, required this.scope, required this.layout, this.location}): _members = members;
  

 final  List<PortableResourceMember> _members;
@override List<PortableResourceMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  PortablePresentationScope scope;
@override final  PortableResourcesLayoutKind layout;
/// The link field the members are linked at, when the binding has one.
@override final  skir.ValueLocation? location;

/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourcesViewCopyWith<_PortableResourcesView> get copyWith => __$PortableResourcesViewCopyWithImpl<_PortableResourcesView>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourcesView&&const DeepCollectionEquality().equals(other.members, _members)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_members),scope,layout,location);
}

@override
String toString() {
    return 'PortableResourcesView(members: $members, scope: $scope, layout: $layout, location: $location)';
}


}

/// @nodoc
abstract mixin class _$PortableResourcesViewCopyWith<$Res> implements $PortableResourcesViewCopyWith<$Res> {
  factory _$PortableResourcesViewCopyWith(_PortableResourcesView value, $Res Function(_PortableResourcesView) _then) = __$PortableResourcesViewCopyWithImpl;
@override @useResult
$Res call({
 List<PortableResourceMember> members, PortablePresentationScope scope, PortableResourcesLayoutKind layout, skir.ValueLocation? location
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$PortableResourcesViewCopyWithImpl<$Res>
    implements _$PortableResourcesViewCopyWith<$Res> {
  __$PortableResourcesViewCopyWithImpl(this._self, this._then);

  final _PortableResourcesView _self;
  final $Res Function(_PortableResourcesView) _then;

/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? members = null,Object? scope = null,Object? layout = null,Object? location = freezed,}) {
  return _then(_PortableResourcesView(
members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as PortableResourcesLayoutKind,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}

/// Create a copy of PortableResourcesView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$PortableResourcesGroup {

 skir.ValuePath get field; String get path; String get name; List<PortableResourceMember> get members;
/// Create a copy of PortableResourcesGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourcesGroupCopyWith<PortableResourcesGroup> get copyWith => _$PortableResourcesGroupCopyWithImpl<PortableResourcesGroup>(this as PortableResourcesGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourcesGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourcesGroup&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.members, _this.members));
}


@override
int get hashCode {
  final _this = this as PortableResourcesGroup;
  return Object.hash(runtimeType,_this.field,_this.path,_this.name,const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as PortableResourcesGroup;
  return 'PortableResourcesGroup(field: ${_this.field}, path: ${_this.path}, name: ${_this.name}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $PortableResourcesGroupCopyWith<$Res>  {
  factory $PortableResourcesGroupCopyWith(PortableResourcesGroup value, $Res Function(PortableResourcesGroup) _then) = _$PortableResourcesGroupCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath field, String path, String name, List<PortableResourceMember> members
});




}
/// @nodoc
class _$PortableResourcesGroupCopyWithImpl<$Res>
    implements $PortableResourcesGroupCopyWith<$Res> {
  _$PortableResourcesGroupCopyWithImpl(this._self, this._then);

  final PortableResourcesGroup _self;
  final $Res Function(PortableResourcesGroup) _then;

/// Create a copy of PortableResourcesGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? path = null,Object? name = null,Object? members = null,}) {
  return _then(PortableResourcesGroup(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableResourcesGroup].
extension PortableResourcesGroupPatterns on PortableResourcesGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableResourcesGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableResourcesGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableResourcesGroup value)  $default,){
final _that = this;
switch (_that) {
case _PortableResourcesGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableResourcesGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PortableResourcesGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValuePath field,  String path,  String name,  List<PortableResourceMember> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableResourcesGroup() when $default != null:
return $default(_that.field,_that.path,_that.name,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValuePath field,  String path,  String name,  List<PortableResourceMember> members)  $default,) {final _that = this;
switch (_that) {
case _PortableResourcesGroup():
return $default(_that.field,_that.path,_that.name,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValuePath field,  String path,  String name,  List<PortableResourceMember> members)?  $default,) {final _that = this;
switch (_that) {
case _PortableResourcesGroup() when $default != null:
return $default(_that.field,_that.path,_that.name,_that.members);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourcesGroup implements PortableResourcesGroup {
  const _PortableResourcesGroup({required this.field, required this.path, required this.name, required  List<PortableResourceMember> members}): _members = members;
  

@override final  skir.ValuePath field;
@override final  String path;
@override final  String name;
 final  List<PortableResourceMember> _members;
@override List<PortableResourceMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of PortableResourcesGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourcesGroupCopyWith<_PortableResourcesGroup> get copyWith => __$PortableResourcesGroupCopyWithImpl<_PortableResourcesGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourcesGroup&&(identical(other.field, field) || other.field == field)&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.members, _members));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field,path,name,const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'PortableResourcesGroup(field: $field, path: $path, name: $name, members: $members)';
}


}

/// @nodoc
abstract mixin class _$PortableResourcesGroupCopyWith<$Res> implements $PortableResourcesGroupCopyWith<$Res> {
  factory _$PortableResourcesGroupCopyWith(_PortableResourcesGroup value, $Res Function(_PortableResourcesGroup) _then) = __$PortableResourcesGroupCopyWithImpl;
@override @useResult
$Res call({
 skir.ValuePath field, String path, String name, List<PortableResourceMember> members
});




}
/// @nodoc
class __$PortableResourcesGroupCopyWithImpl<$Res>
    implements _$PortableResourcesGroupCopyWith<$Res> {
  __$PortableResourcesGroupCopyWithImpl(this._self, this._then);

  final _PortableResourcesGroup _self;
  final $Res Function(_PortableResourcesGroup) _then;

/// Create a copy of PortableResourcesGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? path = null,Object? name = null,Object? members = null,}) {
  return _then(_PortableResourcesGroup(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,
  ));
}


}

// dart format on
