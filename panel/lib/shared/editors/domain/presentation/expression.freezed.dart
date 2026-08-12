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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LiteralExpression value)?  literal,TResult Function( BindingExpression value)?  binding,TResult Function( FieldAccessExpression value)?  fieldAccess,TResult Function( InterpolationExpression value)?  interpolation,TResult Function( ComparisonExpression value)?  comparison,TResult Function( BooleanExpression value)?  boolean,TResult Function( ArithmeticExpression value)?  arithmetic,TResult Function( ConditionalExpression value)?  conditional,TResult Function( CollectionProjectionExpression value)?  collectionProjection,TResult Function( ConversionExpression value)?  conversion,required TResult orElse(),}){
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
return conditional(_that);case CollectionProjectionExpression() when collectionProjection != null:
return collectionProjection(_that);case ConversionExpression() when conversion != null:
return conversion(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LiteralExpression value)  literal,required TResult Function( BindingExpression value)  binding,required TResult Function( FieldAccessExpression value)  fieldAccess,required TResult Function( InterpolationExpression value)  interpolation,required TResult Function( ComparisonExpression value)  comparison,required TResult Function( BooleanExpression value)  boolean,required TResult Function( ArithmeticExpression value)  arithmetic,required TResult Function( ConditionalExpression value)  conditional,required TResult Function( CollectionProjectionExpression value)  collectionProjection,required TResult Function( ConversionExpression value)  conversion,}){
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
return conditional(_that);case CollectionProjectionExpression():
return collectionProjection(_that);case ConversionExpression():
return conversion(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LiteralExpression value)?  literal,TResult? Function( BindingExpression value)?  binding,TResult? Function( FieldAccessExpression value)?  fieldAccess,TResult? Function( InterpolationExpression value)?  interpolation,TResult? Function( ComparisonExpression value)?  comparison,TResult? Function( BooleanExpression value)?  boolean,TResult? Function( ArithmeticExpression value)?  arithmetic,TResult? Function( ConditionalExpression value)?  conditional,TResult? Function( CollectionProjectionExpression value)?  collectionProjection,TResult? Function( ConversionExpression value)?  conversion,}){
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
return conditional(_that);case CollectionProjectionExpression() when collectionProjection != null:
return collectionProjection(_that);case ConversionExpression() when conversion != null:
return conversion(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DataValue value)?  literal,TResult Function( BindingReference binding)?  binding,TResult Function( TypedExpression target,  String fieldName)?  fieldAccess,TResult Function( List<InterpolationPart> parts)?  interpolation,TResult Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)?  comparison,TResult Function( BooleanOperator operator,  List<TypedExpression> operands)?  boolean,TResult Function( ArithmeticOperator operator,  List<TypedExpression> operands)?  arithmetic,TResult Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)?  conditional,TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression projection)?  collectionProjection,TResult Function( ConversionId conversionId,  TypedExpression input)?  conversion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that.value);case BindingExpression() when binding != null:
return binding(_that.binding);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression() when interpolation != null:
return interpolation(_that.parts);case ComparisonExpression() when comparison != null:
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression() when boolean != null:
return boolean(_that.operator,_that.operands);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that.operator,_that.operands);case ConditionalExpression() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionProjectionExpression() when collectionProjection != null:
return collectionProjection(_that.source,_that.itemBindingId,_that.projection);case ConversionExpression() when conversion != null:
return conversion(_that.conversionId,_that.input);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DataValue value)  literal,required TResult Function( BindingReference binding)  binding,required TResult Function( TypedExpression target,  String fieldName)  fieldAccess,required TResult Function( List<InterpolationPart> parts)  interpolation,required TResult Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)  comparison,required TResult Function( BooleanOperator operator,  List<TypedExpression> operands)  boolean,required TResult Function( ArithmeticOperator operator,  List<TypedExpression> operands)  arithmetic,required TResult Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)  conditional,required TResult Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression projection)  collectionProjection,required TResult Function( ConversionId conversionId,  TypedExpression input)  conversion,}) {final _that = this;
switch (_that) {
case LiteralExpression():
return literal(_that.value);case BindingExpression():
return binding(_that.binding);case FieldAccessExpression():
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression():
return interpolation(_that.parts);case ComparisonExpression():
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression():
return boolean(_that.operator,_that.operands);case ArithmeticExpression():
return arithmetic(_that.operator,_that.operands);case ConditionalExpression():
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionProjectionExpression():
return collectionProjection(_that.source,_that.itemBindingId,_that.projection);case ConversionExpression():
return conversion(_that.conversionId,_that.input);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DataValue value)?  literal,TResult? Function( BindingReference binding)?  binding,TResult? Function( TypedExpression target,  String fieldName)?  fieldAccess,TResult? Function( List<InterpolationPart> parts)?  interpolation,TResult? Function( ComparisonOperator operator,  TypedExpression left,  TypedExpression right)?  comparison,TResult? Function( BooleanOperator operator,  List<TypedExpression> operands)?  boolean,TResult? Function( ArithmeticOperator operator,  List<TypedExpression> operands)?  arithmetic,TResult? Function( TypedExpression condition,  TypedExpression whenTrue,  TypedExpression whenFalse)?  conditional,TResult? Function( TypedExpression source,  BindingId itemBindingId,  TypedExpression projection)?  collectionProjection,TResult? Function( ConversionId conversionId,  TypedExpression input)?  conversion,}) {final _that = this;
switch (_that) {
case LiteralExpression() when literal != null:
return literal(_that.value);case BindingExpression() when binding != null:
return binding(_that.binding);case FieldAccessExpression() when fieldAccess != null:
return fieldAccess(_that.target,_that.fieldName);case InterpolationExpression() when interpolation != null:
return interpolation(_that.parts);case ComparisonExpression() when comparison != null:
return comparison(_that.operator,_that.left,_that.right);case BooleanExpression() when boolean != null:
return boolean(_that.operator,_that.operands);case ArithmeticExpression() when arithmetic != null:
return arithmetic(_that.operator,_that.operands);case ConditionalExpression() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case CollectionProjectionExpression() when collectionProjection != null:
return collectionProjection(_that.source,_that.itemBindingId,_that.projection);case ConversionExpression() when conversion != null:
return conversion(_that.conversionId,_that.input);case _:
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


class CollectionProjectionExpression implements Expression {
  const CollectionProjectionExpression({required this.source, required this.itemBindingId, required this.projection});
  

 final  TypedExpression source;
 final  BindingId itemBindingId;
 final  TypedExpression projection;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionProjectionExpressionCopyWith<CollectionProjectionExpression> get copyWith => _$CollectionProjectionExpressionCopyWithImpl<CollectionProjectionExpression>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionProjectionExpression&&(identical(other.source, source) || other.source == source)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.projection, projection) || other.projection == projection));
}


