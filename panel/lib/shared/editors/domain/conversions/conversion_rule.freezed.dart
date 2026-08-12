// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversion_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversionRule {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionRule()';
}


}

/// @nodoc
class $ConversionRuleCopyWith<$Res>  {
$ConversionRuleCopyWith(ConversionRule _, $Res Function(ConversionRule) __);
}


/// Adds pattern-matching-related methods to [ConversionRule].
extension ConversionRulePatterns on ConversionRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InputConversionRule value)?  input,TResult Function( InheritanceUpcastRule value)?  inheritanceUpcast,TResult Function( ValidatedDowncastRule value)?  validatedDowncast,TResult Function( ScalarConversionRule value)?  scalar,TResult Function( FieldConversionRule value)?  field,TResult Function( RecordConversionRule value)?  record,TResult Function( ListConversionRule value)?  list,TResult Function( PolymorphicConversionRule value)?  polymorphic,TResult Function( ComposedConversionRule value)?  compose,TResult Function( RealmConversionRule value)?  realm,TResult Function( RecordProjectionConversionRule value)?  recordProjection,TResult Function( RecordConstructionConversionRule value)?  recordConstruction,TResult Function( CollectionMappingConversionRule value)?  collectionMapping,TResult Function( PolymorphicMatchingConversionRule value)?  polymorphicMatching,TResult Function( ConversionCompositionIdsRule value)?  compositionIds,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InputConversionRule() when input != null:
return input(_that);case InheritanceUpcastRule() when inheritanceUpcast != null:
return inheritanceUpcast(_that);case ValidatedDowncastRule() when validatedDowncast != null:
return validatedDowncast(_that);case ScalarConversionRule() when scalar != null:
return scalar(_that);case FieldConversionRule() when field != null:
return field(_that);case RecordConversionRule() when record != null:
return record(_that);case ListConversionRule() when list != null:
return list(_that);case PolymorphicConversionRule() when polymorphic != null:
return polymorphic(_that);case ComposedConversionRule() when compose != null:
return compose(_that);case RealmConversionRule() when realm != null:
return realm(_that);case RecordProjectionConversionRule() when recordProjection != null:
return recordProjection(_that);case RecordConstructionConversionRule() when recordConstruction != null:
return recordConstruction(_that);case CollectionMappingConversionRule() when collectionMapping != null:
return collectionMapping(_that);case PolymorphicMatchingConversionRule() when polymorphicMatching != null:
return polymorphicMatching(_that);case ConversionCompositionIdsRule() when compositionIds != null:
return compositionIds(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InputConversionRule value)  input,required TResult Function( InheritanceUpcastRule value)  inheritanceUpcast,required TResult Function( ValidatedDowncastRule value)  validatedDowncast,required TResult Function( ScalarConversionRule value)  scalar,required TResult Function( FieldConversionRule value)  field,required TResult Function( RecordConversionRule value)  record,required TResult Function( ListConversionRule value)  list,required TResult Function( PolymorphicConversionRule value)  polymorphic,required TResult Function( ComposedConversionRule value)  compose,required TResult Function( RealmConversionRule value)  realm,required TResult Function( RecordProjectionConversionRule value)  recordProjection,required TResult Function( RecordConstructionConversionRule value)  recordConstruction,required TResult Function( CollectionMappingConversionRule value)  collectionMapping,required TResult Function( PolymorphicMatchingConversionRule value)  polymorphicMatching,required TResult Function( ConversionCompositionIdsRule value)  compositionIds,}){
final _that = this;
switch (_that) {
case InputConversionRule():
return input(_that);case InheritanceUpcastRule():
return inheritanceUpcast(_that);case ValidatedDowncastRule():
return validatedDowncast(_that);case ScalarConversionRule():
return scalar(_that);case FieldConversionRule():
return field(_that);case RecordConversionRule():
return record(_that);case ListConversionRule():
return list(_that);case PolymorphicConversionRule():
return polymorphic(_that);case ComposedConversionRule():
return compose(_that);case RealmConversionRule():
return realm(_that);case RecordProjectionConversionRule():
return recordProjection(_that);case RecordConstructionConversionRule():
return recordConstruction(_that);case CollectionMappingConversionRule():
return collectionMapping(_that);case PolymorphicMatchingConversionRule():
return polymorphicMatching(_that);case ConversionCompositionIdsRule():
return compositionIds(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InputConversionRule value)?  input,TResult? Function( InheritanceUpcastRule value)?  inheritanceUpcast,TResult? Function( ValidatedDowncastRule value)?  validatedDowncast,TResult? Function( ScalarConversionRule value)?  scalar,TResult? Function( FieldConversionRule value)?  field,TResult? Function( RecordConversionRule value)?  record,TResult? Function( ListConversionRule value)?  list,TResult? Function( PolymorphicConversionRule value)?  polymorphic,TResult? Function( ComposedConversionRule value)?  compose,TResult? Function( RealmConversionRule value)?  realm,TResult? Function( RecordProjectionConversionRule value)?  recordProjection,TResult? Function( RecordConstructionConversionRule value)?  recordConstruction,TResult? Function( CollectionMappingConversionRule value)?  collectionMapping,TResult? Function( PolymorphicMatchingConversionRule value)?  polymorphicMatching,TResult? Function( ConversionCompositionIdsRule value)?  compositionIds,}){
final _that = this;
switch (_that) {
case InputConversionRule() when input != null:
return input(_that);case InheritanceUpcastRule() when inheritanceUpcast != null:
return inheritanceUpcast(_that);case ValidatedDowncastRule() when validatedDowncast != null:
return validatedDowncast(_that);case ScalarConversionRule() when scalar != null:
return scalar(_that);case FieldConversionRule() when field != null:
return field(_that);case RecordConversionRule() when record != null:
return record(_that);case ListConversionRule() when list != null:
return list(_that);case PolymorphicConversionRule() when polymorphic != null:
return polymorphic(_that);case ComposedConversionRule() when compose != null:
return compose(_that);case RealmConversionRule() when realm != null:
return realm(_that);case RecordProjectionConversionRule() when recordProjection != null:
return recordProjection(_that);case RecordConstructionConversionRule() when recordConstruction != null:
return recordConstruction(_that);case CollectionMappingConversionRule() when collectionMapping != null:
return collectionMapping(_that);case PolymorphicMatchingConversionRule() when polymorphicMatching != null:
return polymorphicMatching(_that);case ConversionCompositionIdsRule() when compositionIds != null:
return compositionIds(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  input,TResult Function()?  inheritanceUpcast,TResult Function()?  validatedDowncast,TResult Function( ScalarConversion conversion)?  scalar,TResult Function( String name,  ConversionRule rule)?  field,TResult Function( Map<String, ConversionRule> fields)?  record,TResult Function( ConversionRule element)?  list,TResult Function( List<ConversionPolymorphicCase> cases)?  polymorphic,TResult Function( List<ConversionRule> rules)?  compose,TResult Function()?  realm,TResult Function( List<ConversionProjectionField> fields)?  recordProjection,TResult Function( List<ConversionConstructionField> fields)?  recordConstruction,TResult Function( ConversionId elementConversionId)?  collectionMapping,TResult Function( List<ConversionPolymorphicMatch> cases)?  polymorphicMatching,TResult Function( List<ConversionId> steps)?  compositionIds,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InputConversionRule() when input != null:
return input();case InheritanceUpcastRule() when inheritanceUpcast != null:
return inheritanceUpcast();case ValidatedDowncastRule() when validatedDowncast != null:
return validatedDowncast();case ScalarConversionRule() when scalar != null:
return scalar(_that.conversion);case FieldConversionRule() when field != null:
return field(_that.name,_that.rule);case RecordConversionRule() when record != null:
return record(_that.fields);case ListConversionRule() when list != null:
return list(_that.element);case PolymorphicConversionRule() when polymorphic != null:
return polymorphic(_that.cases);case ComposedConversionRule() when compose != null:
return compose(_that.rules);case RealmConversionRule() when realm != null:
return realm();case RecordProjectionConversionRule() when recordProjection != null:
return recordProjection(_that.fields);case RecordConstructionConversionRule() when recordConstruction != null:
return recordConstruction(_that.fields);case CollectionMappingConversionRule() when collectionMapping != null:
return collectionMapping(_that.elementConversionId);case PolymorphicMatchingConversionRule() when polymorphicMatching != null:
return polymorphicMatching(_that.cases);case ConversionCompositionIdsRule() when compositionIds != null:
return compositionIds(_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  input,required TResult Function()  inheritanceUpcast,required TResult Function()  validatedDowncast,required TResult Function( ScalarConversion conversion)  scalar,required TResult Function( String name,  ConversionRule rule)  field,required TResult Function( Map<String, ConversionRule> fields)  record,required TResult Function( ConversionRule element)  list,required TResult Function( List<ConversionPolymorphicCase> cases)  polymorphic,required TResult Function( List<ConversionRule> rules)  compose,required TResult Function()  realm,required TResult Function( List<ConversionProjectionField> fields)  recordProjection,required TResult Function( List<ConversionConstructionField> fields)  recordConstruction,required TResult Function( ConversionId elementConversionId)  collectionMapping,required TResult Function( List<ConversionPolymorphicMatch> cases)  polymorphicMatching,required TResult Function( List<ConversionId> steps)  compositionIds,}) {final _that = this;
switch (_that) {
case InputConversionRule():
return input();case InheritanceUpcastRule():
return inheritanceUpcast();case ValidatedDowncastRule():
return validatedDowncast();case ScalarConversionRule():
return scalar(_that.conversion);case FieldConversionRule():
return field(_that.name,_that.rule);case RecordConversionRule():
return record(_that.fields);case ListConversionRule():
return list(_that.element);case PolymorphicConversionRule():
return polymorphic(_that.cases);case ComposedConversionRule():
return compose(_that.rules);case RealmConversionRule():
return realm();case RecordProjectionConversionRule():
return recordProjection(_that.fields);case RecordConstructionConversionRule():
return recordConstruction(_that.fields);case CollectionMappingConversionRule():
return collectionMapping(_that.elementConversionId);case PolymorphicMatchingConversionRule():
return polymorphicMatching(_that.cases);case ConversionCompositionIdsRule():
return compositionIds(_that.steps);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  input,TResult? Function()?  inheritanceUpcast,TResult? Function()?  validatedDowncast,TResult? Function( ScalarConversion conversion)?  scalar,TResult? Function( String name,  ConversionRule rule)?  field,TResult? Function( Map<String, ConversionRule> fields)?  record,TResult? Function( ConversionRule element)?  list,TResult? Function( List<ConversionPolymorphicCase> cases)?  polymorphic,TResult? Function( List<ConversionRule> rules)?  compose,TResult? Function()?  realm,TResult? Function( List<ConversionProjectionField> fields)?  recordProjection,TResult? Function( List<ConversionConstructionField> fields)?  recordConstruction,TResult? Function( ConversionId elementConversionId)?  collectionMapping,TResult? Function( List<ConversionPolymorphicMatch> cases)?  polymorphicMatching,TResult? Function( List<ConversionId> steps)?  compositionIds,}) {final _that = this;
switch (_that) {
case InputConversionRule() when input != null:
return input();case InheritanceUpcastRule() when inheritanceUpcast != null:
return inheritanceUpcast();case ValidatedDowncastRule() when validatedDowncast != null:
return validatedDowncast();case ScalarConversionRule() when scalar != null:
return scalar(_that.conversion);case FieldConversionRule() when field != null:
return field(_that.name,_that.rule);case RecordConversionRule() when record != null:
return record(_that.fields);case ListConversionRule() when list != null:
return list(_that.element);case PolymorphicConversionRule() when polymorphic != null:
return polymorphic(_that.cases);case ComposedConversionRule() when compose != null:
return compose(_that.rules);case RealmConversionRule() when realm != null:
return realm();case RecordProjectionConversionRule() when recordProjection != null:
return recordProjection(_that.fields);case RecordConstructionConversionRule() when recordConstruction != null:
return recordConstruction(_that.fields);case CollectionMappingConversionRule() when collectionMapping != null:
return collectionMapping(_that.elementConversionId);case PolymorphicMatchingConversionRule() when polymorphicMatching != null:
return polymorphicMatching(_that.cases);case ConversionCompositionIdsRule() when compositionIds != null:
return compositionIds(_that.steps);case _:
  return null;

}
}

}

/// @nodoc


class InputConversionRule implements ConversionRule {
  const InputConversionRule();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputConversionRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionRule.input()';
}


}




