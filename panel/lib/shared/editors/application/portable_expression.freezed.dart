// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_expression.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableExpressionResult {

 List<PortableExpressionRead> get reads;
/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExpressionResultCopyWith<PortableExpressionResult> get copyWith => _$PortableExpressionResultCopyWithImpl<PortableExpressionResult>(this as PortableExpressionResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableExpressionResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionResult&&const DeepCollectionEquality().equals(other.reads, _this.reads));
}


@override
int get hashCode {
  final _this = this as PortableExpressionResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.reads));
}

@override
String toString() {
  final _this = this as PortableExpressionResult;
  return 'PortableExpressionResult(reads: ${_this.reads})';
}


}

/// @nodoc
abstract mixin class $PortableExpressionResultCopyWith<$Res>  {
  factory $PortableExpressionResultCopyWith(PortableExpressionResult value, $Res Function(PortableExpressionResult) _then) = _$PortableExpressionResultCopyWithImpl;
@useResult
$Res call({
 List<PortableExpressionRead> reads
});




}
/// @nodoc
class _$PortableExpressionResultCopyWithImpl<$Res>
    implements $PortableExpressionResultCopyWith<$Res> {
  _$PortableExpressionResultCopyWithImpl(this._self, this._then);

  final PortableExpressionResult _self;
  final $Res Function(PortableExpressionResult) _then;

/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reads = null,}) {
  return _then(_self.copyWith(
reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as List<PortableExpressionRead>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableExpressionResult].
extension PortableExpressionResultPatterns on PortableExpressionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableExpressionAvailable value)?  available,TResult Function( PortableExpressionUnavailable value)?  unavailable,TResult Function( PortableExpressionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that);case PortableExpressionFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableExpressionAvailable value)  available,required TResult Function( PortableExpressionUnavailable value)  unavailable,required TResult Function( PortableExpressionFailed value)  failed,}){
final _that = this;
switch (_that) {
case PortableExpressionAvailable():
return available(_that);case PortableExpressionUnavailable():
return unavailable(_that);case PortableExpressionFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableExpressionAvailable value)?  available,TResult? Function( PortableExpressionUnavailable value)?  unavailable,TResult? Function( PortableExpressionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that);case PortableExpressionFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.DataValue value,  List<PortableExpressionRead> reads)?  available,TResult Function( List<PortableExpressionRead> reads)?  unavailable,TResult Function( String code,  String message,  List<PortableExpressionRead> reads)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that.value,_that.reads);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that.reads);case PortableExpressionFailed() when failed != null:
return failed(_that.code,_that.message,_that.reads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.DataValue value,  List<PortableExpressionRead> reads)  available,required TResult Function( List<PortableExpressionRead> reads)  unavailable,required TResult Function( String code,  String message,  List<PortableExpressionRead> reads)  failed,}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable():
return available(_that.value,_that.reads);case PortableExpressionUnavailable():
return unavailable(_that.reads);case PortableExpressionFailed():
return failed(_that.code,_that.message,_that.reads);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.DataValue value,  List<PortableExpressionRead> reads)?  available,TResult? Function( List<PortableExpressionRead> reads)?  unavailable,TResult? Function( String code,  String message,  List<PortableExpressionRead> reads)?  failed,}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that.value,_that.reads);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that.reads);case PortableExpressionFailed() when failed != null:
return failed(_that.code,_that.message,_that.reads);case _:
  return null;

}
}

}

/// @nodoc


class PortableExpressionAvailable implements PortableExpressionResult {
  const PortableExpressionAvailable(this.value,  List<PortableExpressionRead> reads): _reads = reads;
  

 final  skir.DataValue value;
 final  List<PortableExpressionRead> _reads;
@override List<PortableExpressionRead> get reads {
  if (_reads is EqualUnmodifiableListView) return _reads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reads);
}


/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExpressionAvailableCopyWith<PortableExpressionAvailable> get copyWith => _$PortableExpressionAvailableCopyWithImpl<PortableExpressionAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionAvailable&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.reads, _reads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_reads));
}

@override
String toString() {
    return 'PortableExpressionResult.available(value: $value, reads: $reads)';
}


}

/// @nodoc
abstract mixin class $PortableExpressionAvailableCopyWith<$Res> implements $PortableExpressionResultCopyWith<$Res> {
  factory $PortableExpressionAvailableCopyWith(PortableExpressionAvailable value, $Res Function(PortableExpressionAvailable) _then) = _$PortableExpressionAvailableCopyWithImpl;
@override @useResult
$Res call({
 skir.DataValue value, List<PortableExpressionRead> reads
});




}
/// @nodoc
class _$PortableExpressionAvailableCopyWithImpl<$Res>
    implements $PortableExpressionAvailableCopyWith<$Res> {
  _$PortableExpressionAvailableCopyWithImpl(this._self, this._then);

  final PortableExpressionAvailable _self;
  final $Res Function(PortableExpressionAvailable) _then;

/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? reads = null,}) {
  return _then(PortableExpressionAvailable(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,null == reads ? _self._reads : reads // ignore: cast_nullable_to_non_nullable
as List<PortableExpressionRead>,
  ));
}


}

/// @nodoc


class PortableExpressionUnavailable implements PortableExpressionResult {
  const PortableExpressionUnavailable( List<PortableExpressionRead> reads): _reads = reads;
  

 final  List<PortableExpressionRead> _reads;
@override List<PortableExpressionRead> get reads {
  if (_reads is EqualUnmodifiableListView) return _reads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reads);
}


/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExpressionUnavailableCopyWith<PortableExpressionUnavailable> get copyWith => _$PortableExpressionUnavailableCopyWithImpl<PortableExpressionUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionUnavailable&&const DeepCollectionEquality().equals(other.reads, _reads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_reads));
}

@override
String toString() {
    return 'PortableExpressionResult.unavailable(reads: $reads)';
}


}

/// @nodoc
abstract mixin class $PortableExpressionUnavailableCopyWith<$Res> implements $PortableExpressionResultCopyWith<$Res> {
  factory $PortableExpressionUnavailableCopyWith(PortableExpressionUnavailable value, $Res Function(PortableExpressionUnavailable) _then) = _$PortableExpressionUnavailableCopyWithImpl;
@override @useResult
$Res call({
 List<PortableExpressionRead> reads
});




}
/// @nodoc
class _$PortableExpressionUnavailableCopyWithImpl<$Res>
    implements $PortableExpressionUnavailableCopyWith<$Res> {
  _$PortableExpressionUnavailableCopyWithImpl(this._self, this._then);

  final PortableExpressionUnavailable _self;
  final $Res Function(PortableExpressionUnavailable) _then;

/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reads = null,}) {
  return _then(PortableExpressionUnavailable(
null == reads ? _self._reads : reads // ignore: cast_nullable_to_non_nullable
as List<PortableExpressionRead>,
  ));
}


}

