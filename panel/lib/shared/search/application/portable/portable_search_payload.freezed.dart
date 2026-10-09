// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_search_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableSearchPayload {

 skir.DataValue get selectedValue; String get providerPath; SearchQueryContext get query;
/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableSearchPayloadCopyWith<PortableSearchPayload> get copyWith => _$PortableSearchPayloadCopyWithImpl<PortableSearchPayload>(this as PortableSearchPayload, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableSearchPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableSearchPayload&&(identical(other.selectedValue, _this.selectedValue) || other.selectedValue == _this.selectedValue)&&(identical(other.providerPath, _this.providerPath) || other.providerPath == _this.providerPath)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as PortableSearchPayload;
  return Object.hash(runtimeType,_this.selectedValue,_this.providerPath,_this.query);
}

@override
String toString() {
  final _this = this as PortableSearchPayload;
  return 'PortableSearchPayload(selectedValue: ${_this.selectedValue}, providerPath: ${_this.providerPath}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $PortableSearchPayloadCopyWith<$Res>  {
  factory $PortableSearchPayloadCopyWith(PortableSearchPayload value, $Res Function(PortableSearchPayload) _then) = _$PortableSearchPayloadCopyWithImpl;
@useResult
$Res call({
 skir.DataValue selectedValue, String providerPath, SearchQueryContext query
});


$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$PortableSearchPayloadCopyWithImpl<$Res>
    implements $PortableSearchPayloadCopyWith<$Res> {
  _$PortableSearchPayloadCopyWithImpl(this._self, this._then);

  final PortableSearchPayload _self;
  final $Res Function(PortableSearchPayload) _then;

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedValue = null,Object? providerPath = null,Object? query = null,}) {
  return _then(_self.copyWith(
selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,providerPath: null == providerPath ? _self.providerPath : providerPath // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}
/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {

  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableSearchPayload].
extension PortableSearchPayloadPatterns on PortableSearchPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableMappedSearchPayload value)?  mapped,TResult Function( PortableCustomSearchPayload value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableMappedSearchPayload() when mapped != null:
return mapped(_that);case PortableCustomSearchPayload() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableMappedSearchPayload value)  mapped,required TResult Function( PortableCustomSearchPayload value)  custom,}){
final _that = this;
switch (_that) {
case PortableMappedSearchPayload():
return mapped(_that);case PortableCustomSearchPayload():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableMappedSearchPayload value)?  mapped,TResult? Function( PortableCustomSearchPayload value)?  custom,}){
final _that = this;
switch (_that) {
case PortableMappedSearchPayload() when mapped != null:
return mapped(_that);case PortableCustomSearchPayload() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.DataValue sourceValue,  skir.DataValue selectedValue,  skir.SearchResultMapping mapping,  String providerPath,  String distinctKey,  SearchQueryContext query)?  mapped,TResult Function( skir.DataValue selectedValue,  String providerPath,  SearchQueryContext query)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableMappedSearchPayload() when mapped != null:
return mapped(_that.sourceValue,_that.selectedValue,_that.mapping,_that.providerPath,_that.distinctKey,_that.query);case PortableCustomSearchPayload() when custom != null:
return custom(_that.selectedValue,_that.providerPath,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.DataValue sourceValue,  skir.DataValue selectedValue,  skir.SearchResultMapping mapping,  String providerPath,  String distinctKey,  SearchQueryContext query)  mapped,required TResult Function( skir.DataValue selectedValue,  String providerPath,  SearchQueryContext query)  custom,}) {final _that = this;
switch (_that) {
case PortableMappedSearchPayload():
return mapped(_that.sourceValue,_that.selectedValue,_that.mapping,_that.providerPath,_that.distinctKey,_that.query);case PortableCustomSearchPayload():
return custom(_that.selectedValue,_that.providerPath,_that.query);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.DataValue sourceValue,  skir.DataValue selectedValue,  skir.SearchResultMapping mapping,  String providerPath,  String distinctKey,  SearchQueryContext query)?  mapped,TResult? Function( skir.DataValue selectedValue,  String providerPath,  SearchQueryContext query)?  custom,}) {final _that = this;
switch (_that) {
case PortableMappedSearchPayload() when mapped != null:
return mapped(_that.sourceValue,_that.selectedValue,_that.mapping,_that.providerPath,_that.distinctKey,_that.query);case PortableCustomSearchPayload() when custom != null:
return custom(_that.selectedValue,_that.providerPath,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class PortableMappedSearchPayload implements PortableSearchPayload {
  const PortableMappedSearchPayload({required this.sourceValue, required this.selectedValue, required this.mapping, required this.providerPath, required this.distinctKey, required this.query});


 final  skir.DataValue sourceValue;
@override final  skir.DataValue selectedValue;
 final  skir.SearchResultMapping mapping;
@override final  String providerPath;
 final  String distinctKey;
@override final  SearchQueryContext query;

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableMappedSearchPayloadCopyWith<PortableMappedSearchPayload> get copyWith => _$PortableMappedSearchPayloadCopyWithImpl<PortableMappedSearchPayload>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableMappedSearchPayload&&(identical(other.sourceValue, sourceValue) || other.sourceValue == sourceValue)&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.providerPath, providerPath) || other.providerPath == providerPath)&&(identical(other.distinctKey, distinctKey) || other.distinctKey == distinctKey)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sourceValue,selectedValue,mapping,providerPath,distinctKey,query);
}