/// @nodoc


class InheritanceUpcastRule implements ConversionRule {
  const InheritanceUpcastRule();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InheritanceUpcastRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionRule.inheritanceUpcast()';
}


}




/// @nodoc


class ValidatedDowncastRule implements ConversionRule {
  const ValidatedDowncastRule();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidatedDowncastRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionRule.validatedDowncast()';
}


}




/// @nodoc


class ScalarConversionRule implements ConversionRule {
  const ScalarConversionRule(this.conversion);
  

 final  ScalarConversion conversion;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScalarConversionRuleCopyWith<ScalarConversionRule> get copyWith => _$ScalarConversionRuleCopyWithImpl<ScalarConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScalarConversionRule&&(identical(other.conversion, conversion) || other.conversion == conversion));
}


@override
int get hashCode => Object.hash(runtimeType,conversion);

@override
String toString() {
  return 'ConversionRule.scalar(conversion: $conversion)';
}


}

/// @nodoc
abstract mixin class $ScalarConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $ScalarConversionRuleCopyWith(ScalarConversionRule value, $Res Function(ScalarConversionRule) _then) = _$ScalarConversionRuleCopyWithImpl;
@useResult
$Res call({
 ScalarConversion conversion
});




}
/// @nodoc
class _$ScalarConversionRuleCopyWithImpl<$Res>
    implements $ScalarConversionRuleCopyWith<$Res> {
  _$ScalarConversionRuleCopyWithImpl(this._self, this._then);

  final ScalarConversionRule _self;
  final $Res Function(ScalarConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversion = null,}) {
  return _then(ScalarConversionRule(
null == conversion ? _self.conversion : conversion // ignore: cast_nullable_to_non_nullable
as ScalarConversion,
  ));
}


}