/// @nodoc


class PortableExpressionFailed implements PortableExpressionResult {
  const PortableExpressionFailed(this.code, this.message,  List<PortableExpressionRead> reads): _reads = reads;
  

 final  String code;
 final  String message;
 final  List<PortableExpressionRead> _reads;
@override List<PortableExpressionRead> get reads {
  if (_reads is EqualUnmodifiableListView) return _reads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reads);
}


/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExpressionFailedCopyWith<PortableExpressionFailed> get copyWith => _$PortableExpressionFailedCopyWithImpl<PortableExpressionFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionFailed&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.reads, _reads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_reads));
}

@override
String toString() {
    return 'PortableExpressionResult.failed(code: $code, message: $message, reads: $reads)';
}


}

/// @nodoc
abstract mixin class $PortableExpressionFailedCopyWith<$Res> implements $PortableExpressionResultCopyWith<$Res> {
  factory $PortableExpressionFailedCopyWith(PortableExpressionFailed value, $Res Function(PortableExpressionFailed) _then) = _$PortableExpressionFailedCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, List<PortableExpressionRead> reads
});




}
/// @nodoc
class _$PortableExpressionFailedCopyWithImpl<$Res>
    implements $PortableExpressionFailedCopyWith<$Res> {
  _$PortableExpressionFailedCopyWithImpl(this._self, this._then);

  final PortableExpressionFailed _self;
  final $Res Function(PortableExpressionFailed) _then;

/// Create a copy of PortableExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? reads = null,}) {
  return _then(PortableExpressionFailed(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,null == reads ? _self._reads : reads // ignore: cast_nullable_to_non_nullable
as List<PortableExpressionRead>,
  ));
}


}

/// @nodoc
mixin _$PortableExpressionQueries {

 CheckedEditorCatalog get catalog; PortableAuthoringView? get authored;



@override
bool operator ==(Object other) {
  final _this = this as PortableExpressionQueries;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionQueries&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.authored, _this.authored) || other.authored == _this.authored));
}


@override
int get hashCode {
  final _this = this as PortableExpressionQueries;
  return Object.hash(runtimeType,_this.catalog,_this.authored);
}

@override
String toString() {
  final _this = this as PortableExpressionQueries;
  return 'PortableExpressionQueries(catalog: ${_this.catalog}, authored: ${_this.authored})';
}


}





/// @nodoc


class _PortableExpressionQueries extends PortableExpressionQueries {
  const _PortableExpressionQueries({required this.catalog, required this.authored}): super._();
  

@override final  CheckedEditorCatalog catalog;
@override final  PortableAuthoringView? authored;




@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableExpressionQueries&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.authored, authored) || other.authored == authored));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,authored);
}

@override
String toString() {
    return 'PortableExpressionQueries._value(catalog: $catalog, authored: $authored)';
}


}




/// @nodoc
mixin _$ExpressionOccurrence {

 List<int> get path;
/// Create a copy of ExpressionOccurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpressionOccurrenceCopyWith<ExpressionOccurrence> get copyWith => _$ExpressionOccurrenceCopyWithImpl<ExpressionOccurrence>(this as ExpressionOccurrence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExpressionOccurrence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpressionOccurrence&&const DeepCollectionEquality().equals(other.path, _this.path));
}


@override
int get hashCode {
  final _this = this as ExpressionOccurrence;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.path));
}

