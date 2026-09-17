// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationInput {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationInput);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PresentationInput()';
}


}

/// @nodoc
class $PresentationInputCopyWith<$Res>  {
$PresentationInputCopyWith(PresentationInput _, $Res Function(PresentationInput) __);
}


/// Adds pattern-matching-related methods to [PresentationInput].
extension PresentationInputPatterns on PresentationInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PresentationValueInput value)?  value,TResult Function( PresentationEditInput value)?  edit,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PresentationValueInput() when value != null:
return value(_that);case PresentationEditInput() when edit != null:
return edit(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PresentationValueInput value)  value,required TResult Function( PresentationEditInput value)  edit,}){
final _that = this;
switch (_that) {
case PresentationValueInput():
return value(_that);case PresentationEditInput():
return edit(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PresentationValueInput value)?  value,TResult? Function( PresentationEditInput value)?  edit,}){
final _that = this;
switch (_that) {
case PresentationValueInput() when value != null:
return value(_that);case PresentationEditInput() when edit != null:
return edit(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypeExpression type,  EditorValue value)?  value,TResult Function( EditOwner owner,  DataPath path)?  edit,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PresentationValueInput() when value != null:
return value(_that.type,_that.value);case PresentationEditInput() when edit != null:
return edit(_that.owner,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypeExpression type,  EditorValue value)  value,required TResult Function( EditOwner owner,  DataPath path)  edit,}) {final _that = this;
switch (_that) {
case PresentationValueInput():
return value(_that.type,_that.value);case PresentationEditInput():
return edit(_that.owner,_that.path);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypeExpression type,  EditorValue value)?  value,TResult? Function( EditOwner owner,  DataPath path)?  edit,}) {final _that = this;
switch (_that) {
case PresentationValueInput() when value != null:
return value(_that.type,_that.value);case PresentationEditInput() when edit != null:
return edit(_that.owner,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class PresentationValueInput implements PresentationInput {
  const PresentationValueInput({required this.type, required this.value});
  

 final  TypeExpression type;
 final  EditorValue value;

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationValueInputCopyWith<PresentationValueInput> get copyWith => _$PresentationValueInputCopyWithImpl<PresentationValueInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationValueInput&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,value);
}

@override
String toString() {
    return 'PresentationInput.value(type: $type, value: $value)';
}


}

/// @nodoc
abstract mixin class $PresentationValueInputCopyWith<$Res> implements $PresentationInputCopyWith<$Res> {
  factory $PresentationValueInputCopyWith(PresentationValueInput value, $Res Function(PresentationValueInput) _then) = _$PresentationValueInputCopyWithImpl;
@useResult
$Res call({
 TypeExpression type, EditorValue value
});


$TypeExpressionCopyWith<$Res> get type;$EditorValueCopyWith<$Res> get value;

}
/// @nodoc
class _$PresentationValueInputCopyWithImpl<$Res>
    implements $PresentationValueInputCopyWith<$Res> {
  _$PresentationValueInputCopyWithImpl(this._self, this._then);

  final PresentationValueInput _self;
  final $Res Function(PresentationValueInput) _then;

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,}) {
  return _then(PresentationValueInput(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EditorValue,
  ));
}

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorValueCopyWith<$Res> get value {
  
  return $EditorValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class PresentationEditInput implements PresentationInput {
  const PresentationEditInput(this.owner, {this.path = DataPath.root});
  

 final  EditOwner owner;
@JsonKey() final  DataPath path;

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationEditInputCopyWith<PresentationEditInput> get copyWith => _$PresentationEditInputCopyWithImpl<PresentationEditInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationEditInput&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,path);
}

@override
String toString() {
    return 'PresentationInput.edit(owner: $owner, path: $path)';
}


}

