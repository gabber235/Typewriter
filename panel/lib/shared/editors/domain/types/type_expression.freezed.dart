// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'type_expression.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypeExpression {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeExpression);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeExpression()';
}


}

/// @nodoc
class $TypeExpressionCopyWith<$Res>  {
$TypeExpressionCopyWith(TypeExpression _, $Res Function(TypeExpression) __);
}


/// Adds pattern-matching-related methods to [TypeExpression].
extension TypeExpressionPatterns on TypeExpression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AnyType value)?  any,TResult Function( UnitType value)?  unit,TResult Function( BooleanType value)?  boolean,TResult Function( StringType value)?  string,TResult Function( BytesType value)?  bytes,TResult Function( IntegerType value)?  integer,TResult Function( FloatType value)?  float,TResult Function( DecimalType value)?  decimal,TResult Function( TimestampType value)?  timestamp,TResult Function( DurationType value)?  duration,TResult Function( EnumType value)?  enumeration,TResult Function( ListType value)?  list,TResult Function( MapType value)?  map,TResult Function( RecordType value)?  record,TResult Function( NamedType value)?  named,TResult Function( ParameterType value)?  parameter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AnyType() when any != null:
return any(_that);case UnitType() when unit != null:
return unit(_that);case BooleanType() when boolean != null:
return boolean(_that);case StringType() when string != null:
return string(_that);case BytesType() when bytes != null:
return bytes(_that);case IntegerType() when integer != null:
return integer(_that);case FloatType() when float != null:
return float(_that);case DecimalType() when decimal != null:
return decimal(_that);case TimestampType() when timestamp != null:
return timestamp(_that);case DurationType() when duration != null:
return duration(_that);case EnumType() when enumeration != null:
return enumeration(_that);case ListType() when list != null:
return list(_that);case MapType() when map != null:
return map(_that);case RecordType() when record != null:
return record(_that);case NamedType() when named != null:
return named(_that);case ParameterType() when parameter != null:
return parameter(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AnyType value)  any,required TResult Function( UnitType value)  unit,required TResult Function( BooleanType value)  boolean,required TResult Function( StringType value)  string,required TResult Function( BytesType value)  bytes,required TResult Function( IntegerType value)  integer,required TResult Function( FloatType value)  float,required TResult Function( DecimalType value)  decimal,required TResult Function( TimestampType value)  timestamp,required TResult Function( DurationType value)  duration,required TResult Function( EnumType value)  enumeration,required TResult Function( ListType value)  list,required TResult Function( MapType value)  map,required TResult Function( RecordType value)  record,required TResult Function( NamedType value)  named,required TResult Function( ParameterType value)  parameter,}){
final _that = this;
switch (_that) {
case AnyType():
return any(_that);case UnitType():
return unit(_that);case BooleanType():
return boolean(_that);case StringType():
return string(_that);case BytesType():
return bytes(_that);case IntegerType():
return integer(_that);case FloatType():
return float(_that);case DecimalType():
return decimal(_that);case TimestampType():
return timestamp(_that);case DurationType():
return duration(_that);case EnumType():
return enumeration(_that);case ListType():
return list(_that);case MapType():
return map(_that);case RecordType():
return record(_that);case NamedType():
return named(_that);case ParameterType():
return parameter(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AnyType value)?  any,TResult? Function( UnitType value)?  unit,TResult? Function( BooleanType value)?  boolean,TResult? Function( StringType value)?  string,TResult? Function( BytesType value)?  bytes,TResult? Function( IntegerType value)?  integer,TResult? Function( FloatType value)?  float,TResult? Function( DecimalType value)?  decimal,TResult? Function( TimestampType value)?  timestamp,TResult? Function( DurationType value)?  duration,TResult? Function( EnumType value)?  enumeration,TResult? Function( ListType value)?  list,TResult? Function( MapType value)?  map,TResult? Function( RecordType value)?  record,TResult? Function( NamedType value)?  named,TResult? Function( ParameterType value)?  parameter,}){
final _that = this;
switch (_that) {
case AnyType() when any != null:
return any(_that);case UnitType() when unit != null:
return unit(_that);case BooleanType() when boolean != null:
return boolean(_that);case StringType() when string != null:
return string(_that);case BytesType() when bytes != null:
return bytes(_that);case IntegerType() when integer != null:
return integer(_that);case FloatType() when float != null:
return float(_that);case DecimalType() when decimal != null:
return decimal(_that);case TimestampType() when timestamp != null:
return timestamp(_that);case DurationType() when duration != null:
return duration(_that);case EnumType() when enumeration != null:
return enumeration(_that);case ListType() when list != null:
return list(_that);case MapType() when map != null:
return map(_that);case RecordType() when record != null:
return record(_that);case NamedType() when named != null:
return named(_that);case ParameterType() when parameter != null:
return parameter(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  any,TResult Function()?  unit,TResult Function()?  boolean,TResult Function( int? minimumLength,  int? maximumLength,  List<String> patterns)?  string,TResult Function( int? minimumLength,  int? maximumLength)?  bytes,TResult Function( IntegerWidth width,  BigInt? minimum,  BigInt? maximum)?  integer,TResult Function( FloatWidth width,  double? minimum,  double? maximum)?  float,TResult Function( String? minimum,  String? maximum,  int? scale)?  decimal,TResult Function( DateTime? minimum,  DateTime? maximum)?  timestamp,TResult Function( Duration? minimum,  Duration? maximum)?  duration,TResult Function( TypeExpression valueType,  List<DataValue> values)?  enumeration,TResult Function( TypeExpression element,  int? minimumLength,  int? maximumLength,  bool unique)?  list,TResult Function( TypeExpression key,  TypeExpression value,  int? minimumLength,  int? maximumLength)?  map,TResult Function( Map<String, TypeField> fields,  bool closed)?  record,TResult Function( ResolvedTypeRef reference)?  named,TResult Function( String name)?  parameter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AnyType() when any != null:
return any();case UnitType() when unit != null:
return unit();case BooleanType() when boolean != null:
return boolean();case StringType() when string != null:
return string(_that.minimumLength,_that.maximumLength,_that.patterns);case BytesType() when bytes != null:
return bytes(_that.minimumLength,_that.maximumLength);case IntegerType() when integer != null:
return integer(_that.width,_that.minimum,_that.maximum);case FloatType() when float != null:
return float(_that.width,_that.minimum,_that.maximum);case DecimalType() when decimal != null:
return decimal(_that.minimum,_that.maximum,_that.scale);case TimestampType() when timestamp != null:
return timestamp(_that.minimum,_that.maximum);case DurationType() when duration != null:
return duration(_that.minimum,_that.maximum);case EnumType() when enumeration != null:
return enumeration(_that.valueType,_that.values);case ListType() when list != null:
return list(_that.element,_that.minimumLength,_that.maximumLength,_that.unique);case MapType() when map != null:
return map(_that.key,_that.value,_that.minimumLength,_that.maximumLength);case RecordType() when record != null:
return record(_that.fields,_that.closed);case NamedType() when named != null:
return named(_that.reference);case ParameterType() when parameter != null:
return parameter(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  any,required TResult Function()  unit,required TResult Function()  boolean,required TResult Function( int? minimumLength,  int? maximumLength,  List<String> patterns)  string,required TResult Function( int? minimumLength,  int? maximumLength)  bytes,required TResult Function( IntegerWidth width,  BigInt? minimum,  BigInt? maximum)  integer,required TResult Function( FloatWidth width,  double? minimum,  double? maximum)  float,required TResult Function( String? minimum,  String? maximum,  int? scale)  decimal,required TResult Function( DateTime? minimum,  DateTime? maximum)  timestamp,required TResult Function( Duration? minimum,  Duration? maximum)  duration,required TResult Function( TypeExpression valueType,  List<DataValue> values)  enumeration,required TResult Function( TypeExpression element,  int? minimumLength,  int? maximumLength,  bool unique)  list,required TResult Function( TypeExpression key,  TypeExpression value,  int? minimumLength,  int? maximumLength)  map,required TResult Function( Map<String, TypeField> fields,  bool closed)  record,required TResult Function( ResolvedTypeRef reference)  named,required TResult Function( String name)  parameter,}) {final _that = this;
switch (_that) {
case AnyType():
return any();case UnitType():
return unit();case BooleanType():
return boolean();case StringType():
return string(_that.minimumLength,_that.maximumLength,_that.patterns);case BytesType():
return bytes(_that.minimumLength,_that.maximumLength);case IntegerType():
return integer(_that.width,_that.minimum,_that.maximum);case FloatType():
return float(_that.width,_that.minimum,_that.maximum);case DecimalType():
return decimal(_that.minimum,_that.maximum,_that.scale);case TimestampType():
return timestamp(_that.minimum,_that.maximum);case DurationType():
return duration(_that.minimum,_that.maximum);case EnumType():
return enumeration(_that.valueType,_that.values);case ListType():
return list(_that.element,_that.minimumLength,_that.maximumLength,_that.unique);case MapType():
return map(_that.key,_that.value,_that.minimumLength,_that.maximumLength);case RecordType():
return record(_that.fields,_that.closed);case NamedType():
return named(_that.reference);case ParameterType():
return parameter(_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  any,TResult? Function()?  unit,TResult? Function()?  boolean,TResult? Function( int? minimumLength,  int? maximumLength,  List<String> patterns)?  string,TResult? Function( int? minimumLength,  int? maximumLength)?  bytes,TResult? Function( IntegerWidth width,  BigInt? minimum,  BigInt? maximum)?  integer,TResult? Function( FloatWidth width,  double? minimum,  double? maximum)?  float,TResult? Function( String? minimum,  String? maximum,  int? scale)?  decimal,TResult? Function( DateTime? minimum,  DateTime? maximum)?  timestamp,TResult? Function( Duration? minimum,  Duration? maximum)?  duration,TResult? Function( TypeExpression valueType,  List<DataValue> values)?  enumeration,TResult? Function( TypeExpression element,  int? minimumLength,  int? maximumLength,  bool unique)?  list,TResult? Function( TypeExpression key,  TypeExpression value,  int? minimumLength,  int? maximumLength)?  map,TResult? Function( Map<String, TypeField> fields,  bool closed)?  record,TResult? Function( ResolvedTypeRef reference)?  named,TResult? Function( String name)?  parameter,}) {final _that = this;
switch (_that) {
case AnyType() when any != null:
return any();case UnitType() when unit != null:
return unit();case BooleanType() when boolean != null:
return boolean();case StringType() when string != null:
return string(_that.minimumLength,_that.maximumLength,_that.patterns);case BytesType() when bytes != null:
return bytes(_that.minimumLength,_that.maximumLength);case IntegerType() when integer != null:
return integer(_that.width,_that.minimum,_that.maximum);case FloatType() when float != null:
return float(_that.width,_that.minimum,_that.maximum);case DecimalType() when decimal != null:
return decimal(_that.minimum,_that.maximum,_that.scale);case TimestampType() when timestamp != null:
return timestamp(_that.minimum,_that.maximum);case DurationType() when duration != null:
return duration(_that.minimum,_that.maximum);case EnumType() when enumeration != null:
return enumeration(_that.valueType,_that.values);case ListType() when list != null:
return list(_that.element,_that.minimumLength,_that.maximumLength,_that.unique);case MapType() when map != null:
return map(_that.key,_that.value,_that.minimumLength,_that.maximumLength);case RecordType() when record != null:
return record(_that.fields,_that.closed);case NamedType() when named != null:
return named(_that.reference);case ParameterType() when parameter != null:
return parameter(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class AnyType extends TypeExpression {
  const AnyType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnyType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeExpression.any()';
}


}




/// @nodoc


class UnitType extends TypeExpression {
  const UnitType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeExpression.unit()';
}


}




/// @nodoc


class BooleanType extends TypeExpression {
  const BooleanType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BooleanType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeExpression.boolean()';
}


}




/// @nodoc


class StringType extends TypeExpression {
  const StringType({this.minimumLength, this.maximumLength, final  List<String> patterns = const []}): _patterns = patterns,super._();
  

 final  int? minimumLength;
 final  int? maximumLength;
 final  List<String> _patterns;
@JsonKey() List<String> get patterns {
  if (_patterns is EqualUnmodifiableListView) return _patterns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patterns);
}


/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StringTypeCopyWith<StringType> get copyWith => _$StringTypeCopyWithImpl<StringType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StringType&&(identical(other.minimumLength, minimumLength) || other.minimumLength == minimumLength)&&(identical(other.maximumLength, maximumLength) || other.maximumLength == maximumLength)&&const DeepCollectionEquality().equals(other._patterns, _patterns));
}


@override
int get hashCode => Object.hash(runtimeType,minimumLength,maximumLength,const DeepCollectionEquality().hash(_patterns));

@override
String toString() {
  return 'TypeExpression.string(minimumLength: $minimumLength, maximumLength: $maximumLength, patterns: $patterns)';
}


}

