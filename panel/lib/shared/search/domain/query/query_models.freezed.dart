// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'query_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueryCursorContext {

 int get cursorOffset; QueryRange get activeRange;
/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryCursorContextCopyWith<QueryCursorContext> get copyWith => _$QueryCursorContextCopyWithImpl<QueryCursorContext>(this as QueryCursorContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryCursorContext&&(identical(other.cursorOffset, cursorOffset) || other.cursorOffset == cursorOffset)&&(identical(other.activeRange, activeRange) || other.activeRange == activeRange));
}


@override
int get hashCode => Object.hash(runtimeType,cursorOffset,activeRange);

@override
String toString() {
  return 'QueryCursorContext(cursorOffset: $cursorOffset, activeRange: $activeRange)';
}


}

/// @nodoc
abstract mixin class $QueryCursorContextCopyWith<$Res>  {
  factory $QueryCursorContextCopyWith(QueryCursorContext value, $Res Function(QueryCursorContext) _then) = _$QueryCursorContextCopyWithImpl;
@useResult
$Res call({
 int cursorOffset, QueryRange activeRange
});




}
/// @nodoc
class _$QueryCursorContextCopyWithImpl<$Res>
    implements $QueryCursorContextCopyWith<$Res> {
  _$QueryCursorContextCopyWithImpl(this._self, this._then);

  final QueryCursorContext _self;
  final $Res Function(QueryCursorContext) _then;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursorOffset = null,Object? activeRange = null,}) {
  return _then(_self.copyWith(
cursorOffset: null == cursorOffset ? _self.cursorOffset : cursorOffset // ignore: cast_nullable_to_non_nullable
as int,activeRange: null == activeRange ? _self.activeRange : activeRange // ignore: cast_nullable_to_non_nullable
as QueryRange,
  ));
}

}


