// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_element_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ElementAvailability {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementAvailability);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ElementAvailability()';
}


}

/// @nodoc
class $ElementAvailabilityCopyWith<$Res>  {
$ElementAvailabilityCopyWith(ElementAvailability _, $Res Function(ElementAvailability) __);
}


/// Adds pattern-matching-related methods to [ElementAvailability].
extension ElementAvailabilityPatterns on ElementAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ElementAlwaysAvailable value)?  always,TResult Function( ElementFactAvailability value)?  fact,TResult Function( ElementAllAvailability value)?  all,TResult Function( ElementAnyAvailability value)?  any,TResult Function( ElementNotAvailability value)?  not,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ElementAlwaysAvailable() when always != null:
return always(_that);case ElementFactAvailability() when fact != null:
return fact(_that);case ElementAllAvailability() when all != null:
return all(_that);case ElementAnyAvailability() when any != null:
return any(_that);case ElementNotAvailability() when not != null:
return not(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ElementAlwaysAvailable value)  always,required TResult Function( ElementFactAvailability value)  fact,required TResult Function( ElementAllAvailability value)  all,required TResult Function( ElementAnyAvailability value)  any,required TResult Function( ElementNotAvailability value)  not,}){
final _that = this;
switch (_that) {
case ElementAlwaysAvailable():
return always(_that);case ElementFactAvailability():
return fact(_that);case ElementAllAvailability():
return all(_that);case ElementAnyAvailability():
return any(_that);case ElementNotAvailability():
return not(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ElementAlwaysAvailable value)?  always,TResult? Function( ElementFactAvailability value)?  fact,TResult? Function( ElementAllAvailability value)?  all,TResult? Function( ElementAnyAvailability value)?  any,TResult? Function( ElementNotAvailability value)?  not,}){
final _that = this;
switch (_that) {
case ElementAlwaysAvailable() when always != null:
return always(_that);case ElementFactAvailability() when fact != null:
return fact(_that);case ElementAllAvailability() when all != null:
return all(_that);case ElementAnyAvailability() when any != null:
return any(_that);case ElementNotAvailability() when not != null:
return not(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  always,TResult Function( String key,  String expected)?  fact,TResult Function( List<ElementAvailability> expressions)?  all,TResult Function( List<ElementAvailability> expressions)?  any,TResult Function( ElementAvailability expression)?  not,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ElementAlwaysAvailable() when always != null:
return always();case ElementFactAvailability() when fact != null:
return fact(_that.key,_that.expected);case ElementAllAvailability() when all != null:
return all(_that.expressions);case ElementAnyAvailability() when any != null:
return any(_that.expressions);case ElementNotAvailability() when not != null:
return not(_that.expression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  always,required TResult Function( String key,  String expected)  fact,required TResult Function( List<ElementAvailability> expressions)  all,required TResult Function( List<ElementAvailability> expressions)  any,required TResult Function( ElementAvailability expression)  not,}) {final _that = this;
switch (_that) {
case ElementAlwaysAvailable():
return always();case ElementFactAvailability():
return fact(_that.key,_that.expected);case ElementAllAvailability():
return all(_that.expressions);case ElementAnyAvailability():
return any(_that.expressions);case ElementNotAvailability():
return not(_that.expression);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  always,TResult? Function( String key,  String expected)?  fact,TResult? Function( List<ElementAvailability> expressions)?  all,TResult? Function( List<ElementAvailability> expressions)?  any,TResult? Function( ElementAvailability expression)?  not,}) {final _that = this;
switch (_that) {
case ElementAlwaysAvailable() when always != null:
return always();case ElementFactAvailability() when fact != null:
return fact(_that.key,_that.expected);case ElementAllAvailability() when all != null:
return all(_that.expressions);case ElementAnyAvailability() when any != null:
return any(_that.expressions);case ElementNotAvailability() when not != null:
return not(_that.expression);case _:
  return null;

}
}

}

/// @nodoc


class ElementAlwaysAvailable implements ElementAvailability {
  const ElementAlwaysAvailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementAlwaysAvailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ElementAvailability.always()';
}


}