@override
String toString() {
  final _this = this as ExpressionOccurrence;
  return 'ExpressionOccurrence(path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $ExpressionOccurrenceCopyWith<$Res>  {
  factory $ExpressionOccurrenceCopyWith(ExpressionOccurrence value, $Res Function(ExpressionOccurrence) _then) = _$ExpressionOccurrenceCopyWithImpl;
@useResult
$Res call({
 List<int> path
});




}
/// @nodoc
class _$ExpressionOccurrenceCopyWithImpl<$Res>
    implements $ExpressionOccurrenceCopyWith<$Res> {
  _$ExpressionOccurrenceCopyWithImpl(this._self, this._then);

  final ExpressionOccurrence _self;
  final $Res Function(ExpressionOccurrence) _then;

/// Create a copy of ExpressionOccurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,}) {
  return _then(ExpressionOccurrence(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpressionOccurrence].
extension ExpressionOccurrencePatterns on ExpressionOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpressionOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpressionOccurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpressionOccurrence value)  $default,){
final _that = this;
switch (_that) {
case _ExpressionOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpressionOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case _ExpressionOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpressionOccurrence() when $default != null:
return $default(_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> path)  $default,) {final _that = this;
switch (_that) {
case _ExpressionOccurrence():
return $default(_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> path)?  $default,) {final _that = this;
switch (_that) {
case _ExpressionOccurrence() when $default != null:
return $default(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _ExpressionOccurrence implements ExpressionOccurrence {
  const _ExpressionOccurrence({required  List<int> path}): _path = path;
  

 final  List<int> _path;
@override List<int> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}


/// Create a copy of ExpressionOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionOccurrenceCopyWith<_ExpressionOccurrence> get copyWith => __$ExpressionOccurrenceCopyWithImpl<_ExpressionOccurrence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionOccurrence&&const DeepCollectionEquality().equals(other.path, _path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_path));
}

@override
String toString() {
    return 'ExpressionOccurrence(path: $path)';
}


}

/// @nodoc
abstract mixin class _$ExpressionOccurrenceCopyWith<$Res> implements $ExpressionOccurrenceCopyWith<$Res> {
  factory _$ExpressionOccurrenceCopyWith(_ExpressionOccurrence value, $Res Function(_ExpressionOccurrence) _then) = __$ExpressionOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 List<int> path
});




}
/// @nodoc
class __$ExpressionOccurrenceCopyWithImpl<$Res>
    implements _$ExpressionOccurrenceCopyWith<$Res> {
  __$ExpressionOccurrenceCopyWithImpl(this._self, this._then);

  final _ExpressionOccurrence _self;
  final $Res Function(_ExpressionOccurrence) _then;

/// Create a copy of ExpressionOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(_ExpressionOccurrence(
path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
mixin _$CheckedQueryCall {

 skir.ExpressionQuery get query; skir.TypeUse? get targetType; skir.ExpressionType get result; bool get sourceIsReference;
/// Create a copy of CheckedQueryCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedQueryCallCopyWith<CheckedQueryCall> get copyWith => _$CheckedQueryCallCopyWithImpl<CheckedQueryCall>(this as CheckedQueryCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CheckedQueryCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedQueryCall&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.sourceIsReference, _this.sourceIsReference) || other.sourceIsReference == _this.sourceIsReference));
}


@override
int get hashCode {
  final _this = this as CheckedQueryCall;
  return Object.hash(runtimeType,_this.query,_this.targetType,_this.result,_this.sourceIsReference);
}

@override
String toString() {
  final _this = this as CheckedQueryCall;
  return 'CheckedQueryCall(query: ${_this.query}, targetType: ${_this.targetType}, result: ${_this.result}, sourceIsReference: ${_this.sourceIsReference})';
}


}

/// @nodoc
abstract mixin class $CheckedQueryCallCopyWith<$Res>  {
  factory $CheckedQueryCallCopyWith(CheckedQueryCall value, $Res Function(CheckedQueryCall) _then) = _$CheckedQueryCallCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionQuery query, skir.TypeUse? targetType, skir.ExpressionType result, bool sourceIsReference
});




}
/// @nodoc
class _$CheckedQueryCallCopyWithImpl<$Res>
    implements $CheckedQueryCallCopyWith<$Res> {
  _$CheckedQueryCallCopyWithImpl(this._self, this._then);

  final CheckedQueryCall _self;
  final $Res Function(CheckedQueryCall) _then;

/// Create a copy of CheckedQueryCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? targetType = freezed,Object? result = null,Object? sourceIsReference = null,}) {
  return _then(CheckedQueryCall(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as skir.ExpressionQuery,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.ExpressionType,sourceIsReference: null == sourceIsReference ? _self.sourceIsReference : sourceIsReference // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckedQueryCall].
extension CheckedQueryCallPatterns on CheckedQueryCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckedQueryCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckedQueryCall value)  $default,){
final _that = this;
switch (_that) {
case _CheckedQueryCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckedQueryCall value)?  $default,){
final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ExpressionQuery query,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
return $default(_that.query,_that.targetType,_that.result,_that.sourceIsReference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ExpressionQuery query,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)  $default,) {final _that = this;
switch (_that) {
case _CheckedQueryCall():
return $default(_that.query,_that.targetType,_that.result,_that.sourceIsReference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ExpressionQuery query,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)?  $default,) {final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
return $default(_that.query,_that.targetType,_that.result,_that.sourceIsReference);case _:
  return null;

}
}

}

/// @nodoc


class _CheckedQueryCall implements CheckedQueryCall {
  const _CheckedQueryCall({required this.query, required this.targetType, required this.result, required this.sourceIsReference});
  

@override final  skir.ExpressionQuery query;
@override final  skir.TypeUse? targetType;
@override final  skir.ExpressionType result;
@override final  bool sourceIsReference;

/// Create a copy of CheckedQueryCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckedQueryCallCopyWith<_CheckedQueryCall> get copyWith => __$CheckedQueryCallCopyWithImpl<_CheckedQueryCall>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckedQueryCall&&(identical(other.query, query) || other.query == query)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.result, result) || other.result == result)&&(identical(other.sourceIsReference, sourceIsReference) || other.sourceIsReference == sourceIsReference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,targetType,result,sourceIsReference);
}

@override
String toString() {
    return 'CheckedQueryCall(query: $query, targetType: $targetType, result: $result, sourceIsReference: $sourceIsReference)';
}


}

/// @nodoc
abstract mixin class _$CheckedQueryCallCopyWith<$Res> implements $CheckedQueryCallCopyWith<$Res> {
  factory _$CheckedQueryCallCopyWith(_CheckedQueryCall value, $Res Function(_CheckedQueryCall) _then) = __$CheckedQueryCallCopyWithImpl;
@override @useResult
$Res call({
 skir.ExpressionQuery query, skir.TypeUse? targetType, skir.ExpressionType result, bool sourceIsReference
});




}
/// @nodoc
class __$CheckedQueryCallCopyWithImpl<$Res>
    implements _$CheckedQueryCallCopyWith<$Res> {
  __$CheckedQueryCallCopyWithImpl(this._self, this._then);

  final _CheckedQueryCall _self;
  final $Res Function(_CheckedQueryCall) _then;

/// Create a copy of CheckedQueryCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? targetType = freezed,Object? result = null,Object? sourceIsReference = null,}) {
  return _then(_CheckedQueryCall(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as skir.ExpressionQuery,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.ExpressionType,sourceIsReference: null == sourceIsReference ? _self.sourceIsReference : sourceIsReference // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CheckedExpressionProgram {

 skir.ExpressionNode get body; skir.ExpressionType get result; Map<ExpressionOccurrence, CheckedQueryCall> get queries;
/// Create a copy of CheckedExpressionProgram
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedExpressionProgramCopyWith<CheckedExpressionProgram> get copyWith => _$CheckedExpressionProgramCopyWithImpl<CheckedExpressionProgram>(this as CheckedExpressionProgram, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CheckedExpressionProgram;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedExpressionProgram&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.result, _this.result) || other.result == _this.result)&&const DeepCollectionEquality().equals(other.queries, _this.queries));
}


@override
int get hashCode {
  final _this = this as CheckedExpressionProgram;
  return Object.hash(runtimeType,_this.body,_this.result,const DeepCollectionEquality().hash(_this.queries));
}

@override
String toString() {
  final _this = this as CheckedExpressionProgram;
  return 'CheckedExpressionProgram(body: ${_this.body}, result: ${_this.result}, queries: ${_this.queries})';
}


}

