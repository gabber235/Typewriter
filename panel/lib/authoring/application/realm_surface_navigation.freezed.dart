// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_surface_navigation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceSurfaceLayout {

 bool get workspace; skir.ResourceId? get rail;
/// Create a copy of ResourceSurfaceLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceSurfaceLayoutCopyWith<ResourceSurfaceLayout> get copyWith => _$ResourceSurfaceLayoutCopyWithImpl<ResourceSurfaceLayout>(this as ResourceSurfaceLayout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceSurfaceLayout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceSurfaceLayout&&(identical(other.workspace, _this.workspace) || other.workspace == _this.workspace)&&(identical(other.rail, _this.rail) || other.rail == _this.rail));
}


@override
int get hashCode {
  final _this = this as ResourceSurfaceLayout;
  return Object.hash(runtimeType,_this.workspace,_this.rail);
}

@override
String toString() {
  final _this = this as ResourceSurfaceLayout;
  return 'ResourceSurfaceLayout(workspace: ${_this.workspace}, rail: ${_this.rail})';
}


}

/// @nodoc
abstract mixin class $ResourceSurfaceLayoutCopyWith<$Res>  {
  factory $ResourceSurfaceLayoutCopyWith(ResourceSurfaceLayout value, $Res Function(ResourceSurfaceLayout) _then) = _$ResourceSurfaceLayoutCopyWithImpl;
@useResult
$Res call({
 bool workspace, skir.ResourceId? rail
});




}
/// @nodoc
class _$ResourceSurfaceLayoutCopyWithImpl<$Res>
    implements $ResourceSurfaceLayoutCopyWith<$Res> {
  _$ResourceSurfaceLayoutCopyWithImpl(this._self, this._then);

  final ResourceSurfaceLayout _self;
  final $Res Function(ResourceSurfaceLayout) _then;

/// Create a copy of ResourceSurfaceLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspace = null,Object? rail = freezed,}) {
  return _then(ResourceSurfaceLayout(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as bool,rail: freezed == rail ? _self.rail : rail // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceSurfaceLayout].
extension ResourceSurfaceLayoutPatterns on ResourceSurfaceLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceSurfaceLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceSurfaceLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceSurfaceLayout value)  $default,){
final _that = this;
switch (_that) {
case _ResourceSurfaceLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceSurfaceLayout value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceSurfaceLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool workspace,  skir.ResourceId? rail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceSurfaceLayout() when $default != null:
return $default(_that.workspace,_that.rail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool workspace,  skir.ResourceId? rail)  $default,) {final _that = this;
switch (_that) {
case _ResourceSurfaceLayout():
return $default(_that.workspace,_that.rail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool workspace,  skir.ResourceId? rail)?  $default,) {final _that = this;
switch (_that) {
case _ResourceSurfaceLayout() when $default != null:
return $default(_that.workspace,_that.rail);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceSurfaceLayout implements ResourceSurfaceLayout {
  const _ResourceSurfaceLayout({required this.workspace, this.rail});
  

@override final  bool workspace;
@override final  skir.ResourceId? rail;

/// Create a copy of ResourceSurfaceLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceSurfaceLayoutCopyWith<_ResourceSurfaceLayout> get copyWith => __$ResourceSurfaceLayoutCopyWithImpl<_ResourceSurfaceLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceSurfaceLayout&&(identical(other.workspace, workspace) || other.workspace == workspace)&&(identical(other.rail, rail) || other.rail == rail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,workspace,rail);
}

@override
String toString() {
    return 'ResourceSurfaceLayout(workspace: $workspace, rail: $rail)';
}


}

/// @nodoc
abstract mixin class _$ResourceSurfaceLayoutCopyWith<$Res> implements $ResourceSurfaceLayoutCopyWith<$Res> {
  factory _$ResourceSurfaceLayoutCopyWith(_ResourceSurfaceLayout value, $Res Function(_ResourceSurfaceLayout) _then) = __$ResourceSurfaceLayoutCopyWithImpl;
@override @useResult
$Res call({
 bool workspace, skir.ResourceId? rail
});




}
/// @nodoc
class __$ResourceSurfaceLayoutCopyWithImpl<$Res>
    implements _$ResourceSurfaceLayoutCopyWith<$Res> {
  __$ResourceSurfaceLayoutCopyWithImpl(this._self, this._then);

  final _ResourceSurfaceLayout _self;
  final $Res Function(_ResourceSurfaceLayout) _then;

/// Create a copy of ResourceSurfaceLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspace = null,Object? rail = freezed,}) {
  return _then(_ResourceSurfaceLayout(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as bool,rail: freezed == rail ? _self.rail : rail // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,
  ));
}


}

/// @nodoc
mixin _$ResourceCreationField {

/// The owning link field a created member joins.
 skir.ValueLocation get owner; skir.TypeDefinitionId get type;/// The action label, such as "New Page".
 String get label;
/// Create a copy of ResourceCreationField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCreationFieldCopyWith<ResourceCreationField> get copyWith => _$ResourceCreationFieldCopyWithImpl<ResourceCreationField>(this as ResourceCreationField, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceCreationField;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCreationField&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.label, _this.label) || other.label == _this.label));
}


@override
int get hashCode {
  final _this = this as ResourceCreationField;
  return Object.hash(runtimeType,_this.owner,_this.type,_this.label);
}

@override
String toString() {
  final _this = this as ResourceCreationField;
  return 'ResourceCreationField(owner: ${_this.owner}, type: ${_this.type}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $ResourceCreationFieldCopyWith<$Res>  {
  factory $ResourceCreationFieldCopyWith(ResourceCreationField value, $Res Function(ResourceCreationField) _then) = _$ResourceCreationFieldCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation owner, skir.TypeDefinitionId type, String label
});




}
/// @nodoc
class _$ResourceCreationFieldCopyWithImpl<$Res>
    implements $ResourceCreationFieldCopyWith<$Res> {
  _$ResourceCreationFieldCopyWithImpl(this._self, this._then);

  final ResourceCreationField _self;
  final $Res Function(ResourceCreationField) _then;

/// Create a copy of ResourceCreationField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? type = null,Object? label = null,}) {
  return _then(ResourceCreationField(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeDefinitionId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceCreationField].
extension ResourceCreationFieldPatterns on ResourceCreationField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceCreationField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceCreationField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceCreationField value)  $default,){
final _that = this;
switch (_that) {
case _ResourceCreationField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceCreationField value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceCreationField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValueLocation owner,  skir.TypeDefinitionId type,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceCreationField() when $default != null:
return $default(_that.owner,_that.type,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValueLocation owner,  skir.TypeDefinitionId type,  String label)  $default,) {final _that = this;
switch (_that) {
case _ResourceCreationField():
return $default(_that.owner,_that.type,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValueLocation owner,  skir.TypeDefinitionId type,  String label)?  $default,) {final _that = this;
switch (_that) {
case _ResourceCreationField() when $default != null:
return $default(_that.owner,_that.type,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceCreationField implements ResourceCreationField {
  const _ResourceCreationField({required this.owner, required this.type, required this.label});
  

/// The owning link field a created member joins.
@override final  skir.ValueLocation owner;
@override final  skir.TypeDefinitionId type;
/// The action label, such as "New Page".
@override final  String label;

/// Create a copy of ResourceCreationField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCreationFieldCopyWith<_ResourceCreationField> get copyWith => __$ResourceCreationFieldCopyWithImpl<_ResourceCreationField>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceCreationField&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,type,label);
}

@override
String toString() {
    return 'ResourceCreationField(owner: $owner, type: $type, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ResourceCreationFieldCopyWith<$Res> implements $ResourceCreationFieldCopyWith<$Res> {
  factory _$ResourceCreationFieldCopyWith(_ResourceCreationField value, $Res Function(_ResourceCreationField) _then) = __$ResourceCreationFieldCopyWithImpl;
@override @useResult
$Res call({
 skir.ValueLocation owner, skir.TypeDefinitionId type, String label
});




}
/// @nodoc
class __$ResourceCreationFieldCopyWithImpl<$Res>
    implements _$ResourceCreationFieldCopyWith<$Res> {
  __$ResourceCreationFieldCopyWithImpl(this._self, this._then);

  final _ResourceCreationField _self;
  final $Res Function(_ResourceCreationField) _then;

/// Create a copy of ResourceCreationField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? type = null,Object? label = null,}) {
  return _then(_ResourceCreationField(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeDefinitionId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ResourceCrumbChoice {

 skir.ResourceId get resource; skir.ResourceAppearance get appearance;
/// Create a copy of ResourceCrumbChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCrumbChoiceCopyWith<ResourceCrumbChoice> get copyWith => _$ResourceCrumbChoiceCopyWithImpl<ResourceCrumbChoice>(this as ResourceCrumbChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceCrumbChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCrumbChoice&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance));
}


@override
int get hashCode {
  final _this = this as ResourceCrumbChoice;
  return Object.hash(runtimeType,_this.resource,_this.appearance);
}

@override
String toString() {
  final _this = this as ResourceCrumbChoice;
  return 'ResourceCrumbChoice(resource: ${_this.resource}, appearance: ${_this.appearance})';
}


}

/// @nodoc
abstract mixin class $ResourceCrumbChoiceCopyWith<$Res>  {
  factory $ResourceCrumbChoiceCopyWith(ResourceCrumbChoice value, $Res Function(ResourceCrumbChoice) _then) = _$ResourceCrumbChoiceCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.ResourceAppearance appearance
});




}
/// @nodoc
class _$ResourceCrumbChoiceCopyWithImpl<$Res>
    implements $ResourceCrumbChoiceCopyWith<$Res> {
  _$ResourceCrumbChoiceCopyWithImpl(this._self, this._then);

  final ResourceCrumbChoice _self;
  final $Res Function(ResourceCrumbChoice) _then;

/// Create a copy of ResourceCrumbChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? appearance = null,}) {
  return _then(ResourceCrumbChoice(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.ResourceAppearance,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceCrumbChoice].
extension ResourceCrumbChoicePatterns on ResourceCrumbChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceCrumbChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceCrumbChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceCrumbChoice value)  $default,){
final _that = this;
switch (_that) {
case _ResourceCrumbChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceCrumbChoice value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceCrumbChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.ResourceAppearance appearance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceCrumbChoice() when $default != null:
return $default(_that.resource,_that.appearance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.ResourceAppearance appearance)  $default,) {final _that = this;
switch (_that) {
case _ResourceCrumbChoice():
return $default(_that.resource,_that.appearance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.ResourceAppearance appearance)?  $default,) {final _that = this;
switch (_that) {
case _ResourceCrumbChoice() when $default != null:
return $default(_that.resource,_that.appearance);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceCrumbChoice implements ResourceCrumbChoice {
  const _ResourceCrumbChoice({required this.resource, required this.appearance});
  

@override final  skir.ResourceId resource;
@override final  skir.ResourceAppearance appearance;

/// Create a copy of ResourceCrumbChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCrumbChoiceCopyWith<_ResourceCrumbChoice> get copyWith => __$ResourceCrumbChoiceCopyWithImpl<_ResourceCrumbChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceCrumbChoice&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,appearance);
}

@override
String toString() {
    return 'ResourceCrumbChoice(resource: $resource, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class _$ResourceCrumbChoiceCopyWith<$Res> implements $ResourceCrumbChoiceCopyWith<$Res> {
  factory _$ResourceCrumbChoiceCopyWith(_ResourceCrumbChoice value, $Res Function(_ResourceCrumbChoice) _then) = __$ResourceCrumbChoiceCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.ResourceAppearance appearance
});




}
/// @nodoc
class __$ResourceCrumbChoiceCopyWithImpl<$Res>
    implements _$ResourceCrumbChoiceCopyWith<$Res> {
  __$ResourceCrumbChoiceCopyWithImpl(this._self, this._then);

  final _ResourceCrumbChoice _self;
  final $Res Function(_ResourceCrumbChoice) _then;

/// Create a copy of ResourceCrumbChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? appearance = null,}) {
  return _then(_ResourceCrumbChoice(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.ResourceAppearance,
  ));
}


}

/// @nodoc
mixin _$ResourceCrumb {

 skir.ResourceId get resource; List<skir.ResourceId> get siblings;
/// Create a copy of ResourceCrumb
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCrumbCopyWith<ResourceCrumb> get copyWith => _$ResourceCrumbCopyWithImpl<ResourceCrumb>(this as ResourceCrumb, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceCrumb;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCrumb&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&const DeepCollectionEquality().equals(other.siblings, _this.siblings));
}


@override
int get hashCode {
  final _this = this as ResourceCrumb;
  return Object.hash(runtimeType,_this.resource,const DeepCollectionEquality().hash(_this.siblings));
}

@override
String toString() {
  final _this = this as ResourceCrumb;
  return 'ResourceCrumb(resource: ${_this.resource}, siblings: ${_this.siblings})';
}


}

/// @nodoc
abstract mixin class $ResourceCrumbCopyWith<$Res>  {
  factory $ResourceCrumbCopyWith(ResourceCrumb value, $Res Function(ResourceCrumb) _then) = _$ResourceCrumbCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, List<skir.ResourceId> siblings
});




}
/// @nodoc
class _$ResourceCrumbCopyWithImpl<$Res>
    implements $ResourceCrumbCopyWith<$Res> {
  _$ResourceCrumbCopyWithImpl(this._self, this._then);

  final ResourceCrumb _self;
  final $Res Function(ResourceCrumb) _then;

/// Create a copy of ResourceCrumb
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? siblings = null,}) {
  return _then(ResourceCrumb(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,siblings: null == siblings ? _self.siblings : siblings // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceCrumb].
extension ResourceCrumbPatterns on ResourceCrumb {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceCrumb value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceCrumb() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceCrumb value)  $default,){
final _that = this;
switch (_that) {
case _ResourceCrumb():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceCrumb value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceCrumb() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  List<skir.ResourceId> siblings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceCrumb() when $default != null:
return $default(_that.resource,_that.siblings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  List<skir.ResourceId> siblings)  $default,) {final _that = this;
switch (_that) {
case _ResourceCrumb():
return $default(_that.resource,_that.siblings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  List<skir.ResourceId> siblings)?  $default,) {final _that = this;
switch (_that) {
case _ResourceCrumb() when $default != null:
return $default(_that.resource,_that.siblings);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceCrumb implements ResourceCrumb {
  const _ResourceCrumb({required this.resource, required  List<skir.ResourceId> siblings}): _siblings = siblings;
  

@override final  skir.ResourceId resource;
 final  List<skir.ResourceId> _siblings;
@override List<skir.ResourceId> get siblings {
  if (_siblings is EqualUnmodifiableListView) return _siblings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_siblings);
}


/// Create a copy of ResourceCrumb
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCrumbCopyWith<_ResourceCrumb> get copyWith => __$ResourceCrumbCopyWithImpl<_ResourceCrumb>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceCrumb&&(identical(other.resource, resource) || other.resource == resource)&&const DeepCollectionEquality().equals(other.siblings, _siblings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,const DeepCollectionEquality().hash(_siblings));
}

@override
String toString() {
    return 'ResourceCrumb(resource: $resource, siblings: $siblings)';
}


}

/// @nodoc
abstract mixin class _$ResourceCrumbCopyWith<$Res> implements $ResourceCrumbCopyWith<$Res> {
  factory _$ResourceCrumbCopyWith(_ResourceCrumb value, $Res Function(_ResourceCrumb) _then) = __$ResourceCrumbCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, List<skir.ResourceId> siblings
});




}
/// @nodoc
class __$ResourceCrumbCopyWithImpl<$Res>
    implements _$ResourceCrumbCopyWith<$Res> {
  __$ResourceCrumbCopyWithImpl(this._self, this._then);

  final _ResourceCrumb _self;
  final $Res Function(_ResourceCrumb) _then;

/// Create a copy of ResourceCrumb
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? siblings = null,}) {
  return _then(_ResourceCrumb(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,siblings: null == siblings ? _self._siblings : siblings // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}


}

// dart format on