/// @nodoc
abstract mixin class $StringTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $StringTypeCopyWith(StringType value, $Res Function(StringType) _then) = _$StringTypeCopyWithImpl;
@useResult
$Res call({
 int? minimumLength, int? maximumLength, List<String> patterns
});




}
/// @nodoc
class _$StringTypeCopyWithImpl<$Res>
    implements $StringTypeCopyWith<$Res> {
  _$StringTypeCopyWithImpl(this._self, this._then);

  final StringType _self;
  final $Res Function(StringType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimumLength = freezed,Object? maximumLength = freezed,Object? patterns = null,}) {
  return _then(StringType(
minimumLength: freezed == minimumLength ? _self.minimumLength : minimumLength // ignore: cast_nullable_to_non_nullable
as int?,maximumLength: freezed == maximumLength ? _self.maximumLength : maximumLength // ignore: cast_nullable_to_non_nullable
as int?,patterns: null == patterns ? _self._patterns : patterns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class BytesType extends TypeExpression {
  const BytesType({this.minimumLength, this.maximumLength}): super._();
  

 final  int? minimumLength;
 final  int? maximumLength;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BytesTypeCopyWith<BytesType> get copyWith => _$BytesTypeCopyWithImpl<BytesType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BytesType&&(identical(other.minimumLength, minimumLength) || other.minimumLength == minimumLength)&&(identical(other.maximumLength, maximumLength) || other.maximumLength == maximumLength));
}


@override
int get hashCode => Object.hash(runtimeType,minimumLength,maximumLength);

@override
String toString() {
  return 'TypeExpression.bytes(minimumLength: $minimumLength, maximumLength: $maximumLength)';
}


}

/// @nodoc
abstract mixin class $BytesTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $BytesTypeCopyWith(BytesType value, $Res Function(BytesType) _then) = _$BytesTypeCopyWithImpl;
@useResult
$Res call({
 int? minimumLength, int? maximumLength
});




}
/// @nodoc
class _$BytesTypeCopyWithImpl<$Res>
    implements $BytesTypeCopyWith<$Res> {
  _$BytesTypeCopyWithImpl(this._self, this._then);

  final BytesType _self;
  final $Res Function(BytesType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimumLength = freezed,Object? maximumLength = freezed,}) {
  return _then(BytesType(
minimumLength: freezed == minimumLength ? _self.minimumLength : minimumLength // ignore: cast_nullable_to_non_nullable
as int?,maximumLength: freezed == maximumLength ? _self.maximumLength : maximumLength // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class IntegerType extends TypeExpression {
  const IntegerType({required this.width, this.minimum, this.maximum}): super._();
  

 final  IntegerWidth width;
 final  BigInt? minimum;
 final  BigInt? maximum;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntegerTypeCopyWith<IntegerType> get copyWith => _$IntegerTypeCopyWithImpl<IntegerType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntegerType&&(identical(other.width, width) || other.width == width)&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum));
}