/// @nodoc
abstract mixin class $CheckedExpressionProgramCopyWith<$Res>  {
  factory $CheckedExpressionProgramCopyWith(CheckedExpressionProgram value, $Res Function(CheckedExpressionProgram) _then) = _$CheckedExpressionProgramCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionNode body, skir.ExpressionType result, Map<ExpressionOccurrence, CheckedQueryCall> queries
});




}
/// @nodoc
class _$CheckedExpressionProgramCopyWithImpl<$Res>
    implements $CheckedExpressionProgramCopyWith<$Res> {
  _$CheckedExpressionProgramCopyWithImpl(this._self, this._then);

  final CheckedExpressionProgram _self;
  final $Res Function(CheckedExpressionProgram) _then;

/// Create a copy of CheckedExpressionProgram
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? result = null,Object? queries = null,}) {
  return _then(CheckedExpressionProgram(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.ExpressionType,queries: null == queries ? _self.queries : queries // ignore: cast_nullable_to_non_nullable
as Map<ExpressionOccurrence, CheckedQueryCall>,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckedExpressionProgram].
extension CheckedExpressionProgramPatterns on CheckedExpressionProgram {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckedExpressionProgram value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckedExpressionProgram() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckedExpressionProgram value)  $default,){
final _that = this;
switch (_that) {
case _CheckedExpressionProgram():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckedExpressionProgram value)?  $default,){
final _that = this;
switch (_that) {
case _CheckedExpressionProgram() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ExpressionNode body,  skir.ExpressionType result,  Map<ExpressionOccurrence, CheckedQueryCall> queries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckedExpressionProgram() when $default != null:
return $default(_that.body,_that.result,_that.queries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ExpressionNode body,  skir.ExpressionType result,  Map<ExpressionOccurrence, CheckedQueryCall> queries)  $default,) {final _that = this;
switch (_that) {
case _CheckedExpressionProgram():
return $default(_that.body,_that.result,_that.queries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ExpressionNode body,  skir.ExpressionType result,  Map<ExpressionOccurrence, CheckedQueryCall> queries)?  $default,) {final _that = this;
switch (_that) {
case _CheckedExpressionProgram() when $default != null:
return $default(_that.body,_that.result,_that.queries);case _:
  return null;

}
}

}

/// @nodoc


class _CheckedExpressionProgram implements CheckedExpressionProgram {
  const _CheckedExpressionProgram({required this.body, required this.result, required  Map<ExpressionOccurrence, CheckedQueryCall> queries}): _queries = queries;
  

@override final  skir.ExpressionNode body;
@override final  skir.ExpressionType result;
 final  Map<ExpressionOccurrence, CheckedQueryCall> _queries;
@override Map<ExpressionOccurrence, CheckedQueryCall> get queries {
  if (_queries is EqualUnmodifiableMapView) return _queries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_queries);
}


/// Create a copy of CheckedExpressionProgram
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckedExpressionProgramCopyWith<_CheckedExpressionProgram> get copyWith => __$CheckedExpressionProgramCopyWithImpl<_CheckedExpressionProgram>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckedExpressionProgram&&(identical(other.body, body) || other.body == body)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other.queries, _queries));
}


@override
int get hashCode {
    return Object.hash(runtimeType,body,result,const DeepCollectionEquality().hash(_queries));
}

@override
String toString() {
    return 'CheckedExpressionProgram(body: $body, result: $result, queries: $queries)';
}


}

/// @nodoc
abstract mixin class _$CheckedExpressionProgramCopyWith<$Res> implements $CheckedExpressionProgramCopyWith<$Res> {
  factory _$CheckedExpressionProgramCopyWith(_CheckedExpressionProgram value, $Res Function(_CheckedExpressionProgram) _then) = __$CheckedExpressionProgramCopyWithImpl;
@override @useResult
$Res call({
 skir.ExpressionNode body, skir.ExpressionType result, Map<ExpressionOccurrence, CheckedQueryCall> queries
});




}
/// @nodoc
class __$CheckedExpressionProgramCopyWithImpl<$Res>
    implements _$CheckedExpressionProgramCopyWith<$Res> {
  __$CheckedExpressionProgramCopyWithImpl(this._self, this._then);

  final _CheckedExpressionProgram _self;
  final $Res Function(_CheckedExpressionProgram) _then;

/// Create a copy of CheckedExpressionProgram
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? result = null,Object? queries = null,}) {
  return _then(_CheckedExpressionProgram(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as skir.ExpressionType,queries: null == queries ? _self._queries : queries // ignore: cast_nullable_to_non_nullable
as Map<ExpressionOccurrence, CheckedQueryCall>,
  ));
}


}

/// @nodoc
mixin _$CheckedExpressionResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedExpressionResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CheckedExpressionResult()';
}


}

/// @nodoc
class $CheckedExpressionResultCopyWith<$Res>  {
$CheckedExpressionResultCopyWith(CheckedExpressionResult _, $Res Function(CheckedExpressionResult) __);
}


/// Adds pattern-matching-related methods to [CheckedExpressionResult].
extension CheckedExpressionResultPatterns on CheckedExpressionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CheckedExpressionReady value)?  ready,TResult Function( CheckedExpressionInvalid value)?  invalid,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CheckedExpressionReady() when ready != null:
return ready(_that);case CheckedExpressionInvalid() when invalid != null:
return invalid(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CheckedExpressionReady value)  ready,required TResult Function( CheckedExpressionInvalid value)  invalid,}){
final _that = this;
switch (_that) {
case CheckedExpressionReady():
return ready(_that);case CheckedExpressionInvalid():
return invalid(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CheckedExpressionReady value)?  ready,TResult? Function( CheckedExpressionInvalid value)?  invalid,}){
final _that = this;
switch (_that) {
case CheckedExpressionReady() when ready != null:
return ready(_that);case CheckedExpressionInvalid() when invalid != null:
return invalid(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CheckedExpressionProgram program)?  ready,TResult Function( String code,  String message)?  invalid,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CheckedExpressionReady() when ready != null:
return ready(_that.program);case CheckedExpressionInvalid() when invalid != null:
return invalid(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CheckedExpressionProgram program)  ready,required TResult Function( String code,  String message)  invalid,}) {final _that = this;
switch (_that) {
case CheckedExpressionReady():
return ready(_that.program);case CheckedExpressionInvalid():
return invalid(_that.code,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CheckedExpressionProgram program)?  ready,TResult? Function( String code,  String message)?  invalid,}) {final _that = this;
switch (_that) {
case CheckedExpressionReady() when ready != null:
return ready(_that.program);case CheckedExpressionInvalid() when invalid != null:
return invalid(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class CheckedExpressionReady implements CheckedExpressionResult {
  const CheckedExpressionReady(this.program);
  

 final  CheckedExpressionProgram program;

/// Create a copy of CheckedExpressionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedExpressionReadyCopyWith<CheckedExpressionReady> get copyWith => _$CheckedExpressionReadyCopyWithImpl<CheckedExpressionReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedExpressionReady&&(identical(other.program, program) || other.program == program));
}


@override
int get hashCode {
    return Object.hash(runtimeType,program);
}

@override
String toString() {
    return 'CheckedExpressionResult.ready(program: $program)';
}


}

/// @nodoc
abstract mixin class $CheckedExpressionReadyCopyWith<$Res> implements $CheckedExpressionResultCopyWith<$Res> {
  factory $CheckedExpressionReadyCopyWith(CheckedExpressionReady value, $Res Function(CheckedExpressionReady) _then) = _$CheckedExpressionReadyCopyWithImpl;
@useResult
$Res call({
 CheckedExpressionProgram program
});


$CheckedExpressionProgramCopyWith<$Res> get program;

}
/// @nodoc
class _$CheckedExpressionReadyCopyWithImpl<$Res>
    implements $CheckedExpressionReadyCopyWith<$Res> {
  _$CheckedExpressionReadyCopyWithImpl(this._self, this._then);

  final CheckedExpressionReady _self;
  final $Res Function(CheckedExpressionReady) _then;

/// Create a copy of CheckedExpressionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? program = null,}) {
  return _then(CheckedExpressionReady(
null == program ? _self.program : program // ignore: cast_nullable_to_non_nullable
as CheckedExpressionProgram,
  ));
}

/// Create a copy of CheckedExpressionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckedExpressionProgramCopyWith<$Res> get program {
  
  return $CheckedExpressionProgramCopyWith<$Res>(_self.program, (value) {
    return _then(_self.copyWith(program: value));
  });
}
}

