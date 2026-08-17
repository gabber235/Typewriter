// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expression.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypedExpression {

 TypeExpression get resultType; Expression get expression;
/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<TypedExpression> get copyWith => _$TypedExpressionCopyWithImpl<TypedExpression>(this as TypedExpression, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedExpression&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.expression, expression) || other.expression == expression));
}


@override
int get hashCode => Object.hash(runtimeType,resultType,expression);

@override
String toString() {
  return 'TypedExpression(resultType: $resultType, expression: $expression)';
}


}

/// @nodoc
abstract mixin class $TypedExpressionCopyWith<$Res>  {
  factory $TypedExpressionCopyWith(TypedExpression value, $Res Function(TypedExpression) _then) = _$TypedExpressionCopyWithImpl;
@useResult
$Res call({
 TypeExpression resultType, Expression expression
});


$TypeExpressionCopyWith<$Res> get resultType;$ExpressionCopyWith<$Res> get expression;

}
/// @nodoc
class _$TypedExpressionCopyWithImpl<$Res>
    implements $TypedExpressionCopyWith<$Res> {
  _$TypedExpressionCopyWithImpl(this._self, this._then);

  final TypedExpression _self;
  final $Res Function(TypedExpression) _then;

/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resultType = null,Object? expression = null,}) {
  return _then(_self.copyWith(
resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as TypeExpression,expression: null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as Expression,
  ));
}
/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get resultType {
  
  return $TypeExpressionCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionCopyWith<$Res> get expression {
  
  return $ExpressionCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypedExpression].
extension TypedExpressionPatterns on TypedExpression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypedExpression value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypedExpression() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypedExpression value)  $default,){
final _that = this;
switch (_that) {
case _TypedExpression():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypedExpression value)?  $default,){
final _that = this;
switch (_that) {
case _TypedExpression() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeExpression resultType,  Expression expression)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypedExpression() when $default != null:
return $default(_that.resultType,_that.expression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeExpression resultType,  Expression expression)  $default,) {final _that = this;
switch (_that) {
case _TypedExpression():
return $default(_that.resultType,_that.expression);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeExpression resultType,  Expression expression)?  $default,) {final _that = this;
switch (_that) {
case _TypedExpression() when $default != null:
return $default(_that.resultType,_that.expression);case _:
  return null;

}
}

}

/// @nodoc


class _TypedExpression implements TypedExpression {
  const _TypedExpression({required this.resultType, required this.expression});
  

@override final  TypeExpression resultType;
@override final  Expression expression;

/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypedExpressionCopyWith<_TypedExpression> get copyWith => __$TypedExpressionCopyWithImpl<_TypedExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypedExpression&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.expression, expression) || other.expression == expression));
}


@override
int get hashCode => Object.hash(runtimeType,resultType,expression);

@override
String toString() {
  return 'TypedExpression(resultType: $resultType, expression: $expression)';
}


}

/// @nodoc
abstract mixin class _$TypedExpressionCopyWith<$Res> implements $TypedExpressionCopyWith<$Res> {
  factory _$TypedExpressionCopyWith(_TypedExpression value, $Res Function(_TypedExpression) _then) = __$TypedExpressionCopyWithImpl;
@override @useResult
$Res call({
 TypeExpression resultType, Expression expression
});


@override $TypeExpressionCopyWith<$Res> get resultType;@override $ExpressionCopyWith<$Res> get expression;

}
/// @nodoc
class __$TypedExpressionCopyWithImpl<$Res>
    implements _$TypedExpressionCopyWith<$Res> {
  __$TypedExpressionCopyWithImpl(this._self, this._then);

  final _TypedExpression _self;
  final $Res Function(_TypedExpression) _then;

/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resultType = null,Object? expression = null,}) {
  return _then(_TypedExpression(
resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as TypeExpression,expression: null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as Expression,
  ));
}

/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get resultType {
  
  return $TypeExpressionCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}/// Create a copy of TypedExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionCopyWith<$Res> get expression {
  
  return $ExpressionCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}

/// @nodoc
mixin _$Expression {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expression);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Expression()';
}


}

/// @nodoc
class $ExpressionCopyWith<$Res>  {
$ExpressionCopyWith(Expression _, $Res Function(Expression) __);
}