@override
String toString() {
    return 'PortableSearchPayload.mapped(sourceValue: $sourceValue, selectedValue: $selectedValue, mapping: $mapping, providerPath: $providerPath, distinctKey: $distinctKey, query: $query)';
}


}

/// @nodoc
abstract mixin class $PortableMappedSearchPayloadCopyWith<$Res> implements $PortableSearchPayloadCopyWith<$Res> {
  factory $PortableMappedSearchPayloadCopyWith(PortableMappedSearchPayload value, $Res Function(PortableMappedSearchPayload) _then) = _$PortableMappedSearchPayloadCopyWithImpl;
@override @useResult
$Res call({
 skir.DataValue sourceValue, skir.DataValue selectedValue, skir.SearchResultMapping mapping, String providerPath, String distinctKey, SearchQueryContext query
});


@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$PortableMappedSearchPayloadCopyWithImpl<$Res>
    implements $PortableMappedSearchPayloadCopyWith<$Res> {
  _$PortableMappedSearchPayloadCopyWithImpl(this._self, this._then);

  final PortableMappedSearchPayload _self;
  final $Res Function(PortableMappedSearchPayload) _then;

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceValue = null,Object? selectedValue = null,Object? mapping = null,Object? providerPath = null,Object? distinctKey = null,Object? query = null,}) {
  return _then(PortableMappedSearchPayload(
sourceValue: null == sourceValue ? _self.sourceValue : sourceValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as skir.SearchResultMapping,providerPath: null == providerPath ? _self.providerPath : providerPath // ignore: cast_nullable_to_non_nullable
as String,distinctKey: null == distinctKey ? _self.distinctKey : distinctKey // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {

  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc


class PortableCustomSearchPayload implements PortableSearchPayload {
  const PortableCustomSearchPayload({required this.selectedValue, required this.providerPath, required this.query});


@override final  skir.DataValue selectedValue;
@override final  String providerPath;
@override final  SearchQueryContext query;

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableCustomSearchPayloadCopyWith<PortableCustomSearchPayload> get copyWith => _$PortableCustomSearchPayloadCopyWithImpl<PortableCustomSearchPayload>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableCustomSearchPayload&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.providerPath, providerPath) || other.providerPath == providerPath)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selectedValue,providerPath,query);
}

@override
String toString() {
    return 'PortableSearchPayload.custom(selectedValue: $selectedValue, providerPath: $providerPath, query: $query)';
}


}