/// @nodoc


class CheckedExpressionInvalid implements CheckedExpressionResult {
  const CheckedExpressionInvalid({required this.code, required this.message});
  

 final  String code;
 final  String message;

/// Create a copy of CheckedExpressionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedExpressionInvalidCopyWith<CheckedExpressionInvalid> get copyWith => _$CheckedExpressionInvalidCopyWithImpl<CheckedExpressionInvalid>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedExpressionInvalid&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,message);
}

@override
String toString() {
    return 'CheckedExpressionResult.invalid(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $CheckedExpressionInvalidCopyWith<$Res> implements $CheckedExpressionResultCopyWith<$Res> {
  factory $CheckedExpressionInvalidCopyWith(CheckedExpressionInvalid value, $Res Function(CheckedExpressionInvalid) _then) = _$CheckedExpressionInvalidCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$CheckedExpressionInvalidCopyWithImpl<$Res>
    implements $CheckedExpressionInvalidCopyWith<$Res> {
  _$CheckedExpressionInvalidCopyWithImpl(this._self, this._then);

  final CheckedExpressionInvalid _self;
  final $Res Function(CheckedExpressionInvalid) _then;

/// Create a copy of CheckedExpressionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(CheckedExpressionInvalid(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ExpressionProgramKey {

 skir.ExpressionNode get body; Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> get lexicalTypes;
/// Create a copy of _ExpressionProgramKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionProgramKeyCopyWith<_ExpressionProgramKey> get copyWith => __$ExpressionProgramKeyCopyWithImpl<_ExpressionProgramKey>(this as _ExpressionProgramKey, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _ExpressionProgramKey;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionProgramKey&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.lexicalTypes, _this.lexicalTypes));
}


@override
int get hashCode {
  final _this = this as _ExpressionProgramKey;
  return Object.hash(runtimeType,_this.body,const DeepCollectionEquality().hash(_this.lexicalTypes));
}

@override
String toString() {
  final _this = this as _ExpressionProgramKey;
  return '_ExpressionProgramKey(body: ${_this.body}, lexicalTypes: ${_this.lexicalTypes})';
}


}

/// @nodoc
abstract mixin class _$ExpressionProgramKeyCopyWith<$Res>  {
  factory _$ExpressionProgramKeyCopyWith(_ExpressionProgramKey value, $Res Function(_ExpressionProgramKey) _then) = __$ExpressionProgramKeyCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionNode body, Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes
});




}
/// @nodoc
class __$ExpressionProgramKeyCopyWithImpl<$Res>
    implements _$ExpressionProgramKeyCopyWith<$Res> {
  __$ExpressionProgramKeyCopyWithImpl(this._self, this._then);

  final _ExpressionProgramKey _self;
  final $Res Function(_ExpressionProgramKey) _then;

/// Create a copy of _ExpressionProgramKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? lexicalTypes = null,}) {
  return _then(_ExpressionProgramKey(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,lexicalTypes: null == lexicalTypes ? _self.lexicalTypes : lexicalTypes // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>,
  ));
}

}


/// Adds pattern-matching-related methods to [_ExpressionProgramKey].
extension _ExpressionProgramKeyPatterns on _ExpressionProgramKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __ExpressionProgramKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __ExpressionProgramKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __ExpressionProgramKey value)  $default,){
final _that = this;
switch (_that) {
case __ExpressionProgramKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __ExpressionProgramKey value)?  $default,){
final _that = this;
switch (_that) {
case __ExpressionProgramKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ExpressionNode body,  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __ExpressionProgramKey() when $default != null:
return $default(_that.body,_that.lexicalTypes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ExpressionNode body,  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes)  $default,) {final _that = this;
switch (_that) {
case __ExpressionProgramKey():
return $default(_that.body,_that.lexicalTypes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ExpressionNode body,  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes)?  $default,) {final _that = this;
switch (_that) {
case __ExpressionProgramKey() when $default != null:
return $default(_that.body,_that.lexicalTypes);case _:
  return null;

}
}

}

/// @nodoc


class __ExpressionProgramKey implements _ExpressionProgramKey {
  const __ExpressionProgramKey({required this.body, required  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes}): _lexicalTypes = lexicalTypes;
  

@override final  skir.ExpressionNode body;
 final  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> _lexicalTypes;
@override Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> get lexicalTypes {
  if (_lexicalTypes is EqualUnmodifiableMapView) return _lexicalTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lexicalTypes);
}


/// Create a copy of _ExpressionProgramKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_ExpressionProgramKeyCopyWith<__ExpressionProgramKey> get copyWith => __$_ExpressionProgramKeyCopyWithImpl<__ExpressionProgramKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __ExpressionProgramKey&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.lexicalTypes, _lexicalTypes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,body,const DeepCollectionEquality().hash(_lexicalTypes));
}

@override
String toString() {
    return '_ExpressionProgramKey(body: $body, lexicalTypes: $lexicalTypes)';
}


}