/// @nodoc


class ElementFactAvailability implements ElementAvailability {
  const ElementFactAvailability({required this.key, required this.expected});
  

 final  String key;
 final  String expected;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementFactAvailabilityCopyWith<ElementFactAvailability> get copyWith => _$ElementFactAvailabilityCopyWithImpl<ElementFactAvailability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementFactAvailability&&(identical(other.key, key) || other.key == key)&&(identical(other.expected, expected) || other.expected == expected));
}


@override
int get hashCode => Object.hash(runtimeType,key,expected);

@override
String toString() {
  return 'ElementAvailability.fact(key: $key, expected: $expected)';
}


}

/// @nodoc
abstract mixin class $ElementFactAvailabilityCopyWith<$Res> implements $ElementAvailabilityCopyWith<$Res> {
  factory $ElementFactAvailabilityCopyWith(ElementFactAvailability value, $Res Function(ElementFactAvailability) _then) = _$ElementFactAvailabilityCopyWithImpl;
@useResult
$Res call({
 String key, String expected
});




}
/// @nodoc
class _$ElementFactAvailabilityCopyWithImpl<$Res>
    implements $ElementFactAvailabilityCopyWith<$Res> {
  _$ElementFactAvailabilityCopyWithImpl(this._self, this._then);

  final ElementFactAvailability _self;
  final $Res Function(ElementFactAvailability) _then;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? expected = null,}) {
  return _then(ElementFactAvailability(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ElementAllAvailability implements ElementAvailability {
  const ElementAllAvailability(final  List<ElementAvailability> expressions): _expressions = expressions;
  

 final  List<ElementAvailability> _expressions;
 List<ElementAvailability> get expressions {
  if (_expressions is EqualUnmodifiableListView) return _expressions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expressions);
}


/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementAllAvailabilityCopyWith<ElementAllAvailability> get copyWith => _$ElementAllAvailabilityCopyWithImpl<ElementAllAvailability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementAllAvailability&&const DeepCollectionEquality().equals(other._expressions, _expressions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_expressions));

@override
String toString() {
  return 'ElementAvailability.all(expressions: $expressions)';
}


}

/// @nodoc
abstract mixin class $ElementAllAvailabilityCopyWith<$Res> implements $ElementAvailabilityCopyWith<$Res> {
  factory $ElementAllAvailabilityCopyWith(ElementAllAvailability value, $Res Function(ElementAllAvailability) _then) = _$ElementAllAvailabilityCopyWithImpl;
@useResult
$Res call({
 List<ElementAvailability> expressions
});




}
/// @nodoc
class _$ElementAllAvailabilityCopyWithImpl<$Res>
    implements $ElementAllAvailabilityCopyWith<$Res> {
  _$ElementAllAvailabilityCopyWithImpl(this._self, this._then);

  final ElementAllAvailability _self;
  final $Res Function(ElementAllAvailability) _then;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expressions = null,}) {
  return _then(ElementAllAvailability(
null == expressions ? _self._expressions : expressions // ignore: cast_nullable_to_non_nullable
as List<ElementAvailability>,
  ));
}


}

/// @nodoc


class ElementAnyAvailability implements ElementAvailability {
  const ElementAnyAvailability(final  List<ElementAvailability> expressions): _expressions = expressions;
  

 final  List<ElementAvailability> _expressions;
 List<ElementAvailability> get expressions {
  if (_expressions is EqualUnmodifiableListView) return _expressions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expressions);
}


/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementAnyAvailabilityCopyWith<ElementAnyAvailability> get copyWith => _$ElementAnyAvailabilityCopyWithImpl<ElementAnyAvailability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementAnyAvailability&&const DeepCollectionEquality().equals(other._expressions, _expressions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_expressions));

