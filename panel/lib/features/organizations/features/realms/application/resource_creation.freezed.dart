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
