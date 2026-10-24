// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_creation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceCreationRequest {

 skir.ResourceId get id; skir.ResourceDefinitionId get definition; skir.TypeSelection get configuration; List<skir.FieldValue> get supplied;
/// Create a copy of ResourceCreationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCreationRequestCopyWith<ResourceCreationRequest> get copyWith => _$ResourceCreationRequestCopyWithImpl<ResourceCreationRequest>(this as ResourceCreationRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceCreationRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCreationRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration)&&const DeepCollectionEquality().equals(other.supplied, _this.supplied));
}


@override
int get hashCode {
  final _this = this as ResourceCreationRequest;
  return Object.hash(runtimeType,_this.id,_this.definition,_this.configuration,const DeepCollectionEquality().hash(_this.supplied));
}

@override
String toString() {
  final _this = this as ResourceCreationRequest;
  return 'ResourceCreationRequest(id: ${_this.id}, definition: ${_this.definition}, configuration: ${_this.configuration}, supplied: ${_this.supplied})';
}


}

/// @nodoc
abstract mixin class $ResourceCreationRequestCopyWith<$Res>  {
  factory $ResourceCreationRequestCopyWith(ResourceCreationRequest value, $Res Function(ResourceCreationRequest) _then) = _$ResourceCreationRequestCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId id, skir.ResourceDefinitionId definition, skir.TypeSelection configuration, List<skir.FieldValue> supplied
});




}
/// @nodoc
class _$ResourceCreationRequestCopyWithImpl<$Res>
    implements $ResourceCreationRequestCopyWith<$Res> {
  _$ResourceCreationRequestCopyWithImpl(this._self, this._then);

  final ResourceCreationRequest _self;
  final $Res Function(ResourceCreationRequest) _then;

/// Create a copy of ResourceCreationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? definition = null,Object? configuration = null,Object? supplied = null,}) {
  return _then(ResourceCreationRequest(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,id: freezed == id ? _self.id! : id // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,supplied: null == supplied ? _self.supplied : supplied // ignore: cast_nullable_to_non_nullable
as List<skir.FieldValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceCreationRequest].
extension ResourceCreationRequestPatterns on ResourceCreationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ResourceCreationRequest value)?  data,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceCreationRequest() when data != null:
return data(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ResourceCreationRequest value)  data,}){
final _that = this;
switch (_that) {
case _ResourceCreationRequest():
return data(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ResourceCreationRequest value)?  data,}){
final _that = this;
switch (_that) {
case _ResourceCreationRequest() when data != null:
return data(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.TypeSelection configuration,  List<skir.FieldValue> supplied)?  data,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceCreationRequest() when data != null:
return data(_that.id,_that.definition,_that.configuration,_that.supplied);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.TypeSelection configuration,  List<skir.FieldValue> supplied)  data,}) {final _that = this;
switch (_that) {
case _ResourceCreationRequest():
return data(_that.id,_that.definition,_that.configuration,_that.supplied);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ResourceId id,  skir.ResourceDefinitionId definition,  skir.TypeSelection configuration,  List<skir.FieldValue> supplied)?  data,}) {final _that = this;
switch (_that) {
case _ResourceCreationRequest() when data != null:
return data(_that.id,_that.definition,_that.configuration,_that.supplied);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceCreationRequest implements ResourceCreationRequest {
  const _ResourceCreationRequest({required this.id, required this.definition, required this.configuration,  List<skir.FieldValue> supplied = const []}): _supplied = supplied;
  

@override final  skir.ResourceId id;
@override final  skir.ResourceDefinitionId definition;
@override final  skir.TypeSelection configuration;
 final  List<skir.FieldValue> _supplied;
@override@JsonKey() List<skir.FieldValue> get supplied {
  if (_supplied is EqualUnmodifiableListView) return _supplied;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supplied);
}


/// Create a copy of ResourceCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCreationRequestCopyWith<_ResourceCreationRequest> get copyWith => __$ResourceCreationRequestCopyWithImpl<_ResourceCreationRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceCreationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.configuration, configuration) || other.configuration == configuration)&&const DeepCollectionEquality().equals(other.supplied, _supplied));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,definition,configuration,const DeepCollectionEquality().hash(_supplied));
}

@override
String toString() {
    return 'ResourceCreationRequest.data(id: $id, definition: $definition, configuration: $configuration, supplied: $supplied)';
}


}

/// @nodoc
abstract mixin class _$ResourceCreationRequestCopyWith<$Res> implements $ResourceCreationRequestCopyWith<$Res> {
  factory _$ResourceCreationRequestCopyWith(_ResourceCreationRequest value, $Res Function(_ResourceCreationRequest) _then) = __$ResourceCreationRequestCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId id, skir.ResourceDefinitionId definition, skir.TypeSelection configuration, List<skir.FieldValue> supplied
});




}
/// @nodoc
class __$ResourceCreationRequestCopyWithImpl<$Res>
    implements _$ResourceCreationRequestCopyWith<$Res> {
  __$ResourceCreationRequestCopyWithImpl(this._self, this._then);

  final _ResourceCreationRequest _self;
  final $Res Function(_ResourceCreationRequest) _then;

/// Create a copy of ResourceCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? definition = null,Object? configuration = null,Object? supplied = null,}) {
  return _then(_ResourceCreationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,supplied: null == supplied ? _self._supplied : supplied // ignore: cast_nullable_to_non_nullable
as List<skir.FieldValue>,
  ));
}


}