/// Adds pattern-matching-related methods to [Expression].
extension ExpressionPatterns on Expression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LiteralExpression value)?  literal,TResult Function( BindingExpression value)?  binding,TResult Function( FieldAccessExpression value)?  fieldAccess,TResult Function( InterpolationExpression value)?  interpolation,TResult Function( ComparisonExpression value)?  comparison,TResult Function( BooleanExpression value)?  boolean,TResult Function( ArithmeticExpression value)?  arithmetic,TResult Function( ConditionalExpression value)?  conditional,TResult Function( CollectionMapExpression value)?  collectionMap,TResult Function( CollectionFilterExpression value)?  collectionFilter,TResult Function( CollectionQuantifierExpression value)?  collectionQuantifier,TResult Function( CollectionFindExpression value)?  collectionFind,TResult Function( CollectionCountExpression value)?  collectionCount,TResult Function( CollectionDistinctExpression value)?  collectionDistinct,TResult Function( CollectionSortExpression value)?  collectionSort,TResult Function( CollectionGroupExpression value)?  collectionGroup,TResult Function( CollectionReduceExpression value)?  collectionReduce,TResult Function( CollectionFoldExpression value)?  collectionFold,TResult Function( CollectionTransformExpression value)?  collectionTransform,TResult Function( IsTypeExpression value)?  isType,TResult Function( ConversionExpression value)?  conversion,TResult Function( StringOperationExpression value)?  stringOperation,TResult Function( CollectionOperationExpression value)?  collectionOperation,TResult Function( RegexExpression value)?  regex,TResult Function( CoalesceExpression value)?  coalesce,TResult Function( ColorOperationExpression value)?  colorOperation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that);case BindingExpression() when binding != null:
return binding(_that);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that);case InterpolationExpression() when interpolation != null:
return interpolation(_that);case ComparisonExpression() when comparison != null:
return comparison(_that);case BooleanExpression() when boolean != null:
return boolean(_that);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that);case ConditionalExpression() when conditional != null:
return conditional(_that);case CollectionMapExpression() when collectionMap != null:
return collectionMap(_that);case CollectionFilterExpression() when collectionFilter != null:
return collectionFilter(_that);case CollectionQuantifierExpression() when collectionQuantifier != null:
return collectionQuantifier(_that);case CollectionFindExpression() when collectionFind != null:
return collectionFind(_that);case CollectionCountExpression() when collectionCount != null:
return collectionCount(_that);case CollectionDistinctExpression() when collectionDistinct != null:
return collectionDistinct(_that);case CollectionSortExpression() when collectionSort != null:
return collectionSort(_that);case CollectionGroupExpression() when collectionGroup != null:
return collectionGroup(_that);case CollectionReduceExpression() when collectionReduce != null:
return collectionReduce(_that);case CollectionFoldExpression() when collectionFold != null:
return collectionFold(_that);case CollectionTransformExpression() when collectionTransform != null:
return collectionTransform(_that);case IsTypeExpression() when isType != null:
return isType(_that);case ConversionExpression() when conversion != null:
return conversion(_that);case StringOperationExpression() when stringOperation != null:
return stringOperation(_that);case CollectionOperationExpression() when collectionOperation != null:
return collectionOperation(_that);case RegexExpression() when regex != null:
return regex(_that);case CoalesceExpression() when coalesce != null:
return coalesce(_that);case ColorOperationExpression() when colorOperation != null:
return colorOperation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LiteralExpression value)  literal,required TResult Function( BindingExpression value)  binding,required TResult Function( FieldAccessExpression value)  fieldAccess,required TResult Function( InterpolationExpression value)  interpolation,required TResult Function( ComparisonExpression value)  comparison,required TResult Function( BooleanExpression value)  boolean,required TResult Function( ArithmeticExpression value)  arithmetic,required TResult Function( ConditionalExpression value)  conditional,required TResult Function( CollectionMapExpression value)  collectionMap,required TResult Function( CollectionFilterExpression value)  collectionFilter,required TResult Function( CollectionQuantifierExpression value)  collectionQuantifier,required TResult Function( CollectionFindExpression value)  collectionFind,required TResult Function( CollectionCountExpression value)  collectionCount,required TResult Function( CollectionDistinctExpression value)  collectionDistinct,required TResult Function( CollectionSortExpression value)  collectionSort,required TResult Function( CollectionGroupExpression value)  collectionGroup,required TResult Function( CollectionReduceExpression value)  collectionReduce,required TResult Function( CollectionFoldExpression value)  collectionFold,required TResult Function( CollectionTransformExpression value)  collectionTransform,required TResult Function( IsTypeExpression value)  isType,required TResult Function( ConversionExpression value)  conversion,required TResult Function( StringOperationExpression value)  stringOperation,required TResult Function( CollectionOperationExpression value)  collectionOperation,required TResult Function( RegexExpression value)  regex,required TResult Function( CoalesceExpression value)  coalesce,required TResult Function( ColorOperationExpression value)  colorOperation,}){
final _that = this;
switch (_that) {
case LiteralExpression():
return literal(_that);case BindingExpression():
return binding(_that);case FieldAccessExpression():
return fieldAccess(_that);case InterpolationExpression():
return interpolation(_that);case ComparisonExpression():
return comparison(_that);case BooleanExpression():
return boolean(_that);case ArithmeticExpression():
return arithmetic(_that);case ConditionalExpression():
return conditional(_that);case CollectionMapExpression():
return collectionMap(_that);case CollectionFilterExpression():
return collectionFilter(_that);case CollectionQuantifierExpression():
return collectionQuantifier(_that);case CollectionFindExpression():
return collectionFind(_that);case CollectionCountExpression():
return collectionCount(_that);case CollectionDistinctExpression():
return collectionDistinct(_that);case CollectionSortExpression():
return collectionSort(_that);case CollectionGroupExpression():
return collectionGroup(_that);case CollectionReduceExpression():
return collectionReduce(_that);case CollectionFoldExpression():
return collectionFold(_that);case CollectionTransformExpression():
return collectionTransform(_that);case IsTypeExpression():
return isType(_that);case ConversionExpression():
return conversion(_that);case StringOperationExpression():
return stringOperation(_that);case CollectionOperationExpression():
return collectionOperation(_that);case RegexExpression():
return regex(_that);case CoalesceExpression():
return coalesce(_that);case ColorOperationExpression():
return colorOperation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LiteralExpression value)?  literal,TResult? Function( BindingExpression value)?  binding,TResult? Function( FieldAccessExpression value)?  fieldAccess,TResult? Function( InterpolationExpression value)?  interpolation,TResult? Function( ComparisonExpression value)?  comparison,TResult? Function( BooleanExpression value)?  boolean,TResult? Function( ArithmeticExpression value)?  arithmetic,TResult? Function( ConditionalExpression value)?  conditional,TResult? Function( CollectionMapExpression value)?  collectionMap,TResult? Function( CollectionFilterExpression value)?  collectionFilter,TResult? Function( CollectionQuantifierExpression value)?  collectionQuantifier,TResult? Function( CollectionFindExpression value)?  collectionFind,TResult? Function( CollectionCountExpression value)?  collectionCount,TResult? Function( CollectionDistinctExpression value)?  collectionDistinct,TResult? Function( CollectionSortExpression value)?  collectionSort,TResult? Function( CollectionGroupExpression value)?  collectionGroup,TResult? Function( CollectionReduceExpression value)?  collectionReduce,TResult? Function( CollectionFoldExpression value)?  collectionFold,TResult? Function( CollectionTransformExpression value)?  collectionTransform,TResult? Function( IsTypeExpression value)?  isType,TResult? Function( ConversionExpression value)?  conversion,TResult? Function( StringOperationExpression value)?  stringOperation,TResult? Function( CollectionOperationExpression value)?  collectionOperation,TResult? Function( RegexExpression value)?  regex,TResult? Function( CoalesceExpression value)?  coalesce,TResult? Function( ColorOperationExpression value)?  colorOperation,}){
final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that);case BindingExpression() when binding != null:
return binding(_that);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that);case InterpolationExpression() when interpolation != null:
return interpolation(_that);case ComparisonExpression() when comparison != null:
return comparison(_that);case BooleanExpression() when boolean != null:
return boolean(_that);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that);case ConditionalExpression() when conditional != null:
return conditional(_that);case CollectionMapExpression() when collectionMap != null:
return collectionMap(_that);case CollectionFilterExpression() when collectionFilter != null:
return collectionFilter(_that);case CollectionQuantifierExpression() when collectionQuantifier != null:
return collectionQuantifier(_that);case CollectionFindExpression() when collectionFind != null:
return collectionFind(_that);case CollectionCountExpression() when collectionCount != null:
return collectionCount(_that);case CollectionDistinctExpression() when collectionDistinct != null:
return collectionDistinct(_that);case CollectionSortExpression() when collectionSort != null:
return collectionSort(_that);case CollectionGroupExpression() when collectionGroup != null:
return collectionGroup(_that);case CollectionReduceExpression() when collectionReduce != null:
return collectionReduce(_that);case CollectionFoldExpression() when collectionFold != null:
return collectionFold(_that);case CollectionTransformExpression() when collectionTransform != null:
return collectionTransform(_that);case IsTypeExpression() when isType != null:
return isType(_that);case ConversionExpression() when conversion != null:
return conversion(_that);case StringOperationExpression() when stringOperation != null:
return stringOperation(_that);case CollectionOperationExpression() when collectionOperation != null:
return collectionOperation(_that);case RegexExpression() when regex != null:
return regex(_that);case CoalesceExpression() when coalesce != null:
return coalesce(_that);case ColorOperationExpression() when colorOperation != null:
return colorOperation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DataValue value)?  literal,TResult Function( BindingReference binding)?  binding,TResult Function( TypedExpression target,  String fieldName)?  fieldAccess,TResult Function( List<InterpolationPart> parts)?  interpolation,TResult Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)?  comparison,TResult Function( BooleanOperator operator,  List<TypedExpression> operands)?  boolean,TResult Function( ArithmeticOperator operator,  List<TypedExpression> operands)?  arithmetic,TResult Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)?  conditional,TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression transform)?  collectionMap,TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)?  collectionFilter,TResult Function( TypedExpression source,  CollectionQuantifier quantifier,  BindingId itemBindingId,  TypedExpression predicate)?  collectionQuantifier,TResult Function( TypedExpression source,  CollectionSelection selection,  BindingId itemBindingId,  TypedExpression predicate)?  collectionFind,TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)?  collectionCount,TResult Function( TypedExpression source,  TypedExpression? key,  BindingId? itemBindingId)?  collectionDistinct,TResult Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  CollectionSortDirection direction,  CollectionComparator? comparator)?  collectionSort,TResult Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  TypedExpression? value)?  collectionGroup,TResult Function( TypedExpression source,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)?  collectionReduce,TResult Function( TypedExpression source,  TypedExpression initial,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)?  collectionFold,TResult Function( TypedExpression source,  CollectionTransformOperation operation,  TypedExpression? transform,  BindingId? itemBindingId,  TypedExpression? count)?  collectionTransform,TResult Function( TypedExpression source,  TypeExpression type)?  isType,TResult Function( ConversionId conversionId,  TypedExpression input)?  conversion,TResult Function( StringOperation operation,  List<TypedExpression> operands)?  stringOperation,TResult Function( CollectionOperation operation,  List<TypedExpression> operands)?  collectionOperation,TResult Function( RegexOperation operation,  TypedExpression source,  String pattern,  int? group,  String? replacement)?  regex,TResult Function( List<TypedExpression> operands)?  coalesce,TResult Function( ColorOperation operation,  TypedExpression color,  TypedExpression alpha)?  colorOperation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that.value);case BindingExpression() when binding != null:
return binding(_that.binding);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression() when interpolation != null:
return interpolation(_that.parts);case ComparisonExpression() when comparison != null:
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression() when boolean != null:
return boolean(_that.operator,_that.operands);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that.operator,_that.operands);case ConditionalExpression() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionMapExpression() when collectionMap != null:
return collectionMap(_that.source,_that.itemBindingId,_that.transform);case CollectionFilterExpression() when collectionFilter != null:
return collectionFilter(_that.source,_that.itemBindingId,_that.predicate);case CollectionQuantifierExpression() when collectionQuantifier != null:
return collectionQuantifier(_that.source,_that.quantifier,_that.itemBindingId,_that.predicate);case CollectionFindExpression() when collectionFind != null:
return collectionFind(_that.source,_that.selection,_that.itemBindingId,_that.predicate);case CollectionCountExpression() when collectionCount != null:
return collectionCount(_that.source,_that.itemBindingId,_that.predicate);case CollectionDistinctExpression() when collectionDistinct != null:
return collectionDistinct(_that.source,_that.key,_that.itemBindingId);case CollectionSortExpression() when collectionSort != null:
return collectionSort(_that.source,_that.key,_that.itemBindingId,_that.direction,_that.comparator);case CollectionGroupExpression() when collectionGroup != null:
return collectionGroup(_that.source,_that.key,_that.itemBindingId,_that.value);case CollectionReduceExpression() when collectionReduce != null:
return collectionReduce(_that.source,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionFoldExpression() when collectionFold != null:
return collectionFold(_that.source,_that.initial,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionTransformExpression() when collectionTransform != null:
return collectionTransform(_that.source,_that.operation,_that.transform,_that.itemBindingId,_that.count);case IsTypeExpression() when isType != null:
return isType(_that.source,_that.type);case ConversionExpression() when conversion != null:
return conversion(_that.conversionId,_that.input);case StringOperationExpression() when stringOperation != null:
return stringOperation(_that.operation,_that.operands);case CollectionOperationExpression() when collectionOperation != null:
return collectionOperation(_that.operation,_that.operands);case RegexExpression() when regex != null:
return regex(_that.operation,_that.source,_that.pattern,_that.group,_that.replacement);case CoalesceExpression() when coalesce != null:
return coalesce(_that.operands);case ColorOperationExpression() when colorOperation != null:
return colorOperation(_that.operation,_that.color,_that.alpha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DataValue value)  literal,required TResult Function( BindingReference binding)  binding,required TResult Function( TypedExpression target,  String fieldName)  fieldAccess,required TResult Function( List<InterpolationPart> parts)  interpolation,required TResult Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)  comparison,required TResult Function( BooleanOperator operator,  List<TypedExpression> operands)  boolean,required TResult Function( ArithmeticOperator operator,  List<TypedExpression> operands)  arithmetic,required TResult Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)  conditional,required TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression transform)  collectionMap,required TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)  collectionFilter,required TResult Function( TypedExpression source,  CollectionQuantifier quantifier,  BindingId itemBindingId,  TypedExpression predicate)  collectionQuantifier,required TResult Function( TypedExpression source,  CollectionSelection selection,  BindingId itemBindingId,  TypedExpression predicate)  collectionFind,required TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)  collectionCount,required TResult Function( TypedExpression source,  TypedExpression? key,  BindingId? itemBindingId)  collectionDistinct,required TResult Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  CollectionSortDirection direction,  CollectionComparator? comparator)  collectionSort,required TResult Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  TypedExpression? value)  collectionGroup,required TResult Function( TypedExpression source,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)  collectionReduce,required TResult Function( TypedExpression source,  TypedExpression initial,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)  collectionFold,required TResult Function( TypedExpression source,  CollectionTransformOperation operation,  TypedExpression? transform,  BindingId? itemBindingId,  TypedExpression? count)  collectionTransform,required TResult Function( TypedExpression source,  TypeExpression type)  isType,required TResult Function( ConversionId conversionId,  TypedExpression input)  conversion,required TResult Function( StringOperation operation,  List<TypedExpression> operands)  stringOperation,required TResult Function( CollectionOperation operation,  List<TypedExpression> operands)  collectionOperation,required TResult Function( RegexOperation operation,  TypedExpression source,  String pattern,  int? group,  String? replacement)  regex,required TResult Function( List<TypedExpression> operands)  coalesce,required TResult Function( ColorOperation operation,  TypedExpression color,  TypedExpression alpha)  colorOperation,}) {final _that = this;
switch (_that) {
case LiteralExpression():
return literal(_that.value);case BindingExpression():
return binding(_that.binding);case FieldAccessExpression():
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression():
return interpolation(_that.parts);case ComparisonExpression():
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression():
return boolean(_that.operator,_that.operands);case ArithmeticExpression():
return arithmetic(_that.operator,_that.operands);case ConditionalExpression():
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionMapExpression():
return collectionMap(_that.source,_that.itemBindingId,_that.transform);case CollectionFilterExpression():
return collectionFilter(_that.source,_that.itemBindingId,_that.predicate);case CollectionQuantifierExpression():
return collectionQuantifier(_that.source,_that.quantifier,_that.itemBindingId,_that.predicate);case CollectionFindExpression():
return collectionFind(_that.source,_that.selection,_that.itemBindingId,_that.predicate);case CollectionCountExpression():
return collectionCount(_that.source,_that.itemBindingId,_that.predicate);case CollectionDistinctExpression():
return collectionDistinct(_that.source,_that.key,_that.itemBindingId);case CollectionSortExpression():
return collectionSort(_that.source,_that.key,_that.itemBindingId,_that.direction,_that.comparator);case CollectionGroupExpression():
return collectionGroup(_that.source,_that.key,_that.itemBindingId,_that.value);case CollectionReduceExpression():
return collectionReduce(_that.source,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionFoldExpression():
return collectionFold(_that.source,_that.initial,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionTransformExpression():
return collectionTransform(_that.source,_that.operation,_that.transform,_that.itemBindingId,_that.count);case IsTypeExpression():
return isType(_that.source,_that.type);case ConversionExpression():
return conversion(_that.conversionId,_that.input);case StringOperationExpression():
return stringOperation(_that.operation,_that.operands);case CollectionOperationExpression():
return collectionOperation(_that.operation,_that.operands);case RegexExpression():
return regex(_that.operation,_that.source,_that.pattern,_that.group,_that.replacement);case CoalesceExpression():
return coalesce(_that.operands);case ColorOperationExpression():
return colorOperation(_that.operation,_that.color,_that.alpha);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DataValue value)?  literal,TResult? Function( BindingReference binding)?  binding,TResult? Function( TypedExpression target,  String fieldName)?  fieldAccess,TResult? Function( List<InterpolationPart> parts)?  interpolation,TResult? Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)?  comparison,TResult? Function( BooleanOperator operator,  List<TypedExpression> operands)?  boolean,TResult? Function( ArithmeticOperator operator,  List<TypedExpression> operands)?  arithmetic,TResult? Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)?  conditional,TResult? Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression transform)?  collectionMap,TResult? Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)?  collectionFilter,TResult? Function( TypedExpression source,  CollectionQuantifier quantifier,  BindingId itemBindingId,  TypedExpression predicate)?  collectionQuantifier,TResult? Function( TypedExpression source,  CollectionSelection selection,  BindingId itemBindingId,  TypedExpression predicate)?  collectionFind,TResult? Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression predicate)?  collectionCount,TResult? Function( TypedExpression source,  TypedExpression? key,  BindingId? itemBindingId)?  collectionDistinct,TResult? Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  CollectionSortDirection direction,  CollectionComparator? comparator)?  collectionSort,TResult? Function( TypedExpression source,  TypedExpression key,  BindingId itemBindingId,  TypedExpression? value)?  collectionGroup,TResult? Function( TypedExpression source,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)?  collectionReduce,TResult? Function( TypedExpression source,  TypedExpression initial,  BindingId accumulatorBindingId,  BindingId itemBindingId,  TypedExpression reduction)?  collectionFold,TResult? Function( TypedExpression source,  CollectionTransformOperation operation,  TypedExpression? transform,  BindingId? itemBindingId,  TypedExpression? count)?  collectionTransform,TResult? Function( TypedExpression source,  TypeExpression type)?  isType,TResult? Function( ConversionId conversionId,  TypedExpression input)?  conversion,TResult? Function( StringOperation operation,  List<TypedExpression> operands)?  stringOperation,TResult? Function( CollectionOperation operation,  List<TypedExpression> operands)?  collectionOperation,TResult? Function( RegexOperation operation,  TypedExpression source,  String pattern,  int? group,  String? replacement)?  regex,TResult? Function( List<TypedExpression> operands)?  coalesce,TResult? Function( ColorOperation operation,  TypedExpression color,  TypedExpression alpha)?  colorOperation,}) {final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that.value);case BindingExpression() when binding != null:
return binding(_that.binding);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression() when interpolation != null:
return interpolation(_that.parts);case ComparisonExpression() when comparison != null:
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression() when boolean != null:
return boolean(_that.operator,_that.operands);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that.operator,_that.operands);case ConditionalExpression() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionMapExpression() when collectionMap != null:
return collectionMap(_that.source,_that.itemBindingId,_that.transform);case CollectionFilterExpression() when collectionFilter != null:
return collectionFilter(_that.source,_that.itemBindingId,_that.predicate);case CollectionQuantifierExpression() when collectionQuantifier != null:
return collectionQuantifier(_that.source,_that.quantifier,_that.itemBindingId,_that.predicate);case CollectionFindExpression() when collectionFind != null:
return collectionFind(_that.source,_that.selection,_that.itemBindingId,_that.predicate);case CollectionCountExpression() when collectionCount != null:
return collectionCount(_that.source,_that.itemBindingId,_that.predicate);case CollectionDistinctExpression() when collectionDistinct != null:
return collectionDistinct(_that.source,_that.key,_that.itemBindingId);case CollectionSortExpression() when collectionSort != null:
return collectionSort(_that.source,_that.key,_that.itemBindingId,_that.direction,_that.comparator);case CollectionGroupExpression() when collectionGroup != null:
return collectionGroup(_that.source,_that.key,_that.itemBindingId,_that.value);case CollectionReduceExpression() when collectionReduce != null:
return collectionReduce(_that.source,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionFoldExpression() when collectionFold != null:
return collectionFold(_that.source,_that.initial,_that.accumulatorBindingId,_that.itemBindingId,_that.reduction);case CollectionTransformExpression() when collectionTransform != null:
return collectionTransform(_that.source,_that.operation,_that.transform,_that.itemBindingId,_that.count);case IsTypeExpression() when isType != null:
return isType(_that.source,_that.type);case ConversionExpression() when conversion != null:
return conversion(_that.conversionId,_that.input);case StringOperationExpression() when stringOperation != null:
return stringOperation(_that.operation,_that.operands);case CollectionOperationExpression() when collectionOperation != null:
return collectionOperation(_that.operation,_that.operands);case RegexExpression() when regex != null:
return regex(_that.operation,_that.source,_that.pattern,_that.group,_that.replacement);case CoalesceExpression() when coalesce != null:
return coalesce(_that.operands);case ColorOperationExpression() when colorOperation != null:
return colorOperation(_that.operation,_that.color,_that.alpha);case _:
  return null;

}
}

}