/// @nodoc


class FieldConversionRule implements ConversionRule {
  const FieldConversionRule({required this.name, required this.rule}): assert(name != "", 'Field name must not be empty.');
  

 final  String name;
 final  ConversionRule rule;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldConversionRuleCopyWith<FieldConversionRule> get copyWith => _$FieldConversionRuleCopyWithImpl<FieldConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldConversionRule&&(identical(other.name, name) || other.name == name)&&(identical(other.rule, rule) || other.rule == rule));
}


@override
int get hashCode => Object.hash(runtimeType,name,rule);

@override
String toString() {
  return 'ConversionRule.field(name: $name, rule: $rule)';
}


}

/// @nodoc
abstract mixin class $FieldConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $FieldConversionRuleCopyWith(FieldConversionRule value, $Res Function(FieldConversionRule) _then) = _$FieldConversionRuleCopyWithImpl;
@useResult
$Res call({
 String name, ConversionRule rule
});


$ConversionRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$FieldConversionRuleCopyWithImpl<$Res>
    implements $FieldConversionRuleCopyWith<$Res> {
  _$FieldConversionRuleCopyWithImpl(this._self, this._then);

  final FieldConversionRule _self;
  final $Res Function(FieldConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? rule = null,}) {
  return _then(FieldConversionRule(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as ConversionRule,
  ));
}

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get rule {
  
  return $ConversionRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}

/// @nodoc


class RecordConversionRule implements ConversionRule {
  const RecordConversionRule(final  Map<String, ConversionRule> fields): _fields = fields;
  

 final  Map<String, ConversionRule> _fields;
 Map<String, ConversionRule> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordConversionRuleCopyWith<RecordConversionRule> get copyWith => _$RecordConversionRuleCopyWithImpl<RecordConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordConversionRule&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'ConversionRule.record(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $RecordConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $RecordConversionRuleCopyWith(RecordConversionRule value, $Res Function(RecordConversionRule) _then) = _$RecordConversionRuleCopyWithImpl;
@useResult
$Res call({
 Map<String, ConversionRule> fields
});




}
/// @nodoc
class _$RecordConversionRuleCopyWithImpl<$Res>
    implements $RecordConversionRuleCopyWith<$Res> {
  _$RecordConversionRuleCopyWithImpl(this._self, this._then);

  final RecordConversionRule _self;
  final $Res Function(RecordConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(RecordConversionRule(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, ConversionRule>,
  ));
}


}

/// @nodoc


class ListConversionRule implements ConversionRule {
  const ListConversionRule(this.element);
  

 final  ConversionRule element;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListConversionRuleCopyWith<ListConversionRule> get copyWith => _$ListConversionRuleCopyWithImpl<ListConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListConversionRule&&(identical(other.element, element) || other.element == element));
}


@override
int get hashCode => Object.hash(runtimeType,element);

@override
String toString() {
  return 'ConversionRule.list(element: $element)';
}


}

/// @nodoc
abstract mixin class $ListConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $ListConversionRuleCopyWith(ListConversionRule value, $Res Function(ListConversionRule) _then) = _$ListConversionRuleCopyWithImpl;
@useResult
$Res call({
 ConversionRule element
});


