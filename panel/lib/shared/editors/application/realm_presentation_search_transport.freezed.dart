// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_presentation_search_transport.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmPresentationSearchRequest {

 String get subscriptionId; RealmActionId get actionId; DataValue get payload; TypeExpression get resultType; SearchQueryContext get query;
/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPresentationSearchRequestCopyWith<RealmPresentationSearchRequest> get copyWith => _$RealmPresentationSearchRequestCopyWithImpl<RealmPresentationSearchRequest>(this as RealmPresentationSearchRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPresentationSearchRequest&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,subscriptionId,actionId,payload,resultType,query);

@override
String toString() {
  return 'RealmPresentationSearchRequest(subscriptionId: $subscriptionId, actionId: $actionId, payload: $payload, resultType: $resultType, query: $query)';
}


}

/// @nodoc
abstract mixin class $RealmPresentationSearchRequestCopyWith<$Res>  {
  factory $RealmPresentationSearchRequestCopyWith(RealmPresentationSearchRequest value, $Res Function(RealmPresentationSearchRequest) _then) = _$RealmPresentationSearchRequestCopyWithImpl;
@useResult
$Res call({
 String subscriptionId, RealmActionId actionId, DataValue payload, TypeExpression resultType, SearchQueryContext query
});


$RealmActionIdCopyWith<$Res> get actionId;$DataValueCopyWith<$Res> get payload;$TypeExpressionCopyWith<$Res> get resultType;$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$RealmPresentationSearchRequestCopyWithImpl<$Res>
    implements $RealmPresentationSearchRequestCopyWith<$Res> {
  _$RealmPresentationSearchRequestCopyWithImpl(this._self, this._then);

  final RealmPresentationSearchRequest _self;
  final $Res Function(RealmPresentationSearchRequest) _then;

/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subscriptionId = null,Object? actionId = null,Object? payload = null,Object? resultType = null,Object? query = null,}) {
  return _then(_self.copyWith(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as RealmActionId,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as DataValue,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as TypeExpression,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}
/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionIdCopyWith<$Res> get actionId {
  
  return $RealmActionIdCopyWith<$Res>(_self.actionId, (value) {
    return _then(_self.copyWith(actionId: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get payload {
  
  return $DataValueCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get resultType {
  
  return $TypeExpressionCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmPresentationSearchRequest].
extension RealmPresentationSearchRequestPatterns on RealmPresentationSearchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPresentationSearchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPresentationSearchRequest value)  $default,){
final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPresentationSearchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subscriptionId,  RealmActionId actionId,  DataValue payload,  TypeExpression resultType,  SearchQueryContext query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest() when $default != null:
return $default(_that.subscriptionId,_that.actionId,_that.payload,_that.resultType,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subscriptionId,  RealmActionId actionId,  DataValue payload,  TypeExpression resultType,  SearchQueryContext query)  $default,) {final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest():
return $default(_that.subscriptionId,_that.actionId,_that.payload,_that.resultType,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subscriptionId,  RealmActionId actionId,  DataValue payload,  TypeExpression resultType,  SearchQueryContext query)?  $default,) {final _that = this;
switch (_that) {
case _RealmPresentationSearchRequest() when $default != null:
return $default(_that.subscriptionId,_that.actionId,_that.payload,_that.resultType,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPresentationSearchRequest implements RealmPresentationSearchRequest {
  const _RealmPresentationSearchRequest({required this.subscriptionId, required this.actionId, required this.payload, required this.resultType, required this.query});
  

@override final  String subscriptionId;
@override final  RealmActionId actionId;
@override final  DataValue payload;
@override final  TypeExpression resultType;
@override final  SearchQueryContext query;

/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPresentationSearchRequestCopyWith<_RealmPresentationSearchRequest> get copyWith => __$RealmPresentationSearchRequestCopyWithImpl<_RealmPresentationSearchRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPresentationSearchRequest&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,subscriptionId,actionId,payload,resultType,query);

@override
String toString() {
  return 'RealmPresentationSearchRequest(subscriptionId: $subscriptionId, actionId: $actionId, payload: $payload, resultType: $resultType, query: $query)';
}


}

/// @nodoc
abstract mixin class _$RealmPresentationSearchRequestCopyWith<$Res> implements $RealmPresentationSearchRequestCopyWith<$Res> {
  factory _$RealmPresentationSearchRequestCopyWith(_RealmPresentationSearchRequest value, $Res Function(_RealmPresentationSearchRequest) _then) = __$RealmPresentationSearchRequestCopyWithImpl;
@override @useResult
$Res call({
 String subscriptionId, RealmActionId actionId, DataValue payload, TypeExpression resultType, SearchQueryContext query
});


@override $RealmActionIdCopyWith<$Res> get actionId;@override $DataValueCopyWith<$Res> get payload;@override $TypeExpressionCopyWith<$Res> get resultType;@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class __$RealmPresentationSearchRequestCopyWithImpl<$Res>
    implements _$RealmPresentationSearchRequestCopyWith<$Res> {
  __$RealmPresentationSearchRequestCopyWithImpl(this._self, this._then);

  final _RealmPresentationSearchRequest _self;
  final $Res Function(_RealmPresentationSearchRequest) _then;

/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscriptionId = null,Object? actionId = null,Object? payload = null,Object? resultType = null,Object? query = null,}) {
  return _then(_RealmPresentationSearchRequest(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as RealmActionId,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as DataValue,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as TypeExpression,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionIdCopyWith<$Res> get actionId {
  
  return $RealmActionIdCopyWith<$Res>(_self.actionId, (value) {
    return _then(_self.copyWith(actionId: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get payload {
  
  return $DataValueCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get resultType {
  
  return $TypeExpressionCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}/// Create a copy of RealmPresentationSearchRequest
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
mixin _$RealmPresentationSearchUpdate {

 String get subscriptionId; List<TypeDiagnostic> get diagnostics;
/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPresentationSearchUpdateCopyWith<RealmPresentationSearchUpdate> get copyWith => _$RealmPresentationSearchUpdateCopyWithImpl<RealmPresentationSearchUpdate>(this as RealmPresentationSearchUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPresentationSearchUpdate&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,subscriptionId,const DeepCollectionEquality().hash(diagnostics));

@override
String toString() {
  return 'RealmPresentationSearchUpdate(subscriptionId: $subscriptionId, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmPresentationSearchUpdateCopyWith<$Res>  {
  factory $RealmPresentationSearchUpdateCopyWith(RealmPresentationSearchUpdate value, $Res Function(RealmPresentationSearchUpdate) _then) = _$RealmPresentationSearchUpdateCopyWithImpl;
@useResult
$Res call({
 String subscriptionId, List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmPresentationSearchUpdateCopyWithImpl<$Res>
    implements $RealmPresentationSearchUpdateCopyWith<$Res> {
  _$RealmPresentationSearchUpdateCopyWithImpl(this._self, this._then);

  final RealmPresentationSearchUpdate _self;
  final $Res Function(RealmPresentationSearchUpdate) _then;

/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subscriptionId = null,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmPresentationSearchUpdate].
extension RealmPresentationSearchUpdatePatterns on RealmPresentationSearchUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmPresentationSearchSnapshotUpdate value)?  snapshot,TResult Function( RealmPresentationSearchUnavailableUpdate value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate() when snapshot != null:
return snapshot(_that);case RealmPresentationSearchUnavailableUpdate() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmPresentationSearchSnapshotUpdate value)  snapshot,required TResult Function( RealmPresentationSearchUnavailableUpdate value)  unavailable,}){
final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate():
return snapshot(_that);case RealmPresentationSearchUnavailableUpdate():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmPresentationSearchSnapshotUpdate value)?  snapshot,TResult? Function( RealmPresentationSearchUnavailableUpdate value)?  unavailable,}){
final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate() when snapshot != null:
return snapshot(_that);case RealmPresentationSearchUnavailableUpdate() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String subscriptionId,  SearchSourceStatus status,  List<DataValue> values,  List<String> guidance,  List<TypeDiagnostic> diagnostics)?  snapshot,TResult Function( String subscriptionId,  List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate() when snapshot != null:
return snapshot(_that.subscriptionId,_that.status,_that.values,_that.guidance,_that.diagnostics);case RealmPresentationSearchUnavailableUpdate() when unavailable != null:
return unavailable(_that.subscriptionId,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String subscriptionId,  SearchSourceStatus status,  List<DataValue> values,  List<String> guidance,  List<TypeDiagnostic> diagnostics)  snapshot,required TResult Function( String subscriptionId,  List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate():
return snapshot(_that.subscriptionId,_that.status,_that.values,_that.guidance,_that.diagnostics);case RealmPresentationSearchUnavailableUpdate():
return unavailable(_that.subscriptionId,_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String subscriptionId,  SearchSourceStatus status,  List<DataValue> values,  List<String> guidance,  List<TypeDiagnostic> diagnostics)?  snapshot,TResult? Function( String subscriptionId,  List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case RealmPresentationSearchSnapshotUpdate() when snapshot != null:
return snapshot(_that.subscriptionId,_that.status,_that.values,_that.guidance,_that.diagnostics);case RealmPresentationSearchUnavailableUpdate() when unavailable != null:
return unavailable(_that.subscriptionId,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class RealmPresentationSearchSnapshotUpdate implements RealmPresentationSearchUpdate {
  const RealmPresentationSearchSnapshotUpdate({required this.subscriptionId, required this.status, required final  List<DataValue> values, final  List<String> guidance = const [], final  List<TypeDiagnostic> diagnostics = const []}): _values = values,_guidance = guidance,_diagnostics = diagnostics;
  

@override final  String subscriptionId;
 final  SearchSourceStatus status;
 final  List<DataValue> _values;
 List<DataValue> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}

 final  List<String> _guidance;
@JsonKey() List<String> get guidance {
  if (_guidance is EqualUnmodifiableListView) return _guidance;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guidance);
}

 final  List<TypeDiagnostic> _diagnostics;
@override@JsonKey() List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPresentationSearchSnapshotUpdateCopyWith<RealmPresentationSearchSnapshotUpdate> get copyWith => _$RealmPresentationSearchSnapshotUpdateCopyWithImpl<RealmPresentationSearchSnapshotUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPresentationSearchSnapshotUpdate&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._values, _values)&&const DeepCollectionEquality().equals(other._guidance, _guidance)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,subscriptionId,status,const DeepCollectionEquality().hash(_values),const DeepCollectionEquality().hash(_guidance),const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'RealmPresentationSearchUpdate.snapshot(subscriptionId: $subscriptionId, status: $status, values: $values, guidance: $guidance, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmPresentationSearchSnapshotUpdateCopyWith<$Res> implements $RealmPresentationSearchUpdateCopyWith<$Res> {
  factory $RealmPresentationSearchSnapshotUpdateCopyWith(RealmPresentationSearchSnapshotUpdate value, $Res Function(RealmPresentationSearchSnapshotUpdate) _then) = _$RealmPresentationSearchSnapshotUpdateCopyWithImpl;
@override @useResult
$Res call({
 String subscriptionId, SearchSourceStatus status, List<DataValue> values, List<String> guidance, List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmPresentationSearchSnapshotUpdateCopyWithImpl<$Res>
    implements $RealmPresentationSearchSnapshotUpdateCopyWith<$Res> {
  _$RealmPresentationSearchSnapshotUpdateCopyWithImpl(this._self, this._then);

  final RealmPresentationSearchSnapshotUpdate _self;
  final $Res Function(RealmPresentationSearchSnapshotUpdate) _then;

/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscriptionId = null,Object? status = null,Object? values = null,Object? guidance = null,Object? diagnostics = null,}) {
  return _then(RealmPresentationSearchSnapshotUpdate(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchSourceStatus,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<DataValue>,guidance: null == guidance ? _self._guidance : guidance // ignore: cast_nullable_to_non_nullable
as List<String>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class RealmPresentationSearchUnavailableUpdate implements RealmPresentationSearchUpdate {
  const RealmPresentationSearchUnavailableUpdate({required this.subscriptionId, required final  List<TypeDiagnostic> diagnostics}): _diagnostics = diagnostics;
  

@override final  String subscriptionId;
 final  List<TypeDiagnostic> _diagnostics;
@override List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPresentationSearchUnavailableUpdateCopyWith<RealmPresentationSearchUnavailableUpdate> get copyWith => _$RealmPresentationSearchUnavailableUpdateCopyWithImpl<RealmPresentationSearchUnavailableUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPresentationSearchUnavailableUpdate&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,subscriptionId,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'RealmPresentationSearchUpdate.unavailable(subscriptionId: $subscriptionId, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmPresentationSearchUnavailableUpdateCopyWith<$Res> implements $RealmPresentationSearchUpdateCopyWith<$Res> {
  factory $RealmPresentationSearchUnavailableUpdateCopyWith(RealmPresentationSearchUnavailableUpdate value, $Res Function(RealmPresentationSearchUnavailableUpdate) _then) = _$RealmPresentationSearchUnavailableUpdateCopyWithImpl;
@override @useResult
$Res call({
 String subscriptionId, List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmPresentationSearchUnavailableUpdateCopyWithImpl<$Res>
    implements $RealmPresentationSearchUnavailableUpdateCopyWith<$Res> {
  _$RealmPresentationSearchUnavailableUpdateCopyWithImpl(this._self, this._then);

  final RealmPresentationSearchUnavailableUpdate _self;
  final $Res Function(RealmPresentationSearchUnavailableUpdate) _then;

/// Create a copy of RealmPresentationSearchUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscriptionId = null,Object? diagnostics = null,}) {
  return _then(RealmPresentationSearchUnavailableUpdate(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
