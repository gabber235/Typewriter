// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'materialization_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConcreteTypeInitializationResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcreteTypeInitializationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ConcreteTypeInitializationResult()';
}


}

/// @nodoc
class $ConcreteTypeInitializationResultCopyWith<$Res>  {
$ConcreteTypeInitializationResultCopyWith(ConcreteTypeInitializationResult _, $Res Function(ConcreteTypeInitializationResult) __);
}


/// Adds pattern-matching-related methods to [ConcreteTypeInitializationResult].
extension ConcreteTypeInitializationResultPatterns on ConcreteTypeInitializationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConcreteTypeInitialized value)?  initialized,TResult Function( ConcreteTypeNeedsInput value)?  needsInput,TResult Function( ConcreteTypeInitializationRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConcreteTypeInitialized() when initialized != null:
return initialized(_that);case ConcreteTypeNeedsInput() when needsInput != null:
return needsInput(_that);case ConcreteTypeInitializationRejected() when rejected != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConcreteTypeInitialized value)  initialized,required TResult Function( ConcreteTypeNeedsInput value)  needsInput,required TResult Function( ConcreteTypeInitializationRejected value)  rejected,}){
final _that = this;
switch (_that) {
case ConcreteTypeInitialized():
return initialized(_that);case ConcreteTypeNeedsInput():
return needsInput(_that);case ConcreteTypeInitializationRejected():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConcreteTypeInitialized value)?  initialized,TResult? Function( ConcreteTypeNeedsInput value)?  needsInput,TResult? Function( ConcreteTypeInitializationRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case ConcreteTypeInitialized() when initialized != null:
return initialized(_that);case ConcreteTypeNeedsInput() when needsInput != null:
return needsInput(_that);case ConcreteTypeInitializationRejected() when rejected != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedValueEnvelope value)?  initialized,TResult Function( DataValue? suppliedValue)?  needsInput,TResult Function( List<TypeDiagnostic> diagnostics)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConcreteTypeInitialized() when initialized != null:
return initialized(_that.value);case ConcreteTypeNeedsInput() when needsInput != null:
return needsInput(_that.suppliedValue);case ConcreteTypeInitializationRejected() when rejected != null:
return rejected(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedValueEnvelope value)  initialized,required TResult Function( DataValue? suppliedValue)  needsInput,required TResult Function( List<TypeDiagnostic> diagnostics)  rejected,}) {final _that = this;
switch (_that) {
case ConcreteTypeInitialized():
return initialized(_that.value);case ConcreteTypeNeedsInput():
return needsInput(_that.suppliedValue);case ConcreteTypeInitializationRejected():
return rejected(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedValueEnvelope value)?  initialized,TResult? Function( DataValue? suppliedValue)?  needsInput,TResult? Function( List<TypeDiagnostic> diagnostics)?  rejected,}) {final _that = this;
switch (_that) {
case ConcreteTypeInitialized() when initialized != null:
return initialized(_that.value);case ConcreteTypeNeedsInput() when needsInput != null:
return needsInput(_that.suppliedValue);case ConcreteTypeInitializationRejected() when rejected != null:
return rejected(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class ConcreteTypeInitialized implements ConcreteTypeInitializationResult {
  const ConcreteTypeInitialized(this.value);


 final  TypedValueEnvelope value;

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcreteTypeInitializedCopyWith<ConcreteTypeInitialized> get copyWith => _$ConcreteTypeInitializedCopyWithImpl<ConcreteTypeInitialized>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcreteTypeInitialized&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'ConcreteTypeInitializationResult.initialized(value: $value)';
}


}

/// @nodoc
abstract mixin class $ConcreteTypeInitializedCopyWith<$Res> implements $ConcreteTypeInitializationResultCopyWith<$Res> {
  factory $ConcreteTypeInitializedCopyWith(ConcreteTypeInitialized value, $Res Function(ConcreteTypeInitialized) _then) = _$ConcreteTypeInitializedCopyWithImpl;
@useResult
$Res call({
 TypedValueEnvelope value
});


$TypedValueEnvelopeCopyWith<$Res> get value;

}
/// @nodoc
class _$ConcreteTypeInitializedCopyWithImpl<$Res>
    implements $ConcreteTypeInitializedCopyWith<$Res> {
  _$ConcreteTypeInitializedCopyWithImpl(this._self, this._then);

  final ConcreteTypeInitialized _self;
  final $Res Function(ConcreteTypeInitialized) _then;

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ConcreteTypeInitialized(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedValueEnvelope,
  ));
}

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedValueEnvelopeCopyWith<$Res> get value {

  return $TypedValueEnvelopeCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class ConcreteTypeNeedsInput implements ConcreteTypeInitializationResult {
  const ConcreteTypeNeedsInput({this.suppliedValue});


 final  DataValue? suppliedValue;

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcreteTypeNeedsInputCopyWith<ConcreteTypeNeedsInput> get copyWith => _$ConcreteTypeNeedsInputCopyWithImpl<ConcreteTypeNeedsInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcreteTypeNeedsInput&&(identical(other.suppliedValue, suppliedValue) || other.suppliedValue == suppliedValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,suppliedValue);
}

@override
String toString() {
    return 'ConcreteTypeInitializationResult.needsInput(suppliedValue: $suppliedValue)';
}


}

/// @nodoc
abstract mixin class $ConcreteTypeNeedsInputCopyWith<$Res> implements $ConcreteTypeInitializationResultCopyWith<$Res> {
  factory $ConcreteTypeNeedsInputCopyWith(ConcreteTypeNeedsInput value, $Res Function(ConcreteTypeNeedsInput) _then) = _$ConcreteTypeNeedsInputCopyWithImpl;
@useResult
$Res call({
 DataValue? suppliedValue
});


$DataValueCopyWith<$Res>? get suppliedValue;

}
/// @nodoc
class _$ConcreteTypeNeedsInputCopyWithImpl<$Res>
    implements $ConcreteTypeNeedsInputCopyWith<$Res> {
  _$ConcreteTypeNeedsInputCopyWithImpl(this._self, this._then);

  final ConcreteTypeNeedsInput _self;
  final $Res Function(ConcreteTypeNeedsInput) _then;

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? suppliedValue = freezed,}) {
  return _then(ConcreteTypeNeedsInput(
suppliedValue: freezed == suppliedValue ? _self.suppliedValue : suppliedValue // ignore: cast_nullable_to_non_nullable
as DataValue?,
  ));
}

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res>? get suppliedValue {
    if (_self.suppliedValue == null) {
    return null;
  }

  return $DataValueCopyWith<$Res>(_self.suppliedValue!, (value) {
    return _then(_self.copyWith(suppliedValue: value));
  });
}
}