$ConversionRuleCopyWith<$Res> get element;

}
/// @nodoc
class _$ListConversionRuleCopyWithImpl<$Res>
    implements $ListConversionRuleCopyWith<$Res> {
  _$ListConversionRuleCopyWithImpl(this._self, this._then);

  final ListConversionRule _self;
  final $Res Function(ListConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? element = null,}) {
  return _then(ListConversionRule(
null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as ConversionRule,
  ));
}

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get element {
  
  return $ConversionRuleCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}
}

/// @nodoc


class PolymorphicConversionRule implements ConversionRule {
  const PolymorphicConversionRule(final  List<ConversionPolymorphicCase> cases): _cases = cases;
  

 final  List<ConversionPolymorphicCase> _cases;
 List<ConversionPolymorphicCase> get cases {
  if (_cases is EqualUnmodifiableListView) return _cases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cases);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolymorphicConversionRuleCopyWith<PolymorphicConversionRule> get copyWith => _$PolymorphicConversionRuleCopyWithImpl<PolymorphicConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PolymorphicConversionRule&&const DeepCollectionEquality().equals(other._cases, _cases));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cases));

@override
String toString() {
  return 'ConversionRule.polymorphic(cases: $cases)';
}


}

/// @nodoc
abstract mixin class $PolymorphicConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $PolymorphicConversionRuleCopyWith(PolymorphicConversionRule value, $Res Function(PolymorphicConversionRule) _then) = _$PolymorphicConversionRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionPolymorphicCase> cases
});




}
/// @nodoc
class _$PolymorphicConversionRuleCopyWithImpl<$Res>
    implements $PolymorphicConversionRuleCopyWith<$Res> {
  _$PolymorphicConversionRuleCopyWithImpl(this._self, this._then);

  final PolymorphicConversionRule _self;
  final $Res Function(PolymorphicConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cases = null,}) {
  return _then(PolymorphicConversionRule(
null == cases ? _self._cases : cases // ignore: cast_nullable_to_non_nullable
as List<ConversionPolymorphicCase>,
  ));
}


}

/// @nodoc


class ComposedConversionRule implements ConversionRule {
  const ComposedConversionRule(final  List<ConversionRule> rules): _rules = rules;
  

 final  List<ConversionRule> _rules;
 List<ConversionRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComposedConversionRuleCopyWith<ComposedConversionRule> get copyWith => _$ComposedConversionRuleCopyWithImpl<ComposedConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComposedConversionRule&&const DeepCollectionEquality().equals(other._rules, _rules));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rules));

@override
String toString() {
  return 'ConversionRule.compose(rules: $rules)';
}


}

/// @nodoc
abstract mixin class $ComposedConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $ComposedConversionRuleCopyWith(ComposedConversionRule value, $Res Function(ComposedConversionRule) _then) = _$ComposedConversionRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionRule> rules
});




}
/// @nodoc
class _$ComposedConversionRuleCopyWithImpl<$Res>
    implements $ComposedConversionRuleCopyWith<$Res> {
  _$ComposedConversionRuleCopyWithImpl(this._self, this._then);

  final ComposedConversionRule _self;
  final $Res Function(ComposedConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rules = null,}) {
  return _then(ComposedConversionRule(
null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<ConversionRule>,
  ));
}


}

/// @nodoc


class RealmConversionRule implements ConversionRule {
  const RealmConversionRule();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmConversionRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionRule.realm()';
}


}




/// @nodoc


class RecordProjectionConversionRule implements ConversionRule {
  const RecordProjectionConversionRule(final  List<ConversionProjectionField> fields): _fields = fields;
  

 final  List<ConversionProjectionField> _fields;
 List<ConversionProjectionField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordProjectionConversionRuleCopyWith<RecordProjectionConversionRule> get copyWith => _$RecordProjectionConversionRuleCopyWithImpl<RecordProjectionConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordProjectionConversionRule&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'ConversionRule.recordProjection(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $RecordProjectionConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $RecordProjectionConversionRuleCopyWith(RecordProjectionConversionRule value, $Res Function(RecordProjectionConversionRule) _then) = _$RecordProjectionConversionRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionProjectionField> fields
});




}
/// @nodoc
class _$RecordProjectionConversionRuleCopyWithImpl<$Res>
    implements $RecordProjectionConversionRuleCopyWith<$Res> {
  _$RecordProjectionConversionRuleCopyWithImpl(this._self, this._then);

  final RecordProjectionConversionRule _self;
  final $Res Function(RecordProjectionConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(RecordProjectionConversionRule(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<ConversionProjectionField>,
  ));
}


}

/// @nodoc


class RecordConstructionConversionRule implements ConversionRule {
  const RecordConstructionConversionRule(final  List<ConversionConstructionField> fields): _fields = fields;
  

 final  List<ConversionConstructionField> _fields;
 List<ConversionConstructionField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordConstructionConversionRuleCopyWith<RecordConstructionConversionRule> get copyWith => _$RecordConstructionConversionRuleCopyWithImpl<RecordConstructionConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordConstructionConversionRule&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'ConversionRule.recordConstruction(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $RecordConstructionConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $RecordConstructionConversionRuleCopyWith(RecordConstructionConversionRule value, $Res Function(RecordConstructionConversionRule) _then) = _$RecordConstructionConversionRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionConstructionField> fields
});




}
/// @nodoc
class _$RecordConstructionConversionRuleCopyWithImpl<$Res>
    implements $RecordConstructionConversionRuleCopyWith<$Res> {
  _$RecordConstructionConversionRuleCopyWithImpl(this._self, this._then);

  final RecordConstructionConversionRule _self;
  final $Res Function(RecordConstructionConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(RecordConstructionConversionRule(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<ConversionConstructionField>,
  ));
}


}