/// @nodoc


class LiteralExpression implements Expression {
  const LiteralExpression(this.value);
  

 final  DataValue value;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiteralExpressionCopyWith<LiteralExpression> get copyWith => _$LiteralExpressionCopyWithImpl<LiteralExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiteralExpression&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Expression.literal(value: $value)';
}


}

/// @nodoc
abstract mixin class $LiteralExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $LiteralExpressionCopyWith(LiteralExpression value, $Res Function(LiteralExpression) _then) = _$LiteralExpressionCopyWithImpl;
@useResult
$Res call({
 DataValue value
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$LiteralExpressionCopyWithImpl<$Res>
    implements $LiteralExpressionCopyWith<$Res> {
  _$LiteralExpressionCopyWithImpl(this._self, this._then);

  final LiteralExpression _self;
  final $Res Function(LiteralExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(LiteralExpression(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class BindingExpression implements Expression {
  const BindingExpression(this.binding);
  

 final  BindingReference binding;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingExpressionCopyWith<BindingExpression> get copyWith => _$BindingExpressionCopyWithImpl<BindingExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BindingExpression&&(identical(other.binding, binding) || other.binding == binding));
}


@override
int get hashCode => Object.hash(runtimeType,binding);

@override
String toString() {
  return 'Expression.binding(binding: $binding)';
}


}

/// @nodoc
abstract mixin class $BindingExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $BindingExpressionCopyWith(BindingExpression value, $Res Function(BindingExpression) _then) = _$BindingExpressionCopyWithImpl;
@useResult
$Res call({
 BindingReference binding
});


$BindingReferenceCopyWith<$Res> get binding;

}
/// @nodoc
class _$BindingExpressionCopyWithImpl<$Res>
    implements $BindingExpressionCopyWith<$Res> {
  _$BindingExpressionCopyWithImpl(this._self, this._then);

  final BindingExpression _self;
  final $Res Function(BindingExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,}) {
  return _then(BindingExpression(
null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}
}

/// @nodoc


class FieldAccessExpression implements Expression {
  const FieldAccessExpression({required this.target, required this.fieldName}): assert(fieldName != "", 'Field name must not be empty.');
  

 final  TypedExpression target;
 final  String fieldName;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldAccessExpressionCopyWith<FieldAccessExpression> get copyWith => _$FieldAccessExpressionCopyWithImpl<FieldAccessExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldAccessExpression&&(identical(other.target, target) || other.target == target)&&(identical(other.fieldName, fieldName) || other.fieldName == fieldName));
}


@override
int get hashCode => Object.hash(runtimeType,target,fieldName);

@override
String toString() {
  return 'Expression.fieldAccess(target: $target, fieldName: $fieldName)';
}


}

/// @nodoc
abstract mixin class $FieldAccessExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $FieldAccessExpressionCopyWith(FieldAccessExpression value, $Res Function(FieldAccessExpression) _then) = _$FieldAccessExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression target, String fieldName
});


