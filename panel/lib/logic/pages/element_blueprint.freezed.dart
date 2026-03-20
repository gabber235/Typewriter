// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_blueprint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ElementBlueprint {

 String get id; String get name; String get description; String get extension; ObjectBlueprint get dataBlueprint;@ColorConverter() Color get color; String get icon; List<String> get tags; List<DataBlueprint>? get genericConstraints; DataBlueprint? get variableDataBlueprint; List<ContextKey> get contextKeys; List<ElementModifier> get modifiers;
/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementBlueprintCopyWith<ElementBlueprint> get copyWith => _$ElementBlueprintCopyWithImpl<ElementBlueprint>(this as ElementBlueprint, _$identity);

  /// Serializes this ElementBlueprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementBlueprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.extension, extension) || other.extension == extension)&&const DeepCollectionEquality().equals(other.dataBlueprint, dataBlueprint)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.genericConstraints, genericConstraints)&&(identical(other.variableDataBlueprint, variableDataBlueprint) || other.variableDataBlueprint == variableDataBlueprint)&&const DeepCollectionEquality().equals(other.contextKeys, contextKeys)&&const DeepCollectionEquality().equals(other.modifiers, modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,extension,const DeepCollectionEquality().hash(dataBlueprint),color,icon,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(genericConstraints),variableDataBlueprint,const DeepCollectionEquality().hash(contextKeys),const DeepCollectionEquality().hash(modifiers));

@override
String toString() {
  return 'ElementBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class $ElementBlueprintCopyWith<$Res>  {
  factory $ElementBlueprintCopyWith(ElementBlueprint value, $Res Function(ElementBlueprint) _then) = _$ElementBlueprintCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String extension, ObjectBlueprint dataBlueprint,@ColorConverter() Color color, String icon, List<String> tags, List<DataBlueprint>? genericConstraints, DataBlueprint? variableDataBlueprint, List<ContextKey> contextKeys, List<ElementModifier> modifiers
});


$DataBlueprintCopyWith<$Res>? get variableDataBlueprint;

}
/// @nodoc
class _$ElementBlueprintCopyWithImpl<$Res>
    implements $ElementBlueprintCopyWith<$Res> {
  _$ElementBlueprintCopyWithImpl(this._self, this._then);

  final ElementBlueprint _self;
  final $Res Function(ElementBlueprint) _then;

/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? extension = null,Object? dataBlueprint = freezed,Object? color = null,Object? icon = null,Object? tags = null,Object? genericConstraints = freezed,Object? variableDataBlueprint = freezed,Object? contextKeys = null,Object? modifiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,dataBlueprint: freezed == dataBlueprint ? _self.dataBlueprint : dataBlueprint // ignore: cast_nullable_to_non_nullable
as ObjectBlueprint,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,genericConstraints: freezed == genericConstraints ? _self.genericConstraints : genericConstraints // ignore: cast_nullable_to_non_nullable
as List<DataBlueprint>?,variableDataBlueprint: freezed == variableDataBlueprint ? _self.variableDataBlueprint : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint?,contextKeys: null == contextKeys ? _self.contextKeys : contextKeys // ignore: cast_nullable_to_non_nullable
as List<ContextKey>,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<ElementModifier>,
  ));
}
/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
    return null;
  }

  return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
    return _then(_self.copyWith(variableDataBlueprint: value));
  });
}
}


/// Adds pattern-matching-related methods to [ElementBlueprint].
extension ElementBlueprintPatterns on ElementBlueprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementBlueprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementBlueprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementBlueprint value)  $default,){
final _that = this;
switch (_that) {
case _ElementBlueprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementBlueprint value)?  $default,){
final _that = this;
switch (_that) {
case _ElementBlueprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<ElementModifier> modifiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementBlueprint() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<ElementModifier> modifiers)  $default,) {final _that = this;
switch (_that) {
case _ElementBlueprint():
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<ElementModifier> modifiers)?  $default,) {final _that = this;
switch (_that) {
case _ElementBlueprint() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ElementBlueprint implements ElementBlueprint {
  const _ElementBlueprint({required this.id, required this.name, required this.description, required this.extension, required this.dataBlueprint, @ColorConverter() this.color = Colors.grey, this.icon = "fa-solid:question-circle", final  List<String> tags = const <String>[], final  List<DataBlueprint>? genericConstraints = null, this.variableDataBlueprint = null, final  List<ContextKey> contextKeys = const [], final  List<ElementModifier> modifiers = const []}): _tags = tags,_genericConstraints = genericConstraints,_contextKeys = contextKeys,_modifiers = modifiers;
  factory _ElementBlueprint.fromJson(Map<String, dynamic> json) => _$ElementBlueprintFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  String extension;
@override final  ObjectBlueprint dataBlueprint;
@override@JsonKey()@ColorConverter() final  Color color;
@override@JsonKey() final  String icon;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<DataBlueprint>? _genericConstraints;
@override@JsonKey() List<DataBlueprint>? get genericConstraints {
  final value = _genericConstraints;
  if (value == null) return null;
  if (_genericConstraints is EqualUnmodifiableListView) return _genericConstraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  DataBlueprint? variableDataBlueprint;
 final  List<ContextKey> _contextKeys;
@override@JsonKey() List<ContextKey> get contextKeys {
  if (_contextKeys is EqualUnmodifiableListView) return _contextKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextKeys);
}

 final  List<ElementModifier> _modifiers;
@override@JsonKey() List<ElementModifier> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}


/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementBlueprintCopyWith<_ElementBlueprint> get copyWith => __$ElementBlueprintCopyWithImpl<_ElementBlueprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ElementBlueprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementBlueprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.extension, extension) || other.extension == extension)&&const DeepCollectionEquality().equals(other.dataBlueprint, dataBlueprint)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._genericConstraints, _genericConstraints)&&(identical(other.variableDataBlueprint, variableDataBlueprint) || other.variableDataBlueprint == variableDataBlueprint)&&const DeepCollectionEquality().equals(other._contextKeys, _contextKeys)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,extension,const DeepCollectionEquality().hash(dataBlueprint),color,icon,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_genericConstraints),variableDataBlueprint,const DeepCollectionEquality().hash(_contextKeys),const DeepCollectionEquality().hash(_modifiers));