/// @nodoc


class CollectionMappingConversionRule implements ConversionRule {
  const CollectionMappingConversionRule(this.elementConversionId);
  

 final  ConversionId elementConversionId;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionMappingConversionRuleCopyWith<CollectionMappingConversionRule> get copyWith => _$CollectionMappingConversionRuleCopyWithImpl<CollectionMappingConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMappingConversionRule&&(identical(other.elementConversionId, elementConversionId) || other.elementConversionId == elementConversionId));
}


@override
int get hashCode => Object.hash(runtimeType,elementConversionId);

@override
String toString() {
  return 'ConversionRule.collectionMapping(elementConversionId: $elementConversionId)';
}


}

/// @nodoc
abstract mixin class $CollectionMappingConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $CollectionMappingConversionRuleCopyWith(CollectionMappingConversionRule value, $Res Function(CollectionMappingConversionRule) _then) = _$CollectionMappingConversionRuleCopyWithImpl;
@useResult
$Res call({
 ConversionId elementConversionId
});


$ConversionIdCopyWith<$Res> get elementConversionId;

}
/// @nodoc
class _$CollectionMappingConversionRuleCopyWithImpl<$Res>
    implements $CollectionMappingConversionRuleCopyWith<$Res> {
  _$CollectionMappingConversionRuleCopyWithImpl(this._self, this._then);

  final CollectionMappingConversionRule _self;
  final $Res Function(CollectionMappingConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? elementConversionId = null,}) {
  return _then(CollectionMappingConversionRule(
null == elementConversionId ? _self.elementConversionId : elementConversionId // ignore: cast_nullable_to_non_nullable
as ConversionId,
  ));
}

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res> get elementConversionId {
  
  return $ConversionIdCopyWith<$Res>(_self.elementConversionId, (value) {
    return _then(_self.copyWith(elementConversionId: value));
  });
}
}

/// @nodoc


class PolymorphicMatchingConversionRule implements ConversionRule {
  const PolymorphicMatchingConversionRule(final  List<ConversionPolymorphicMatch> cases): _cases = cases;
  

 final  List<ConversionPolymorphicMatch> _cases;
 List<ConversionPolymorphicMatch> get cases {
  if (_cases is EqualUnmodifiableListView) return _cases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cases);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolymorphicMatchingConversionRuleCopyWith<PolymorphicMatchingConversionRule> get copyWith => _$PolymorphicMatchingConversionRuleCopyWithImpl<PolymorphicMatchingConversionRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PolymorphicMatchingConversionRule&&const DeepCollectionEquality().equals(other._cases, _cases));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cases));

@override
String toString() {
  return 'ConversionRule.polymorphicMatching(cases: $cases)';
}


}

/// @nodoc
abstract mixin class $PolymorphicMatchingConversionRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $PolymorphicMatchingConversionRuleCopyWith(PolymorphicMatchingConversionRule value, $Res Function(PolymorphicMatchingConversionRule) _then) = _$PolymorphicMatchingConversionRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionPolymorphicMatch> cases
});




}
/// @nodoc
class _$PolymorphicMatchingConversionRuleCopyWithImpl<$Res>
    implements $PolymorphicMatchingConversionRuleCopyWith<$Res> {
  _$PolymorphicMatchingConversionRuleCopyWithImpl(this._self, this._then);

  final PolymorphicMatchingConversionRule _self;
  final $Res Function(PolymorphicMatchingConversionRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cases = null,}) {
  return _then(PolymorphicMatchingConversionRule(
null == cases ? _self._cases : cases // ignore: cast_nullable_to_non_nullable
as List<ConversionPolymorphicMatch>,
  ));
}


}

/// @nodoc


class ConversionCompositionIdsRule implements ConversionRule {
  const ConversionCompositionIdsRule(final  List<ConversionId> steps): _steps = steps;
  

 final  List<ConversionId> _steps;
 List<ConversionId> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionCompositionIdsRuleCopyWith<ConversionCompositionIdsRule> get copyWith => _$ConversionCompositionIdsRuleCopyWithImpl<ConversionCompositionIdsRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionCompositionIdsRule&&const DeepCollectionEquality().equals(other._steps, _steps));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'ConversionRule.compositionIds(steps: $steps)';
}


}

/// @nodoc
abstract mixin class $ConversionCompositionIdsRuleCopyWith<$Res> implements $ConversionRuleCopyWith<$Res> {
  factory $ConversionCompositionIdsRuleCopyWith(ConversionCompositionIdsRule value, $Res Function(ConversionCompositionIdsRule) _then) = _$ConversionCompositionIdsRuleCopyWithImpl;
@useResult
$Res call({
 List<ConversionId> steps
});




}
/// @nodoc
class _$ConversionCompositionIdsRuleCopyWithImpl<$Res>
    implements $ConversionCompositionIdsRuleCopyWith<$Res> {
  _$ConversionCompositionIdsRuleCopyWithImpl(this._self, this._then);

  final ConversionCompositionIdsRule _self;
  final $Res Function(ConversionCompositionIdsRule) _then;

/// Create a copy of ConversionRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? steps = null,}) {
  return _then(ConversionCompositionIdsRule(
null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ConversionId>,
  ));
}


}

/// @nodoc
mixin _$ConversionPolymorphicCase {

 ResolvedTypeRef get sourceType; ResolvedTypeRef get targetType; ConversionRule get rule;
/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionPolymorphicCaseCopyWith<ConversionPolymorphicCase> get copyWith => _$ConversionPolymorphicCaseCopyWithImpl<ConversionPolymorphicCase>(this as ConversionPolymorphicCase, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionPolymorphicCase&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.rule, rule) || other.rule == rule));
}


@override
int get hashCode => Object.hash(runtimeType,sourceType,targetType,rule);

