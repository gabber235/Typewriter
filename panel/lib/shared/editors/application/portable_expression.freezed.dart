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

/// Distinct authored locations whose stored values decided this result,
/// in first read order. Save conflict witnesses are built from exactly
/// these: input projections of located bindings and the resources panel
/// operations read. Lambda locals are never reads.
 List<skir.ValueLocation> get reads;
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
 List<skir.ValueLocation> reads
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
as List<skir.ValueLocation>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.DataValue value,  List<skir.ValueLocation> reads)?  available,TResult Function( List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)?  unavailable,TResult Function( skir.FailureId failure,  String message,  List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that.value,_that.reads);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that.locations,_that.reads);case PortableExpressionFailed() when failed != null:
return failed(_that.failure,_that.message,_that.locations,_that.reads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.DataValue value,  List<skir.ValueLocation> reads)  available,required TResult Function( List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)  unavailable,required TResult Function( skir.FailureId failure,  String message,  List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)  failed,}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable():
return available(_that.value,_that.reads);case PortableExpressionUnavailable():
return unavailable(_that.locations,_that.reads);case PortableExpressionFailed():
return failed(_that.failure,_that.message,_that.locations,_that.reads);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.DataValue value,  List<skir.ValueLocation> reads)?  available,TResult? Function( List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)?  unavailable,TResult? Function( skir.FailureId failure,  String message,  List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads)?  failed,}) {final _that = this;
switch (_that) {
case PortableExpressionAvailable() when available != null:
return available(_that.value,_that.reads);case PortableExpressionUnavailable() when unavailable != null:
return unavailable(_that.locations,_that.reads);case PortableExpressionFailed() when failed != null:
return failed(_that.failure,_that.message,_that.locations,_that.reads);case _:
  return null;

}
}

}

/// @nodoc


class PortableExpressionAvailable implements PortableExpressionResult {
  const PortableExpressionAvailable(this.value,  List<skir.ValueLocation> reads): _reads = reads;
  

 final  skir.DataValue value;
/// Distinct authored locations whose stored values decided this result,
/// in first read order. Save conflict witnesses are built from exactly
/// these: input projections of located bindings and the resources panel
/// operations read. Lambda locals are never reads.
 final  List<skir.ValueLocation> _reads;
/// Distinct authored locations whose stored values decided this result,
/// in first read order. Save conflict witnesses are built from exactly
/// these: input projections of located bindings and the resources panel
/// operations read. Lambda locals are never reads.
@override List<skir.ValueLocation> get reads {
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
 skir.DataValue value, List<skir.ValueLocation> reads
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
as List<skir.ValueLocation>,
  ));
}


}

/// @nodoc


class PortableExpressionUnavailable implements PortableExpressionResult {
  const PortableExpressionUnavailable( List<skir.ValueLocation> locations,  List<skir.ValueLocation> reads): _locations = locations,_reads = reads;
  

/// Authored locations whose missing values block the result. Empty when
/// the missing data has no authored location.
 final  List<skir.ValueLocation> _locations;
/// Authored locations whose missing values block the result. Empty when
/// the missing data has no authored location.
 List<skir.ValueLocation> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

 final  List<skir.ValueLocation> _reads;
@override List<skir.ValueLocation> get reads {
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionUnavailable&&const DeepCollectionEquality().equals(other.locations, _locations)&&const DeepCollectionEquality().equals(other.reads, _reads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_locations),const DeepCollectionEquality().hash(_reads));
}

@override
String toString() {
    return 'PortableExpressionResult.unavailable(locations: $locations, reads: $reads)';
}


}

/// @nodoc
abstract mixin class $PortableExpressionUnavailableCopyWith<$Res> implements $PortableExpressionResultCopyWith<$Res> {
  factory $PortableExpressionUnavailableCopyWith(PortableExpressionUnavailable value, $Res Function(PortableExpressionUnavailable) _then) = _$PortableExpressionUnavailableCopyWithImpl;
@override @useResult
$Res call({
 List<skir.ValueLocation> locations, List<skir.ValueLocation> reads
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
@override @pragma('vm:prefer-inline') $Res call({Object? locations = null,Object? reads = null,}) {
  return _then(PortableExpressionUnavailable(
null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,null == reads ? _self._reads : reads // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,
  ));
}


}

/// @nodoc


class PortableExpressionFailed implements PortableExpressionResult {
  const PortableExpressionFailed(this.failure, this.message, {required  List<skir.ValueLocation> locations, required  List<skir.ValueLocation> reads}): _locations = locations,_reads = reads;
  

/// The declared failure, from operations.yaml.
 final  skir.FailureId failure;
 final  String message;
/// The reads so far plus the located lambda locals in scope, as Kotlin
/// reports them.
 final  List<skir.ValueLocation> _locations;
/// The reads so far plus the located lambda locals in scope, as Kotlin
/// reports them.
 List<skir.ValueLocation> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

 final  List<skir.ValueLocation> _reads;
@override List<skir.ValueLocation> get reads {
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExpressionFailed&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.locations, _locations)&&const DeepCollectionEquality().equals(other.reads, _reads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure,message,const DeepCollectionEquality().hash(_locations),const DeepCollectionEquality().hash(_reads));
}

@override
String toString() {
    return 'PortableExpressionResult.failed(failure: $failure, message: $message, locations: $locations, reads: $reads)';
}


}

/// @nodoc
abstract mixin class $PortableExpressionFailedCopyWith<$Res> implements $PortableExpressionResultCopyWith<$Res> {
  factory $PortableExpressionFailedCopyWith(PortableExpressionFailed value, $Res Function(PortableExpressionFailed) _then) = _$PortableExpressionFailedCopyWithImpl;
@override @useResult
$Res call({
 skir.FailureId failure, String message, List<skir.ValueLocation> locations, List<skir.ValueLocation> reads
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
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? message = null,Object? locations = null,Object? reads = null,}) {
  return _then(PortableExpressionFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as skir.FailureId,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,reads: null == reads ? _self._reads : reads // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,
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




// dart format on
