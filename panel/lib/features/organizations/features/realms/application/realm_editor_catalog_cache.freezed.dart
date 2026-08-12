// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_editor_catalog_cache.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmEditorCatalogState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RealmEditorCatalogState()';
}


}

/// @nodoc
class $RealmEditorCatalogStateCopyWith<$Res>  {
$RealmEditorCatalogStateCopyWith(RealmEditorCatalogState _, $Res Function(RealmEditorCatalogState) __);
}


/// Adds pattern-matching-related methods to [RealmEditorCatalogState].
extension RealmEditorCatalogStatePatterns on RealmEditorCatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmEditorCatalogLoading value)?  loading,TResult Function( RealmEditorCatalogReady value)?  ready,TResult Function( RealmEditorCatalogUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmEditorCatalogLoading() when loading != null:
return loading(_that);case RealmEditorCatalogReady() when ready != null:
return ready(_that);case RealmEditorCatalogUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmEditorCatalogLoading value)  loading,required TResult Function( RealmEditorCatalogReady value)  ready,required TResult Function( RealmEditorCatalogUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogLoading():
return loading(_that);case RealmEditorCatalogReady():
return ready(_that);case RealmEditorCatalogUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmEditorCatalogLoading value)?  loading,TResult? Function( RealmEditorCatalogReady value)?  ready,TResult? Function( RealmEditorCatalogUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogLoading() when loading != null:
return loading(_that);case RealmEditorCatalogReady() when ready != null:
return ready(_that);case RealmEditorCatalogUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RealmEditorCatalogSnapshot? previous)?  loading,TResult Function( RealmEditorCatalogSnapshot value)?  ready,TResult Function( List<TypeDiagnostic> diagnostics,  RealmEditorCatalogSnapshot? previous)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmEditorCatalogLoading() when loading != null:
return loading(_that.previous);case RealmEditorCatalogReady() when ready != null:
return ready(_that.value);case RealmEditorCatalogUnavailable() when unavailable != null:
return unavailable(_that.diagnostics,_that.previous);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RealmEditorCatalogSnapshot? previous)  loading,required TResult Function( RealmEditorCatalogSnapshot value)  ready,required TResult Function( List<TypeDiagnostic> diagnostics,  RealmEditorCatalogSnapshot? previous)  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogLoading():
return loading(_that.previous);case RealmEditorCatalogReady():
return ready(_that.value);case RealmEditorCatalogUnavailable():
return unavailable(_that.diagnostics,_that.previous);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RealmEditorCatalogSnapshot? previous)?  loading,TResult? Function( RealmEditorCatalogSnapshot value)?  ready,TResult? Function( List<TypeDiagnostic> diagnostics,  RealmEditorCatalogSnapshot? previous)?  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogLoading() when loading != null:
return loading(_that.previous);case RealmEditorCatalogReady() when ready != null:
return ready(_that.value);case RealmEditorCatalogUnavailable() when unavailable != null:
return unavailable(_that.diagnostics,_that.previous);case _:
  return null;

}
}

}

/// @nodoc


class RealmEditorCatalogLoading extends RealmEditorCatalogState {
  const RealmEditorCatalogLoading([this.previous]): super._();
  

 final  RealmEditorCatalogSnapshot? previous;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogLoadingCopyWith<RealmEditorCatalogLoading> get copyWith => _$RealmEditorCatalogLoadingCopyWithImpl<RealmEditorCatalogLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogLoading&&(identical(other.previous, previous) || other.previous == previous));
}


@override
int get hashCode => Object.hash(runtimeType,previous);

@override
String toString() {
  return 'RealmEditorCatalogState.loading(previous: $previous)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogLoadingCopyWith<$Res> implements $RealmEditorCatalogStateCopyWith<$Res> {
  factory $RealmEditorCatalogLoadingCopyWith(RealmEditorCatalogLoading value, $Res Function(RealmEditorCatalogLoading) _then) = _$RealmEditorCatalogLoadingCopyWithImpl;
@useResult
$Res call({
 RealmEditorCatalogSnapshot? previous
});


$RealmEditorCatalogSnapshotCopyWith<$Res>? get previous;

}
/// @nodoc
class _$RealmEditorCatalogLoadingCopyWithImpl<$Res>
    implements $RealmEditorCatalogLoadingCopyWith<$Res> {
  _$RealmEditorCatalogLoadingCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogLoading _self;
  final $Res Function(RealmEditorCatalogLoading) _then;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? previous = freezed,}) {
  return _then(RealmEditorCatalogLoading(
freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot?,
  ));
}

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}
}

/// @nodoc


class RealmEditorCatalogReady extends RealmEditorCatalogState {
  const RealmEditorCatalogReady(this.value): super._();
  

 final  RealmEditorCatalogSnapshot value;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogReadyCopyWith<RealmEditorCatalogReady> get copyWith => _$RealmEditorCatalogReadyCopyWithImpl<RealmEditorCatalogReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogReady&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'RealmEditorCatalogState.ready(value: $value)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogReadyCopyWith<$Res> implements $RealmEditorCatalogStateCopyWith<$Res> {
  factory $RealmEditorCatalogReadyCopyWith(RealmEditorCatalogReady value, $Res Function(RealmEditorCatalogReady) _then) = _$RealmEditorCatalogReadyCopyWithImpl;
@useResult
$Res call({
 RealmEditorCatalogSnapshot value
});


$RealmEditorCatalogSnapshotCopyWith<$Res> get value;

}
/// @nodoc
class _$RealmEditorCatalogReadyCopyWithImpl<$Res>
    implements $RealmEditorCatalogReadyCopyWith<$Res> {
  _$RealmEditorCatalogReadyCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogReady _self;
  final $Res Function(RealmEditorCatalogReady) _then;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(RealmEditorCatalogReady(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot,
  ));
}

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res> get value {
  
  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class RealmEditorCatalogUnavailable extends RealmEditorCatalogState {
  const RealmEditorCatalogUnavailable(final  List<TypeDiagnostic> diagnostics, {this.previous}): _diagnostics = diagnostics,super._();
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

 final  RealmEditorCatalogSnapshot? previous;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogUnavailableCopyWith<RealmEditorCatalogUnavailable> get copyWith => _$RealmEditorCatalogUnavailableCopyWithImpl<RealmEditorCatalogUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics)&&(identical(other.previous, previous) || other.previous == previous));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics),previous);

@override
String toString() {
  return 'RealmEditorCatalogState.unavailable(diagnostics: $diagnostics, previous: $previous)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogUnavailableCopyWith<$Res> implements $RealmEditorCatalogStateCopyWith<$Res> {
  factory $RealmEditorCatalogUnavailableCopyWith(RealmEditorCatalogUnavailable value, $Res Function(RealmEditorCatalogUnavailable) _then) = _$RealmEditorCatalogUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics, RealmEditorCatalogSnapshot? previous
});


$RealmEditorCatalogSnapshotCopyWith<$Res>? get previous;

}
/// @nodoc
class _$RealmEditorCatalogUnavailableCopyWithImpl<$Res>
    implements $RealmEditorCatalogUnavailableCopyWith<$Res> {
  _$RealmEditorCatalogUnavailableCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogUnavailable _self;
  final $Res Function(RealmEditorCatalogUnavailable) _then;

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,Object? previous = freezed,}) {
  return _then(RealmEditorCatalogUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot?,
  ));
}

/// Create a copy of RealmEditorCatalogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}
}

// dart format on
