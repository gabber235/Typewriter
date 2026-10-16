// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checked_editor_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorFieldPresentationIdentity {

 skir.PresentationId get provider; skir.TypeTemplate get subject; skir.PresentationRole get role; String get field; String get nodeId;
/// Create a copy of EditorFieldPresentationIdentity
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<EditorFieldPresentationIdentity> get copyWith => _$EditorFieldPresentationIdentityCopyWithImpl<EditorFieldPresentationIdentity>(this as EditorFieldPresentationIdentity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorFieldPresentationIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorFieldPresentationIdentity&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.nodeId, _this.nodeId) || other.nodeId == _this.nodeId));
}


@override
int get hashCode {
  final _this = this as EditorFieldPresentationIdentity;
  return Object.hash(runtimeType,_this.provider,_this.subject,_this.role,_this.field,_this.nodeId);
}

@override
String toString() {
  final _this = this as EditorFieldPresentationIdentity;
  return 'EditorFieldPresentationIdentity(provider: ${_this.provider}, subject: ${_this.subject}, role: ${_this.role}, field: ${_this.field}, nodeId: ${_this.nodeId})';
}


}

/// @nodoc
abstract mixin class $EditorFieldPresentationIdentityCopyWith<$Res>  {
  factory $EditorFieldPresentationIdentityCopyWith(EditorFieldPresentationIdentity value, $Res Function(EditorFieldPresentationIdentity) _then) = _$EditorFieldPresentationIdentityCopyWithImpl;
@useResult
$Res call({
 skir.PresentationId provider, skir.TypeTemplate subject, skir.PresentationRole role, String field, String nodeId
});




}
/// @nodoc
class _$EditorFieldPresentationIdentityCopyWithImpl<$Res>
    implements $EditorFieldPresentationIdentityCopyWith<$Res> {
  _$EditorFieldPresentationIdentityCopyWithImpl(this._self, this._then);

  final EditorFieldPresentationIdentity _self;
  final $Res Function(EditorFieldPresentationIdentity) _then;

/// Create a copy of EditorFieldPresentationIdentity
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? subject = null,Object? role = null,Object? field = null,Object? nodeId = null,}) {
  return _then(EditorFieldPresentationIdentity(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as skir.TypeTemplate,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern matching related methods to [EditorFieldPresentationIdentity].
extension EditorFieldPresentationIdentityPatterns on EditorFieldPresentationIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorFieldPresentationIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorFieldPresentationIdentity value)  $default,){
final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorFieldPresentationIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationId provider,  skir.TypeTemplate subject,  skir.PresentationRole role,  String field,  String nodeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity() when $default != null:
return $default(_that.provider,_that.subject,_that.role,_that.field,_that.nodeId);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationId provider,  skir.TypeTemplate subject,  skir.PresentationRole role,  String field,  String nodeId)  $default,) {final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity():
return $default(_that.provider,_that.subject,_that.role,_that.field,_that.nodeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationId provider,  skir.TypeTemplate subject,  skir.PresentationRole role,  String field,  String nodeId)?  $default,) {final _that = this;
switch (_that) {
case _EditorFieldPresentationIdentity() when $default != null:
return $default(_that.provider,_that.subject,_that.role,_that.field,_that.nodeId);case _:
  return null;

}
}

}

/// @nodoc


class _EditorFieldPresentationIdentity implements EditorFieldPresentationIdentity {
  const _EditorFieldPresentationIdentity({required this.provider, required this.subject, required this.role, required this.field, required this.nodeId});


@override final  skir.PresentationId provider;
@override final  skir.TypeTemplate subject;
@override final  skir.PresentationRole role;
@override final  String field;
@override final  String nodeId;

/// Create a copy of EditorFieldPresentationIdentity
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorFieldPresentationIdentityCopyWith<_EditorFieldPresentationIdentity> get copyWith => __$EditorFieldPresentationIdentityCopyWithImpl<_EditorFieldPresentationIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorFieldPresentationIdentity&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.role, role) || other.role == role)&&(identical(other.field, field) || other.field == field)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,provider,subject,role,field,nodeId);
}

@override
String toString() {
    return 'EditorFieldPresentationIdentity(provider: $provider, subject: $subject, role: $role, field: $field, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class _$EditorFieldPresentationIdentityCopyWith<$Res> implements $EditorFieldPresentationIdentityCopyWith<$Res> {
  factory _$EditorFieldPresentationIdentityCopyWith(_EditorFieldPresentationIdentity value, $Res Function(_EditorFieldPresentationIdentity) _then) = __$EditorFieldPresentationIdentityCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationId provider, skir.TypeTemplate subject, skir.PresentationRole role, String field, String nodeId
});




}
/// @nodoc
class __$EditorFieldPresentationIdentityCopyWithImpl<$Res>
    implements _$EditorFieldPresentationIdentityCopyWith<$Res> {
  __$EditorFieldPresentationIdentityCopyWithImpl(this._self, this._then);

  final _EditorFieldPresentationIdentity _self;
  final $Res Function(_EditorFieldPresentationIdentity) _then;

/// Create a copy of EditorFieldPresentationIdentity
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? subject = null,Object? role = null,Object? field = null,Object? nodeId = null,}) {
  return _then(_EditorFieldPresentationIdentity(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as skir.TypeTemplate,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EditorFieldPresentationSelection {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorFieldPresentationSelection);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorFieldPresentationSelection()';
}


}

/// @nodoc
class $EditorFieldPresentationSelectionCopyWith<$Res>  {
$EditorFieldPresentationSelectionCopyWith(EditorFieldPresentationSelection _, $Res Function(EditorFieldPresentationSelection) __);
}


/// Adds pattern matching related methods to [EditorFieldPresentationSelection].
extension EditorFieldPresentationSelectionPatterns on EditorFieldPresentationSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectedEditorFieldPresentation value)?  selected,TResult Function( ConflictingEditorFieldPresentation value)?  conflicting,TResult Function( InvalidEditorFieldPresentation value)?  invalid,TResult Function( MissingEditorFieldPresentation value)?  missing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation() when selected != null:
return selected(_that);case ConflictingEditorFieldPresentation() when conflicting != null:
return conflicting(_that);case InvalidEditorFieldPresentation() when invalid != null:
return invalid(_that);case MissingEditorFieldPresentation() when missing != null:
return missing(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectedEditorFieldPresentation value)  selected,required TResult Function( ConflictingEditorFieldPresentation value)  conflicting,required TResult Function( InvalidEditorFieldPresentation value)  invalid,required TResult Function( MissingEditorFieldPresentation value)  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation():
return selected(_that);case ConflictingEditorFieldPresentation():
return conflicting(_that);case InvalidEditorFieldPresentation():
return invalid(_that);case MissingEditorFieldPresentation():
return missing(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectedEditorFieldPresentation value)?  selected,TResult? Function( ConflictingEditorFieldPresentation value)?  conflicting,TResult? Function( InvalidEditorFieldPresentation value)?  invalid,TResult? Function( MissingEditorFieldPresentation value)?  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation() when selected != null:
return selected(_that);case ConflictingEditorFieldPresentation() when conflicting != null:
return conflicting(_that);case InvalidEditorFieldPresentation() when invalid != null:
return invalid(_that);case MissingEditorFieldPresentation() when missing != null:
return missing(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)?  selected,TResult Function( List<EditorFieldPresentationIdentity> candidates)?  conflicting,TResult Function( EditorFieldPresentationIdentity identity,  String diagnostic)?  invalid,TResult Function()?  missing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation() when selected != null:
return selected(_that.identity,_that.material,_that.node);case ConflictingEditorFieldPresentation() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorFieldPresentation() when invalid != null:
return invalid(_that.identity,_that.diagnostic);case MissingEditorFieldPresentation() when missing != null:
return missing();case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)  selected,required TResult Function( List<EditorFieldPresentationIdentity> candidates)  conflicting,required TResult Function( EditorFieldPresentationIdentity identity,  String diagnostic)  invalid,required TResult Function()  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation():
return selected(_that.identity,_that.material,_that.node);case ConflictingEditorFieldPresentation():
return conflicting(_that.candidates);case InvalidEditorFieldPresentation():
return invalid(_that.identity,_that.diagnostic);case MissingEditorFieldPresentation():
return missing();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)?  selected,TResult? Function( List<EditorFieldPresentationIdentity> candidates)?  conflicting,TResult? Function( EditorFieldPresentationIdentity identity,  String diagnostic)?  invalid,TResult? Function()?  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorFieldPresentation() when selected != null:
return selected(_that.identity,_that.material,_that.node);case ConflictingEditorFieldPresentation() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorFieldPresentation() when invalid != null:
return invalid(_that.identity,_that.diagnostic);case MissingEditorFieldPresentation() when missing != null:
return missing();case _:
  return null;

}
}

}

