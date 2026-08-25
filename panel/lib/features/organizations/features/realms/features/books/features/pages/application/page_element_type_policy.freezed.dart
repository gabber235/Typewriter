// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_element_type_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageElementTypesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementTypesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PageElementTypesState()';
}


}

/// @nodoc
class $PageElementTypesStateCopyWith<$Res>  {
$PageElementTypesStateCopyWith(PageElementTypesState _, $Res Function(PageElementTypesState) __);
}


/// Adds pattern-matching-related methods to [PageElementTypesState].
extension PageElementTypesStatePatterns on PageElementTypesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PageElementTypesLoading value)?  loading,TResult Function( PageElementTypesReady value)?  ready,TResult Function( PageElementTypesUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PageElementTypesLoading() when loading != null:
return loading(_that);case PageElementTypesReady() when ready != null:
return ready(_that);case PageElementTypesUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PageElementTypesLoading value)  loading,required TResult Function( PageElementTypesReady value)  ready,required TResult Function( PageElementTypesUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case PageElementTypesLoading():
return loading(_that);case PageElementTypesReady():
return ready(_that);case PageElementTypesUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PageElementTypesLoading value)?  loading,TResult? Function( PageElementTypesReady value)?  ready,TResult? Function( PageElementTypesUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case PageElementTypesLoading() when loading != null:
return loading(_that);case PageElementTypesReady() when ready != null:
return ready(_that);case PageElementTypesUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Set<ResolvedTypeRef> types)?  ready,TResult Function( List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PageElementTypesLoading() when loading != null:
return loading();case PageElementTypesReady() when ready != null:
return ready(_that.types);case PageElementTypesUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Set<ResolvedTypeRef> types)  ready,required TResult Function( List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case PageElementTypesLoading():
return loading();case PageElementTypesReady():
return ready(_that.types);case PageElementTypesUnavailable():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Set<ResolvedTypeRef> types)?  ready,TResult? Function( List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case PageElementTypesLoading() when loading != null:
return loading();case PageElementTypesReady() when ready != null:
return ready(_that.types);case PageElementTypesUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class PageElementTypesLoading implements PageElementTypesState {
  const PageElementTypesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementTypesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PageElementTypesState.loading()';
}


}




/// @nodoc


class PageElementTypesReady implements PageElementTypesState {
  const PageElementTypesReady(final  Set<ResolvedTypeRef> types): _types = types;
  

 final  Set<ResolvedTypeRef> _types;
 Set<ResolvedTypeRef> get types {
  if (_types is EqualUnmodifiableSetView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_types);
}


/// Create a copy of PageElementTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementTypesReadyCopyWith<PageElementTypesReady> get copyWith => _$PageElementTypesReadyCopyWithImpl<PageElementTypesReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementTypesReady&&const DeepCollectionEquality().equals(other._types, _types));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_types));

@override
String toString() {
  return 'PageElementTypesState.ready(types: $types)';
}


}

/// @nodoc
abstract mixin class $PageElementTypesReadyCopyWith<$Res> implements $PageElementTypesStateCopyWith<$Res> {
  factory $PageElementTypesReadyCopyWith(PageElementTypesReady value, $Res Function(PageElementTypesReady) _then) = _$PageElementTypesReadyCopyWithImpl;
@useResult
$Res call({
 Set<ResolvedTypeRef> types
});




}
/// @nodoc
class _$PageElementTypesReadyCopyWithImpl<$Res>
    implements $PageElementTypesReadyCopyWith<$Res> {
  _$PageElementTypesReadyCopyWithImpl(this._self, this._then);

  final PageElementTypesReady _self;
  final $Res Function(PageElementTypesReady) _then;

/// Create a copy of PageElementTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? types = null,}) {
  return _then(PageElementTypesReady(
null == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,
  ));
}


}

/// @nodoc


class PageElementTypesUnavailable implements PageElementTypesState {
  const PageElementTypesUnavailable(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PageElementTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementTypesUnavailableCopyWith<PageElementTypesUnavailable> get copyWith => _$PageElementTypesUnavailableCopyWithImpl<PageElementTypesUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementTypesUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'PageElementTypesState.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $PageElementTypesUnavailableCopyWith<$Res> implements $PageElementTypesStateCopyWith<$Res> {
  factory $PageElementTypesUnavailableCopyWith(PageElementTypesUnavailable value, $Res Function(PageElementTypesUnavailable) _then) = _$PageElementTypesUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$PageElementTypesUnavailableCopyWithImpl<$Res>
    implements $PageElementTypesUnavailableCopyWith<$Res> {
  _$PageElementTypesUnavailableCopyWithImpl(this._self, this._then);

  final PageElementTypesUnavailable _self;
  final $Res Function(PageElementTypesUnavailable) _then;

/// Create a copy of PageElementTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(PageElementTypesUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