/// @nodoc
abstract mixin class _$_ExpressionProgramKeyCopyWith<$Res> implements _$ExpressionProgramKeyCopyWith<$Res> {
  factory _$_ExpressionProgramKeyCopyWith(__ExpressionProgramKey value, $Res Function(__ExpressionProgramKey) _then) = __$_ExpressionProgramKeyCopyWithImpl;
@override @useResult
$Res call({
 skir.ExpressionNode body, Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> lexicalTypes
});




}
/// @nodoc
class __$_ExpressionProgramKeyCopyWithImpl<$Res>
    implements _$_ExpressionProgramKeyCopyWith<$Res> {
  __$_ExpressionProgramKeyCopyWithImpl(this._self, this._then);

  final __ExpressionProgramKey _self;
  final $Res Function(__ExpressionProgramKey) _then;

/// Create a copy of _ExpressionProgramKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? lexicalTypes = null,}) {
  return _then(__ExpressionProgramKey(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,lexicalTypes: null == lexicalTypes ? _self._lexicalTypes : lexicalTypes // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>,
  ));
}


}

/// @nodoc
mixin _$PortableExpressionReadSource {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionReadSource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableExpressionReadSource()';
}


}

/// @nodoc
class $PortableExpressionReadSourceCopyWith<$Res>  {
$PortableExpressionReadSourceCopyWith(PortableExpressionReadSource _, $Res Function(PortableExpressionReadSource) __);
}


/// Adds pattern-matching-related methods to [PortableExpressionReadSource].
extension PortableExpressionReadSourcePatterns on PortableExpressionReadSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InputReadSource value)?  input,TResult Function( LocalReadSource value)?  local,TResult Function( QueryReadSource value)?  query,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InputReadSource() when input != null:
return input(_that);case LocalReadSource() when local != null:
return local(_that);case QueryReadSource() when query != null:
return query(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InputReadSource value)  input,required TResult Function( LocalReadSource value)  local,required TResult Function( QueryReadSource value)  query,}){
final _that = this;
switch (_that) {
case InputReadSource():
return input(_that);case LocalReadSource():
return local(_that);case QueryReadSource():
return query(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InputReadSource value)?  input,TResult? Function( LocalReadSource value)?  local,TResult? Function( QueryReadSource value)?  query,}){
final _that = this;
switch (_that) {
case InputReadSource() when input != null:
return input(_that);case LocalReadSource() when local != null:
return local(_that);case QueryReadSource() when query != null:
return query(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ExpressionBindingId binding)?  input,TResult Function( int depth,  int slot)?  local,TResult Function( ExpressionOccurrence occurrence)?  query,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InputReadSource() when input != null:
return input(_that.binding);case LocalReadSource() when local != null:
return local(_that.depth,_that.slot);case QueryReadSource() when query != null:
return query(_that.occurrence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ExpressionBindingId binding)  input,required TResult Function( int depth,  int slot)  local,required TResult Function( ExpressionOccurrence occurrence)  query,}) {final _that = this;
switch (_that) {
case InputReadSource():
return input(_that.binding);case LocalReadSource():
return local(_that.depth,_that.slot);case QueryReadSource():
return query(_that.occurrence);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ExpressionBindingId binding)?  input,TResult? Function( int depth,  int slot)?  local,TResult? Function( ExpressionOccurrence occurrence)?  query,}) {final _that = this;
switch (_that) {
case InputReadSource() when input != null:
return input(_that.binding);case LocalReadSource() when local != null:
return local(_that.depth,_that.slot);case QueryReadSource() when query != null:
return query(_that.occurrence);case _:
  return null;

}
}

}

/// @nodoc


class InputReadSource implements PortableExpressionReadSource {
  const InputReadSource(this.binding);
  

 final  skir.ExpressionBindingId binding;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputReadSourceCopyWith<InputReadSource> get copyWith => _$InputReadSourceCopyWithImpl<InputReadSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InputReadSource&&(identical(other.binding, binding) || other.binding == binding));
}


@override
int get hashCode {
    return Object.hash(runtimeType,binding);
}

@override
String toString() {
    return 'PortableExpressionReadSource.input(binding: $binding)';
}


}

/// @nodoc
abstract mixin class $InputReadSourceCopyWith<$Res> implements $PortableExpressionReadSourceCopyWith<$Res> {
  factory $InputReadSourceCopyWith(InputReadSource value, $Res Function(InputReadSource) _then) = _$InputReadSourceCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionBindingId binding
});




}
/// @nodoc
class _$InputReadSourceCopyWithImpl<$Res>
    implements $InputReadSourceCopyWith<$Res> {
  _$InputReadSourceCopyWithImpl(this._self, this._then);

  final InputReadSource _self;
  final $Res Function(InputReadSource) _then;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,}) {
  return _then(InputReadSource(
null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as skir.ExpressionBindingId,
  ));
}


}

/// @nodoc


class LocalReadSource implements PortableExpressionReadSource {
  const LocalReadSource(this.depth, this.slot);
  

 final  int depth;
 final  int slot;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalReadSourceCopyWith<LocalReadSource> get copyWith => _$LocalReadSourceCopyWithImpl<LocalReadSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalReadSource&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,depth,slot);
}

@override
String toString() {
    return 'PortableExpressionReadSource.local(depth: $depth, slot: $slot)';
}


}

/// @nodoc
abstract mixin class $LocalReadSourceCopyWith<$Res> implements $PortableExpressionReadSourceCopyWith<$Res> {
  factory $LocalReadSourceCopyWith(LocalReadSource value, $Res Function(LocalReadSource) _then) = _$LocalReadSourceCopyWithImpl;
@useResult
$Res call({
 int depth, int slot
});




}
/// @nodoc
class _$LocalReadSourceCopyWithImpl<$Res>
    implements $LocalReadSourceCopyWith<$Res> {
  _$LocalReadSourceCopyWithImpl(this._self, this._then);

  final LocalReadSource _self;
  final $Res Function(LocalReadSource) _then;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? depth = null,Object? slot = null,}) {
  return _then(LocalReadSource(
null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class QueryReadSource implements PortableExpressionReadSource {
  const QueryReadSource(this.occurrence);
  

 final  ExpressionOccurrence occurrence;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryReadSourceCopyWith<QueryReadSource> get copyWith => _$QueryReadSourceCopyWithImpl<QueryReadSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryReadSource&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,occurrence);
}

@override
String toString() {
    return 'PortableExpressionReadSource.query(occurrence: $occurrence)';
}


}

/// @nodoc
abstract mixin class $QueryReadSourceCopyWith<$Res> implements $PortableExpressionReadSourceCopyWith<$Res> {
  factory $QueryReadSourceCopyWith(QueryReadSource value, $Res Function(QueryReadSource) _then) = _$QueryReadSourceCopyWithImpl;
@useResult
$Res call({
 ExpressionOccurrence occurrence
});


$ExpressionOccurrenceCopyWith<$Res> get occurrence;

}
/// @nodoc
class _$QueryReadSourceCopyWithImpl<$Res>
    implements $QueryReadSourceCopyWith<$Res> {
  _$QueryReadSourceCopyWithImpl(this._self, this._then);

  final QueryReadSource _self;
  final $Res Function(QueryReadSource) _then;

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? occurrence = null,}) {
  return _then(QueryReadSource(
null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as ExpressionOccurrence,
  ));
}