/// @nodoc


class SelectedEditorFieldPresentation implements EditorFieldPresentationSelection {
  const SelectedEditorFieldPresentation({required this.identity, required this.material, required this.node});


 final  EditorFieldPresentationIdentity identity;
 final  skir.PresentationMaterial material;
 final  skir.PresentationNode node;

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedEditorFieldPresentationCopyWith<SelectedEditorFieldPresentation> get copyWith => _$SelectedEditorFieldPresentationCopyWithImpl<SelectedEditorFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedEditorFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.material, material) || other.material == material)&&(identical(other.node, node) || other.node == node));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,material,node);
}

@override
String toString() {
    return 'EditorFieldPresentationSelection.selected(identity: $identity, material: $material, node: $node)';
}


}

/// @nodoc
abstract mixin class $SelectedEditorFieldPresentationCopyWith<$Res> implements $EditorFieldPresentationSelectionCopyWith<$Res> {
  factory $SelectedEditorFieldPresentationCopyWith(SelectedEditorFieldPresentation value, $Res Function(SelectedEditorFieldPresentation) _then) = _$SelectedEditorFieldPresentationCopyWithImpl;
@useResult
$Res call({
 EditorFieldPresentationIdentity identity, skir.PresentationMaterial material, skir.PresentationNode node
});


$EditorFieldPresentationIdentityCopyWith<$Res> get identity;

}
/// @nodoc
class _$SelectedEditorFieldPresentationCopyWithImpl<$Res>
    implements $SelectedEditorFieldPresentationCopyWith<$Res> {
  _$SelectedEditorFieldPresentationCopyWithImpl(this._self, this._then);

  final SelectedEditorFieldPresentation _self;
  final $Res Function(SelectedEditorFieldPresentation) _then;

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? material = null,Object? node = null,}) {
  return _then(SelectedEditorFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,
  ));
}

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}

/// @nodoc


class ConflictingEditorFieldPresentation implements EditorFieldPresentationSelection {
  const ConflictingEditorFieldPresentation({required  List<EditorFieldPresentationIdentity> candidates}): _candidates = candidates;


 final  List<EditorFieldPresentationIdentity> _candidates;
 List<EditorFieldPresentationIdentity> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictingEditorFieldPresentationCopyWith<ConflictingEditorFieldPresentation> get copyWith => _$ConflictingEditorFieldPresentationCopyWithImpl<ConflictingEditorFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictingEditorFieldPresentation&&const DeepCollectionEquality().equals(other.candidates, _candidates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_candidates));
}

@override
String toString() {
    return 'EditorFieldPresentationSelection.conflicting(candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $ConflictingEditorFieldPresentationCopyWith<$Res> implements $EditorFieldPresentationSelectionCopyWith<$Res> {
  factory $ConflictingEditorFieldPresentationCopyWith(ConflictingEditorFieldPresentation value, $Res Function(ConflictingEditorFieldPresentation) _then) = _$ConflictingEditorFieldPresentationCopyWithImpl;
@useResult
$Res call({
 List<EditorFieldPresentationIdentity> candidates
});




}
/// @nodoc
class _$ConflictingEditorFieldPresentationCopyWithImpl<$Res>
    implements $ConflictingEditorFieldPresentationCopyWith<$Res> {
  _$ConflictingEditorFieldPresentationCopyWithImpl(this._self, this._then);

  final ConflictingEditorFieldPresentation _self;
  final $Res Function(ConflictingEditorFieldPresentation) _then;

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidates = null,}) {
  return _then(ConflictingEditorFieldPresentation(
candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<EditorFieldPresentationIdentity>,
  ));
}


}

/// @nodoc


class InvalidEditorFieldPresentation implements EditorFieldPresentationSelection {
  const InvalidEditorFieldPresentation({required this.identity, required this.diagnostic});


 final  EditorFieldPresentationIdentity identity;
 final  String diagnostic;

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidEditorFieldPresentationCopyWith<InvalidEditorFieldPresentation> get copyWith => _$InvalidEditorFieldPresentationCopyWithImpl<InvalidEditorFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEditorFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,diagnostic);
}

@override
String toString() {
    return 'EditorFieldPresentationSelection.invalid(identity: $identity, diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class $InvalidEditorFieldPresentationCopyWith<$Res> implements $EditorFieldPresentationSelectionCopyWith<$Res> {
  factory $InvalidEditorFieldPresentationCopyWith(InvalidEditorFieldPresentation value, $Res Function(InvalidEditorFieldPresentation) _then) = _$InvalidEditorFieldPresentationCopyWithImpl;
@useResult
$Res call({
 EditorFieldPresentationIdentity identity, String diagnostic
});


$EditorFieldPresentationIdentityCopyWith<$Res> get identity;

}
/// @nodoc
class _$InvalidEditorFieldPresentationCopyWithImpl<$Res>
    implements $InvalidEditorFieldPresentationCopyWith<$Res> {
  _$InvalidEditorFieldPresentationCopyWithImpl(this._self, this._then);

  final InvalidEditorFieldPresentation _self;
  final $Res Function(InvalidEditorFieldPresentation) _then;

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? diagnostic = null,}) {
  return _then(InvalidEditorFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of EditorFieldPresentationSelection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}

/// @nodoc


class MissingEditorFieldPresentation implements EditorFieldPresentationSelection {
  const MissingEditorFieldPresentation();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MissingEditorFieldPresentation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorFieldPresentationSelection.missing()';
}


}




/// @nodoc
mixin _$CheckedFieldPresentation {

 EditorFieldPresentationIdentity get identity; skir.PresentationMaterial get material;
/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckedFieldPresentationCopyWith<_CheckedFieldPresentation> get copyWith => __$CheckedFieldPresentationCopyWithImpl<_CheckedFieldPresentation>(this as _CheckedFieldPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CheckedFieldPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckedFieldPresentation&&(identical(other.identity, _this.identity) || other.identity == _this.identity)&&(identical(other.material, _this.material) || other.material == _this.material));
}


@override
int get hashCode {
  final _this = this as _CheckedFieldPresentation;
  return Object.hash(runtimeType,_this.identity,_this.material);
}

@override
String toString() {
  final _this = this as _CheckedFieldPresentation;
  return '_CheckedFieldPresentation(identity: ${_this.identity}, material: ${_this.material})';
}


}