/// Adds pattern-matching-related methods to [QueryCursorContext].
extension QueryCursorContextPatterns on QueryCursorContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectorKeyCursorContext value)?  selectorKey,TResult Function( SelectorValueCursorContext value)?  selectorValue,TResult Function( OperatorCursorContext value)?  operator,TResult Function( UnknownCursorContext value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectorKeyCursorContext() when selectorKey != null:
return selectorKey(_that);case SelectorValueCursorContext() when selectorValue != null:
return selectorValue(_that);case OperatorCursorContext() when operator != null:
return operator(_that);case UnknownCursorContext() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectorKeyCursorContext value)  selectorKey,required TResult Function( SelectorValueCursorContext value)  selectorValue,required TResult Function( OperatorCursorContext value)  operator,required TResult Function( UnknownCursorContext value)  unknown,}){
final _that = this;
switch (_that) {
case SelectorKeyCursorContext():
return selectorKey(_that);case SelectorValueCursorContext():
return selectorValue(_that);case OperatorCursorContext():
return operator(_that);case UnknownCursorContext():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectorKeyCursorContext value)?  selectorKey,TResult? Function( SelectorValueCursorContext value)?  selectorValue,TResult? Function( OperatorCursorContext value)?  operator,TResult? Function( UnknownCursorContext value)?  unknown,}){
final _that = this;
switch (_that) {
case SelectorKeyCursorContext() when selectorKey != null:
return selectorKey(_that);case SelectorValueCursorContext() when selectorValue != null:
return selectorValue(_that);case OperatorCursorContext() when operator != null:
return operator(_that);case UnknownCursorContext() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int cursorOffset,  QueryRange activeRange,  String partialKey)?  selectorKey,TResult Function( int cursorOffset,  QueryRange activeRange,  String selectorId,  String partialValue,  QueryRange keyRange,  QueryRange? valueRange)?  selectorValue,TResult Function( int cursorOffset,  QueryRange activeRange,  String partialOperator)?  operator,TResult Function( int cursorOffset,  QueryRange activeRange,  String partial,  QuerySide side)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectorKeyCursorContext() when selectorKey != null:
return selectorKey(_that.cursorOffset,_that.activeRange,_that.partialKey);case SelectorValueCursorContext() when selectorValue != null:
return selectorValue(_that.cursorOffset,_that.activeRange,_that.selectorId,_that.partialValue,_that.keyRange,_that.valueRange);case OperatorCursorContext() when operator != null:
return operator(_that.cursorOffset,_that.activeRange,_that.partialOperator);case UnknownCursorContext() when unknown != null:
return unknown(_that.cursorOffset,_that.activeRange,_that.partial,_that.side);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int cursorOffset,  QueryRange activeRange,  String partialKey)  selectorKey,required TResult Function( int cursorOffset,  QueryRange activeRange,  String selectorId,  String partialValue,  QueryRange keyRange,  QueryRange? valueRange)  selectorValue,required TResult Function( int cursorOffset,  QueryRange activeRange,  String partialOperator)  operator,required TResult Function( int cursorOffset,  QueryRange activeRange,  String partial,  QuerySide side)  unknown,}) {final _that = this;
switch (_that) {
case SelectorKeyCursorContext():
return selectorKey(_that.cursorOffset,_that.activeRange,_that.partialKey);case SelectorValueCursorContext():
return selectorValue(_that.cursorOffset,_that.activeRange,_that.selectorId,_that.partialValue,_that.keyRange,_that.valueRange);case OperatorCursorContext():
return operator(_that.cursorOffset,_that.activeRange,_that.partialOperator);case UnknownCursorContext():
return unknown(_that.cursorOffset,_that.activeRange,_that.partial,_that.side);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int cursorOffset,  QueryRange activeRange,  String partialKey)?  selectorKey,TResult? Function( int cursorOffset,  QueryRange activeRange,  String selectorId,  String partialValue,  QueryRange keyRange,  QueryRange? valueRange)?  selectorValue,TResult? Function( int cursorOffset,  QueryRange activeRange,  String partialOperator)?  operator,TResult? Function( int cursorOffset,  QueryRange activeRange,  String partial,  QuerySide side)?  unknown,}) {final _that = this;
switch (_that) {
case SelectorKeyCursorContext() when selectorKey != null:
return selectorKey(_that.cursorOffset,_that.activeRange,_that.partialKey);case SelectorValueCursorContext() when selectorValue != null:
return selectorValue(_that.cursorOffset,_that.activeRange,_that.selectorId,_that.partialValue,_that.keyRange,_that.valueRange);case OperatorCursorContext() when operator != null:
return operator(_that.cursorOffset,_that.activeRange,_that.partialOperator);case UnknownCursorContext() when unknown != null:
return unknown(_that.cursorOffset,_that.activeRange,_that.partial,_that.side);case _:
  return null;

}
}

}

/// @nodoc


class SelectorKeyCursorContext implements QueryCursorContext {
  const SelectorKeyCursorContext({required this.cursorOffset, required this.activeRange, required this.partialKey});


@override final  int cursorOffset;
@override final  QueryRange activeRange;
 final  String partialKey;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectorKeyCursorContextCopyWith<SelectorKeyCursorContext> get copyWith => _$SelectorKeyCursorContextCopyWithImpl<SelectorKeyCursorContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectorKeyCursorContext&&(identical(other.cursorOffset, cursorOffset) || other.cursorOffset == cursorOffset)&&(identical(other.activeRange, activeRange) || other.activeRange == activeRange)&&(identical(other.partialKey, partialKey) || other.partialKey == partialKey));
}


@override
int get hashCode => Object.hash(runtimeType,cursorOffset,activeRange,partialKey);

@override
String toString() {
  return 'QueryCursorContext.selectorKey(cursorOffset: $cursorOffset, activeRange: $activeRange, partialKey: $partialKey)';
}


}