@override
String toString() {
  return 'ConversionPolymorphicCase(sourceType: $sourceType, targetType: $targetType, rule: $rule)';
}


}

/// @nodoc
abstract mixin class $ConversionPolymorphicCaseCopyWith<$Res>  {
  factory $ConversionPolymorphicCaseCopyWith(ConversionPolymorphicCase value, $Res Function(ConversionPolymorphicCase) _then) = _$ConversionPolymorphicCaseCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef sourceType, ResolvedTypeRef targetType, ConversionRule rule
});


$ResolvedTypeRefCopyWith<$Res> get sourceType;$ResolvedTypeRefCopyWith<$Res> get targetType;$ConversionRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$ConversionPolymorphicCaseCopyWithImpl<$Res>
    implements $ConversionPolymorphicCaseCopyWith<$Res> {
  _$ConversionPolymorphicCaseCopyWithImpl(this._self, this._then);

  final ConversionPolymorphicCase _self;
  final $Res Function(ConversionPolymorphicCase) _then;

/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceType = null,Object? targetType = null,Object? rule = null,}) {
  return _then(_self.copyWith(
sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as ConversionRule,
  ));
}
/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get sourceType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.sourceType, (value) {
    return _then(_self.copyWith(sourceType: value));
  });
}/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get targetType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.targetType, (value) {
    return _then(_self.copyWith(targetType: value));
  });
}/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get rule {
  
  return $ConversionRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversionPolymorphicCase].
extension ConversionPolymorphicCasePatterns on ConversionPolymorphicCase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionPolymorphicCase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionPolymorphicCase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionPolymorphicCase value)  $default,){
final _that = this;
switch (_that) {
case _ConversionPolymorphicCase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionPolymorphicCase value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionPolymorphicCase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionRule rule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionPolymorphicCase() when $default != null:
return $default(_that.sourceType,_that.targetType,_that.rule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionRule rule)  $default,) {final _that = this;
switch (_that) {
case _ConversionPolymorphicCase():
return $default(_that.sourceType,_that.targetType,_that.rule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionRule rule)?  $default,) {final _that = this;
switch (_that) {
case _ConversionPolymorphicCase() when $default != null:
return $default(_that.sourceType,_that.targetType,_that.rule);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionPolymorphicCase implements ConversionPolymorphicCase {
  const _ConversionPolymorphicCase({required this.sourceType, required this.targetType, required this.rule});
  

@override final  ResolvedTypeRef sourceType;
@override final  ResolvedTypeRef targetType;
@override final  ConversionRule rule;

/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionPolymorphicCaseCopyWith<_ConversionPolymorphicCase> get copyWith => __$ConversionPolymorphicCaseCopyWithImpl<_ConversionPolymorphicCase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionPolymorphicCase&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.rule, rule) || other.rule == rule));
}


@override
int get hashCode => Object.hash(runtimeType,sourceType,targetType,rule);

@override
String toString() {
  return 'ConversionPolymorphicCase(sourceType: $sourceType, targetType: $targetType, rule: $rule)';
}


}

/// @nodoc
abstract mixin class _$ConversionPolymorphicCaseCopyWith<$Res> implements $ConversionPolymorphicCaseCopyWith<$Res> {
  factory _$ConversionPolymorphicCaseCopyWith(_ConversionPolymorphicCase value, $Res Function(_ConversionPolymorphicCase) _then) = __$ConversionPolymorphicCaseCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef sourceType, ResolvedTypeRef targetType, ConversionRule rule
});


@override $ResolvedTypeRefCopyWith<$Res> get sourceType;@override $ResolvedTypeRefCopyWith<$Res> get targetType;@override $ConversionRuleCopyWith<$Res> get rule;

}
/// @nodoc
class __$ConversionPolymorphicCaseCopyWithImpl<$Res>
    implements _$ConversionPolymorphicCaseCopyWith<$Res> {
  __$ConversionPolymorphicCaseCopyWithImpl(this._self, this._then);

  final _ConversionPolymorphicCase _self;
  final $Res Function(_ConversionPolymorphicCase) _then;

/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceType = null,Object? targetType = null,Object? rule = null,}) {
  return _then(_ConversionPolymorphicCase(
sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as ConversionRule,
  ));
}

/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get sourceType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.sourceType, (value) {
    return _then(_self.copyWith(sourceType: value));
  });
}/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get targetType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.targetType, (value) {
    return _then(_self.copyWith(targetType: value));
  });
}/// Create a copy of ConversionPolymorphicCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get rule {
  
  return $ConversionRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}

