// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorSelection {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorSelection);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditorSelection()';
}


}

/// @nodoc
class $EditorSelectionCopyWith<$Res>  {
$EditorSelectionCopyWith(EditorSelection _, $Res Function(EditorSelection) __);
}


/// Adds pattern-matching-related methods to [EditorSelection].
extension EditorSelectionPatterns on EditorSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadyEditorSelection value)?  ready,TResult Function( FailedEditorSelection value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadyEditorSelection() when ready != null:
return ready(_that);case FailedEditorSelection() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadyEditorSelection value)  ready,required TResult Function( FailedEditorSelection value)  failed,}){
final _that = this;
switch (_that) {
case ReadyEditorSelection():
return ready(_that);case FailedEditorSelection():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadyEditorSelection value)?  ready,TResult? Function( FailedEditorSelection value)?  failed,}){
final _that = this;
switch (_that) {
case ReadyEditorSelection() when ready != null:
return ready(_that);case FailedEditorSelection() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PresentationNode node,  PortablePresentationScope scope,  ResolvedFieldAssociation? fieldAssociation,  ScopedEditorGuidance? guidance)?  ready,TResult Function( String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadyEditorSelection() when ready != null:
return ready(_that.node,_that.scope,_that.fieldAssociation,_that.guidance);case FailedEditorSelection() when failed != null:
return failed(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PresentationNode node,  PortablePresentationScope scope,  ResolvedFieldAssociation? fieldAssociation,  ScopedEditorGuidance? guidance)  ready,required TResult Function( String message)  failed,}) {final _that = this;
switch (_that) {
case ReadyEditorSelection():
return ready(_that.node,_that.scope,_that.fieldAssociation,_that.guidance);case FailedEditorSelection():
return failed(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PresentationNode node,  PortablePresentationScope scope,  ResolvedFieldAssociation? fieldAssociation,  ScopedEditorGuidance? guidance)?  ready,TResult? Function( String message)?  failed,}) {final _that = this;
switch (_that) {
case ReadyEditorSelection() when ready != null:
return ready(_that.node,_that.scope,_that.fieldAssociation,_that.guidance);case FailedEditorSelection() when failed != null:
return failed(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ReadyEditorSelection implements EditorSelection {
  const ReadyEditorSelection({required this.node, required this.scope, this.fieldAssociation, this.guidance});
  

 final  skir.PresentationNode node;
 final  PortablePresentationScope scope;
 final  ResolvedFieldAssociation? fieldAssociation;
 final  ScopedEditorGuidance? guidance;

/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadyEditorSelectionCopyWith<ReadyEditorSelection> get copyWith => _$ReadyEditorSelectionCopyWithImpl<ReadyEditorSelection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadyEditorSelection&&(identical(other.node, node) || other.node == node)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.fieldAssociation, fieldAssociation) || other.fieldAssociation == fieldAssociation)&&(identical(other.guidance, guidance) || other.guidance == guidance));
}


@override
int get hashCode {
    return Object.hash(runtimeType,node,scope,fieldAssociation,guidance);
}

@override
String toString() {
    return 'EditorSelection.ready(node: $node, scope: $scope, fieldAssociation: $fieldAssociation, guidance: $guidance)';
}


}

/// @nodoc
abstract mixin class $ReadyEditorSelectionCopyWith<$Res> implements $EditorSelectionCopyWith<$Res> {
  factory $ReadyEditorSelectionCopyWith(ReadyEditorSelection value, $Res Function(ReadyEditorSelection) _then) = _$ReadyEditorSelectionCopyWithImpl;
@useResult
$Res call({
 skir.PresentationNode node, PortablePresentationScope scope, ResolvedFieldAssociation? fieldAssociation, ScopedEditorGuidance? guidance
});


$PortablePresentationScopeCopyWith<$Res> get scope;$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation;$ScopedEditorGuidanceCopyWith<$Res>? get guidance;

}
/// @nodoc
class _$ReadyEditorSelectionCopyWithImpl<$Res>
    implements $ReadyEditorSelectionCopyWith<$Res> {
  _$ReadyEditorSelectionCopyWithImpl(this._self, this._then);

  final ReadyEditorSelection _self;
  final $Res Function(ReadyEditorSelection) _then;

/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? node = null,Object? scope = null,Object? fieldAssociation = freezed,Object? guidance = freezed,}) {
  return _then(ReadyEditorSelection(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,fieldAssociation: freezed == fieldAssociation ? _self.fieldAssociation : fieldAssociation // ignore: cast_nullable_to_non_nullable
as ResolvedFieldAssociation?,guidance: freezed == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as ScopedEditorGuidance?,
  ));
}

/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation {
    if (_self.fieldAssociation == null) {
    return null;
  }

  return $ResolvedFieldAssociationCopyWith<$Res>(_self.fieldAssociation!, (value) {
    return _then(_self.copyWith(fieldAssociation: value));
  });
}/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopedEditorGuidanceCopyWith<$Res>? get guidance {
    if (_self.guidance == null) {
    return null;
  }

  return $ScopedEditorGuidanceCopyWith<$Res>(_self.guidance!, (value) {
    return _then(_self.copyWith(guidance: value));
  });
}
}

/// @nodoc


class FailedEditorSelection implements EditorSelection {
  const FailedEditorSelection(this.message);
  

 final  String message;

/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedEditorSelectionCopyWith<FailedEditorSelection> get copyWith => _$FailedEditorSelectionCopyWithImpl<FailedEditorSelection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedEditorSelection&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'EditorSelection.failed(message: $message)';
}


}

/// @nodoc
abstract mixin class $FailedEditorSelectionCopyWith<$Res> implements $EditorSelectionCopyWith<$Res> {
  factory $FailedEditorSelectionCopyWith(FailedEditorSelection value, $Res Function(FailedEditorSelection) _then) = _$FailedEditorSelectionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$FailedEditorSelectionCopyWithImpl<$Res>
    implements $FailedEditorSelectionCopyWith<$Res> {
  _$FailedEditorSelectionCopyWithImpl(this._self, this._then);

  final FailedEditorSelection _self;
  final $Res Function(FailedEditorSelection) _then;

/// Create a copy of EditorSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(FailedEditorSelection(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ScopedEditorGuidance {

 skir.BoundControl get control; PortablePresentationScope get scope;
/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopedEditorGuidanceCopyWith<ScopedEditorGuidance> get copyWith => _$ScopedEditorGuidanceCopyWithImpl<ScopedEditorGuidance>(this as ScopedEditorGuidance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScopedEditorGuidance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopedEditorGuidance&&(identical(other.control, _this.control) || other.control == _this.control)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as ScopedEditorGuidance;
  return Object.hash(runtimeType,_this.control,_this.scope);
}

@override
String toString() {
  final _this = this as ScopedEditorGuidance;
  return 'ScopedEditorGuidance(control: ${_this.control}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $ScopedEditorGuidanceCopyWith<$Res>  {
  factory $ScopedEditorGuidanceCopyWith(ScopedEditorGuidance value, $Res Function(ScopedEditorGuidance) _then) = _$ScopedEditorGuidanceCopyWithImpl;
@useResult
$Res call({
 skir.BoundControl control, PortablePresentationScope scope
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$ScopedEditorGuidanceCopyWithImpl<$Res>
    implements $ScopedEditorGuidanceCopyWith<$Res> {
  _$ScopedEditorGuidanceCopyWithImpl(this._self, this._then);

  final ScopedEditorGuidance _self;
  final $Res Function(ScopedEditorGuidance) _then;

/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? control = null,Object? scope = null,}) {
  return _then(ScopedEditorGuidance(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as skir.BoundControl,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScopedEditorGuidance].
extension ScopedEditorGuidancePatterns on ScopedEditorGuidance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScopedEditorGuidance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScopedEditorGuidance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScopedEditorGuidance value)  $default,){
final _that = this;
switch (_that) {
case _ScopedEditorGuidance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScopedEditorGuidance value)?  $default,){
final _that = this;
switch (_that) {
case _ScopedEditorGuidance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.BoundControl control,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScopedEditorGuidance() when $default != null:
return $default(_that.control,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.BoundControl control,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case _ScopedEditorGuidance():
return $default(_that.control,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.BoundControl control,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case _ScopedEditorGuidance() when $default != null:
return $default(_that.control,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _ScopedEditorGuidance extends ScopedEditorGuidance {
  const _ScopedEditorGuidance({required this.control, required this.scope}): super._();
  

@override final  skir.BoundControl control;
@override final  PortablePresentationScope scope;

/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopedEditorGuidanceCopyWith<_ScopedEditorGuidance> get copyWith => __$ScopedEditorGuidanceCopyWithImpl<_ScopedEditorGuidance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopedEditorGuidance&&(identical(other.control, control) || other.control == control)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,control,scope);
}

@override
String toString() {
    return 'ScopedEditorGuidance(control: $control, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$ScopedEditorGuidanceCopyWith<$Res> implements $ScopedEditorGuidanceCopyWith<$Res> {
  factory _$ScopedEditorGuidanceCopyWith(_ScopedEditorGuidance value, $Res Function(_ScopedEditorGuidance) _then) = __$ScopedEditorGuidanceCopyWithImpl;
@override @useResult
$Res call({
 skir.BoundControl control, PortablePresentationScope scope
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$ScopedEditorGuidanceCopyWithImpl<$Res>
    implements _$ScopedEditorGuidanceCopyWith<$Res> {
  __$ScopedEditorGuidanceCopyWithImpl(this._self, this._then);

  final _ScopedEditorGuidance _self;
  final $Res Function(_ScopedEditorGuidance) _then;

/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? control = null,Object? scope = null,}) {
  return _then(_ScopedEditorGuidance(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as skir.BoundControl,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of ScopedEditorGuidance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$ScopedCollectionHeader {

 PortablePresentationScope get scope; skir.PresentationHeader? get header; List<_SuppliedHeaderControl> get controls;
/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopedCollectionHeaderCopyWith<_ScopedCollectionHeader> get copyWith => __$ScopedCollectionHeaderCopyWithImpl<_ScopedCollectionHeader>(this as _ScopedCollectionHeader, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _ScopedCollectionHeader;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopedCollectionHeader&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.header, _this.header) || other.header == _this.header)&&const DeepCollectionEquality().equals(other.controls, _this.controls));
}


@override
int get hashCode {
  final _this = this as _ScopedCollectionHeader;
  return Object.hash(runtimeType,_this.scope,_this.header,const DeepCollectionEquality().hash(_this.controls));
}

@override
String toString() {
  final _this = this as _ScopedCollectionHeader;
  return '_ScopedCollectionHeader(scope: ${_this.scope}, header: ${_this.header}, controls: ${_this.controls})';
}


}

/// @nodoc
abstract mixin class _$ScopedCollectionHeaderCopyWith<$Res>  {
  factory _$ScopedCollectionHeaderCopyWith(_ScopedCollectionHeader value, $Res Function(_ScopedCollectionHeader) _then) = __$ScopedCollectionHeaderCopyWithImpl;
@useResult
$Res call({
 PortablePresentationScope scope, skir.PresentationHeader? header, List<_SuppliedHeaderControl> controls
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$ScopedCollectionHeaderCopyWithImpl<$Res>
    implements _$ScopedCollectionHeaderCopyWith<$Res> {
  __$ScopedCollectionHeaderCopyWithImpl(this._self, this._then);

  final _ScopedCollectionHeader _self;
  final $Res Function(_ScopedCollectionHeader) _then;

/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? header = freezed,Object? controls = null,}) {
  return _then(_ScopedCollectionHeader(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as skir.PresentationHeader?,controls: null == controls ? _self.controls : controls // ignore: cast_nullable_to_non_nullable
as List<_SuppliedHeaderControl>,
  ));
}
/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [_ScopedCollectionHeader].
extension _ScopedCollectionHeaderPatterns on _ScopedCollectionHeader {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __ScopedCollectionHeader value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __ScopedCollectionHeader() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __ScopedCollectionHeader value)  $default,){
final _that = this;
switch (_that) {
case __ScopedCollectionHeader():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __ScopedCollectionHeader value)?  $default,){
final _that = this;
switch (_that) {
case __ScopedCollectionHeader() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortablePresentationScope scope,  skir.PresentationHeader? header,  List<_SuppliedHeaderControl> controls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __ScopedCollectionHeader() when $default != null:
return $default(_that.scope,_that.header,_that.controls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortablePresentationScope scope,  skir.PresentationHeader? header,  List<_SuppliedHeaderControl> controls)  $default,) {final _that = this;
switch (_that) {
case __ScopedCollectionHeader():
return $default(_that.scope,_that.header,_that.controls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortablePresentationScope scope,  skir.PresentationHeader? header,  List<_SuppliedHeaderControl> controls)?  $default,) {final _that = this;
switch (_that) {
case __ScopedCollectionHeader() when $default != null:
return $default(_that.scope,_that.header,_that.controls);case _:
  return null;

}
}

}

/// @nodoc


class __ScopedCollectionHeader implements _ScopedCollectionHeader {
  const __ScopedCollectionHeader({required this.scope, this.header,  List<_SuppliedHeaderControl> controls = const []}): _controls = controls;
  

@override final  PortablePresentationScope scope;
@override final  skir.PresentationHeader? header;
 final  List<_SuppliedHeaderControl> _controls;
@override@JsonKey() List<_SuppliedHeaderControl> get controls {
  if (_controls is EqualUnmodifiableListView) return _controls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_controls);
}


/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_ScopedCollectionHeaderCopyWith<__ScopedCollectionHeader> get copyWith => __$_ScopedCollectionHeaderCopyWithImpl<__ScopedCollectionHeader>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __ScopedCollectionHeader&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.header, header) || other.header == header)&&const DeepCollectionEquality().equals(other.controls, _controls));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scope,header,const DeepCollectionEquality().hash(_controls));
}

@override
String toString() {
    return '_ScopedCollectionHeader(scope: $scope, header: $header, controls: $controls)';
}


}

/// @nodoc
abstract mixin class _$_ScopedCollectionHeaderCopyWith<$Res> implements _$ScopedCollectionHeaderCopyWith<$Res> {
  factory _$_ScopedCollectionHeaderCopyWith(__ScopedCollectionHeader value, $Res Function(__ScopedCollectionHeader) _then) = __$_ScopedCollectionHeaderCopyWithImpl;
@override @useResult
$Res call({
 PortablePresentationScope scope, skir.PresentationHeader? header, List<_SuppliedHeaderControl> controls
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$_ScopedCollectionHeaderCopyWithImpl<$Res>
    implements _$_ScopedCollectionHeaderCopyWith<$Res> {
  __$_ScopedCollectionHeaderCopyWithImpl(this._self, this._then);

  final __ScopedCollectionHeader _self;
  final $Res Function(__ScopedCollectionHeader) _then;

/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? header = freezed,Object? controls = null,}) {
  return _then(__ScopedCollectionHeader(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as skir.PresentationHeader?,controls: null == controls ? _self._controls : controls // ignore: cast_nullable_to_non_nullable
as List<_SuppliedHeaderControl>,
  ));
}

/// Create a copy of _ScopedCollectionHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$CollectionEditorContinuation {

 AuthoredBindingAddress get owner; PortablePresentationScope get scope; CollectionEntryLayout get layout; Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) get render; Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? get renderIntrinsicBody;
/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionEditorContinuationCopyWith<_CollectionEditorContinuation> get copyWith => __$CollectionEditorContinuationCopyWithImpl<_CollectionEditorContinuation>(this as _CollectionEditorContinuation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionEditorContinuation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionEditorContinuation&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.layout, _this.layout) || other.layout == _this.layout)&&(identical(other.render, _this.render) || other.render == _this.render)&&(identical(other.renderIntrinsicBody, _this.renderIntrinsicBody) || other.renderIntrinsicBody == _this.renderIntrinsicBody));
}


@override
int get hashCode {
  final _this = this as _CollectionEditorContinuation;
  return Object.hash(runtimeType,_this.owner,_this.scope,_this.layout,_this.render,_this.renderIntrinsicBody);
}

@override
String toString() {
  final _this = this as _CollectionEditorContinuation;
  return '_CollectionEditorContinuation(owner: ${_this.owner}, scope: ${_this.scope}, layout: ${_this.layout}, render: ${_this.render}, renderIntrinsicBody: ${_this.renderIntrinsicBody})';
}


}

/// @nodoc
abstract mixin class _$CollectionEditorContinuationCopyWith<$Res>  {
  factory _$CollectionEditorContinuationCopyWith(_CollectionEditorContinuation value, $Res Function(_CollectionEditorContinuation) _then) = __$CollectionEditorContinuationCopyWithImpl;
@useResult
$Res call({
 AuthoredBindingAddress owner, PortablePresentationScope scope, CollectionEntryLayout layout, Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render, Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody
});


$AuthoredBindingAddressCopyWith<$Res> get owner;$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$CollectionEditorContinuationCopyWithImpl<$Res>
    implements _$CollectionEditorContinuationCopyWith<$Res> {
  __$CollectionEditorContinuationCopyWithImpl(this._self, this._then);

  final _CollectionEditorContinuation _self;
  final $Res Function(_CollectionEditorContinuation) _then;

/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? scope = null,Object? layout = null,Object? render = null,Object? renderIntrinsicBody = freezed,}) {
  return _then(_CollectionEditorContinuation(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as CollectionEntryLayout,render: null == render ? _self.render : render // ignore: cast_nullable_to_non_nullable
as Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?),renderIntrinsicBody: freezed == renderIntrinsicBody ? _self.renderIntrinsicBody : renderIntrinsicBody // ignore: cast_nullable_to_non_nullable
as Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))?,
  ));
}
/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [_CollectionEditorContinuation].
extension _CollectionEditorContinuationPatterns on _CollectionEditorContinuation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionEditorContinuation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionEditorContinuation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionEditorContinuation value)  $default,){
final _that = this;
switch (_that) {
case __CollectionEditorContinuation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionEditorContinuation value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionEditorContinuation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  PortablePresentationScope scope,  CollectionEntryLayout layout,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionEditorContinuation() when $default != null:
return $default(_that.owner,_that.scope,_that.layout,_that.render,_that.renderIntrinsicBody);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  PortablePresentationScope scope,  CollectionEntryLayout layout,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody)  $default,) {final _that = this;
switch (_that) {
case __CollectionEditorContinuation():
return $default(_that.owner,_that.scope,_that.layout,_that.render,_that.renderIntrinsicBody);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoredBindingAddress owner,  PortablePresentationScope scope,  CollectionEntryLayout layout,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render,  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody)?  $default,) {final _that = this;
switch (_that) {
case __CollectionEditorContinuation() when $default != null:
return $default(_that.owner,_that.scope,_that.layout,_that.render,_that.renderIntrinsicBody);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionEditorContinuation extends _CollectionEditorContinuation {
  const __CollectionEditorContinuation({required this.owner, required this.scope, required this.layout, required this.render, this.renderIntrinsicBody}): super._();
  

@override final  AuthoredBindingAddress owner;
@override final  PortablePresentationScope scope;
@override final  CollectionEntryLayout layout;
@override final  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render;
@override final  Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody;

/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionEditorContinuationCopyWith<__CollectionEditorContinuation> get copyWith => __$_CollectionEditorContinuationCopyWithImpl<__CollectionEditorContinuation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionEditorContinuation&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.render, render) || other.render == render)&&(identical(other.renderIntrinsicBody, renderIntrinsicBody) || other.renderIntrinsicBody == renderIntrinsicBody));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,scope,layout,render,renderIntrinsicBody);
}

@override
String toString() {
    return '_CollectionEditorContinuation(owner: $owner, scope: $scope, layout: $layout, render: $render, renderIntrinsicBody: $renderIntrinsicBody)';
}


}

/// @nodoc
abstract mixin class _$_CollectionEditorContinuationCopyWith<$Res> implements _$CollectionEditorContinuationCopyWith<$Res> {
  factory _$_CollectionEditorContinuationCopyWith(__CollectionEditorContinuation value, $Res Function(__CollectionEditorContinuation) _then) = __$_CollectionEditorContinuationCopyWithImpl;
@override @useResult
$Res call({
 AuthoredBindingAddress owner, PortablePresentationScope scope, CollectionEntryLayout layout, Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?) render, Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))? renderIntrinsicBody
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$_CollectionEditorContinuationCopyWithImpl<$Res>
    implements _$_CollectionEditorContinuationCopyWith<$Res> {
  __$_CollectionEditorContinuationCopyWithImpl(this._self, this._then);

  final __CollectionEditorContinuation _self;
  final $Res Function(__CollectionEditorContinuation) _then;

/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? scope = null,Object? layout = null,Object? render = null,Object? renderIntrinsicBody = freezed,}) {
  return _then(__CollectionEditorContinuation(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as CollectionEntryLayout,render: null == render ? _self.render : render // ignore: cast_nullable_to_non_nullable
as Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget)?),renderIntrinsicBody: freezed == renderIntrinsicBody ? _self.renderIntrinsicBody : renderIntrinsicBody // ignore: cast_nullable_to_non_nullable
as Widget Function(BuildContext, Widget Function(_ScopedCollectionHeader, Widget))?,
  ));
}

/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of _CollectionEditorContinuation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$PreparedNode {

 PortablePresentationScope get scope; bool get available;
/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedNodeCopyWith<PreparedNode> get copyWith => _$PreparedNodeCopyWithImpl<PreparedNode>(this as PreparedNode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PreparedNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedNode&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.available, _this.available) || other.available == _this.available));
}


@override
int get hashCode {
  final _this = this as PreparedNode;
  return Object.hash(runtimeType,_this.scope,_this.available);
}

@override
String toString() {
  final _this = this as PreparedNode;
  return 'PreparedNode(scope: ${_this.scope}, available: ${_this.available})';
}


}

/// @nodoc
abstract mixin class $PreparedNodeCopyWith<$Res>  {
  factory $PreparedNodeCopyWith(PreparedNode value, $Res Function(PreparedNode) _then) = _$PreparedNodeCopyWithImpl;
@useResult
$Res call({
 PortablePresentationScope scope, bool available
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$PreparedNodeCopyWithImpl<$Res>
    implements $PreparedNodeCopyWith<$Res> {
  _$PreparedNodeCopyWithImpl(this._self, this._then);

  final PreparedNode _self;
  final $Res Function(PreparedNode) _then;

/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? available = null,}) {
  return _then(PreparedNode(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [PreparedNode].
extension PreparedNodePatterns on PreparedNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreparedNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreparedNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreparedNode value)  $default,){
final _that = this;
switch (_that) {
case _PreparedNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreparedNode value)?  $default,){
final _that = this;
switch (_that) {
case _PreparedNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortablePresentationScope scope,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreparedNode() when $default != null:
return $default(_that.scope,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortablePresentationScope scope,  bool available)  $default,) {final _that = this;
switch (_that) {
case _PreparedNode():
return $default(_that.scope,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortablePresentationScope scope,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _PreparedNode() when $default != null:
return $default(_that.scope,_that.available);case _:
  return null;

}
}

}

/// @nodoc


class _PreparedNode implements PreparedNode {
  const _PreparedNode({required this.scope, required this.available});
  

@override final  PortablePresentationScope scope;
@override final  bool available;

/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreparedNodeCopyWith<_PreparedNode> get copyWith => __$PreparedNodeCopyWithImpl<_PreparedNode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreparedNode&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.available, available) || other.available == available));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scope,available);
}

@override
String toString() {
    return 'PreparedNode(scope: $scope, available: $available)';
}


}