/// Create a copy of PortableExpressionReadSource
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionOccurrenceCopyWith<$Res> get occurrence {
  
  return $ExpressionOccurrenceCopyWith<$Res>(_self.occurrence, (value) {
    return _then(_self.copyWith(occurrence: value));
  });
}
}

/// @nodoc
mixin _$PortableExpressionRead {

 PortableExpressionReadSource get source; skir.ValuePath get path; skir.ValueLocation? get location;
/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExpressionReadCopyWith<PortableExpressionRead> get copyWith => _$PortableExpressionReadCopyWithImpl<PortableExpressionRead>(this as PortableExpressionRead, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableExpressionRead;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionRead&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.location, _this.location) || other.location == _this.location));
}


@override
int get hashCode {
  final _this = this as PortableExpressionRead;
  return Object.hash(runtimeType,_this.source,_this.path,_this.location);
}

@override
String toString() {
  final _this = this as PortableExpressionRead;
  return 'PortableExpressionRead(source: ${_this.source}, path: ${_this.path}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $PortableExpressionReadCopyWith<$Res>  {
  factory $PortableExpressionReadCopyWith(PortableExpressionRead value, $Res Function(PortableExpressionRead) _then) = _$PortableExpressionReadCopyWithImpl;
@useResult
$Res call({
 PortableExpressionReadSource source, skir.ValuePath path, skir.ValueLocation? location
});


$PortableExpressionReadSourceCopyWith<$Res> get source;

}
/// @nodoc
class _$PortableExpressionReadCopyWithImpl<$Res>
    implements $PortableExpressionReadCopyWith<$Res> {
  _$PortableExpressionReadCopyWithImpl(this._self, this._then);

  final PortableExpressionRead _self;
  final $Res Function(PortableExpressionRead) _then;

/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? path = null,Object? location = freezed,}) {
  return _then(PortableExpressionRead(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PortableExpressionReadSource,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}
/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableExpressionReadSourceCopyWith<$Res> get source {
  
  return $PortableExpressionReadSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableExpressionRead].
extension PortableExpressionReadPatterns on PortableExpressionRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableExpressionRead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableExpressionRead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableExpressionRead value)  $default,){
final _that = this;
switch (_that) {
case _PortableExpressionRead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableExpressionRead value)?  $default,){
final _that = this;
switch (_that) {
case _PortableExpressionRead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableExpressionReadSource source,  skir.ValuePath path,  skir.ValueLocation? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableExpressionRead() when $default != null:
return $default(_that.source,_that.path,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableExpressionReadSource source,  skir.ValuePath path,  skir.ValueLocation? location)  $default,) {final _that = this;
switch (_that) {
case _PortableExpressionRead():
return $default(_that.source,_that.path,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableExpressionReadSource source,  skir.ValuePath path,  skir.ValueLocation? location)?  $default,) {final _that = this;
switch (_that) {
case _PortableExpressionRead() when $default != null:
return $default(_that.source,_that.path,_that.location);case _:
  return null;

}
}

}

/// @nodoc


class _PortableExpressionRead extends PortableExpressionRead {
  const _PortableExpressionRead({required this.source, required this.path, this.location}): super._();
  

@override final  PortableExpressionReadSource source;
@override final  skir.ValuePath path;
@override final  skir.ValueLocation? location;

/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableExpressionReadCopyWith<_PortableExpressionRead> get copyWith => __$PortableExpressionReadCopyWithImpl<_PortableExpressionRead>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableExpressionRead&&(identical(other.source, source) || other.source == source)&&(identical(other.path, path) || other.path == path)&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,path,location);
}

@override
String toString() {
    return 'PortableExpressionRead(source: $source, path: $path, location: $location)';
}


}