/// @nodoc
mixin _$ConversionProjectionField {

 DataPath get source; DataPath get target; ConversionId? get conversionId;
/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionProjectionFieldCopyWith<ConversionProjectionField> get copyWith => _$ConversionProjectionFieldCopyWithImpl<ConversionProjectionField>(this as ConversionProjectionField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionProjectionField&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,source,target,conversionId);

@override
String toString() {
  return 'ConversionProjectionField(source: $source, target: $target, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class $ConversionProjectionFieldCopyWith<$Res>  {
  factory $ConversionProjectionFieldCopyWith(ConversionProjectionField value, $Res Function(ConversionProjectionField) _then) = _$ConversionProjectionFieldCopyWithImpl;
@useResult
$Res call({
 DataPath source, DataPath target, ConversionId? conversionId
});


$DataPathCopyWith<$Res> get source;$DataPathCopyWith<$Res> get target;$ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class _$ConversionProjectionFieldCopyWithImpl<$Res>
    implements $ConversionProjectionFieldCopyWith<$Res> {
  _$ConversionProjectionFieldCopyWithImpl(this._self, this._then);

  final ConversionProjectionField _self;
  final $Res Function(ConversionProjectionField) _then;

/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? target = null,Object? conversionId = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataPath,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as DataPath,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}
/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get source {
  
  return $DataPathCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get target {
  
  return $DataPathCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversionProjectionField].
extension ConversionProjectionFieldPatterns on ConversionProjectionField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionProjectionField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionProjectionField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionProjectionField value)  $default,){
final _that = this;
switch (_that) {
case _ConversionProjectionField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionProjectionField value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionProjectionField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataPath source,  DataPath target,  ConversionId? conversionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionProjectionField() when $default != null:
return $default(_that.source,_that.target,_that.conversionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataPath source,  DataPath target,  ConversionId? conversionId)  $default,) {final _that = this;
switch (_that) {
case _ConversionProjectionField():
return $default(_that.source,_that.target,_that.conversionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataPath source,  DataPath target,  ConversionId? conversionId)?  $default,) {final _that = this;
switch (_that) {
case _ConversionProjectionField() when $default != null:
return $default(_that.source,_that.target,_that.conversionId);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionProjectionField implements ConversionProjectionField {
  const _ConversionProjectionField({required this.source, required this.target, this.conversionId});
  

@override final  DataPath source;
@override final  DataPath target;
@override final  ConversionId? conversionId;

/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionProjectionFieldCopyWith<_ConversionProjectionField> get copyWith => __$ConversionProjectionFieldCopyWithImpl<_ConversionProjectionField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionProjectionField&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,source,target,conversionId);

@override
String toString() {
  return 'ConversionProjectionField(source: $source, target: $target, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class _$ConversionProjectionFieldCopyWith<$Res> implements $ConversionProjectionFieldCopyWith<$Res> {
  factory _$ConversionProjectionFieldCopyWith(_ConversionProjectionField value, $Res Function(_ConversionProjectionField) _then) = __$ConversionProjectionFieldCopyWithImpl;
@override @useResult
$Res call({
 DataPath source, DataPath target, ConversionId? conversionId
});


@override $DataPathCopyWith<$Res> get source;@override $DataPathCopyWith<$Res> get target;@override $ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class __$ConversionProjectionFieldCopyWithImpl<$Res>
    implements _$ConversionProjectionFieldCopyWith<$Res> {
  __$ConversionProjectionFieldCopyWithImpl(this._self, this._then);

  final _ConversionProjectionField _self;
  final $Res Function(_ConversionProjectionField) _then;

/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? target = null,Object? conversionId = freezed,}) {
  return _then(_ConversionProjectionField(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataPath,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as DataPath,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}

/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get source {
  
  return $DataPathCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get target {
  
  return $DataPathCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ConversionProjectionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}

/// @nodoc
mixin _$ConversionConstructionField {

 String get targetField; DataPath get source; ConversionId? get conversionId;
/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionConstructionFieldCopyWith<ConversionConstructionField> get copyWith => _$ConversionConstructionFieldCopyWithImpl<ConversionConstructionField>(this as ConversionConstructionField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionConstructionField&&(identical(other.targetField, targetField) || other.targetField == targetField)&&(identical(other.source, source) || other.source == source)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,targetField,source,conversionId);

@override
String toString() {
  return 'ConversionConstructionField(targetField: $targetField, source: $source, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class $ConversionConstructionFieldCopyWith<$Res>  {
  factory $ConversionConstructionFieldCopyWith(ConversionConstructionField value, $Res Function(ConversionConstructionField) _then) = _$ConversionConstructionFieldCopyWithImpl;
@useResult
$Res call({
 String targetField, DataPath source, ConversionId? conversionId
});


$DataPathCopyWith<$Res> get source;$ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class _$ConversionConstructionFieldCopyWithImpl<$Res>
    implements $ConversionConstructionFieldCopyWith<$Res> {
  _$ConversionConstructionFieldCopyWithImpl(this._self, this._then);

  final ConversionConstructionField _self;
  final $Res Function(ConversionConstructionField) _then;

/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetField = null,Object? source = null,Object? conversionId = freezed,}) {
  return _then(_self.copyWith(
targetField: null == targetField ? _self.targetField : targetField // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataPath,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}
/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get source {
  
  return $DataPathCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversionConstructionField].
extension ConversionConstructionFieldPatterns on ConversionConstructionField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionConstructionField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionConstructionField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionConstructionField value)  $default,){
final _that = this;
switch (_that) {
case _ConversionConstructionField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionConstructionField value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionConstructionField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetField,  DataPath source,  ConversionId? conversionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionConstructionField() when $default != null:
return $default(_that.targetField,_that.source,_that.conversionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetField,  DataPath source,  ConversionId? conversionId)  $default,) {final _that = this;
switch (_that) {
case _ConversionConstructionField():
return $default(_that.targetField,_that.source,_that.conversionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetField,  DataPath source,  ConversionId? conversionId)?  $default,) {final _that = this;
switch (_that) {
case _ConversionConstructionField() when $default != null:
return $default(_that.targetField,_that.source,_that.conversionId);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionConstructionField implements ConversionConstructionField {
  const _ConversionConstructionField({required this.targetField, required this.source, this.conversionId});
  

@override final  String targetField;
@override final  DataPath source;
@override final  ConversionId? conversionId;

/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionConstructionFieldCopyWith<_ConversionConstructionField> get copyWith => __$ConversionConstructionFieldCopyWithImpl<_ConversionConstructionField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionConstructionField&&(identical(other.targetField, targetField) || other.targetField == targetField)&&(identical(other.source, source) || other.source == source)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,targetField,source,conversionId);

@override
String toString() {
  return 'ConversionConstructionField(targetField: $targetField, source: $source, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class _$ConversionConstructionFieldCopyWith<$Res> implements $ConversionConstructionFieldCopyWith<$Res> {
  factory _$ConversionConstructionFieldCopyWith(_ConversionConstructionField value, $Res Function(_ConversionConstructionField) _then) = __$ConversionConstructionFieldCopyWithImpl;
@override @useResult
$Res call({
 String targetField, DataPath source, ConversionId? conversionId
});


@override $DataPathCopyWith<$Res> get source;@override $ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class __$ConversionConstructionFieldCopyWithImpl<$Res>
    implements _$ConversionConstructionFieldCopyWith<$Res> {
  __$ConversionConstructionFieldCopyWithImpl(this._self, this._then);

  final _ConversionConstructionField _self;
  final $Res Function(_ConversionConstructionField) _then;

/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetField = null,Object? source = null,Object? conversionId = freezed,}) {
  return _then(_ConversionConstructionField(
targetField: null == targetField ? _self.targetField : targetField // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataPath,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}

/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get source {
  
  return $DataPathCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionConstructionField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}

/// @nodoc
mixin _$ConversionPolymorphicMatch {

 ResolvedTypeRef get sourceType; ResolvedTypeRef get targetType; ConversionId? get conversionId;
/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionPolymorphicMatchCopyWith<ConversionPolymorphicMatch> get copyWith => _$ConversionPolymorphicMatchCopyWithImpl<ConversionPolymorphicMatch>(this as ConversionPolymorphicMatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionPolymorphicMatch&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,sourceType,targetType,conversionId);

@override
String toString() {
  return 'ConversionPolymorphicMatch(sourceType: $sourceType, targetType: $targetType, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class $ConversionPolymorphicMatchCopyWith<$Res>  {
  factory $ConversionPolymorphicMatchCopyWith(ConversionPolymorphicMatch value, $Res Function(ConversionPolymorphicMatch) _then) = _$ConversionPolymorphicMatchCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef sourceType, ResolvedTypeRef targetType, ConversionId? conversionId
});


$ResolvedTypeRefCopyWith<$Res> get sourceType;$ResolvedTypeRefCopyWith<$Res> get targetType;$ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class _$ConversionPolymorphicMatchCopyWithImpl<$Res>
    implements $ConversionPolymorphicMatchCopyWith<$Res> {
  _$ConversionPolymorphicMatchCopyWithImpl(this._self, this._then);

  final ConversionPolymorphicMatch _self;
  final $Res Function(ConversionPolymorphicMatch) _then;

/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceType = null,Object? targetType = null,Object? conversionId = freezed,}) {
  return _then(_self.copyWith(
sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}
/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get sourceType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.sourceType, (value) {
    return _then(_self.copyWith(sourceType: value));
  });
}/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get targetType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.targetType, (value) {
    return _then(_self.copyWith(targetType: value));
  });
}/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversionPolymorphicMatch].
extension ConversionPolymorphicMatchPatterns on ConversionPolymorphicMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionPolymorphicMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionPolymorphicMatch value)  $default,){
final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionPolymorphicMatch value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionId? conversionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch() when $default != null:
return $default(_that.sourceType,_that.targetType,_that.conversionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionId? conversionId)  $default,) {final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch():
return $default(_that.sourceType,_that.targetType,_that.conversionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef sourceType,  ResolvedTypeRef targetType,  ConversionId? conversionId)?  $default,) {final _that = this;
switch (_that) {
case _ConversionPolymorphicMatch() when $default != null:
return $default(_that.sourceType,_that.targetType,_that.conversionId);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionPolymorphicMatch implements ConversionPolymorphicMatch {
  const _ConversionPolymorphicMatch({required this.sourceType, required this.targetType, this.conversionId});
  

@override final  ResolvedTypeRef sourceType;
@override final  ResolvedTypeRef targetType;
@override final  ConversionId? conversionId;

/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionPolymorphicMatchCopyWith<_ConversionPolymorphicMatch> get copyWith => __$ConversionPolymorphicMatchCopyWithImpl<_ConversionPolymorphicMatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionPolymorphicMatch&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId));
}


@override
int get hashCode => Object.hash(runtimeType,sourceType,targetType,conversionId);

@override
String toString() {
  return 'ConversionPolymorphicMatch(sourceType: $sourceType, targetType: $targetType, conversionId: $conversionId)';
}


}

/// @nodoc
abstract mixin class _$ConversionPolymorphicMatchCopyWith<$Res> implements $ConversionPolymorphicMatchCopyWith<$Res> {
  factory _$ConversionPolymorphicMatchCopyWith(_ConversionPolymorphicMatch value, $Res Function(_ConversionPolymorphicMatch) _then) = __$ConversionPolymorphicMatchCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef sourceType, ResolvedTypeRef targetType, ConversionId? conversionId
});


@override $ResolvedTypeRefCopyWith<$Res> get sourceType;@override $ResolvedTypeRefCopyWith<$Res> get targetType;@override $ConversionIdCopyWith<$Res>? get conversionId;

}
/// @nodoc
class __$ConversionPolymorphicMatchCopyWithImpl<$Res>
    implements _$ConversionPolymorphicMatchCopyWith<$Res> {
  __$ConversionPolymorphicMatchCopyWithImpl(this._self, this._then);

  final _ConversionPolymorphicMatch _self;
  final $Res Function(_ConversionPolymorphicMatch) _then;

/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceType = null,Object? targetType = null,Object? conversionId = freezed,}) {
  return _then(_ConversionPolymorphicMatch(
sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,conversionId: freezed == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId?,
  ));
}

/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get sourceType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.sourceType, (value) {
    return _then(_self.copyWith(sourceType: value));
  });
}/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get targetType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.targetType, (value) {
    return _then(_self.copyWith(targetType: value));
  });
}/// Create a copy of ConversionPolymorphicMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res>? get conversionId {
    if (_self.conversionId == null) {
    return null;
  }

  return $ConversionIdCopyWith<$Res>(_self.conversionId!, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}
}

// dart format on