@override
String toString() {
  return 'ElementAvailability.any(expressions: $expressions)';
}


}

/// @nodoc
abstract mixin class $ElementAnyAvailabilityCopyWith<$Res> implements $ElementAvailabilityCopyWith<$Res> {
  factory $ElementAnyAvailabilityCopyWith(ElementAnyAvailability value, $Res Function(ElementAnyAvailability) _then) = _$ElementAnyAvailabilityCopyWithImpl;
@useResult
$Res call({
 List<ElementAvailability> expressions
});




}
/// @nodoc
class _$ElementAnyAvailabilityCopyWithImpl<$Res>
    implements $ElementAnyAvailabilityCopyWith<$Res> {
  _$ElementAnyAvailabilityCopyWithImpl(this._self, this._then);

  final ElementAnyAvailability _self;
  final $Res Function(ElementAnyAvailability) _then;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expressions = null,}) {
  return _then(ElementAnyAvailability(
null == expressions ? _self._expressions : expressions // ignore: cast_nullable_to_non_nullable
as List<ElementAvailability>,
  ));
}


}

/// @nodoc


class ElementNotAvailability implements ElementAvailability {
  const ElementNotAvailability(this.expression);
  

 final  ElementAvailability expression;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementNotAvailabilityCopyWith<ElementNotAvailability> get copyWith => _$ElementNotAvailabilityCopyWithImpl<ElementNotAvailability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementNotAvailability&&(identical(other.expression, expression) || other.expression == expression));
}


@override
int get hashCode => Object.hash(runtimeType,expression);

@override
String toString() {
  return 'ElementAvailability.not(expression: $expression)';
}


}

/// @nodoc
abstract mixin class $ElementNotAvailabilityCopyWith<$Res> implements $ElementAvailabilityCopyWith<$Res> {
  factory $ElementNotAvailabilityCopyWith(ElementNotAvailability value, $Res Function(ElementNotAvailability) _then) = _$ElementNotAvailabilityCopyWithImpl;
@useResult
$Res call({
 ElementAvailability expression
});


$ElementAvailabilityCopyWith<$Res> get expression;

}
/// @nodoc
class _$ElementNotAvailabilityCopyWithImpl<$Res>
    implements $ElementNotAvailabilityCopyWith<$Res> {
  _$ElementNotAvailabilityCopyWithImpl(this._self, this._then);

  final ElementNotAvailability _self;
  final $Res Function(ElementNotAvailability) _then;

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expression = null,}) {
  return _then(ElementNotAvailability(
null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as ElementAvailability,
  ));
}

/// Create a copy of ElementAvailability
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementAvailabilityCopyWith<$Res> get expression {
  
  return $ElementAvailabilityCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}

/// @nodoc
mixin _$DiscoveredElementDefinition {

 String get id; ResolvedTypeRef get type; String get name; String get description; IconValue get icon; Color get color; ElementAvailability get availability;
/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveredElementDefinitionCopyWith<DiscoveredElementDefinition> get copyWith => _$DiscoveredElementDefinitionCopyWithImpl<DiscoveredElementDefinition>(this as DiscoveredElementDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveredElementDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,name,description,icon,color,availability);

@override
String toString() {
  return 'DiscoveredElementDefinition(id: $id, type: $type, name: $name, description: $description, icon: $icon, color: $color, availability: $availability)';
}


}

/// @nodoc
abstract mixin class $DiscoveredElementDefinitionCopyWith<$Res>  {
  factory $DiscoveredElementDefinitionCopyWith(DiscoveredElementDefinition value, $Res Function(DiscoveredElementDefinition) _then) = _$DiscoveredElementDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, ResolvedTypeRef type, String name, String description, IconValue icon, Color color, ElementAvailability availability
});