@override
int get hashCode => Object.hash(runtimeType,width,minimum,maximum);

@override
String toString() {
  return 'TypeExpression.integer(width: $width, minimum: $minimum, maximum: $maximum)';
}


}

/// @nodoc
abstract mixin class $IntegerTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $IntegerTypeCopyWith(IntegerType value, $Res Function(IntegerType) _then) = _$IntegerTypeCopyWithImpl;
@useResult
$Res call({
 IntegerWidth width, BigInt? minimum, BigInt? maximum
});




}
/// @nodoc
class _$IntegerTypeCopyWithImpl<$Res>
    implements $IntegerTypeCopyWith<$Res> {
  _$IntegerTypeCopyWithImpl(this._self, this._then);

  final IntegerType _self;
  final $Res Function(IntegerType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? width = null,Object? minimum = freezed,Object? maximum = freezed,}) {
  return _then(IntegerType(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as IntegerWidth,minimum: freezed == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as BigInt?,maximum: freezed == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as BigInt?,
  ));
}


}

/// @nodoc


class FloatType extends TypeExpression {
  const FloatType({required this.width, this.minimum, this.maximum}): super._();
  

 final  FloatWidth width;
 final  double? minimum;
 final  double? maximum;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloatTypeCopyWith<FloatType> get copyWith => _$FloatTypeCopyWithImpl<FloatType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloatType&&(identical(other.width, width) || other.width == width)&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum));
}