$TypedExpressionCopyWith<$Res> get target;

}
/// @nodoc
class _$FieldAccessExpressionCopyWithImpl<$Res>
    implements $FieldAccessExpressionCopyWith<$Res> {
  _$FieldAccessExpressionCopyWithImpl(this._self, this._then);

  final FieldAccessExpression _self;
  final $Res Function(FieldAccessExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? fieldName = null,}) {
  return _then(FieldAccessExpression(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TypedExpression,fieldName: null == fieldName ? _self.fieldName : fieldName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get target {
  
  return $TypedExpressionCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class InterpolationExpression implements Expression {
  const InterpolationExpression(final  List<InterpolationPart> parts): _parts = parts;
  

 final  List<InterpolationPart> _parts;
 List<InterpolationPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpolationExpressionCopyWith<InterpolationExpression> get copyWith => _$InterpolationExpressionCopyWithImpl<InterpolationExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpolationExpression&&const DeepCollectionEquality().equals(other._parts, _parts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_parts));

@override
String toString() {
  return 'Expression.interpolation(parts: $parts)';
}


}

/// @nodoc
abstract mixin class $InterpolationExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $InterpolationExpressionCopyWith(InterpolationExpression value, $Res Function(InterpolationExpression) _then) = _$InterpolationExpressionCopyWithImpl;
@useResult
$Res call({
 List<InterpolationPart> parts
});




}
/// @nodoc
class _$InterpolationExpressionCopyWithImpl<$Res>
    implements $InterpolationExpressionCopyWith<$Res> {
  _$InterpolationExpressionCopyWithImpl(this._self, this._then);

  final InterpolationExpression _self;
  final $Res Function(InterpolationExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? parts = null,}) {
  return _then(InterpolationExpression(
null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<InterpolationPart>,
  ));
}


}

/// @nodoc


class ComparisonExpression implements Expression {
  const ComparisonExpression({required this.operator, required this.left, required this.right});
  

 final  ComparisonOperator operator;
 final  TypedExpression left;
 final  TypedExpression right;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComparisonExpressionCopyWith<ComparisonExpression> get copyWith => _$ComparisonExpressionCopyWithImpl<ComparisonExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComparisonExpression&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}


@override
int get hashCode => Object.hash(runtimeType,operator,left,right);

@override
String toString() {
  return 'Expression.comparison(operator: $operator, left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class $ComparisonExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $ComparisonExpressionCopyWith(ComparisonExpression value, $Res Function(ComparisonExpression) _then) = _$ComparisonExpressionCopyWithImpl;
@useResult
$Res call({
 ComparisonOperator operator, TypedExpression left, TypedExpression right
});


$TypedExpressionCopyWith<$Res> get left;$TypedExpressionCopyWith<$Res> get right;

}
/// @nodoc
class _$ComparisonExpressionCopyWithImpl<$Res>
    implements $ComparisonExpressionCopyWith<$Res> {
  _$ComparisonExpressionCopyWithImpl(this._self, this._then);

  final ComparisonExpression _self;
  final $Res Function(ComparisonExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operator = null,Object? left = null,Object? right = null,}) {
  return _then(ComparisonExpression(
operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as ComparisonOperator,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as TypedExpression,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get left {
  
  return $TypedExpressionCopyWith<$Res>(_self.left, (value) {
    return _then(_self.copyWith(left: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get right {
  
  return $TypedExpressionCopyWith<$Res>(_self.right, (value) {
    return _then(_self.copyWith(right: value));
  });
}
}

/// @nodoc


class BooleanExpression implements Expression {
  const BooleanExpression({required this.operator, required final  List<TypedExpression> operands}): _operands = operands;
  

 final  BooleanOperator operator;
 final  List<TypedExpression> _operands;
 List<TypedExpression> get operands {
  if (_operands is EqualUnmodifiableListView) return _operands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operands);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BooleanExpressionCopyWith<BooleanExpression> get copyWith => _$BooleanExpressionCopyWithImpl<BooleanExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BooleanExpression&&(identical(other.operator, operator) || other.operator == operator)&&const DeepCollectionEquality().equals(other._operands, _operands));
}


@override
int get hashCode => Object.hash(runtimeType,operator,const DeepCollectionEquality().hash(_operands));

@override
String toString() {
  return 'Expression.boolean(operator: $operator, operands: $operands)';
}


}

/// @nodoc
abstract mixin class $BooleanExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $BooleanExpressionCopyWith(BooleanExpression value, $Res Function(BooleanExpression) _then) = _$BooleanExpressionCopyWithImpl;
@useResult
$Res call({
 BooleanOperator operator, List<TypedExpression> operands
});




}
/// @nodoc
class _$BooleanExpressionCopyWithImpl<$Res>
    implements $BooleanExpressionCopyWith<$Res> {
  _$BooleanExpressionCopyWithImpl(this._self, this._then);

  final BooleanExpression _self;
  final $Res Function(BooleanExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operator = null,Object? operands = null,}) {
  return _then(BooleanExpression(
operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as BooleanOperator,operands: null == operands ? _self._operands : operands // ignore: cast_nullable_to_non_nullable
as List<TypedExpression>,
  ));
}


}

/// @nodoc


class ArithmeticExpression implements Expression {
  const ArithmeticExpression({required this.operator, required final  List<TypedExpression> operands}): _operands = operands;
  

 final  ArithmeticOperator operator;
 final  List<TypedExpression> _operands;
 List<TypedExpression> get operands {
  if (_operands is EqualUnmodifiableListView) return _operands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operands);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArithmeticExpressionCopyWith<ArithmeticExpression> get copyWith => _$ArithmeticExpressionCopyWithImpl<ArithmeticExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArithmeticExpression&&(identical(other.operator, operator) || other.operator == operator)&&const DeepCollectionEquality().equals(other._operands, _operands));
}


@override
int get hashCode => Object.hash(runtimeType,operator,const DeepCollectionEquality().hash(_operands));

@override
String toString() {
  return 'Expression.arithmetic(operator: $operator, operands: $operands)';
}


}

/// @nodoc
abstract mixin class $ArithmeticExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $ArithmeticExpressionCopyWith(ArithmeticExpression value, $Res Function(ArithmeticExpression) _then) = _$ArithmeticExpressionCopyWithImpl;
@useResult
$Res call({
 ArithmeticOperator operator, List<TypedExpression> operands
});




}
/// @nodoc
class _$ArithmeticExpressionCopyWithImpl<$Res>
    implements $ArithmeticExpressionCopyWith<$Res> {
  _$ArithmeticExpressionCopyWithImpl(this._self, this._then);

  final ArithmeticExpression _self;
  final $Res Function(ArithmeticExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operator = null,Object? operands = null,}) {
  return _then(ArithmeticExpression(
operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as ArithmeticOperator,operands: null == operands ? _self._operands : operands // ignore: cast_nullable_to_non_nullable
as List<TypedExpression>,
  ));
}


}

/// @nodoc


class ConditionalExpression implements Expression {
  const ConditionalExpression({required this.condition, required this.whenTrue, required this.whenFalse});
  

 final  TypedExpression condition;
 final  TypedExpression whenTrue;
 final  TypedExpression whenFalse;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConditionalExpressionCopyWith<ConditionalExpression> get copyWith => _$ConditionalExpressionCopyWithImpl<ConditionalExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConditionalExpression&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.whenTrue, whenTrue) || other.whenTrue == whenTrue)&&(identical(other.whenFalse, whenFalse) || other.whenFalse == whenFalse));
}


@override
int get hashCode => Object.hash(runtimeType,condition,whenTrue,whenFalse);

@override
String toString() {
  return 'Expression.conditional(condition: $condition, whenTrue: $whenTrue, whenFalse: $whenFalse)';
}


}

/// @nodoc
abstract mixin class $ConditionalExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $ConditionalExpressionCopyWith(ConditionalExpression value, $Res Function(ConditionalExpression) _then) = _$ConditionalExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression condition, TypedExpression whenTrue, TypedExpression whenFalse
});