$ResolvedTypeRefCopyWith<$Res> get type;$IconValueCopyWith<$Res> get icon;$ElementAvailabilityCopyWith<$Res> get availability;

}
/// @nodoc
class _$DiscoveredElementDefinitionCopyWithImpl<$Res>
    implements $DiscoveredElementDefinitionCopyWith<$Res> {
  _$DiscoveredElementDefinitionCopyWithImpl(this._self, this._then);

  final DiscoveredElementDefinition _self;
  final $Res Function(DiscoveredElementDefinition) _then;

/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? availability = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as ElementAvailability,
  ));
}
/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementAvailabilityCopyWith<$Res> get availability {
  
  return $ElementAvailabilityCopyWith<$Res>(_self.availability, (value) {
    return _then(_self.copyWith(availability: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiscoveredElementDefinition].
extension DiscoveredElementDefinitionPatterns on DiscoveredElementDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveredElementDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveredElementDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveredElementDefinition value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveredElementDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveredElementDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveredElementDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ResolvedTypeRef type,  String name,  String description,  IconValue icon,  Color color,  ElementAvailability availability)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveredElementDefinition() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.description,_that.icon,_that.color,_that.availability);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ResolvedTypeRef type,  String name,  String description,  IconValue icon,  Color color,  ElementAvailability availability)  $default,) {final _that = this;
switch (_that) {
case _DiscoveredElementDefinition():
return $default(_that.id,_that.type,_that.name,_that.description,_that.icon,_that.color,_that.availability);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ResolvedTypeRef type,  String name,  String description,  IconValue icon,  Color color,  ElementAvailability availability)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveredElementDefinition() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.description,_that.icon,_that.color,_that.availability);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoveredElementDefinition implements DiscoveredElementDefinition {
  const _DiscoveredElementDefinition({required this.id, required this.type, required this.name, required this.description, required this.icon, required this.color, required this.availability});
  

@override final  String id;
@override final  ResolvedTypeRef type;
@override final  String name;
@override final  String description;
@override final  IconValue icon;
@override final  Color color;
@override final  ElementAvailability availability;

/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveredElementDefinitionCopyWith<_DiscoveredElementDefinition> get copyWith => __$DiscoveredElementDefinitionCopyWithImpl<_DiscoveredElementDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveredElementDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,name,description,icon,color,availability);

@override
String toString() {
  return 'DiscoveredElementDefinition(id: $id, type: $type, name: $name, description: $description, icon: $icon, color: $color, availability: $availability)';
}


}

/// @nodoc
abstract mixin class _$DiscoveredElementDefinitionCopyWith<$Res> implements $DiscoveredElementDefinitionCopyWith<$Res> {
  factory _$DiscoveredElementDefinitionCopyWith(_DiscoveredElementDefinition value, $Res Function(_DiscoveredElementDefinition) _then) = __$DiscoveredElementDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, ResolvedTypeRef type, String name, String description, IconValue icon, Color color, ElementAvailability availability
});


@override $ResolvedTypeRefCopyWith<$Res> get type;@override $IconValueCopyWith<$Res> get icon;@override $ElementAvailabilityCopyWith<$Res> get availability;

}
/// @nodoc
class __$DiscoveredElementDefinitionCopyWithImpl<$Res>
    implements _$DiscoveredElementDefinitionCopyWith<$Res> {
  __$DiscoveredElementDefinitionCopyWithImpl(this._self, this._then);

  final _DiscoveredElementDefinition _self;
  final $Res Function(_DiscoveredElementDefinition) _then;

/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? availability = null,}) {
  return _then(_DiscoveredElementDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as ElementAvailability,
  ));
}

/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of DiscoveredElementDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementAvailabilityCopyWith<$Res> get availability {
  
  return $ElementAvailabilityCopyWith<$Res>(_self.availability, (value) {
    return _then(_self.copyWith(availability: value));
  });
}
}