/// @nodoc
mixin _$ResourceCreationTemplate {

 skir.ResourceDefinitionId get definition; skir.TypeSelection get configuration;
/// Create a copy of ResourceCreationTemplate
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definition = null,Object? configuration = null,}) {
  return _then(ResourceCreationTemplate(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceCreationTemplate].
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definition = null,Object? configuration = null,}) {
  return _then(_ResourceCreationTemplate(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.ResourceDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}


}

/// @nodoc
mixin _$PendingCreation {

 ResourceCreationRequest get request; CreationContext get context; skir.PreparationStep get step;
/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingCreationCopyWith<_PendingCreation> get copyWith => __$PendingCreationCopyWithImpl<_PendingCreation>(this as _PendingCreation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _PendingCreation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingCreation&&(identical(other.request, _this.request) || other.request == _this.request)&&(identical(other.context, _this.context) || other.context == _this.context)&&(identical(other.step, _this.step) || other.step == _this.step));
}


@override
int get hashCode {
  final _this = this as _PendingCreation;
  return Object.hash(runtimeType,_this.request,_this.context,_this.step);
}

@override
String toString() {
  final _this = this as _PendingCreation;
  return '_PendingCreation(request: ${_this.request}, context: ${_this.context}, step: ${_this.step})';
}


}

/// @nodoc
abstract mixin class _$PendingCreationCopyWith<$Res>  {
  factory _$PendingCreationCopyWith(_PendingCreation value, $Res Function(_PendingCreation) _then) = __$PendingCreationCopyWithImpl;
@useResult
$Res call({
 ResourceCreationRequest request, CreationContext context, skir.PreparationStep step
});


$ResourceCreationRequestCopyWith<$Res> get request;$CreationContextCopyWith<$Res> get context;

}
/// @nodoc
class __$PendingCreationCopyWithImpl<$Res>
    implements _$PendingCreationCopyWith<$Res> {
  __$PendingCreationCopyWithImpl(this._self, this._then);

  final _PendingCreation _self;
  final $Res Function(_PendingCreation) _then;

/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? context = null,Object? step = null,}) {
  return _then(_PendingCreation(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ResourceCreationRequest,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as CreationContext,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as skir.PreparationStep,
  ));
}
/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceCreationRequestCopyWith<$Res> get request {
  
  return $ResourceCreationRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreationContextCopyWith<$Res> get context {
  
  return $CreationContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [_PendingCreation].
extension _PendingCreationPatterns on _PendingCreation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __PendingCreation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __PendingCreation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __PendingCreation value)  $default,){
final _that = this;
switch (_that) {
case __PendingCreation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __PendingCreation value)?  $default,){
final _that = this;
switch (_that) {
case __PendingCreation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResourceCreationRequest request,  CreationContext context,  skir.PreparationStep step)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __PendingCreation() when $default != null:
return $default(_that.request,_that.context,_that.step);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResourceCreationRequest request,  CreationContext context,  skir.PreparationStep step)  $default,) {final _that = this;
switch (_that) {
case __PendingCreation():
return $default(_that.request,_that.context,_that.step);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResourceCreationRequest request,  CreationContext context,  skir.PreparationStep step)?  $default,) {final _that = this;
switch (_that) {
case __PendingCreation() when $default != null:
return $default(_that.request,_that.context,_that.step);case _:
  return null;

}
}

}

/// @nodoc


class __PendingCreation implements _PendingCreation {
  const __PendingCreation({required this.request, required this.context, required this.step});
  

@override final  ResourceCreationRequest request;
@override final  CreationContext context;
@override final  skir.PreparationStep step;

/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_PendingCreationCopyWith<__PendingCreation> get copyWith => __$_PendingCreationCopyWithImpl<__PendingCreation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __PendingCreation&&(identical(other.request, request) || other.request == request)&&(identical(other.context, context) || other.context == context)&&(identical(other.step, step) || other.step == step));
}


@override
int get hashCode {
    return Object.hash(runtimeType,request,context,step);
}

@override
String toString() {
    return '_PendingCreation(request: $request, context: $context, step: $step)';
}


}

/// @nodoc
abstract mixin class _$_PendingCreationCopyWith<$Res> implements _$PendingCreationCopyWith<$Res> {
  factory _$_PendingCreationCopyWith(__PendingCreation value, $Res Function(__PendingCreation) _then) = __$_PendingCreationCopyWithImpl;
@override @useResult
$Res call({
 ResourceCreationRequest request, CreationContext context, skir.PreparationStep step
});


@override $ResourceCreationRequestCopyWith<$Res> get request;@override $CreationContextCopyWith<$Res> get context;

}
/// @nodoc
class __$_PendingCreationCopyWithImpl<$Res>
    implements _$_PendingCreationCopyWith<$Res> {
  __$_PendingCreationCopyWithImpl(this._self, this._then);

  final __PendingCreation _self;
  final $Res Function(__PendingCreation) _then;

/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? context = null,Object? step = null,}) {
  return _then(__PendingCreation(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ResourceCreationRequest,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as CreationContext,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as skir.PreparationStep,
  ));
}

/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceCreationRequestCopyWith<$Res> get request {
  
  return $ResourceCreationRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}/// Create a copy of _PendingCreation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreationContextCopyWith<$Res> get context {
  
  return $CreationContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