/// @nodoc
abstract mixin class _$PreparedNodeCopyWith<$Res> implements $PreparedNodeCopyWith<$Res> {
  factory _$PreparedNodeCopyWith(_PreparedNode value, $Res Function(_PreparedNode) _then) = __$PreparedNodeCopyWithImpl;
@override @useResult
$Res call({
 PortablePresentationScope scope, bool available
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$PreparedNodeCopyWithImpl<$Res>
    implements _$PreparedNodeCopyWith<$Res> {
  __$PreparedNodeCopyWithImpl(this._self, this._then);

  final _PreparedNode _self;
  final $Res Function(_PreparedNode) _then;

/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? available = null,}) {
  return _then(_PreparedNode(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PreparedNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$CollectionCommand {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionCommand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return '_CollectionCommand()';
}


}

/// @nodoc
class _$CollectionCommandCopyWith<$Res>  {
_$CollectionCommandCopyWith(_CollectionCommand _, $Res Function(_CollectionCommand) __);
}


/// Adds pattern-matching-related methods to [_CollectionCommand].
extension _CollectionCommandPatterns on _CollectionCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _RemoveListCommand value)?  removeList,TResult Function( _RemoveMapCommand value)?  removeMap,TResult Function( _ReorderCommand value)?  reorder,TResult Function( _DisconnectCommand value)?  disconnect,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoveListCommand() when removeList != null:
return removeList(_that);case _RemoveMapCommand() when removeMap != null:
return removeMap(_that);case _ReorderCommand() when reorder != null:
return reorder(_that);case _DisconnectCommand() when disconnect != null:
return disconnect(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _RemoveListCommand value)  removeList,required TResult Function( _RemoveMapCommand value)  removeMap,required TResult Function( _ReorderCommand value)  reorder,required TResult Function( _DisconnectCommand value)  disconnect,}){
final _that = this;
switch (_that) {
case _RemoveListCommand():
return removeList(_that);case _RemoveMapCommand():
return removeMap(_that);case _ReorderCommand():
return reorder(_that);case _DisconnectCommand():
return disconnect(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _RemoveListCommand value)?  removeList,TResult? Function( _RemoveMapCommand value)?  removeMap,TResult? Function( _ReorderCommand value)?  reorder,TResult? Function( _DisconnectCommand value)?  disconnect,}){
final _that = this;
switch (_that) {
case _RemoveListCommand() when removeList != null:
return removeList(_that);case _RemoveMapCommand() when removeMap != null:
return removeMap(_that);case _ReorderCommand() when reorder != null:
return reorder(_that);case _DisconnectCommand() when disconnect != null:
return disconnect(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PortableDiagnosticTarget target,  skir.ItemId item)?  removeList,TResult Function( PortableDiagnosticTarget target,  skir.ItemId row)?  removeMap,TResult Function( PortableDiagnosticTarget item)?  reorder,TResult Function( skir.LinkOccurrence occurrence)?  disconnect,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoveListCommand() when removeList != null:
return removeList(_that.target,_that.item);case _RemoveMapCommand() when removeMap != null:
return removeMap(_that.target,_that.row);case _ReorderCommand() when reorder != null:
return reorder(_that.item);case _DisconnectCommand() when disconnect != null:
return disconnect(_that.occurrence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PortableDiagnosticTarget target,  skir.ItemId item)  removeList,required TResult Function( PortableDiagnosticTarget target,  skir.ItemId row)  removeMap,required TResult Function( PortableDiagnosticTarget item)  reorder,required TResult Function( skir.LinkOccurrence occurrence)  disconnect,}) {final _that = this;
switch (_that) {
case _RemoveListCommand():
return removeList(_that.target,_that.item);case _RemoveMapCommand():
return removeMap(_that.target,_that.row);case _ReorderCommand():
return reorder(_that.item);case _DisconnectCommand():
return disconnect(_that.occurrence);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PortableDiagnosticTarget target,  skir.ItemId item)?  removeList,TResult? Function( PortableDiagnosticTarget target,  skir.ItemId row)?  removeMap,TResult? Function( PortableDiagnosticTarget item)?  reorder,TResult? Function( skir.LinkOccurrence occurrence)?  disconnect,}) {final _that = this;
switch (_that) {
case _RemoveListCommand() when removeList != null:
return removeList(_that.target,_that.item);case _RemoveMapCommand() when removeMap != null:
return removeMap(_that.target,_that.row);case _ReorderCommand() when reorder != null:
return reorder(_that.item);case _DisconnectCommand() when disconnect != null:
return disconnect(_that.occurrence);case _:
  return null;

}
}

}

/// @nodoc


class _RemoveListCommand implements _CollectionCommand {
  const _RemoveListCommand(this.target, this.item);
  

 final  PortableDiagnosticTarget target;
 final  skir.ItemId item;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveListCommandCopyWith<_RemoveListCommand> get copyWith => __$RemoveListCommandCopyWithImpl<_RemoveListCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveListCommand&&(identical(other.target, target) || other.target == target)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,item);
}

@override
String toString() {
    return '_CollectionCommand.removeList(target: $target, item: $item)';
}


}

/// @nodoc
abstract mixin class _$RemoveListCommandCopyWith<$Res> implements _$CollectionCommandCopyWith<$Res> {
  factory _$RemoveListCommandCopyWith(_RemoveListCommand value, $Res Function(_RemoveListCommand) _then) = __$RemoveListCommandCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, skir.ItemId item
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$RemoveListCommandCopyWithImpl<$Res>
    implements _$RemoveListCommandCopyWith<$Res> {
  __$RemoveListCommandCopyWithImpl(this._self, this._then);

  final _RemoveListCommand _self;
  final $Res Function(_RemoveListCommand) _then;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? item = null,}) {
  return _then(_RemoveListCommand(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as skir.ItemId,
  ));
}

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _RemoveMapCommand implements _CollectionCommand {
  const _RemoveMapCommand(this.target, this.row);
  

 final  PortableDiagnosticTarget target;
 final  skir.ItemId row;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveMapCommandCopyWith<_RemoveMapCommand> get copyWith => __$RemoveMapCommandCopyWithImpl<_RemoveMapCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveMapCommand&&(identical(other.target, target) || other.target == target)&&(identical(other.row, row) || other.row == row));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,row);
}

@override
String toString() {
    return '_CollectionCommand.removeMap(target: $target, row: $row)';
}


}

/// @nodoc
abstract mixin class _$RemoveMapCommandCopyWith<$Res> implements _$CollectionCommandCopyWith<$Res> {
  factory _$RemoveMapCommandCopyWith(_RemoveMapCommand value, $Res Function(_RemoveMapCommand) _then) = __$RemoveMapCommandCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, skir.ItemId row
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$RemoveMapCommandCopyWithImpl<$Res>
    implements _$RemoveMapCommandCopyWith<$Res> {
  __$RemoveMapCommandCopyWithImpl(this._self, this._then);

  final _RemoveMapCommand _self;
  final $Res Function(_RemoveMapCommand) _then;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? row = null,}) {
  return _then(_RemoveMapCommand(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.ItemId,
  ));
}

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _ReorderCommand implements _CollectionCommand {
  const _ReorderCommand(this.item);
  

 final  PortableDiagnosticTarget item;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReorderCommandCopyWith<_ReorderCommand> get copyWith => __$ReorderCommandCopyWithImpl<_ReorderCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReorderCommand&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode {
    return Object.hash(runtimeType,item);
}

@override
String toString() {
    return '_CollectionCommand.reorder(item: $item)';
}


}

/// @nodoc
abstract mixin class _$ReorderCommandCopyWith<$Res> implements _$CollectionCommandCopyWith<$Res> {
  factory _$ReorderCommandCopyWith(_ReorderCommand value, $Res Function(_ReorderCommand) _then) = __$ReorderCommandCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget item
});


$PortableDiagnosticTargetCopyWith<$Res> get item;

}
/// @nodoc
class __$ReorderCommandCopyWithImpl<$Res>
    implements _$ReorderCommandCopyWith<$Res> {
  __$ReorderCommandCopyWithImpl(this._self, this._then);

  final _ReorderCommand _self;
  final $Res Function(_ReorderCommand) _then;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,}) {
  return _then(_ReorderCommand(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get item {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

/// @nodoc


class _DisconnectCommand implements _CollectionCommand {
  const _DisconnectCommand(this.occurrence);
  

 final  skir.LinkOccurrence occurrence;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisconnectCommandCopyWith<_DisconnectCommand> get copyWith => __$DisconnectCommandCopyWithImpl<_DisconnectCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisconnectCommand&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,occurrence);
}

@override
String toString() {
    return '_CollectionCommand.disconnect(occurrence: $occurrence)';
}


}

/// @nodoc
abstract mixin class _$DisconnectCommandCopyWith<$Res> implements _$CollectionCommandCopyWith<$Res> {
  factory _$DisconnectCommandCopyWith(_DisconnectCommand value, $Res Function(_DisconnectCommand) _then) = __$DisconnectCommandCopyWithImpl;
@useResult
$Res call({
 skir.LinkOccurrence occurrence
});




}
/// @nodoc
class __$DisconnectCommandCopyWithImpl<$Res>
    implements _$DisconnectCommandCopyWith<$Res> {
  __$DisconnectCommandCopyWithImpl(this._self, this._then);

  final _DisconnectCommand _self;
  final $Res Function(_DisconnectCommand) _then;

/// Create a copy of _CollectionCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? occurrence = null,}) {
  return _then(_DisconnectCommand(
null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,
  ));
}


}

/// @nodoc
mixin _$ScopedHeaderDeclaration {

 skir.HeaderItem get item; PortablePresentationScope get scope;
/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopedHeaderDeclarationCopyWith<_ScopedHeaderDeclaration> get copyWith => __$ScopedHeaderDeclarationCopyWithImpl<_ScopedHeaderDeclaration>(this as _ScopedHeaderDeclaration, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _ScopedHeaderDeclaration;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopedHeaderDeclaration&&(identical(other.item, _this.item) || other.item == _this.item)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as _ScopedHeaderDeclaration;
  return Object.hash(runtimeType,_this.item,_this.scope);
}

@override
String toString() {
  final _this = this as _ScopedHeaderDeclaration;
  return '_ScopedHeaderDeclaration(item: ${_this.item}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class _$ScopedHeaderDeclarationCopyWith<$Res>  {
  factory _$ScopedHeaderDeclarationCopyWith(_ScopedHeaderDeclaration value, $Res Function(_ScopedHeaderDeclaration) _then) = __$ScopedHeaderDeclarationCopyWithImpl;
@useResult
$Res call({
 skir.HeaderItem item, PortablePresentationScope scope
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$ScopedHeaderDeclarationCopyWithImpl<$Res>
    implements _$ScopedHeaderDeclarationCopyWith<$Res> {
  __$ScopedHeaderDeclarationCopyWithImpl(this._self, this._then);

  final _ScopedHeaderDeclaration _self;
  final $Res Function(_ScopedHeaderDeclaration) _then;

/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? scope = null,}) {
  return _then(_ScopedHeaderDeclaration(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as skir.HeaderItem,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [_ScopedHeaderDeclaration].
extension _ScopedHeaderDeclarationPatterns on _ScopedHeaderDeclaration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __ScopedHeaderDeclaration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __ScopedHeaderDeclaration value)  $default,){
final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __ScopedHeaderDeclaration value)?  $default,){
final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.HeaderItem item,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration() when $default != null:
return $default(_that.item,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.HeaderItem item,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration():
return $default(_that.item,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.HeaderItem item,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case __ScopedHeaderDeclaration() when $default != null:
return $default(_that.item,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class __ScopedHeaderDeclaration implements _ScopedHeaderDeclaration {
  const __ScopedHeaderDeclaration({required this.item, required this.scope});
  

@override final  skir.HeaderItem item;
@override final  PortablePresentationScope scope;

/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_ScopedHeaderDeclarationCopyWith<__ScopedHeaderDeclaration> get copyWith => __$_ScopedHeaderDeclarationCopyWithImpl<__ScopedHeaderDeclaration>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __ScopedHeaderDeclaration&&(identical(other.item, item) || other.item == item)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,item,scope);
}

@override
String toString() {
    return '_ScopedHeaderDeclaration(item: $item, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$_ScopedHeaderDeclarationCopyWith<$Res> implements _$ScopedHeaderDeclarationCopyWith<$Res> {
  factory _$_ScopedHeaderDeclarationCopyWith(__ScopedHeaderDeclaration value, $Res Function(__ScopedHeaderDeclaration) _then) = __$_ScopedHeaderDeclarationCopyWithImpl;
@override @useResult
$Res call({
 skir.HeaderItem item, PortablePresentationScope scope
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$_ScopedHeaderDeclarationCopyWithImpl<$Res>
    implements _$_ScopedHeaderDeclarationCopyWith<$Res> {
  __$_ScopedHeaderDeclarationCopyWithImpl(this._self, this._then);

  final __ScopedHeaderDeclaration _self;
  final $Res Function(__ScopedHeaderDeclaration) _then;

/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? scope = null,}) {
  return _then(__ScopedHeaderDeclaration(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as skir.HeaderItem,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of _ScopedHeaderDeclaration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$SuppliedHeaderControl {

 WidgetBuilder get build; _CollectionCommand? get command;
/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuppliedHeaderControlCopyWith<_SuppliedHeaderControl> get copyWith => __$SuppliedHeaderControlCopyWithImpl<_SuppliedHeaderControl>(this as _SuppliedHeaderControl, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _SuppliedHeaderControl;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuppliedHeaderControl&&(identical(other.build, _this.build) || other.build == _this.build)&&(identical(other.command, _this.command) || other.command == _this.command));
}


@override
int get hashCode {
  final _this = this as _SuppliedHeaderControl;
  return Object.hash(runtimeType,_this.build,_this.command);
}

@override
String toString() {
  final _this = this as _SuppliedHeaderControl;
  return '_SuppliedHeaderControl(build: ${_this.build}, command: ${_this.command})';
}


}

/// @nodoc
abstract mixin class _$SuppliedHeaderControlCopyWith<$Res>  {
  factory _$SuppliedHeaderControlCopyWith(_SuppliedHeaderControl value, $Res Function(_SuppliedHeaderControl) _then) = __$SuppliedHeaderControlCopyWithImpl;
@useResult
$Res call({
 WidgetBuilder build, _CollectionCommand? command
});


_$CollectionCommandCopyWith<$Res>? get command;

}
/// @nodoc
class __$SuppliedHeaderControlCopyWithImpl<$Res>
    implements _$SuppliedHeaderControlCopyWith<$Res> {
  __$SuppliedHeaderControlCopyWithImpl(this._self, this._then);

  final _SuppliedHeaderControl _self;
  final $Res Function(_SuppliedHeaderControl) _then;

/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? build = null,Object? command = freezed,}) {
  return _then(_SuppliedHeaderControl(
build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as _CollectionCommand?,
  ));
}
/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
_$CollectionCommandCopyWith<$Res>? get command {
    if (_self.command == null) {
    return null;
  }

  return _$CollectionCommandCopyWith<$Res>(_self.command!, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}


/// Adds pattern-matching-related methods to [_SuppliedHeaderControl].
extension _SuppliedHeaderControlPatterns on _SuppliedHeaderControl {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __SuppliedHeaderControl value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __SuppliedHeaderControl() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __SuppliedHeaderControl value)  $default,){
final _that = this;
switch (_that) {
case __SuppliedHeaderControl():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __SuppliedHeaderControl value)?  $default,){
final _that = this;
switch (_that) {
case __SuppliedHeaderControl() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WidgetBuilder build,  _CollectionCommand? command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __SuppliedHeaderControl() when $default != null:
return $default(_that.build,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WidgetBuilder build,  _CollectionCommand? command)  $default,) {final _that = this;
switch (_that) {
case __SuppliedHeaderControl():
return $default(_that.build,_that.command);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WidgetBuilder build,  _CollectionCommand? command)?  $default,) {final _that = this;
switch (_that) {
case __SuppliedHeaderControl() when $default != null:
return $default(_that.build,_that.command);case _:
  return null;

}
}

}

/// @nodoc


class __SuppliedHeaderControl implements _SuppliedHeaderControl {
  const __SuppliedHeaderControl({required this.build, this.command});
  

@override final  WidgetBuilder build;
@override final  _CollectionCommand? command;

/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_SuppliedHeaderControlCopyWith<__SuppliedHeaderControl> get copyWith => __$_SuppliedHeaderControlCopyWithImpl<__SuppliedHeaderControl>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __SuppliedHeaderControl&&(identical(other.build, build) || other.build == build)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,build,command);
}

@override
String toString() {
    return '_SuppliedHeaderControl(build: $build, command: $command)';
}


}

/// @nodoc
abstract mixin class _$_SuppliedHeaderControlCopyWith<$Res> implements _$SuppliedHeaderControlCopyWith<$Res> {
  factory _$_SuppliedHeaderControlCopyWith(__SuppliedHeaderControl value, $Res Function(__SuppliedHeaderControl) _then) = __$_SuppliedHeaderControlCopyWithImpl;
@override @useResult
$Res call({
 WidgetBuilder build, _CollectionCommand? command
});


@override _$CollectionCommandCopyWith<$Res>? get command;

}
/// @nodoc
class __$_SuppliedHeaderControlCopyWithImpl<$Res>
    implements _$_SuppliedHeaderControlCopyWith<$Res> {
  __$_SuppliedHeaderControlCopyWithImpl(this._self, this._then);

  final __SuppliedHeaderControl _self;
  final $Res Function(__SuppliedHeaderControl) _then;

/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? build = null,Object? command = freezed,}) {
  return _then(__SuppliedHeaderControl(
build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as _CollectionCommand?,
  ));
}

/// Create a copy of _SuppliedHeaderControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
_$CollectionCommandCopyWith<$Res>? get command {
    if (_self.command == null) {
    return null;
  }

  return _$CollectionCommandCopyWith<$Res>(_self.command!, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc
mixin _$RemovalFocusIntent {

 Object get token; skir.ItemId get row; FocusNode get origin; Set<FocusNode> get fallbackScopes; int get index; bool get applied; bool get observedRemoval; bool get recoveryQueued;
/// Create a copy of _RemovalFocusIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemovalFocusIntentCopyWith<_RemovalFocusIntent> get copyWith => __$RemovalFocusIntentCopyWithImpl<_RemovalFocusIntent>(this as _RemovalFocusIntent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _RemovalFocusIntent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemovalFocusIntent&&const DeepCollectionEquality().equals(other.token, _this.token)&&(identical(other.row, _this.row) || other.row == _this.row)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&const DeepCollectionEquality().equals(other.fallbackScopes, _this.fallbackScopes)&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.applied, _this.applied) || other.applied == _this.applied)&&(identical(other.observedRemoval, _this.observedRemoval) || other.observedRemoval == _this.observedRemoval)&&(identical(other.recoveryQueued, _this.recoveryQueued) || other.recoveryQueued == _this.recoveryQueued));
}


@override
int get hashCode {
  final _this = this as _RemovalFocusIntent;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.token),_this.row,_this.origin,const DeepCollectionEquality().hash(_this.fallbackScopes),_this.index,_this.applied,_this.observedRemoval,_this.recoveryQueued);
}

@override
String toString() {
  final _this = this as _RemovalFocusIntent;
  return '_RemovalFocusIntent(token: ${_this.token}, row: ${_this.row}, origin: ${_this.origin}, fallbackScopes: ${_this.fallbackScopes}, index: ${_this.index}, applied: ${_this.applied}, observedRemoval: ${_this.observedRemoval}, recoveryQueued: ${_this.recoveryQueued})';
}


}

/// @nodoc
abstract mixin class _$RemovalFocusIntentCopyWith<$Res>  {
  factory _$RemovalFocusIntentCopyWith(_RemovalFocusIntent value, $Res Function(_RemovalFocusIntent) _then) = __$RemovalFocusIntentCopyWithImpl;
@useResult
$Res call({
 Object token, skir.ItemId row, FocusNode origin, Set<FocusNode> fallbackScopes, int index, bool applied, bool observedRemoval, bool recoveryQueued
});




}
/// @nodoc
class __$RemovalFocusIntentCopyWithImpl<$Res>
    implements _$RemovalFocusIntentCopyWith<$Res> {
  __$RemovalFocusIntentCopyWithImpl(this._self, this._then);

  final _RemovalFocusIntent _self;
  final $Res Function(_RemovalFocusIntent) _then;

/// Create a copy of _RemovalFocusIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? row = null,Object? origin = null,Object? fallbackScopes = null,Object? index = null,Object? applied = null,Object? observedRemoval = null,Object? recoveryQueued = null,}) {
  return _then(_RemovalFocusIntent(
token: null == token ? _self.token : token ,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.ItemId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as FocusNode,fallbackScopes: null == fallbackScopes ? _self.fallbackScopes : fallbackScopes // ignore: cast_nullable_to_non_nullable
as Set<FocusNode>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,observedRemoval: null == observedRemoval ? _self.observedRemoval : observedRemoval // ignore: cast_nullable_to_non_nullable
as bool,recoveryQueued: null == recoveryQueued ? _self.recoveryQueued : recoveryQueued // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [_RemovalFocusIntent].
extension _RemovalFocusIntentPatterns on _RemovalFocusIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __RemovalFocusIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __RemovalFocusIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __RemovalFocusIntent value)  $default,){
final _that = this;
switch (_that) {
case __RemovalFocusIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __RemovalFocusIntent value)?  $default,){
final _that = this;
switch (_that) {
case __RemovalFocusIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes,  int index,  bool applied,  bool observedRemoval,  bool recoveryQueued)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __RemovalFocusIntent() when $default != null:
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes,_that.index,_that.applied,_that.observedRemoval,_that.recoveryQueued);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes,  int index,  bool applied,  bool observedRemoval,  bool recoveryQueued)  $default,) {final _that = this;
switch (_that) {
case __RemovalFocusIntent():
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes,_that.index,_that.applied,_that.observedRemoval,_that.recoveryQueued);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes,  int index,  bool applied,  bool observedRemoval,  bool recoveryQueued)?  $default,) {final _that = this;
switch (_that) {
case __RemovalFocusIntent() when $default != null:
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes,_that.index,_that.applied,_that.observedRemoval,_that.recoveryQueued);case _:
  return null;

}
}

}

/// @nodoc


class __RemovalFocusIntent implements _RemovalFocusIntent {
  const __RemovalFocusIntent({required this.token, required this.row, required this.origin, required  Set<FocusNode> fallbackScopes, required this.index, this.applied = false, this.observedRemoval = false, this.recoveryQueued = false}): _fallbackScopes = fallbackScopes;
  

@override final  Object token;
@override final  skir.ItemId row;
@override final  FocusNode origin;
 final  Set<FocusNode> _fallbackScopes;
@override Set<FocusNode> get fallbackScopes {
  if (_fallbackScopes is EqualUnmodifiableSetView) return _fallbackScopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_fallbackScopes);
}

@override final  int index;
@override@JsonKey() final  bool applied;
@override@JsonKey() final  bool observedRemoval;
@override@JsonKey() final  bool recoveryQueued;

/// Create a copy of _RemovalFocusIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_RemovalFocusIntentCopyWith<__RemovalFocusIntent> get copyWith => __$_RemovalFocusIntentCopyWithImpl<__RemovalFocusIntent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __RemovalFocusIntent&&const DeepCollectionEquality().equals(other.token, token)&&(identical(other.row, row) || other.row == row)&&(identical(other.origin, origin) || other.origin == origin)&&const DeepCollectionEquality().equals(other.fallbackScopes, _fallbackScopes)&&(identical(other.index, index) || other.index == index)&&(identical(other.applied, applied) || other.applied == applied)&&(identical(other.observedRemoval, observedRemoval) || other.observedRemoval == observedRemoval)&&(identical(other.recoveryQueued, recoveryQueued) || other.recoveryQueued == recoveryQueued));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(token),row,origin,const DeepCollectionEquality().hash(_fallbackScopes),index,applied,observedRemoval,recoveryQueued);
}

@override
String toString() {
    return '_RemovalFocusIntent(token: $token, row: $row, origin: $origin, fallbackScopes: $fallbackScopes, index: $index, applied: $applied, observedRemoval: $observedRemoval, recoveryQueued: $recoveryQueued)';
}


}