/// @nodoc
mixin _$RealmElementCatalogEntry {

 String get originArtifactId; String get sourcePart; DiscoveredElementDefinition get definition; bool get eligible; bool get available; List<String> get ineligibilityReasons;
/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmElementCatalogEntryCopyWith<RealmElementCatalogEntry> get copyWith => _$RealmElementCatalogEntryCopyWithImpl<RealmElementCatalogEntry>(this as RealmElementCatalogEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmElementCatalogEntry&&(identical(other.originArtifactId, originArtifactId) || other.originArtifactId == originArtifactId)&&(identical(other.sourcePart, sourcePart) || other.sourcePart == sourcePart)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.eligible, eligible) || other.eligible == eligible)&&(identical(other.available, available) || other.available == available)&&const DeepCollectionEquality().equals(other.ineligibilityReasons, ineligibilityReasons));
}


@override
int get hashCode => Object.hash(runtimeType,originArtifactId,sourcePart,definition,eligible,available,const DeepCollectionEquality().hash(ineligibilityReasons));

@override
String toString() {
  return 'RealmElementCatalogEntry(originArtifactId: $originArtifactId, sourcePart: $sourcePart, definition: $definition, eligible: $eligible, available: $available, ineligibilityReasons: $ineligibilityReasons)';
}


}