$TypedExpressionCopyWith<$Res> get condition;$TypedExpressionCopyWith<$Res> get whenTrue;$TypedExpressionCopyWith<$Res> get whenFalse;

}
/// @nodoc
class _$ConditionalExpressionCopyWithImpl<$Res>
    implements $ConditionalExpressionCopyWith<$Res> {
  _$ConditionalExpressionCopyWithImpl(this._self, this._then);

  final ConditionalExpression _self;
  final $Res Function(ConditionalExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? condition = null,Object? whenTrue = null,Object? whenFalse = null,}) {
  return _then(ConditionalExpression(
condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as TypedExpression,whenTrue: null == whenTrue ? _self.whenTrue : whenTrue // ignore: cast_nullable_to_non_nullable
as TypedExpression,whenFalse: null == whenFalse ? _self.whenFalse : whenFalse // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get condition {
  
  return $TypedExpressionCopyWith<$Res>(_self.condition, (value) {
    return _then(_self.copyWith(condition: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get whenTrue {
  
  return $TypedExpressionCopyWith<$Res>(_self.whenTrue, (value) {
    return _then(_self.copyWith(whenTrue: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get whenFalse {
  
  return $TypedExpressionCopyWith<$Res>(_self.whenFalse, (value) {
    return _then(_self.copyWith(whenFalse: value));
  });
}
}

/// @nodoc


class CollectionMapExpression implements Expression {
  const CollectionMapExpression({required this.source, required this.itemBindingId, required this.transform});
  

 final  TypedExpression source;
 final  BindingId itemBindingId;
 final  TypedExpression transform;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionMapExpressionCopyWith<CollectionMapExpression> get copyWith => _$CollectionMapExpressionCopyWithImpl<CollectionMapExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMapExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.transform, transform) || other.transform == transform));
}


@override
int get hashCode => Object.hash(runtimeType,source,itemBindingId,transform);

@override
String toString() {
  return 'Expression.collectionMap(source: $source, itemBindingId: $itemBindingId, transform: $transform)';
}


}

/// @nodoc
abstract mixin class $CollectionMapExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionMapExpressionCopyWith(CollectionMapExpression value, $Res Function(CollectionMapExpression) _then) = _$CollectionMapExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId itemBindingId, TypedExpression transform
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get transform;

}
/// @nodoc
class _$CollectionMapExpressionCopyWithImpl<$Res>
    implements $CollectionMapExpressionCopyWith<$Res> {
  _$CollectionMapExpressionCopyWithImpl(this._self, this._then);

  final CollectionMapExpression _self;
  final $Res Function(CollectionMapExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? itemBindingId = null,Object? transform = null,}) {
  return _then(CollectionMapExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get transform {
  
  return $TypedExpressionCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}

/// @nodoc


class CollectionFilterExpression implements Expression {
  const CollectionFilterExpression({required this.source, required this.itemBindingId, required this.predicate});
  

 final  TypedExpression source;
 final  BindingId itemBindingId;
 final  TypedExpression predicate;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionFilterExpressionCopyWith<CollectionFilterExpression> get copyWith => _$CollectionFilterExpressionCopyWithImpl<CollectionFilterExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionFilterExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}


@override
int get hashCode => Object.hash(runtimeType,source,itemBindingId,predicate);

@override
String toString() {
  return 'Expression.collectionFilter(source: $source, itemBindingId: $itemBindingId, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class $CollectionFilterExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionFilterExpressionCopyWith(CollectionFilterExpression value, $Res Function(CollectionFilterExpression) _then) = _$CollectionFilterExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId itemBindingId, TypedExpression predicate
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get predicate;

}
/// @nodoc
class _$CollectionFilterExpressionCopyWithImpl<$Res>
    implements $CollectionFilterExpressionCopyWith<$Res> {
  _$CollectionFilterExpressionCopyWithImpl(this._self, this._then);

  final CollectionFilterExpression _self;
  final $Res Function(CollectionFilterExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? itemBindingId = null,Object? predicate = null,}) {
  return _then(CollectionFilterExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,predicate: null == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get predicate {
  
  return $TypedExpressionCopyWith<$Res>(_self.predicate, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}

/// @nodoc


class CollectionQuantifierExpression implements Expression {
  const CollectionQuantifierExpression({required this.source, required this.quantifier, required this.itemBindingId, required this.predicate});
  

 final  TypedExpression source;
 final  CollectionQuantifier quantifier;
 final  BindingId itemBindingId;
 final  TypedExpression predicate;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionQuantifierExpressionCopyWith<CollectionQuantifierExpression> get copyWith => _$CollectionQuantifierExpressionCopyWithImpl<CollectionQuantifierExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionQuantifierExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.quantifier, quantifier) || other.quantifier == quantifier)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}


@override
int get hashCode => Object.hash(runtimeType,source,quantifier,itemBindingId,predicate);

@override
String toString() {
  return 'Expression.collectionQuantifier(source: $source, quantifier: $quantifier, itemBindingId: $itemBindingId, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class $CollectionQuantifierExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionQuantifierExpressionCopyWith(CollectionQuantifierExpression value, $Res Function(CollectionQuantifierExpression) _then) = _$CollectionQuantifierExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, CollectionQuantifier quantifier, BindingId itemBindingId, TypedExpression predicate
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get predicate;

}
/// @nodoc
class _$CollectionQuantifierExpressionCopyWithImpl<$Res>
    implements $CollectionQuantifierExpressionCopyWith<$Res> {
  _$CollectionQuantifierExpressionCopyWithImpl(this._self, this._then);

  final CollectionQuantifierExpression _self;
  final $Res Function(CollectionQuantifierExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? quantifier = null,Object? itemBindingId = null,Object? predicate = null,}) {
  return _then(CollectionQuantifierExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,quantifier: null == quantifier ? _self.quantifier : quantifier // ignore: cast_nullable_to_non_nullable
as CollectionQuantifier,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,predicate: null == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get predicate {
  
  return $TypedExpressionCopyWith<$Res>(_self.predicate, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}

/// @nodoc


class CollectionFindExpression implements Expression {
  const CollectionFindExpression({required this.source, required this.selection, required this.itemBindingId, required this.predicate});
  

 final  TypedExpression source;
 final  CollectionSelection selection;
 final  BindingId itemBindingId;
 final  TypedExpression predicate;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionFindExpressionCopyWith<CollectionFindExpression> get copyWith => _$CollectionFindExpressionCopyWithImpl<CollectionFindExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionFindExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}


@override
int get hashCode => Object.hash(runtimeType,source,selection,itemBindingId,predicate);

@override
String toString() {
  return 'Expression.collectionFind(source: $source, selection: $selection, itemBindingId: $itemBindingId, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class $CollectionFindExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionFindExpressionCopyWith(CollectionFindExpression value, $Res Function(CollectionFindExpression) _then) = _$CollectionFindExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, CollectionSelection selection, BindingId itemBindingId, TypedExpression predicate
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get predicate;

}
/// @nodoc
class _$CollectionFindExpressionCopyWithImpl<$Res>
    implements $CollectionFindExpressionCopyWith<$Res> {
  _$CollectionFindExpressionCopyWithImpl(this._self, this._then);

  final CollectionFindExpression _self;
  final $Res Function(CollectionFindExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? selection = null,Object? itemBindingId = null,Object? predicate = null,}) {
  return _then(CollectionFindExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as CollectionSelection,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,predicate: null == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get predicate {
  
  return $TypedExpressionCopyWith<$Res>(_self.predicate, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}

/// @nodoc


class CollectionCountExpression implements Expression {
  const CollectionCountExpression({required this.source, required this.itemBindingId, required this.predicate});
  

 final  TypedExpression source;
 final  BindingId itemBindingId;
 final  TypedExpression predicate;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionCountExpressionCopyWith<CollectionCountExpression> get copyWith => _$CollectionCountExpressionCopyWithImpl<CollectionCountExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionCountExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}


@override
int get hashCode => Object.hash(runtimeType,source,itemBindingId,predicate);

@override
String toString() {
  return 'Expression.collectionCount(source: $source, itemBindingId: $itemBindingId, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class $CollectionCountExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionCountExpressionCopyWith(CollectionCountExpression value, $Res Function(CollectionCountExpression) _then) = _$CollectionCountExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId itemBindingId, TypedExpression predicate
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get predicate;

}
/// @nodoc
class _$CollectionCountExpressionCopyWithImpl<$Res>
    implements $CollectionCountExpressionCopyWith<$Res> {
  _$CollectionCountExpressionCopyWithImpl(this._self, this._then);

  final CollectionCountExpression _self;
  final $Res Function(CollectionCountExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? itemBindingId = null,Object? predicate = null,}) {
  return _then(CollectionCountExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,predicate: null == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get predicate {
  
  return $TypedExpressionCopyWith<$Res>(_self.predicate, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}

/// @nodoc


class CollectionDistinctExpression implements Expression {
  const CollectionDistinctExpression({required this.source, this.key, this.itemBindingId});
  

 final  TypedExpression source;
 final  TypedExpression? key;
 final  BindingId? itemBindingId;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionDistinctExpressionCopyWith<CollectionDistinctExpression> get copyWith => _$CollectionDistinctExpressionCopyWithImpl<CollectionDistinctExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionDistinctExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.key, key) || other.key == key)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId));
}


@override
int get hashCode => Object.hash(runtimeType,source,key,itemBindingId);

@override
String toString() {
  return 'Expression.collectionDistinct(source: $source, key: $key, itemBindingId: $itemBindingId)';
}


}

/// @nodoc
abstract mixin class $CollectionDistinctExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionDistinctExpressionCopyWith(CollectionDistinctExpression value, $Res Function(CollectionDistinctExpression) _then) = _$CollectionDistinctExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypedExpression? key, BindingId? itemBindingId
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res>? get key;$BindingIdCopyWith<$Res>? get itemBindingId;

}
/// @nodoc
class _$CollectionDistinctExpressionCopyWithImpl<$Res>
    implements $CollectionDistinctExpressionCopyWith<$Res> {
  _$CollectionDistinctExpressionCopyWithImpl(this._self, this._then);

  final CollectionDistinctExpression _self;
  final $Res Function(CollectionDistinctExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? key = freezed,Object? itemBindingId = freezed,}) {
  return _then(CollectionDistinctExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression?,itemBindingId: freezed == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId?,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get key {
    if (_self.key == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.key!, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res>? get itemBindingId {
    if (_self.itemBindingId == null) {
    return null;
  }

  return $BindingIdCopyWith<$Res>(_self.itemBindingId!, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}
}

/// @nodoc


class CollectionSortExpression implements Expression {
  const CollectionSortExpression({required this.source, required this.key, required this.itemBindingId, required this.direction, this.comparator});
  

 final  TypedExpression source;
 final  TypedExpression key;
 final  BindingId itemBindingId;
 final  CollectionSortDirection direction;
 final  CollectionComparator? comparator;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionSortExpressionCopyWith<CollectionSortExpression> get copyWith => _$CollectionSortExpressionCopyWithImpl<CollectionSortExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionSortExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.key, key) || other.key == key)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.comparator, comparator) || other.comparator == comparator));
}


@override
int get hashCode => Object.hash(runtimeType,source,key,itemBindingId,direction,comparator);

@override
String toString() {
  return 'Expression.collectionSort(source: $source, key: $key, itemBindingId: $itemBindingId, direction: $direction, comparator: $comparator)';
}


}

/// @nodoc
abstract mixin class $CollectionSortExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionSortExpressionCopyWith(CollectionSortExpression value, $Res Function(CollectionSortExpression) _then) = _$CollectionSortExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypedExpression key, BindingId itemBindingId, CollectionSortDirection direction, CollectionComparator? comparator
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res> get key;$BindingIdCopyWith<$Res> get itemBindingId;$CollectionComparatorCopyWith<$Res>? get comparator;

}
/// @nodoc
class _$CollectionSortExpressionCopyWithImpl<$Res>
    implements $CollectionSortExpressionCopyWith<$Res> {
  _$CollectionSortExpressionCopyWithImpl(this._self, this._then);

  final CollectionSortExpression _self;
  final $Res Function(CollectionSortExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? key = null,Object? itemBindingId = null,Object? direction = null,Object? comparator = freezed,}) {
  return _then(CollectionSortExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CollectionSortDirection,comparator: freezed == comparator ? _self.comparator : comparator // ignore: cast_nullable_to_non_nullable
as CollectionComparator?,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CollectionComparatorCopyWith<$Res>? get comparator {
    if (_self.comparator == null) {
    return null;
  }

  return $CollectionComparatorCopyWith<$Res>(_self.comparator!, (value) {
    return _then(_self.copyWith(comparator: value));
  });
}
}

/// @nodoc


class CollectionGroupExpression implements Expression {
  const CollectionGroupExpression({required this.source, required this.key, required this.itemBindingId, this.value});
  

 final  TypedExpression source;
 final  TypedExpression key;
 final  BindingId itemBindingId;
 final  TypedExpression? value;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionGroupExpressionCopyWith<CollectionGroupExpression> get copyWith => _$CollectionGroupExpressionCopyWithImpl<CollectionGroupExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionGroupExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.key, key) || other.key == key)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,source,key,itemBindingId,value);

@override
String toString() {
  return 'Expression.collectionGroup(source: $source, key: $key, itemBindingId: $itemBindingId, value: $value)';
}


}

/// @nodoc
abstract mixin class $CollectionGroupExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionGroupExpressionCopyWith(CollectionGroupExpression value, $Res Function(CollectionGroupExpression) _then) = _$CollectionGroupExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypedExpression key, BindingId itemBindingId, TypedExpression? value
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res> get key;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res>? get value;

}
/// @nodoc
class _$CollectionGroupExpressionCopyWithImpl<$Res>
    implements $CollectionGroupExpressionCopyWith<$Res> {
  _$CollectionGroupExpressionCopyWithImpl(this._self, this._then);

  final CollectionGroupExpression _self;
  final $Res Function(CollectionGroupExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? key = null,Object? itemBindingId = null,Object? value = freezed,}) {
  return _then(CollectionGroupExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get value {
    if (_self.value == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.value!, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class CollectionReduceExpression implements Expression {
  const CollectionReduceExpression({required this.source, required this.accumulatorBindingId, required this.itemBindingId, required this.reduction});
  

 final  TypedExpression source;
 final  BindingId accumulatorBindingId;
 final  BindingId itemBindingId;
 final  TypedExpression reduction;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionReduceExpressionCopyWith<CollectionReduceExpression> get copyWith => _$CollectionReduceExpressionCopyWithImpl<CollectionReduceExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionReduceExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.accumulatorBindingId, accumulatorBindingId) || other.accumulatorBindingId == accumulatorBindingId)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.reduction, reduction) || other.reduction == reduction));
}


@override
int get hashCode => Object.hash(runtimeType,source,accumulatorBindingId,itemBindingId,reduction);

@override
String toString() {
  return 'Expression.collectionReduce(source: $source, accumulatorBindingId: $accumulatorBindingId, itemBindingId: $itemBindingId, reduction: $reduction)';
}


}

/// @nodoc
abstract mixin class $CollectionReduceExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionReduceExpressionCopyWith(CollectionReduceExpression value, $Res Function(CollectionReduceExpression) _then) = _$CollectionReduceExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId accumulatorBindingId, BindingId itemBindingId, TypedExpression reduction
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get accumulatorBindingId;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get reduction;

}
/// @nodoc
class _$CollectionReduceExpressionCopyWithImpl<$Res>
    implements $CollectionReduceExpressionCopyWith<$Res> {
  _$CollectionReduceExpressionCopyWithImpl(this._self, this._then);

  final CollectionReduceExpression _self;
  final $Res Function(CollectionReduceExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? accumulatorBindingId = null,Object? itemBindingId = null,Object? reduction = null,}) {
  return _then(CollectionReduceExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,accumulatorBindingId: null == accumulatorBindingId ? _self.accumulatorBindingId : accumulatorBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,reduction: null == reduction ? _self.reduction : reduction // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get accumulatorBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.accumulatorBindingId, (value) {
    return _then(_self.copyWith(accumulatorBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get reduction {
  
  return $TypedExpressionCopyWith<$Res>(_self.reduction, (value) {
    return _then(_self.copyWith(reduction: value));
  });
}
}

/// @nodoc


class CollectionFoldExpression implements Expression {
  const CollectionFoldExpression({required this.source, required this.initial, required this.accumulatorBindingId, required this.itemBindingId, required this.reduction});
  

 final  TypedExpression source;
 final  TypedExpression initial;
 final  BindingId accumulatorBindingId;
 final  BindingId itemBindingId;
 final  TypedExpression reduction;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionFoldExpressionCopyWith<CollectionFoldExpression> get copyWith => _$CollectionFoldExpressionCopyWithImpl<CollectionFoldExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionFoldExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.accumulatorBindingId, accumulatorBindingId) || other.accumulatorBindingId == accumulatorBindingId)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.reduction, reduction) || other.reduction == reduction));
}


@override
int get hashCode => Object.hash(runtimeType,source,initial,accumulatorBindingId,itemBindingId,reduction);

@override
String toString() {
  return 'Expression.collectionFold(source: $source, initial: $initial, accumulatorBindingId: $accumulatorBindingId, itemBindingId: $itemBindingId, reduction: $reduction)';
}


}