/// @nodoc
abstract mixin class _$PortableExpressionReadCopyWith<$Res> implements $PortableExpressionReadCopyWith<$Res> {
  factory _$PortableExpressionReadCopyWith(_PortableExpressionRead value, $Res Function(_PortableExpressionRead) _then) = __$PortableExpressionReadCopyWithImpl;
@override @useResult
$Res call({
 PortableExpressionReadSource source, skir.ValuePath path, skir.ValueLocation? location
});


@override $PortableExpressionReadSourceCopyWith<$Res> get source;

}
/// @nodoc
class __$PortableExpressionReadCopyWithImpl<$Res>
    implements _$PortableExpressionReadCopyWith<$Res> {
  __$PortableExpressionReadCopyWithImpl(this._self, this._then);

  final _PortableExpressionRead _self;
  final $Res Function(_PortableExpressionRead) _then;

/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? path = null,Object? location = freezed,}) {
  return _then(_PortableExpressionRead(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PortableExpressionReadSource,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}

/// Create a copy of PortableExpressionRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableExpressionReadSourceCopyWith<$Res> get source {
  
  return $PortableExpressionReadSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc
mixin _$ExpressionProblem {

 String get code;
/// Create a copy of ExpressionProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpressionProblemCopyWith<ExpressionProblem> get copyWith => _$ExpressionProblemCopyWithImpl<ExpressionProblem>(this as ExpressionProblem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExpressionProblem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpressionProblem&&(identical(other.code, _this.code) || other.code == _this.code));
}


@override
int get hashCode {
  final _this = this as ExpressionProblem;
  return Object.hash(runtimeType,_this.code);
}

@override
String toString() {
  final _this = this as ExpressionProblem;
  return 'ExpressionProblem(code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $ExpressionProblemCopyWith<$Res>  {
  factory $ExpressionProblemCopyWith(ExpressionProblem value, $Res Function(ExpressionProblem) _then) = _$ExpressionProblemCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$ExpressionProblemCopyWithImpl<$Res>
    implements $ExpressionProblemCopyWith<$Res> {
  _$ExpressionProblemCopyWithImpl(this._self, this._then);

  final ExpressionProblem _self;
  final $Res Function(ExpressionProblem) _then;

/// Create a copy of ExpressionProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(ExpressionProblem(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpressionProblem].
extension ExpressionProblemPatterns on ExpressionProblem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpressionProblem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpressionProblem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpressionProblem value)  $default,){
final _that = this;
switch (_that) {
case _ExpressionProblem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpressionProblem value)?  $default,){
final _that = this;
switch (_that) {
case _ExpressionProblem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpressionProblem() when $default != null:
return $default(_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code)  $default,) {final _that = this;
switch (_that) {
case _ExpressionProblem():
return $default(_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code)?  $default,) {final _that = this;
switch (_that) {
case _ExpressionProblem() when $default != null:
return $default(_that.code);case _:
  return null;

}
}

}

/// @nodoc


class _ExpressionProblem implements ExpressionProblem {
  const _ExpressionProblem(this.code);
  

@override final  String code;

/// Create a copy of ExpressionProblem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionProblemCopyWith<_ExpressionProblem> get copyWith => __$ExpressionProblemCopyWithImpl<_ExpressionProblem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionProblem&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code);
}

@override
String toString() {
    return 'ExpressionProblem(code: $code)';
}


}

/// @nodoc
abstract mixin class _$ExpressionProblemCopyWith<$Res> implements $ExpressionProblemCopyWith<$Res> {
  factory _$ExpressionProblemCopyWith(_ExpressionProblem value, $Res Function(_ExpressionProblem) _then) = __$ExpressionProblemCopyWithImpl;
@override @useResult
$Res call({
 String code
});




}
/// @nodoc
class __$ExpressionProblemCopyWithImpl<$Res>
    implements _$ExpressionProblemCopyWith<$Res> {
  __$ExpressionProblemCopyWithImpl(this._self, this._then);

  final _ExpressionProblem _self;
  final $Res Function(_ExpressionProblem) _then;

/// Create a copy of ExpressionProblem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(_ExpressionProblem(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ExpressionProjection {

 skir.ExpressionNode get root; skir.ValuePath get suffix; int get descents;
/// Create a copy of ExpressionProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpressionProjectionCopyWith<ExpressionProjection> get copyWith => _$ExpressionProjectionCopyWithImpl<ExpressionProjection>(this as ExpressionProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExpressionProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpressionProjection&&(identical(other.root, _this.root) || other.root == _this.root)&&(identical(other.suffix, _this.suffix) || other.suffix == _this.suffix)&&(identical(other.descents, _this.descents) || other.descents == _this.descents));
}


@override
int get hashCode {
  final _this = this as ExpressionProjection;
  return Object.hash(runtimeType,_this.root,_this.suffix,_this.descents);
}

@override
String toString() {
  final _this = this as ExpressionProjection;
  return 'ExpressionProjection(root: ${_this.root}, suffix: ${_this.suffix}, descents: ${_this.descents})';
}


}

/// @nodoc
abstract mixin class $ExpressionProjectionCopyWith<$Res>  {
  factory $ExpressionProjectionCopyWith(ExpressionProjection value, $Res Function(ExpressionProjection) _then) = _$ExpressionProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionNode root, skir.ValuePath suffix, int descents
});




}
/// @nodoc
class _$ExpressionProjectionCopyWithImpl<$Res>
    implements $ExpressionProjectionCopyWith<$Res> {
  _$ExpressionProjectionCopyWithImpl(this._self, this._then);

  final ExpressionProjection _self;
  final $Res Function(ExpressionProjection) _then;

/// Create a copy of ExpressionProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? suffix = null,Object? descents = null,}) {
  return _then(ExpressionProjection(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,descents: null == descents ? _self.descents : descents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpressionProjection].
extension ExpressionProjectionPatterns on ExpressionProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpressionProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpressionProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpressionProjection value)  $default,){
final _that = this;
switch (_that) {
case _ExpressionProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpressionProjection value)?  $default,){
final _that = this;
switch (_that) {
case _ExpressionProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ExpressionNode root,  skir.ValuePath suffix,  int descents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpressionProjection() when $default != null:
return $default(_that.root,_that.suffix,_that.descents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ExpressionNode root,  skir.ValuePath suffix,  int descents)  $default,) {final _that = this;
switch (_that) {
case _ExpressionProjection():
return $default(_that.root,_that.suffix,_that.descents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ExpressionNode root,  skir.ValuePath suffix,  int descents)?  $default,) {final _that = this;
switch (_that) {
case _ExpressionProjection() when $default != null:
return $default(_that.root,_that.suffix,_that.descents);case _:
  return null;

}
}

}

/// @nodoc


class _ExpressionProjection implements ExpressionProjection {
  const _ExpressionProjection({required this.root, required this.suffix, required this.descents});
  

@override final  skir.ExpressionNode root;
@override final  skir.ValuePath suffix;
@override final  int descents;

/// Create a copy of ExpressionProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionProjectionCopyWith<_ExpressionProjection> get copyWith => __$ExpressionProjectionCopyWithImpl<_ExpressionProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionProjection&&(identical(other.root, root) || other.root == root)&&(identical(other.suffix, suffix) || other.suffix == suffix)&&(identical(other.descents, descents) || other.descents == descents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,root,suffix,descents);
}

@override
String toString() {
    return 'ExpressionProjection(root: $root, suffix: $suffix, descents: $descents)';
}


}

/// @nodoc
abstract mixin class _$ExpressionProjectionCopyWith<$Res> implements $ExpressionProjectionCopyWith<$Res> {
  factory _$ExpressionProjectionCopyWith(_ExpressionProjection value, $Res Function(_ExpressionProjection) _then) = __$ExpressionProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ExpressionNode root, skir.ValuePath suffix, int descents
});




}
/// @nodoc
class __$ExpressionProjectionCopyWithImpl<$Res>
    implements _$ExpressionProjectionCopyWith<$Res> {
  __$ExpressionProjectionCopyWithImpl(this._self, this._then);

  final _ExpressionProjection _self;
  final $Res Function(_ExpressionProjection) _then;

/// Create a copy of ExpressionProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? suffix = null,Object? descents = null,}) {
  return _then(_ExpressionProjection(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as skir.ExpressionNode,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,descents: null == descents ? _self.descents : descents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