/// @nodoc
abstract mixin class _$_RemovalFocusIntentCopyWith<$Res> implements _$RemovalFocusIntentCopyWith<$Res> {
  factory _$_RemovalFocusIntentCopyWith(__RemovalFocusIntent value, $Res Function(__RemovalFocusIntent) _then) = __$_RemovalFocusIntentCopyWithImpl;
@override @useResult
$Res call({
 Object token, skir.ItemId row, FocusNode origin, Set<FocusNode> fallbackScopes, int index, bool applied, bool observedRemoval, bool recoveryQueued
});




}
/// @nodoc
class __$_RemovalFocusIntentCopyWithImpl<$Res>
    implements _$_RemovalFocusIntentCopyWith<$Res> {
  __$_RemovalFocusIntentCopyWithImpl(this._self, this._then);

  final __RemovalFocusIntent _self;
  final $Res Function(__RemovalFocusIntent) _then;

/// Create a copy of _RemovalFocusIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? row = null,Object? origin = null,Object? fallbackScopes = null,Object? index = null,Object? applied = null,Object? observedRemoval = null,Object? recoveryQueued = null,}) {
  return _then(__RemovalFocusIntent(
token: null == token ? _self.token : token ,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.ItemId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as FocusNode,fallbackScopes: null == fallbackScopes ? _self._fallbackScopes : fallbackScopes // ignore: cast_nullable_to_non_nullable
as Set<FocusNode>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,observedRemoval: null == observedRemoval ? _self.observedRemoval : observedRemoval // ignore: cast_nullable_to_non_nullable
as bool,recoveryQueued: null == recoveryQueued ? _self.recoveryQueued : recoveryQueued // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$LiveCollectionSource {

 PortablePresentationHost get host; skir.BindingRef get source; AuthoredBindingAddress get owner; skir.CatalogGeneration get generation; Object? get lifetime;
/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveCollectionSourceCopyWith<_LiveCollectionSource> get copyWith => __$LiveCollectionSourceCopyWithImpl<_LiveCollectionSource>(this as _LiveCollectionSource, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _LiveCollectionSource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveCollectionSource&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&const DeepCollectionEquality().equals(other.lifetime, _this.lifetime));
}


@override
int get hashCode {
  final _this = this as _LiveCollectionSource;
  return Object.hash(runtimeType,_this.host,_this.source,_this.owner,_this.generation,const DeepCollectionEquality().hash(_this.lifetime));
}

@override
String toString() {
  final _this = this as _LiveCollectionSource;
  return '_LiveCollectionSource(host: ${_this.host}, source: ${_this.source}, owner: ${_this.owner}, generation: ${_this.generation}, lifetime: ${_this.lifetime})';
}


}

/// @nodoc
abstract mixin class _$LiveCollectionSourceCopyWith<$Res>  {
  factory _$LiveCollectionSourceCopyWith(_LiveCollectionSource value, $Res Function(_LiveCollectionSource) _then) = __$LiveCollectionSourceCopyWithImpl;
@useResult
$Res call({
 PortablePresentationHost host, skir.BindingRef source, AuthoredBindingAddress owner, skir.CatalogGeneration generation, Object? lifetime
});


$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$LiveCollectionSourceCopyWithImpl<$Res>
    implements _$LiveCollectionSourceCopyWith<$Res> {
  __$LiveCollectionSourceCopyWithImpl(this._self, this._then);

  final _LiveCollectionSource _self;
  final $Res Function(_LiveCollectionSource) _then;

/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? host = null,Object? source = null,Object? owner = null,Object? generation = null,Object? lifetime = freezed,}) {
  return _then(_LiveCollectionSource(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.BindingRef,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as skir.CatalogGeneration,lifetime: freezed == lifetime ? _self.lifetime : lifetime ,
  ));
}
/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [_LiveCollectionSource].
extension _LiveCollectionSourcePatterns on _LiveCollectionSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __LiveCollectionSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __LiveCollectionSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __LiveCollectionSource value)  $default,){
final _that = this;
switch (_that) {
case __LiveCollectionSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __LiveCollectionSource value)?  $default,){
final _that = this;
switch (_that) {
case __LiveCollectionSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortablePresentationHost host,  skir.BindingRef source,  AuthoredBindingAddress owner,  skir.CatalogGeneration generation,  Object? lifetime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __LiveCollectionSource() when $default != null:
return $default(_that.host,_that.source,_that.owner,_that.generation,_that.lifetime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortablePresentationHost host,  skir.BindingRef source,  AuthoredBindingAddress owner,  skir.CatalogGeneration generation,  Object? lifetime)  $default,) {final _that = this;
switch (_that) {
case __LiveCollectionSource():
return $default(_that.host,_that.source,_that.owner,_that.generation,_that.lifetime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortablePresentationHost host,  skir.BindingRef source,  AuthoredBindingAddress owner,  skir.CatalogGeneration generation,  Object? lifetime)?  $default,) {final _that = this;
switch (_that) {
case __LiveCollectionSource() when $default != null:
return $default(_that.host,_that.source,_that.owner,_that.generation,_that.lifetime);case _:
  return null;

}
}

}

/// @nodoc


class __LiveCollectionSource extends _LiveCollectionSource {
  const __LiveCollectionSource({required this.host, required this.source, required this.owner, required this.generation, required this.lifetime}): super._();
  

@override final  PortablePresentationHost host;
@override final  skir.BindingRef source;
@override final  AuthoredBindingAddress owner;
@override final  skir.CatalogGeneration generation;
@override final  Object? lifetime;

/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_LiveCollectionSourceCopyWith<__LiveCollectionSource> get copyWith => __$_LiveCollectionSourceCopyWithImpl<__LiveCollectionSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __LiveCollectionSource&&(identical(other.host, host) || other.host == host)&&(identical(other.source, source) || other.source == source)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.generation, generation) || other.generation == generation)&&const DeepCollectionEquality().equals(other.lifetime, lifetime));
}


@override
int get hashCode {
    return Object.hash(runtimeType,host,source,owner,generation,const DeepCollectionEquality().hash(lifetime));
}

@override
String toString() {
    return '_LiveCollectionSource(host: $host, source: $source, owner: $owner, generation: $generation, lifetime: $lifetime)';
}


}

/// @nodoc
abstract mixin class _$_LiveCollectionSourceCopyWith<$Res> implements _$LiveCollectionSourceCopyWith<$Res> {
  factory _$_LiveCollectionSourceCopyWith(__LiveCollectionSource value, $Res Function(__LiveCollectionSource) _then) = __$_LiveCollectionSourceCopyWithImpl;
@override @useResult
$Res call({
 PortablePresentationHost host, skir.BindingRef source, AuthoredBindingAddress owner, skir.CatalogGeneration generation, Object? lifetime
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$_LiveCollectionSourceCopyWithImpl<$Res>
    implements _$_LiveCollectionSourceCopyWith<$Res> {
  __$_LiveCollectionSourceCopyWithImpl(this._self, this._then);

  final __LiveCollectionSource _self;
  final $Res Function(__LiveCollectionSource) _then;

/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? host = null,Object? source = null,Object? owner = null,Object? generation = null,Object? lifetime = freezed,}) {
  return _then(__LiveCollectionSource(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.BindingRef,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as skir.CatalogGeneration,lifetime: freezed == lifetime ? _self.lifetime : lifetime ,
  ));
}

/// Create a copy of _LiveCollectionSource
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$CollectionActionOrigin {

 Object get token; skir.ItemId get row; FocusNode get origin; Set<FocusNode> get fallbackScopes;
/// Create a copy of _CollectionActionOrigin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionActionOriginCopyWith<_CollectionActionOrigin> get copyWith => __$CollectionActionOriginCopyWithImpl<_CollectionActionOrigin>(this as _CollectionActionOrigin, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionActionOrigin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionActionOrigin&&const DeepCollectionEquality().equals(other.token, _this.token)&&(identical(other.row, _this.row) || other.row == _this.row)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&const DeepCollectionEquality().equals(other.fallbackScopes, _this.fallbackScopes));
}


@override
int get hashCode {
  final _this = this as _CollectionActionOrigin;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.token),_this.row,_this.origin,const DeepCollectionEquality().hash(_this.fallbackScopes));
}

@override
String toString() {
  final _this = this as _CollectionActionOrigin;
  return '_CollectionActionOrigin(token: ${_this.token}, row: ${_this.row}, origin: ${_this.origin}, fallbackScopes: ${_this.fallbackScopes})';
}


}

/// @nodoc
abstract mixin class _$CollectionActionOriginCopyWith<$Res>  {
  factory _$CollectionActionOriginCopyWith(_CollectionActionOrigin value, $Res Function(_CollectionActionOrigin) _then) = __$CollectionActionOriginCopyWithImpl;
@useResult
$Res call({
 Object token, skir.ItemId row, FocusNode origin, Set<FocusNode> fallbackScopes
});




}
/// @nodoc
class __$CollectionActionOriginCopyWithImpl<$Res>
    implements _$CollectionActionOriginCopyWith<$Res> {
  __$CollectionActionOriginCopyWithImpl(this._self, this._then);

  final _CollectionActionOrigin _self;
  final $Res Function(_CollectionActionOrigin) _then;

/// Create a copy of _CollectionActionOrigin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? row = null,Object? origin = null,Object? fallbackScopes = null,}) {
  return _then(_CollectionActionOrigin(
token: null == token ? _self.token : token ,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.ItemId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as FocusNode,fallbackScopes: null == fallbackScopes ? _self.fallbackScopes : fallbackScopes // ignore: cast_nullable_to_non_nullable
as Set<FocusNode>,
  ));
}

}


/// Adds pattern-matching-related methods to [_CollectionActionOrigin].
extension _CollectionActionOriginPatterns on _CollectionActionOrigin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionActionOrigin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionActionOrigin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionActionOrigin value)  $default,){
final _that = this;
switch (_that) {
case __CollectionActionOrigin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionActionOrigin value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionActionOrigin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionActionOrigin() when $default != null:
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes)  $default,) {final _that = this;
switch (_that) {
case __CollectionActionOrigin():
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object token,  skir.ItemId row,  FocusNode origin,  Set<FocusNode> fallbackScopes)?  $default,) {final _that = this;
switch (_that) {
case __CollectionActionOrigin() when $default != null:
return $default(_that.token,_that.row,_that.origin,_that.fallbackScopes);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionActionOrigin implements _CollectionActionOrigin {
  const __CollectionActionOrigin({required this.token, required this.row, required this.origin, required  Set<FocusNode> fallbackScopes}): _fallbackScopes = fallbackScopes;
  

@override final  Object token;
@override final  skir.ItemId row;
@override final  FocusNode origin;
 final  Set<FocusNode> _fallbackScopes;
@override Set<FocusNode> get fallbackScopes {
  if (_fallbackScopes is EqualUnmodifiableSetView) return _fallbackScopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_fallbackScopes);
}


/// Create a copy of _CollectionActionOrigin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionActionOriginCopyWith<__CollectionActionOrigin> get copyWith => __$_CollectionActionOriginCopyWithImpl<__CollectionActionOrigin>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionActionOrigin&&const DeepCollectionEquality().equals(other.token, token)&&(identical(other.row, row) || other.row == row)&&(identical(other.origin, origin) || other.origin == origin)&&const DeepCollectionEquality().equals(other.fallbackScopes, _fallbackScopes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(token),row,origin,const DeepCollectionEquality().hash(_fallbackScopes));
}

@override
String toString() {
    return '_CollectionActionOrigin(token: $token, row: $row, origin: $origin, fallbackScopes: $fallbackScopes)';
}


}

/// @nodoc
abstract mixin class _$_CollectionActionOriginCopyWith<$Res> implements _$CollectionActionOriginCopyWith<$Res> {
  factory _$_CollectionActionOriginCopyWith(__CollectionActionOrigin value, $Res Function(__CollectionActionOrigin) _then) = __$_CollectionActionOriginCopyWithImpl;
@override @useResult
$Res call({
 Object token, skir.ItemId row, FocusNode origin, Set<FocusNode> fallbackScopes
});




}
/// @nodoc
class __$_CollectionActionOriginCopyWithImpl<$Res>
    implements _$_CollectionActionOriginCopyWith<$Res> {
  __$_CollectionActionOriginCopyWithImpl(this._self, this._then);

  final __CollectionActionOrigin _self;
  final $Res Function(__CollectionActionOrigin) _then;

/// Create a copy of _CollectionActionOrigin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? row = null,Object? origin = null,Object? fallbackScopes = null,}) {
  return _then(__CollectionActionOrigin(
token: null == token ? _self.token : token ,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.ItemId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as FocusNode,fallbackScopes: null == fallbackScopes ? _self._fallbackScopes : fallbackScopes // ignore: cast_nullable_to_non_nullable
as Set<FocusNode>,
  ));
}


}

/// @nodoc
mixin _$CollectionGraphOccurrence {

 String get canonicalKey; List<String> get path; List<_CollectionGraphOccurrence> get children;
/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphOccurrenceCopyWith<_CollectionGraphOccurrence> get copyWith => __$CollectionGraphOccurrenceCopyWithImpl<_CollectionGraphOccurrence>(this as _CollectionGraphOccurrence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphOccurrence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphOccurrence&&(identical(other.canonicalKey, _this.canonicalKey) || other.canonicalKey == _this.canonicalKey)&&const DeepCollectionEquality().equals(other.path, _this.path)&&const DeepCollectionEquality().equals(other.children, _this.children));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphOccurrence;
  return Object.hash(runtimeType,_this.canonicalKey,const DeepCollectionEquality().hash(_this.path),const DeepCollectionEquality().hash(_this.children));
}

@override
String toString() {
  final _this = this as _CollectionGraphOccurrence;
  return '_CollectionGraphOccurrence(canonicalKey: ${_this.canonicalKey}, path: ${_this.path}, children: ${_this.children})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphOccurrenceCopyWith<$Res>  {
  factory _$CollectionGraphOccurrenceCopyWith(_CollectionGraphOccurrence value, $Res Function(_CollectionGraphOccurrence) _then) = __$CollectionGraphOccurrenceCopyWithImpl;
@useResult
$Res call({
 String canonicalKey, List<String> path, List<_CollectionGraphOccurrence> children
});




}
/// @nodoc
class __$CollectionGraphOccurrenceCopyWithImpl<$Res>
    implements _$CollectionGraphOccurrenceCopyWith<$Res> {
  __$CollectionGraphOccurrenceCopyWithImpl(this._self, this._then);

  final _CollectionGraphOccurrence _self;
  final $Res Function(_CollectionGraphOccurrence) _then;

/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canonicalKey = null,Object? path = null,Object? children = null,}) {
  return _then(_CollectionGraphOccurrence(
canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<String>,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,
  ));
}

}


/// Adds pattern-matching-related methods to [_CollectionGraphOccurrence].
extension _CollectionGraphOccurrencePatterns on _CollectionGraphOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphOccurrence value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
return $default(_that.canonicalKey,_that.path,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence():
return $default(_that.canonicalKey,_that.path,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
return $default(_that.canonicalKey,_that.path,_that.children);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphOccurrence implements _CollectionGraphOccurrence {
  const __CollectionGraphOccurrence({required this.canonicalKey, required  List<String> path, required  List<_CollectionGraphOccurrence> children}): _path = path,_children = children;
  

@override final  String canonicalKey;
 final  List<String> _path;
@override List<String> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}

 final  List<_CollectionGraphOccurrence> _children;
@override List<_CollectionGraphOccurrence> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphOccurrenceCopyWith<__CollectionGraphOccurrence> get copyWith => __$_CollectionGraphOccurrenceCopyWithImpl<__CollectionGraphOccurrence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphOccurrence&&(identical(other.canonicalKey, canonicalKey) || other.canonicalKey == canonicalKey)&&const DeepCollectionEquality().equals(other.path, _path)&&const DeepCollectionEquality().equals(other.children, _children));
}


@override
int get hashCode {
    return Object.hash(runtimeType,canonicalKey,const DeepCollectionEquality().hash(_path),const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return '_CollectionGraphOccurrence(canonicalKey: $canonicalKey, path: $path, children: $children)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphOccurrenceCopyWith<$Res> implements _$CollectionGraphOccurrenceCopyWith<$Res> {
  factory _$_CollectionGraphOccurrenceCopyWith(__CollectionGraphOccurrence value, $Res Function(__CollectionGraphOccurrence) _then) = __$_CollectionGraphOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 String canonicalKey, List<String> path, List<_CollectionGraphOccurrence> children
});




}
/// @nodoc
class __$_CollectionGraphOccurrenceCopyWithImpl<$Res>
    implements _$_CollectionGraphOccurrenceCopyWith<$Res> {
  __$_CollectionGraphOccurrenceCopyWithImpl(this._self, this._then);

  final __CollectionGraphOccurrence _self;
  final $Res Function(__CollectionGraphOccurrence) _then;

/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canonicalKey = null,Object? path = null,Object? children = null,}) {
  return _then(__CollectionGraphOccurrence(
canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<String>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,
  ));
}


}

/// @nodoc
mixin _$CollectionGraphProjection {

 List<_CollectionGraphOccurrence> get roots; bool get truncated;
/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphProjectionCopyWith<_CollectionGraphProjection> get copyWith => __$CollectionGraphProjectionCopyWithImpl<_CollectionGraphProjection>(this as _CollectionGraphProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphProjection&&const DeepCollectionEquality().equals(other.roots, _this.roots)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.roots),_this.truncated);
}

@override
String toString() {
  final _this = this as _CollectionGraphProjection;
  return '_CollectionGraphProjection(roots: ${_this.roots}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphProjectionCopyWith<$Res>  {
  factory _$CollectionGraphProjectionCopyWith(_CollectionGraphProjection value, $Res Function(_CollectionGraphProjection) _then) = __$CollectionGraphProjectionCopyWithImpl;
@useResult
$Res call({
 List<_CollectionGraphOccurrence> roots, bool truncated
});




}
/// @nodoc
class __$CollectionGraphProjectionCopyWithImpl<$Res>
    implements _$CollectionGraphProjectionCopyWith<$Res> {
  __$CollectionGraphProjectionCopyWithImpl(this._self, this._then);

  final _CollectionGraphProjection _self;
  final $Res Function(_CollectionGraphProjection) _then;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roots = null,Object? truncated = null,}) {
  return _then(_CollectionGraphProjection(
roots: null == roots ? _self.roots : roots // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [_CollectionGraphProjection].
extension _CollectionGraphProjectionPatterns on _CollectionGraphProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphProjection value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphProjection value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<_CollectionGraphOccurrence> roots,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
return $default(_that.roots,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<_CollectionGraphOccurrence> roots,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphProjection():
return $default(_that.roots,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<_CollectionGraphOccurrence> roots,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
return $default(_that.roots,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphProjection implements _CollectionGraphProjection {
  const __CollectionGraphProjection({required  List<_CollectionGraphOccurrence> roots, required this.truncated}): _roots = roots;
  

 final  List<_CollectionGraphOccurrence> _roots;
@override List<_CollectionGraphOccurrence> get roots {
  if (_roots is EqualUnmodifiableListView) return _roots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roots);
}

@override final  bool truncated;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphProjectionCopyWith<__CollectionGraphProjection> get copyWith => __$_CollectionGraphProjectionCopyWithImpl<__CollectionGraphProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphProjection&&const DeepCollectionEquality().equals(other.roots, _roots)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_roots),truncated);
}

@override
String toString() {
    return '_CollectionGraphProjection(roots: $roots, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphProjectionCopyWith<$Res> implements _$CollectionGraphProjectionCopyWith<$Res> {
  factory _$_CollectionGraphProjectionCopyWith(__CollectionGraphProjection value, $Res Function(__CollectionGraphProjection) _then) = __$_CollectionGraphProjectionCopyWithImpl;
@override @useResult
$Res call({
 List<_CollectionGraphOccurrence> roots, bool truncated
});




}
/// @nodoc
class __$_CollectionGraphProjectionCopyWithImpl<$Res>
    implements _$_CollectionGraphProjectionCopyWith<$Res> {
  __$_CollectionGraphProjectionCopyWithImpl(this._self, this._then);

  final __CollectionGraphProjection _self;
  final $Res Function(__CollectionGraphProjection) _then;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roots = null,Object? truncated = null,}) {
  return _then(__CollectionGraphProjection(
roots: null == roots ? _self._roots : roots // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CollectionGraphOccurrenceKey {

 Object get graph; Map<skir.ExpressionBindingId, Object> get invocation; List<String> get path;
/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphOccurrenceKeyCopyWith<_CollectionGraphOccurrenceKey> get copyWith => __$CollectionGraphOccurrenceKeyCopyWithImpl<_CollectionGraphOccurrenceKey>(this as _CollectionGraphOccurrenceKey, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphOccurrenceKey;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphOccurrenceKey&&const DeepCollectionEquality().equals(other.graph, _this.graph)&&const DeepCollectionEquality().equals(other.invocation, _this.invocation)&&const DeepCollectionEquality().equals(other.path, _this.path));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphOccurrenceKey;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.graph),const DeepCollectionEquality().hash(_this.invocation),const DeepCollectionEquality().hash(_this.path));
}

@override
String toString() {
  final _this = this as _CollectionGraphOccurrenceKey;
  return '_CollectionGraphOccurrenceKey(graph: ${_this.graph}, invocation: ${_this.invocation}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphOccurrenceKeyCopyWith<$Res>  {
  factory _$CollectionGraphOccurrenceKeyCopyWith(_CollectionGraphOccurrenceKey value, $Res Function(_CollectionGraphOccurrenceKey) _then) = __$CollectionGraphOccurrenceKeyCopyWithImpl;
@useResult
$Res call({
 Object graph, Map<skir.ExpressionBindingId, Object> invocation, List<String> path
});




}
/// @nodoc
class __$CollectionGraphOccurrenceKeyCopyWithImpl<$Res>
    implements _$CollectionGraphOccurrenceKeyCopyWith<$Res> {
  __$CollectionGraphOccurrenceKeyCopyWithImpl(this._self, this._then);

  final _CollectionGraphOccurrenceKey _self;
  final $Res Function(_CollectionGraphOccurrenceKey) _then;

/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? graph = null,Object? invocation = null,Object? path = null,}) {
  return _then(_CollectionGraphOccurrenceKey(
graph: null == graph ? _self.graph : graph ,invocation: null == invocation ? _self.invocation : invocation // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, Object>,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [_CollectionGraphOccurrenceKey].
extension _CollectionGraphOccurrenceKeyPatterns on _CollectionGraphOccurrenceKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphOccurrenceKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphOccurrenceKey value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphOccurrenceKey value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
return $default(_that.graph,_that.invocation,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey():
return $default(_that.graph,_that.invocation,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
return $default(_that.graph,_that.invocation,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphOccurrenceKey implements _CollectionGraphOccurrenceKey {
  const __CollectionGraphOccurrenceKey({required this.graph, required  Map<skir.ExpressionBindingId, Object> invocation, required  List<String> path}): _invocation = invocation,_path = path;
  

@override final  Object graph;
 final  Map<skir.ExpressionBindingId, Object> _invocation;
@override Map<skir.ExpressionBindingId, Object> get invocation {
  if (_invocation is EqualUnmodifiableMapView) return _invocation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_invocation);
}

 final  List<String> _path;
@override List<String> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}


/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphOccurrenceKeyCopyWith<__CollectionGraphOccurrenceKey> get copyWith => __$_CollectionGraphOccurrenceKeyCopyWithImpl<__CollectionGraphOccurrenceKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphOccurrenceKey&&const DeepCollectionEquality().equals(other.graph, graph)&&const DeepCollectionEquality().equals(other.invocation, _invocation)&&const DeepCollectionEquality().equals(other.path, _path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(graph),const DeepCollectionEquality().hash(_invocation),const DeepCollectionEquality().hash(_path));
}

@override
String toString() {
    return '_CollectionGraphOccurrenceKey(graph: $graph, invocation: $invocation, path: $path)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphOccurrenceKeyCopyWith<$Res> implements _$CollectionGraphOccurrenceKeyCopyWith<$Res> {
  factory _$_CollectionGraphOccurrenceKeyCopyWith(__CollectionGraphOccurrenceKey value, $Res Function(__CollectionGraphOccurrenceKey) _then) = __$_CollectionGraphOccurrenceKeyCopyWithImpl;
@override @useResult
$Res call({
 Object graph, Map<skir.ExpressionBindingId, Object> invocation, List<String> path
});




}
/// @nodoc
class __$_CollectionGraphOccurrenceKeyCopyWithImpl<$Res>
    implements _$_CollectionGraphOccurrenceKeyCopyWith<$Res> {
  __$_CollectionGraphOccurrenceKeyCopyWithImpl(this._self, this._then);

  final __CollectionGraphOccurrenceKey _self;
  final $Res Function(__CollectionGraphOccurrenceKey) _then;

/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? graph = null,Object? invocation = null,Object? path = null,}) {
  return _then(__CollectionGraphOccurrenceKey(
graph: null == graph ? _self.graph : graph ,invocation: null == invocation ? _self._invocation : invocation // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, Object>,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$PortableAppearanceLayer {

 skir.InputAppearance get appearance; Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget;
/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableAppearanceLayerCopyWith<PortableAppearanceLayer> get copyWith => _$PortableAppearanceLayerCopyWithImpl<PortableAppearanceLayer>(this as PortableAppearanceLayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableAppearanceLayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAppearanceLayer&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget));
}


@override
int get hashCode {
  final _this = this as PortableAppearanceLayer;
  return Object.hash(runtimeType,_this.appearance,const DeepCollectionEquality().hash(_this.bindings),_this.budget);
}

@override
String toString() {
  final _this = this as PortableAppearanceLayer;
  return 'PortableAppearanceLayer(appearance: ${_this.appearance}, bindings: ${_this.bindings}, budget: ${_this.budget})';
}


}

/// @nodoc
abstract mixin class $PortableAppearanceLayerCopyWith<$Res>  {
  factory $PortableAppearanceLayerCopyWith(PortableAppearanceLayer value, $Res Function(PortableAppearanceLayer) _then) = _$PortableAppearanceLayerCopyWithImpl;
@useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class _$PortableAppearanceLayerCopyWithImpl<$Res>
    implements $PortableAppearanceLayerCopyWith<$Res> {
  _$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final PortableAppearanceLayer _self;
  final $Res Function(PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableAppearanceLayer].
extension PortableAppearanceLayerPatterns on PortableAppearanceLayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableAppearanceLayer value)?  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
  return null;

}
}

}

/// @nodoc


class _PortableAppearanceLayer implements PortableAppearanceLayer {
  const _PortableAppearanceLayer({required this.appearance, required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget}): _bindings = bindings;
  

@override final  skir.InputAppearance appearance;
 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAppearanceLayerCopyWith<_PortableAppearanceLayer> get copyWith => __$PortableAppearanceLayerCopyWithImpl<_PortableAppearanceLayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAppearanceLayer&&(identical(other.appearance, appearance) || other.appearance == appearance)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget));
}