/// @nodoc
abstract mixin class _$CheckedFieldPresentationCopyWith<$Res>  {
  factory _$CheckedFieldPresentationCopyWith(_CheckedFieldPresentation value, $Res Function(_CheckedFieldPresentation) _then) = __$CheckedFieldPresentationCopyWithImpl;
@useResult
$Res call({
 EditorFieldPresentationIdentity identity, skir.PresentationMaterial material
});


$EditorFieldPresentationIdentityCopyWith<$Res> get identity;

}
/// @nodoc
class __$CheckedFieldPresentationCopyWithImpl<$Res>
    implements _$CheckedFieldPresentationCopyWith<$Res> {
  __$CheckedFieldPresentationCopyWithImpl(this._self, this._then);

  final _CheckedFieldPresentation _self;
  final $Res Function(_CheckedFieldPresentation) _then;

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? material = null,}) {
  return _then(_self.copyWith(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,
  ));
}
/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}


/// Adds pattern matching related methods to [_CheckedFieldPresentation].
extension _CheckedFieldPresentationPatterns on _CheckedFieldPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ValidFieldPresentation value)?  valid,TResult Function( _InvalidFieldPresentation value)?  invalid,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValidFieldPresentation() when valid != null:
return valid(_that);case _InvalidFieldPresentation() when invalid != null:
return invalid(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ValidFieldPresentation value)  valid,required TResult Function( _InvalidFieldPresentation value)  invalid,}){
final _that = this;
switch (_that) {
case _ValidFieldPresentation():
return valid(_that);case _InvalidFieldPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ValidFieldPresentation value)?  valid,TResult? Function( _InvalidFieldPresentation value)?  invalid,}){
final _that = this;
switch (_that) {
case _ValidFieldPresentation() when valid != null:
return valid(_that);case _InvalidFieldPresentation() when invalid != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)?  valid,TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  String diagnostic)?  invalid,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValidFieldPresentation() when valid != null:
return valid(_that.identity,_that.material,_that.node);case _InvalidFieldPresentation() when invalid != null:
return invalid(_that.identity,_that.material,_that.diagnostic);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)  valid,required TResult Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  String diagnostic)  invalid,}) {final _that = this;
switch (_that) {
case _ValidFieldPresentation():
return valid(_that.identity,_that.material,_that.node);case _InvalidFieldPresentation():
return invalid(_that.identity,_that.material,_that.diagnostic);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  skir.PresentationNode node)?  valid,TResult? Function( EditorFieldPresentationIdentity identity,  skir.PresentationMaterial material,  String diagnostic)?  invalid,}) {final _that = this;
switch (_that) {
case _ValidFieldPresentation() when valid != null:
return valid(_that.identity,_that.material,_that.node);case _InvalidFieldPresentation() when invalid != null:
return invalid(_that.identity,_that.material,_that.diagnostic);case _:
  return null;

}
}

}

/// @nodoc


class _ValidFieldPresentation implements _CheckedFieldPresentation {
  const _ValidFieldPresentation({required this.identity, required this.material, required this.node});


@override final  EditorFieldPresentationIdentity identity;
@override final  skir.PresentationMaterial material;
 final  skir.PresentationNode node;

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidFieldPresentationCopyWith<_ValidFieldPresentation> get copyWith => __$ValidFieldPresentationCopyWithImpl<_ValidFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.material, material) || other.material == material)&&(identical(other.node, node) || other.node == node));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,material,node);
}

@override
String toString() {
    return '_CheckedFieldPresentation.valid(identity: $identity, material: $material, node: $node)';
}


}

/// @nodoc
abstract mixin class _$ValidFieldPresentationCopyWith<$Res> implements _$CheckedFieldPresentationCopyWith<$Res> {
  factory _$ValidFieldPresentationCopyWith(_ValidFieldPresentation value, $Res Function(_ValidFieldPresentation) _then) = __$ValidFieldPresentationCopyWithImpl;
@override @useResult
$Res call({
 EditorFieldPresentationIdentity identity, skir.PresentationMaterial material, skir.PresentationNode node
});


@override $EditorFieldPresentationIdentityCopyWith<$Res> get identity;

}
/// @nodoc
class __$ValidFieldPresentationCopyWithImpl<$Res>
    implements _$ValidFieldPresentationCopyWith<$Res> {
  __$ValidFieldPresentationCopyWithImpl(this._self, this._then);

  final _ValidFieldPresentation _self;
  final $Res Function(_ValidFieldPresentation) _then;

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? material = null,Object? node = null,}) {
  return _then(_ValidFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,
  ));
}

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}

/// @nodoc


class _InvalidFieldPresentation implements _CheckedFieldPresentation {
  const _InvalidFieldPresentation({required this.identity, required this.material, required this.diagnostic});


@override final  EditorFieldPresentationIdentity identity;
@override final  skir.PresentationMaterial material;
 final  String diagnostic;

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvalidFieldPresentationCopyWith<_InvalidFieldPresentation> get copyWith => __$InvalidFieldPresentationCopyWithImpl<_InvalidFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvalidFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.material, material) || other.material == material)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,material,diagnostic);
}

@override
String toString() {
    return '_CheckedFieldPresentation.invalid(identity: $identity, material: $material, diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class _$InvalidFieldPresentationCopyWith<$Res> implements _$CheckedFieldPresentationCopyWith<$Res> {
  factory _$InvalidFieldPresentationCopyWith(_InvalidFieldPresentation value, $Res Function(_InvalidFieldPresentation) _then) = __$InvalidFieldPresentationCopyWithImpl;
@override @useResult
$Res call({
 EditorFieldPresentationIdentity identity, skir.PresentationMaterial material, String diagnostic
});


@override $EditorFieldPresentationIdentityCopyWith<$Res> get identity;

}
/// @nodoc
class __$InvalidFieldPresentationCopyWithImpl<$Res>
    implements _$InvalidFieldPresentationCopyWith<$Res> {
  __$InvalidFieldPresentationCopyWithImpl(this._self, this._then);

  final _InvalidFieldPresentation _self;
  final $Res Function(_InvalidFieldPresentation) _then;

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? material = null,Object? diagnostic = null,}) {
  return _then(_InvalidFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of _CheckedFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}

/// @nodoc
mixin _$FieldPresentationCandidate {

 skir.PresentationDescriptor get descriptor; _CheckedFieldPresentation get reference;
/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldPresentationCandidateCopyWith<_FieldPresentationCandidate> get copyWith => __$FieldPresentationCandidateCopyWithImpl<_FieldPresentationCandidate>(this as _FieldPresentationCandidate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _FieldPresentationCandidate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldPresentationCandidate&&(identical(other.descriptor, _this.descriptor) || other.descriptor == _this.descriptor)&&(identical(other.reference, _this.reference) || other.reference == _this.reference));
}


@override
int get hashCode {
  final _this = this as _FieldPresentationCandidate;
  return Object.hash(runtimeType,_this.descriptor,_this.reference);
}

@override
String toString() {
  final _this = this as _FieldPresentationCandidate;
  return '_FieldPresentationCandidate(descriptor: ${_this.descriptor}, reference: ${_this.reference})';
}


}