/// @nodoc
abstract mixin class $PresentationEditInputCopyWith<$Res> implements $PresentationInputCopyWith<$Res> {
  factory $PresentationEditInputCopyWith(PresentationEditInput value, $Res Function(PresentationEditInput) _then) = _$PresentationEditInputCopyWithImpl;
@useResult
$Res call({
 EditOwner owner, DataPath path
});


$DataPathCopyWith<$Res> get path;

}
/// @nodoc
class _$PresentationEditInputCopyWithImpl<$Res>
    implements $PresentationEditInputCopyWith<$Res> {
  _$PresentationEditInputCopyWithImpl(this._self, this._then);

  final PresentationEditInput _self;
  final $Res Function(PresentationEditInput) _then;

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? path = null,}) {
  return _then(PresentationEditInput(
null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as EditOwner,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,
  ));
}

/// Create a copy of PresentationInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {
  
  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}
}

/// @nodoc
mixin _$PresentationModel {

 TypeCatalog get catalog; Map<BindingId, PresentationInput> get inputs; PresentationNode get root; Map<EditOwner, String> get ownerLabels; List<PresentationDefinition> get presentations; PresentationCollections get collections; List<TypeDiagnostic> get diagnostics;
/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationModelCopyWith<PresentationModel> get copyWith => _$PresentationModelCopyWithImpl<PresentationModel>(this as PresentationModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationModel&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&const DeepCollectionEquality().equals(other.inputs, _this.inputs)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.ownerLabels, _this.ownerLabels)&&const DeepCollectionEquality().equals(other.presentations, _this.presentations)&&(identical(other.collections, _this.collections) || other.collections == _this.collections)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as PresentationModel;
  return Object.hash(runtimeType,_this.catalog,const DeepCollectionEquality().hash(_this.inputs),_this.root,const DeepCollectionEquality().hash(_this.ownerLabels),const DeepCollectionEquality().hash(_this.presentations),_this.collections,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as PresentationModel;
  return 'PresentationModel(catalog: ${_this.catalog}, inputs: ${_this.inputs}, root: ${_this.root}, ownerLabels: ${_this.ownerLabels}, presentations: ${_this.presentations}, collections: ${_this.collections}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $PresentationModelCopyWith<$Res>  {
  factory $PresentationModelCopyWith(PresentationModel value, $Res Function(PresentationModel) _then) = _$PresentationModelCopyWithImpl;
@useResult
$Res call({
 TypeCatalog catalog, Map<BindingId, PresentationInput> inputs, PresentationNode root, Map<EditOwner, String> ownerLabels, List<PresentationDefinition> presentations, PresentationCollections collections, List<TypeDiagnostic> diagnostics
});


$TypeCatalogCopyWith<$Res> get catalog;$PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class _$PresentationModelCopyWithImpl<$Res>
    implements $PresentationModelCopyWith<$Res> {
  _$PresentationModelCopyWithImpl(this._self, this._then);

  final PresentationModel _self;
  final $Res Function(PresentationModel) _then;

/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? inputs = null,Object? root = null,Object? ownerLabels = null,Object? presentations = null,Object? collections = null,Object? diagnostics = null,}) {
  return _then(PresentationModel(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,inputs: null == inputs ? _self.inputs : inputs // ignore: cast_nullable_to_non_nullable
as Map<BindingId, PresentationInput>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,ownerLabels: null == ownerLabels ? _self.ownerLabels : ownerLabels // ignore: cast_nullable_to_non_nullable
as Map<EditOwner, String>,presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as List<PresentationDefinition>,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as PresentationCollections,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}
/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {
  
  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationModel].
extension PresentationModelPatterns on PresentationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationModel value)  $default,){
final _that = this;
switch (_that) {
case _PresentationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationModel value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeCatalog catalog,  Map<BindingId, PresentationInput> inputs,  PresentationNode root,  Map<EditOwner, String> ownerLabels,  List<PresentationDefinition> presentations,  PresentationCollections collections,  List<TypeDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationModel() when $default != null:
return $default(_that.catalog,_that.inputs,_that.root,_that.ownerLabels,_that.presentations,_that.collections,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeCatalog catalog,  Map<BindingId, PresentationInput> inputs,  PresentationNode root,  Map<EditOwner, String> ownerLabels,  List<PresentationDefinition> presentations,  PresentationCollections collections,  List<TypeDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _PresentationModel():
return $default(_that.catalog,_that.inputs,_that.root,_that.ownerLabels,_that.presentations,_that.collections,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeCatalog catalog,  Map<BindingId, PresentationInput> inputs,  PresentationNode root,  Map<EditOwner, String> ownerLabels,  List<PresentationDefinition> presentations,  PresentationCollections collections,  List<TypeDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _PresentationModel() when $default != null:
return $default(_that.catalog,_that.inputs,_that.root,_that.ownerLabels,_that.presentations,_that.collections,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationModel extends PresentationModel {
  const _PresentationModel({required this.catalog, required  Map<BindingId, PresentationInput> inputs, required this.root,  Map<EditOwner, String> ownerLabels = const {},  List<PresentationDefinition> presentations = const [], this.collections = const PresentationCollections.empty(),  List<TypeDiagnostic> diagnostics = const []}): _inputs = inputs,_ownerLabels = ownerLabels,_presentations = presentations,_diagnostics = diagnostics,super._();
  

@override final  TypeCatalog catalog;
 final  Map<BindingId, PresentationInput> _inputs;
@override Map<BindingId, PresentationInput> get inputs {
  if (_inputs is EqualUnmodifiableMapView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_inputs);
}

@override final  PresentationNode root;
 final  Map<EditOwner, String> _ownerLabels;
@override@JsonKey() Map<EditOwner, String> get ownerLabels {
  if (_ownerLabels is EqualUnmodifiableMapView) return _ownerLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownerLabels);
}

 final  List<PresentationDefinition> _presentations;
@override@JsonKey() List<PresentationDefinition> get presentations {
  if (_presentations is EqualUnmodifiableListView) return _presentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presentations);
}

@override@JsonKey() final  PresentationCollections collections;
 final  List<TypeDiagnostic> _diagnostics;
@override@JsonKey() List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationModelCopyWith<_PresentationModel> get copyWith => __$PresentationModelCopyWithImpl<_PresentationModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationModel&&(identical(other.catalog, catalog) || other.catalog == catalog)&&const DeepCollectionEquality().equals(other.inputs, _inputs)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.ownerLabels, _ownerLabels)&&const DeepCollectionEquality().equals(other.presentations, _presentations)&&(identical(other.collections, collections) || other.collections == collections)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,const DeepCollectionEquality().hash(_inputs),root,const DeepCollectionEquality().hash(_ownerLabels),const DeepCollectionEquality().hash(_presentations),collections,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PresentationModel(catalog: $catalog, inputs: $inputs, root: $root, ownerLabels: $ownerLabels, presentations: $presentations, collections: $collections, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$PresentationModelCopyWith<$Res> implements $PresentationModelCopyWith<$Res> {
  factory _$PresentationModelCopyWith(_PresentationModel value, $Res Function(_PresentationModel) _then) = __$PresentationModelCopyWithImpl;
@override @useResult
$Res call({
 TypeCatalog catalog, Map<BindingId, PresentationInput> inputs, PresentationNode root, Map<EditOwner, String> ownerLabels, List<PresentationDefinition> presentations, PresentationCollections collections, List<TypeDiagnostic> diagnostics
});


@override $TypeCatalogCopyWith<$Res> get catalog;@override $PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class __$PresentationModelCopyWithImpl<$Res>
    implements _$PresentationModelCopyWith<$Res> {
  __$PresentationModelCopyWithImpl(this._self, this._then);

  final _PresentationModel _self;
  final $Res Function(_PresentationModel) _then;

/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? inputs = null,Object? root = null,Object? ownerLabels = null,Object? presentations = null,Object? collections = null,Object? diagnostics = null,}) {
  return _then(_PresentationModel(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as Map<BindingId, PresentationInput>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,ownerLabels: null == ownerLabels ? _self._ownerLabels : ownerLabels // ignore: cast_nullable_to_non_nullable
as Map<EditOwner, String>,presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as List<PresentationDefinition>,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as PresentationCollections,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}

/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {
  
  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of PresentationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

// dart format on