@override
String toString() {
  return 'ElementBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class _$ElementBlueprintCopyWith<$Res> implements $ElementBlueprintCopyWith<$Res> {
  factory _$ElementBlueprintCopyWith(_ElementBlueprint value, $Res Function(_ElementBlueprint) _then) = __$ElementBlueprintCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String extension, ObjectBlueprint dataBlueprint,@ColorConverter() Color color, String icon, List<String> tags, List<DataBlueprint>? genericConstraints, DataBlueprint? variableDataBlueprint, List<ContextKey> contextKeys, List<ElementModifier> modifiers
});


@override $DataBlueprintCopyWith<$Res>? get variableDataBlueprint;

}
/// @nodoc
class __$ElementBlueprintCopyWithImpl<$Res>
    implements _$ElementBlueprintCopyWith<$Res> {
  __$ElementBlueprintCopyWithImpl(this._self, this._then);

  final _ElementBlueprint _self;
  final $Res Function(_ElementBlueprint) _then;

/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? extension = null,Object? dataBlueprint = freezed,Object? color = null,Object? icon = null,Object? tags = null,Object? genericConstraints = freezed,Object? variableDataBlueprint = freezed,Object? contextKeys = null,Object? modifiers = null,}) {
  return _then(_ElementBlueprint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,dataBlueprint: freezed == dataBlueprint ? _self.dataBlueprint : dataBlueprint // ignore: cast_nullable_to_non_nullable
as ObjectBlueprint,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,genericConstraints: freezed == genericConstraints ? _self._genericConstraints : genericConstraints // ignore: cast_nullable_to_non_nullable
as List<DataBlueprint>?,variableDataBlueprint: freezed == variableDataBlueprint ? _self.variableDataBlueprint : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint?,contextKeys: null == contextKeys ? _self._contextKeys : contextKeys // ignore: cast_nullable_to_non_nullable
as List<ContextKey>,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<ElementModifier>,
  ));
}

/// Create a copy of ElementBlueprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
    return null;
  }

  return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
    return _then(_self.copyWith(variableDataBlueprint: value));
  });
}
}


/// @nodoc
mixin _$ContextKey {

 String get name; String get klassName; DataBlueprint get blueprint;
/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextKeyCopyWith<ContextKey> get copyWith => _$ContextKeyCopyWithImpl<ContextKey>(this as ContextKey, _$identity);

  /// Serializes this ContextKey to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextKey&&(identical(other.name, name) || other.name == name)&&(identical(other.klassName, klassName) || other.klassName == klassName)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,klassName,blueprint);

@override
String toString() {
  return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
}


}

/// @nodoc
abstract mixin class $ContextKeyCopyWith<$Res>  {
  factory $ContextKeyCopyWith(ContextKey value, $Res Function(ContextKey) _then) = _$ContextKeyCopyWithImpl;
@useResult
$Res call({
 String name, String klassName, DataBlueprint blueprint
});


$DataBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class _$ContextKeyCopyWithImpl<$Res>
    implements $ContextKeyCopyWith<$Res> {
  _$ContextKeyCopyWithImpl(this._self, this._then);

  final ContextKey _self;
  final $Res Function(ContextKey) _then;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? klassName = null,Object? blueprint = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,klassName: null == klassName ? _self.klassName : klassName // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint,
  ));
}
/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res> get blueprint {
  
  return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContextKey].