/// @nodoc
abstract mixin class $SelectorKeyCursorContextCopyWith<$Res> implements $QueryCursorContextCopyWith<$Res> {
  factory $SelectorKeyCursorContextCopyWith(SelectorKeyCursorContext value, $Res Function(SelectorKeyCursorContext) _then) = _$SelectorKeyCursorContextCopyWithImpl;
@override @useResult
$Res call({
 int cursorOffset, QueryRange activeRange, String partialKey
});




}
/// @nodoc
class _$SelectorKeyCursorContextCopyWithImpl<$Res>
    implements $SelectorKeyCursorContextCopyWith<$Res> {
  _$SelectorKeyCursorContextCopyWithImpl(this._self, this._then);

  final SelectorKeyCursorContext _self;
  final $Res Function(SelectorKeyCursorContext) _then;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursorOffset = null,Object? activeRange = null,Object? partialKey = null,}) {
  return _then(SelectorKeyCursorContext(
cursorOffset: null == cursorOffset ? _self.cursorOffset : cursorOffset // ignore: cast_nullable_to_non_nullable
as int,activeRange: null == activeRange ? _self.activeRange : activeRange // ignore: cast_nullable_to_non_nullable
as QueryRange,partialKey: null == partialKey ? _self.partialKey : partialKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SelectorValueCursorContext implements QueryCursorContext {
  const SelectorValueCursorContext({required this.cursorOffset, required this.activeRange, required this.selectorId, required this.partialValue, required this.keyRange, required this.valueRange});


@override final  int cursorOffset;
@override final  QueryRange activeRange;
 final  String selectorId;
 final  String partialValue;
 final  QueryRange keyRange;
 final  QueryRange? valueRange;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectorValueCursorContextCopyWith<SelectorValueCursorContext> get copyWith => _$SelectorValueCursorContextCopyWithImpl<SelectorValueCursorContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectorValueCursorContext&&(identical(other.cursorOffset, cursorOffset) || other.cursorOffset == cursorOffset)&&(identical(other.activeRange, activeRange) || other.activeRange == activeRange)&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId)&&(identical(other.partialValue, partialValue) || other.partialValue == partialValue)&&(identical(other.keyRange, keyRange) || other.keyRange == keyRange)&&(identical(other.valueRange, valueRange) || other.valueRange == valueRange));
}


@override
int get hashCode => Object.hash(runtimeType,cursorOffset,activeRange,selectorId,partialValue,keyRange,valueRange);

@override
String toString() {
  return 'QueryCursorContext.selectorValue(cursorOffset: $cursorOffset, activeRange: $activeRange, selectorId: $selectorId, partialValue: $partialValue, keyRange: $keyRange, valueRange: $valueRange)';
}


}

/// @nodoc
abstract mixin class $SelectorValueCursorContextCopyWith<$Res> implements $QueryCursorContextCopyWith<$Res> {
  factory $SelectorValueCursorContextCopyWith(SelectorValueCursorContext value, $Res Function(SelectorValueCursorContext) _then) = _$SelectorValueCursorContextCopyWithImpl;
@override @useResult
$Res call({
 int cursorOffset, QueryRange activeRange, String selectorId, String partialValue, QueryRange keyRange, QueryRange? valueRange
});




}
/// @nodoc
class _$SelectorValueCursorContextCopyWithImpl<$Res>
    implements $SelectorValueCursorContextCopyWith<$Res> {
  _$SelectorValueCursorContextCopyWithImpl(this._self, this._then);

  final SelectorValueCursorContext _self;
  final $Res Function(SelectorValueCursorContext) _then;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursorOffset = null,Object? activeRange = null,Object? selectorId = null,Object? partialValue = null,Object? keyRange = null,Object? valueRange = freezed,}) {
  return _then(SelectorValueCursorContext(
cursorOffset: null == cursorOffset ? _self.cursorOffset : cursorOffset // ignore: cast_nullable_to_non_nullable
as int,activeRange: null == activeRange ? _self.activeRange : activeRange // ignore: cast_nullable_to_non_nullable
as QueryRange,selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,partialValue: null == partialValue ? _self.partialValue : partialValue // ignore: cast_nullable_to_non_nullable
as String,keyRange: null == keyRange ? _self.keyRange : keyRange // ignore: cast_nullable_to_non_nullable
as QueryRange,valueRange: freezed == valueRange ? _self.valueRange : valueRange // ignore: cast_nullable_to_non_nullable
as QueryRange?,
  ));
}


}