/// @nodoc
abstract mixin class $CollectionFoldExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionFoldExpressionCopyWith(CollectionFoldExpression value, $Res Function(CollectionFoldExpression) _then) = _$CollectionFoldExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypedExpression initial, BindingId accumulatorBindingId, BindingId itemBindingId, TypedExpression reduction
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res> get initial;$BindingIdCopyWith<$Res> get accumulatorBindingId;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get reduction;

}
/// @nodoc
class _$CollectionFoldExpressionCopyWithImpl<$Res>
    implements $CollectionFoldExpressionCopyWith<$Res> {
  _$CollectionFoldExpressionCopyWithImpl(this._self, this._then);

  final CollectionFoldExpression _self;
  final $Res Function(CollectionFoldExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? initial = null,Object? accumulatorBindingId = null,Object? itemBindingId = null,Object? reduction = null,}) {
  return _then(CollectionFoldExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as TypedExpression,accumulatorBindingId: null == accumulatorBindingId ? _self.accumulatorBindingId : accumulatorBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,reduction: null == reduction ? _self.reduction : reduction // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get initial {
  
  return $TypedExpressionCopyWith<$Res>(_self.initial, (value) {
    return _then(_self.copyWith(initial: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get accumulatorBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.accumulatorBindingId, (value) {
    return _then(_self.copyWith(accumulatorBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get reduction {
  
  return $TypedExpressionCopyWith<$Res>(_self.reduction, (value) {
    return _then(_self.copyWith(reduction: value));
  });
}
}

/// @nodoc


class CollectionTransformExpression implements Expression {
  const CollectionTransformExpression({required this.source, required this.operation, this.transform, this.itemBindingId, this.count});
  

 final  TypedExpression source;
 final  CollectionTransformOperation operation;
 final  TypedExpression? transform;
 final  BindingId? itemBindingId;
 final  TypedExpression? count;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionTransformExpressionCopyWith<CollectionTransformExpression> get copyWith => _$CollectionTransformExpressionCopyWithImpl<CollectionTransformExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionTransformExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,source,operation,transform,itemBindingId,count);

@override
String toString() {
  return 'Expression.collectionTransform(source: $source, operation: $operation, transform: $transform, itemBindingId: $itemBindingId, count: $count)';
}


}

/// @nodoc
abstract mixin class $CollectionTransformExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionTransformExpressionCopyWith(CollectionTransformExpression value, $Res Function(CollectionTransformExpression) _then) = _$CollectionTransformExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, CollectionTransformOperation operation, TypedExpression? transform, BindingId? itemBindingId, TypedExpression? count
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res>? get transform;$BindingIdCopyWith<$Res>? get itemBindingId;$TypedExpressionCopyWith<$Res>? get count;

}
/// @nodoc
class _$CollectionTransformExpressionCopyWithImpl<$Res>
    implements $CollectionTransformExpressionCopyWith<$Res> {
  _$CollectionTransformExpressionCopyWithImpl(this._self, this._then);

  final CollectionTransformExpression _self;
  final $Res Function(CollectionTransformExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? operation = null,Object? transform = freezed,Object? itemBindingId = freezed,Object? count = freezed,}) {
  return _then(CollectionTransformExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as CollectionTransformOperation,transform: freezed == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as TypedExpression?,itemBindingId: freezed == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get transform {
    if (_self.transform == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.transform!, (value) {
    return _then(_self.copyWith(transform: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res>? get itemBindingId {
    if (_self.itemBindingId == null) {
    return null;
  }

  return $BindingIdCopyWith<$Res>(_self.itemBindingId!, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get count {
    if (_self.count == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.count!, (value) {
    return _then(_self.copyWith(count: value));
  });
}
}

/// @nodoc


class IsTypeExpression implements Expression {
  const IsTypeExpression({required this.source, required this.type});
  

 final  TypedExpression source;
 final  TypeExpression type;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IsTypeExpressionCopyWith<IsTypeExpression> get copyWith => _$IsTypeExpressionCopyWithImpl<IsTypeExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IsTypeExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,source,type);

@override
String toString() {
  return 'Expression.isType(source: $source, type: $type)';
}


}

/// @nodoc
abstract mixin class $IsTypeExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $IsTypeExpressionCopyWith(IsTypeExpression value, $Res Function(IsTypeExpression) _then) = _$IsTypeExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypeExpression type
});


$TypedExpressionCopyWith<$Res> get source;$TypeExpressionCopyWith<$Res> get type;

}
/// @nodoc
class _$IsTypeExpressionCopyWithImpl<$Res>
    implements $IsTypeExpressionCopyWith<$Res> {
  _$IsTypeExpressionCopyWithImpl(this._self, this._then);

  final IsTypeExpression _self;
  final $Res Function(IsTypeExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? type = null,}) {
  return _then(IsTypeExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc


class ConversionExpression implements Expression {
  const ConversionExpression({required this.conversionId, required this.input});
  

 final  ConversionId conversionId;
 final  TypedExpression input;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionExpressionCopyWith<ConversionExpression> get copyWith => _$ConversionExpressionCopyWithImpl<ConversionExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionExpression&&(identical(other.conversionId, conversionId) || other.conversionId == conversionId)&&(identical(other.input, input) || other.input == input));
}


@override
int get hashCode => Object.hash(runtimeType,conversionId,input);

@override
String toString() {
  return 'Expression.conversion(conversionId: $conversionId, input: $input)';
}


}

/// @nodoc
abstract mixin class $ConversionExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $ConversionExpressionCopyWith(ConversionExpression value, $Res Function(ConversionExpression) _then) = _$ConversionExpressionCopyWithImpl;
@useResult
$Res call({
 ConversionId conversionId, TypedExpression input
});


$ConversionIdCopyWith<$Res> get conversionId;$TypedExpressionCopyWith<$Res> get input;

}
/// @nodoc
class _$ConversionExpressionCopyWithImpl<$Res>
    implements $ConversionExpressionCopyWith<$Res> {
  _$ConversionExpressionCopyWithImpl(this._self, this._then);

  final ConversionExpression _self;
  final $Res Function(ConversionExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversionId = null,Object? input = null,}) {
  return _then(ConversionExpression(
conversionId: null == conversionId ? _self.conversionId : conversionId // ignore: cast_nullable_to_non_nullable
as ConversionId,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res> get conversionId {
  
  return $ConversionIdCopyWith<$Res>(_self.conversionId, (value) {
    return _then(_self.copyWith(conversionId: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get input {
  
  return $TypedExpressionCopyWith<$Res>(_self.input, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

/// @nodoc


class StringOperationExpression implements Expression {
  const StringOperationExpression({required this.operation, required final  List<TypedExpression> operands}): _operands = operands;
  

 final  StringOperation operation;
 final  List<TypedExpression> _operands;
 List<TypedExpression> get operands {
  if (_operands is EqualUnmodifiableListView) return _operands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operands);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StringOperationExpressionCopyWith<StringOperationExpression> get copyWith => _$StringOperationExpressionCopyWithImpl<StringOperationExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StringOperationExpression&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other._operands, _operands));
}


@override
int get hashCode => Object.hash(runtimeType,operation,const DeepCollectionEquality().hash(_operands));

@override
String toString() {
  return 'Expression.stringOperation(operation: $operation, operands: $operands)';
}


}

/// @nodoc
abstract mixin class $StringOperationExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $StringOperationExpressionCopyWith(StringOperationExpression value, $Res Function(StringOperationExpression) _then) = _$StringOperationExpressionCopyWithImpl;
@useResult
$Res call({
 StringOperation operation, List<TypedExpression> operands
});




}
/// @nodoc
class _$StringOperationExpressionCopyWithImpl<$Res>
    implements $StringOperationExpressionCopyWith<$Res> {
  _$StringOperationExpressionCopyWithImpl(this._self, this._then);

  final StringOperationExpression _self;
  final $Res Function(StringOperationExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? operands = null,}) {
  return _then(StringOperationExpression(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as StringOperation,operands: null == operands ? _self._operands : operands // ignore: cast_nullable_to_non_nullable
as List<TypedExpression>,
  ));
}


}

/// @nodoc


class CollectionOperationExpression implements Expression {
  const CollectionOperationExpression({required this.operation, required final  List<TypedExpression> operands}): _operands = operands;
  

 final  CollectionOperation operation;
 final  List<TypedExpression> _operands;
 List<TypedExpression> get operands {
  if (_operands is EqualUnmodifiableListView) return _operands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operands);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionOperationExpressionCopyWith<CollectionOperationExpression> get copyWith => _$CollectionOperationExpressionCopyWithImpl<CollectionOperationExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionOperationExpression&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other._operands, _operands));
}


@override
int get hashCode => Object.hash(runtimeType,operation,const DeepCollectionEquality().hash(_operands));

@override
String toString() {
  return 'Expression.collectionOperation(operation: $operation, operands: $operands)';
}


}

/// @nodoc
abstract mixin class $CollectionOperationExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionOperationExpressionCopyWith(CollectionOperationExpression value, $Res Function(CollectionOperationExpression) _then) = _$CollectionOperationExpressionCopyWithImpl;
@useResult
$Res call({
 CollectionOperation operation, List<TypedExpression> operands
});




}
/// @nodoc
class _$CollectionOperationExpressionCopyWithImpl<$Res>
    implements $CollectionOperationExpressionCopyWith<$Res> {
  _$CollectionOperationExpressionCopyWithImpl(this._self, this._then);

  final CollectionOperationExpression _self;
  final $Res Function(CollectionOperationExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? operands = null,}) {
  return _then(CollectionOperationExpression(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as CollectionOperation,operands: null == operands ? _self._operands : operands // ignore: cast_nullable_to_non_nullable
as List<TypedExpression>,
  ));
}


}

/// @nodoc


class RegexExpression implements Expression {
  const RegexExpression({required this.operation, required this.source, required this.pattern, this.group, this.replacement});
  

 final  RegexOperation operation;
 final  TypedExpression source;
 final  String pattern;
 final  int? group;
 final  String? replacement;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegexExpressionCopyWith<RegexExpression> get copyWith => _$RegexExpressionCopyWithImpl<RegexExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegexExpression&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.source, source) || other.source == source)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.group, group) || other.group == group)&&(identical(other.replacement, replacement) || other.replacement == replacement));
}


@override
int get hashCode => Object.hash(runtimeType,operation,source,pattern,group,replacement);

@override
String toString() {
  return 'Expression.regex(operation: $operation, source: $source, pattern: $pattern, group: $group, replacement: $replacement)';
}


}

/// @nodoc
abstract mixin class $RegexExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $RegexExpressionCopyWith(RegexExpression value, $Res Function(RegexExpression) _then) = _$RegexExpressionCopyWithImpl;
@useResult
$Res call({
 RegexOperation operation, TypedExpression source, String pattern, int? group, String? replacement
});


$TypedExpressionCopyWith<$Res> get source;

}
/// @nodoc
class _$RegexExpressionCopyWithImpl<$Res>
    implements $RegexExpressionCopyWith<$Res> {
  _$RegexExpressionCopyWithImpl(this._self, this._then);

  final RegexExpression _self;
  final $Res Function(RegexExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? source = null,Object? pattern = null,Object? group = freezed,Object? replacement = freezed,}) {
  return _then(RegexExpression(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as RegexOperation,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as int?,replacement: freezed == replacement ? _self.replacement : replacement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc


class CoalesceExpression implements Expression {
  const CoalesceExpression(final  List<TypedExpression> operands): _operands = operands;
  

 final  List<TypedExpression> _operands;
 List<TypedExpression> get operands {
  if (_operands is EqualUnmodifiableListView) return _operands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operands);
}


/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoalesceExpressionCopyWith<CoalesceExpression> get copyWith => _$CoalesceExpressionCopyWithImpl<CoalesceExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoalesceExpression&&const DeepCollectionEquality().equals(other._operands, _operands));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_operands));

@override
String toString() {
  return 'Expression.coalesce(operands: $operands)';
}


}

/// @nodoc
abstract mixin class $CoalesceExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CoalesceExpressionCopyWith(CoalesceExpression value, $Res Function(CoalesceExpression) _then) = _$CoalesceExpressionCopyWithImpl;
@useResult
$Res call({
 List<TypedExpression> operands
});




}
/// @nodoc
class _$CoalesceExpressionCopyWithImpl<$Res>
    implements $CoalesceExpressionCopyWith<$Res> {
  _$CoalesceExpressionCopyWithImpl(this._self, this._then);

  final CoalesceExpression _self;
  final $Res Function(CoalesceExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operands = null,}) {
  return _then(CoalesceExpression(
null == operands ? _self._operands : operands // ignore: cast_nullable_to_non_nullable
as List<TypedExpression>,
  ));
}


}

