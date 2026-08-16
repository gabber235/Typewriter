// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_surface.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorSurfaceDefinitionResolution {

 EditorDocument get document; DataPath get path; TypeRegistry? get registryOverride; TypeResult<_EditorSurfaceDefinition> get result;
/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSurfaceDefinitionResolutionCopyWith<_EditorSurfaceDefinitionResolution> get copyWith => __$EditorSurfaceDefinitionResolutionCopyWithImpl<_EditorSurfaceDefinitionResolution>(this as _EditorSurfaceDefinitionResolution, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSurfaceDefinitionResolution&&(identical(other.document, document) || other.document == document)&&(identical(other.path, path) || other.path == path)&&(identical(other.registryOverride, registryOverride) || other.registryOverride == registryOverride)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,document,path,registryOverride,result);

@override
String toString() {
  return '_EditorSurfaceDefinitionResolution(document: $document, path: $path, registryOverride: $registryOverride, result: $result)';
}


}

/// @nodoc
abstract mixin class _$EditorSurfaceDefinitionResolutionCopyWith<$Res>  {
  factory _$EditorSurfaceDefinitionResolutionCopyWith(_EditorSurfaceDefinitionResolution value, $Res Function(_EditorSurfaceDefinitionResolution) _then) = __$EditorSurfaceDefinitionResolutionCopyWithImpl;
@useResult
$Res call({
 EditorDocument document, DataPath path, TypeRegistry? registryOverride, TypeResult<_EditorSurfaceDefinition> result
});


$DataPathCopyWith<$Res> get path;$TypeResultCopyWith<_EditorSurfaceDefinition, $Res> get result;

}
/// @nodoc
class __$EditorSurfaceDefinitionResolutionCopyWithImpl<$Res>
    implements _$EditorSurfaceDefinitionResolutionCopyWith<$Res> {
  __$EditorSurfaceDefinitionResolutionCopyWithImpl(this._self, this._then);

  final _EditorSurfaceDefinitionResolution _self;
  final $Res Function(_EditorSurfaceDefinitionResolution) _then;

/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,Object? path = null,Object? registryOverride = freezed,Object? result = null,}) {
  return _then(_self.copyWith(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as EditorDocument,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,registryOverride: freezed == registryOverride ? _self.registryOverride : registryOverride // ignore: cast_nullable_to_non_nullable
as TypeRegistry?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TypeResult<_EditorSurfaceDefinition>,
  ));
}
/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeResultCopyWith<_EditorSurfaceDefinition, $Res> get result {
  
  return $TypeResultCopyWith<_EditorSurfaceDefinition, $Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [_EditorSurfaceDefinitionResolution].
extension _EditorSurfaceDefinitionResolutionPatterns on _EditorSurfaceDefinitionResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorSurfaceDefinitionResolutionData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorSurfaceDefinitionResolutionData value)  $default,){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorSurfaceDefinitionResolutionData value)?  $default,){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorDocument document,  DataPath path,  TypeRegistry? registryOverride,  TypeResult<_EditorSurfaceDefinition> result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData() when $default != null:
return $default(_that.document,_that.path,_that.registryOverride,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorDocument document,  DataPath path,  TypeRegistry? registryOverride,  TypeResult<_EditorSurfaceDefinition> result)  $default,) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData():
return $default(_that.document,_that.path,_that.registryOverride,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorDocument document,  DataPath path,  TypeRegistry? registryOverride,  TypeResult<_EditorSurfaceDefinition> result)?  $default,) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionResolutionData() when $default != null:
return $default(_that.document,_that.path,_that.registryOverride,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _EditorSurfaceDefinitionResolutionData extends _EditorSurfaceDefinitionResolution {
  const _EditorSurfaceDefinitionResolutionData({required this.document, required this.path, required this.registryOverride, required this.result}): super._();
  

@override final  EditorDocument document;
@override final  DataPath path;
@override final  TypeRegistry? registryOverride;
@override final  TypeResult<_EditorSurfaceDefinition> result;

/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSurfaceDefinitionResolutionDataCopyWith<_EditorSurfaceDefinitionResolutionData> get copyWith => __$EditorSurfaceDefinitionResolutionDataCopyWithImpl<_EditorSurfaceDefinitionResolutionData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSurfaceDefinitionResolutionData&&(identical(other.document, document) || other.document == document)&&(identical(other.path, path) || other.path == path)&&(identical(other.registryOverride, registryOverride) || other.registryOverride == registryOverride)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,document,path,registryOverride,result);

@override
String toString() {
  return '_EditorSurfaceDefinitionResolution(document: $document, path: $path, registryOverride: $registryOverride, result: $result)';
}


}