@override
int get hashCode => Object.hash(runtimeType,source,itemBindingId,projection);

@override
String toString() {
  return 'Expression.collectionProjection(source: $source, itemBindingId: $itemBindingId, projection: $projection)';
}


}

/// @nodoc
abstract mixin class $CollectionProjectionExpressionCopyWith<$Res> implements $ExpressionCopyWith<$Res> {
  factory $CollectionProjectionExpressionCopyWith(CollectionProjectionExpression value, $Res Function(CollectionProjectionExpression) _then) = _$CollectionProjectionExpressionCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId itemBindingId, TypedExpression projection
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$TypedExpressionCopyWith<$Res> get projection;

}
/// @nodoc
class _$CollectionProjectionExpressionCopyWithImpl<$Res>
    implements $CollectionProjectionExpressionCopyWith<$Res> {
  _$CollectionProjectionExpressionCopyWithImpl(this._self, this._then);

  final CollectionProjectionExpression _self;
  final $Res Function(CollectionProjectionExpression) _then;

/// Create a copy of Expression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? itemBindingId = null,Object? projection = null,}) {
  return _then(CollectionProjectionExpression(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,projection: null == projection ? _self.projection : projection // ignore: cast_nullable_to_non_nullable
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
$TypedExpressionCopyWith<$Res> get projection {
  
  return $TypedExpressionCopyWith<$Res>(_self.projection, (value) {
    return _then(_self.copyWith(projection: value));
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