/// @nodoc


class ColorOperationExpression implements Expression {
  const ColorOperationExpression({required this.operation, required this.color, required this.alpha});
  

 final  ColorOperation operation;
 final  TypedExpression color;
 final  TypedExpression alpha;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorOperationExpressionCopyWith<ColorOperationExpression> get copyWith => _$ColorOperationExpressionCopyWithImpl<ColorOperationExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorOperationExpression&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.color, color) || other.color == color)&&(identical(other.alpha, alpha) || other.alpha == alpha));
}


@override
int get hashCode => Object.hash(runtimeType,operation,color,alpha);

@override
String toString() {
  return 'Expression.colorOperation(operation: $operation, color: $color, alpha: $alpha)';
}


}

/// @nodoc
abstract mixin class $ColorOperationExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $ColorOperationExpressionCopyWith(ColorOperationExpression value, $Res Function(ColorOperationExpression) _then) = _$ColorOperationExpressionCopyWithImpl;
@useResult
$Res call({
 ColorOperation operation, TypedExpression color, TypedExpression alpha
});


$TypedExpressionCopyWith<$Res> get color;$TypedExpressionCopyWith<$Res> get alpha;

}
/// @nodoc
class _$ColorOperationExpressionCopyWithImpl<$Res>
    implements $ColorOperationExpressionCopyWith<$Res> {
  _$ColorOperationExpressionCopyWithImpl(this._self, this._then);

  final ColorOperationExpression _self;
  final $Res Function(ColorOperationExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? color = null,Object? alpha = null,}) {
  return _then(ColorOperationExpression(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as ColorOperation,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as TypedExpression,alpha: null == alpha ? _self.alpha : alpha // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get color {
  
  return $TypedExpressionCopyWith<$Res>(_self.color, (value) {
    return _then(_self.copyWith(color: value));
  });
}/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get alpha {
  
  return $TypedExpressionCopyWith<$Res>(_self.alpha, (value) {
    return _then(_self.copyWith(alpha: value));
  });
}
}

/// @nodoc
mixin _$CollectionComparator {

 BindingId get leftBindingId; BindingId get rightBindingId; TypedExpression get comparison;
/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionComparatorCopyWith<CollectionComparator> get copyWith => _$CollectionComparatorCopyWithImpl<CollectionComparator>(this as CollectionComparator, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionComparator&&(identical(other.leftBindingId, leftBindingId) || other.leftBindingId == leftBindingId)&&(identical(other.rightBindingId, rightBindingId) || other.rightBindingId == rightBindingId)&&(identical(other.comparison, comparison) || other.comparison == comparison));
}


@override
int get hashCode => Object.hash(runtimeType,leftBindingId,rightBindingId,comparison);

@override
String toString() {
  return 'CollectionComparator(leftBindingId: $leftBindingId, rightBindingId: $rightBindingId, comparison: $comparison)';
}


}

/// @nodoc
abstract mixin class $CollectionComparatorCopyWith<$Res>  {
  factory $CollectionComparatorCopyWith(CollectionComparator value, $Res Function(CollectionComparator) _then) = _$CollectionComparatorCopyWithImpl;
@useResult
$Res call({
 BindingId leftBindingId, BindingId rightBindingId, TypedExpression comparison
});


$BindingIdCopyWith<$Res> get leftBindingId;$BindingIdCopyWith<$Res> get rightBindingId;$TypedExpressionCopyWith<$Res> get comparison;

}
/// @nodoc
class _$CollectionComparatorCopyWithImpl<$Res>
    implements $CollectionComparatorCopyWith<$Res> {
  _$CollectionComparatorCopyWithImpl(this._self, this._then);

  final CollectionComparator _self;
  final $Res Function(CollectionComparator) _then;

/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? leftBindingId = null,Object? rightBindingId = null,Object? comparison = null,}) {
  return _then(_self.copyWith(
leftBindingId: null == leftBindingId ? _self.leftBindingId : leftBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,rightBindingId: null == rightBindingId ? _self.rightBindingId : rightBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}
/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get leftBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.leftBindingId, (value) {
    return _then(_self.copyWith(leftBindingId: value));
  });
}/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get rightBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.rightBindingId, (value) {
    return _then(_self.copyWith(rightBindingId: value));
  });
}/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get comparison {
  
  return $TypedExpressionCopyWith<$Res>(_self.comparison, (value) {
    return _then(_self.copyWith(comparison: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectionComparator].
extension CollectionComparatorPatterns on CollectionComparator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionComparator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionComparator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionComparator value)  $default,){
final _that = this;
switch (_that) {
case _CollectionComparator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionComparator value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionComparator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingId leftBindingId,  BindingId rightBindingId,  TypedExpression comparison)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionComparator() when $default != null:
return $default(_that.leftBindingId,_that.rightBindingId,_that.comparison);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingId leftBindingId,  BindingId rightBindingId,  TypedExpression comparison)  $default,) {final _that = this;
switch (_that) {
case _CollectionComparator():
return $default(_that.leftBindingId,_that.rightBindingId,_that.comparison);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingId leftBindingId,  BindingId rightBindingId,  TypedExpression comparison)?  $default,) {final _that = this;
switch (_that) {
case _CollectionComparator() when $default != null:
return $default(_that.leftBindingId,_that.rightBindingId,_that.comparison);case _:
  return null;

}
}

}

/// @nodoc


class _CollectionComparator implements CollectionComparator {
  const _CollectionComparator({required this.leftBindingId, required this.rightBindingId, required this.comparison});
  

@override final  BindingId leftBindingId;
@override final  BindingId rightBindingId;
@override final  TypedExpression comparison;

/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionComparatorCopyWith<_CollectionComparator> get copyWith => __$CollectionComparatorCopyWithImpl<_CollectionComparator>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionComparator&&(identical(other.leftBindingId, leftBindingId) || other.leftBindingId == leftBindingId)&&(identical(other.rightBindingId, rightBindingId) || other.rightBindingId == rightBindingId)&&(identical(other.comparison, comparison) || other.comparison == comparison));
}


@override
int get hashCode => Object.hash(runtimeType,leftBindingId,rightBindingId,comparison);

@override
String toString() {
  return 'CollectionComparator(leftBindingId: $leftBindingId, rightBindingId: $rightBindingId, comparison: $comparison)';
}


}