/// @nodoc
abstract mixin class _$EditorSurfaceDefinitionResolutionDataCopyWith<$Res> implements _$EditorSurfaceDefinitionResolutionCopyWith<$Res> {
  factory _$EditorSurfaceDefinitionResolutionDataCopyWith(_EditorSurfaceDefinitionResolutionData value, $Res Function(_EditorSurfaceDefinitionResolutionData) _then) = __$EditorSurfaceDefinitionResolutionDataCopyWithImpl;
@override @useResult
$Res call({
 EditorDocument document, DataPath path, TypeRegistry? registryOverride, TypeResult<_EditorSurfaceDefinition> result
});


@override $DataPathCopyWith<$Res> get path;@override $TypeResultCopyWith<_EditorSurfaceDefinition, $Res> get result;

}
/// @nodoc
class __$EditorSurfaceDefinitionResolutionDataCopyWithImpl<$Res>
    implements _$EditorSurfaceDefinitionResolutionDataCopyWith<$Res> {
  __$EditorSurfaceDefinitionResolutionDataCopyWithImpl(this._self, this._then);

  final _EditorSurfaceDefinitionResolutionData _self;
  final $Res Function(_EditorSurfaceDefinitionResolutionData) _then;

/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,Object? path = null,Object? registryOverride = freezed,Object? result = null,}) {
  return _then(_EditorSurfaceDefinitionResolutionData(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as EditorDocument,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,registryOverride: freezed == registryOverride ? _self.registryOverride : registryOverride // ignore: cast_nullable_to_non_nullable
as TypeRegistry?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TypeResult<_EditorSurfaceDefinition>,
  ));
}

