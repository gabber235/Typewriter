// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_search_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationSearchResultPayload {

 DataValue get selectedValue; PresentationNode get presentation; ExpressionContext get expressions; String get providerKey;
/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationSearchResultPayloadCopyWith<PresentationSearchResultPayload> get copyWith => _$PresentationSearchResultPayloadCopyWithImpl<PresentationSearchResultPayload>(this as PresentationSearchResultPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationSearchResultPayload&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.expressions, expressions) || other.expressions == expressions)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey));
}


@override
int get hashCode => Object.hash(runtimeType,selectedValue,presentation,expressions,providerKey);

@override
String toString() {
  return 'PresentationSearchResultPayload(selectedValue: $selectedValue, presentation: $presentation, expressions: $expressions, providerKey: $providerKey)';
}


}

/// @nodoc
abstract mixin class $PresentationSearchResultPayloadCopyWith<$Res>  {
  factory $PresentationSearchResultPayloadCopyWith(PresentationSearchResultPayload value, $Res Function(PresentationSearchResultPayload) _then) = _$PresentationSearchResultPayloadCopyWithImpl;
@useResult
$Res call({
 DataValue selectedValue, PresentationNode presentation, ExpressionContext expressions, String providerKey
});


$DataValueCopyWith<$Res> get selectedValue;$PresentationNodeCopyWith<$Res> get presentation;$ExpressionContextCopyWith<$Res> get expressions;

}
/// @nodoc
class _$PresentationSearchResultPayloadCopyWithImpl<$Res>
    implements $PresentationSearchResultPayloadCopyWith<$Res> {
  _$PresentationSearchResultPayloadCopyWithImpl(this._self, this._then);

  final PresentationSearchResultPayload _self;
  final $Res Function(PresentationSearchResultPayload) _then;

/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedValue = null,Object? presentation = null,Object? expressions = null,Object? providerKey = null,}) {
  return _then(_self.copyWith(
selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as DataValue,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,expressions: null == expressions ? _self.expressions : expressions // ignore: cast_nullable_to_non_nullable
as ExpressionContext,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get selectedValue {
  
  return $DataValueCopyWith<$Res>(_self.selectedValue, (value) {
    return _then(_self.copyWith(selectedValue: value));
  });
}/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionContextCopyWith<$Res> get expressions {
  
  return $ExpressionContextCopyWith<$Res>(_self.expressions, (value) {
    return _then(_self.copyWith(expressions: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationSearchResultPayload].
extension PresentationSearchResultPayloadPatterns on PresentationSearchResultPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationSearchResultPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationSearchResultPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationSearchResultPayload value)  $default,){
final _that = this;
switch (_that) {
case _PresentationSearchResultPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationSearchResultPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationSearchResultPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataValue selectedValue,  PresentationNode presentation,  ExpressionContext expressions,  String providerKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationSearchResultPayload() when $default != null:
return $default(_that.selectedValue,_that.presentation,_that.expressions,_that.providerKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataValue selectedValue,  PresentationNode presentation,  ExpressionContext expressions,  String providerKey)  $default,) {final _that = this;
switch (_that) {
case _PresentationSearchResultPayload():
return $default(_that.selectedValue,_that.presentation,_that.expressions,_that.providerKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataValue selectedValue,  PresentationNode presentation,  ExpressionContext expressions,  String providerKey)?  $default,) {final _that = this;
switch (_that) {
case _PresentationSearchResultPayload() when $default != null:
return $default(_that.selectedValue,_that.presentation,_that.expressions,_that.providerKey);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationSearchResultPayload implements PresentationSearchResultPayload {
  const _PresentationSearchResultPayload({required this.selectedValue, required this.presentation, required this.expressions, required this.providerKey});
  

@override final  DataValue selectedValue;
@override final  PresentationNode presentation;
@override final  ExpressionContext expressions;
@override final  String providerKey;

/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationSearchResultPayloadCopyWith<_PresentationSearchResultPayload> get copyWith => __$PresentationSearchResultPayloadCopyWithImpl<_PresentationSearchResultPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationSearchResultPayload&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.expressions, expressions) || other.expressions == expressions)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey));
}


@override
int get hashCode => Object.hash(runtimeType,selectedValue,presentation,expressions,providerKey);

@override
String toString() {
  return 'PresentationSearchResultPayload(selectedValue: $selectedValue, presentation: $presentation, expressions: $expressions, providerKey: $providerKey)';
}


}

/// @nodoc
abstract mixin class _$PresentationSearchResultPayloadCopyWith<$Res> implements $PresentationSearchResultPayloadCopyWith<$Res> {
  factory _$PresentationSearchResultPayloadCopyWith(_PresentationSearchResultPayload value, $Res Function(_PresentationSearchResultPayload) _then) = __$PresentationSearchResultPayloadCopyWithImpl;
@override @useResult
$Res call({
 DataValue selectedValue, PresentationNode presentation, ExpressionContext expressions, String providerKey
});


@override $DataValueCopyWith<$Res> get selectedValue;@override $PresentationNodeCopyWith<$Res> get presentation;@override $ExpressionContextCopyWith<$Res> get expressions;

}
/// @nodoc
class __$PresentationSearchResultPayloadCopyWithImpl<$Res>
    implements _$PresentationSearchResultPayloadCopyWith<$Res> {
  __$PresentationSearchResultPayloadCopyWithImpl(this._self, this._then);

  final _PresentationSearchResultPayload _self;
  final $Res Function(_PresentationSearchResultPayload) _then;

/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedValue = null,Object? presentation = null,Object? expressions = null,Object? providerKey = null,}) {
  return _then(_PresentationSearchResultPayload(
selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as DataValue,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,expressions: null == expressions ? _self.expressions : expressions // ignore: cast_nullable_to_non_nullable
as ExpressionContext,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get selectedValue {
  
  return $DataValueCopyWith<$Res>(_self.selectedValue, (value) {
    return _then(_self.copyWith(selectedValue: value));
  });
}/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}/// Create a copy of PresentationSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionContextCopyWith<$Res> get expressions {
  
  return $ExpressionContextCopyWith<$Res>(_self.expressions, (value) {
    return _then(_self.copyWith(expressions: value));
  });
}
}

/// @nodoc
mixin _$PresentationSearchSelectionEvent {

 SearchResult get result; String get historyNamespace;
/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationSearchSelectionEventCopyWith<PresentationSearchSelectionEvent> get copyWith => _$PresentationSearchSelectionEventCopyWithImpl<PresentationSearchSelectionEvent>(this as PresentationSearchSelectionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationSearchSelectionEvent&&(identical(other.result, result) || other.result == result)&&(identical(other.historyNamespace, historyNamespace) || other.historyNamespace == historyNamespace));
}


@override
int get hashCode => Object.hash(runtimeType,result,historyNamespace);

@override
String toString() {
  return 'PresentationSearchSelectionEvent(result: $result, historyNamespace: $historyNamespace)';
}


}

/// @nodoc
abstract mixin class $PresentationSearchSelectionEventCopyWith<$Res>  {
  factory $PresentationSearchSelectionEventCopyWith(PresentationSearchSelectionEvent value, $Res Function(PresentationSearchSelectionEvent) _then) = _$PresentationSearchSelectionEventCopyWithImpl;
@useResult
$Res call({
 SearchResult result, String historyNamespace
});


$SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$PresentationSearchSelectionEventCopyWithImpl<$Res>
    implements $PresentationSearchSelectionEventCopyWith<$Res> {
  _$PresentationSearchSelectionEventCopyWithImpl(this._self, this._then);

  final PresentationSearchSelectionEvent _self;
  final $Res Function(PresentationSearchSelectionEvent) _then;

/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? result = null,Object? historyNamespace = null,}) {
  return _then(_self.copyWith(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,historyNamespace: null == historyNamespace ? _self.historyNamespace : historyNamespace // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationSearchSelectionEvent].
extension PresentationSearchSelectionEventPatterns on PresentationSearchSelectionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationSearchSelectionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationSearchSelectionEvent value)  $default,){
final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationSearchSelectionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchResult result,  String historyNamespace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent() when $default != null:
return $default(_that.result,_that.historyNamespace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchResult result,  String historyNamespace)  $default,) {final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent():
return $default(_that.result,_that.historyNamespace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchResult result,  String historyNamespace)?  $default,) {final _that = this;
switch (_that) {
case _PresentationSearchSelectionEvent() when $default != null:
return $default(_that.result,_that.historyNamespace);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationSearchSelectionEvent implements PresentationSearchSelectionEvent {
  const _PresentationSearchSelectionEvent({required this.result, required this.historyNamespace});
  

@override final  SearchResult result;
@override final  String historyNamespace;

/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationSearchSelectionEventCopyWith<_PresentationSearchSelectionEvent> get copyWith => __$PresentationSearchSelectionEventCopyWithImpl<_PresentationSearchSelectionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationSearchSelectionEvent&&(identical(other.result, result) || other.result == result)&&(identical(other.historyNamespace, historyNamespace) || other.historyNamespace == historyNamespace));
}


@override
int get hashCode => Object.hash(runtimeType,result,historyNamespace);

@override
String toString() {
  return 'PresentationSearchSelectionEvent(result: $result, historyNamespace: $historyNamespace)';
}


}

/// @nodoc
abstract mixin class _$PresentationSearchSelectionEventCopyWith<$Res> implements $PresentationSearchSelectionEventCopyWith<$Res> {
  factory _$PresentationSearchSelectionEventCopyWith(_PresentationSearchSelectionEvent value, $Res Function(_PresentationSearchSelectionEvent) _then) = __$PresentationSearchSelectionEventCopyWithImpl;
@override @useResult
$Res call({
 SearchResult result, String historyNamespace
});


@override $SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class __$PresentationSearchSelectionEventCopyWithImpl<$Res>
    implements _$PresentationSearchSelectionEventCopyWith<$Res> {
  __$PresentationSearchSelectionEventCopyWithImpl(this._self, this._then);

  final _PresentationSearchSelectionEvent _self;
  final $Res Function(_PresentationSearchSelectionEvent) _then;

/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,Object? historyNamespace = null,}) {
  return _then(_PresentationSearchSelectionEvent(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,historyNamespace: null == historyNamespace ? _self.historyNamespace : historyNamespace // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PresentationSearchSelectionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