@override
int get hashCode {
    return Object.hash(runtimeType,appearance,const DeepCollectionEquality().hash(_bindings),budget);
}

@override
String toString() {
    return 'PortableAppearanceLayer(appearance: $appearance, bindings: $bindings, budget: $budget)';
}


}

/// @nodoc
abstract mixin class _$PortableAppearanceLayerCopyWith<$Res> implements $PortableAppearanceLayerCopyWith<$Res> {
  factory _$PortableAppearanceLayerCopyWith(_PortableAppearanceLayer value, $Res Function(_PortableAppearanceLayer) _then) = __$PortableAppearanceLayerCopyWithImpl;
@override @useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class __$PortableAppearanceLayerCopyWithImpl<$Res>
    implements _$PortableAppearanceLayerCopyWith<$Res> {
  __$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final _PortableAppearanceLayer _self;
  final $Res Function(_PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(_PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}


}

/// @nodoc
mixin _$PortableControlStyle {

 InputDecoration get decoration; TextStyle get valueStyle; TextStyle get labelStyle; TextStyle get descriptionStyle; TextAlign get alignment; double get iconSize; Color? get iconColor; EdgeInsetsGeometry? get padding; bool? get dense;
/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlStyleCopyWith<_PortableControlStyle> get copyWith => __$PortableControlStyleCopyWithImpl<_PortableControlStyle>(this as _PortableControlStyle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _PortableControlStyle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlStyle&&(identical(other.decoration, _this.decoration) || other.decoration == _this.decoration)&&(identical(other.valueStyle, _this.valueStyle) || other.valueStyle == _this.valueStyle)&&(identical(other.labelStyle, _this.labelStyle) || other.labelStyle == _this.labelStyle)&&(identical(other.descriptionStyle, _this.descriptionStyle) || other.descriptionStyle == _this.descriptionStyle)&&(identical(other.alignment, _this.alignment) || other.alignment == _this.alignment)&&(identical(other.iconSize, _this.iconSize) || other.iconSize == _this.iconSize)&&(identical(other.iconColor, _this.iconColor) || other.iconColor == _this.iconColor)&&(identical(other.padding, _this.padding) || other.padding == _this.padding)&&(identical(other.dense, _this.dense) || other.dense == _this.dense));
}


@override
int get hashCode {
  final _this = this as _PortableControlStyle;
  return Object.hash(runtimeType,_this.decoration,_this.valueStyle,_this.labelStyle,_this.descriptionStyle,_this.alignment,_this.iconSize,_this.iconColor,_this.padding,_this.dense);
}

@override
String toString() {
  final _this = this as _PortableControlStyle;
  return '_PortableControlStyle(decoration: ${_this.decoration}, valueStyle: ${_this.valueStyle}, labelStyle: ${_this.labelStyle}, descriptionStyle: ${_this.descriptionStyle}, alignment: ${_this.alignment}, iconSize: ${_this.iconSize}, iconColor: ${_this.iconColor}, padding: ${_this.padding}, dense: ${_this.dense})';
}


}

/// @nodoc
abstract mixin class _$PortableControlStyleCopyWith<$Res>  {
  factory _$PortableControlStyleCopyWith(_PortableControlStyle value, $Res Function(_PortableControlStyle) _then) = __$PortableControlStyleCopyWithImpl;
@useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$PortableControlStyleCopyWithImpl<$Res>
    implements _$PortableControlStyleCopyWith<$Res> {
  __$PortableControlStyleCopyWithImpl(this._self, this._then);

  final _PortableControlStyle _self;
  final $Res Function(_PortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_PortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [_PortableControlStyle].
extension _PortableControlStylePatterns on _PortableControlStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedPortableControlStyle value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPortableControlStyle implements _PortableControlStyle {
  const _ResolvedPortableControlStyle({required this.decoration, required this.valueStyle, required this.labelStyle, required this.descriptionStyle, required this.alignment, required this.iconSize, this.iconColor, this.padding, this.dense});
  

@override final  InputDecoration decoration;
@override final  TextStyle valueStyle;
@override final  TextStyle labelStyle;
@override final  TextStyle descriptionStyle;
@override final  TextAlign alignment;
@override final  double iconSize;
@override final  Color? iconColor;
@override final  EdgeInsetsGeometry? padding;
@override final  bool? dense;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPortableControlStyleCopyWith<_ResolvedPortableControlStyle> get copyWith => __$ResolvedPortableControlStyleCopyWithImpl<_ResolvedPortableControlStyle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPortableControlStyle&&(identical(other.decoration, decoration) || other.decoration == decoration)&&(identical(other.valueStyle, valueStyle) || other.valueStyle == valueStyle)&&(identical(other.labelStyle, labelStyle) || other.labelStyle == labelStyle)&&(identical(other.descriptionStyle, descriptionStyle) || other.descriptionStyle == descriptionStyle)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.iconSize, iconSize) || other.iconSize == iconSize)&&(identical(other.iconColor, iconColor) || other.iconColor == iconColor)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.dense, dense) || other.dense == dense));
}


@override
int get hashCode {
    return Object.hash(runtimeType,decoration,valueStyle,labelStyle,descriptionStyle,alignment,iconSize,iconColor,padding,dense);
}

@override
String toString() {
    return '_PortableControlStyle(decoration: $decoration, valueStyle: $valueStyle, labelStyle: $labelStyle, descriptionStyle: $descriptionStyle, alignment: $alignment, iconSize: $iconSize, iconColor: $iconColor, padding: $padding, dense: $dense)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPortableControlStyleCopyWith<$Res> implements _$PortableControlStyleCopyWith<$Res> {
  factory _$ResolvedPortableControlStyleCopyWith(_ResolvedPortableControlStyle value, $Res Function(_ResolvedPortableControlStyle) _then) = __$ResolvedPortableControlStyleCopyWithImpl;
@override @useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$ResolvedPortableControlStyleCopyWithImpl<$Res>
    implements _$ResolvedPortableControlStyleCopyWith<$Res> {
  __$ResolvedPortableControlStyleCopyWithImpl(this._self, this._then);

  final _ResolvedPortableControlStyle _self;
  final $Res Function(_ResolvedPortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_ResolvedPortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$PortableOperationKey {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey()';
}


}

/// @nodoc
class $PortableOperationKeyCopyWith<$Res>  {
$PortableOperationKeyCopyWith(PortableOperationKey _, $Res Function(PortableOperationKey) __);
}


/// Adds pattern-matching-related methods to [PortableOperationKey].
extension PortableOperationKeyPatterns on PortableOperationKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PortableWriteKey value)?  write,TResult Function( _PortableExecuteKey value)?  execute,TResult Function( _PortableAddItemKey value)?  addItem,TResult Function( _PortableAddMapRowKey value)?  addMapRow,TResult Function( _PortableMappingKey value)?  mapping,TResult Function( _PortableStatusKey value)?  status,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PortableWriteKey value)  write,required TResult Function( _PortableExecuteKey value)  execute,required TResult Function( _PortableAddItemKey value)  addItem,required TResult Function( _PortableAddMapRowKey value)  addMapRow,required TResult Function( _PortableMappingKey value)  mapping,required TResult Function( _PortableStatusKey value)  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that);case _PortableExecuteKey():
return execute(_that);case _PortableAddItemKey():
return addItem(_that);case _PortableAddMapRowKey():
return addMapRow(_that);case _PortableMappingKey():
return mapping(_that);case _PortableStatusKey():
return status(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PortableWriteKey value)?  write,TResult? Function( _PortableExecuteKey value)?  execute,TResult? Function( _PortableAddItemKey value)?  addItem,TResult? Function( _PortableAddMapRowKey value)?  addMapRow,TResult? Function( _PortableMappingKey value)?  mapping,TResult? Function( _PortableStatusKey value)?  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PortableDiagnosticTarget target)?  write,TResult Function( skir.EditorAction action)?  execute,TResult Function( PortableDiagnosticTarget target)?  addItem,TResult Function( PortableDiagnosticTarget target)?  addMapRow,TResult Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult Function()?  status,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PortableDiagnosticTarget target)  write,required TResult Function( skir.EditorAction action)  execute,required TResult Function( PortableDiagnosticTarget target)  addItem,required TResult Function( PortableDiagnosticTarget target)  addMapRow,required TResult Function( PortableDiagnosticTarget target,  bool completion)  mapping,required TResult Function()  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that.target);case _PortableExecuteKey():
return execute(_that.action);case _PortableAddItemKey():
return addItem(_that.target);case _PortableAddMapRowKey():
return addMapRow(_that.target);case _PortableMappingKey():
return mapping(_that.target,_that.completion);case _PortableStatusKey():
return status();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PortableDiagnosticTarget target)?  write,TResult? Function( skir.EditorAction action)?  execute,TResult? Function( PortableDiagnosticTarget target)?  addItem,TResult? Function( PortableDiagnosticTarget target)?  addMapRow,TResult? Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult? Function()?  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
  return null;

}
}

}

/// @nodoc


