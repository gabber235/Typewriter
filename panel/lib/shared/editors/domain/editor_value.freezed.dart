// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorValue {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorValue()';
}


}

/// @nodoc
class $EditorValueCopyWith<$Res>  {
$EditorValueCopyWith(EditorValue _, $Res Function(EditorValue) __);
}


/// Adds pattern-matching-related methods to [EditorValue].
extension EditorValuePatterns on EditorValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadingEditorValue value)?  loading,TResult Function( ConflictEditorValue value)?  conflict,TResult Function( InvalidEditorValue value)?  invalid,TResult Function( ReadyEditorValue value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadingEditorValue() when loading != null:
return loading(_that);case ConflictEditorValue() when conflict != null:
return conflict(_that);case InvalidEditorValue() when invalid != null:
return invalid(_that);case ReadyEditorValue() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadingEditorValue value)  loading,required TResult Function( ConflictEditorValue value)  conflict,required TResult Function( InvalidEditorValue value)  invalid,required TResult Function( ReadyEditorValue value)  ready,}){
final _that = this;
switch (_that) {
case LoadingEditorValue():
return loading(_that);case ConflictEditorValue():
return conflict(_that);case InvalidEditorValue():
return invalid(_that);case ReadyEditorValue():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadingEditorValue value)?  loading,TResult? Function( ConflictEditorValue value)?  conflict,TResult? Function( InvalidEditorValue value)?  invalid,TResult? Function( ReadyEditorValue value)?  ready,}){
final _that = this;
switch (_that) {
case LoadingEditorValue() when loading != null:
return loading(_that);case ConflictEditorValue() when conflict != null:
return conflict(_that);case InvalidEditorValue() when invalid != null:
return invalid(_that);case ReadyEditorValue() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  conflict,TResult Function( List<TypeDiagnostic> diagnostics)?  invalid,TResult Function( DataValue value)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadingEditorValue() when loading != null:
return loading();case ConflictEditorValue() when conflict != null:
return conflict();case InvalidEditorValue() when invalid != null:
return invalid(_that.diagnostics);case ReadyEditorValue() when ready != null:
return ready(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  conflict,required TResult Function( List<TypeDiagnostic> diagnostics)  invalid,required TResult Function( DataValue value)  ready,}) {final _that = this;
switch (_that) {
case LoadingEditorValue():
return loading();case ConflictEditorValue():
return conflict();case InvalidEditorValue():
return invalid(_that.diagnostics);case ReadyEditorValue():
return ready(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  conflict,TResult? Function( List<TypeDiagnostic> diagnostics)?  invalid,TResult? Function( DataValue value)?  ready,}) {final _that = this;
switch (_that) {
case LoadingEditorValue() when loading != null:
return loading();case ConflictEditorValue() when conflict != null:
return conflict();case InvalidEditorValue() when invalid != null:
return invalid(_that.diagnostics);case ReadyEditorValue() when ready != null:
return ready(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class LoadingEditorValue extends EditorValue {
  const LoadingEditorValue(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadingEditorValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorValue.loading()';
}


}




/// @nodoc


class ConflictEditorValue extends EditorValue {
  const ConflictEditorValue(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictEditorValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorValue.conflict()';
}


}




/// @nodoc


class InvalidEditorValue extends EditorValue {
  const InvalidEditorValue(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics,super._();
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditorValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidEditorValueCopyWith<InvalidEditorValue> get copyWith => _$InvalidEditorValueCopyWithImpl<InvalidEditorValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEditorValue&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'EditorValue.invalid(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $InvalidEditorValueCopyWith<$Res> implements $EditorValueCopyWith<$Res> {
  factory $InvalidEditorValueCopyWith(InvalidEditorValue value, $Res Function(InvalidEditorValue) _then) = _$InvalidEditorValueCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$InvalidEditorValueCopyWithImpl<$Res>
    implements $InvalidEditorValueCopyWith<$Res> {
  _$InvalidEditorValueCopyWithImpl(this._self, this._then);

  final InvalidEditorValue _self;
  final $Res Function(InvalidEditorValue) _then;

/// Create a copy of EditorValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(InvalidEditorValue(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class ReadyEditorValue extends EditorValue {
  const ReadyEditorValue(this.value): super._();
  

 final  DataValue value;

/// Create a copy of EditorValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadyEditorValueCopyWith<ReadyEditorValue> get copyWith => _$ReadyEditorValueCopyWithImpl<ReadyEditorValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadyEditorValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'EditorValue.ready(value: $value)';
}


}

/// @nodoc
abstract mixin class $ReadyEditorValueCopyWith<$Res> implements $EditorValueCopyWith<$Res> {
  factory $ReadyEditorValueCopyWith(ReadyEditorValue value, $Res Function(ReadyEditorValue) _then) = _$ReadyEditorValueCopyWithImpl;
@useResult
$Res call({
 DataValue value
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$ReadyEditorValueCopyWithImpl<$Res>
    implements $ReadyEditorValueCopyWith<$Res> {
  _$ReadyEditorValueCopyWithImpl(this._self, this._then);

  final ReadyEditorValue _self;
  final $Res Function(ReadyEditorValue) _then;

/// Create a copy of EditorValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ReadyEditorValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of EditorValue
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
mixin _$EditorMutationResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorMutationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorMutationResult()';
}


}

/// @nodoc
class $EditorMutationResultCopyWith<$Res>  {
$EditorMutationResultCopyWith(EditorMutationResult _, $Res Function(EditorMutationResult) __);
}


/// Adds pattern-matching-related methods to [EditorMutationResult].
extension EditorMutationResultPatterns on EditorMutationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppliedEditorMutation value)?  applied,TResult Function( ConflictingEditorMutation value)?  conflict,TResult Function( InvalidEditorMutation value)?  invalid,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppliedEditorMutation() when applied != null:
return applied(_that);case ConflictingEditorMutation() when conflict != null:
return conflict(_that);case InvalidEditorMutation() when invalid != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppliedEditorMutation value)  applied,required TResult Function( ConflictingEditorMutation value)  conflict,required TResult Function( InvalidEditorMutation value)  invalid,}){
final _that = this;
switch (_that) {
case AppliedEditorMutation():
return applied(_that);case ConflictingEditorMutation():
return conflict(_that);case InvalidEditorMutation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppliedEditorMutation value)?  applied,TResult? Function( ConflictingEditorMutation value)?  conflict,TResult? Function( InvalidEditorMutation value)?  invalid,}){
final _that = this;
switch (_that) {
case AppliedEditorMutation() when applied != null:
return applied(_that);case ConflictingEditorMutation() when conflict != null:
return conflict(_that);case InvalidEditorMutation() when invalid != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DataValue value)?  applied,TResult Function()?  conflict,TResult Function( List<TypeDiagnostic> diagnostics)?  invalid,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppliedEditorMutation() when applied != null:
return applied(_that.value);case ConflictingEditorMutation() when conflict != null:
return conflict();case InvalidEditorMutation() when invalid != null:
return invalid(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DataValue value)  applied,required TResult Function()  conflict,required TResult Function( List<TypeDiagnostic> diagnostics)  invalid,}) {final _that = this;
switch (_that) {
case AppliedEditorMutation():
return applied(_that.value);case ConflictingEditorMutation():
return conflict();case InvalidEditorMutation():
return invalid(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DataValue value)?  applied,TResult? Function()?  conflict,TResult? Function( List<TypeDiagnostic> diagnostics)?  invalid,}) {final _that = this;
switch (_that) {
case AppliedEditorMutation() when applied != null:
return applied(_that.value);case ConflictingEditorMutation() when conflict != null:
return conflict();case InvalidEditorMutation() when invalid != null:
return invalid(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class AppliedEditorMutation extends EditorMutationResult {
  const AppliedEditorMutation(this.value): super._();
  

 final  DataValue value;

/// Create a copy of EditorMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppliedEditorMutationCopyWith<AppliedEditorMutation> get copyWith => _$AppliedEditorMutationCopyWithImpl<AppliedEditorMutation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppliedEditorMutation&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'EditorMutationResult.applied(value: $value)';
}


}

/// @nodoc
abstract mixin class $AppliedEditorMutationCopyWith<$Res> implements $EditorMutationResultCopyWith<$Res> {
  factory $AppliedEditorMutationCopyWith(AppliedEditorMutation value, $Res Function(AppliedEditorMutation) _then) = _$AppliedEditorMutationCopyWithImpl;
@useResult
$Res call({
 DataValue value
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$AppliedEditorMutationCopyWithImpl<$Res>
    implements $AppliedEditorMutationCopyWith<$Res> {
  _$AppliedEditorMutationCopyWithImpl(this._self, this._then);

  final AppliedEditorMutation _self;
  final $Res Function(AppliedEditorMutation) _then;

/// Create a copy of EditorMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(AppliedEditorMutation(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of EditorMutationResult
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


class ConflictingEditorMutation extends EditorMutationResult {
  const ConflictingEditorMutation(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictingEditorMutation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorMutationResult.conflict()';
}


}




/// @nodoc


class InvalidEditorMutation extends EditorMutationResult {
  const InvalidEditorMutation(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics,super._();
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditorMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidEditorMutationCopyWith<InvalidEditorMutation> get copyWith => _$InvalidEditorMutationCopyWithImpl<InvalidEditorMutation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEditorMutation&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'EditorMutationResult.invalid(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $InvalidEditorMutationCopyWith<$Res> implements $EditorMutationResultCopyWith<$Res> {
  factory $InvalidEditorMutationCopyWith(InvalidEditorMutation value, $Res Function(InvalidEditorMutation) _then) = _$InvalidEditorMutationCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$InvalidEditorMutationCopyWithImpl<$Res>
    implements $InvalidEditorMutationCopyWith<$Res> {
  _$InvalidEditorMutationCopyWithImpl(this._self, this._then);

  final InvalidEditorMutation _self;
  final $Res Function(InvalidEditorMutation) _then;

/// Create a copy of EditorMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(InvalidEditorMutation(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