/// @nodoc


class OperatorCursorContext implements QueryCursorContext {
  const OperatorCursorContext({required this.cursorOffset, required this.activeRange, required this.partialOperator});


@override final  int cursorOffset;
@override final  QueryRange activeRange;
 final  String partialOperator;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperatorCursorContextCopyWith<OperatorCursorContext> get copyWith => _$OperatorCursorContextCopyWithImpl<OperatorCursorContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperatorCursorContext&&(identical(other.cursorOffset, cursorOffset) || other.cursorOffset == cursorOffset)&&(identical(other.activeRange, activeRange) || other.activeRange == activeRange)&&(identical(other.partialOperator, partialOperator) || other.partialOperator == partialOperator));
}


@override
int get hashCode => Object.hash(runtimeType,cursorOffset,activeRange,partialOperator);

@override
String toString() {
  return 'QueryCursorContext.operator(cursorOffset: $cursorOffset, activeRange: $activeRange, partialOperator: $partialOperator)';
}


}

/// @nodoc
abstract mixin class $OperatorCursorContextCopyWith<$Res> implements $QueryCursorContextCopyWith<$Res> {
  factory $OperatorCursorContextCopyWith(OperatorCursorContext value, $Res Function(OperatorCursorContext) _then) = _$OperatorCursorContextCopyWithImpl;
@override @useResult
$Res call({
 int cursorOffset, QueryRange activeRange, String partialOperator
});




}
/// @nodoc
class _$OperatorCursorContextCopyWithImpl<$Res>
    implements $OperatorCursorContextCopyWith<$Res> {
  _$OperatorCursorContextCopyWithImpl(this._self, this._then);

  final OperatorCursorContext _self;
  final $Res Function(OperatorCursorContext) _then;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursorOffset = null,Object? activeRange = null,Object? partialOperator = null,}) {
  return _then(OperatorCursorContext(
cursorOffset: null == cursorOffset ? _self.cursorOffset : cursorOffset // ignore: cast_nullable_to_non_nullable
as int,activeRange: null == activeRange ? _self.activeRange : activeRange // ignore: cast_nullable_to_non_nullable
as QueryRange,partialOperator: null == partialOperator ? _self.partialOperator : partialOperator // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnknownCursorContext implements QueryCursorContext {
  const UnknownCursorContext({required this.cursorOffset, required this.activeRange, required this.partial, required this.side});


@override final  int cursorOffset;
@override final  QueryRange activeRange;
 final  String partial;
 final  QuerySide side;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownCursorContextCopyWith<UnknownCursorContext> get copyWith => _$UnknownCursorContextCopyWithImpl<UnknownCursorContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownCursorContext&&(identical(other.cursorOffset, cursorOffset) || other.cursorOffset == cursorOffset)&&(identical(other.activeRange, activeRange) || other.activeRange == activeRange)&&(identical(other.partial, partial) || other.partial == partial)&&(identical(other.side, side) || other.side == side));
}


@override
int get hashCode => Object.hash(runtimeType,cursorOffset,activeRange,partial,side);

@override
String toString() {
  return 'QueryCursorContext.unknown(cursorOffset: $cursorOffset, activeRange: $activeRange, partial: $partial, side: $side)';
}


}