@override
int get hashCode => Object.hash(runtimeType,width,minimum,maximum);

@override
String toString() {
  return 'TypeExpression.float(width: $width, minimum: $minimum, maximum: $maximum)';
}


}

/// @nodoc
abstract mixin class $FloatTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $FloatTypeCopyWith(FloatType value, $Res Function(FloatType) _then) = _$FloatTypeCopyWithImpl;
@useResult
$Res call({
 FloatWidth width, double? minimum, double? maximum
});




}
/// @nodoc
class _$FloatTypeCopyWithImpl<$Res>
    implements $FloatTypeCopyWith<$Res> {
  _$FloatTypeCopyWithImpl(this._self, this._then);

  final FloatType _self;
  final $Res Function(FloatType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? width = null,Object? minimum = freezed,Object? maximum = freezed,}) {
  return _then(FloatType(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as FloatWidth,minimum: freezed == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as double?,maximum: freezed == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc


class DecimalType extends TypeExpression {
  const DecimalType({this.minimum, this.maximum, this.scale}): super._();
  

 final  String? minimum;
 final  String? maximum;
 final  int? scale;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecimalTypeCopyWith<DecimalType> get copyWith => _$DecimalTypeCopyWithImpl<DecimalType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecimalType&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum)&&(identical(other.scale, scale) || other.scale == scale));
}


@override
int get hashCode => Object.hash(runtimeType,minimum,maximum,scale);

@override
String toString() {
  return 'TypeExpression.decimal(minimum: $minimum, maximum: $maximum, scale: $scale)';
}


}

