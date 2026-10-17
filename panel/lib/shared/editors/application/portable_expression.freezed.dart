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

 CanonicalQueryOperation get operation; skir.TypeUse? get targetType; skir.ExpressionType get result; bool get sourceIsReference;
/// Create a copy of CheckedQueryCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedQueryCallCopyWith<CheckedQueryCall> get copyWith => _$CheckedQueryCallCopyWithImpl<CheckedQueryCall>(this as CheckedQueryCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CheckedQueryCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedQueryCall&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.sourceIsReference, _this.sourceIsReference) || other.sourceIsReference == _this.sourceIsReference));
}


@override
int get hashCode {
  final _this = this as CheckedQueryCall;
  return Object.hash(runtimeType,_this.operation,_this.targetType,_this.result,_this.sourceIsReference);
}

@override
String toString() {
  final _this = this as CheckedQueryCall;
  return 'CheckedQueryCall(operation: ${_this.operation}, targetType: ${_this.targetType}, result: ${_this.result}, sourceIsReference: ${_this.sourceIsReference})';
}


}

/// @nodoc
abstract mixin class $CheckedQueryCallCopyWith<$Res>  {
  factory $CheckedQueryCallCopyWith(CheckedQueryCall value, $Res Function(CheckedQueryCall) _then) = _$CheckedQueryCallCopyWithImpl;
@useResult
$Res call({
 CanonicalQueryOperation operation, skir.TypeUse? targetType, skir.ExpressionType result, bool sourceIsReference
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
@pragma('vm:prefer-inline') @override $Res call({Object? operation = null,Object? targetType = freezed,Object? result = null,Object? sourceIsReference = null,}) {
  return _then(CheckedQueryCall(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as CanonicalQueryOperation,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CanonicalQueryOperation operation,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
return $default(_that.operation,_that.targetType,_that.result,_that.sourceIsReference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CanonicalQueryOperation operation,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)  $default,) {final _that = this;
switch (_that) {
case _CheckedQueryCall():
return $default(_that.operation,_that.targetType,_that.result,_that.sourceIsReference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CanonicalQueryOperation operation,  skir.TypeUse? targetType,  skir.ExpressionType result,  bool sourceIsReference)?  $default,) {final _that = this;
switch (_that) {
case _CheckedQueryCall() when $default != null:
return $default(_that.operation,_that.targetType,_that.result,_that.sourceIsReference);case _:
  return null;

}
}

}

/// @nodoc


class _CheckedQueryCall implements CheckedQueryCall {
  const _CheckedQueryCall({required this.operation, required this.targetType, required this.result, required this.sourceIsReference});


@override final  CanonicalQueryOperation operation;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckedQueryCall&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.result, result) || other.result == result)&&(identical(other.sourceIsReference, sourceIsReference) || other.sourceIsReference == sourceIsReference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,operation,targetType,result,sourceIsReference);
}

@override
String toString() {
    return 'CheckedQueryCall(operation: $operation, targetType: $targetType, result: $result, sourceIsReference: $sourceIsReference)';
}


}

/// @nodoc
abstract mixin class _$CheckedQueryCallCopyWith<$Res> implements $CheckedQueryCallCopyWith<$Res> {
  factory _$CheckedQueryCallCopyWith(_CheckedQueryCall value, $Res Function(_CheckedQueryCall) _then) = __$CheckedQueryCallCopyWithImpl;
@override @useResult
$Res call({
 CanonicalQueryOperation operation, skir.TypeUse? targetType, skir.ExpressionType result, bool sourceIsReference
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
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? targetType = freezed,Object? result = null,Object? sourceIsReference = null,}) {
  return _then(_CheckedQueryCall(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as CanonicalQueryOperation,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
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
mixin _$CanonicalLeafProjection {

 skir.ExpressionCall get root; List<String> get fields;
/// Create a copy of CanonicalLeafProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanonicalLeafProjectionCopyWith<CanonicalLeafProjection> get copyWith => _$CanonicalLeafProjectionCopyWithImpl<CanonicalLeafProjection>(this as CanonicalLeafProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CanonicalLeafProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanonicalLeafProjection&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.fields, _this.fields));
}


@override
int get hashCode {
  final _this = this as CanonicalLeafProjection;
  return Object.hash(runtimeType,_this.root,const DeepCollectionEquality().hash(_this.fields));
}

@override
String toString() {
  final _this = this as CanonicalLeafProjection;
  return 'CanonicalLeafProjection(root: ${_this.root}, fields: ${_this.fields})';
}


}

/// @nodoc
abstract mixin class $CanonicalLeafProjectionCopyWith<$Res>  {
  factory $CanonicalLeafProjectionCopyWith(CanonicalLeafProjection value, $Res Function(CanonicalLeafProjection) _then) = _$CanonicalLeafProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionCall root, List<String> fields
});




}
/// @nodoc
class _$CanonicalLeafProjectionCopyWithImpl<$Res>
    implements $CanonicalLeafProjectionCopyWith<$Res> {
  _$CanonicalLeafProjectionCopyWithImpl(this._self, this._then);

  final CanonicalLeafProjection _self;
  final $Res Function(CanonicalLeafProjection) _then;

/// Create a copy of CanonicalLeafProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? fields = null,}) {
  return _then(CanonicalLeafProjection(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as skir.ExpressionCall,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CanonicalLeafProjection].
extension CanonicalLeafProjectionPatterns on CanonicalLeafProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanonicalLeafProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanonicalLeafProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanonicalLeafProjection value)  $default,){
final _that = this;
switch (_that) {
case _CanonicalLeafProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanonicalLeafProjection value)?  $default,){
final _that = this;
switch (_that) {
case _CanonicalLeafProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ExpressionCall root,  List<String> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanonicalLeafProjection() when $default != null:
return $default(_that.root,_that.fields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ExpressionCall root,  List<String> fields)  $default,) {final _that = this;
switch (_that) {
case _CanonicalLeafProjection():
return $default(_that.root,_that.fields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ExpressionCall root,  List<String> fields)?  $default,) {final _that = this;
switch (_that) {
case _CanonicalLeafProjection() when $default != null:
return $default(_that.root,_that.fields);case _:
  return null;

}
}

}

/// @nodoc


class _CanonicalLeafProjection implements CanonicalLeafProjection {
  const _CanonicalLeafProjection({required this.root, required  List<String> fields}): _fields = fields;


@override final  skir.ExpressionCall root;
 final  List<String> _fields;
@override List<String> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of CanonicalLeafProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanonicalLeafProjectionCopyWith<_CanonicalLeafProjection> get copyWith => __$CanonicalLeafProjectionCopyWithImpl<_CanonicalLeafProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanonicalLeafProjection&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.fields, _fields));
}


@override
int get hashCode {
    return Object.hash(runtimeType,root,const DeepCollectionEquality().hash(_fields));
}

@override
String toString() {
    return 'CanonicalLeafProjection(root: $root, fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$CanonicalLeafProjectionCopyWith<$Res> implements $CanonicalLeafProjectionCopyWith<$Res> {
  factory _$CanonicalLeafProjectionCopyWith(_CanonicalLeafProjection value, $Res Function(_CanonicalLeafProjection) _then) = __$CanonicalLeafProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ExpressionCall root, List<String> fields
});




}
/// @nodoc
class __$CanonicalLeafProjectionCopyWithImpl<$Res>
    implements _$CanonicalLeafProjectionCopyWith<$Res> {
  __$CanonicalLeafProjectionCopyWithImpl(this._self, this._then);

  final _CanonicalLeafProjection _self;
  final $Res Function(_CanonicalLeafProjection) _then;

/// Create a copy of CanonicalLeafProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? fields = null,}) {
  return _then(_CanonicalLeafProjection(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as skir.ExpressionCall,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<String>,
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

// dart format on