/// @nodoc
abstract mixin class $UnknownCursorContextCopyWith<$Res> implements $QueryCursorContextCopyWith<$Res> {
  factory $UnknownCursorContextCopyWith(UnknownCursorContext value, $Res Function(UnknownCursorContext) _then) = _$UnknownCursorContextCopyWithImpl;
@override @useResult
$Res call({
 int cursorOffset, QueryRange activeRange, String partial, QuerySide side
});




}
/// @nodoc
class _$UnknownCursorContextCopyWithImpl<$Res>
    implements $UnknownCursorContextCopyWith<$Res> {
  _$UnknownCursorContextCopyWithImpl(this._self, this._then);

  final UnknownCursorContext _self;
  final $Res Function(UnknownCursorContext) _then;

/// Create a copy of QueryCursorContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursorOffset = null,Object? activeRange = null,Object? partial = null,Object? side = null,}) {
  return _then(UnknownCursorContext(
cursorOffset: null == cursorOffset ? _self.cursorOffset : cursorOffset // ignore: cast_nullable_to_non_nullable
as int,activeRange: null == activeRange ? _self.activeRange : activeRange // ignore: cast_nullable_to_non_nullable
as QueryRange,partial: null == partial ? _self.partial : partial // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as QuerySide,
  ));
}


}

/// @nodoc
mixin _$QuerySuggestion {

 String get label; QueryRange get replaceRange;
/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuerySuggestionCopyWith<QuerySuggestion> get copyWith => _$QuerySuggestionCopyWithImpl<QuerySuggestion>(this as QuerySuggestion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuerySuggestion&&(identical(other.label, label) || other.label == label)&&(identical(other.replaceRange, replaceRange) || other.replaceRange == replaceRange));
}


@override
int get hashCode => Object.hash(runtimeType,label,replaceRange);

@override
String toString() {
  return 'QuerySuggestion(label: $label, replaceRange: $replaceRange)';
}


}

/// @nodoc
abstract mixin class $QuerySuggestionCopyWith<$Res>  {
  factory $QuerySuggestionCopyWith(QuerySuggestion value, $Res Function(QuerySuggestion) _then) = _$QuerySuggestionCopyWithImpl;
@useResult
$Res call({
 String label, QueryRange replaceRange
});




}
/// @nodoc
class _$QuerySuggestionCopyWithImpl<$Res>
    implements $QuerySuggestionCopyWith<$Res> {
  _$QuerySuggestionCopyWithImpl(this._self, this._then);

  final QuerySuggestion _self;
  final $Res Function(QuerySuggestion) _then;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? replaceRange = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,replaceRange: null == replaceRange ? _self.replaceRange : replaceRange // ignore: cast_nullable_to_non_nullable
as QueryRange,
  ));
}

}


