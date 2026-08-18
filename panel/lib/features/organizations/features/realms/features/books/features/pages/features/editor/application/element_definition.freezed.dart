// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ElementDefinition {

 ResolvedTypeRef get rootType; String get name; String get description; IconValue get icon; Color get color; ElementDeprecation? get deprecation;
/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementDefinitionCopyWith<ElementDefinition> get copyWith => _$ElementDefinitionCopyWithImpl<ElementDefinition>(this as ElementDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementDefinition&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.deprecation, deprecation) || other.deprecation == deprecation));
}


@override
int get hashCode => Object.hash(runtimeType,rootType,name,description,icon,color,deprecation);

@override
String toString() {
  return 'ElementDefinition(rootType: $rootType, name: $name, description: $description, icon: $icon, color: $color, deprecation: $deprecation)';
}


}

/// @nodoc
abstract mixin class $ElementDefinitionCopyWith<$Res>  {
  factory $ElementDefinitionCopyWith(ElementDefinition value, $Res Function(ElementDefinition) _then) = _$ElementDefinitionCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef rootType, String name, String description, IconValue icon, Color color, ElementDeprecation? deprecation
});


$ResolvedTypeRefCopyWith<$Res> get rootType;$IconValueCopyWith<$Res> get icon;$ElementDeprecationCopyWith<$Res>? get deprecation;

}
/// @nodoc
class _$ElementDefinitionCopyWithImpl<$Res>
    implements $ElementDefinitionCopyWith<$Res> {
  _$ElementDefinitionCopyWithImpl(this._self, this._then);

  final ElementDefinition _self;
  final $Res Function(ElementDefinition) _then;

/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootType = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? deprecation = freezed,}) {
  return _then(_self.copyWith(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,deprecation: freezed == deprecation ? _self.deprecation : deprecation // ignore: cast_nullable_to_non_nullable
as ElementDeprecation?,
  ));
}
/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementDeprecationCopyWith<$Res>? get deprecation {
    if (_self.deprecation == null) {
    return null;
  }

  return $ElementDeprecationCopyWith<$Res>(_self.deprecation!, (value) {
    return _then(_self.copyWith(deprecation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ElementDefinition].
extension ElementDefinitionPatterns on ElementDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ElementDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ElementDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  String name,  String description,  IconValue icon,  Color color,  ElementDeprecation? deprecation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementDefinition() when $default != null:
return $default(_that.rootType,_that.name,_that.description,_that.icon,_that.color,_that.deprecation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  String name,  String description,  IconValue icon,  Color color,  ElementDeprecation? deprecation)  $default,) {final _that = this;
switch (_that) {
case _ElementDefinition():
return $default(_that.rootType,_that.name,_that.description,_that.icon,_that.color,_that.deprecation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef rootType,  String name,  String description,  IconValue icon,  Color color,  ElementDeprecation? deprecation)?  $default,) {final _that = this;
switch (_that) {
case _ElementDefinition() when $default != null:
return $default(_that.rootType,_that.name,_that.description,_that.icon,_that.color,_that.deprecation);case _:
  return null;

}
}

}

/// @nodoc


class _ElementDefinition implements ElementDefinition {
  const _ElementDefinition({required this.rootType, required this.name, required this.description, required this.icon, this.color = Colors.grey, this.deprecation}): assert(name != "", 'Name must not be empty.');
  

@override final  ResolvedTypeRef rootType;
@override final  String name;
@override final  String description;
@override final  IconValue icon;
@override@JsonKey() final  Color color;
@override final  ElementDeprecation? deprecation;

/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementDefinitionCopyWith<_ElementDefinition> get copyWith => __$ElementDefinitionCopyWithImpl<_ElementDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementDefinition&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.deprecation, deprecation) || other.deprecation == deprecation));
}


@override
int get hashCode => Object.hash(runtimeType,rootType,name,description,icon,color,deprecation);

@override
String toString() {
  return 'ElementDefinition(rootType: $rootType, name: $name, description: $description, icon: $icon, color: $color, deprecation: $deprecation)';
}


}

