// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_creation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreatedAuthoringResource {

 AuthoringScope get scope; skir.ResourceId get id; skir.ResourceDefinitionId get definition; skir.AuthoringRecord get content;
/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedAuthoringResourceCopyWith<CreatedAuthoringResource> get copyWith => _$CreatedAuthoringResourceCopyWithImpl<CreatedAuthoringResource>(this as CreatedAuthoringResource, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreatedAuthoringResource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedAuthoringResource&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.content, _this.content) || other.content == _this.content));
}


@override
int get hashCode {
  final _this = this as CreatedAuthoringResource;
  return Object.hash(runtimeType,_this.scope,_this.id,_this.definition,_this.content);
}

@override
String toString() {
  final _this = this as CreatedAuthoringResource;
  return 'CreatedAuthoringResource(scope: ${_this.scope}, id: ${_this.id}, definition: ${_this.definition}, content: ${_this.content})';
}


}

/// @nodoc
abstract mixin class $CreatedAuthoringResourceCopyWith<$Res>  {
  factory $CreatedAuthoringResourceCopyWith(CreatedAuthoringResource value, $Res Function(CreatedAuthoringResource) _then) = _$CreatedAuthoringResourceCopyWithImpl;
@useResult
$Res call({
 AuthoringScope scope, skir.ResourceId id, skir.ResourceDefinitionId definition, skir.AuthoringRecord content
});


$AuthoringScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$CreatedAuthoringResourceCopyWithImpl<$Res>
    implements $CreatedAuthoringResourceCopyWith<$Res> {
  _$CreatedAuthoringResourceCopyWithImpl(this._self, this._then);

  final CreatedAuthoringResource _self;
  final $Res Function(CreatedAuthoringResource) _then;

/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? id = null,Object? definition = null,Object? content = null,}) {
  return _then(CreatedAuthoringResource(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as AuthoringScope,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as skir.AuthoringRecord,
  ));
}
/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<$Res> get scope {

  return $AuthoringScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern matching related methods to [CreatedAuthoringResource].
extension CreatedAuthoringResourcePatterns on CreatedAuthoringResource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedAuthoringResource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedAuthoringResource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedAuthoringResource value)  $default,){
final _that = this;
switch (_that) {
case _CreatedAuthoringResource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedAuthoringResource value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedAuthoringResource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringScope scope,  skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.AuthoringRecord content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedAuthoringResource() when $default != null:
return $default(_that.scope,_that.id,_that.definition,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringScope scope,  skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.AuthoringRecord content)  $default,) {final _that = this;
switch (_that) {
case _CreatedAuthoringResource():
return $default(_that.scope,_that.id,_that.definition,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringScope scope,  skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.AuthoringRecord content)?  $default,) {final _that = this;
switch (_that) {
case _CreatedAuthoringResource() when $default != null:
return $default(_that.scope,_that.id,_that.definition,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _CreatedAuthoringResource implements CreatedAuthoringResource {
  const _CreatedAuthoringResource({required this.scope, required this.id, required this.definition, required this.content});


@override final  AuthoringScope scope;
@override final  skir.ResourceId id;
@override final  skir.ResourceDefinitionId definition;
@override final  skir.AuthoringRecord content;

/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedAuthoringResourceCopyWith<_CreatedAuthoringResource> get copyWith => __$CreatedAuthoringResourceCopyWithImpl<_CreatedAuthoringResource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedAuthoringResource&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.id, id) || other.id == id)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scope,id,definition,content);
}

@override
String toString() {
    return 'CreatedAuthoringResource(scope: $scope, id: $id, definition: $definition, content: $content)';
}


}

/// @nodoc
abstract mixin class _$CreatedAuthoringResourceCopyWith<$Res> implements $CreatedAuthoringResourceCopyWith<$Res> {
  factory _$CreatedAuthoringResourceCopyWith(_CreatedAuthoringResource value, $Res Function(_CreatedAuthoringResource) _then) = __$CreatedAuthoringResourceCopyWithImpl;
@override @useResult
$Res call({
 AuthoringScope scope, skir.ResourceId id, skir.ResourceDefinitionId definition, skir.AuthoringRecord content
});


@override $AuthoringScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$CreatedAuthoringResourceCopyWithImpl<$Res>
    implements _$CreatedAuthoringResourceCopyWith<$Res> {
  __$CreatedAuthoringResourceCopyWithImpl(this._self, this._then);

  final _CreatedAuthoringResource _self;
  final $Res Function(_CreatedAuthoringResource) _then;

/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? id = null,Object? definition = null,Object? content = null,}) {
  return _then(_CreatedAuthoringResource(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as AuthoringScope,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as skir.AuthoringRecord,
  ));
}

/// Create a copy of CreatedAuthoringResource
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<$Res> get scope {

  return $AuthoringScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$ResourceCreationTemplate {

 skir.ResourceDefinitionId get definition; skir.TypeSelection get configuration;
/// Create a copy of ResourceCreationTemplate
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCreationTemplateCopyWith<ResourceCreationTemplate> get copyWith => _$ResourceCreationTemplateCopyWithImpl<ResourceCreationTemplate>(this as ResourceCreationTemplate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceCreationTemplate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCreationTemplate&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration));
}


@override
int get hashCode {
  final _this = this as ResourceCreationTemplate;
  return Object.hash(runtimeType,_this.definition,_this.configuration);
}

@override
String toString() {
  final _this = this as ResourceCreationTemplate;
  return 'ResourceCreationTemplate(definition: ${_this.definition}, configuration: ${_this.configuration})';
}


}