/// @nodoc
abstract mixin class _$FieldPresentationCandidateCopyWith<$Res>  {
  factory _$FieldPresentationCandidateCopyWith(_FieldPresentationCandidate value, $Res Function(_FieldPresentationCandidate) _then) = __$FieldPresentationCandidateCopyWithImpl;
@useResult
$Res call({
 skir.PresentationDescriptor descriptor, _CheckedFieldPresentation reference
});


_$CheckedFieldPresentationCopyWith<$Res> get reference;

}
/// @nodoc
class __$FieldPresentationCandidateCopyWithImpl<$Res>
    implements _$FieldPresentationCandidateCopyWith<$Res> {
  __$FieldPresentationCandidateCopyWithImpl(this._self, this._then);

  final _FieldPresentationCandidate _self;
  final $Res Function(_FieldPresentationCandidate) _then;

/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? descriptor = null,Object? reference = null,}) {
  return _then(_FieldPresentationCandidate(
descriptor: null == descriptor ? _self.descriptor : descriptor // ignore: cast_nullable_to_non_nullable
as skir.PresentationDescriptor,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as _CheckedFieldPresentation,
  ));
}
/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
_$CheckedFieldPresentationCopyWith<$Res> get reference {

  return _$CheckedFieldPresentationCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// Adds pattern matching related methods to [_FieldPresentationCandidate].
extension _FieldPresentationCandidatePatterns on _FieldPresentationCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __FieldPresentationCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __FieldPresentationCandidate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __FieldPresentationCandidate value)  $default,){
final _that = this;
switch (_that) {
case __FieldPresentationCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __FieldPresentationCandidate value)?  $default,){
final _that = this;
switch (_that) {
case __FieldPresentationCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationDescriptor descriptor,  _CheckedFieldPresentation reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __FieldPresentationCandidate() when $default != null:
return $default(_that.descriptor,_that.reference);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationDescriptor descriptor,  _CheckedFieldPresentation reference)  $default,) {final _that = this;
switch (_that) {
case __FieldPresentationCandidate():
return $default(_that.descriptor,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationDescriptor descriptor,  _CheckedFieldPresentation reference)?  $default,) {final _that = this;
switch (_that) {
case __FieldPresentationCandidate() when $default != null:
return $default(_that.descriptor,_that.reference);case _:
  return null;

}
}

}

/// @nodoc


class __FieldPresentationCandidate implements _FieldPresentationCandidate {
  const __FieldPresentationCandidate({required this.descriptor, required this.reference});


@override final  skir.PresentationDescriptor descriptor;
@override final  _CheckedFieldPresentation reference;

/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_FieldPresentationCandidateCopyWith<__FieldPresentationCandidate> get copyWith => __$_FieldPresentationCandidateCopyWithImpl<__FieldPresentationCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __FieldPresentationCandidate&&(identical(other.descriptor, descriptor) || other.descriptor == descriptor)&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,descriptor,reference);
}

@override
String toString() {
    return '_FieldPresentationCandidate(descriptor: $descriptor, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$_FieldPresentationCandidateCopyWith<$Res> implements _$FieldPresentationCandidateCopyWith<$Res> {
  factory _$_FieldPresentationCandidateCopyWith(__FieldPresentationCandidate value, $Res Function(__FieldPresentationCandidate) _then) = __$_FieldPresentationCandidateCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationDescriptor descriptor, _CheckedFieldPresentation reference
});


@override _$CheckedFieldPresentationCopyWith<$Res> get reference;

}
/// @nodoc
class __$_FieldPresentationCandidateCopyWithImpl<$Res>
    implements _$_FieldPresentationCandidateCopyWith<$Res> {
  __$_FieldPresentationCandidateCopyWithImpl(this._self, this._then);

  final __FieldPresentationCandidate _self;
  final $Res Function(__FieldPresentationCandidate) _then;

/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? descriptor = null,Object? reference = null,}) {
  return _then(__FieldPresentationCandidate(
descriptor: null == descriptor ? _self.descriptor : descriptor // ignore: cast_nullable_to_non_nullable
as skir.PresentationDescriptor,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as _CheckedFieldPresentation,
  ));
}

/// Create a copy of _FieldPresentationCandidate
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
_$CheckedFieldPresentationCopyWith<$Res> get reference {

  return _$CheckedFieldPresentationCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

/// @nodoc
mixin _$CheckedInheritableLayout {

 Map<String, skir.PresentationNode> get nodes; Set<String> get inheritableNodes; int get remainderCount; Set<String> get canonicalFields; Set<skir.PresentationPartId> get declaredParts; String? get diagnostic;
/// Create a copy of CheckedInheritableLayout
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckedInheritableLayoutCopyWith<CheckedInheritableLayout> get copyWith => _$CheckedInheritableLayoutCopyWithImpl<CheckedInheritableLayout>(this as CheckedInheritableLayout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CheckedInheritableLayout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckedInheritableLayout&&const DeepCollectionEquality().equals(other.nodes, _this.nodes)&&const DeepCollectionEquality().equals(other.inheritableNodes, _this.inheritableNodes)&&(identical(other.remainderCount, _this.remainderCount) || other.remainderCount == _this.remainderCount)&&const DeepCollectionEquality().equals(other.canonicalFields, _this.canonicalFields)&&const DeepCollectionEquality().equals(other.declaredParts, _this.declaredParts)&&(identical(other.diagnostic, _this.diagnostic) || other.diagnostic == _this.diagnostic));
}


@override
int get hashCode {
  final _this = this as CheckedInheritableLayout;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.nodes),const DeepCollectionEquality().hash(_this.inheritableNodes),_this.remainderCount,const DeepCollectionEquality().hash(_this.canonicalFields),const DeepCollectionEquality().hash(_this.declaredParts),_this.diagnostic);
}

@override
String toString() {
  final _this = this as CheckedInheritableLayout;
  return 'CheckedInheritableLayout(nodes: ${_this.nodes}, inheritableNodes: ${_this.inheritableNodes}, remainderCount: ${_this.remainderCount}, canonicalFields: ${_this.canonicalFields}, declaredParts: ${_this.declaredParts}, diagnostic: ${_this.diagnostic})';
}


}