class _PortableWriteKey implements PortableOperationKey {
  const _PortableWriteKey(this.target);
  

 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableWriteKeyCopyWith<_PortableWriteKey> get copyWith => __$PortableWriteKeyCopyWithImpl<_PortableWriteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableWriteKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.write(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableWriteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableWriteKeyCopyWith(_PortableWriteKey value, $Res Function(_PortableWriteKey) _then) = __$PortableWriteKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableWriteKeyCopyWithImpl<$Res>
    implements _$PortableWriteKeyCopyWith<$Res> {
  __$PortableWriteKeyCopyWithImpl(this._self, this._then);

  final _PortableWriteKey _self;
  final $Res Function(_PortableWriteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableWriteKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableExecuteKey implements PortableOperationKey {
  const _PortableExecuteKey(this.action);
  

 final  skir.EditorAction action;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableExecuteKeyCopyWith<_PortableExecuteKey> get copyWith => __$PortableExecuteKeyCopyWithImpl<_PortableExecuteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableExecuteKey&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,action);
}

@override
String toString() {
    return 'PortableOperationKey.execute(action: $action)';
}


}

/// @nodoc
abstract mixin class _$PortableExecuteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableExecuteKeyCopyWith(_PortableExecuteKey value, $Res Function(_PortableExecuteKey) _then) = __$PortableExecuteKeyCopyWithImpl;
@useResult
$Res call({
 skir.EditorAction action
});




}
/// @nodoc
class __$PortableExecuteKeyCopyWithImpl<$Res>
    implements _$PortableExecuteKeyCopyWith<$Res> {
  __$PortableExecuteKeyCopyWithImpl(this._self, this._then);

  final _PortableExecuteKey _self;
  final $Res Function(_PortableExecuteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(_PortableExecuteKey(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as skir.EditorAction,
  ));
}


}

/// @nodoc


class _PortableAddItemKey implements PortableOperationKey {
  const _PortableAddItemKey(this.target);
  

 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddItemKeyCopyWith<_PortableAddItemKey> get copyWith => __$PortableAddItemKeyCopyWithImpl<_PortableAddItemKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddItemKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addItem(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddItemKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddItemKeyCopyWith(_PortableAddItemKey value, $Res Function(_PortableAddItemKey) _then) = __$PortableAddItemKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddItemKeyCopyWithImpl<$Res>
    implements _$PortableAddItemKeyCopyWith<$Res> {
  __$PortableAddItemKeyCopyWithImpl(this._self, this._then);

  final _PortableAddItemKey _self;
  final $Res Function(_PortableAddItemKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddItemKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableAddMapRowKey implements PortableOperationKey {
  const _PortableAddMapRowKey(this.target);
  

 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddMapRowKeyCopyWith<_PortableAddMapRowKey> get copyWith => __$PortableAddMapRowKeyCopyWithImpl<_PortableAddMapRowKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddMapRowKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addMapRow(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddMapRowKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddMapRowKeyCopyWith(_PortableAddMapRowKey value, $Res Function(_PortableAddMapRowKey) _then) = __$PortableAddMapRowKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddMapRowKeyCopyWithImpl<$Res>
    implements _$PortableAddMapRowKeyCopyWith<$Res> {
  __$PortableAddMapRowKeyCopyWithImpl(this._self, this._then);

  final _PortableAddMapRowKey _self;
  final $Res Function(_PortableAddMapRowKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddMapRowKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableMappingKey implements PortableOperationKey {
  const _PortableMappingKey(this.target, {required this.completion});
  

 final  PortableDiagnosticTarget target;
 final  bool completion;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableMappingKeyCopyWith<_PortableMappingKey> get copyWith => __$PortableMappingKeyCopyWithImpl<_PortableMappingKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableMappingKey&&(identical(other.target, target) || other.target == target)&&(identical(other.completion, completion) || other.completion == completion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,completion);
}

@override
String toString() {
    return 'PortableOperationKey.mapping(target: $target, completion: $completion)';
}


}

/// @nodoc
abstract mixin class _$PortableMappingKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableMappingKeyCopyWith(_PortableMappingKey value, $Res Function(_PortableMappingKey) _then) = __$PortableMappingKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, bool completion
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableMappingKeyCopyWithImpl<$Res>
    implements _$PortableMappingKeyCopyWith<$Res> {
  __$PortableMappingKeyCopyWithImpl(this._self, this._then);

  final _PortableMappingKey _self;
  final $Res Function(_PortableMappingKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? completion = null,}) {
  return _then(_PortableMappingKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableStatusKey implements PortableOperationKey {
  const _PortableStatusKey();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableStatusKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey.status()';
}


}




/// @nodoc
mixin _$PortableOperationOutcome {

 Object get request; PortableDiagnosticObservation? get input; bool get pending; List<PortablePresentationDiagnostic> get diagnostics;
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationOutcomeCopyWith<PortableOperationOutcome> get copyWith => _$PortableOperationOutcomeCopyWithImpl<PortableOperationOutcome>(this as PortableOperationOutcome, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationOutcome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, _this.request)&&(identical(other.input, _this.input) || other.input == _this.input)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as PortableOperationOutcome;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.request),_this.input,_this.pending,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as PortableOperationOutcome;
  return 'PortableOperationOutcome(request: ${_this.request}, input: ${_this.input}, pending: ${_this.pending}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $PortableOperationOutcomeCopyWith<$Res>  {
  factory $PortableOperationOutcomeCopyWith(PortableOperationOutcome value, $Res Function(PortableOperationOutcome) _then) = _$PortableOperationOutcomeCopyWithImpl;
@useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


$PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class _$PortableOperationOutcomeCopyWithImpl<$Res>
    implements $PortableOperationOutcomeCopyWith<$Res> {
  _$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final PortableOperationOutcome _self;
  final $Res Function(PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableOperationOutcome].
extension PortableOperationOutcomePatterns on PortableOperationOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome():
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationOutcome implements PortableOperationOutcome {
  const _PortableOperationOutcome({required this.request, this.input, this.pending = false,  List<PortablePresentationDiagnostic> diagnostics = const []}): _diagnostics = diagnostics;
  

@override final  Object request;
@override final  PortableDiagnosticObservation? input;
@override@JsonKey() final  bool pending;
 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationOutcomeCopyWith<_PortableOperationOutcome> get copyWith => __$PortableOperationOutcomeCopyWithImpl<_PortableOperationOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, request)&&(identical(other.input, input) || other.input == input)&&(identical(other.pending, pending) || other.pending == pending)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(request),input,pending,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PortableOperationOutcome(request: $request, input: $input, pending: $pending, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationOutcomeCopyWith<$Res> implements $PortableOperationOutcomeCopyWith<$Res> {
  factory _$PortableOperationOutcomeCopyWith(_PortableOperationOutcome value, $Res Function(_PortableOperationOutcome) _then) = __$PortableOperationOutcomeCopyWithImpl;
@override @useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


@override $PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class __$PortableOperationOutcomeCopyWithImpl<$Res>
    implements _$PortableOperationOutcomeCopyWith<$Res> {
  __$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final _PortableOperationOutcome _self;
  final $Res Function(_PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(_PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

/// @nodoc
mixin _$PortableOperationState {

 Map<PortableOperationKey, PortableOperationOutcome> get outcomes;
/// Create a copy of PortableOperationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationStateCopyWith<PortableOperationState> get copyWith => _$PortableOperationStateCopyWithImpl<PortableOperationState>(this as PortableOperationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _this.outcomes));
}


@override
int get hashCode {
  final _this = this as PortableOperationState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.outcomes));
}

@override
String toString() {
  final _this = this as PortableOperationState;
  return 'PortableOperationState(outcomes: ${_this.outcomes})';
}


}

/// @nodoc
abstract mixin class $PortableOperationStateCopyWith<$Res>  {
  factory $PortableOperationStateCopyWith(PortableOperationState value, $Res Function(PortableOperationState) _then) = _$PortableOperationStateCopyWithImpl;
@useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class _$PortableOperationStateCopyWithImpl<$Res>
    implements $PortableOperationStateCopyWith<$Res> {
  _$PortableOperationStateCopyWithImpl(this._self, this._then);

  final PortableOperationState _self;
  final $Res Function(PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outcomes = null,}) {
  return _then(PortableOperationState(
outcomes: null == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableOperationState].
extension PortableOperationStatePatterns on PortableOperationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationState value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationState value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState():
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationState extends PortableOperationState {
  const _PortableOperationState({ Map<PortableOperationKey, PortableOperationOutcome> outcomes = const {}}): _outcomes = outcomes,super._();
  

 final  Map<PortableOperationKey, PortableOperationOutcome> _outcomes;
@override@JsonKey() Map<PortableOperationKey, PortableOperationOutcome> get outcomes {
  if (_outcomes is EqualUnmodifiableMapView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outcomes);
}


/// Create a copy of PortableOperationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationStateCopyWith<_PortableOperationState> get copyWith => __$PortableOperationStateCopyWithImpl<_PortableOperationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _outcomes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_outcomes));
}

@override
String toString() {
    return 'PortableOperationState(outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationStateCopyWith<$Res> implements $PortableOperationStateCopyWith<$Res> {
  factory _$PortableOperationStateCopyWith(_PortableOperationState value, $Res Function(_PortableOperationState) _then) = __$PortableOperationStateCopyWithImpl;
@override @useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class __$PortableOperationStateCopyWithImpl<$Res>
    implements _$PortableOperationStateCopyWith<$Res> {
  __$PortableOperationStateCopyWithImpl(this._self, this._then);

  final _PortableOperationState _self;
  final $Res Function(_PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outcomes = null,}) {
  return _then(_PortableOperationState(
outcomes: null == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticObservation {

 PortableDiagnosticTarget get target; skir.DataValue? get value;
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<PortableDiagnosticObservation> get copyWith => _$PortableDiagnosticObservationCopyWithImpl<PortableDiagnosticObservation>(this as PortableDiagnosticObservation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticObservation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticObservation&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticObservation;
  return Object.hash(runtimeType,_this.target,_this.value);
}

@override
String toString() {
  final _this = this as PortableDiagnosticObservation;
  return 'PortableDiagnosticObservation(target: ${_this.target}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticObservationCopyWith<$Res>  {
  factory $PortableDiagnosticObservationCopyWith(PortableDiagnosticObservation value, $Res Function(PortableDiagnosticObservation) _then) = _$PortableDiagnosticObservationCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements $PortableDiagnosticObservationCopyWith<$Res> {
  _$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticObservation _self;
  final $Res Function(PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableDiagnosticObservation].
extension PortableDiagnosticObservationPatterns on PortableDiagnosticObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticObservation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticObservation extends PortableDiagnosticObservation {
  const _PortableDiagnosticObservation({required this.target, required this.value}): super._();
  

@override final  PortableDiagnosticTarget target;
@override final  skir.DataValue? value;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticObservationCopyWith<_PortableDiagnosticObservation> get copyWith => __$PortableDiagnosticObservationCopyWithImpl<_PortableDiagnosticObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticObservation&&(identical(other.target, target) || other.target == target)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,value);
}

@override
String toString() {
    return 'PortableDiagnosticObservation(target: $target, value: $value)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticObservationCopyWith<$Res> implements $PortableDiagnosticObservationCopyWith<$Res> {
  factory _$PortableDiagnosticObservationCopyWith(_PortableDiagnosticObservation value, $Res Function(_PortableDiagnosticObservation) _then) = __$PortableDiagnosticObservationCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements _$PortableDiagnosticObservationCopyWith<$Res> {
  __$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticObservation _self;
  final $Res Function(_PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(_PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$PortableDiagnosticNode {

 PortableDiagnosticNodeKind get kind; Object? get parent; List<PortableDiagnosticObservation> get observations; List<PortablePresentationDiagnostic> get diagnostics; PortableDiagnosticFallback get diagnosticFallback;
/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticNodeCopyWith<PortableDiagnosticNode> get copyWith => _$PortableDiagnosticNodeCopyWithImpl<PortableDiagnosticNode>(this as PortableDiagnosticNode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticNode&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.parent, _this.parent)&&const DeepCollectionEquality().equals(other.observations, _this.observations)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.diagnosticFallback, _this.diagnosticFallback) || other.diagnosticFallback == _this.diagnosticFallback));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticNode;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.parent),const DeepCollectionEquality().hash(_this.observations),const DeepCollectionEquality().hash(_this.diagnostics),_this.diagnosticFallback);
}

@override
String toString() {
  final _this = this as PortableDiagnosticNode;
  return 'PortableDiagnosticNode(kind: ${_this.kind}, parent: ${_this.parent}, observations: ${_this.observations}, diagnostics: ${_this.diagnostics}, diagnosticFallback: ${_this.diagnosticFallback})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticNodeCopyWith<$Res>  {
  factory $PortableDiagnosticNodeCopyWith(PortableDiagnosticNode value, $Res Function(PortableDiagnosticNode) _then) = _$PortableDiagnosticNodeCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class _$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements $PortableDiagnosticNodeCopyWith<$Res> {
  _$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final PortableDiagnosticNode _self;
  final $Res Function(PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableDiagnosticNode].
extension PortableDiagnosticNodePatterns on PortableDiagnosticNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticNode value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticNode extends PortableDiagnosticNode {
  const _PortableDiagnosticNode({required this.kind, this.parent,  List<PortableDiagnosticObservation> observations = const [],  List<PortablePresentationDiagnostic> diagnostics = const [], this.diagnosticFallback = PortableDiagnosticFallback.presentation}): _observations = observations,_diagnostics = diagnostics,super._();
  

@override final  PortableDiagnosticNodeKind kind;
@override final  Object? parent;
 final  List<PortableDiagnosticObservation> _observations;
@override@JsonKey() List<PortableDiagnosticObservation> get observations {
  if (_observations is EqualUnmodifiableListView) return _observations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_observations);
}

 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  PortableDiagnosticFallback diagnosticFallback;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticNodeCopyWith<_PortableDiagnosticNode> get copyWith => __$PortableDiagnosticNodeCopyWithImpl<_PortableDiagnosticNode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticNode&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.parent, parent)&&const DeepCollectionEquality().equals(other.observations, _observations)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.diagnosticFallback, diagnosticFallback) || other.diagnosticFallback == diagnosticFallback));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(parent),const DeepCollectionEquality().hash(_observations),const DeepCollectionEquality().hash(_diagnostics),diagnosticFallback);
}

@override
String toString() {
    return 'PortableDiagnosticNode(kind: $kind, parent: $parent, observations: $observations, diagnostics: $diagnostics, diagnosticFallback: $diagnosticFallback)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticNodeCopyWith<$Res> implements $PortableDiagnosticNodeCopyWith<$Res> {
  factory _$PortableDiagnosticNodeCopyWith(_PortableDiagnosticNode value, $Res Function(_PortableDiagnosticNode) _then) = __$PortableDiagnosticNodeCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class __$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements _$PortableDiagnosticNodeCopyWith<$Res> {
  __$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticNode _self;
  final $Res Function(_PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(_PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self._observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPresentation {

 Map<Object, PortableDiagnosticNode> get nodes;
/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPresentationCopyWith<PortableDiagnosticPresentation> get copyWith => _$PortableDiagnosticPresentationCopyWithImpl<PortableDiagnosticPresentation>(this as PortableDiagnosticPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _this.nodes));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPresentation;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.nodes));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPresentation;
  return 'PortableDiagnosticPresentation(nodes: ${_this.nodes})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPresentationCopyWith<$Res>  {
  factory $PortableDiagnosticPresentationCopyWith(PortableDiagnosticPresentation value, $Res Function(PortableDiagnosticPresentation) _then) = _$PortableDiagnosticPresentationCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class _$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements $PortableDiagnosticPresentationCopyWith<$Res> {
  _$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPresentation _self;
  final $Res Function(PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,}) {
  return _then(PortableDiagnosticPresentation(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableDiagnosticPresentation].
extension PortableDiagnosticPresentationPatterns on PortableDiagnosticPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPresentation extends PortableDiagnosticPresentation {
  const _PortableDiagnosticPresentation({ Map<Object, PortableDiagnosticNode> nodes = const {}}): _nodes = nodes,super._();
  

 final  Map<Object, PortableDiagnosticNode> _nodes;
@override@JsonKey() Map<Object, PortableDiagnosticNode> get nodes {
  if (_nodes is EqualUnmodifiableMapView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodes);
}


/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPresentationCopyWith<_PortableDiagnosticPresentation> get copyWith => __$PortableDiagnosticPresentationCopyWithImpl<_PortableDiagnosticPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _nodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes));
}

@override
String toString() {
    return 'PortableDiagnosticPresentation(nodes: $nodes)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPresentationCopyWith<$Res> implements $PortableDiagnosticPresentationCopyWith<$Res> {
  factory _$PortableDiagnosticPresentationCopyWith(_PortableDiagnosticPresentation value, $Res Function(_PortableDiagnosticPresentation) _then) = __$PortableDiagnosticPresentationCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class __$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements _$PortableDiagnosticPresentationCopyWith<$Res> {
  __$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPresentation _self;
  final $Res Function(_PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,}) {
  return _then(_PortableDiagnosticPresentation(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticSummary {

 List<PortablePresentationDiagnostic> get direct; List<PortablePresentationDiagnostic> get descendants;
/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticSummaryCopyWith<PortableDiagnosticSummary> get copyWith => _$PortableDiagnosticSummaryCopyWithImpl<PortableDiagnosticSummary>(this as PortableDiagnosticSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _this.direct)&&const DeepCollectionEquality().equals(other.descendants, _this.descendants));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticSummary;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.direct),const DeepCollectionEquality().hash(_this.descendants));
}

@override
String toString() {
  final _this = this as PortableDiagnosticSummary;
  return 'PortableDiagnosticSummary(direct: ${_this.direct}, descendants: ${_this.descendants})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticSummaryCopyWith<$Res>  {
  factory $PortableDiagnosticSummaryCopyWith(PortableDiagnosticSummary value, $Res Function(PortableDiagnosticSummary) _then) = _$PortableDiagnosticSummaryCopyWithImpl;
@useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class _$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements $PortableDiagnosticSummaryCopyWith<$Res> {
  _$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final PortableDiagnosticSummary _self;
  final $Res Function(PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(PortableDiagnosticSummary(
direct: null == direct ? _self.direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self.descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableDiagnosticSummary].
extension PortableDiagnosticSummaryPatterns on PortableDiagnosticSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticSummary extends PortableDiagnosticSummary {
  const _PortableDiagnosticSummary({ List<PortablePresentationDiagnostic> direct = const [],  List<PortablePresentationDiagnostic> descendants = const []}): _direct = direct,_descendants = descendants,super._();
  

 final  List<PortablePresentationDiagnostic> _direct;
@override@JsonKey() List<PortablePresentationDiagnostic> get direct {
  if (_direct is EqualUnmodifiableListView) return _direct;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_direct);
}

 final  List<PortablePresentationDiagnostic> _descendants;
@override@JsonKey() List<PortablePresentationDiagnostic> get descendants {
  if (_descendants is EqualUnmodifiableListView) return _descendants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_descendants);
}


/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticSummaryCopyWith<_PortableDiagnosticSummary> get copyWith => __$PortableDiagnosticSummaryCopyWithImpl<_PortableDiagnosticSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _direct)&&const DeepCollectionEquality().equals(other.descendants, _descendants));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_direct),const DeepCollectionEquality().hash(_descendants));
}

@override
String toString() {
    return 'PortableDiagnosticSummary(direct: $direct, descendants: $descendants)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticSummaryCopyWith<$Res> implements $PortableDiagnosticSummaryCopyWith<$Res> {
  factory _$PortableDiagnosticSummaryCopyWith(_PortableDiagnosticSummary value, $Res Function(_PortableDiagnosticSummary) _then) = __$PortableDiagnosticSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class __$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements _$PortableDiagnosticSummaryCopyWith<$Res> {
  __$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticSummary _self;
  final $Res Function(_PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(_PortableDiagnosticSummary(
direct: null == direct ? _self._direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self._descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPlacement {

 Map<Object, PortableDiagnosticSummary> get summaries; List<PortablePresentationDiagnostic> get general; List<PortablePresentationDiagnostic> get unplaced;
/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPlacementCopyWith<PortableDiagnosticPlacement> get copyWith => _$PortableDiagnosticPlacementCopyWithImpl<PortableDiagnosticPlacement>(this as PortableDiagnosticPlacement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPlacement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _this.summaries)&&const DeepCollectionEquality().equals(other.general, _this.general)&&const DeepCollectionEquality().equals(other.unplaced, _this.unplaced));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPlacement;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.summaries),const DeepCollectionEquality().hash(_this.general),const DeepCollectionEquality().hash(_this.unplaced));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPlacement;
  return 'PortableDiagnosticPlacement(summaries: ${_this.summaries}, general: ${_this.general}, unplaced: ${_this.unplaced})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPlacementCopyWith<$Res>  {
  factory $PortableDiagnosticPlacementCopyWith(PortableDiagnosticPlacement value, $Res Function(PortableDiagnosticPlacement) _then) = _$PortableDiagnosticPlacementCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general, List<PortablePresentationDiagnostic> unplaced
});




}
/// @nodoc
class _$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements $PortableDiagnosticPlacementCopyWith<$Res> {
  _$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPlacement _self;
  final $Res Function(PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summaries = null,Object? general = null,Object? unplaced = null,}) {
  return _then(PortableDiagnosticPlacement(
summaries: null == summaries ? _self.summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,unplaced: null == unplaced ? _self.unplaced : unplaced // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableDiagnosticPlacement].
extension PortableDiagnosticPlacementPatterns on PortableDiagnosticPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general,_that.unplaced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
return $default(_that.summaries,_that.general,_that.unplaced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general,_that.unplaced);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPlacement extends PortableDiagnosticPlacement {
  const _PortableDiagnosticPlacement({ Map<Object, PortableDiagnosticSummary> summaries = const {},  List<PortablePresentationDiagnostic> general = const [],  List<PortablePresentationDiagnostic> unplaced = const []}): _summaries = summaries,_general = general,_unplaced = unplaced,super._();
  

 final  Map<Object, PortableDiagnosticSummary> _summaries;
@override@JsonKey() Map<Object, PortableDiagnosticSummary> get summaries {
  if (_summaries is EqualUnmodifiableMapView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_summaries);
}

 final  List<PortablePresentationDiagnostic> _general;
@override@JsonKey() List<PortablePresentationDiagnostic> get general {
  if (_general is EqualUnmodifiableListView) return _general;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_general);
}

 final  List<PortablePresentationDiagnostic> _unplaced;
@override@JsonKey() List<PortablePresentationDiagnostic> get unplaced {
  if (_unplaced is EqualUnmodifiableListView) return _unplaced;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unplaced);
}


/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPlacementCopyWith<_PortableDiagnosticPlacement> get copyWith => __$PortableDiagnosticPlacementCopyWithImpl<_PortableDiagnosticPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _summaries)&&const DeepCollectionEquality().equals(other.general, _general)&&const DeepCollectionEquality().equals(other.unplaced, _unplaced));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_summaries),const DeepCollectionEquality().hash(_general),const DeepCollectionEquality().hash(_unplaced));
}

@override
String toString() {
    return 'PortableDiagnosticPlacement(summaries: $summaries, general: $general, unplaced: $unplaced)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPlacementCopyWith<$Res> implements $PortableDiagnosticPlacementCopyWith<$Res> {
  factory _$PortableDiagnosticPlacementCopyWith(_PortableDiagnosticPlacement value, $Res Function(_PortableDiagnosticPlacement) _then) = __$PortableDiagnosticPlacementCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general, List<PortablePresentationDiagnostic> unplaced
});




}
/// @nodoc
class __$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements _$PortableDiagnosticPlacementCopyWith<$Res> {
  __$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPlacement _self;
  final $Res Function(_PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summaries = null,Object? general = null,Object? unplaced = null,}) {
  return _then(_PortableDiagnosticPlacement(
summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self._general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,unplaced: null == unplaced ? _self._unplaced : unplaced // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableControlValidationIdentity {

 Object get owner; PortableDiagnosticTarget get target;
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableControlValidationIdentityCopyWith<PortableControlValidationIdentity> get copyWith => _$PortableControlValidationIdentityCopyWithImpl<PortableControlValidationIdentity>(this as PortableControlValidationIdentity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableControlValidationIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, _this.owner)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as PortableControlValidationIdentity;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.owner),_this.target);
}

@override
String toString() {
  final _this = this as PortableControlValidationIdentity;
  return 'PortableControlValidationIdentity(owner: ${_this.owner}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $PortableControlValidationIdentityCopyWith<$Res>  {
  factory $PortableControlValidationIdentityCopyWith(PortableControlValidationIdentity value, $Res Function(PortableControlValidationIdentity) _then) = _$PortableControlValidationIdentityCopyWithImpl;
@useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements $PortableControlValidationIdentityCopyWith<$Res> {
  _$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final PortableControlValidationIdentity _self;
  final $Res Function(PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? target = null,}) {
  return _then(PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableControlValidationIdentity].
extension PortableControlValidationIdentityPatterns on PortableControlValidationIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableControlValidationIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object owner,  PortableDiagnosticTarget target)?  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _PortableControlValidationIdentity implements PortableControlValidationIdentity {
  const _PortableControlValidationIdentity({required this.owner, required this.target});
  

@override final  Object owner;
@override final  PortableDiagnosticTarget target;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlValidationIdentityCopyWith<_PortableControlValidationIdentity> get copyWith => __$PortableControlValidationIdentityCopyWithImpl<_PortableControlValidationIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, owner)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(owner),target);
}

@override
String toString() {
    return 'PortableControlValidationIdentity(owner: $owner, target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableControlValidationIdentityCopyWith<$Res> implements $PortableControlValidationIdentityCopyWith<$Res> {
  factory _$PortableControlValidationIdentityCopyWith(_PortableControlValidationIdentity value, $Res Function(_PortableControlValidationIdentity) _then) = __$PortableControlValidationIdentityCopyWithImpl;
@override @useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements _$PortableControlValidationIdentityCopyWith<$Res> {
  __$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final _PortableControlValidationIdentity _self;
  final $Res Function(_PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? target = null,}) {
  return _then(_PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {
  
  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$ResolvedFieldAssociation {

 String? get label; String? get description; String? get semanticLabel; ScopedControlPrefix? get prefix;
/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<ResolvedFieldAssociation> get copyWith => _$ResolvedFieldAssociationCopyWithImpl<ResolvedFieldAssociation>(this as ResolvedFieldAssociation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedFieldAssociation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedFieldAssociation&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.semanticLabel, _this.semanticLabel) || other.semanticLabel == _this.semanticLabel)&&(identical(other.prefix, _this.prefix) || other.prefix == _this.prefix));
}


@override
int get hashCode {
  final _this = this as ResolvedFieldAssociation;
  return Object.hash(runtimeType,_this.label,_this.description,_this.semanticLabel,_this.prefix);
}

@override
String toString() {
  final _this = this as ResolvedFieldAssociation;
  return 'ResolvedFieldAssociation(label: ${_this.label}, description: ${_this.description}, semanticLabel: ${_this.semanticLabel}, prefix: ${_this.prefix})';
}


}

/// @nodoc
abstract mixin class $ResolvedFieldAssociationCopyWith<$Res>  {
  factory $ResolvedFieldAssociationCopyWith(ResolvedFieldAssociation value, $Res Function(ResolvedFieldAssociation) _then) = _$ResolvedFieldAssociationCopyWithImpl;
@useResult
$Res call({
 String? label, String? description, String? semanticLabel, ScopedControlPrefix? prefix
});


$ScopedControlPrefixCopyWith<$Res>? get prefix;

}
/// @nodoc
class _$ResolvedFieldAssociationCopyWithImpl<$Res>
    implements $ResolvedFieldAssociationCopyWith<$Res> {
  _$ResolvedFieldAssociationCopyWithImpl(this._self, this._then);

  final ResolvedFieldAssociation _self;
  final $Res Function(ResolvedFieldAssociation) _then;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,Object? description = freezed,Object? semanticLabel = freezed,Object? prefix = freezed,}) {
  return _then(ResolvedFieldAssociation(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as String?,prefix: freezed == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as ScopedControlPrefix?,
  ));
}
/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<$Res>? get prefix {
    if (_self.prefix == null) {
    return null;
  }

  return $ScopedControlPrefixCopyWith<$Res>(_self.prefix!, (value) {
    return _then(_self.copyWith(prefix: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedFieldAssociation].
extension ResolvedFieldAssociationPatterns on ResolvedFieldAssociation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedFieldAssociation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedFieldAssociation value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedFieldAssociation value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)  $default,) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation():
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedFieldAssociation extends ResolvedFieldAssociation {
  const _ResolvedFieldAssociation({this.label, this.description, this.semanticLabel, this.prefix}): super._();
  

@override final  String? label;
@override final  String? description;
@override final  String? semanticLabel;
@override final  ScopedControlPrefix? prefix;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedFieldAssociationCopyWith<_ResolvedFieldAssociation> get copyWith => __$ResolvedFieldAssociationCopyWithImpl<_ResolvedFieldAssociation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedFieldAssociation&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.semanticLabel, semanticLabel) || other.semanticLabel == semanticLabel)&&(identical(other.prefix, prefix) || other.prefix == prefix));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,description,semanticLabel,prefix);
}

@override
String toString() {
    return 'ResolvedFieldAssociation(label: $label, description: $description, semanticLabel: $semanticLabel, prefix: $prefix)';
}


}

/// @nodoc
abstract mixin class _$ResolvedFieldAssociationCopyWith<$Res> implements $ResolvedFieldAssociationCopyWith<$Res> {
  factory _$ResolvedFieldAssociationCopyWith(_ResolvedFieldAssociation value, $Res Function(_ResolvedFieldAssociation) _then) = __$ResolvedFieldAssociationCopyWithImpl;
@override @useResult
$Res call({
 String? label, String? description, String? semanticLabel, ScopedControlPrefix? prefix
});


@override $ScopedControlPrefixCopyWith<$Res>? get prefix;

}
/// @nodoc
class __$ResolvedFieldAssociationCopyWithImpl<$Res>
    implements _$ResolvedFieldAssociationCopyWith<$Res> {
  __$ResolvedFieldAssociationCopyWithImpl(this._self, this._then);

  final _ResolvedFieldAssociation _self;
  final $Res Function(_ResolvedFieldAssociation) _then;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,Object? description = freezed,Object? semanticLabel = freezed,Object? prefix = freezed,}) {
  return _then(_ResolvedFieldAssociation(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as String?,prefix: freezed == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as ScopedControlPrefix?,
  ));
}

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<$Res>? get prefix {
    if (_self.prefix == null) {
    return null;
  }

  return $ScopedControlPrefixCopyWith<$Res>(_self.prefix!, (value) {
    return _then(_self.copyWith(prefix: value));
  });
}
}

/// @nodoc
mixin _$ScopedControlPrefix {

 skir.PresentationNode get node; PortablePresentationScope get scope;
/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<ScopedControlPrefix> get copyWith => _$ScopedControlPrefixCopyWithImpl<ScopedControlPrefix>(this as ScopedControlPrefix, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScopedControlPrefix;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopedControlPrefix&&(identical(other.node, _this.node) || other.node == _this.node)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as ScopedControlPrefix;
  return Object.hash(runtimeType,_this.node,_this.scope);
}

@override
String toString() {
  final _this = this as ScopedControlPrefix;
  return 'ScopedControlPrefix(node: ${_this.node}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $ScopedControlPrefixCopyWith<$Res>  {
  factory $ScopedControlPrefixCopyWith(ScopedControlPrefix value, $Res Function(ScopedControlPrefix) _then) = _$ScopedControlPrefixCopyWithImpl;
@useResult
$Res call({
 skir.PresentationNode node, PortablePresentationScope scope
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$ScopedControlPrefixCopyWithImpl<$Res>
    implements $ScopedControlPrefixCopyWith<$Res> {
  _$ScopedControlPrefixCopyWithImpl(this._self, this._then);

  final ScopedControlPrefix _self;
  final $Res Function(ScopedControlPrefix) _then;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? scope = null,}) {
  return _then(ScopedControlPrefix(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScopedControlPrefix].
extension ScopedControlPrefixPatterns on ScopedControlPrefix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScopedControlPrefix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScopedControlPrefix value)  $default,){
final _that = this;
switch (_that) {
case _ScopedControlPrefix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScopedControlPrefix value)?  $default,){
final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationNode node,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
return $default(_that.node,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationNode node,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case _ScopedControlPrefix():
return $default(_that.node,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationNode node,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
return $default(_that.node,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _ScopedControlPrefix extends ScopedControlPrefix {
  const _ScopedControlPrefix({required this.node, required this.scope}): super._();
  

@override final  skir.PresentationNode node;
@override final  PortablePresentationScope scope;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopedControlPrefixCopyWith<_ScopedControlPrefix> get copyWith => __$ScopedControlPrefixCopyWithImpl<_ScopedControlPrefix>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopedControlPrefix&&(identical(other.node, node) || other.node == node)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,node,scope);
}

@override
String toString() {
    return 'ScopedControlPrefix(node: $node, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$ScopedControlPrefixCopyWith<$Res> implements $ScopedControlPrefixCopyWith<$Res> {
  factory _$ScopedControlPrefixCopyWith(_ScopedControlPrefix value, $Res Function(_ScopedControlPrefix) _then) = __$ScopedControlPrefixCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationNode node, PortablePresentationScope scope
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$ScopedControlPrefixCopyWithImpl<$Res>
    implements _$ScopedControlPrefixCopyWith<$Res> {
  __$ScopedControlPrefixCopyWithImpl(this._self, this._then);

  final _ScopedControlPrefix _self;
  final $Res Function(_ScopedControlPrefix) _then;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? scope = null,}) {
  return _then(_ScopedControlPrefix(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$PortableRecordFieldOwner {

 skir.TypeSelection get type; String get field; AuthoredBindingAddress get address; PortablePresentationScope get scope;
/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableRecordFieldOwnerCopyWith<PortableRecordFieldOwner> get copyWith => _$PortableRecordFieldOwnerCopyWithImpl<PortableRecordFieldOwner>(this as PortableRecordFieldOwner, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableRecordFieldOwner;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRecordFieldOwner&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as PortableRecordFieldOwner;
  return Object.hash(runtimeType,_this.type,_this.field,_this.address,_this.scope);
}

@override
String toString() {
  final _this = this as PortableRecordFieldOwner;
  return 'PortableRecordFieldOwner(type: ${_this.type}, field: ${_this.field}, address: ${_this.address}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $PortableRecordFieldOwnerCopyWith<$Res>  {
  factory $PortableRecordFieldOwnerCopyWith(PortableRecordFieldOwner value, $Res Function(PortableRecordFieldOwner) _then) = _$PortableRecordFieldOwnerCopyWithImpl;
@useResult
$Res call({
 skir.TypeSelection type, String field, AuthoredBindingAddress address, PortablePresentationScope scope
});


$AuthoredBindingAddressCopyWith<$Res> get address;$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$PortableRecordFieldOwnerCopyWithImpl<$Res>
    implements $PortableRecordFieldOwnerCopyWith<$Res> {
  _$PortableRecordFieldOwnerCopyWithImpl(this._self, this._then);

  final PortableRecordFieldOwner _self;
  final $Res Function(PortableRecordFieldOwner) _then;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? field = null,Object? address = null,Object? scope = null,}) {
  return _then(PortableRecordFieldOwner(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableRecordFieldOwner].
extension PortableRecordFieldOwnerPatterns on PortableRecordFieldOwner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableRecordFieldOwner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableRecordFieldOwner value)  $default,){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableRecordFieldOwner value)?  $default,){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner():
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _PortableRecordFieldOwner implements PortableRecordFieldOwner {
  const _PortableRecordFieldOwner({required this.type, required this.field, required this.address, required this.scope});
  

@override final  skir.TypeSelection type;
@override final  String field;
@override final  AuthoredBindingAddress address;
@override final  PortablePresentationScope scope;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableRecordFieldOwnerCopyWith<_PortableRecordFieldOwner> get copyWith => __$PortableRecordFieldOwnerCopyWithImpl<_PortableRecordFieldOwner>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableRecordFieldOwner&&(identical(other.type, type) || other.type == type)&&(identical(other.field, field) || other.field == field)&&(identical(other.address, address) || other.address == address)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,field,address,scope);
}

@override
String toString() {
    return 'PortableRecordFieldOwner(type: $type, field: $field, address: $address, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$PortableRecordFieldOwnerCopyWith<$Res> implements $PortableRecordFieldOwnerCopyWith<$Res> {
  factory _$PortableRecordFieldOwnerCopyWith(_PortableRecordFieldOwner value, $Res Function(_PortableRecordFieldOwner) _then) = __$PortableRecordFieldOwnerCopyWithImpl;
@override @useResult
$Res call({
 skir.TypeSelection type, String field, AuthoredBindingAddress address, PortablePresentationScope scope
});


@override $AuthoredBindingAddressCopyWith<$Res> get address;@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$PortableRecordFieldOwnerCopyWithImpl<$Res>
    implements _$PortableRecordFieldOwnerCopyWith<$Res> {
  __$PortableRecordFieldOwnerCopyWithImpl(this._self, this._then);

  final _PortableRecordFieldOwner _self;
  final $Res Function(_PortableRecordFieldOwner) _then;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? field = null,Object? address = null,Object? scope = null,}) {
  return _then(_PortableRecordFieldOwner(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {
  
  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$ActiveFieldPresentation {

 EditorFieldPresentationIdentity get identity; AuthoredBindingAddress get owner;
/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveFieldPresentationCopyWith<ActiveFieldPresentation> get copyWith => _$ActiveFieldPresentationCopyWithImpl<ActiveFieldPresentation>(this as ActiveFieldPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveFieldPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveFieldPresentation&&(identical(other.identity, _this.identity) || other.identity == _this.identity)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as ActiveFieldPresentation;
  return Object.hash(runtimeType,_this.identity,_this.owner);
}

@override
String toString() {
  final _this = this as ActiveFieldPresentation;
  return 'ActiveFieldPresentation(identity: ${_this.identity}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $ActiveFieldPresentationCopyWith<$Res>  {
  factory $ActiveFieldPresentationCopyWith(ActiveFieldPresentation value, $Res Function(ActiveFieldPresentation) _then) = _$ActiveFieldPresentationCopyWithImpl;
@useResult
$Res call({
 EditorFieldPresentationIdentity identity, AuthoredBindingAddress owner
});


$EditorFieldPresentationIdentityCopyWith<$Res> get identity;$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActiveFieldPresentationCopyWithImpl<$Res>
    implements $ActiveFieldPresentationCopyWith<$Res> {
  _$ActiveFieldPresentationCopyWithImpl(this._self, this._then);

  final ActiveFieldPresentation _self;
  final $Res Function(ActiveFieldPresentation) _then;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? owner = null,}) {
  return _then(ActiveFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}
/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {
  
  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveFieldPresentation].
extension ActiveFieldPresentationPatterns on ActiveFieldPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveFieldPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveFieldPresentation value)  $default,){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveFieldPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
return $default(_that.identity,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)  $default,) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation():
return $default(_that.identity,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)?  $default,) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
return $default(_that.identity,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveFieldPresentation implements ActiveFieldPresentation {
  const _ActiveFieldPresentation({required this.identity, required this.owner});
  

@override final  EditorFieldPresentationIdentity identity;
@override final  AuthoredBindingAddress owner;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveFieldPresentationCopyWith<_ActiveFieldPresentation> get copyWith => __$ActiveFieldPresentationCopyWithImpl<_ActiveFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,owner);
}

@override
String toString() {
    return 'ActiveFieldPresentation(identity: $identity, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$ActiveFieldPresentationCopyWith<$Res> implements $ActiveFieldPresentationCopyWith<$Res> {
  factory _$ActiveFieldPresentationCopyWith(_ActiveFieldPresentation value, $Res Function(_ActiveFieldPresentation) _then) = __$ActiveFieldPresentationCopyWithImpl;
@override @useResult
$Res call({
 EditorFieldPresentationIdentity identity, AuthoredBindingAddress owner
});


@override $EditorFieldPresentationIdentityCopyWith<$Res> get identity;@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActiveFieldPresentationCopyWithImpl<$Res>
    implements _$ActiveFieldPresentationCopyWith<$Res> {
  __$ActiveFieldPresentationCopyWithImpl(this._self, this._then);

  final _ActiveFieldPresentation _self;
  final $Res Function(_ActiveFieldPresentation) _then;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? owner = null,}) {
  return _then(_ActiveFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {
  
  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$PortableAuthoredPart {

 String get nodeId; skir.PresentationPartElement get part; AuthoredBindingAddress? get owner;
/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableAuthoredPartCopyWith<PortableAuthoredPart> get copyWith => _$PortableAuthoredPartCopyWithImpl<PortableAuthoredPart>(this as PortableAuthoredPart, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableAuthoredPart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAuthoredPart&&(identical(other.nodeId, _this.nodeId) || other.nodeId == _this.nodeId)&&(identical(other.part, _this.part) || other.part == _this.part)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as PortableAuthoredPart;
  return Object.hash(runtimeType,_this.nodeId,_this.part,_this.owner);
}

@override
String toString() {
  final _this = this as PortableAuthoredPart;
  return 'PortableAuthoredPart(nodeId: ${_this.nodeId}, part: ${_this.part}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $PortableAuthoredPartCopyWith<$Res>  {
  factory $PortableAuthoredPartCopyWith(PortableAuthoredPart value, $Res Function(PortableAuthoredPart) _then) = _$PortableAuthoredPartCopyWithImpl;
@useResult
$Res call({
 String nodeId, skir.PresentationPartElement part, AuthoredBindingAddress? owner
});


$AuthoredBindingAddressCopyWith<$Res>? get owner;

}
/// @nodoc
class _$PortableAuthoredPartCopyWithImpl<$Res>
    implements $PortableAuthoredPartCopyWith<$Res> {
  _$PortableAuthoredPartCopyWithImpl(this._self, this._then);

  final PortableAuthoredPart _self;
  final $Res Function(PortableAuthoredPart) _then;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodeId = null,Object? part = null,Object? owner = freezed,}) {
  return _then(PortableAuthoredPart(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartElement,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress?,
  ));
}
/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableAuthoredPart].
extension PortableAuthoredPartPatterns on PortableAuthoredPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableAuthoredPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableAuthoredPart value)  $default,){
final _that = this;
switch (_that) {
case _PortableAuthoredPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableAuthoredPart value)?  $default,){
final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
return $default(_that.nodeId,_that.part,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)  $default,) {final _that = this;
switch (_that) {
case _PortableAuthoredPart():
return $default(_that.nodeId,_that.part,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)?  $default,) {final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
return $default(_that.nodeId,_that.part,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _PortableAuthoredPart implements PortableAuthoredPart {
  const _PortableAuthoredPart({required this.nodeId, required this.part, required this.owner});
  

@override final  String nodeId;
@override final  skir.PresentationPartElement part;
@override final  AuthoredBindingAddress? owner;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAuthoredPartCopyWith<_PortableAuthoredPart> get copyWith => __$PortableAuthoredPartCopyWithImpl<_PortableAuthoredPart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAuthoredPart&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.part, part) || other.part == part)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nodeId,part,owner);
}

@override
String toString() {
    return 'PortableAuthoredPart(nodeId: $nodeId, part: $part, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$PortableAuthoredPartCopyWith<$Res> implements $PortableAuthoredPartCopyWith<$Res> {
  factory _$PortableAuthoredPartCopyWith(_PortableAuthoredPart value, $Res Function(_PortableAuthoredPart) _then) = __$PortableAuthoredPartCopyWithImpl;
@override @useResult
$Res call({
 String nodeId, skir.PresentationPartElement part, AuthoredBindingAddress? owner
});


@override $AuthoredBindingAddressCopyWith<$Res>? get owner;

}
/// @nodoc
class __$PortableAuthoredPartCopyWithImpl<$Res>
    implements _$PortableAuthoredPartCopyWith<$Res> {
  __$PortableAuthoredPartCopyWithImpl(this._self, this._then);

  final _PortableAuthoredPart _self;
  final $Res Function(_PortableAuthoredPart) _then;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodeId = null,Object? part = null,Object? owner = freezed,}) {
  return _then(_PortableAuthoredPart(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartElement,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress?,
  ));
}

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$PortableInspectorClaims {

 Set<String> get editedFields; Set<String> get reservedFields; Set<String> get excludedFields; Set<skir.PresentationPartId> get parts; Map<String, String> get problems;
/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<PortableInspectorClaims> get copyWith => _$PortableInspectorClaimsCopyWithImpl<PortableInspectorClaims>(this as PortableInspectorClaims, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableInspectorClaims;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableInspectorClaims&&const DeepCollectionEquality().equals(other.editedFields, _this.editedFields)&&const DeepCollectionEquality().equals(other.reservedFields, _this.reservedFields)&&const DeepCollectionEquality().equals(other.excludedFields, _this.excludedFields)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.problems, _this.problems));
}


@override
int get hashCode {
  final _this = this as PortableInspectorClaims;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.editedFields),const DeepCollectionEquality().hash(_this.reservedFields),const DeepCollectionEquality().hash(_this.excludedFields),const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.problems));
}

@override
String toString() {
  final _this = this as PortableInspectorClaims;
  return 'PortableInspectorClaims(editedFields: ${_this.editedFields}, reservedFields: ${_this.reservedFields}, excludedFields: ${_this.excludedFields}, parts: ${_this.parts}, problems: ${_this.problems})';
}


}

/// @nodoc
abstract mixin class $PortableInspectorClaimsCopyWith<$Res>  {
  factory $PortableInspectorClaimsCopyWith(PortableInspectorClaims value, $Res Function(PortableInspectorClaims) _then) = _$PortableInspectorClaimsCopyWithImpl;
@useResult
$Res call({
 Set<String> editedFields, Set<String> reservedFields, Set<String> excludedFields, Set<skir.PresentationPartId> parts, Map<String, String> problems
});




}
/// @nodoc
class _$PortableInspectorClaimsCopyWithImpl<$Res>
    implements $PortableInspectorClaimsCopyWith<$Res> {
  _$PortableInspectorClaimsCopyWithImpl(this._self, this._then);

  final PortableInspectorClaims _self;
  final $Res Function(PortableInspectorClaims) _then;

/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? editedFields = null,Object? reservedFields = null,Object? excludedFields = null,Object? parts = null,Object? problems = null,}) {
  return _then(PortableInspectorClaims(
editedFields: null == editedFields ? _self.editedFields : editedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,reservedFields: null == reservedFields ? _self.reservedFields : reservedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedFields: null == excludedFields ? _self.excludedFields : excludedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,problems: null == problems ? _self.problems : problems // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableInspectorClaims].
extension PortableInspectorClaimsPatterns on PortableInspectorClaims {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableInspectorClaims value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableInspectorClaims value)  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorClaims():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableInspectorClaims value)?  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorClaims():
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)?  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
  return null;

}
}

}

/// @nodoc


class _PortableInspectorClaims implements PortableInspectorClaims {
  const _PortableInspectorClaims({ Set<String> editedFields = const {},  Set<String> reservedFields = const {},  Set<String> excludedFields = const {},  Set<skir.PresentationPartId> parts = const {},  Map<String, String> problems = const {}}): _editedFields = editedFields,_reservedFields = reservedFields,_excludedFields = excludedFields,_parts = parts,_problems = problems;
  

 final  Set<String> _editedFields;
@override@JsonKey() Set<String> get editedFields {
  if (_editedFields is EqualUnmodifiableSetView) return _editedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_editedFields);
}

 final  Set<String> _reservedFields;
@override@JsonKey() Set<String> get reservedFields {
  if (_reservedFields is EqualUnmodifiableSetView) return _reservedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_reservedFields);
}

 final  Set<String> _excludedFields;
@override@JsonKey() Set<String> get excludedFields {
  if (_excludedFields is EqualUnmodifiableSetView) return _excludedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_excludedFields);
}

 final  Set<skir.PresentationPartId> _parts;
@override@JsonKey() Set<skir.PresentationPartId> get parts {
  if (_parts is EqualUnmodifiableSetView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_parts);
}

 final  Map<String, String> _problems;
@override@JsonKey() Map<String, String> get problems {
  if (_problems is EqualUnmodifiableMapView) return _problems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_problems);
}


/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableInspectorClaimsCopyWith<_PortableInspectorClaims> get copyWith => __$PortableInspectorClaimsCopyWithImpl<_PortableInspectorClaims>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableInspectorClaims&&const DeepCollectionEquality().equals(other.editedFields, _editedFields)&&const DeepCollectionEquality().equals(other.reservedFields, _reservedFields)&&const DeepCollectionEquality().equals(other.excludedFields, _excludedFields)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.problems, _problems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_editedFields),const DeepCollectionEquality().hash(_reservedFields),const DeepCollectionEquality().hash(_excludedFields),const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_problems));
}

@override
String toString() {
    return 'PortableInspectorClaims(editedFields: $editedFields, reservedFields: $reservedFields, excludedFields: $excludedFields, parts: $parts, problems: $problems)';
}


}

/// @nodoc
abstract mixin class _$PortableInspectorClaimsCopyWith<$Res> implements $PortableInspectorClaimsCopyWith<$Res> {
  factory _$PortableInspectorClaimsCopyWith(_PortableInspectorClaims value, $Res Function(_PortableInspectorClaims) _then) = __$PortableInspectorClaimsCopyWithImpl;
@override @useResult
$Res call({
 Set<String> editedFields, Set<String> reservedFields, Set<String> excludedFields, Set<skir.PresentationPartId> parts, Map<String, String> problems
});




}
/// @nodoc
class __$PortableInspectorClaimsCopyWithImpl<$Res>
    implements _$PortableInspectorClaimsCopyWith<$Res> {
  __$PortableInspectorClaimsCopyWithImpl(this._self, this._then);

  final _PortableInspectorClaims _self;
  final $Res Function(_PortableInspectorClaims) _then;

/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? editedFields = null,Object? reservedFields = null,Object? excludedFields = null,Object? parts = null,Object? problems = null,}) {
  return _then(_PortableInspectorClaims(
editedFields: null == editedFields ? _self._editedFields : editedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,reservedFields: null == reservedFields ? _self._reservedFields : reservedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedFields: null == excludedFields ? _self._excludedFields : excludedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,problems: null == problems ? _self._problems : problems // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc
mixin _$PortableInspectorFrame {

 AuthoredBindingAddress get owner; skir.TypeSelection get actualType; skir.PresentationTarget get sourceTarget; skir.PresentationId get source; PortableInspectorClaims get higher;
/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<PortableInspectorFrame> get copyWith => _$PortableInspectorFrameCopyWithImpl<PortableInspectorFrame>(this as PortableInspectorFrame, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableInspectorFrame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableInspectorFrame&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.actualType, _this.actualType) || other.actualType == _this.actualType)&&(identical(other.sourceTarget, _this.sourceTarget) || other.sourceTarget == _this.sourceTarget)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.higher, _this.higher) || other.higher == _this.higher));
}


