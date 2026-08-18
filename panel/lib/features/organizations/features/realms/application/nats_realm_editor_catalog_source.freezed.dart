// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nats_realm_editor_catalog_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DecodedCatalogParts {

 Map<PresentationId, PresentationDefinition> get presentations; Map<ConversionId, ConversionDefinition> get conversions; Map<RealmActionId, RealmActionDefinition> get realmActions; Map<String, RealmEditorSubtypeResult> get subtypeResults; List<TypeDiagnostic> get diagnostics;
/// Create a copy of _DecodedCatalogParts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecodedCatalogPartsCopyWith<_DecodedCatalogParts> get copyWith => __$DecodedCatalogPartsCopyWithImpl<_DecodedCatalogParts>(this as _DecodedCatalogParts, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecodedCatalogParts&&const DeepCollectionEquality().equals(other.presentations, presentations)&&const DeepCollectionEquality().equals(other.conversions, conversions)&&const DeepCollectionEquality().equals(other.realmActions, realmActions)&&const DeepCollectionEquality().equals(other.subtypeResults, subtypeResults)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(presentations),const DeepCollectionEquality().hash(conversions),const DeepCollectionEquality().hash(realmActions),const DeepCollectionEquality().hash(subtypeResults),const DeepCollectionEquality().hash(diagnostics));

@override
String toString() {
  return '_DecodedCatalogParts(presentations: $presentations, conversions: $conversions, realmActions: $realmActions, subtypeResults: $subtypeResults, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$DecodedCatalogPartsCopyWith<$Res>  {
  factory _$DecodedCatalogPartsCopyWith(_DecodedCatalogParts value, $Res Function(_DecodedCatalogParts) _then) = __$DecodedCatalogPartsCopyWithImpl;
@useResult
$Res call({
 Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<RealmActionId, RealmActionDefinition> realmActions, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class __$DecodedCatalogPartsCopyWithImpl<$Res>
    implements _$DecodedCatalogPartsCopyWith<$Res> {
  __$DecodedCatalogPartsCopyWithImpl(this._self, this._then);

  final _DecodedCatalogParts _self;
  final $Res Function(_DecodedCatalogParts) _then;

/// Create a copy of _DecodedCatalogParts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? presentations = null,Object? conversions = null,Object? realmActions = null,Object? subtypeResults = null,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self.conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,realmActions: null == realmActions ? _self.realmActions : realmActions // ignore: cast_nullable_to_non_nullable
as Map<RealmActionId, RealmActionDefinition>,subtypeResults: null == subtypeResults ? _self.subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [_DecodedCatalogParts].
extension _DecodedCatalogPartsPatterns on _DecodedCatalogParts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DecodedCatalogPartsValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DecodedCatalogPartsValue value)  $default,){
final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DecodedCatalogPartsValue value)?  $default,){
final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<RealmActionId, RealmActionDefinition> realmActions,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue() when $default != null:
return $default(_that.presentations,_that.conversions,_that.realmActions,_that.subtypeResults,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<RealmActionId, RealmActionDefinition> realmActions,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue():
return $default(_that.presentations,_that.conversions,_that.realmActions,_that.subtypeResults,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<RealmActionId, RealmActionDefinition> realmActions,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _DecodedCatalogPartsValue() when $default != null:
return $default(_that.presentations,_that.conversions,_that.realmActions,_that.subtypeResults,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _DecodedCatalogPartsValue implements _DecodedCatalogParts {
  const _DecodedCatalogPartsValue({required final  Map<PresentationId, PresentationDefinition> presentations, required final  Map<ConversionId, ConversionDefinition> conversions, required final  Map<RealmActionId, RealmActionDefinition> realmActions, required final  Map<String, RealmEditorSubtypeResult> subtypeResults, required final  List<TypeDiagnostic> diagnostics}): _presentations = presentations,_conversions = conversions,_realmActions = realmActions,_subtypeResults = subtypeResults,_diagnostics = diagnostics;
  

 final  Map<PresentationId, PresentationDefinition> _presentations;
@override Map<PresentationId, PresentationDefinition> get presentations {
  if (_presentations is EqualUnmodifiableMapView) return _presentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_presentations);
}

 final  Map<ConversionId, ConversionDefinition> _conversions;
@override Map<ConversionId, ConversionDefinition> get conversions {
  if (_conversions is EqualUnmodifiableMapView) return _conversions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conversions);
}

 final  Map<RealmActionId, RealmActionDefinition> _realmActions;
@override Map<RealmActionId, RealmActionDefinition> get realmActions {
  if (_realmActions is EqualUnmodifiableMapView) return _realmActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_realmActions);
}

 final  Map<String, RealmEditorSubtypeResult> _subtypeResults;
@override Map<String, RealmEditorSubtypeResult> get subtypeResults {
  if (_subtypeResults is EqualUnmodifiableMapView) return _subtypeResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subtypeResults);
}

 final  List<TypeDiagnostic> _diagnostics;
@override List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of _DecodedCatalogParts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecodedCatalogPartsValueCopyWith<_DecodedCatalogPartsValue> get copyWith => __$DecodedCatalogPartsValueCopyWithImpl<_DecodedCatalogPartsValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecodedCatalogPartsValue&&const DeepCollectionEquality().equals(other._presentations, _presentations)&&const DeepCollectionEquality().equals(other._conversions, _conversions)&&const DeepCollectionEquality().equals(other._realmActions, _realmActions)&&const DeepCollectionEquality().equals(other._subtypeResults, _subtypeResults)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_presentations),const DeepCollectionEquality().hash(_conversions),const DeepCollectionEquality().hash(_realmActions),const DeepCollectionEquality().hash(_subtypeResults),const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return '_DecodedCatalogParts(presentations: $presentations, conversions: $conversions, realmActions: $realmActions, subtypeResults: $subtypeResults, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$DecodedCatalogPartsValueCopyWith<$Res> implements _$DecodedCatalogPartsCopyWith<$Res> {
  factory _$DecodedCatalogPartsValueCopyWith(_DecodedCatalogPartsValue value, $Res Function(_DecodedCatalogPartsValue) _then) = __$DecodedCatalogPartsValueCopyWithImpl;
@override @useResult
$Res call({
 Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<RealmActionId, RealmActionDefinition> realmActions, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class __$DecodedCatalogPartsValueCopyWithImpl<$Res>
    implements _$DecodedCatalogPartsValueCopyWith<$Res> {
  __$DecodedCatalogPartsValueCopyWithImpl(this._self, this._then);

  final _DecodedCatalogPartsValue _self;
  final $Res Function(_DecodedCatalogPartsValue) _then;

/// Create a copy of _DecodedCatalogParts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? presentations = null,Object? conversions = null,Object? realmActions = null,Object? subtypeResults = null,Object? diagnostics = null,}) {
  return _then(_DecodedCatalogPartsValue(
presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self._conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,realmActions: null == realmActions ? _self._realmActions : realmActions // ignore: cast_nullable_to_non_nullable
as Map<RealmActionId, RealmActionDefinition>,subtypeResults: null == subtypeResults ? _self._subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