/// @nodoc
abstract mixin class $CheckedInheritableLayoutCopyWith<$Res>  {
  factory $CheckedInheritableLayoutCopyWith(CheckedInheritableLayout value, $Res Function(CheckedInheritableLayout) _then) = _$CheckedInheritableLayoutCopyWithImpl;
@useResult
$Res call({
 Map<String, skir.PresentationNode> nodes, Set<String> inheritableNodes, int remainderCount, Set<String> canonicalFields, Set<skir.PresentationPartId> declaredParts, String? diagnostic
});




}
/// @nodoc
class _$CheckedInheritableLayoutCopyWithImpl<$Res>
    implements $CheckedInheritableLayoutCopyWith<$Res> {
  _$CheckedInheritableLayoutCopyWithImpl(this._self, this._then);

  final CheckedInheritableLayout _self;
  final $Res Function(CheckedInheritableLayout) _then;

/// Create a copy of CheckedInheritableLayout
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,Object? inheritableNodes = null,Object? remainderCount = null,Object? canonicalFields = null,Object? declaredParts = null,Object? diagnostic = freezed,}) {
  return _then(CheckedInheritableLayout(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,inheritableNodes: null == inheritableNodes ? _self.inheritableNodes : inheritableNodes // ignore: cast_nullable_to_non_nullable
as Set<String>,remainderCount: null == remainderCount ? _self.remainderCount : remainderCount // ignore: cast_nullable_to_non_nullable
as int,canonicalFields: null == canonicalFields ? _self.canonicalFields : canonicalFields // ignore: cast_nullable_to_non_nullable
as Set<String>,declaredParts: null == declaredParts ? _self.declaredParts : declaredParts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,diagnostic: freezed == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern matching related methods to [CheckedInheritableLayout].
extension CheckedInheritableLayoutPatterns on CheckedInheritableLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckedInheritableLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckedInheritableLayout() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckedInheritableLayout value)  $default,){
final _that = this;
switch (_that) {
case _CheckedInheritableLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckedInheritableLayout value)?  $default,){
final _that = this;
switch (_that) {
case _CheckedInheritableLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, skir.PresentationNode> nodes,  Set<String> inheritableNodes,  int remainderCount,  Set<String> canonicalFields,  Set<skir.PresentationPartId> declaredParts,  String? diagnostic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckedInheritableLayout() when $default != null:
return $default(_that.nodes,_that.inheritableNodes,_that.remainderCount,_that.canonicalFields,_that.declaredParts,_that.diagnostic);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, skir.PresentationNode> nodes,  Set<String> inheritableNodes,  int remainderCount,  Set<String> canonicalFields,  Set<skir.PresentationPartId> declaredParts,  String? diagnostic)  $default,) {final _that = this;
switch (_that) {
case _CheckedInheritableLayout():
return $default(_that.nodes,_that.inheritableNodes,_that.remainderCount,_that.canonicalFields,_that.declaredParts,_that.diagnostic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, skir.PresentationNode> nodes,  Set<String> inheritableNodes,  int remainderCount,  Set<String> canonicalFields,  Set<skir.PresentationPartId> declaredParts,  String? diagnostic)?  $default,) {final _that = this;
switch (_that) {
case _CheckedInheritableLayout() when $default != null:
return $default(_that.nodes,_that.inheritableNodes,_that.remainderCount,_that.canonicalFields,_that.declaredParts,_that.diagnostic);case _:
  return null;

}
}

}

/// @nodoc


class _CheckedInheritableLayout implements CheckedInheritableLayout {
  const _CheckedInheritableLayout({required  Map<String, skir.PresentationNode> nodes, required  Set<String> inheritableNodes, required this.remainderCount, required  Set<String> canonicalFields, required  Set<skir.PresentationPartId> declaredParts, this.diagnostic}): _nodes = nodes,_inheritableNodes = inheritableNodes,_canonicalFields = canonicalFields,_declaredParts = declaredParts;


 final  Map<String, skir.PresentationNode> _nodes;
@override Map<String, skir.PresentationNode> get nodes {
  if (_nodes is EqualUnmodifiableMapView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodes);
}

 final  Set<String> _inheritableNodes;
@override Set<String> get inheritableNodes {
  if (_inheritableNodes is EqualUnmodifiableSetView) return _inheritableNodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inheritableNodes);
}

@override final  int remainderCount;
 final  Set<String> _canonicalFields;
@override Set<String> get canonicalFields {
  if (_canonicalFields is EqualUnmodifiableSetView) return _canonicalFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_canonicalFields);
}

 final  Set<skir.PresentationPartId> _declaredParts;
@override Set<skir.PresentationPartId> get declaredParts {
  if (_declaredParts is EqualUnmodifiableSetView) return _declaredParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_declaredParts);
}

@override final  String? diagnostic;

/// Create a copy of CheckedInheritableLayout
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckedInheritableLayoutCopyWith<_CheckedInheritableLayout> get copyWith => __$CheckedInheritableLayoutCopyWithImpl<_CheckedInheritableLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckedInheritableLayout&&const DeepCollectionEquality().equals(other.nodes, _nodes)&&const DeepCollectionEquality().equals(other.inheritableNodes, _inheritableNodes)&&(identical(other.remainderCount, remainderCount) || other.remainderCount == remainderCount)&&const DeepCollectionEquality().equals(other.canonicalFields, _canonicalFields)&&const DeepCollectionEquality().equals(other.declaredParts, _declaredParts)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_inheritableNodes),remainderCount,const DeepCollectionEquality().hash(_canonicalFields),const DeepCollectionEquality().hash(_declaredParts),diagnostic);
}

@override
String toString() {
    return 'CheckedInheritableLayout(nodes: $nodes, inheritableNodes: $inheritableNodes, remainderCount: $remainderCount, canonicalFields: $canonicalFields, declaredParts: $declaredParts, diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class _$CheckedInheritableLayoutCopyWith<$Res> implements $CheckedInheritableLayoutCopyWith<$Res> {
  factory _$CheckedInheritableLayoutCopyWith(_CheckedInheritableLayout value, $Res Function(_CheckedInheritableLayout) _then) = __$CheckedInheritableLayoutCopyWithImpl;
@override @useResult
$Res call({
 Map<String, skir.PresentationNode> nodes, Set<String> inheritableNodes, int remainderCount, Set<String> canonicalFields, Set<skir.PresentationPartId> declaredParts, String? diagnostic
});




}
/// @nodoc
class __$CheckedInheritableLayoutCopyWithImpl<$Res>
    implements _$CheckedInheritableLayoutCopyWith<$Res> {
  __$CheckedInheritableLayoutCopyWithImpl(this._self, this._then);

  final _CheckedInheritableLayout _self;
  final $Res Function(_CheckedInheritableLayout) _then;

/// Create a copy of CheckedInheritableLayout
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,Object? inheritableNodes = null,Object? remainderCount = null,Object? canonicalFields = null,Object? declaredParts = null,Object? diagnostic = freezed,}) {
  return _then(_CheckedInheritableLayout(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,inheritableNodes: null == inheritableNodes ? _self._inheritableNodes : inheritableNodes // ignore: cast_nullable_to_non_nullable
as Set<String>,remainderCount: null == remainderCount ? _self.remainderCount : remainderCount // ignore: cast_nullable_to_non_nullable
as int,canonicalFields: null == canonicalFields ? _self._canonicalFields : canonicalFields // ignore: cast_nullable_to_non_nullable
as Set<String>,declaredParts: null == declaredParts ? _self._declaredParts : declaredParts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,diagnostic: freezed == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EditorInspectorLayoutSelection {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorInspectorLayoutSelection);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorInspectorLayoutSelection()';
}


}

/// @nodoc
class $EditorInspectorLayoutSelectionCopyWith<$Res>  {
$EditorInspectorLayoutSelectionCopyWith(EditorInspectorLayoutSelection _, $Res Function(EditorInspectorLayoutSelection) __);
}


/// Adds pattern matching related methods to [EditorInspectorLayoutSelection].
extension EditorInspectorLayoutSelectionPatterns on EditorInspectorLayoutSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectedEditorInspectorLayout value)?  selected,TResult Function( ConflictingEditorInspectorLayout value)?  conflicting,TResult Function( InvalidEditorInspectorLayout value)?  invalid,TResult Function( MissingEditorInspectorLayout value)?  missing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout() when selected != null:
return selected(_that);case ConflictingEditorInspectorLayout() when conflicting != null:
return conflicting(_that);case InvalidEditorInspectorLayout() when invalid != null:
return invalid(_that);case MissingEditorInspectorLayout() when missing != null:
return missing(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectedEditorInspectorLayout value)  selected,required TResult Function( ConflictingEditorInspectorLayout value)  conflicting,required TResult Function( InvalidEditorInspectorLayout value)  invalid,required TResult Function( MissingEditorInspectorLayout value)  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout():
return selected(_that);case ConflictingEditorInspectorLayout():
return conflicting(_that);case InvalidEditorInspectorLayout():
return invalid(_that);case MissingEditorInspectorLayout():
return missing(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectedEditorInspectorLayout value)?  selected,TResult? Function( ConflictingEditorInspectorLayout value)?  conflicting,TResult? Function( InvalidEditorInspectorLayout value)?  invalid,TResult? Function( MissingEditorInspectorLayout value)?  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout() when selected != null:
return selected(_that);case ConflictingEditorInspectorLayout() when conflicting != null:
return conflicting(_that);case InvalidEditorInspectorLayout() when invalid != null:
return invalid(_that);case MissingEditorInspectorLayout() when missing != null:
return missing(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PresentationDescriptor descriptor,  skir.PresentationMaterial material,  Set<String> inheritableNodes)?  selected,TResult Function( List<skir.PresentationId> candidates)?  conflicting,TResult Function( String diagnostic)?  invalid,TResult Function()?  missing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout() when selected != null:
return selected(_that.descriptor,_that.material,_that.inheritableNodes);case ConflictingEditorInspectorLayout() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorInspectorLayout() when invalid != null:
return invalid(_that.diagnostic);case MissingEditorInspectorLayout() when missing != null:
return missing();case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PresentationDescriptor descriptor,  skir.PresentationMaterial material,  Set<String> inheritableNodes)  selected,required TResult Function( List<skir.PresentationId> candidates)  conflicting,required TResult Function( String diagnostic)  invalid,required TResult Function()  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout():
return selected(_that.descriptor,_that.material,_that.inheritableNodes);case ConflictingEditorInspectorLayout():
return conflicting(_that.candidates);case InvalidEditorInspectorLayout():
return invalid(_that.diagnostic);case MissingEditorInspectorLayout():
return missing();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PresentationDescriptor descriptor,  skir.PresentationMaterial material,  Set<String> inheritableNodes)?  selected,TResult? Function( List<skir.PresentationId> candidates)?  conflicting,TResult? Function( String diagnostic)?  invalid,TResult? Function()?  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorInspectorLayout() when selected != null:
return selected(_that.descriptor,_that.material,_that.inheritableNodes);case ConflictingEditorInspectorLayout() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorInspectorLayout() when invalid != null:
return invalid(_that.diagnostic);case MissingEditorInspectorLayout() when missing != null:
return missing();case _:
  return null;

}
}

}