@override
int get hashCode {
  final _this = this as PortableInspectorFrame;
  return Object.hash(runtimeType,_this.owner,_this.actualType,_this.sourceTarget,_this.source,_this.higher);
}

@override
String toString() {
  final _this = this as PortableInspectorFrame;
  return 'PortableInspectorFrame(owner: ${_this.owner}, actualType: ${_this.actualType}, sourceTarget: ${_this.sourceTarget}, source: ${_this.source}, higher: ${_this.higher})';
}


}

/// @nodoc
abstract mixin class $PortableInspectorFrameCopyWith<$Res>  {
  factory $PortableInspectorFrameCopyWith(PortableInspectorFrame value, $Res Function(PortableInspectorFrame) _then) = _$PortableInspectorFrameCopyWithImpl;
@useResult
$Res call({
 AuthoredBindingAddress owner, skir.TypeSelection actualType, skir.PresentationTarget sourceTarget, skir.PresentationId source, PortableInspectorClaims higher
});


$AuthoredBindingAddressCopyWith<$Res> get owner;$PortableInspectorClaimsCopyWith<$Res> get higher;

}
/// @nodoc
class _$PortableInspectorFrameCopyWithImpl<$Res>
    implements $PortableInspectorFrameCopyWith<$Res> {
  _$PortableInspectorFrameCopyWithImpl(this._self, this._then);

  final PortableInspectorFrame _self;
  final $Res Function(PortableInspectorFrame) _then;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? actualType = null,Object? sourceTarget = null,Object? source = null,Object? higher = null,}) {
  return _then(PortableInspectorFrame(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,sourceTarget: null == sourceTarget ? _self.sourceTarget : sourceTarget // ignore: cast_nullable_to_non_nullable
as skir.PresentationTarget,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,higher: null == higher ? _self.higher : higher // ignore: cast_nullable_to_non_nullable
as PortableInspectorClaims,
  ));
}
/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<$Res> get higher {
  
  return $PortableInspectorClaimsCopyWith<$Res>(_self.higher, (value) {
    return _then(_self.copyWith(higher: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableInspectorFrame].
extension PortableInspectorFramePatterns on PortableInspectorFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableInspectorFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableInspectorFrame value)  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableInspectorFrame value)?  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorFrame():
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)?  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
  return null;

}
}

}

/// @nodoc


class _PortableInspectorFrame implements PortableInspectorFrame {
  const _PortableInspectorFrame({required this.owner, required this.actualType, required this.sourceTarget, required this.source, this.higher = const PortableInspectorClaims()});
  

@override final  AuthoredBindingAddress owner;
@override final  skir.TypeSelection actualType;
@override final  skir.PresentationTarget sourceTarget;
@override final  skir.PresentationId source;
@override@JsonKey() final  PortableInspectorClaims higher;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableInspectorFrameCopyWith<_PortableInspectorFrame> get copyWith => __$PortableInspectorFrameCopyWithImpl<_PortableInspectorFrame>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableInspectorFrame&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.actualType, actualType) || other.actualType == actualType)&&(identical(other.sourceTarget, sourceTarget) || other.sourceTarget == sourceTarget)&&(identical(other.source, source) || other.source == source)&&(identical(other.higher, higher) || other.higher == higher));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,actualType,sourceTarget,source,higher);
}

@override
String toString() {
    return 'PortableInspectorFrame(owner: $owner, actualType: $actualType, sourceTarget: $sourceTarget, source: $source, higher: $higher)';
}


}

/// @nodoc
abstract mixin class _$PortableInspectorFrameCopyWith<$Res> implements $PortableInspectorFrameCopyWith<$Res> {
  factory _$PortableInspectorFrameCopyWith(_PortableInspectorFrame value, $Res Function(_PortableInspectorFrame) _then) = __$PortableInspectorFrameCopyWithImpl;
@override @useResult
$Res call({
 AuthoredBindingAddress owner, skir.TypeSelection actualType, skir.PresentationTarget sourceTarget, skir.PresentationId source, PortableInspectorClaims higher
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;@override $PortableInspectorClaimsCopyWith<$Res> get higher;

}
/// @nodoc
class __$PortableInspectorFrameCopyWithImpl<$Res>
    implements _$PortableInspectorFrameCopyWith<$Res> {
  __$PortableInspectorFrameCopyWithImpl(this._self, this._then);

  final _PortableInspectorFrame _self;
  final $Res Function(_PortableInspectorFrame) _then;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? actualType = null,Object? sourceTarget = null,Object? source = null,Object? higher = null,}) {
  return _then(_PortableInspectorFrame(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,sourceTarget: null == sourceTarget ? _self.sourceTarget : sourceTarget // ignore: cast_nullable_to_non_nullable
as skir.PresentationTarget,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,higher: null == higher ? _self.higher : higher // ignore: cast_nullable_to_non_nullable
as PortableInspectorClaims,
  ));
}

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<$Res> get higher {
  
  return $PortableInspectorClaimsCopyWith<$Res>(_self.higher, (value) {
    return _then(_self.copyWith(higher: value));
  });
}
}

/// @nodoc
mixin _$ActiveInspectorLayout {

 skir.PresentationId get source; AuthoredBindingAddress get owner;
/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveInspectorLayoutCopyWith<ActiveInspectorLayout> get copyWith => _$ActiveInspectorLayoutCopyWithImpl<ActiveInspectorLayout>(this as ActiveInspectorLayout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveInspectorLayout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveInspectorLayout&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as ActiveInspectorLayout;
  return Object.hash(runtimeType,_this.source,_this.owner);
}

@override
String toString() {
  final _this = this as ActiveInspectorLayout;
  return 'ActiveInspectorLayout(source: ${_this.source}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $ActiveInspectorLayoutCopyWith<$Res>  {
  factory $ActiveInspectorLayoutCopyWith(ActiveInspectorLayout value, $Res Function(ActiveInspectorLayout) _then) = _$ActiveInspectorLayoutCopyWithImpl;
@useResult
$Res call({
 skir.PresentationId source, AuthoredBindingAddress owner
});


$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActiveInspectorLayoutCopyWithImpl<$Res>
    implements $ActiveInspectorLayoutCopyWith<$Res> {
  _$ActiveInspectorLayoutCopyWithImpl(this._self, this._then);

  final ActiveInspectorLayout _self;
  final $Res Function(ActiveInspectorLayout) _then;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? owner = null,}) {
  return _then(ActiveInspectorLayout(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}
/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveInspectorLayout].
extension ActiveInspectorLayoutPatterns on ActiveInspectorLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveInspectorLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveInspectorLayout value)  $default,){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveInspectorLayout value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationId source,  AuthoredBindingAddress owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
return $default(_that.source,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationId source,  AuthoredBindingAddress owner)  $default,) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout():
return $default(_that.source,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationId source,  AuthoredBindingAddress owner)?  $default,) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
return $default(_that.source,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveInspectorLayout implements ActiveInspectorLayout {
  const _ActiveInspectorLayout({required this.source, required this.owner});
  

@override final  skir.PresentationId source;
@override final  AuthoredBindingAddress owner;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveInspectorLayoutCopyWith<_ActiveInspectorLayout> get copyWith => __$ActiveInspectorLayoutCopyWithImpl<_ActiveInspectorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveInspectorLayout&&(identical(other.source, source) || other.source == source)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,owner);
}