/// @nodoc
abstract mixin class $PortableCustomSearchPayloadCopyWith<$Res> implements $PortableSearchPayloadCopyWith<$Res> {
  factory $PortableCustomSearchPayloadCopyWith(PortableCustomSearchPayload value, $Res Function(PortableCustomSearchPayload) _then) = _$PortableCustomSearchPayloadCopyWithImpl;
@override @useResult
$Res call({
 skir.DataValue selectedValue, String providerPath, SearchQueryContext query
});


@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$PortableCustomSearchPayloadCopyWithImpl<$Res>
    implements $PortableCustomSearchPayloadCopyWith<$Res> {
  _$PortableCustomSearchPayloadCopyWithImpl(this._self, this._then);

  final PortableCustomSearchPayload _self;
  final $Res Function(PortableCustomSearchPayload) _then;

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedValue = null,Object? providerPath = null,Object? query = null,}) {
  return _then(PortableCustomSearchPayload(
selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,providerPath: null == providerPath ? _self.providerPath : providerPath // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of PortableSearchPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {

  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc
mixin _$PortableSearchSelectionResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableSearchSelectionResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableSearchSelectionResult()';
}


}

/// @nodoc
class $PortableSearchSelectionResultCopyWith<$Res>  {
$PortableSearchSelectionResultCopyWith(PortableSearchSelectionResult _, $Res Function(PortableSearchSelectionResult) __);
}


/// Adds pattern-matching-related methods to [PortableSearchSelectionResult].
extension PortableSearchSelectionResultPatterns on PortableSearchSelectionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableSearchSelectionApplied value)?  applied,TResult Function( PortableSearchSelectionRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableSearchSelectionApplied() when applied != null:
return applied(_that);case PortableSearchSelectionRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableSearchSelectionApplied value)  applied,required TResult Function( PortableSearchSelectionRejected value)  rejected,}){
final _that = this;
switch (_that) {
case PortableSearchSelectionApplied():
return applied(_that);case PortableSearchSelectionRejected():
return rejected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableSearchSelectionApplied value)?  applied,TResult? Function( PortableSearchSelectionRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case PortableSearchSelectionApplied() when applied != null:
return applied(_that);case PortableSearchSelectionRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool added)?  applied,TResult Function( String message)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableSearchSelectionApplied() when applied != null:
return applied(_that.added);case PortableSearchSelectionRejected() when rejected != null:
return rejected(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool added)  applied,required TResult Function( String message)  rejected,}) {final _that = this;
switch (_that) {
case PortableSearchSelectionApplied():
return applied(_that.added);case PortableSearchSelectionRejected():
return rejected(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool added)?  applied,TResult? Function( String message)?  rejected,}) {final _that = this;
switch (_that) {
case PortableSearchSelectionApplied() when applied != null:
return applied(_that.added);case PortableSearchSelectionRejected() when rejected != null:
return rejected(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PortableSearchSelectionApplied implements PortableSearchSelectionResult {
  const PortableSearchSelectionApplied({required this.added});


 final  bool added;

/// Create a copy of PortableSearchSelectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableSearchSelectionAppliedCopyWith<PortableSearchSelectionApplied> get copyWith => _$PortableSearchSelectionAppliedCopyWithImpl<PortableSearchSelectionApplied>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableSearchSelectionApplied&&(identical(other.added, added) || other.added == added));
}


@override
int get hashCode {
    return Object.hash(runtimeType,added);
}

@override
String toString() {
    return 'PortableSearchSelectionResult.applied(added: $added)';
}


}

/// @nodoc
abstract mixin class $PortableSearchSelectionAppliedCopyWith<$Res> implements $PortableSearchSelectionResultCopyWith<$Res> {
  factory $PortableSearchSelectionAppliedCopyWith(PortableSearchSelectionApplied value, $Res Function(PortableSearchSelectionApplied) _then) = _$PortableSearchSelectionAppliedCopyWithImpl;
@useResult
$Res call({
 bool added
});




}
/// @nodoc
class _$PortableSearchSelectionAppliedCopyWithImpl<$Res>
    implements $PortableSearchSelectionAppliedCopyWith<$Res> {
  _$PortableSearchSelectionAppliedCopyWithImpl(this._self, this._then);

  final PortableSearchSelectionApplied _self;
  final $Res Function(PortableSearchSelectionApplied) _then;

/// Create a copy of PortableSearchSelectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? added = null,}) {
  return _then(PortableSearchSelectionApplied(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class PortableSearchSelectionRejected implements PortableSearchSelectionResult {
  const PortableSearchSelectionRejected(this.message);


 final  String message;

/// Create a copy of PortableSearchSelectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableSearchSelectionRejectedCopyWith<PortableSearchSelectionRejected> get copyWith => _$PortableSearchSelectionRejectedCopyWithImpl<PortableSearchSelectionRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableSearchSelectionRejected&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'PortableSearchSelectionResult.rejected(message: $message)';
}


}

/// @nodoc
abstract mixin class $PortableSearchSelectionRejectedCopyWith<$Res> implements $PortableSearchSelectionResultCopyWith<$Res> {
  factory $PortableSearchSelectionRejectedCopyWith(PortableSearchSelectionRejected value, $Res Function(PortableSearchSelectionRejected) _then) = _$PortableSearchSelectionRejectedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PortableSearchSelectionRejectedCopyWithImpl<$Res>
    implements $PortableSearchSelectionRejectedCopyWith<$Res> {
  _$PortableSearchSelectionRejectedCopyWithImpl(this._self, this._then);

  final PortableSearchSelectionRejected _self;
  final $Res Function(PortableSearchSelectionRejected) _then;

/// Create a copy of PortableSearchSelectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PortableSearchSelectionRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