/// @nodoc


class SelectedEditorInspectorLayout implements EditorInspectorLayoutSelection {
  const SelectedEditorInspectorLayout({required this.descriptor, required this.material, required  Set<String> inheritableNodes}): _inheritableNodes = inheritableNodes;


 final  skir.PresentationDescriptor descriptor;
 final  skir.PresentationMaterial material;
 final  Set<String> _inheritableNodes;
 Set<String> get inheritableNodes {
  if (_inheritableNodes is EqualUnmodifiableSetView) return _inheritableNodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inheritableNodes);
}


/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedEditorInspectorLayoutCopyWith<SelectedEditorInspectorLayout> get copyWith => _$SelectedEditorInspectorLayoutCopyWithImpl<SelectedEditorInspectorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedEditorInspectorLayout&&(identical(other.descriptor, descriptor) || other.descriptor == descriptor)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.inheritableNodes, _inheritableNodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,descriptor,material,const DeepCollectionEquality().hash(_inheritableNodes));
}

@override
String toString() {
    return 'EditorInspectorLayoutSelection.selected(descriptor: $descriptor, material: $material, inheritableNodes: $inheritableNodes)';
}


}

/// @nodoc
abstract mixin class $SelectedEditorInspectorLayoutCopyWith<$Res> implements $EditorInspectorLayoutSelectionCopyWith<$Res> {
  factory $SelectedEditorInspectorLayoutCopyWith(SelectedEditorInspectorLayout value, $Res Function(SelectedEditorInspectorLayout) _then) = _$SelectedEditorInspectorLayoutCopyWithImpl;
@useResult
$Res call({
 skir.PresentationDescriptor descriptor, skir.PresentationMaterial material, Set<String> inheritableNodes
});




}
/// @nodoc
class _$SelectedEditorInspectorLayoutCopyWithImpl<$Res>
    implements $SelectedEditorInspectorLayoutCopyWith<$Res> {
  _$SelectedEditorInspectorLayoutCopyWithImpl(this._self, this._then);

  final SelectedEditorInspectorLayout _self;
  final $Res Function(SelectedEditorInspectorLayout) _then;

/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? descriptor = null,Object? material = null,Object? inheritableNodes = null,}) {
  return _then(SelectedEditorInspectorLayout(
descriptor: null == descriptor ? _self.descriptor : descriptor // ignore: cast_nullable_to_non_nullable
as skir.PresentationDescriptor,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,inheritableNodes: null == inheritableNodes ? _self._inheritableNodes : inheritableNodes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class ConflictingEditorInspectorLayout implements EditorInspectorLayoutSelection {
  const ConflictingEditorInspectorLayout({required  List<skir.PresentationId> candidates}): _candidates = candidates;


 final  List<skir.PresentationId> _candidates;
 List<skir.PresentationId> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictingEditorInspectorLayoutCopyWith<ConflictingEditorInspectorLayout> get copyWith => _$ConflictingEditorInspectorLayoutCopyWithImpl<ConflictingEditorInspectorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictingEditorInspectorLayout&&const DeepCollectionEquality().equals(other.candidates, _candidates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_candidates));
}

@override
String toString() {
    return 'EditorInspectorLayoutSelection.conflicting(candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $ConflictingEditorInspectorLayoutCopyWith<$Res> implements $EditorInspectorLayoutSelectionCopyWith<$Res> {
  factory $ConflictingEditorInspectorLayoutCopyWith(ConflictingEditorInspectorLayout value, $Res Function(ConflictingEditorInspectorLayout) _then) = _$ConflictingEditorInspectorLayoutCopyWithImpl;
@useResult
$Res call({
 List<skir.PresentationId> candidates
});




}
/// @nodoc
class _$ConflictingEditorInspectorLayoutCopyWithImpl<$Res>
    implements $ConflictingEditorInspectorLayoutCopyWith<$Res> {
  _$ConflictingEditorInspectorLayoutCopyWithImpl(this._self, this._then);

  final ConflictingEditorInspectorLayout _self;
  final $Res Function(ConflictingEditorInspectorLayout) _then;

/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidates = null,}) {
  return _then(ConflictingEditorInspectorLayout(
candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<skir.PresentationId>,
  ));
}


}

/// @nodoc


class InvalidEditorInspectorLayout implements EditorInspectorLayoutSelection {
  const InvalidEditorInspectorLayout({required this.diagnostic});


 final  String diagnostic;

/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidEditorInspectorLayoutCopyWith<InvalidEditorInspectorLayout> get copyWith => _$InvalidEditorInspectorLayoutCopyWithImpl<InvalidEditorInspectorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEditorInspectorLayout&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,diagnostic);
}