/// @nodoc
abstract mixin class $DecimalTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $DecimalTypeCopyWith(DecimalType value, $Res Function(DecimalType) _then) = _$DecimalTypeCopyWithImpl;
@useResult
$Res call({
 String? minimum, String? maximum, int? scale
});




}
/// @nodoc
class _$DecimalTypeCopyWithImpl<$Res>
    implements $DecimalTypeCopyWith<$Res> {
  _$DecimalTypeCopyWithImpl(this._self, this._then);

  final DecimalType _self;
  final $Res Function(DecimalType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimum = freezed,Object? maximum = freezed,Object? scale = freezed,}) {
  return _then(DecimalType(
minimum: freezed == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as String?,maximum: freezed == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as String?,scale: freezed == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class TimestampType extends TypeExpression {
  const TimestampType({this.minimum, this.maximum}): super._();
  

 final  DateTime? minimum;
 final  DateTime? maximum;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimestampTypeCopyWith<TimestampType> get copyWith => _$TimestampTypeCopyWithImpl<TimestampType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimestampType&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum));
}


@override
int get hashCode => Object.hash(runtimeType,minimum,maximum);

@override
String toString() {
  return 'TypeExpression.timestamp(minimum: $minimum, maximum: $maximum)';
}


}

/// @nodoc
abstract mixin class $TimestampTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $TimestampTypeCopyWith(TimestampType value, $Res Function(TimestampType) _then) = _$TimestampTypeCopyWithImpl;
@useResult
$Res call({
 DateTime? minimum, DateTime? maximum
});




}
/// @nodoc
class _$TimestampTypeCopyWithImpl<$Res>
    implements $TimestampTypeCopyWith<$Res> {
  _$TimestampTypeCopyWithImpl(this._self, this._then);

  final TimestampType _self;
  final $Res Function(TimestampType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimum = freezed,Object? maximum = freezed,}) {
  return _then(TimestampType(
minimum: freezed == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as DateTime?,maximum: freezed == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class DurationType extends TypeExpression {
  const DurationType({this.minimum, this.maximum}): super._();
  

 final  Duration? minimum;
 final  Duration? maximum;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DurationTypeCopyWith<DurationType> get copyWith => _$DurationTypeCopyWithImpl<DurationType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DurationType&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum));
}


@override
int get hashCode => Object.hash(runtimeType,minimum,maximum);

@override
String toString() {
  return 'TypeExpression.duration(minimum: $minimum, maximum: $maximum)';
}


}