/// Adds pattern-matching-related methods to [QuerySuggestion].
extension QuerySuggestionPatterns on QuerySuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectorKeySuggestion value)?  selectorKey,TResult Function( SelectorValueSuggestion value)?  selectorValue,TResult Function( OperatorSuggestion value)?  operator,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectorKeySuggestion() when selectorKey != null:
return selectorKey(_that);case SelectorValueSuggestion() when selectorValue != null:
return selectorValue(_that);case OperatorSuggestion() when operator != null:
return operator(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectorKeySuggestion value)  selectorKey,required TResult Function( SelectorValueSuggestion value)  selectorValue,required TResult Function( OperatorSuggestion value)  operator,}){
final _that = this;
switch (_that) {
case SelectorKeySuggestion():
return selectorKey(_that);case SelectorValueSuggestion():
return selectorValue(_that);case OperatorSuggestion():
return operator(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectorKeySuggestion value)?  selectorKey,TResult? Function( SelectorValueSuggestion value)?  selectorValue,TResult? Function( OperatorSuggestion value)?  operator,}){
final _that = this;
switch (_that) {
case SelectorKeySuggestion() when selectorKey != null:
return selectorKey(_that);case SelectorValueSuggestion() when selectorValue != null:
return selectorValue(_that);case OperatorSuggestion() when operator != null:
return operator(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String label,  QueryRange replaceRange,  String selectorId)?  selectorKey,TResult Function( String label,  QueryRange replaceRange,  String selectorId,  String value)?  selectorValue,TResult Function( String label,  QueryRange replaceRange,  String operatorToken)?  operator,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectorKeySuggestion() when selectorKey != null:
return selectorKey(_that.label,_that.replaceRange,_that.selectorId);case SelectorValueSuggestion() when selectorValue != null:
return selectorValue(_that.label,_that.replaceRange,_that.selectorId,_that.value);case OperatorSuggestion() when operator != null:
return operator(_that.label,_that.replaceRange,_that.operatorToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String label,  QueryRange replaceRange,  String selectorId)  selectorKey,required TResult Function( String label,  QueryRange replaceRange,  String selectorId,  String value)  selectorValue,required TResult Function( String label,  QueryRange replaceRange,  String operatorToken)  operator,}) {final _that = this;
switch (_that) {
case SelectorKeySuggestion():
return selectorKey(_that.label,_that.replaceRange,_that.selectorId);case SelectorValueSuggestion():
return selectorValue(_that.label,_that.replaceRange,_that.selectorId,_that.value);case OperatorSuggestion():
return operator(_that.label,_that.replaceRange,_that.operatorToken);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String label,  QueryRange replaceRange,  String selectorId)?  selectorKey,TResult? Function( String label,  QueryRange replaceRange,  String selectorId,  String value)?  selectorValue,TResult? Function( String label,  QueryRange replaceRange,  String operatorToken)?  operator,}) {final _that = this;
switch (_that) {
case SelectorKeySuggestion() when selectorKey != null:
return selectorKey(_that.label,_that.replaceRange,_that.selectorId);case SelectorValueSuggestion() when selectorValue != null:
return selectorValue(_that.label,_that.replaceRange,_that.selectorId,_that.value);case OperatorSuggestion() when operator != null:
return operator(_that.label,_that.replaceRange,_that.operatorToken);case _:
  return null;

}
}

}

/// @nodoc


class SelectorKeySuggestion implements QuerySuggestion {
  const SelectorKeySuggestion({required this.label, required this.replaceRange, required this.selectorId});


@override final  String label;
@override final  QueryRange replaceRange;
 final  String selectorId;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectorKeySuggestionCopyWith<SelectorKeySuggestion> get copyWith => _$SelectorKeySuggestionCopyWithImpl<SelectorKeySuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectorKeySuggestion&&(identical(other.label, label) || other.label == label)&&(identical(other.replaceRange, replaceRange) || other.replaceRange == replaceRange)&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId));
}


@override
int get hashCode => Object.hash(runtimeType,label,replaceRange,selectorId);

@override
String toString() {
  return 'QuerySuggestion.selectorKey(label: $label, replaceRange: $replaceRange, selectorId: $selectorId)';
}


}