/// @nodoc
abstract mixin class _$CollectionComparatorCopyWith<$Res> implements $CollectionComparatorCopyWith<$Res> {
  factory _$CollectionComparatorCopyWith(_CollectionComparator value, $Res Function(_CollectionComparator) _then) = __$CollectionComparatorCopyWithImpl;
@override @useResult
$Res call({
 BindingId leftBindingId, BindingId rightBindingId, TypedExpression comparison
});


@override $BindingIdCopyWith<$Res> get leftBindingId;@override $BindingIdCopyWith<$Res> get rightBindingId;@override $TypedExpressionCopyWith<$Res> get comparison;

}
/// @nodoc
class __$CollectionComparatorCopyWithImpl<$Res>
    implements _$CollectionComparatorCopyWith<$Res> {
  __$CollectionComparatorCopyWithImpl(this._self, this._then);

  final _CollectionComparator _self;
  final $Res Function(_CollectionComparator) _then;

/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leftBindingId = null,Object? rightBindingId = null,Object? comparison = null,}) {
  return _then(_CollectionComparator(
leftBindingId: null == leftBindingId ? _self.leftBindingId : leftBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,rightBindingId: null == rightBindingId ? _self.rightBindingId : rightBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get leftBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.leftBindingId, (value) {
    return _then(_self.copyWith(leftBindingId: value));
  });
}/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get rightBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.rightBindingId, (value) {
    return _then(_self.copyWith(rightBindingId: value));
  });
}/// Create a copy of CollectionComparator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get comparison {
  
  return $TypedExpressionCopyWith<$Res>(_self.comparison, (value) {
    return _then(_self.copyWith(comparison: value));
  });
}
}

/// @nodoc
mixin _$InterpolationPart {

 Object get value;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpolationPart&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'InterpolationPart(value: $value)';
}


}

/// @nodoc
class $InterpolationPartCopyWith<$Res>  {
$InterpolationPartCopyWith(InterpolationPart _, $Res Function(InterpolationPart) __);
}


/// Adds pattern-matching-related methods to [InterpolationPart].
extension InterpolationPartPatterns on InterpolationPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InterpolationText value)?  text,TResult Function( InterpolationValue value)?  value,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InterpolationText() when text != null:
return text(_that);case InterpolationValue() when value != null:
return value(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InterpolationText value)  text,required TResult Function( InterpolationValue value)  value,}){
final _that = this;
switch (_that) {
case InterpolationText():
return text(_that);case InterpolationValue():
return value(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InterpolationText value)?  text,TResult? Function( InterpolationValue value)?  value,}){
final _that = this;
switch (_that) {
case InterpolationText() when text != null:
return text(_that);case InterpolationValue() when value != null:
return value(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String value)?  text,TResult Function( TypedExpression value)?  value,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InterpolationText() when text != null:
return text(_that.value);case InterpolationValue() when value != null:
return value(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String value)  text,required TResult Function( TypedExpression value)  value,}) {final _that = this;
switch (_that) {
case InterpolationText():
return text(_that.value);case InterpolationValue():
return value(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String value)?  text,TResult? Function( TypedExpression value)?  value,}) {final _that = this;
switch (_that) {
case InterpolationText() when text != null:
return text(_that.value);case InterpolationValue() when value != null:
return value(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class InterpolationText implements InterpolationPart {
  const InterpolationText(this.value);
  

@override final  String value;

/// Create a copy of InterpolationPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpolationTextCopyWith<InterpolationText> get copyWith => _$InterpolationTextCopyWithImpl<InterpolationText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpolationText&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'InterpolationPart.text(value: $value)';
}


}

/// @nodoc
abstract mixin class $InterpolationTextCopyWith<$Res> implements $InterpolationPartCopyWith<$Res> {
  factory $InterpolationTextCopyWith(InterpolationText value, $Res Function(InterpolationText) _then) = _$InterpolationTextCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$InterpolationTextCopyWithImpl<$Res>
    implements $InterpolationTextCopyWith<$Res> {
  _$InterpolationTextCopyWithImpl(this._self, this._then);

  final InterpolationText _self;
  final $Res Function(InterpolationText) _then;

/// Create a copy of InterpolationPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(InterpolationText(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InterpolationValue implements InterpolationPart {
  const InterpolationValue(this.value);
  

@override final  TypedExpression value;

/// Create a copy of InterpolationPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpolationValueCopyWith<InterpolationValue> get copyWith => _$InterpolationValueCopyWithImpl<InterpolationValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpolationValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'InterpolationPart.value(value: $value)';
}


}

/// @nodoc
abstract mixin class $InterpolationValueCopyWith<$Res> implements $InterpolationPartCopyWith<$Res> {
  factory $InterpolationValueCopyWith(InterpolationValue value, $Res Function(InterpolationValue) _then) = _$InterpolationValueCopyWithImpl;
@useResult
$Res call({
 TypedExpression value
});


$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$InterpolationValueCopyWithImpl<$Res>
    implements $InterpolationValueCopyWith<$Res> {
  _$InterpolationValueCopyWithImpl(this._self, this._then);

  final InterpolationValue _self;
  final $Res Function(InterpolationValue) _then;

/// Create a copy of InterpolationPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(InterpolationValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of InterpolationPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$ExpressionBudget {

 int get maximumDepth; int get maximumNodes; int get maximumEvaluations;
/// Create a copy of ExpressionBudget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpressionBudgetCopyWith<ExpressionBudget> get copyWith => _$ExpressionBudgetCopyWithImpl<ExpressionBudget>(this as ExpressionBudget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpressionBudget&&(identical(other.maximumDepth, maximumDepth) || other.maximumDepth == maximumDepth)&&(identical(other.maximumNodes, maximumNodes) || other.maximumNodes == maximumNodes)&&(identical(other.maximumEvaluations, maximumEvaluations) || other.maximumEvaluations == maximumEvaluations));
}


@override
int get hashCode => Object.hash(runtimeType,maximumDepth,maximumNodes,maximumEvaluations);

@override
String toString() {
  return 'ExpressionBudget(maximumDepth: $maximumDepth, maximumNodes: $maximumNodes, maximumEvaluations: $maximumEvaluations)';
}


}

/// @nodoc
abstract mixin class $ExpressionBudgetCopyWith<$Res>  {
  factory $ExpressionBudgetCopyWith(ExpressionBudget value, $Res Function(ExpressionBudget) _then) = _$ExpressionBudgetCopyWithImpl;
@useResult
$Res call({
 int maximumDepth, int maximumNodes, int maximumEvaluations
});




}
/// @nodoc
class _$ExpressionBudgetCopyWithImpl<$Res>
    implements $ExpressionBudgetCopyWith<$Res> {
  _$ExpressionBudgetCopyWithImpl(this._self, this._then);

  final ExpressionBudget _self;
  final $Res Function(ExpressionBudget) _then;

/// Create a copy of ExpressionBudget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maximumDepth = null,Object? maximumNodes = null,Object? maximumEvaluations = null,}) {
  return _then(_self.copyWith(
maximumDepth: null == maximumDepth ? _self.maximumDepth : maximumDepth // ignore: cast_nullable_to_non_nullable
as int,maximumNodes: null == maximumNodes ? _self.maximumNodes : maximumNodes // ignore: cast_nullable_to_non_nullable
as int,maximumEvaluations: null == maximumEvaluations ? _self.maximumEvaluations : maximumEvaluations // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpressionBudget].
extension ExpressionBudgetPatterns on ExpressionBudget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpressionBudget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpressionBudget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpressionBudget value)  $default,){
final _that = this;
switch (_that) {
case _ExpressionBudget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpressionBudget value)?  $default,){
final _that = this;
switch (_that) {
case _ExpressionBudget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maximumDepth,  int maximumNodes,  int maximumEvaluations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpressionBudget() when $default != null:
return $default(_that.maximumDepth,_that.maximumNodes,_that.maximumEvaluations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maximumDepth,  int maximumNodes,  int maximumEvaluations)  $default,) {final _that = this;
switch (_that) {
case _ExpressionBudget():
return $default(_that.maximumDepth,_that.maximumNodes,_that.maximumEvaluations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maximumDepth,  int maximumNodes,  int maximumEvaluations)?  $default,) {final _that = this;
switch (_that) {
case _ExpressionBudget() when $default != null:
return $default(_that.maximumDepth,_that.maximumNodes,_that.maximumEvaluations);case _:
  return null;

}
}

}

/// @nodoc


class _ExpressionBudget implements ExpressionBudget {
  const _ExpressionBudget({this.maximumDepth = 32, this.maximumNodes = 512, this.maximumEvaluations = 4096}): assert(maximumDepth > 0, 'Maximum depth must be positive.'),assert(maximumNodes > 0, 'Maximum node count must be positive.'),assert(maximumEvaluations > 0, 'Maximum evaluations must be positive.');
  

@override@JsonKey() final  int maximumDepth;
@override@JsonKey() final  int maximumNodes;
@override@JsonKey() final  int maximumEvaluations;

/// Create a copy of ExpressionBudget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionBudgetCopyWith<_ExpressionBudget> get copyWith => __$ExpressionBudgetCopyWithImpl<_ExpressionBudget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionBudget&&(identical(other.maximumDepth, maximumDepth) || other.maximumDepth == maximumDepth)&&(identical(other.maximumNodes, maximumNodes) || other.maximumNodes == maximumNodes)&&(identical(other.maximumEvaluations, maximumEvaluations) || other.maximumEvaluations == maximumEvaluations));
}


@override
int get hashCode => Object.hash(runtimeType,maximumDepth,maximumNodes,maximumEvaluations);

@override
String toString() {
  return 'ExpressionBudget(maximumDepth: $maximumDepth, maximumNodes: $maximumNodes, maximumEvaluations: $maximumEvaluations)';
}


}

/// @nodoc
abstract mixin class _$ExpressionBudgetCopyWith<$Res> implements $ExpressionBudgetCopyWith<$Res> {
  factory _$ExpressionBudgetCopyWith(_ExpressionBudget value, $Res Function(_ExpressionBudget) _then) = __$ExpressionBudgetCopyWithImpl;
@override @useResult
$Res call({
 int maximumDepth, int maximumNodes, int maximumEvaluations
});




}
/// @nodoc
class __$ExpressionBudgetCopyWithImpl<$Res>
    implements _$ExpressionBudgetCopyWith<$Res> {
  __$ExpressionBudgetCopyWithImpl(this._self, this._then);

  final _ExpressionBudget _self;
  final $Res Function(_ExpressionBudget) _then;

/// Create a copy of ExpressionBudget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maximumDepth = null,Object? maximumNodes = null,Object? maximumEvaluations = null,}) {
  return _then(_ExpressionBudget(
maximumDepth: null == maximumDepth ? _self.maximumDepth : maximumDepth // ignore: cast_nullable_to_non_nullable
as int,maximumNodes: null == maximumNodes ? _self.maximumNodes : maximumNodes // ignore: cast_nullable_to_non_nullable
as int,maximumEvaluations: null == maximumEvaluations ? _self.maximumEvaluations : maximumEvaluations // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