/// @nodoc
abstract mixin class $DurationTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $DurationTypeCopyWith(DurationType value, $Res Function(DurationType) _then) = _$DurationTypeCopyWithImpl;
@useResult
$Res call({
 Duration? minimum, Duration? maximum
});




}
/// @nodoc
class _$DurationTypeCopyWithImpl<$Res>
    implements $DurationTypeCopyWith<$Res> {
  _$DurationTypeCopyWithImpl(this._self, this._then);

  final DurationType _self;
  final $Res Function(DurationType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimum = freezed,Object? maximum = freezed,}) {
  return _then(DurationType(
minimum: freezed == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as Duration?,maximum: freezed == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class EnumType extends TypeExpression {
  const EnumType({required this.valueType, required final  List<DataValue> values}): _values = values,super._();
  

 final  TypeExpression valueType;
 final  List<DataValue> _values;
 List<DataValue> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnumTypeCopyWith<EnumType> get copyWith => _$EnumTypeCopyWithImpl<EnumType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnumType&&(identical(other.valueType, valueType) || other.valueType == valueType)&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,valueType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'TypeExpression.enumeration(valueType: $valueType, values: $values)';
}


}

/// @nodoc
abstract mixin class $EnumTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $EnumTypeCopyWith(EnumType value, $Res Function(EnumType) _then) = _$EnumTypeCopyWithImpl;
@useResult
$Res call({
 TypeExpression valueType, List<DataValue> values
});


$TypeExpressionCopyWith<$Res> get valueType;

}
/// @nodoc
class _$EnumTypeCopyWithImpl<$Res>
    implements $EnumTypeCopyWith<$Res> {
  _$EnumTypeCopyWithImpl(this._self, this._then);

  final EnumType _self;
  final $Res Function(EnumType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? valueType = null,Object? values = null,}) {
  return _then(EnumType(
valueType: null == valueType ? _self.valueType : valueType // ignore: cast_nullable_to_non_nullable
as TypeExpression,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<DataValue>,
  ));
}

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get valueType {
  
  return $TypeExpressionCopyWith<$Res>(_self.valueType, (value) {
    return _then(_self.copyWith(valueType: value));
  });
}
}

/// @nodoc


class ListType extends TypeExpression {
  const ListType({required this.element, this.minimumLength, this.maximumLength, this.unique = false}): super._();
  

 final  TypeExpression element;
 final  int? minimumLength;
 final  int? maximumLength;
@JsonKey() final  bool unique;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListTypeCopyWith<ListType> get copyWith => _$ListTypeCopyWithImpl<ListType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListType&&(identical(other.element, element) || other.element == element)&&(identical(other.minimumLength, minimumLength) || other.minimumLength == minimumLength)&&(identical(other.maximumLength, maximumLength) || other.maximumLength == maximumLength)&&(identical(other.unique, unique) || other.unique == unique));
}


@override
int get hashCode => Object.hash(runtimeType,element,minimumLength,maximumLength,unique);

@override
String toString() {
  return 'TypeExpression.list(element: $element, minimumLength: $minimumLength, maximumLength: $maximumLength, unique: $unique)';
}


}

/// @nodoc
abstract mixin class $ListTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $ListTypeCopyWith(ListType value, $Res Function(ListType) _then) = _$ListTypeCopyWithImpl;
@useResult
$Res call({
 TypeExpression element, int? minimumLength, int? maximumLength, bool unique
});


$TypeExpressionCopyWith<$Res> get element;

}
/// @nodoc
class _$ListTypeCopyWithImpl<$Res>
    implements $ListTypeCopyWith<$Res> {
  _$ListTypeCopyWithImpl(this._self, this._then);

  final ListType _self;
  final $Res Function(ListType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? element = null,Object? minimumLength = freezed,Object? maximumLength = freezed,Object? unique = null,}) {
  return _then(ListType(
element: null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as TypeExpression,minimumLength: freezed == minimumLength ? _self.minimumLength : minimumLength // ignore: cast_nullable_to_non_nullable
as int?,maximumLength: freezed == maximumLength ? _self.maximumLength : maximumLength // ignore: cast_nullable_to_non_nullable
as int?,unique: null == unique ? _self.unique : unique // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get element {
  
  return $TypeExpressionCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}
}

/// @nodoc


class MapType extends TypeExpression {
  const MapType({required this.key, required this.value, this.minimumLength, this.maximumLength}): super._();
  

 final  TypeExpression key;
 final  TypeExpression value;
 final  int? minimumLength;
 final  int? maximumLength;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapTypeCopyWith<MapType> get copyWith => _$MapTypeCopyWithImpl<MapType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapType&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.minimumLength, minimumLength) || other.minimumLength == minimumLength)&&(identical(other.maximumLength, maximumLength) || other.maximumLength == maximumLength));
}