extension ContextKeyPatterns on ContextKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextKey value)  $default,){
final _that = this;
switch (_that) {
case _ContextKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextKey value)?  $default,){
final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String klassName,  DataBlueprint blueprint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
return $default(_that.name,_that.klassName,_that.blueprint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String klassName,  DataBlueprint blueprint)  $default,) {final _that = this;
switch (_that) {
case _ContextKey():
return $default(_that.name,_that.klassName,_that.blueprint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String klassName,  DataBlueprint blueprint)?  $default,) {final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
return $default(_that.name,_that.klassName,_that.blueprint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextKey implements ContextKey {
  const _ContextKey({required this.name, required this.klassName, required this.blueprint});
  factory _ContextKey.fromJson(Map<String, dynamic> json) => _$ContextKeyFromJson(json);

@override final  String name;
@override final  String klassName;
@override final  DataBlueprint blueprint;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextKeyCopyWith<_ContextKey> get copyWith => __$ContextKeyCopyWithImpl<_ContextKey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextKeyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextKey&&(identical(other.name, name) || other.name == name)&&(identical(other.klassName, klassName) || other.klassName == klassName)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,klassName,blueprint);

@override
String toString() {
  return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
}


}

/// @nodoc
abstract mixin class _$ContextKeyCopyWith<$Res> implements $ContextKeyCopyWith<$Res> {
  factory _$ContextKeyCopyWith(_ContextKey value, $Res Function(_ContextKey) _then) = __$ContextKeyCopyWithImpl;
@override @useResult
$Res call({
 String name, String klassName, DataBlueprint blueprint
});


@override $DataBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class __$ContextKeyCopyWithImpl<$Res>
    implements _$ContextKeyCopyWith<$Res> {
  __$ContextKeyCopyWithImpl(this._self, this._then);

  final _ContextKey _self;
  final $Res Function(_ContextKey) _then;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? klassName = null,Object? blueprint = null,}) {
  return _then(_ContextKey(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,klassName: null == klassName ? _self.klassName : klassName // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint,
  ));
}

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res> get blueprint {
  
  return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}

ElementModifier _$ElementModifierFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'default':
          return _EmptyModifier.fromJson(
            json
          );
                case 'deprecated':
          return DeprecatedModifier.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'ElementModifier',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$ElementModifier {



  /// Serializes this ElementModifier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementModifier);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ElementModifier()';
}


}

/// @nodoc
class $ElementModifierCopyWith<$Res>  {
$ElementModifierCopyWith(ElementModifier _, $Res Function(ElementModifier) __);
}


/// Adds pattern-matching-related methods to [ElementModifier].
extension ElementModifierPatterns on ElementModifier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmptyModifier value)?  $default,{TResult Function( DeprecatedModifier value)?  deprecated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default(_that);case DeprecatedModifier() when deprecated != null:
return deprecated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmptyModifier value)  $default,{required TResult Function( DeprecatedModifier value)  deprecated,}){
final _that = this;
switch (_that) {
case _EmptyModifier():
return $default(_that);case DeprecatedModifier():
return deprecated(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmptyModifier value)?  $default,{TResult? Function( DeprecatedModifier value)?  deprecated,}){
final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default(_that);case DeprecatedModifier() when deprecated != null:
return deprecated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function()?  $default,{TResult Function( String reason)?  deprecated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default();case DeprecatedModifier() when deprecated != null:
return deprecated(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function()  $default,{required TResult Function( String reason)  deprecated,}) {final _that = this;
switch (_that) {
case _EmptyModifier():
return $default();case DeprecatedModifier():
return deprecated(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function()?  $default,{TResult? Function( String reason)?  deprecated,}) {final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default();case DeprecatedModifier() when deprecated != null:
return deprecated(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmptyModifier implements ElementModifier {
  const _EmptyModifier({final  String? $type}): $type = $type ?? 'default';
  factory _EmptyModifier.fromJson(Map<String, dynamic> json) => _$EmptyModifierFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$EmptyModifierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmptyModifier);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ElementModifier()';
}


}




/// @nodoc
@JsonSerializable()

class DeprecatedModifier implements ElementModifier {
  const DeprecatedModifier({this.reason = "", final  String? $type}): $type = $type ?? 'deprecated';
  factory DeprecatedModifier.fromJson(Map<String, dynamic> json) => _$DeprecatedModifierFromJson(json);

@JsonKey() final  String reason;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ElementModifier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeprecatedModifierCopyWith<DeprecatedModifier> get copyWith => _$DeprecatedModifierCopyWithImpl<DeprecatedModifier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeprecatedModifierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeprecatedModifier&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'ElementModifier.deprecated(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $DeprecatedModifierCopyWith<$Res> implements $ElementModifierCopyWith<$Res> {
  factory $DeprecatedModifierCopyWith(DeprecatedModifier value, $Res Function(DeprecatedModifier) _then) = _$DeprecatedModifierCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$DeprecatedModifierCopyWithImpl<$Res>
    implements $DeprecatedModifierCopyWith<$Res> {
  _$DeprecatedModifierCopyWithImpl(this._self, this._then);

  final DeprecatedModifier _self;
  final $Res Function(DeprecatedModifier) _then;

/// Create a copy of ElementModifier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(DeprecatedModifier(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
