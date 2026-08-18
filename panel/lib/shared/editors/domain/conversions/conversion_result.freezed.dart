// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversion_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversionResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversionResult()';
}


}

/// @nodoc
class $ConversionResultCopyWith<$Res>  {
$ConversionResultCopyWith(ConversionResult _, $Res Function(ConversionResult) __);
}


/// Adds pattern-matching-related methods to [ConversionResult].
extension ConversionResultPatterns on ConversionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConversionSuccess value)?  success,TResult Function( ConversionFailure value)?  failure,TResult Function( ConversionUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConversionSuccess() when success != null:
return success(_that);case ConversionFailure() when failure != null:
return failure(_that);case ConversionUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConversionSuccess value)  success,required TResult Function( ConversionFailure value)  failure,required TResult Function( ConversionUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case ConversionSuccess():
return success(_that);case ConversionFailure():
return failure(_that);case ConversionUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConversionSuccess value)?  success,TResult? Function( ConversionFailure value)?  failure,TResult? Function( ConversionUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case ConversionSuccess() when success != null:
return success(_that);case ConversionFailure() when failure != null:
return failure(_that);case ConversionUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DataValue value)?  success,TResult Function( List<TypeDiagnostic> diagnostics)?  failure,TResult Function( List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConversionSuccess() when success != null:
return success(_that.value);case ConversionFailure() when failure != null:
return failure(_that.diagnostics);case ConversionUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DataValue value)  success,required TResult Function( List<TypeDiagnostic> diagnostics)  failure,required TResult Function( List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case ConversionSuccess():
return success(_that.value);case ConversionFailure():
return failure(_that.diagnostics);case ConversionUnavailable():
return unavailable(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DataValue value)?  success,TResult? Function( List<TypeDiagnostic> diagnostics)?  failure,TResult? Function( List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case ConversionSuccess() when success != null:
return success(_that.value);case ConversionFailure() when failure != null:
return failure(_that.diagnostics);case ConversionUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class ConversionSuccess implements ConversionResult {
  const ConversionSuccess(this.value);
  

 final  DataValue value;

/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionSuccessCopyWith<ConversionSuccess> get copyWith => _$ConversionSuccessCopyWithImpl<ConversionSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionSuccess&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ConversionResult.success(value: $value)';
}


}

/// @nodoc
abstract mixin class $ConversionSuccessCopyWith<$Res> implements $ConversionResultCopyWith<$Res> {
  factory $ConversionSuccessCopyWith(ConversionSuccess value, $Res Function(ConversionSuccess) _then) = _$ConversionSuccessCopyWithImpl;
@useResult
$Res call({
 DataValue value
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$ConversionSuccessCopyWithImpl<$Res>
    implements $ConversionSuccessCopyWith<$Res> {
  _$ConversionSuccessCopyWithImpl(this._self, this._then);

  final ConversionSuccess _self;
  final $Res Function(ConversionSuccess) _then;

/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ConversionSuccess(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of ConversionResult
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


class ConversionFailure implements ConversionResult {
   ConversionFailure(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionFailureCopyWith<ConversionFailure> get copyWith => _$ConversionFailureCopyWithImpl<ConversionFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionFailure&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'ConversionResult.failure(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $ConversionFailureCopyWith<$Res> implements $ConversionResultCopyWith<$Res> {
  factory $ConversionFailureCopyWith(ConversionFailure value, $Res Function(ConversionFailure) _then) = _$ConversionFailureCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$ConversionFailureCopyWithImpl<$Res>
    implements $ConversionFailureCopyWith<$Res> {
  _$ConversionFailureCopyWithImpl(this._self, this._then);

  final ConversionFailure _self;
  final $Res Function(ConversionFailure) _then;

/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(ConversionFailure(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class ConversionUnavailable implements ConversionResult {
   ConversionUnavailable(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionUnavailableCopyWith<ConversionUnavailable> get copyWith => _$ConversionUnavailableCopyWithImpl<ConversionUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'ConversionResult.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $ConversionUnavailableCopyWith<$Res> implements $ConversionResultCopyWith<$Res> {
  factory $ConversionUnavailableCopyWith(ConversionUnavailable value, $Res Function(ConversionUnavailable) _then) = _$ConversionUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$ConversionUnavailableCopyWithImpl<$Res>
    implements $ConversionUnavailableCopyWith<$Res> {
  _$ConversionUnavailableCopyWithImpl(this._self, this._then);

  final ConversionUnavailable _self;
  final $Res Function(ConversionUnavailable) _then;

/// Create a copy of ConversionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(ConversionUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
