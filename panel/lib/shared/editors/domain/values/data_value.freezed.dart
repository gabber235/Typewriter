// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataValue {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataValue()';
}


}

/// @nodoc
class $DataValueCopyWith<$Res>  {
$DataValueCopyWith(DataValue _, $Res Function(DataValue) __);
}



/// @nodoc


class UnitValue extends DataValue {
  const UnitValue(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataValue.unit()';
}


}




/// @nodoc


class BooleanValue extends DataValue {
  const BooleanValue(this.value): super._();
  

 final  bool value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BooleanValueCopyWith<BooleanValue> get copyWith => _$BooleanValueCopyWithImpl<BooleanValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BooleanValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.boolean(value: $value)';
}


}

/// @nodoc
abstract mixin class $BooleanValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $BooleanValueCopyWith(BooleanValue value, $Res Function(BooleanValue) _then) = _$BooleanValueCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$BooleanValueCopyWithImpl<$Res>
    implements $BooleanValueCopyWith<$Res> {
  _$BooleanValueCopyWithImpl(this._self, this._then);

  final BooleanValue _self;
  final $Res Function(BooleanValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(BooleanValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class IntegerValue extends DataValue {
   IntegerValue(this.value): super._();
  

 final  BigInt value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntegerValueCopyWith<IntegerValue> get copyWith => _$IntegerValueCopyWithImpl<IntegerValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntegerValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.integer(value: $value)';
}


}

/// @nodoc
abstract mixin class $IntegerValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $IntegerValueCopyWith(IntegerValue value, $Res Function(IntegerValue) _then) = _$IntegerValueCopyWithImpl;
@useResult
$Res call({
 BigInt value
});




}
/// @nodoc
class _$IntegerValueCopyWithImpl<$Res>
    implements $IntegerValueCopyWith<$Res> {
  _$IntegerValueCopyWithImpl(this._self, this._then);

  final IntegerValue _self;
  final $Res Function(IntegerValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(IntegerValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class FloatValue extends DataValue {
  const FloatValue(this.value): super._();
  

 final  double value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloatValueCopyWith<FloatValue> get copyWith => _$FloatValueCopyWithImpl<FloatValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloatValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.float(value: $value)';
}


}

/// @nodoc
abstract mixin class $FloatValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $FloatValueCopyWith(FloatValue value, $Res Function(FloatValue) _then) = _$FloatValueCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$FloatValueCopyWithImpl<$Res>
    implements $FloatValueCopyWith<$Res> {
  _$FloatValueCopyWithImpl(this._self, this._then);

  final FloatValue _self;
  final $Res Function(FloatValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(FloatValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class DecimalValue extends DataValue {
   DecimalValue(this.value): assert(RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$").hasMatch(value), 'Decimal value must use canonical decimal syntax.'),super._();
  

 final  String value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecimalValueCopyWith<DecimalValue> get copyWith => _$DecimalValueCopyWithImpl<DecimalValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecimalValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.decimal(value: $value)';
}


}

/// @nodoc
abstract mixin class $DecimalValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $DecimalValueCopyWith(DecimalValue value, $Res Function(DecimalValue) _then) = _$DecimalValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$DecimalValueCopyWithImpl<$Res>
    implements $DecimalValueCopyWith<$Res> {
  _$DecimalValueCopyWithImpl(this._self, this._then);

  final DecimalValue _self;
  final $Res Function(DecimalValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DecimalValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StringValue extends DataValue {
  const StringValue(this.value): super._();
  

 final  String value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StringValueCopyWith<StringValue> get copyWith => _$StringValueCopyWithImpl<StringValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StringValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.string(value: $value)';
}


}

/// @nodoc
abstract mixin class $StringValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $StringValueCopyWith(StringValue value, $Res Function(StringValue) _then) = _$StringValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$StringValueCopyWithImpl<$Res>
    implements $StringValueCopyWith<$Res> {
  _$StringValueCopyWithImpl(this._self, this._then);

  final StringValue _self;
  final $Res Function(StringValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(StringValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}



/// @nodoc


class DurationValue extends DataValue {
  const DurationValue(this.value): super._();
  

 final  Duration value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DurationValueCopyWith<DurationValue> get copyWith => _$DurationValueCopyWithImpl<DurationValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DurationValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DataValue.duration(value: $value)';
}


}

/// @nodoc
abstract mixin class $DurationValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $DurationValueCopyWith(DurationValue value, $Res Function(DurationValue) _then) = _$DurationValueCopyWithImpl;
@useResult
$Res call({
 Duration value
});




}
/// @nodoc
class _$DurationValueCopyWithImpl<$Res>
    implements $DurationValueCopyWith<$Res> {
  _$DurationValueCopyWithImpl(this._self, this._then);

  final DurationValue _self;
  final $Res Function(DurationValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DurationValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class ListValue extends DataValue {
  const ListValue(final  List<DataValue> values): _values = values,super._();
  

 final  List<DataValue> _values;
 List<DataValue> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListValueCopyWith<ListValue> get copyWith => _$ListValueCopyWithImpl<ListValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListValue&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'DataValue.list(values: $values)';
}


}

/// @nodoc
abstract mixin class $ListValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $ListValueCopyWith(ListValue value, $Res Function(ListValue) _then) = _$ListValueCopyWithImpl;
@useResult
$Res call({
 List<DataValue> values
});




}
/// @nodoc
class _$ListValueCopyWithImpl<$Res>
    implements $ListValueCopyWith<$Res> {
  _$ListValueCopyWithImpl(this._self, this._then);

  final ListValue _self;
  final $Res Function(ListValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(ListValue(
null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<DataValue>,
  ));
}


}

/// @nodoc


class MapValue extends DataValue {
  const MapValue(final  List<DataMapEntry> entries): _entries = entries,super._();
  

 final  List<DataMapEntry> _entries;
 List<DataMapEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapValueCopyWith<MapValue> get copyWith => _$MapValueCopyWithImpl<MapValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapValue&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'DataValue.map(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $MapValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $MapValueCopyWith(MapValue value, $Res Function(MapValue) _then) = _$MapValueCopyWithImpl;
@useResult
$Res call({
 List<DataMapEntry> entries
});




}
/// @nodoc
class _$MapValueCopyWithImpl<$Res>
    implements $MapValueCopyWith<$Res> {
  _$MapValueCopyWithImpl(this._self, this._then);

  final MapValue _self;
  final $Res Function(MapValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(MapValue(
null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<DataMapEntry>,
  ));
}


}

/// @nodoc


class _RecordValue extends DataValue implements RecordValue {
  const _RecordValue(final  Map<String, DataValue> fields): _fields = fields,super._();
  

 final  Map<String, DataValue> _fields;
 Map<String, DataValue> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecordValueCopyWith<_RecordValue> get copyWith => __$RecordValueCopyWithImpl<_RecordValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecordValue&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'DataValue.record(fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$RecordValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory _$RecordValueCopyWith(_RecordValue value, $Res Function(_RecordValue) _then) = __$RecordValueCopyWithImpl;
@useResult
$Res call({
 Map<String, DataValue> fields
});




}
/// @nodoc
class __$RecordValueCopyWithImpl<$Res>
    implements _$RecordValueCopyWith<$Res> {
  __$RecordValueCopyWithImpl(this._self, this._then);

  final _RecordValue _self;
  final $Res Function(_RecordValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(_RecordValue(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, DataValue>,
  ));
}


}

/// @nodoc


class PolymorphicValue extends DataValue {
  const PolymorphicValue({required this.concreteType, required this.value}): super._();
  

 final  ResolvedTypeRef concreteType;
 final  DataValue value;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolymorphicValueCopyWith<PolymorphicValue> get copyWith => _$PolymorphicValueCopyWithImpl<PolymorphicValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PolymorphicValue&&(identical(other.concreteType, concreteType) || other.concreteType == concreteType)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,concreteType,value);

@override
String toString() {
  return 'DataValue.polymorphic(concreteType: $concreteType, value: $value)';
}


}

/// @nodoc
abstract mixin class $PolymorphicValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $PolymorphicValueCopyWith(PolymorphicValue value, $Res Function(PolymorphicValue) _then) = _$PolymorphicValueCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef concreteType, DataValue value
});


$ResolvedTypeRefCopyWith<$Res> get concreteType;$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$PolymorphicValueCopyWithImpl<$Res>
    implements $PolymorphicValueCopyWith<$Res> {
  _$PolymorphicValueCopyWithImpl(this._self, this._then);

  final PolymorphicValue _self;
  final $Res Function(PolymorphicValue) _then;

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? concreteType = null,Object? value = null,}) {
  return _then(PolymorphicValue(
concreteType: null == concreteType ? _self.concreteType : concreteType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of DataValue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get concreteType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.concreteType, (value) {
    return _then(_self.copyWith(concreteType: value));
  });
}/// Create a copy of DataValue
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
mixin _$BytesValue {

 Uint8List get value;
/// Create a copy of BytesValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BytesValueCopyWith<BytesValue> get copyWith => _$BytesValueCopyWithImpl<BytesValue>(this as BytesValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BytesValue&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'BytesValue(value: $value)';
}


}

/// @nodoc
abstract mixin class $BytesValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $BytesValueCopyWith(BytesValue value, $Res Function(BytesValue) _then) = _$BytesValueCopyWithImpl;
@useResult
$Res call({
 Uint8List value
});




}
/// @nodoc
class _$BytesValueCopyWithImpl<$Res>
    implements $BytesValueCopyWith<$Res> {
  _$BytesValueCopyWithImpl(this._self, this._then);

  final BytesValue _self;
  final $Res Function(BytesValue) _then;

/// Create a copy of BytesValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(BytesValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [BytesValue].
extension BytesValuePatterns on BytesValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

/// @nodoc
mixin _$TimestampValue {

 DateTime get value;
/// Create a copy of TimestampValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimestampValueCopyWith<TimestampValue> get copyWith => _$TimestampValueCopyWithImpl<TimestampValue>(this as TimestampValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimestampValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TimestampValue(value: $value)';
}


}

/// @nodoc
abstract mixin class $TimestampValueCopyWith<$Res> implements $DataValueCopyWith<$Res> {
  factory $TimestampValueCopyWith(TimestampValue value, $Res Function(TimestampValue) _then) = _$TimestampValueCopyWithImpl;
@useResult
$Res call({
 DateTime value
});




}
/// @nodoc
class _$TimestampValueCopyWithImpl<$Res>
    implements $TimestampValueCopyWith<$Res> {
  _$TimestampValueCopyWithImpl(this._self, this._then);

  final TimestampValue _self;
  final $Res Function(TimestampValue) _then;

/// Create a copy of TimestampValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(TimestampValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TimestampValue].
extension TimestampValuePatterns on TimestampValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

/// @nodoc
mixin _$DataMapEntry {

 DataValue get key; DataValue get value;
/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataMapEntryCopyWith<DataMapEntry> get copyWith => _$DataMapEntryCopyWithImpl<DataMapEntry>(this as DataMapEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataMapEntry&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'DataMapEntry(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $DataMapEntryCopyWith<$Res>  {
  factory $DataMapEntryCopyWith(DataMapEntry value, $Res Function(DataMapEntry) _then) = _$DataMapEntryCopyWithImpl;
@useResult
$Res call({
 DataValue key, DataValue value
});


$DataValueCopyWith<$Res> get key;$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$DataMapEntryCopyWithImpl<$Res>
    implements $DataMapEntryCopyWith<$Res> {
  _$DataMapEntryCopyWithImpl(this._self, this._then);

  final DataMapEntry _self;
  final $Res Function(DataMapEntry) _then;

/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? value = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as DataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}
/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get key {
  
  return $DataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [DataMapEntry].
extension DataMapEntryPatterns on DataMapEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataMapEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataMapEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataMapEntry value)  $default,){
final _that = this;
switch (_that) {
case _DataMapEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataMapEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DataMapEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataValue key,  DataValue value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataMapEntry() when $default != null:
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataValue key,  DataValue value)  $default,) {final _that = this;
switch (_that) {
case _DataMapEntry():
return $default(_that.key,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataValue key,  DataValue value)?  $default,) {final _that = this;
switch (_that) {
case _DataMapEntry() when $default != null:
return $default(_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _DataMapEntry implements DataMapEntry {
  const _DataMapEntry({required this.key, required this.value});
  

@override final  DataValue key;
@override final  DataValue value;

/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataMapEntryCopyWith<_DataMapEntry> get copyWith => __$DataMapEntryCopyWithImpl<_DataMapEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataMapEntry&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'DataMapEntry(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$DataMapEntryCopyWith<$Res> implements $DataMapEntryCopyWith<$Res> {
  factory _$DataMapEntryCopyWith(_DataMapEntry value, $Res Function(_DataMapEntry) _then) = __$DataMapEntryCopyWithImpl;
@override @useResult
$Res call({
 DataValue key, DataValue value
});


@override $DataValueCopyWith<$Res> get key;@override $DataValueCopyWith<$Res> get value;

}
/// @nodoc
class __$DataMapEntryCopyWithImpl<$Res>
    implements _$DataMapEntryCopyWith<$Res> {
  __$DataMapEntryCopyWithImpl(this._self, this._then);

  final _DataMapEntry _self;
  final $Res Function(_DataMapEntry) _then;

/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(_DataMapEntry(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as DataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get key {
  
  return $DataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of DataMapEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get value {
  
  return $DataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

// dart format on