/// @nodoc
abstract mixin class $ResourceCreationTemplateCopyWith<$Res>  {
  factory $ResourceCreationTemplateCopyWith(ResourceCreationTemplate value, $Res Function(ResourceCreationTemplate) _then) = _$ResourceCreationTemplateCopyWithImpl;
@useResult
$Res call({
 skir.ResourceDefinitionId definition, skir.TypeSelection configuration
});




}
/// @nodoc
class _$ResourceCreationTemplateCopyWithImpl<$Res>
    implements $ResourceCreationTemplateCopyWith<$Res> {
  _$ResourceCreationTemplateCopyWithImpl(this._self, this._then);

  final ResourceCreationTemplate _self;
  final $Res Function(ResourceCreationTemplate) _then;

/// Create a copy of ResourceCreationTemplate
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definition = null,Object? configuration = null,}) {
  return _then(ResourceCreationTemplate(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}

}


/// Adds pattern matching related methods to [ResourceCreationTemplate].
extension ResourceCreationTemplatePatterns on ResourceCreationTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceCreationTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceCreationTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceCreationTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ResourceCreationTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceCreationTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceCreationTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceDefinitionId definition,  skir.TypeSelection configuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceCreationTemplate() when $default != null:
return $default(_that.definition,_that.configuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceDefinitionId definition,  skir.TypeSelection configuration)  $default,) {final _that = this;
switch (_that) {
case _ResourceCreationTemplate():
return $default(_that.definition,_that.configuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceDefinitionId definition,  skir.TypeSelection configuration)?  $default,) {final _that = this;
switch (_that) {
case _ResourceCreationTemplate() when $default != null:
return $default(_that.definition,_that.configuration);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceCreationTemplate implements ResourceCreationTemplate {
  const _ResourceCreationTemplate({required this.definition, required this.configuration});


@override final  skir.ResourceDefinitionId definition;
@override final  skir.TypeSelection configuration;

/// Create a copy of ResourceCreationTemplate
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCreationTemplateCopyWith<_ResourceCreationTemplate> get copyWith => __$ResourceCreationTemplateCopyWithImpl<_ResourceCreationTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceCreationTemplate&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.configuration, configuration) || other.configuration == configuration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,definition,configuration);
}

@override
String toString() {
    return 'ResourceCreationTemplate(definition: $definition, configuration: $configuration)';
}


}

/// @nodoc
abstract mixin class _$ResourceCreationTemplateCopyWith<$Res> implements $ResourceCreationTemplateCopyWith<$Res> {
  factory _$ResourceCreationTemplateCopyWith(_ResourceCreationTemplate value, $Res Function(_ResourceCreationTemplate) _then) = __$ResourceCreationTemplateCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceDefinitionId definition, skir.TypeSelection configuration
});




}
/// @nodoc
class __$ResourceCreationTemplateCopyWithImpl<$Res>
    implements _$ResourceCreationTemplateCopyWith<$Res> {
  __$ResourceCreationTemplateCopyWithImpl(this._self, this._then);

  final _ResourceCreationTemplate _self;
  final $Res Function(_ResourceCreationTemplate) _then;

/// Create a copy of ResourceCreationTemplate
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definition = null,Object? configuration = null,}) {
  return _then(_ResourceCreationTemplate(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}


}

// dart format on