@override
String toString() {
    return 'EditorInspectorLayoutSelection.invalid(diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class $InvalidEditorInspectorLayoutCopyWith<$Res> implements $EditorInspectorLayoutSelectionCopyWith<$Res> {
  factory $InvalidEditorInspectorLayoutCopyWith(InvalidEditorInspectorLayout value, $Res Function(InvalidEditorInspectorLayout) _then) = _$InvalidEditorInspectorLayoutCopyWithImpl;
@useResult
$Res call({
 String diagnostic
});




}
/// @nodoc
class _$InvalidEditorInspectorLayoutCopyWithImpl<$Res>
    implements $InvalidEditorInspectorLayoutCopyWith<$Res> {
  _$InvalidEditorInspectorLayoutCopyWithImpl(this._self, this._then);

  final InvalidEditorInspectorLayout _self;
  final $Res Function(InvalidEditorInspectorLayout) _then;

/// Create a copy of EditorInspectorLayoutSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostic = null,}) {
  return _then(InvalidEditorInspectorLayout(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MissingEditorInspectorLayout implements EditorInspectorLayoutSelection {
  const MissingEditorInspectorLayout();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MissingEditorInspectorLayout);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorInspectorLayoutSelection.missing()';
}


}




/// @nodoc
mixin _$EditorPartDeclaration {

 skir.PresentationMaterial get material; skir.PresentationNode get body;
/// Create a copy of EditorPartDeclaration
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorPartDeclarationCopyWith<EditorPartDeclaration> get copyWith => _$EditorPartDeclarationCopyWithImpl<EditorPartDeclaration>(this as EditorPartDeclaration, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorPartDeclaration;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPartDeclaration&&(identical(other.material, _this.material) || other.material == _this.material)&&(identical(other.body, _this.body) || other.body == _this.body));
}


@override
int get hashCode {
  final _this = this as EditorPartDeclaration;
  return Object.hash(runtimeType,_this.material,_this.body);
}

@override
String toString() {
  final _this = this as EditorPartDeclaration;
  return 'EditorPartDeclaration(material: ${_this.material}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $EditorPartDeclarationCopyWith<$Res>  {
  factory $EditorPartDeclarationCopyWith(EditorPartDeclaration value, $Res Function(EditorPartDeclaration) _then) = _$EditorPartDeclarationCopyWithImpl;
@useResult
$Res call({
 skir.PresentationMaterial material, skir.PresentationNode body
});




}
/// @nodoc
class _$EditorPartDeclarationCopyWithImpl<$Res>
    implements $EditorPartDeclarationCopyWith<$Res> {
  _$EditorPartDeclarationCopyWithImpl(this._self, this._then);

  final EditorPartDeclaration _self;
  final $Res Function(EditorPartDeclaration) _then;

/// Create a copy of EditorPartDeclaration
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? material = null,Object? body = null,}) {
  return _then(EditorPartDeclaration(
material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,
  ));
}

}


/// Adds pattern matching related methods to [EditorPartDeclaration].
extension EditorPartDeclarationPatterns on EditorPartDeclaration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorPartDeclaration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorPartDeclaration() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorPartDeclaration value)  $default,){
final _that = this;
switch (_that) {
case _EditorPartDeclaration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorPartDeclaration value)?  $default,){
final _that = this;
switch (_that) {
case _EditorPartDeclaration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationMaterial material,  skir.PresentationNode body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorPartDeclaration() when $default != null:
return $default(_that.material,_that.body);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationMaterial material,  skir.PresentationNode body)  $default,) {final _that = this;
switch (_that) {
case _EditorPartDeclaration():
return $default(_that.material,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationMaterial material,  skir.PresentationNode body)?  $default,) {final _that = this;
switch (_that) {
case _EditorPartDeclaration() when $default != null:
return $default(_that.material,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _EditorPartDeclaration implements EditorPartDeclaration {
  const _EditorPartDeclaration({required this.material, required this.body});


@override final  skir.PresentationMaterial material;
@override final  skir.PresentationNode body;

/// Create a copy of EditorPartDeclaration
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorPartDeclarationCopyWith<_EditorPartDeclaration> get copyWith => __$EditorPartDeclarationCopyWithImpl<_EditorPartDeclaration>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorPartDeclaration&&(identical(other.material, material) || other.material == material)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode {
    return Object.hash(runtimeType,material,body);
}

@override
String toString() {
    return 'EditorPartDeclaration(material: $material, body: $body)';
}


}

/// @nodoc
abstract mixin class _$EditorPartDeclarationCopyWith<$Res> implements $EditorPartDeclarationCopyWith<$Res> {
  factory _$EditorPartDeclarationCopyWith(_EditorPartDeclaration value, $Res Function(_EditorPartDeclaration) _then) = __$EditorPartDeclarationCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationMaterial material, skir.PresentationNode body
});




}
/// @nodoc
class __$EditorPartDeclarationCopyWithImpl<$Res>
    implements _$EditorPartDeclarationCopyWith<$Res> {
  __$EditorPartDeclarationCopyWithImpl(this._self, this._then);

  final _EditorPartDeclaration _self;
  final $Res Function(_EditorPartDeclaration) _then;

/// Create a copy of EditorPartDeclaration
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? material = null,Object? body = null,}) {
  return _then(_EditorPartDeclaration(
material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,
  ));
}


}

/// @nodoc
mixin _$EditorPartPresentationSelection {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPartPresentationSelection);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorPartPresentationSelection()';
}


}

/// @nodoc
class $EditorPartPresentationSelectionCopyWith<$Res>  {
$EditorPartPresentationSelectionCopyWith(EditorPartPresentationSelection _, $Res Function(EditorPartPresentationSelection) __);
}


/// Adds pattern matching related methods to [EditorPartPresentationSelection].
extension EditorPartPresentationSelectionPatterns on EditorPartPresentationSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectedEditorPartPresentation value)?  selected,TResult Function( ConflictingEditorPartPresentation value)?  conflicting,TResult Function( InvalidEditorPartPresentation value)?  invalid,TResult Function( MissingEditorPartPresentation value)?  missing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectedEditorPartPresentation() when selected != null:
return selected(_that);case ConflictingEditorPartPresentation() when conflicting != null:
return conflicting(_that);case InvalidEditorPartPresentation() when invalid != null:
return invalid(_that);case MissingEditorPartPresentation() when missing != null:
return missing(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectedEditorPartPresentation value)  selected,required TResult Function( ConflictingEditorPartPresentation value)  conflicting,required TResult Function( InvalidEditorPartPresentation value)  invalid,required TResult Function( MissingEditorPartPresentation value)  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorPartPresentation():
return selected(_that);case ConflictingEditorPartPresentation():
return conflicting(_that);case InvalidEditorPartPresentation():
return invalid(_that);case MissingEditorPartPresentation():
return missing(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectedEditorPartPresentation value)?  selected,TResult? Function( ConflictingEditorPartPresentation value)?  conflicting,TResult? Function( InvalidEditorPartPresentation value)?  invalid,TResult? Function( MissingEditorPartPresentation value)?  missing,}){
final _that = this;
switch (_that) {
case SelectedEditorPartPresentation() when selected != null:
return selected(_that);case ConflictingEditorPartPresentation() when conflicting != null:
return conflicting(_that);case InvalidEditorPartPresentation() when invalid != null:
return invalid(_that);case MissingEditorPartPresentation() when missing != null:
return missing(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PresentationPartId key,  skir.PresentationMaterial material,  skir.PresentationNode body,  Set<String> editedFields,  Set<String> fallbackFields,  Set<skir.PresentationPartId> claimedParts)?  selected,TResult Function( List<skir.PresentationId> candidates)?  conflicting,TResult Function( String diagnostic)?  invalid,TResult Function()?  missing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectedEditorPartPresentation() when selected != null:
return selected(_that.key,_that.material,_that.body,_that.editedFields,_that.fallbackFields,_that.claimedParts);case ConflictingEditorPartPresentation() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorPartPresentation() when invalid != null:
return invalid(_that.diagnostic);case MissingEditorPartPresentation() when missing != null:
return missing();case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PresentationPartId key,  skir.PresentationMaterial material,  skir.PresentationNode body,  Set<String> editedFields,  Set<String> fallbackFields,  Set<skir.PresentationPartId> claimedParts)  selected,required TResult Function( List<skir.PresentationId> candidates)  conflicting,required TResult Function( String diagnostic)  invalid,required TResult Function()  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorPartPresentation():
return selected(_that.key,_that.material,_that.body,_that.editedFields,_that.fallbackFields,_that.claimedParts);case ConflictingEditorPartPresentation():
return conflicting(_that.candidates);case InvalidEditorPartPresentation():
return invalid(_that.diagnostic);case MissingEditorPartPresentation():
return missing();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PresentationPartId key,  skir.PresentationMaterial material,  skir.PresentationNode body,  Set<String> editedFields,  Set<String> fallbackFields,  Set<skir.PresentationPartId> claimedParts)?  selected,TResult? Function( List<skir.PresentationId> candidates)?  conflicting,TResult? Function( String diagnostic)?  invalid,TResult? Function()?  missing,}) {final _that = this;
switch (_that) {
case SelectedEditorPartPresentation() when selected != null:
return selected(_that.key,_that.material,_that.body,_that.editedFields,_that.fallbackFields,_that.claimedParts);case ConflictingEditorPartPresentation() when conflicting != null:
return conflicting(_that.candidates);case InvalidEditorPartPresentation() when invalid != null:
return invalid(_that.diagnostic);case MissingEditorPartPresentation() when missing != null:
return missing();case _:
  return null;

}
}

}