@override
String toString() {
    return 'ActiveInspectorLayout(source: $source, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$ActiveInspectorLayoutCopyWith<$Res> implements $ActiveInspectorLayoutCopyWith<$Res> {
  factory _$ActiveInspectorLayoutCopyWith(_ActiveInspectorLayout value, $Res Function(_ActiveInspectorLayout) _then) = __$ActiveInspectorLayoutCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationId source, AuthoredBindingAddress owner
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActiveInspectorLayoutCopyWithImpl<$Res>
    implements _$ActiveInspectorLayoutCopyWith<$Res> {
  __$ActiveInspectorLayoutCopyWithImpl(this._self, this._then);

  final _ActiveInspectorLayout _self;
  final $Res Function(_ActiveInspectorLayout) _then;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? owner = null,}) {
  return _then(_ActiveInspectorLayout(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$ActivePartPresentation {

 skir.PresentationPartId get key; AuthoredBindingAddress get owner; skir.PresentationRole get role;
/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePartPresentationCopyWith<ActivePartPresentation> get copyWith => _$ActivePartPresentationCopyWithImpl<ActivePartPresentation>(this as ActivePartPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivePartPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePartPresentation&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.role, _this.role) || other.role == _this.role));
}


@override
int get hashCode {
  final _this = this as ActivePartPresentation;
  return Object.hash(runtimeType,_this.key,_this.owner,_this.role);
}

@override
String toString() {
  final _this = this as ActivePartPresentation;
  return 'ActivePartPresentation(key: ${_this.key}, owner: ${_this.owner}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $ActivePartPresentationCopyWith<$Res>  {
  factory $ActivePartPresentationCopyWith(ActivePartPresentation value, $Res Function(ActivePartPresentation) _then) = _$ActivePartPresentationCopyWithImpl;
@useResult
$Res call({
 skir.PresentationPartId key, AuthoredBindingAddress owner, skir.PresentationRole role
});


$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActivePartPresentationCopyWithImpl<$Res>
    implements $ActivePartPresentationCopyWith<$Res> {
  _$ActivePartPresentationCopyWithImpl(this._self, this._then);

  final ActivePartPresentation _self;
  final $Res Function(ActivePartPresentation) _then;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? owner = null,Object? role = null,}) {
  return _then(ActivePartPresentation(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,
  ));
}
/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivePartPresentation].
extension ActivePartPresentationPatterns on ActivePartPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePartPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePartPresentation value)  $default,){
final _that = this;
switch (_that) {
case _ActivePartPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePartPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
return $default(_that.key,_that.owner,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)  $default,) {final _that = this;
switch (_that) {
case _ActivePartPresentation():
return $default(_that.key,_that.owner,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)?  $default,) {final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
return $default(_that.key,_that.owner,_that.role);case _:
  return null;

}
}

}

/// @nodoc


class _ActivePartPresentation implements ActivePartPresentation {
  const _ActivePartPresentation({required this.key, required this.owner, required this.role});
  

@override final  skir.PresentationPartId key;
@override final  AuthoredBindingAddress owner;
@override final  skir.PresentationRole role;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePartPresentationCopyWith<_ActivePartPresentation> get copyWith => __$ActivePartPresentationCopyWithImpl<_ActivePartPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePartPresentation&&(identical(other.key, key) || other.key == key)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,owner,role);
}

@override
String toString() {
    return 'ActivePartPresentation(key: $key, owner: $owner, role: $role)';
}


}

/// @nodoc
abstract mixin class _$ActivePartPresentationCopyWith<$Res> implements $ActivePartPresentationCopyWith<$Res> {
  factory _$ActivePartPresentationCopyWith(_ActivePartPresentation value, $Res Function(_ActivePartPresentation) _then) = __$ActivePartPresentationCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationPartId key, AuthoredBindingAddress owner, skir.PresentationRole role
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActivePartPresentationCopyWithImpl<$Res>
    implements _$ActivePartPresentationCopyWith<$Res> {
  __$ActivePartPresentationCopyWithImpl(this._self, this._then);

  final _ActivePartPresentation _self;
  final $Res Function(_ActivePartPresentation) _then;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? owner = null,Object? role = null,}) {
  return _then(_ActivePartPresentation(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,
  ));
}

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {
  
  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$AuthoredLinkDecision {

 PortableLinkPlan get plan; PortableLinkTargetChoice get target; PortableLinkCounterpartRequest get counterpart;
/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredLinkDecisionCopyWith<_AuthoredLinkDecision> get copyWith => __$AuthoredLinkDecisionCopyWithImpl<_AuthoredLinkDecision>(this as _AuthoredLinkDecision, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _AuthoredLinkDecision;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredLinkDecision&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.counterpart, _this.counterpart) || other.counterpart == _this.counterpart));
}


@override
int get hashCode {
  final _this = this as _AuthoredLinkDecision;
  return Object.hash(runtimeType,_this.plan,_this.target,_this.counterpart);
}

@override
String toString() {
  final _this = this as _AuthoredLinkDecision;
  return '_AuthoredLinkDecision(plan: ${_this.plan}, target: ${_this.target}, counterpart: ${_this.counterpart})';
}


}

/// @nodoc
abstract mixin class _$AuthoredLinkDecisionCopyWith<$Res>  {
  factory _$AuthoredLinkDecisionCopyWith(_AuthoredLinkDecision value, $Res Function(_AuthoredLinkDecision) _then) = __$AuthoredLinkDecisionCopyWithImpl;
@useResult
$Res call({
 PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart
});


$PortableLinkPlanCopyWith<$Res> get plan;$PortableLinkTargetChoiceCopyWith<$Res> get target;$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class __$AuthoredLinkDecisionCopyWithImpl<$Res>
    implements _$AuthoredLinkDecisionCopyWith<$Res> {
  __$AuthoredLinkDecisionCopyWithImpl(this._self, this._then);

  final _AuthoredLinkDecision _self;
  final $Res Function(_AuthoredLinkDecision) _then;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? target = null,Object? counterpart = null,}) {
  return _then(_AuthoredLinkDecision(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,
  ));
}
/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {
  
  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {
  
  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {
  
  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}


/// Adds pattern-matching-related methods to [_AuthoredLinkDecision].
extension _AuthoredLinkDecisionPatterns on _AuthoredLinkDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __AuthoredLinkDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __AuthoredLinkDecision value)  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __AuthoredLinkDecision value)?  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
return $default(_that.plan,_that.target,_that.counterpart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision():
return $default(_that.plan,_that.target,_that.counterpart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)?  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
return $default(_that.plan,_that.target,_that.counterpart);case _:
  return null;

}
}

}

/// @nodoc


class __AuthoredLinkDecision implements _AuthoredLinkDecision {
  const __AuthoredLinkDecision({required this.plan, required this.target, required this.counterpart});
  

@override final  PortableLinkPlan plan;
@override final  PortableLinkTargetChoice target;
@override final  PortableLinkCounterpartRequest counterpart;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_AuthoredLinkDecisionCopyWith<__AuthoredLinkDecision> get copyWith => __$_AuthoredLinkDecisionCopyWithImpl<__AuthoredLinkDecision>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __AuthoredLinkDecision&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.target, target) || other.target == target)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart));
}


@override
int get hashCode {
    return Object.hash(runtimeType,plan,target,counterpart);
}

@override
String toString() {
    return '_AuthoredLinkDecision(plan: $plan, target: $target, counterpart: $counterpart)';
}


}

/// @nodoc
abstract mixin class _$_AuthoredLinkDecisionCopyWith<$Res> implements _$AuthoredLinkDecisionCopyWith<$Res> {
  factory _$_AuthoredLinkDecisionCopyWith(__AuthoredLinkDecision value, $Res Function(__AuthoredLinkDecision) _then) = __$_AuthoredLinkDecisionCopyWithImpl;
@override @useResult
$Res call({
 PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart
});


@override $PortableLinkPlanCopyWith<$Res> get plan;@override $PortableLinkTargetChoiceCopyWith<$Res> get target;@override $PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class __$_AuthoredLinkDecisionCopyWithImpl<$Res>
    implements _$_AuthoredLinkDecisionCopyWith<$Res> {
  __$_AuthoredLinkDecisionCopyWithImpl(this._self, this._then);

  final __AuthoredLinkDecision _self;
  final $Res Function(__AuthoredLinkDecision) _then;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? target = null,Object? counterpart = null,}) {
  return _then(__AuthoredLinkDecision(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,
  ));
}

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {
  
  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {
  
  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {
  
  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}

/// @nodoc
mixin _$AuthoredLinkChoice {

 String get id; String get widgetKey; PortableLinkPlan get plan; PortableLinkTargetChoice get target; _AuthoredLinkChoiceKind get kind; String get label; String get typeLabel; String get subtitle; String get searchText; _AuthoredCollectionRow? get row; skir.PresentationCollectionDefinition? get definition; skir.LinkOccurrence? get occurrence; PortableNewCounterpartChoice? get slot; skir.ValueLocation? get collection; String? get disabledReason;
/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredLinkChoiceCopyWith<_AuthoredLinkChoice> get copyWith => __$AuthoredLinkChoiceCopyWithImpl<_AuthoredLinkChoice>(this as _AuthoredLinkChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _AuthoredLinkChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredLinkChoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.widgetKey, _this.widgetKey) || other.widgetKey == _this.widgetKey)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.typeLabel, _this.typeLabel) || other.typeLabel == _this.typeLabel)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.searchText, _this.searchText) || other.searchText == _this.searchText)&&(identical(other.row, _this.row) || other.row == _this.row)&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.occurrence, _this.occurrence) || other.occurrence == _this.occurrence)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.collection, _this.collection) || other.collection == _this.collection)&&(identical(other.disabledReason, _this.disabledReason) || other.disabledReason == _this.disabledReason));
}


@override
int get hashCode {
  final _this = this as _AuthoredLinkChoice;
  return Object.hash(runtimeType,_this.id,_this.widgetKey,_this.plan,_this.target,_this.kind,_this.label,_this.typeLabel,_this.subtitle,_this.searchText,_this.row,_this.definition,_this.occurrence,_this.slot,_this.collection,_this.disabledReason);
}

@override
String toString() {
  final _this = this as _AuthoredLinkChoice;
  return '_AuthoredLinkChoice(id: ${_this.id}, widgetKey: ${_this.widgetKey}, plan: ${_this.plan}, target: ${_this.target}, kind: ${_this.kind}, label: ${_this.label}, typeLabel: ${_this.typeLabel}, subtitle: ${_this.subtitle}, searchText: ${_this.searchText}, row: ${_this.row}, definition: ${_this.definition}, occurrence: ${_this.occurrence}, slot: ${_this.slot}, collection: ${_this.collection}, disabledReason: ${_this.disabledReason})';
}


}

/// @nodoc
abstract mixin class _$AuthoredLinkChoiceCopyWith<$Res>  {
  factory _$AuthoredLinkChoiceCopyWith(_AuthoredLinkChoice value, $Res Function(_AuthoredLinkChoice) _then) = __$AuthoredLinkChoiceCopyWithImpl;
@useResult
$Res call({
 String id, String widgetKey, PortableLinkPlan plan, PortableLinkTargetChoice target, _AuthoredLinkChoiceKind kind, String label, String typeLabel, String subtitle, String searchText, _AuthoredCollectionRow? row, skir.PresentationCollectionDefinition? definition, skir.LinkOccurrence? occurrence, PortableNewCounterpartChoice? slot, skir.ValueLocation? collection, String? disabledReason
});


$PortableLinkPlanCopyWith<$Res> get plan;$PortableLinkTargetChoiceCopyWith<$Res> get target;$PortableNewCounterpartChoiceCopyWith<$Res>? get slot;

}
/// @nodoc
class __$AuthoredLinkChoiceCopyWithImpl<$Res>
    implements _$AuthoredLinkChoiceCopyWith<$Res> {
  __$AuthoredLinkChoiceCopyWithImpl(this._self, this._then);

  final _AuthoredLinkChoice _self;
  final $Res Function(_AuthoredLinkChoice) _then;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? widgetKey = null,Object? plan = null,Object? target = null,Object? kind = null,Object? label = null,Object? typeLabel = null,Object? subtitle = null,Object? searchText = null,Object? row = freezed,Object? definition = freezed,Object? occurrence = freezed,Object? slot = freezed,Object? collection = freezed,Object? disabledReason = freezed,}) {
  return _then(_AuthoredLinkChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,widgetKey: null == widgetKey ? _self.widgetKey : widgetKey // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as _AuthoredLinkChoiceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,row: freezed == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as _AuthoredCollectionRow?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,occurrence: freezed == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice?,collection: freezed == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {
  
  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {
  
  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res>? get slot {
    if (_self.slot == null) {
    return null;
  }

  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot!, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}


/// Adds pattern-matching-related methods to [_AuthoredLinkChoice].
extension _AuthoredLinkChoicePatterns on _AuthoredLinkChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __AuthoredLinkChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __AuthoredLinkChoice value)  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __AuthoredLinkChoice value)?  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice():
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)?  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
  return null;

}
}

}

/// @nodoc


class __AuthoredLinkChoice implements _AuthoredLinkChoice {
  const __AuthoredLinkChoice({required this.id, required this.widgetKey, required this.plan, required this.target, required this.kind, required this.label, required this.typeLabel, required this.subtitle, required this.searchText, this.row, this.definition, this.occurrence, this.slot, this.collection, this.disabledReason});
  

@override final  String id;
@override final  String widgetKey;
@override final  PortableLinkPlan plan;
@override final  PortableLinkTargetChoice target;
@override final  _AuthoredLinkChoiceKind kind;
@override final  String label;
@override final  String typeLabel;
@override final  String subtitle;
@override final  String searchText;
@override final  _AuthoredCollectionRow? row;
@override final  skir.PresentationCollectionDefinition? definition;
@override final  skir.LinkOccurrence? occurrence;
@override final  PortableNewCounterpartChoice? slot;
@override final  skir.ValueLocation? collection;
@override final  String? disabledReason;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_AuthoredLinkChoiceCopyWith<__AuthoredLinkChoice> get copyWith => __$_AuthoredLinkChoiceCopyWithImpl<__AuthoredLinkChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __AuthoredLinkChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.widgetKey, widgetKey) || other.widgetKey == widgetKey)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.target, target) || other.target == target)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&(identical(other.row, row) || other.row == row)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.collection, collection) || other.collection == collection)&&(identical(other.disabledReason, disabledReason) || other.disabledReason == disabledReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,widgetKey,plan,target,kind,label,typeLabel,subtitle,searchText,row,definition,occurrence,slot,collection,disabledReason);
}

@override
String toString() {
    return '_AuthoredLinkChoice(id: $id, widgetKey: $widgetKey, plan: $plan, target: $target, kind: $kind, label: $label, typeLabel: $typeLabel, subtitle: $subtitle, searchText: $searchText, row: $row, definition: $definition, occurrence: $occurrence, slot: $slot, collection: $collection, disabledReason: $disabledReason)';
}


}

/// @nodoc
abstract mixin class _$_AuthoredLinkChoiceCopyWith<$Res> implements _$AuthoredLinkChoiceCopyWith<$Res> {
  factory _$_AuthoredLinkChoiceCopyWith(__AuthoredLinkChoice value, $Res Function(__AuthoredLinkChoice) _then) = __$_AuthoredLinkChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String widgetKey, PortableLinkPlan plan, PortableLinkTargetChoice target, _AuthoredLinkChoiceKind kind, String label, String typeLabel, String subtitle, String searchText, _AuthoredCollectionRow? row, skir.PresentationCollectionDefinition? definition, skir.LinkOccurrence? occurrence, PortableNewCounterpartChoice? slot, skir.ValueLocation? collection, String? disabledReason
});


@override $PortableLinkPlanCopyWith<$Res> get plan;@override $PortableLinkTargetChoiceCopyWith<$Res> get target;@override $PortableNewCounterpartChoiceCopyWith<$Res>? get slot;

}
/// @nodoc
class __$_AuthoredLinkChoiceCopyWithImpl<$Res>
    implements _$_AuthoredLinkChoiceCopyWith<$Res> {
  __$_AuthoredLinkChoiceCopyWithImpl(this._self, this._then);

  final __AuthoredLinkChoice _self;
  final $Res Function(__AuthoredLinkChoice) _then;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? widgetKey = null,Object? plan = null,Object? target = null,Object? kind = null,Object? label = null,Object? typeLabel = null,Object? subtitle = null,Object? searchText = null,Object? row = freezed,Object? definition = freezed,Object? occurrence = freezed,Object? slot = freezed,Object? collection = freezed,Object? disabledReason = freezed,}) {
  return _then(__AuthoredLinkChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,widgetKey: null == widgetKey ? _self.widgetKey : widgetKey // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as _AuthoredLinkChoiceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,row: freezed == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as _AuthoredCollectionRow?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,occurrence: freezed == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice?,collection: freezed == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {
  
  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {
  
  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res>? get slot {
    if (_self.slot == null) {
    return null;
  }

  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot!, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

/// @nodoc
mixin _$TransformValues {

 double get scale; double get rotateX; double get rotateY; double get rotateZ; double get translateX; double get translateY;
/// Create a copy of _TransformValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransformValuesCopyWith<_TransformValues> get copyWith => __$TransformValuesCopyWithImpl<_TransformValues>(this as _TransformValues, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _TransformValues;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransformValues&&(identical(other.scale, _this.scale) || other.scale == _this.scale)&&(identical(other.rotateX, _this.rotateX) || other.rotateX == _this.rotateX)&&(identical(other.rotateY, _this.rotateY) || other.rotateY == _this.rotateY)&&(identical(other.rotateZ, _this.rotateZ) || other.rotateZ == _this.rotateZ)&&(identical(other.translateX, _this.translateX) || other.translateX == _this.translateX)&&(identical(other.translateY, _this.translateY) || other.translateY == _this.translateY));
}


@override
int get hashCode {
  final _this = this as _TransformValues;
  return Object.hash(runtimeType,_this.scale,_this.rotateX,_this.rotateY,_this.rotateZ,_this.translateX,_this.translateY);
}

@override
String toString() {
  final _this = this as _TransformValues;
  return '_TransformValues(scale: ${_this.scale}, rotateX: ${_this.rotateX}, rotateY: ${_this.rotateY}, rotateZ: ${_this.rotateZ}, translateX: ${_this.translateX}, translateY: ${_this.translateY})';
}


}

/// @nodoc
abstract mixin class _$TransformValuesCopyWith<$Res>  {
  factory _$TransformValuesCopyWith(_TransformValues value, $Res Function(_TransformValues) _then) = __$TransformValuesCopyWithImpl;
@useResult
$Res call({
 double scale, double rotateX, double rotateY, double rotateZ, double translateX, double translateY
});




}
/// @nodoc
class __$TransformValuesCopyWithImpl<$Res>
    implements _$TransformValuesCopyWith<$Res> {
  __$TransformValuesCopyWithImpl(this._self, this._then);

  final _TransformValues _self;
  final $Res Function(_TransformValues) _then;

/// Create a copy of _TransformValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scale = null,Object? rotateX = null,Object? rotateY = null,Object? rotateZ = null,Object? translateX = null,Object? translateY = null,}) {
  return _then(_TransformValues(
scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotateX: null == rotateX ? _self.rotateX : rotateX // ignore: cast_nullable_to_non_nullable
as double,rotateY: null == rotateY ? _self.rotateY : rotateY // ignore: cast_nullable_to_non_nullable
as double,rotateZ: null == rotateZ ? _self.rotateZ : rotateZ // ignore: cast_nullable_to_non_nullable
as double,translateX: null == translateX ? _self.translateX : translateX // ignore: cast_nullable_to_non_nullable
as double,translateY: null == translateY ? _self.translateY : translateY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [_TransformValues].
extension _TransformValuesPatterns on _TransformValues {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __TransformValues value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __TransformValues() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __TransformValues value)  $default,){
final _that = this;
switch (_that) {
case __TransformValues():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __TransformValues value)?  $default,){
final _that = this;
switch (_that) {
case __TransformValues() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double scale,  double rotateX,  double rotateY,  double rotateZ,  double translateX,  double translateY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __TransformValues() when $default != null:
return $default(_that.scale,_that.rotateX,_that.rotateY,_that.rotateZ,_that.translateX,_that.translateY);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double scale,  double rotateX,  double rotateY,  double rotateZ,  double translateX,  double translateY)  $default,) {final _that = this;
switch (_that) {
case __TransformValues():
return $default(_that.scale,_that.rotateX,_that.rotateY,_that.rotateZ,_that.translateX,_that.translateY);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double scale,  double rotateX,  double rotateY,  double rotateZ,  double translateX,  double translateY)?  $default,) {final _that = this;
switch (_that) {
case __TransformValues() when $default != null:
return $default(_that.scale,_that.rotateX,_that.rotateY,_that.rotateZ,_that.translateX,_that.translateY);case _:
  return null;

}
}

}

/// @nodoc


class __TransformValues extends _TransformValues {
  const __TransformValues({required this.scale, required this.rotateX, required this.rotateY, required this.rotateZ, required this.translateX, required this.translateY}): super._();
  

@override final  double scale;
@override final  double rotateX;
@override final  double rotateY;
@override final  double rotateZ;
@override final  double translateX;
@override final  double translateY;

/// Create a copy of _TransformValues
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_TransformValuesCopyWith<__TransformValues> get copyWith => __$_TransformValuesCopyWithImpl<__TransformValues>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __TransformValues&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.rotateX, rotateX) || other.rotateX == rotateX)&&(identical(other.rotateY, rotateY) || other.rotateY == rotateY)&&(identical(other.rotateZ, rotateZ) || other.rotateZ == rotateZ)&&(identical(other.translateX, translateX) || other.translateX == translateX)&&(identical(other.translateY, translateY) || other.translateY == translateY));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scale,rotateX,rotateY,rotateZ,translateX,translateY);
}

@override
String toString() {
    return '_TransformValues(scale: $scale, rotateX: $rotateX, rotateY: $rotateY, rotateZ: $rotateZ, translateX: $translateX, translateY: $translateY)';
}


}