/// @nodoc
abstract mixin class $SelectorKeySuggestionCopyWith<$Res> implements $QuerySuggestionCopyWith<$Res> {
  factory $SelectorKeySuggestionCopyWith(SelectorKeySuggestion value, $Res Function(SelectorKeySuggestion) _then) = _$SelectorKeySuggestionCopyWithImpl;
@override @useResult
$Res call({
 String label, QueryRange replaceRange, String selectorId
});




}
/// @nodoc
class _$SelectorKeySuggestionCopyWithImpl<$Res>
    implements $SelectorKeySuggestionCopyWith<$Res> {
  _$SelectorKeySuggestionCopyWithImpl(this._self, this._then);

  final SelectorKeySuggestion _self;
  final $Res Function(SelectorKeySuggestion) _then;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? replaceRange = null,Object? selectorId = null,}) {
  return _then(SelectorKeySuggestion(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,replaceRange: null == replaceRange ? _self.replaceRange : replaceRange // ignore: cast_nullable_to_non_nullable
as QueryRange,selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SelectorValueSuggestion implements QuerySuggestion {
  const SelectorValueSuggestion({required this.label, required this.replaceRange, required this.selectorId, required this.value});


@override final  String label;
@override final  QueryRange replaceRange;
 final  String selectorId;
 final  String value;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectorValueSuggestionCopyWith<SelectorValueSuggestion> get copyWith => _$SelectorValueSuggestionCopyWithImpl<SelectorValueSuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectorValueSuggestion&&(identical(other.label, label) || other.label == label)&&(identical(other.replaceRange, replaceRange) || other.replaceRange == replaceRange)&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,label,replaceRange,selectorId,value);

@override
String toString() {
  return 'QuerySuggestion.selectorValue(label: $label, replaceRange: $replaceRange, selectorId: $selectorId, value: $value)';
}


}

/// @nodoc
abstract mixin class $SelectorValueSuggestionCopyWith<$Res> implements $QuerySuggestionCopyWith<$Res> {
  factory $SelectorValueSuggestionCopyWith(SelectorValueSuggestion value, $Res Function(SelectorValueSuggestion) _then) = _$SelectorValueSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String label, QueryRange replaceRange, String selectorId, String value
});




}
/// @nodoc
class _$SelectorValueSuggestionCopyWithImpl<$Res>
    implements $SelectorValueSuggestionCopyWith<$Res> {
  _$SelectorValueSuggestionCopyWithImpl(this._self, this._then);

  final SelectorValueSuggestion _self;
  final $Res Function(SelectorValueSuggestion) _then;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? replaceRange = null,Object? selectorId = null,Object? value = null,}) {
  return _then(SelectorValueSuggestion(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,replaceRange: null == replaceRange ? _self.replaceRange : replaceRange // ignore: cast_nullable_to_non_nullable
as QueryRange,selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OperatorSuggestion implements QuerySuggestion {
  const OperatorSuggestion({required this.label, required this.replaceRange, required this.operatorToken});


@override final  String label;
@override final  QueryRange replaceRange;
 final  String operatorToken;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperatorSuggestionCopyWith<OperatorSuggestion> get copyWith => _$OperatorSuggestionCopyWithImpl<OperatorSuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperatorSuggestion&&(identical(other.label, label) || other.label == label)&&(identical(other.replaceRange, replaceRange) || other.replaceRange == replaceRange)&&(identical(other.operatorToken, operatorToken) || other.operatorToken == operatorToken));
}


@override
int get hashCode => Object.hash(runtimeType,label,replaceRange,operatorToken);

@override
String toString() {
  return 'QuerySuggestion.operator(label: $label, replaceRange: $replaceRange, operatorToken: $operatorToken)';
}


}

/// @nodoc
abstract mixin class $OperatorSuggestionCopyWith<$Res> implements $QuerySuggestionCopyWith<$Res> {
  factory $OperatorSuggestionCopyWith(OperatorSuggestion value, $Res Function(OperatorSuggestion) _then) = _$OperatorSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String label, QueryRange replaceRange, String operatorToken
});




}
/// @nodoc
class _$OperatorSuggestionCopyWithImpl<$Res>
    implements $OperatorSuggestionCopyWith<$Res> {
  _$OperatorSuggestionCopyWithImpl(this._self, this._then);

  final OperatorSuggestion _self;
  final $Res Function(OperatorSuggestion) _then;

/// Create a copy of QuerySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? replaceRange = null,Object? operatorToken = null,}) {
  return _then(OperatorSuggestion(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,replaceRange: null == replaceRange ? _self.replaceRange : replaceRange // ignore: cast_nullable_to_non_nullable
as QueryRange,operatorToken: null == operatorToken ? _self.operatorToken : operatorToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