/// @nodoc


class ConcreteTypeInitializationRejected implements ConcreteTypeInitializationResult {
  const ConcreteTypeInitializationRejected( List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;


 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcreteTypeInitializationRejectedCopyWith<ConcreteTypeInitializationRejected> get copyWith => _$ConcreteTypeInitializationRejectedCopyWithImpl<ConcreteTypeInitializationRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcreteTypeInitializationRejected&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'ConcreteTypeInitializationResult.rejected(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $ConcreteTypeInitializationRejectedCopyWith<$Res> implements $ConcreteTypeInitializationResultCopyWith<$Res> {
  factory $ConcreteTypeInitializationRejectedCopyWith(ConcreteTypeInitializationRejected value, $Res Function(ConcreteTypeInitializationRejected) _then) = _$ConcreteTypeInitializationRejectedCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$ConcreteTypeInitializationRejectedCopyWithImpl<$Res>
    implements $ConcreteTypeInitializationRejectedCopyWith<$Res> {
  _$ConcreteTypeInitializationRejectedCopyWithImpl(this._self, this._then);

  final ConcreteTypeInitializationRejected _self;
  final $Res Function(ConcreteTypeInitializationRejected) _then;

/// Create a copy of ConcreteTypeInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(ConcreteTypeInitializationRejected(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