/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of _EditorSurfaceDefinitionResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeResultCopyWith<_EditorSurfaceDefinition, $Res> get result {
  
  return $TypeResultCopyWith<_EditorSurfaceDefinition, $Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
mixin _$EditorSurfaceDefinition {

 EditorDocument get document; TypeRegistry get registry; TypeExpression get type; TypeExpression get bindingType; ResolvedPresentationDefinition? get selectedPresentation; PresentationNode get presentation;
/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSurfaceDefinitionCopyWith<_EditorSurfaceDefinition> get copyWith => __$EditorSurfaceDefinitionCopyWithImpl<_EditorSurfaceDefinition>(this as _EditorSurfaceDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSurfaceDefinition&&(identical(other.document, document) || other.document == document)&&(identical(other.registry, registry) || other.registry == registry)&&(identical(other.type, type) || other.type == type)&&(identical(other.bindingType, bindingType) || other.bindingType == bindingType)&&(identical(other.selectedPresentation, selectedPresentation) || other.selectedPresentation == selectedPresentation)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,document,registry,type,bindingType,selectedPresentation,presentation);

@override
String toString() {
  return '_EditorSurfaceDefinition(document: $document, registry: $registry, type: $type, bindingType: $bindingType, selectedPresentation: $selectedPresentation, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class _$EditorSurfaceDefinitionCopyWith<$Res>  {
  factory _$EditorSurfaceDefinitionCopyWith(_EditorSurfaceDefinition value, $Res Function(_EditorSurfaceDefinition) _then) = __$EditorSurfaceDefinitionCopyWithImpl;
@useResult
$Res call({
 EditorDocument document, TypeRegistry registry, TypeExpression type, TypeExpression bindingType, ResolvedPresentationDefinition? selectedPresentation, PresentationNode presentation
});


$TypeExpressionCopyWith<$Res> get type;$TypeExpressionCopyWith<$Res> get bindingType;$ResolvedPresentationDefinitionCopyWith<$Res>? get selectedPresentation;$PresentationNodeCopyWith<$Res> get presentation;

}
/// @nodoc
class __$EditorSurfaceDefinitionCopyWithImpl<$Res>
    implements _$EditorSurfaceDefinitionCopyWith<$Res> {
  __$EditorSurfaceDefinitionCopyWithImpl(this._self, this._then);

  final _EditorSurfaceDefinition _self;
  final $Res Function(_EditorSurfaceDefinition) _then;

/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,Object? registry = null,Object? type = null,Object? bindingType = null,Object? selectedPresentation = freezed,Object? presentation = null,}) {
  return _then(_self.copyWith(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as EditorDocument,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,bindingType: null == bindingType ? _self.bindingType : bindingType // ignore: cast_nullable_to_non_nullable
as TypeExpression,selectedPresentation: freezed == selectedPresentation ? _self.selectedPresentation : selectedPresentation // ignore: cast_nullable_to_non_nullable
as ResolvedPresentationDefinition?,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}
/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get bindingType {
  
  return $TypeExpressionCopyWith<$Res>(_self.bindingType, (value) {
    return _then(_self.copyWith(bindingType: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedPresentationDefinitionCopyWith<$Res>? get selectedPresentation {
    if (_self.selectedPresentation == null) {
    return null;
  }

  return $ResolvedPresentationDefinitionCopyWith<$Res>(_self.selectedPresentation!, (value) {
    return _then(_self.copyWith(selectedPresentation: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [_EditorSurfaceDefinition].
extension _EditorSurfaceDefinitionPatterns on _EditorSurfaceDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorSurfaceDefinitionData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorSurfaceDefinitionData value)  $default,){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorSurfaceDefinitionData value)?  $default,){
final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorDocument document,  TypeRegistry registry,  TypeExpression type,  TypeExpression bindingType,  ResolvedPresentationDefinition? selectedPresentation,  PresentationNode presentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData() when $default != null:
return $default(_that.document,_that.registry,_that.type,_that.bindingType,_that.selectedPresentation,_that.presentation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorDocument document,  TypeRegistry registry,  TypeExpression type,  TypeExpression bindingType,  ResolvedPresentationDefinition? selectedPresentation,  PresentationNode presentation)  $default,) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData():
return $default(_that.document,_that.registry,_that.type,_that.bindingType,_that.selectedPresentation,_that.presentation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorDocument document,  TypeRegistry registry,  TypeExpression type,  TypeExpression bindingType,  ResolvedPresentationDefinition? selectedPresentation,  PresentationNode presentation)?  $default,) {final _that = this;
switch (_that) {
case _EditorSurfaceDefinitionData() when $default != null:
return $default(_that.document,_that.registry,_that.type,_that.bindingType,_that.selectedPresentation,_that.presentation);case _:
  return null;

}
}

}

/// @nodoc


class _EditorSurfaceDefinitionData extends _EditorSurfaceDefinition {
  const _EditorSurfaceDefinitionData({required this.document, required this.registry, required this.type, required this.bindingType, required this.selectedPresentation, required this.presentation}): super._();
  

@override final  EditorDocument document;
@override final  TypeRegistry registry;
@override final  TypeExpression type;
@override final  TypeExpression bindingType;
@override final  ResolvedPresentationDefinition? selectedPresentation;
@override final  PresentationNode presentation;

/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSurfaceDefinitionDataCopyWith<_EditorSurfaceDefinitionData> get copyWith => __$EditorSurfaceDefinitionDataCopyWithImpl<_EditorSurfaceDefinitionData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSurfaceDefinitionData&&(identical(other.document, document) || other.document == document)&&(identical(other.registry, registry) || other.registry == registry)&&(identical(other.type, type) || other.type == type)&&(identical(other.bindingType, bindingType) || other.bindingType == bindingType)&&(identical(other.selectedPresentation, selectedPresentation) || other.selectedPresentation == selectedPresentation)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,document,registry,type,bindingType,selectedPresentation,presentation);

@override
String toString() {
  return '_EditorSurfaceDefinition(document: $document, registry: $registry, type: $type, bindingType: $bindingType, selectedPresentation: $selectedPresentation, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class _$EditorSurfaceDefinitionDataCopyWith<$Res> implements _$EditorSurfaceDefinitionCopyWith<$Res> {
  factory _$EditorSurfaceDefinitionDataCopyWith(_EditorSurfaceDefinitionData value, $Res Function(_EditorSurfaceDefinitionData) _then) = __$EditorSurfaceDefinitionDataCopyWithImpl;
@override @useResult
$Res call({
 EditorDocument document, TypeRegistry registry, TypeExpression type, TypeExpression bindingType, ResolvedPresentationDefinition? selectedPresentation, PresentationNode presentation
});


@override $TypeExpressionCopyWith<$Res> get type;@override $TypeExpressionCopyWith<$Res> get bindingType;@override $ResolvedPresentationDefinitionCopyWith<$Res>? get selectedPresentation;@override $PresentationNodeCopyWith<$Res> get presentation;

}
/// @nodoc
class __$EditorSurfaceDefinitionDataCopyWithImpl<$Res>
    implements _$EditorSurfaceDefinitionDataCopyWith<$Res> {
  __$EditorSurfaceDefinitionDataCopyWithImpl(this._self, this._then);

  final _EditorSurfaceDefinitionData _self;
  final $Res Function(_EditorSurfaceDefinitionData) _then;

/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,Object? registry = null,Object? type = null,Object? bindingType = null,Object? selectedPresentation = freezed,Object? presentation = null,}) {
  return _then(_EditorSurfaceDefinitionData(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as EditorDocument,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,bindingType: null == bindingType ? _self.bindingType : bindingType // ignore: cast_nullable_to_non_nullable
as TypeExpression,selectedPresentation: freezed == selectedPresentation ? _self.selectedPresentation : selectedPresentation // ignore: cast_nullable_to_non_nullable
as ResolvedPresentationDefinition?,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get bindingType {
  
  return $TypeExpressionCopyWith<$Res>(_self.bindingType, (value) {
    return _then(_self.copyWith(bindingType: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedPresentationDefinitionCopyWith<$Res>? get selectedPresentation {
    if (_self.selectedPresentation == null) {
    return null;
  }

  return $ResolvedPresentationDefinitionCopyWith<$Res>(_self.selectedPresentation!, (value) {
    return _then(_self.copyWith(selectedPresentation: value));
  });
}/// Create a copy of _EditorSurfaceDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

// dart format on