/// @nodoc
abstract mixin class $RealmElementCatalogEntryCopyWith<$Res>  {
  factory $RealmElementCatalogEntryCopyWith(RealmElementCatalogEntry value, $Res Function(RealmElementCatalogEntry) _then) = _$RealmElementCatalogEntryCopyWithImpl;
@useResult
$Res call({
 String originArtifactId, String sourcePart, DiscoveredElementDefinition definition, bool eligible, bool available, List<String> ineligibilityReasons
});


$DiscoveredElementDefinitionCopyWith<$Res> get definition;

}
/// @nodoc
class _$RealmElementCatalogEntryCopyWithImpl<$Res>
    implements $RealmElementCatalogEntryCopyWith<$Res> {
  _$RealmElementCatalogEntryCopyWithImpl(this._self, this._then);

  final RealmElementCatalogEntry _self;
  final $Res Function(RealmElementCatalogEntry) _then;

/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originArtifactId = null,Object? sourcePart = null,Object? definition = null,Object? eligible = null,Object? available = null,Object? ineligibilityReasons = null,}) {
  return _then(_self.copyWith(
originArtifactId: null == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String,sourcePart: null == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as DiscoveredElementDefinition,eligible: null == eligible ? _self.eligible : eligible // ignore: cast_nullable_to_non_nullable
as bool,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,ineligibilityReasons: null == ineligibilityReasons ? _self.ineligibilityReasons : ineligibilityReasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoveredElementDefinitionCopyWith<$Res> get definition {
  
  return $DiscoveredElementDefinitionCopyWith<$Res>(_self.definition, (value) {
    return _then(_self.copyWith(definition: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmElementCatalogEntry].
extension RealmElementCatalogEntryPatterns on RealmElementCatalogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmElementCatalogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmElementCatalogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmElementCatalogEntry value)  $default,){
final _that = this;
switch (_that) {
case _RealmElementCatalogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmElementCatalogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RealmElementCatalogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String originArtifactId,  String sourcePart,  DiscoveredElementDefinition definition,  bool eligible,  bool available,  List<String> ineligibilityReasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmElementCatalogEntry() when $default != null:
return $default(_that.originArtifactId,_that.sourcePart,_that.definition,_that.eligible,_that.available,_that.ineligibilityReasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String originArtifactId,  String sourcePart,  DiscoveredElementDefinition definition,  bool eligible,  bool available,  List<String> ineligibilityReasons)  $default,) {final _that = this;
switch (_that) {
case _RealmElementCatalogEntry():
return $default(_that.originArtifactId,_that.sourcePart,_that.definition,_that.eligible,_that.available,_that.ineligibilityReasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String originArtifactId,  String sourcePart,  DiscoveredElementDefinition definition,  bool eligible,  bool available,  List<String> ineligibilityReasons)?  $default,) {final _that = this;
switch (_that) {
case _RealmElementCatalogEntry() when $default != null:
return $default(_that.originArtifactId,_that.sourcePart,_that.definition,_that.eligible,_that.available,_that.ineligibilityReasons);case _:
  return null;

}
}

}

/// @nodoc


class _RealmElementCatalogEntry implements RealmElementCatalogEntry {
  const _RealmElementCatalogEntry({required this.originArtifactId, required this.sourcePart, required this.definition, required this.eligible, required this.available, final  List<String> ineligibilityReasons = const []}): _ineligibilityReasons = ineligibilityReasons;
  

@override final  String originArtifactId;
@override final  String sourcePart;
@override final  DiscoveredElementDefinition definition;
@override final  bool eligible;
@override final  bool available;
 final  List<String> _ineligibilityReasons;
@override@JsonKey() List<String> get ineligibilityReasons {
  if (_ineligibilityReasons is EqualUnmodifiableListView) return _ineligibilityReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ineligibilityReasons);
}


/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmElementCatalogEntryCopyWith<_RealmElementCatalogEntry> get copyWith => __$RealmElementCatalogEntryCopyWithImpl<_RealmElementCatalogEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmElementCatalogEntry&&(identical(other.originArtifactId, originArtifactId) || other.originArtifactId == originArtifactId)&&(identical(other.sourcePart, sourcePart) || other.sourcePart == sourcePart)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.eligible, eligible) || other.eligible == eligible)&&(identical(other.available, available) || other.available == available)&&const DeepCollectionEquality().equals(other._ineligibilityReasons, _ineligibilityReasons));
}


@override
int get hashCode => Object.hash(runtimeType,originArtifactId,sourcePart,definition,eligible,available,const DeepCollectionEquality().hash(_ineligibilityReasons));

@override
String toString() {
  return 'RealmElementCatalogEntry(originArtifactId: $originArtifactId, sourcePart: $sourcePart, definition: $definition, eligible: $eligible, available: $available, ineligibilityReasons: $ineligibilityReasons)';
}


}

/// @nodoc
abstract mixin class _$RealmElementCatalogEntryCopyWith<$Res> implements $RealmElementCatalogEntryCopyWith<$Res> {
  factory _$RealmElementCatalogEntryCopyWith(_RealmElementCatalogEntry value, $Res Function(_RealmElementCatalogEntry) _then) = __$RealmElementCatalogEntryCopyWithImpl;
@override @useResult
$Res call({
 String originArtifactId, String sourcePart, DiscoveredElementDefinition definition, bool eligible, bool available, List<String> ineligibilityReasons
});


@override $DiscoveredElementDefinitionCopyWith<$Res> get definition;

}
/// @nodoc
class __$RealmElementCatalogEntryCopyWithImpl<$Res>
    implements _$RealmElementCatalogEntryCopyWith<$Res> {
  __$RealmElementCatalogEntryCopyWithImpl(this._self, this._then);

  final _RealmElementCatalogEntry _self;
  final $Res Function(_RealmElementCatalogEntry) _then;

/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originArtifactId = null,Object? sourcePart = null,Object? definition = null,Object? eligible = null,Object? available = null,Object? ineligibilityReasons = null,}) {
  return _then(_RealmElementCatalogEntry(
originArtifactId: null == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String,sourcePart: null == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as DiscoveredElementDefinition,eligible: null == eligible ? _self.eligible : eligible // ignore: cast_nullable_to_non_nullable
as bool,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,ineligibilityReasons: null == ineligibilityReasons ? _self._ineligibilityReasons : ineligibilityReasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of RealmElementCatalogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoveredElementDefinitionCopyWith<$Res> get definition {
  
  return $DiscoveredElementDefinitionCopyWith<$Res>(_self.definition, (value) {
    return _then(_self.copyWith(definition: value));
  });
}
}

// dart format on