/// @nodoc
abstract mixin class _$ElementDefinitionCopyWith<$Res> implements $ElementDefinitionCopyWith<$Res> {
  factory _$ElementDefinitionCopyWith(_ElementDefinition value, $Res Function(_ElementDefinition) _then) = __$ElementDefinitionCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef rootType, String name, String description, IconValue icon, Color color, ElementDeprecation? deprecation
});


@override $ResolvedTypeRefCopyWith<$Res> get rootType;@override $IconValueCopyWith<$Res> get icon;@override $ElementDeprecationCopyWith<$Res>? get deprecation;

}
/// @nodoc
class __$ElementDefinitionCopyWithImpl<$Res>
    implements _$ElementDefinitionCopyWith<$Res> {
  __$ElementDefinitionCopyWithImpl(this._self, this._then);

  final _ElementDefinition _self;
  final $Res Function(_ElementDefinition) _then;

/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootType = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? deprecation = freezed,}) {
  return _then(_ElementDefinition(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,deprecation: freezed == deprecation ? _self.deprecation : deprecation // ignore: cast_nullable_to_non_nullable
as ElementDeprecation?,
  ));
}

/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of ElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementDeprecationCopyWith<$Res>? get deprecation {
    if (_self.deprecation == null) {
    return null;
  }

  return $ElementDeprecationCopyWith<$Res>(_self.deprecation!, (value) {
    return _then(_self.copyWith(deprecation: value));
  });
}
}

/// @nodoc
mixin _$ElementDeprecation {

 String get reason;
/// Create a copy of ElementDeprecation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementDeprecationCopyWith<ElementDeprecation> get copyWith => _$ElementDeprecationCopyWithImpl<ElementDeprecation>(this as ElementDeprecation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementDeprecation&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'ElementDeprecation(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ElementDeprecationCopyWith<$Res>  {
  factory $ElementDeprecationCopyWith(ElementDeprecation value, $Res Function(ElementDeprecation) _then) = _$ElementDeprecationCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$ElementDeprecationCopyWithImpl<$Res>
    implements $ElementDeprecationCopyWith<$Res> {
  _$ElementDeprecationCopyWithImpl(this._self, this._then);

  final ElementDeprecation _self;
  final $Res Function(ElementDeprecation) _then;

/// Create a copy of ElementDeprecation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ElementDeprecation].
extension ElementDeprecationPatterns on ElementDeprecation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementDeprecation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementDeprecation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementDeprecation value)  $default,){
final _that = this;
switch (_that) {
case _ElementDeprecation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementDeprecation value)?  $default,){
final _that = this;
switch (_that) {
case _ElementDeprecation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementDeprecation() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason)  $default,) {final _that = this;
switch (_that) {
case _ElementDeprecation():
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason)?  $default,) {final _that = this;
switch (_that) {
case _ElementDeprecation() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _ElementDeprecation implements ElementDeprecation {
  const _ElementDeprecation({this.reason = ""});
  

@override@JsonKey() final  String reason;

/// Create a copy of ElementDeprecation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementDeprecationCopyWith<_ElementDeprecation> get copyWith => __$ElementDeprecationCopyWithImpl<_ElementDeprecation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementDeprecation&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'ElementDeprecation(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ElementDeprecationCopyWith<$Res> implements $ElementDeprecationCopyWith<$Res> {
  factory _$ElementDeprecationCopyWith(_ElementDeprecation value, $Res Function(_ElementDeprecation) _then) = __$ElementDeprecationCopyWithImpl;
@override @useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$ElementDeprecationCopyWithImpl<$Res>
    implements _$ElementDeprecationCopyWith<$Res> {
  __$ElementDeprecationCopyWithImpl(this._self, this._then);

  final _ElementDeprecation _self;
  final $Res Function(_ElementDeprecation) _then;

/// Create a copy of ElementDeprecation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_ElementDeprecation(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