@override
int get hashCode => Object.hash(runtimeType,key,value,minimumLength,maximumLength);

@override
String toString() {
  return 'TypeExpression.map(key: $key, value: $value, minimumLength: $minimumLength, maximumLength: $maximumLength)';
}


}

/// @nodoc
abstract mixin class $MapTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $MapTypeCopyWith(MapType value, $Res Function(MapType) _then) = _$MapTypeCopyWithImpl;
@useResult
$Res call({
 TypeExpression key, TypeExpression value, int? minimumLength, int? maximumLength
});


$TypeExpressionCopyWith<$Res> get key;$TypeExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$MapTypeCopyWithImpl<$Res>
    implements $MapTypeCopyWith<$Res> {
  _$MapTypeCopyWithImpl(this._self, this._then);

  final MapType _self;
  final $Res Function(MapType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,Object? minimumLength = freezed,Object? maximumLength = freezed,}) {
  return _then(MapType(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypeExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypeExpression,minimumLength: freezed == minimumLength ? _self.minimumLength : minimumLength // ignore: cast_nullable_to_non_nullable
as int?,maximumLength: freezed == maximumLength ? _self.maximumLength : maximumLength // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get key {
  
  return $TypeExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get value {
  
  return $TypeExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class RecordType extends TypeExpression {
  const RecordType({required final  Map<String, TypeField> fields, this.closed = true}): _fields = fields,super._();
  

 final  Map<String, TypeField> _fields;
 Map<String, TypeField> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}

@JsonKey() final  bool closed;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordTypeCopyWith<RecordType> get copyWith => _$RecordTypeCopyWithImpl<RecordType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordType&&const DeepCollectionEquality().equals(other._fields, _fields)&&(identical(other.closed, closed) || other.closed == closed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields),closed);

@override
String toString() {
  return 'TypeExpression.record(fields: $fields, closed: $closed)';
}


}

/// @nodoc
abstract mixin class $RecordTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $RecordTypeCopyWith(RecordType value, $Res Function(RecordType) _then) = _$RecordTypeCopyWithImpl;
@useResult
$Res call({
 Map<String, TypeField> fields, bool closed
});




}
/// @nodoc
class _$RecordTypeCopyWithImpl<$Res>
    implements $RecordTypeCopyWith<$Res> {
  _$RecordTypeCopyWithImpl(this._self, this._then);

  final RecordType _self;
  final $Res Function(RecordType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,Object? closed = null,}) {
  return _then(RecordType(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, TypeField>,closed: null == closed ? _self.closed : closed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class NamedType extends TypeExpression {
  const NamedType(this.reference): super._();
  

 final  ResolvedTypeRef reference;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NamedTypeCopyWith<NamedType> get copyWith => _$NamedTypeCopyWithImpl<NamedType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NamedType&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode => Object.hash(runtimeType,reference);

@override
String toString() {
  return 'TypeExpression.named(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $NamedTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $NamedTypeCopyWith(NamedType value, $Res Function(NamedType) _then) = _$NamedTypeCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef reference
});


$ResolvedTypeRefCopyWith<$Res> get reference;

}
/// @nodoc
class _$NamedTypeCopyWithImpl<$Res>
    implements $NamedTypeCopyWith<$Res> {
  _$NamedTypeCopyWithImpl(this._self, this._then);

  final NamedType _self;
  final $Res Function(NamedType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(NamedType(
null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get reference {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

/// @nodoc


class ParameterType extends TypeExpression {
  const ParameterType(this.name): assert(name != "", 'Parameter name must not be empty.'),super._();
  

 final  String name;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParameterTypeCopyWith<ParameterType> get copyWith => _$ParameterTypeCopyWithImpl<ParameterType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParameterType&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'TypeExpression.parameter(name: $name)';
}


}

/// @nodoc
abstract mixin class $ParameterTypeCopyWith<$Res> implements $TypeExpressionCopyWith<$Res> {
  factory $ParameterTypeCopyWith(ParameterType value, $Res Function(ParameterType) _then) = _$ParameterTypeCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$ParameterTypeCopyWithImpl<$Res>
    implements $ParameterTypeCopyWith<$Res> {
  _$ParameterTypeCopyWithImpl(this._self, this._then);

  final ParameterType _self;
  final $Res Function(ParameterType) _then;

/// Create a copy of TypeExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(ParameterType(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TypeField {

 String get name; TypeExpression get type; DataValue? get initialValue;
/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeFieldCopyWith<TypeField> get copyWith => _$TypeFieldCopyWithImpl<TypeField>(this as TypeField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeField&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.initialValue, initialValue) || other.initialValue == initialValue));
}


@override
int get hashCode => Object.hash(runtimeType,name,type,initialValue);

@override
String toString() {
  return 'TypeField(name: $name, type: $type, initialValue: $initialValue)';
}


}

/// @nodoc
abstract mixin class $TypeFieldCopyWith<$Res>  {
  factory $TypeFieldCopyWith(TypeField value, $Res Function(TypeField) _then) = _$TypeFieldCopyWithImpl;
@useResult
$Res call({
 String name, TypeExpression type, DataValue? initialValue
});


$TypeExpressionCopyWith<$Res> get type;$DataValueCopyWith<$Res>? get initialValue;

}
/// @nodoc
class _$TypeFieldCopyWithImpl<$Res>
    implements $TypeFieldCopyWith<$Res> {
  _$TypeFieldCopyWithImpl(this._self, this._then);

  final TypeField _self;
  final $Res Function(TypeField) _then;

/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? initialValue = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,initialValue: freezed == initialValue ? _self.initialValue : initialValue // ignore: cast_nullable_to_non_nullable
as DataValue?,
  ));
}
/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res>? get initialValue {
    if (_self.initialValue == null) {
    return null;
  }

  return $DataValueCopyWith<$Res>(_self.initialValue!, (value) {
    return _then(_self.copyWith(initialValue: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeField].
extension TypeFieldPatterns on TypeField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeField value)  $default,){
final _that = this;
switch (_that) {
case _TypeField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeField value)?  $default,){
final _that = this;
switch (_that) {
case _TypeField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  TypeExpression type,  DataValue? initialValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeField() when $default != null:
return $default(_that.name,_that.type,_that.initialValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  TypeExpression type,  DataValue? initialValue)  $default,) {final _that = this;
switch (_that) {
case _TypeField():
return $default(_that.name,_that.type,_that.initialValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  TypeExpression type,  DataValue? initialValue)?  $default,) {final _that = this;
switch (_that) {
case _TypeField() when $default != null:
return $default(_that.name,_that.type,_that.initialValue);case _:
  return null;

}
}

}

/// @nodoc


class _TypeField implements TypeField {
  const _TypeField({required this.name, required this.type, this.initialValue});
  

@override final  String name;
@override final  TypeExpression type;
@override final  DataValue? initialValue;

/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeFieldCopyWith<_TypeField> get copyWith => __$TypeFieldCopyWithImpl<_TypeField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeField&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.initialValue, initialValue) || other.initialValue == initialValue));
}


@override
int get hashCode => Object.hash(runtimeType,name,type,initialValue);

@override
String toString() {
  return 'TypeField(name: $name, type: $type, initialValue: $initialValue)';
}


}

/// @nodoc
abstract mixin class _$TypeFieldCopyWith<$Res> implements $TypeFieldCopyWith<$Res> {
  factory _$TypeFieldCopyWith(_TypeField value, $Res Function(_TypeField) _then) = __$TypeFieldCopyWithImpl;
@override @useResult
$Res call({
 String name, TypeExpression type, DataValue? initialValue
});


@override $TypeExpressionCopyWith<$Res> get type;@override $DataValueCopyWith<$Res>? get initialValue;

}
/// @nodoc
class __$TypeFieldCopyWithImpl<$Res>
    implements _$TypeFieldCopyWith<$Res> {
  __$TypeFieldCopyWithImpl(this._self, this._then);

  final _TypeField _self;
  final $Res Function(_TypeField) _then;

/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? initialValue = freezed,}) {
  return _then(_TypeField(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,initialValue: freezed == initialValue ? _self.initialValue : initialValue // ignore: cast_nullable_to_non_nullable
as DataValue?,
  ));
}

/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of TypeField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res>? get initialValue {
    if (_self.initialValue == null) {
    return null;
  }

  return $DataValueCopyWith<$Res>(_self.initialValue!, (value) {
    return _then(_self.copyWith(initialValue: value));
  });
}
}

// dart format on