/// @nodoc


class SelectedEditorPartPresentation implements EditorPartPresentationSelection {
  const SelectedEditorPartPresentation({required this.key, required this.material, required this.body, required  Set<String> editedFields, required  Set<String> fallbackFields, required  Set<skir.PresentationPartId> claimedParts}): _editedFields = editedFields,_fallbackFields = fallbackFields,_claimedParts = claimedParts;


 final  skir.PresentationPartId key;
 final  skir.PresentationMaterial material;
 final  skir.PresentationNode body;
 final  Set<String> _editedFields;
 Set<String> get editedFields {
  if (_editedFields is EqualUnmodifiableSetView) return _editedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_editedFields);
}

 final  Set<String> _fallbackFields;
 Set<String> get fallbackFields {
  if (_fallbackFields is EqualUnmodifiableSetView) return _fallbackFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_fallbackFields);
}

 final  Set<skir.PresentationPartId> _claimedParts;
 Set<skir.PresentationPartId> get claimedParts {
  if (_claimedParts is EqualUnmodifiableSetView) return _claimedParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_claimedParts);
}


/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedEditorPartPresentationCopyWith<SelectedEditorPartPresentation> get copyWith => _$SelectedEditorPartPresentationCopyWithImpl<SelectedEditorPartPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedEditorPartPresentation&&(identical(other.key, key) || other.key == key)&&(identical(other.material, material) || other.material == material)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.editedFields, _editedFields)&&const DeepCollectionEquality().equals(other.fallbackFields, _fallbackFields)&&const DeepCollectionEquality().equals(other.claimedParts, _claimedParts));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,material,body,const DeepCollectionEquality().hash(_editedFields),const DeepCollectionEquality().hash(_fallbackFields),const DeepCollectionEquality().hash(_claimedParts));
}

@override
String toString() {
    return 'EditorPartPresentationSelection.selected(key: $key, material: $material, body: $body, editedFields: $editedFields, fallbackFields: $fallbackFields, claimedParts: $claimedParts)';
}


}

/// @nodoc
abstract mixin class $SelectedEditorPartPresentationCopyWith<$Res> implements $EditorPartPresentationSelectionCopyWith<$Res> {
  factory $SelectedEditorPartPresentationCopyWith(SelectedEditorPartPresentation value, $Res Function(SelectedEditorPartPresentation) _then) = _$SelectedEditorPartPresentationCopyWithImpl;
@useResult
$Res call({
 skir.PresentationPartId key, skir.PresentationMaterial material, skir.PresentationNode body, Set<String> editedFields, Set<String> fallbackFields, Set<skir.PresentationPartId> claimedParts
});




}
/// @nodoc
class _$SelectedEditorPartPresentationCopyWithImpl<$Res>
    implements $SelectedEditorPartPresentationCopyWith<$Res> {
  _$SelectedEditorPartPresentationCopyWithImpl(this._self, this._then);

  final SelectedEditorPartPresentation _self;
  final $Res Function(SelectedEditorPartPresentation) _then;

/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? material = null,Object? body = null,Object? editedFields = null,Object? fallbackFields = null,Object? claimedParts = null,}) {
  return _then(SelectedEditorPartPresentation(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartId,material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,editedFields: null == editedFields ? _self._editedFields : editedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,fallbackFields: null == fallbackFields ? _self._fallbackFields : fallbackFields // ignore: cast_nullable_to_non_nullable
as Set<String>,claimedParts: null == claimedParts ? _self._claimedParts : claimedParts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,
  ));
}


}

/// @nodoc


class ConflictingEditorPartPresentation implements EditorPartPresentationSelection {
  const ConflictingEditorPartPresentation({required  List<skir.PresentationId> candidates}): _candidates = candidates;


 final  List<skir.PresentationId> _candidates;
 List<skir.PresentationId> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictingEditorPartPresentationCopyWith<ConflictingEditorPartPresentation> get copyWith => _$ConflictingEditorPartPresentationCopyWithImpl<ConflictingEditorPartPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictingEditorPartPresentation&&const DeepCollectionEquality().equals(other.candidates, _candidates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_candidates));
}

@override
String toString() {
    return 'EditorPartPresentationSelection.conflicting(candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $ConflictingEditorPartPresentationCopyWith<$Res> implements $EditorPartPresentationSelectionCopyWith<$Res> {
  factory $ConflictingEditorPartPresentationCopyWith(ConflictingEditorPartPresentation value, $Res Function(ConflictingEditorPartPresentation) _then) = _$ConflictingEditorPartPresentationCopyWithImpl;
@useResult
$Res call({
 List<skir.PresentationId> candidates
});




}
/// @nodoc
class _$ConflictingEditorPartPresentationCopyWithImpl<$Res>
    implements $ConflictingEditorPartPresentationCopyWith<$Res> {
  _$ConflictingEditorPartPresentationCopyWithImpl(this._self, this._then);

  final ConflictingEditorPartPresentation _self;
  final $Res Function(ConflictingEditorPartPresentation) _then;

/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidates = null,}) {
  return _then(ConflictingEditorPartPresentation(
candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<skir.PresentationId>,
  ));
}


}

/// @nodoc


class InvalidEditorPartPresentation implements EditorPartPresentationSelection {
  const InvalidEditorPartPresentation({required this.diagnostic});


 final  String diagnostic;

/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidEditorPartPresentationCopyWith<InvalidEditorPartPresentation> get copyWith => _$InvalidEditorPartPresentationCopyWithImpl<InvalidEditorPartPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEditorPartPresentation&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,diagnostic);
}

@override
String toString() {
    return 'EditorPartPresentationSelection.invalid(diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class $InvalidEditorPartPresentationCopyWith<$Res> implements $EditorPartPresentationSelectionCopyWith<$Res> {
  factory $InvalidEditorPartPresentationCopyWith(InvalidEditorPartPresentation value, $Res Function(InvalidEditorPartPresentation) _then) = _$InvalidEditorPartPresentationCopyWithImpl;
@useResult
$Res call({
 String diagnostic
});




}
/// @nodoc
class _$InvalidEditorPartPresentationCopyWithImpl<$Res>
    implements $InvalidEditorPartPresentationCopyWith<$Res> {
  _$InvalidEditorPartPresentationCopyWithImpl(this._self, this._then);

  final InvalidEditorPartPresentation _self;
  final $Res Function(InvalidEditorPartPresentation) _then;

/// Create a copy of EditorPartPresentationSelection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostic = null,}) {
  return _then(InvalidEditorPartPresentation(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MissingEditorPartPresentation implements EditorPartPresentationSelection {
  const MissingEditorPartPresentation();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MissingEditorPartPresentation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorPartPresentationSelection.missing()';
}


}




// dart format on