/// @nodoc
abstract mixin class _$_TransformValuesCopyWith<$Res> implements _$TransformValuesCopyWith<$Res> {
  factory _$_TransformValuesCopyWith(__TransformValues value, $Res Function(__TransformValues) _then) = __$_TransformValuesCopyWithImpl;
@override @useResult
$Res call({
 double scale, double rotateX, double rotateY, double rotateZ, double translateX, double translateY
});




}
/// @nodoc
class __$_TransformValuesCopyWithImpl<$Res>
    implements _$_TransformValuesCopyWith<$Res> {
  __$_TransformValuesCopyWithImpl(this._self, this._then);

  final __TransformValues _self;
  final $Res Function(__TransformValues) _then;

/// Create a copy of _TransformValues
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scale = null,Object? rotateX = null,Object? rotateY = null,Object? rotateZ = null,Object? translateX = null,Object? translateY = null,}) {
  return _then(__TransformValues(
scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotateX: null == rotateX ? _self.rotateX : rotateX // ignore: cast_nullable_to_non_nullable
as double,rotateY: null == rotateY ? _self.rotateY : rotateY // ignore: cast_nullable_to_non_nullable
as double,rotateZ: null == rotateZ ? _self.rotateZ : rotateZ // ignore: cast_nullable_to_non_nullable
as double,translateX: null == translateX ? _self.translateX : translateX // ignore: cast_nullable_to_non_nullable
as double,translateY: null == translateY ? _self.translateY : translateY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$PortablePresentationScope {

 Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget; PortableOperationResults get operations; List<PortableAppearanceLayer> get appearanceLayers; Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases; AuthoredPresentationIndex? get authoredIndex; AuthoredPresentationIndex? get independentAuthoredIndex; List<PortableAuthoredPart> get authoredParts; PortableInspectorFrame? get inspectorFrame; Set<ActiveInspectorLayout> get activeInspectorLayouts; Set<ActivePartPresentation> get activeParts; bool get readOnly; bool get enabled; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; ValueChanged<String>? get reportStatus; CheckedEditorCatalog? get catalog; PortableExpressionQueries? get queries; ResourceDiagnosticReader get resourceDiagnostics; skir.ResourceId? get resource; String? get searchHistoryNamespace; ValueChanged<skir.ResourceId>? get openResource;/// The resource open in the workspace, which resources layouts mark as
/// routed.
 skir.ResourceId? get routedResource; skir.PresentationRole? get role; skir.PresentationMaterial? get material; Set<skir.PresentationId> get activePresentations; Set<ActiveFieldPresentation> get activeFieldPresentations; skir.BoundControl? get associatedControl; ResolvedFieldAssociation? get fieldAssociation; Map<String, skir.PresentationNode> get slots; Map<String, PortableSlotBuilder> get slotBuilders; PortablePresentationHost? get host;/// Host values for the host inputs each material in this scope declares.
 HostContext get hostContext; Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters;
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<PortablePresentationScope> get copyWith => _$PortablePresentationScopeCopyWithImpl<PortablePresentationScope>(this as PortablePresentationScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.operations, _this.operations) || other.operations == _this.operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _this.appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _this.authoredAliases)&&(identical(other.authoredIndex, _this.authoredIndex) || other.authoredIndex == _this.authoredIndex)&&(identical(other.independentAuthoredIndex, _this.independentAuthoredIndex) || other.independentAuthoredIndex == _this.independentAuthoredIndex)&&const DeepCollectionEquality().equals(other.authoredParts, _this.authoredParts)&&(identical(other.inspectorFrame, _this.inspectorFrame) || other.inspectorFrame == _this.inspectorFrame)&&const DeepCollectionEquality().equals(other.activeInspectorLayouts, _this.activeInspectorLayouts)&&const DeepCollectionEquality().equals(other.activeParts, _this.activeParts)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reportStatus, _this.reportStatus) || other.reportStatus == _this.reportStatus)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.queries, _this.queries) || other.queries == _this.queries)&&(identical(other.resourceDiagnostics, _this.resourceDiagnostics) || other.resourceDiagnostics == _this.resourceDiagnostics)&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.searchHistoryNamespace, _this.searchHistoryNamespace) || other.searchHistoryNamespace == _this.searchHistoryNamespace)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.routedResource, _this.routedResource) || other.routedResource == _this.routedResource)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.activeFieldPresentations, _this.activeFieldPresentations)&&(identical(other.associatedControl, _this.associatedControl) || other.associatedControl == _this.associatedControl)&&(identical(other.fieldAssociation, _this.fieldAssociation) || other.fieldAssociation == _this.fieldAssociation)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _this.slotBuilders)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.hostContext, _this.hostContext) || other.hostContext == _this.hostContext)&&const DeepCollectionEquality().equals(other.projectedWriters, _this.projectedWriters));
}


@override
int get hashCode {
  final _this = this as PortablePresentationScope;
  return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.operations,const DeepCollectionEquality().hash(_this.appearanceLayers),const DeepCollectionEquality().hash(_this.authoredAliases),_this.authoredIndex,_this.independentAuthoredIndex,const DeepCollectionEquality().hash(_this.authoredParts),_this.inspectorFrame,const DeepCollectionEquality().hash(_this.activeInspectorLayouts),const DeepCollectionEquality().hash(_this.activeParts),_this.readOnly,_this.enabled,_this.watchSearch,_this.reportStatus,_this.catalog,_this.queries,_this.resourceDiagnostics,_this.resource,_this.searchHistoryNamespace,_this.openResource,_this.routedResource,_this.role,_this.material,const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.activeFieldPresentations),_this.associatedControl,_this.fieldAssociation,const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.slotBuilders),_this.host,_this.hostContext,const DeepCollectionEquality().hash(_this.projectedWriters)]);
}

@override
String toString() {
  final _this = this as PortablePresentationScope;
  return 'PortablePresentationScope(bindings: ${_this.bindings}, budget: ${_this.budget}, operations: ${_this.operations}, appearanceLayers: ${_this.appearanceLayers}, authoredAliases: ${_this.authoredAliases}, authoredIndex: ${_this.authoredIndex}, independentAuthoredIndex: ${_this.independentAuthoredIndex}, authoredParts: ${_this.authoredParts}, inspectorFrame: ${_this.inspectorFrame}, activeInspectorLayouts: ${_this.activeInspectorLayouts}, activeParts: ${_this.activeParts}, readOnly: ${_this.readOnly}, enabled: ${_this.enabled}, watchSearch: ${_this.watchSearch}, reportStatus: ${_this.reportStatus}, catalog: ${_this.catalog}, queries: ${_this.queries}, resourceDiagnostics: ${_this.resourceDiagnostics}, resource: ${_this.resource}, searchHistoryNamespace: ${_this.searchHistoryNamespace}, openResource: ${_this.openResource}, routedResource: ${_this.routedResource}, role: ${_this.role}, material: ${_this.material}, activePresentations: ${_this.activePresentations}, activeFieldPresentations: ${_this.activeFieldPresentations}, associatedControl: ${_this.associatedControl}, fieldAssociation: ${_this.fieldAssociation}, slots: ${_this.slots}, slotBuilders: ${_this.slotBuilders}, host: ${_this.host}, hostContext: ${_this.hostContext}, projectedWriters: ${_this.projectedWriters})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationScopeCopyWith<$Res>  {
  factory $PortablePresentationScopeCopyWith(PortablePresentationScope value, $Res Function(PortablePresentationScope) _then) = _$PortablePresentationScopeCopyWithImpl;
@useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, AuthoredPresentationIndex? independentAuthoredIndex, List<PortableAuthoredPart> authoredParts, PortableInspectorFrame? inspectorFrame, Set<ActiveInspectorLayout> activeInspectorLayouts, Set<ActivePartPresentation> activeParts, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, PortableExpressionQueries? queries, ResourceDiagnosticReader resourceDiagnostics, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.ResourceId? routedResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Set<ActiveFieldPresentation> activeFieldPresentations, skir.BoundControl? associatedControl, ResolvedFieldAssociation? fieldAssociation, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, HostContext hostContext, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex;$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame;$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation;$HostContextCopyWith<$Res> get hostContext;

}
/// @nodoc
class _$PortablePresentationScopeCopyWithImpl<$Res>
    implements $PortablePresentationScopeCopyWith<$Res> {
  _$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final PortablePresentationScope _self;
  final $Res Function(PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? independentAuthoredIndex = freezed,Object? authoredParts = null,Object? inspectorFrame = freezed,Object? activeInspectorLayouts = null,Object? activeParts = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? queries = freezed,Object? resourceDiagnostics = null,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? routedResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? activeFieldPresentations = null,Object? associatedControl = freezed,Object? fieldAssociation = freezed,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? hostContext = null,Object? projectedWriters = null,}) {
  return _then(PortablePresentationScope(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self.appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self.authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,independentAuthoredIndex: freezed == independentAuthoredIndex ? _self.independentAuthoredIndex : independentAuthoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,authoredParts: null == authoredParts ? _self.authoredParts : authoredParts // ignore: cast_nullable_to_non_nullable
as List<PortableAuthoredPart>,inspectorFrame: freezed == inspectorFrame ? _self.inspectorFrame : inspectorFrame // ignore: cast_nullable_to_non_nullable
as PortableInspectorFrame?,activeInspectorLayouts: null == activeInspectorLayouts ? _self.activeInspectorLayouts : activeInspectorLayouts // ignore: cast_nullable_to_non_nullable
as Set<ActiveInspectorLayout>,activeParts: null == activeParts ? _self.activeParts : activeParts // ignore: cast_nullable_to_non_nullable
as Set<ActivePartPresentation>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,queries: freezed == queries ? _self.queries : queries // ignore: cast_nullable_to_non_nullable
as PortableExpressionQueries?,resourceDiagnostics: null == resourceDiagnostics ? _self.resourceDiagnostics : resourceDiagnostics // ignore: cast_nullable_to_non_nullable
as ResourceDiagnosticReader,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,routedResource: freezed == routedResource ? _self.routedResource : routedResource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self.activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,activeFieldPresentations: null == activeFieldPresentations ? _self.activeFieldPresentations : activeFieldPresentations // ignore: cast_nullable_to_non_nullable
as Set<ActiveFieldPresentation>,associatedControl: freezed == associatedControl ? _self.associatedControl : associatedControl // ignore: cast_nullable_to_non_nullable
as skir.BoundControl?,fieldAssociation: freezed == fieldAssociation ? _self.fieldAssociation : fieldAssociation // ignore: cast_nullable_to_non_nullable
as ResolvedFieldAssociation?,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self.slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,hostContext: null == hostContext ? _self.hostContext : hostContext // ignore: cast_nullable_to_non_nullable
as HostContext,projectedWriters: null == projectedWriters ? _self.projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex {
    if (_self.independentAuthoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.independentAuthoredIndex!, (value) {
    return _then(_self.copyWith(independentAuthoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame {
    if (_self.inspectorFrame == null) {
    return null;
  }

  return $PortableInspectorFrameCopyWith<$Res>(_self.inspectorFrame!, (value) {
    return _then(_self.copyWith(inspectorFrame: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation {
    if (_self.fieldAssociation == null) {
    return null;
  }

  return $ResolvedFieldAssociationCopyWith<$Res>(_self.fieldAssociation!, (value) {
    return _then(_self.copyWith(fieldAssociation: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HostContextCopyWith<$Res> get hostContext {
  
  return $HostContextCopyWith<$Res>(_self.hostContext, (value) {
    return _then(_self.copyWith(hostContext: value));
  });
}
}



/// @nodoc


class _PortablePresentationScope extends PortablePresentationScope {
  const _PortablePresentationScope({required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget, required this.operations, required  List<PortableAppearanceLayer> appearanceLayers, required  Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, required this.authoredIndex, required this.independentAuthoredIndex, required  List<PortableAuthoredPart> authoredParts, required this.inspectorFrame, required  Set<ActiveInspectorLayout> activeInspectorLayouts, required  Set<ActivePartPresentation> activeParts, required this.readOnly, required this.enabled, required this.watchSearch, required this.reportStatus, required this.catalog, required this.queries, required this.resourceDiagnostics, required this.resource, required this.searchHistoryNamespace, required this.openResource, required this.routedResource, required this.role, required this.material, required  Set<skir.PresentationId> activePresentations, required  Set<ActiveFieldPresentation> activeFieldPresentations, required this.associatedControl, required this.fieldAssociation, required  Map<String, skir.PresentationNode> slots, required  Map<String, PortableSlotBuilder> slotBuilders, required this.host, required this.hostContext, required  Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters}): _bindings = bindings,_appearanceLayers = appearanceLayers,_authoredAliases = authoredAliases,_authoredParts = authoredParts,_activeInspectorLayouts = activeInspectorLayouts,_activeParts = activeParts,_activePresentations = activePresentations,_activeFieldPresentations = activeFieldPresentations,_slots = slots,_slotBuilders = slotBuilders,_projectedWriters = projectedWriters,super._();
  

 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  PortableOperationResults operations;
 final  List<PortableAppearanceLayer> _appearanceLayers;
@override List<PortableAppearanceLayer> get appearanceLayers {
  if (_appearanceLayers is EqualUnmodifiableListView) return _appearanceLayers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appearanceLayers);
}

 final  Map<skir.ExpressionBindingId, AuthoredBindingAddress> _authoredAliases;
@override Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases {
  if (_authoredAliases is EqualUnmodifiableMapView) return _authoredAliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_authoredAliases);
}

@override final  AuthoredPresentationIndex? authoredIndex;
@override final  AuthoredPresentationIndex? independentAuthoredIndex;
 final  List<PortableAuthoredPart> _authoredParts;
@override List<PortableAuthoredPart> get authoredParts {
  if (_authoredParts is EqualUnmodifiableListView) return _authoredParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authoredParts);
}

@override final  PortableInspectorFrame? inspectorFrame;
 final  Set<ActiveInspectorLayout> _activeInspectorLayouts;
@override Set<ActiveInspectorLayout> get activeInspectorLayouts {
  if (_activeInspectorLayouts is EqualUnmodifiableSetView) return _activeInspectorLayouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeInspectorLayouts);
}

 final  Set<ActivePartPresentation> _activeParts;
@override Set<ActivePartPresentation> get activeParts {
  if (_activeParts is EqualUnmodifiableSetView) return _activeParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeParts);
}

@override final  bool readOnly;
@override final  bool enabled;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  ValueChanged<String>? reportStatus;
@override final  CheckedEditorCatalog? catalog;
@override final  PortableExpressionQueries? queries;
@override final  ResourceDiagnosticReader resourceDiagnostics;
@override final  skir.ResourceId? resource;
@override final  String? searchHistoryNamespace;
@override final  ValueChanged<skir.ResourceId>? openResource;
/// The resource open in the workspace, which resources layouts mark as
/// routed.
@override final  skir.ResourceId? routedResource;
@override final  skir.PresentationRole? role;
@override final  skir.PresentationMaterial? material;
 final  Set<skir.PresentationId> _activePresentations;
@override Set<skir.PresentationId> get activePresentations {
  if (_activePresentations is EqualUnmodifiableSetView) return _activePresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activePresentations);
}

 final  Set<ActiveFieldPresentation> _activeFieldPresentations;
@override Set<ActiveFieldPresentation> get activeFieldPresentations {
  if (_activeFieldPresentations is EqualUnmodifiableSetView) return _activeFieldPresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeFieldPresentations);
}

@override final  skir.BoundControl? associatedControl;
@override final  ResolvedFieldAssociation? fieldAssociation;
 final  Map<String, skir.PresentationNode> _slots;
@override Map<String, skir.PresentationNode> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}

 final  Map<String, PortableSlotBuilder> _slotBuilders;
@override Map<String, PortableSlotBuilder> get slotBuilders {
  if (_slotBuilders is EqualUnmodifiableMapView) return _slotBuilders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slotBuilders);
}

@override final  PortablePresentationHost? host;
/// Host values for the host inputs each material in this scope declares.
@override final  HostContext hostContext;
 final  Map<skir.ExpressionBindingId, PortableBindingSetter> _projectedWriters;
@override Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters {
  if (_projectedWriters is EqualUnmodifiableMapView) return _projectedWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_projectedWriters);
}


/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationScopeCopyWith<_PortablePresentationScope> get copyWith => __$PortablePresentationScopeCopyWithImpl<_PortablePresentationScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.operations, operations) || other.operations == operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _authoredAliases)&&(identical(other.authoredIndex, authoredIndex) || other.authoredIndex == authoredIndex)&&(identical(other.independentAuthoredIndex, independentAuthoredIndex) || other.independentAuthoredIndex == independentAuthoredIndex)&&const DeepCollectionEquality().equals(other.authoredParts, _authoredParts)&&(identical(other.inspectorFrame, inspectorFrame) || other.inspectorFrame == inspectorFrame)&&const DeepCollectionEquality().equals(other.activeInspectorLayouts, _activeInspectorLayouts)&&const DeepCollectionEquality().equals(other.activeParts, _activeParts)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reportStatus, reportStatus) || other.reportStatus == reportStatus)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.queries, queries) || other.queries == queries)&&(identical(other.resourceDiagnostics, resourceDiagnostics) || other.resourceDiagnostics == resourceDiagnostics)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.searchHistoryNamespace, searchHistoryNamespace) || other.searchHistoryNamespace == searchHistoryNamespace)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.routedResource, routedResource) || other.routedResource == routedResource)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.activeFieldPresentations, _activeFieldPresentations)&&(identical(other.associatedControl, associatedControl) || other.associatedControl == associatedControl)&&(identical(other.fieldAssociation, fieldAssociation) || other.fieldAssociation == fieldAssociation)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _slotBuilders)&&(identical(other.host, host) || other.host == host)&&(identical(other.hostContext, hostContext) || other.hostContext == hostContext)&&const DeepCollectionEquality().equals(other.projectedWriters, _projectedWriters));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_bindings),budget,operations,const DeepCollectionEquality().hash(_appearanceLayers),const DeepCollectionEquality().hash(_authoredAliases),authoredIndex,independentAuthoredIndex,const DeepCollectionEquality().hash(_authoredParts),inspectorFrame,const DeepCollectionEquality().hash(_activeInspectorLayouts),const DeepCollectionEquality().hash(_activeParts),readOnly,enabled,watchSearch,reportStatus,catalog,queries,resourceDiagnostics,resource,searchHistoryNamespace,openResource,routedResource,role,material,const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_activeFieldPresentations),associatedControl,fieldAssociation,const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_slotBuilders),host,hostContext,const DeepCollectionEquality().hash(_projectedWriters)]);
}

@override
String toString() {
    return 'PortablePresentationScope._value(bindings: $bindings, budget: $budget, operations: $operations, appearanceLayers: $appearanceLayers, authoredAliases: $authoredAliases, authoredIndex: $authoredIndex, independentAuthoredIndex: $independentAuthoredIndex, authoredParts: $authoredParts, inspectorFrame: $inspectorFrame, activeInspectorLayouts: $activeInspectorLayouts, activeParts: $activeParts, readOnly: $readOnly, enabled: $enabled, watchSearch: $watchSearch, reportStatus: $reportStatus, catalog: $catalog, queries: $queries, resourceDiagnostics: $resourceDiagnostics, resource: $resource, searchHistoryNamespace: $searchHistoryNamespace, openResource: $openResource, routedResource: $routedResource, role: $role, material: $material, activePresentations: $activePresentations, activeFieldPresentations: $activeFieldPresentations, associatedControl: $associatedControl, fieldAssociation: $fieldAssociation, slots: $slots, slotBuilders: $slotBuilders, host: $host, hostContext: $hostContext, projectedWriters: $projectedWriters)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationScopeCopyWith<$Res> implements $PortablePresentationScopeCopyWith<$Res> {
  factory _$PortablePresentationScopeCopyWith(_PortablePresentationScope value, $Res Function(_PortablePresentationScope) _then) = __$PortablePresentationScopeCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, AuthoredPresentationIndex? independentAuthoredIndex, List<PortableAuthoredPart> authoredParts, PortableInspectorFrame? inspectorFrame, Set<ActiveInspectorLayout> activeInspectorLayouts, Set<ActivePartPresentation> activeParts, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, PortableExpressionQueries? queries, ResourceDiagnosticReader resourceDiagnostics, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.ResourceId? routedResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Set<ActiveFieldPresentation> activeFieldPresentations, skir.BoundControl? associatedControl, ResolvedFieldAssociation? fieldAssociation, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, HostContext hostContext, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


@override $AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;@override $AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex;@override $PortableInspectorFrameCopyWith<$Res>? get inspectorFrame;@override $ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation;@override $HostContextCopyWith<$Res> get hostContext;

}
/// @nodoc
class __$PortablePresentationScopeCopyWithImpl<$Res>
    implements _$PortablePresentationScopeCopyWith<$Res> {
  __$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final _PortablePresentationScope _self;
  final $Res Function(_PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? independentAuthoredIndex = freezed,Object? authoredParts = null,Object? inspectorFrame = freezed,Object? activeInspectorLayouts = null,Object? activeParts = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? queries = freezed,Object? resourceDiagnostics = null,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? routedResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? activeFieldPresentations = null,Object? associatedControl = freezed,Object? fieldAssociation = freezed,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? hostContext = null,Object? projectedWriters = null,}) {
  return _then(_PortablePresentationScope(
bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self._appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self._authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,independentAuthoredIndex: freezed == independentAuthoredIndex ? _self.independentAuthoredIndex : independentAuthoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,authoredParts: null == authoredParts ? _self._authoredParts : authoredParts // ignore: cast_nullable_to_non_nullable
as List<PortableAuthoredPart>,inspectorFrame: freezed == inspectorFrame ? _self.inspectorFrame : inspectorFrame // ignore: cast_nullable_to_non_nullable
as PortableInspectorFrame?,activeInspectorLayouts: null == activeInspectorLayouts ? _self._activeInspectorLayouts : activeInspectorLayouts // ignore: cast_nullable_to_non_nullable
as Set<ActiveInspectorLayout>,activeParts: null == activeParts ? _self._activeParts : activeParts // ignore: cast_nullable_to_non_nullable
as Set<ActivePartPresentation>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,queries: freezed == queries ? _self.queries : queries // ignore: cast_nullable_to_non_nullable
as PortableExpressionQueries?,resourceDiagnostics: null == resourceDiagnostics ? _self.resourceDiagnostics : resourceDiagnostics // ignore: cast_nullable_to_non_nullable
as ResourceDiagnosticReader,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,routedResource: freezed == routedResource ? _self.routedResource : routedResource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self._activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,activeFieldPresentations: null == activeFieldPresentations ? _self._activeFieldPresentations : activeFieldPresentations // ignore: cast_nullable_to_non_nullable
as Set<ActiveFieldPresentation>,associatedControl: freezed == associatedControl ? _self.associatedControl : associatedControl // ignore: cast_nullable_to_non_nullable
as skir.BoundControl?,fieldAssociation: freezed == fieldAssociation ? _self.fieldAssociation : fieldAssociation // ignore: cast_nullable_to_non_nullable
as ResolvedFieldAssociation?,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self._slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,hostContext: null == hostContext ? _self.hostContext : hostContext // ignore: cast_nullable_to_non_nullable
as HostContext,projectedWriters: null == projectedWriters ? _self._projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex {
    if (_self.independentAuthoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.independentAuthoredIndex!, (value) {
    return _then(_self.copyWith(independentAuthoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame {
    if (_self.inspectorFrame == null) {
    return null;
  }

  return $PortableInspectorFrameCopyWith<$Res>(_self.inspectorFrame!, (value) {
    return _then(_self.copyWith(inspectorFrame: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation {
    if (_self.fieldAssociation == null) {
    return null;
  }

  return $ResolvedFieldAssociationCopyWith<$Res>(_self.fieldAssociation!, (value) {
    return _then(_self.copyWith(fieldAssociation: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HostContextCopyWith<$Res> get hostContext {
  
  return $HostContextCopyWith<$Res>(_self.hostContext, (value) {
    return _then(_self.copyWith(hostContext: value));
  });
}
}

// dart format on
