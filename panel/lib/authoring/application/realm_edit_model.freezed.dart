// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_edit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OperationWorkspaceCapture {

 AuthoringDocument get document; skir.OperationWorkingContext get context; int get revision;
/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationWorkspaceCaptureCopyWith<OperationWorkspaceCapture> get copyWith => _$OperationWorkspaceCaptureCopyWithImpl<OperationWorkspaceCapture>(this as OperationWorkspaceCapture, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OperationWorkspaceCapture;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationWorkspaceCapture&&(identical(other.document, _this.document) || other.document == _this.document)&&(identical(other.context, _this.context) || other.context == _this.context)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as OperationWorkspaceCapture;
  return Object.hash(runtimeType,_this.document,_this.context,_this.revision);
}

@override
String toString() {
  final _this = this as OperationWorkspaceCapture;
  return 'OperationWorkspaceCapture(document: ${_this.document}, context: ${_this.context}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $OperationWorkspaceCaptureCopyWith<$Res>  {
  factory $OperationWorkspaceCaptureCopyWith(OperationWorkspaceCapture value, $Res Function(OperationWorkspaceCapture) _then) = _$OperationWorkspaceCaptureCopyWithImpl;
@useResult
$Res call({
 AuthoringDocument document, skir.OperationWorkingContext context, int revision
});


$AuthoringDocumentCopyWith<$Res> get document;

}
/// @nodoc
class _$OperationWorkspaceCaptureCopyWithImpl<$Res>
    implements $OperationWorkspaceCaptureCopyWith<$Res> {
  _$OperationWorkspaceCaptureCopyWithImpl(this._self, this._then);

  final OperationWorkspaceCapture _self;
  final $Res Function(OperationWorkspaceCapture) _then;

/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,Object? context = null,Object? revision = null,}) {
  return _then(OperationWorkspaceCapture(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as skir.OperationWorkingContext,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get document {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [OperationWorkspaceCapture].
extension OperationWorkspaceCapturePatterns on OperationWorkspaceCapture {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationWorkspaceCapture value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationWorkspaceCapture() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationWorkspaceCapture value)  $default,){
final _that = this;
switch (_that) {
case _OperationWorkspaceCapture():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationWorkspaceCapture value)?  $default,){
final _that = this;
switch (_that) {
case _OperationWorkspaceCapture() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringDocument document,  skir.OperationWorkingContext context,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationWorkspaceCapture() when $default != null:
return $default(_that.document,_that.context,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringDocument document,  skir.OperationWorkingContext context,  int revision)  $default,) {final _that = this;
switch (_that) {
case _OperationWorkspaceCapture():
return $default(_that.document,_that.context,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringDocument document,  skir.OperationWorkingContext context,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _OperationWorkspaceCapture() when $default != null:
return $default(_that.document,_that.context,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _OperationWorkspaceCapture implements OperationWorkspaceCapture {
  const _OperationWorkspaceCapture({required this.document, required this.context, required this.revision});
  

@override final  AuthoringDocument document;
@override final  skir.OperationWorkingContext context;
@override final  int revision;

/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationWorkspaceCaptureCopyWith<_OperationWorkspaceCapture> get copyWith => __$OperationWorkspaceCaptureCopyWithImpl<_OperationWorkspaceCapture>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationWorkspaceCapture&&(identical(other.document, document) || other.document == document)&&(identical(other.context, context) || other.context == context)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,document,context,revision);
}

@override
String toString() {
    return 'OperationWorkspaceCapture(document: $document, context: $context, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$OperationWorkspaceCaptureCopyWith<$Res> implements $OperationWorkspaceCaptureCopyWith<$Res> {
  factory _$OperationWorkspaceCaptureCopyWith(_OperationWorkspaceCapture value, $Res Function(_OperationWorkspaceCapture) _then) = __$OperationWorkspaceCaptureCopyWithImpl;
@override @useResult
$Res call({
 AuthoringDocument document, skir.OperationWorkingContext context, int revision
});


@override $AuthoringDocumentCopyWith<$Res> get document;

}
/// @nodoc
class __$OperationWorkspaceCaptureCopyWithImpl<$Res>
    implements _$OperationWorkspaceCaptureCopyWith<$Res> {
  __$OperationWorkspaceCaptureCopyWithImpl(this._self, this._then);

  final _OperationWorkspaceCapture _self;
  final $Res Function(_OperationWorkspaceCapture) _then;

/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,Object? context = null,Object? revision = null,}) {
  return _then(_OperationWorkspaceCapture(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as skir.OperationWorkingContext,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of OperationWorkspaceCapture
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get document {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

/// @nodoc
mixin _$RealmPreparedEdit {

 skir.PreparedEdit get request; List<LocatedInitializationFinding> get findings;
/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPreparedEditCopyWith<RealmPreparedEdit> get copyWith => _$RealmPreparedEditCopyWithImpl<RealmPreparedEdit>(this as RealmPreparedEdit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPreparedEdit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPreparedEdit&&(identical(other.request, _this.request) || other.request == _this.request)&&const DeepCollectionEquality().equals(other.findings, _this.findings));
}


@override
int get hashCode {
  final _this = this as RealmPreparedEdit;
  return Object.hash(runtimeType,_this.request,const DeepCollectionEquality().hash(_this.findings));
}

@override
String toString() {
  final _this = this as RealmPreparedEdit;
  return 'RealmPreparedEdit(request: ${_this.request}, findings: ${_this.findings})';
}


}

/// @nodoc
abstract mixin class $RealmPreparedEditCopyWith<$Res>  {
  factory $RealmPreparedEditCopyWith(RealmPreparedEdit value, $Res Function(RealmPreparedEdit) _then) = _$RealmPreparedEditCopyWithImpl;
@useResult
$Res call({
 skir.PreparedEdit request, List<LocatedInitializationFinding> findings
});




}
/// @nodoc
class _$RealmPreparedEditCopyWithImpl<$Res>
    implements $RealmPreparedEditCopyWith<$Res> {
  _$RealmPreparedEditCopyWithImpl(this._self, this._then);

  final RealmPreparedEdit _self;
  final $Res Function(RealmPreparedEdit) _then;

/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? findings = null,}) {
  return _then(RealmPreparedEdit(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.PreparedEdit,findings: null == findings ? _self.findings : findings // ignore: cast_nullable_to_non_nullable
as List<LocatedInitializationFinding>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmPreparedEdit].
extension RealmPreparedEditPatterns on RealmPreparedEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPreparedEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPreparedEdit value)  $default,){
final _that = this;
switch (_that) {
case _RealmPreparedEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPreparedEdit value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PreparedEdit request,  List<LocatedInitializationFinding> findings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
return $default(_that.request,_that.findings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PreparedEdit request,  List<LocatedInitializationFinding> findings)  $default,) {final _that = this;
switch (_that) {
case _RealmPreparedEdit():
return $default(_that.request,_that.findings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PreparedEdit request,  List<LocatedInitializationFinding> findings)?  $default,) {final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
return $default(_that.request,_that.findings);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPreparedEdit implements RealmPreparedEdit {
  const _RealmPreparedEdit({required this.request,  List<LocatedInitializationFinding> findings = const []}): _findings = findings;
  

@override final  skir.PreparedEdit request;
 final  List<LocatedInitializationFinding> _findings;
@override@JsonKey() List<LocatedInitializationFinding> get findings {
  if (_findings is EqualUnmodifiableListView) return _findings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_findings);
}


/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPreparedEditCopyWith<_RealmPreparedEdit> get copyWith => __$RealmPreparedEditCopyWithImpl<_RealmPreparedEdit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPreparedEdit&&(identical(other.request, request) || other.request == request)&&const DeepCollectionEquality().equals(other.findings, _findings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,request,const DeepCollectionEquality().hash(_findings));
}

@override
String toString() {
    return 'RealmPreparedEdit(request: $request, findings: $findings)';
}


}

/// @nodoc
abstract mixin class _$RealmPreparedEditCopyWith<$Res> implements $RealmPreparedEditCopyWith<$Res> {
  factory _$RealmPreparedEditCopyWith(_RealmPreparedEdit value, $Res Function(_RealmPreparedEdit) _then) = __$RealmPreparedEditCopyWithImpl;
@override @useResult
$Res call({
 skir.PreparedEdit request, List<LocatedInitializationFinding> findings
});




}
/// @nodoc
class __$RealmPreparedEditCopyWithImpl<$Res>
    implements _$RealmPreparedEditCopyWith<$Res> {
  __$RealmPreparedEditCopyWithImpl(this._self, this._then);

  final _RealmPreparedEdit _self;
  final $Res Function(_RealmPreparedEdit) _then;

/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? findings = null,}) {
  return _then(_RealmPreparedEdit(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.PreparedEdit,findings: null == findings ? _self._findings : findings // ignore: cast_nullable_to_non_nullable
as List<LocatedInitializationFinding>,
  ));
}


}

/// @nodoc
mixin _$AuthoringCompositionFailure {

 List<skir.ExpectationConflict> get conflicts;
/// Create a copy of AuthoringCompositionFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringCompositionFailureCopyWith<AuthoringCompositionFailure> get copyWith => _$AuthoringCompositionFailureCopyWithImpl<AuthoringCompositionFailure>(this as AuthoringCompositionFailure, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringCompositionFailure;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringCompositionFailure&&const DeepCollectionEquality().equals(other.conflicts, _this.conflicts));
}


@override
int get hashCode {
  final _this = this as AuthoringCompositionFailure;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.conflicts));
}

@override
String toString() {
  final _this = this as AuthoringCompositionFailure;
  return 'AuthoringCompositionFailure(conflicts: ${_this.conflicts})';
}


}

/// @nodoc
abstract mixin class $AuthoringCompositionFailureCopyWith<$Res>  {
  factory $AuthoringCompositionFailureCopyWith(AuthoringCompositionFailure value, $Res Function(AuthoringCompositionFailure) _then) = _$AuthoringCompositionFailureCopyWithImpl;
@useResult
$Res call({
 List<skir.ExpectationConflict> conflicts
});




}
/// @nodoc
class _$AuthoringCompositionFailureCopyWithImpl<$Res>
    implements $AuthoringCompositionFailureCopyWith<$Res> {
  _$AuthoringCompositionFailureCopyWithImpl(this._self, this._then);

  final AuthoringCompositionFailure _self;
  final $Res Function(AuthoringCompositionFailure) _then;

/// Create a copy of AuthoringCompositionFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conflicts = null,}) {
  return _then(AuthoringCompositionFailure(
null == conflicts ? _self.conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<skir.ExpectationConflict>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringCompositionFailure].
extension AuthoringCompositionFailurePatterns on AuthoringCompositionFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringCompositionFailure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringCompositionFailure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringCompositionFailure value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringCompositionFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringCompositionFailure value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringCompositionFailure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.ExpectationConflict> conflicts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringCompositionFailure() when $default != null:
return $default(_that.conflicts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.ExpectationConflict> conflicts)  $default,) {final _that = this;
switch (_that) {
case _AuthoringCompositionFailure():
return $default(_that.conflicts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.ExpectationConflict> conflicts)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringCompositionFailure() when $default != null:
return $default(_that.conflicts);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringCompositionFailure implements AuthoringCompositionFailure {
  const _AuthoringCompositionFailure( List<skir.ExpectationConflict> conflicts): _conflicts = conflicts;
  

 final  List<skir.ExpectationConflict> _conflicts;
@override List<skir.ExpectationConflict> get conflicts {
  if (_conflicts is EqualUnmodifiableListView) return _conflicts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conflicts);
}


/// Create a copy of AuthoringCompositionFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringCompositionFailureCopyWith<_AuthoringCompositionFailure> get copyWith => __$AuthoringCompositionFailureCopyWithImpl<_AuthoringCompositionFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringCompositionFailure&&const DeepCollectionEquality().equals(other.conflicts, _conflicts));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_conflicts));
}

@override
String toString() {
    return 'AuthoringCompositionFailure(conflicts: $conflicts)';
}


}

/// @nodoc
abstract mixin class _$AuthoringCompositionFailureCopyWith<$Res> implements $AuthoringCompositionFailureCopyWith<$Res> {
  factory _$AuthoringCompositionFailureCopyWith(_AuthoringCompositionFailure value, $Res Function(_AuthoringCompositionFailure) _then) = __$AuthoringCompositionFailureCopyWithImpl;
@override @useResult
$Res call({
 List<skir.ExpectationConflict> conflicts
});




}
/// @nodoc
class __$AuthoringCompositionFailureCopyWithImpl<$Res>
    implements _$AuthoringCompositionFailureCopyWith<$Res> {
  __$AuthoringCompositionFailureCopyWithImpl(this._self, this._then);

  final _AuthoringCompositionFailure _self;
  final $Res Function(_AuthoringCompositionFailure) _then;

/// Create a copy of AuthoringCompositionFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conflicts = null,}) {
  return _then(_AuthoringCompositionFailure(
null == conflicts ? _self._conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<skir.ExpectationConflict>,
  ));
}


}

/// @nodoc
mixin _$AuthoringConflictEvidence {

 List<skir.ExpectationConflict> get facts; List<EditorDiagnostic> get diagnostics;
/// Create a copy of AuthoringConflictEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringConflictEvidenceCopyWith<AuthoringConflictEvidence> get copyWith => _$AuthoringConflictEvidenceCopyWithImpl<AuthoringConflictEvidence>(this as AuthoringConflictEvidence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringConflictEvidence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringConflictEvidence&&const DeepCollectionEquality().equals(other.facts, _this.facts)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as AuthoringConflictEvidence;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.facts),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as AuthoringConflictEvidence;
  return 'AuthoringConflictEvidence(facts: ${_this.facts}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $AuthoringConflictEvidenceCopyWith<$Res>  {
  factory $AuthoringConflictEvidenceCopyWith(AuthoringConflictEvidence value, $Res Function(AuthoringConflictEvidence) _then) = _$AuthoringConflictEvidenceCopyWithImpl;
@useResult
$Res call({
 List<skir.ExpectationConflict> facts, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class _$AuthoringConflictEvidenceCopyWithImpl<$Res>
    implements $AuthoringConflictEvidenceCopyWith<$Res> {
  _$AuthoringConflictEvidenceCopyWithImpl(this._self, this._then);

  final AuthoringConflictEvidence _self;
  final $Res Function(AuthoringConflictEvidence) _then;

/// Create a copy of AuthoringConflictEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? facts = null,Object? diagnostics = null,}) {
  return _then(AuthoringConflictEvidence(
facts: null == facts ? _self.facts : facts // ignore: cast_nullable_to_non_nullable
as List<skir.ExpectationConflict>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringConflictEvidence].
extension AuthoringConflictEvidencePatterns on AuthoringConflictEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringConflictEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringConflictEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringConflictEvidence value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringConflictEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringConflictEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringConflictEvidence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.ExpectationConflict> facts,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringConflictEvidence() when $default != null:
return $default(_that.facts,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.ExpectationConflict> facts,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _AuthoringConflictEvidence():
return $default(_that.facts,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.ExpectationConflict> facts,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringConflictEvidence() when $default != null:
return $default(_that.facts,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringConflictEvidence implements AuthoringConflictEvidence {
  const _AuthoringConflictEvidence({required  List<skir.ExpectationConflict> facts,  List<EditorDiagnostic> diagnostics = const []}): _facts = facts,_diagnostics = diagnostics;
  

 final  List<skir.ExpectationConflict> _facts;
@override List<skir.ExpectationConflict> get facts {
  if (_facts is EqualUnmodifiableListView) return _facts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facts);
}

 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of AuthoringConflictEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringConflictEvidenceCopyWith<_AuthoringConflictEvidence> get copyWith => __$AuthoringConflictEvidenceCopyWithImpl<_AuthoringConflictEvidence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringConflictEvidence&&const DeepCollectionEquality().equals(other.facts, _facts)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_facts),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'AuthoringConflictEvidence(facts: $facts, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$AuthoringConflictEvidenceCopyWith<$Res> implements $AuthoringConflictEvidenceCopyWith<$Res> {
  factory _$AuthoringConflictEvidenceCopyWith(_AuthoringConflictEvidence value, $Res Function(_AuthoringConflictEvidence) _then) = __$AuthoringConflictEvidenceCopyWithImpl;
@override @useResult
$Res call({
 List<skir.ExpectationConflict> facts, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class __$AuthoringConflictEvidenceCopyWithImpl<$Res>
    implements _$AuthoringConflictEvidenceCopyWith<$Res> {
  __$AuthoringConflictEvidenceCopyWithImpl(this._self, this._then);

  final _AuthoringConflictEvidence _self;
  final $Res Function(_AuthoringConflictEvidence) _then;

/// Create a copy of AuthoringConflictEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? facts = null,Object? diagnostics = null,}) {
  return _then(_AuthoringConflictEvidence(
facts: null == facts ? _self._facts : facts // ignore: cast_nullable_to_non_nullable
as List<skir.ExpectationConflict>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$AuthoringDocument {

 CheckedEditorCatalog get catalog; Map<skir.ResourceId, skir.AuthoringResource> get entries; List<skir.LinkProjection> get links; int get revision; skir.AuthoringObservationId? get confirmedObservation; List<LocatedInitializationFinding> get initializationFindings;
/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<AuthoringDocument> get copyWith => _$AuthoringDocumentCopyWithImpl<AuthoringDocument>(this as AuthoringDocument, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringDocument&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.links, _this.links)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.confirmedObservation, _this.confirmedObservation) || other.confirmedObservation == _this.confirmedObservation)&&const DeepCollectionEquality().equals(other.initializationFindings, _this.initializationFindings));
}


@override
int get hashCode {
  final _this = this as AuthoringDocument;
  return Object.hash(runtimeType,_this.catalog,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.links),_this.revision,_this.confirmedObservation,const DeepCollectionEquality().hash(_this.initializationFindings));
}

@override
String toString() {
  final _this = this as AuthoringDocument;
  return 'AuthoringDocument(catalog: ${_this.catalog}, entries: ${_this.entries}, links: ${_this.links}, revision: ${_this.revision}, confirmedObservation: ${_this.confirmedObservation}, initializationFindings: ${_this.initializationFindings})';
}


}

/// @nodoc
abstract mixin class $AuthoringDocumentCopyWith<$Res>  {
  factory $AuthoringDocumentCopyWith(AuthoringDocument value, $Res Function(AuthoringDocument) _then) = _$AuthoringDocumentCopyWithImpl;
@useResult
$Res call({
 CheckedEditorCatalog catalog, Map<skir.ResourceId, skir.AuthoringResource> entries, List<skir.LinkProjection> links, int revision, skir.AuthoringObservationId? confirmedObservation, List<LocatedInitializationFinding> initializationFindings
});




}
/// @nodoc
class _$AuthoringDocumentCopyWithImpl<$Res>
    implements $AuthoringDocumentCopyWith<$Res> {
  _$AuthoringDocumentCopyWithImpl(this._self, this._then);

  final AuthoringDocument _self;
  final $Res Function(AuthoringDocument) _then;

/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? entries = null,Object? links = null,Object? revision = null,Object? confirmedObservation = freezed,Object? initializationFindings = null,}) {
  return _then(AuthoringDocument(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,confirmedObservation: freezed == confirmedObservation ? _self.confirmedObservation : confirmedObservation // ignore: cast_nullable_to_non_nullable
as skir.AuthoringObservationId?,initializationFindings: null == initializationFindings ? _self.initializationFindings : initializationFindings // ignore: cast_nullable_to_non_nullable
as List<LocatedInitializationFinding>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringDocument].
extension AuthoringDocumentPatterns on AuthoringDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringDocument value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringDocument value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  skir.AuthoringObservationId? confirmedObservation,  List<LocatedInitializationFinding> initializationFindings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.confirmedObservation,_that.initializationFindings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  skir.AuthoringObservationId? confirmedObservation,  List<LocatedInitializationFinding> initializationFindings)  $default,) {final _that = this;
switch (_that) {
case _AuthoringDocument():
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.confirmedObservation,_that.initializationFindings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  skir.AuthoringObservationId? confirmedObservation,  List<LocatedInitializationFinding> initializationFindings)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.confirmedObservation,_that.initializationFindings);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringDocument extends AuthoringDocument {
  const _AuthoringDocument({required this.catalog, required  Map<skir.ResourceId, skir.AuthoringResource> entries, required  List<skir.LinkProjection> links, this.revision = 0, this.confirmedObservation,  List<LocatedInitializationFinding> initializationFindings = const []}): _entries = entries,_links = links,_initializationFindings = initializationFindings,super._();
  

@override final  CheckedEditorCatalog catalog;
 final  Map<skir.ResourceId, skir.AuthoringResource> _entries;
@override Map<skir.ResourceId, skir.AuthoringResource> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
}

 final  List<skir.LinkProjection> _links;
@override List<skir.LinkProjection> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

@override@JsonKey() final  int revision;
@override final  skir.AuthoringObservationId? confirmedObservation;
 final  List<LocatedInitializationFinding> _initializationFindings;
@override@JsonKey() List<LocatedInitializationFinding> get initializationFindings {
  if (_initializationFindings is EqualUnmodifiableListView) return _initializationFindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initializationFindings);
}


/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringDocumentCopyWith<_AuthoringDocument> get copyWith => __$AuthoringDocumentCopyWithImpl<_AuthoringDocument>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringDocument&&(identical(other.catalog, catalog) || other.catalog == catalog)&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.links, _links)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.confirmedObservation, confirmedObservation) || other.confirmedObservation == confirmedObservation)&&const DeepCollectionEquality().equals(other.initializationFindings, _initializationFindings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_links),revision,confirmedObservation,const DeepCollectionEquality().hash(_initializationFindings));
}

@override
String toString() {
    return 'AuthoringDocument(catalog: $catalog, entries: $entries, links: $links, revision: $revision, confirmedObservation: $confirmedObservation, initializationFindings: $initializationFindings)';
}


}

/// @nodoc
abstract mixin class _$AuthoringDocumentCopyWith<$Res> implements $AuthoringDocumentCopyWith<$Res> {
  factory _$AuthoringDocumentCopyWith(_AuthoringDocument value, $Res Function(_AuthoringDocument) _then) = __$AuthoringDocumentCopyWithImpl;
@override @useResult
$Res call({
 CheckedEditorCatalog catalog, Map<skir.ResourceId, skir.AuthoringResource> entries, List<skir.LinkProjection> links, int revision, skir.AuthoringObservationId? confirmedObservation, List<LocatedInitializationFinding> initializationFindings
});




}
/// @nodoc
class __$AuthoringDocumentCopyWithImpl<$Res>
    implements _$AuthoringDocumentCopyWith<$Res> {
  __$AuthoringDocumentCopyWithImpl(this._self, this._then);

  final _AuthoringDocument _self;
  final $Res Function(_AuthoringDocument) _then;

/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? entries = null,Object? links = null,Object? revision = null,Object? confirmedObservation = freezed,Object? initializationFindings = null,}) {
  return _then(_AuthoringDocument(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,confirmedObservation: freezed == confirmedObservation ? _self.confirmedObservation : confirmedObservation // ignore: cast_nullable_to_non_nullable
as skir.AuthoringObservationId?,initializationFindings: null == initializationFindings ? _self._initializationFindings : initializationFindings // ignore: cast_nullable_to_non_nullable
as List<LocatedInitializationFinding>,
  ));
}


}

/// @nodoc
mixin _$AuthoringScope {

 skir.RecordId get organizationId; skir.RecordId get realmId;
/// Create a copy of AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<AuthoringScope> get copyWith => _$AuthoringScopeCopyWithImpl<AuthoringScope>(this as AuthoringScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringScope&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId));
}


@override
int get hashCode {
  final _this = this as AuthoringScope;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId);
}

@override
String toString() {
  final _this = this as AuthoringScope;
  return 'AuthoringScope(organizationId: ${_this.organizationId}, realmId: ${_this.realmId})';
}


}

/// @nodoc
abstract mixin class $AuthoringScopeCopyWith<$Res>  {
  factory $AuthoringScopeCopyWith(AuthoringScope value, $Res Function(AuthoringScope) _then) = _$AuthoringScopeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class _$AuthoringScopeCopyWithImpl<$Res>
    implements $AuthoringScopeCopyWith<$Res> {
  _$AuthoringScopeCopyWithImpl(this._self, this._then);

  final AuthoringScope _self;
  final $Res Function(AuthoringScope) _then;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringScope].
extension AuthoringScopePatterns on AuthoringScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringScope value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringScope value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)  $default,) {final _that = this;
switch (_that) {
case _AuthoringScope():
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringScope implements AuthoringScope {
  const _AuthoringScope({required this.organizationId, required this.realmId});
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringScopeCopyWith<_AuthoringScope> get copyWith => __$AuthoringScopeCopyWithImpl<_AuthoringScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringScope&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId);
}

@override
String toString() {
    return 'AuthoringScope(organizationId: $organizationId, realmId: $realmId)';
}


}

/// @nodoc
abstract mixin class _$AuthoringScopeCopyWith<$Res> implements $AuthoringScopeCopyWith<$Res> {
  factory _$AuthoringScopeCopyWith(_AuthoringScope value, $Res Function(_AuthoringScope) _then) = __$AuthoringScopeCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class __$AuthoringScopeCopyWithImpl<$Res>
    implements _$AuthoringScopeCopyWith<$Res> {
  __$AuthoringScopeCopyWithImpl(this._self, this._then);

  final _AuthoringScope _self;
  final $Res Function(_AuthoringScope) _then;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(_AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

/// @nodoc
mixin _$LocatedInitializationFinding {

 skir.ValueLocation get location; skir.InitializationDiagnostic get diagnostic; skir.DiagnosticEvidence get evidence;
/// Create a copy of LocatedInitializationFinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocatedInitializationFindingCopyWith<LocatedInitializationFinding> get copyWith => _$LocatedInitializationFindingCopyWithImpl<LocatedInitializationFinding>(this as LocatedInitializationFinding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocatedInitializationFinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocatedInitializationFinding&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.diagnostic, _this.diagnostic) || other.diagnostic == _this.diagnostic)&&(identical(other.evidence, _this.evidence) || other.evidence == _this.evidence));
}


@override
int get hashCode {
  final _this = this as LocatedInitializationFinding;
  return Object.hash(runtimeType,_this.location,_this.diagnostic,_this.evidence);
}

@override
String toString() {
  final _this = this as LocatedInitializationFinding;
  return 'LocatedInitializationFinding(location: ${_this.location}, diagnostic: ${_this.diagnostic}, evidence: ${_this.evidence})';
}


}

/// @nodoc
abstract mixin class $LocatedInitializationFindingCopyWith<$Res>  {
  factory $LocatedInitializationFindingCopyWith(LocatedInitializationFinding value, $Res Function(LocatedInitializationFinding) _then) = _$LocatedInitializationFindingCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation location, skir.InitializationDiagnostic diagnostic, skir.DiagnosticEvidence evidence
});




}
/// @nodoc
class _$LocatedInitializationFindingCopyWithImpl<$Res>
    implements $LocatedInitializationFindingCopyWith<$Res> {
  _$LocatedInitializationFindingCopyWithImpl(this._self, this._then);

  final LocatedInitializationFinding _self;
  final $Res Function(LocatedInitializationFinding) _then;

/// Create a copy of LocatedInitializationFinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? location = null,Object? diagnostic = null,Object? evidence = null,}) {
  return _then(LocatedInitializationFinding(
location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as skir.InitializationDiagnostic,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticEvidence,
  ));
}

}


/// Adds pattern-matching-related methods to [LocatedInitializationFinding].
extension LocatedInitializationFindingPatterns on LocatedInitializationFinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocatedInitializationFinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocatedInitializationFinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocatedInitializationFinding value)  $default,){
final _that = this;
switch (_that) {
case _LocatedInitializationFinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocatedInitializationFinding value)?  $default,){
final _that = this;
switch (_that) {
case _LocatedInitializationFinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValueLocation location,  skir.InitializationDiagnostic diagnostic,  skir.DiagnosticEvidence evidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocatedInitializationFinding() when $default != null:
return $default(_that.location,_that.diagnostic,_that.evidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValueLocation location,  skir.InitializationDiagnostic diagnostic,  skir.DiagnosticEvidence evidence)  $default,) {final _that = this;
switch (_that) {
case _LocatedInitializationFinding():
return $default(_that.location,_that.diagnostic,_that.evidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValueLocation location,  skir.InitializationDiagnostic diagnostic,  skir.DiagnosticEvidence evidence)?  $default,) {final _that = this;
switch (_that) {
case _LocatedInitializationFinding() when $default != null:
return $default(_that.location,_that.diagnostic,_that.evidence);case _:
  return null;

}
}

}

/// @nodoc


class _LocatedInitializationFinding implements LocatedInitializationFinding {
  const _LocatedInitializationFinding({required this.location, required this.diagnostic, required this.evidence});
  

@override final  skir.ValueLocation location;
@override final  skir.InitializationDiagnostic diagnostic;
@override final  skir.DiagnosticEvidence evidence;

/// Create a copy of LocatedInitializationFinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocatedInitializationFindingCopyWith<_LocatedInitializationFinding> get copyWith => __$LocatedInitializationFindingCopyWithImpl<_LocatedInitializationFinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocatedInitializationFinding&&(identical(other.location, location) || other.location == location)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic)&&(identical(other.evidence, evidence) || other.evidence == evidence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,location,diagnostic,evidence);
}

@override
String toString() {
    return 'LocatedInitializationFinding(location: $location, diagnostic: $diagnostic, evidence: $evidence)';
}


}

/// @nodoc
abstract mixin class _$LocatedInitializationFindingCopyWith<$Res> implements $LocatedInitializationFindingCopyWith<$Res> {
  factory _$LocatedInitializationFindingCopyWith(_LocatedInitializationFinding value, $Res Function(_LocatedInitializationFinding) _then) = __$LocatedInitializationFindingCopyWithImpl;
@override @useResult
$Res call({
 skir.ValueLocation location, skir.InitializationDiagnostic diagnostic, skir.DiagnosticEvidence evidence
});




}
/// @nodoc
class __$LocatedInitializationFindingCopyWithImpl<$Res>
    implements _$LocatedInitializationFindingCopyWith<$Res> {
  __$LocatedInitializationFindingCopyWithImpl(this._self, this._then);

  final _LocatedInitializationFinding _self;
  final $Res Function(_LocatedInitializationFinding) _then;

/// Create a copy of LocatedInitializationFinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? location = null,Object? diagnostic = null,Object? evidence = null,}) {
  return _then(_LocatedInitializationFinding(
location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as skir.InitializationDiagnostic,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as skir.DiagnosticEvidence,
  ));
}


}

/// @nodoc
mixin _$AuthoringFacts {

 Map<skir.ResourceId, skir.AuthoringRecord> get resources; List<skir.LinkProjection> get links;
/// Create a copy of AuthoringFacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringFactsCopyWith<AuthoringFacts> get copyWith => _$AuthoringFactsCopyWithImpl<AuthoringFacts>(this as AuthoringFacts, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringFacts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringFacts&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&const DeepCollectionEquality().equals(other.links, _this.links));
}


@override
int get hashCode {
  final _this = this as AuthoringFacts;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.resources),const DeepCollectionEquality().hash(_this.links));
}

@override
String toString() {
  final _this = this as AuthoringFacts;
  return 'AuthoringFacts(resources: ${_this.resources}, links: ${_this.links})';
}


}

/// @nodoc
abstract mixin class $AuthoringFactsCopyWith<$Res>  {
  factory $AuthoringFactsCopyWith(AuthoringFacts value, $Res Function(AuthoringFacts) _then) = _$AuthoringFactsCopyWithImpl;
@useResult
$Res call({
 Map<skir.ResourceId, skir.AuthoringRecord> resources, List<skir.LinkProjection> links
});




}
/// @nodoc
class _$AuthoringFactsCopyWithImpl<$Res>
    implements $AuthoringFactsCopyWith<$Res> {
  _$AuthoringFactsCopyWithImpl(this._self, this._then);

  final AuthoringFacts _self;
  final $Res Function(AuthoringFacts) _then;

/// Create a copy of AuthoringFacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resources = null,Object? links = null,}) {
  return _then(AuthoringFacts(
resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringRecord>,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringFacts].
extension AuthoringFactsPatterns on AuthoringFacts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringFacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringFacts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringFacts value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringFacts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringFacts value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringFacts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<skir.ResourceId, skir.AuthoringRecord> resources,  List<skir.LinkProjection> links)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringFacts() when $default != null:
return $default(_that.resources,_that.links);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<skir.ResourceId, skir.AuthoringRecord> resources,  List<skir.LinkProjection> links)  $default,) {final _that = this;
switch (_that) {
case _AuthoringFacts():
return $default(_that.resources,_that.links);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<skir.ResourceId, skir.AuthoringRecord> resources,  List<skir.LinkProjection> links)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringFacts() when $default != null:
return $default(_that.resources,_that.links);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringFacts extends AuthoringFacts {
  const _AuthoringFacts({required  Map<skir.ResourceId, skir.AuthoringRecord> resources, required  List<skir.LinkProjection> links}): _resources = resources,_links = links,super._();
  

 final  Map<skir.ResourceId, skir.AuthoringRecord> _resources;
@override Map<skir.ResourceId, skir.AuthoringRecord> get resources {
  if (_resources is EqualUnmodifiableMapView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resources);
}

 final  List<skir.LinkProjection> _links;
@override List<skir.LinkProjection> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}


/// Create a copy of AuthoringFacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringFactsCopyWith<_AuthoringFacts> get copyWith => __$AuthoringFactsCopyWithImpl<_AuthoringFacts>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringFacts&&const DeepCollectionEquality().equals(other.resources, _resources)&&const DeepCollectionEquality().equals(other.links, _links));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_links));
}

@override
String toString() {
    return 'AuthoringFacts(resources: $resources, links: $links)';
}


}

/// @nodoc
abstract mixin class _$AuthoringFactsCopyWith<$Res> implements $AuthoringFactsCopyWith<$Res> {
  factory _$AuthoringFactsCopyWith(_AuthoringFacts value, $Res Function(_AuthoringFacts) _then) = __$AuthoringFactsCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ResourceId, skir.AuthoringRecord> resources, List<skir.LinkProjection> links
});




}
/// @nodoc
class __$AuthoringFactsCopyWithImpl<$Res>
    implements _$AuthoringFactsCopyWith<$Res> {
  __$AuthoringFactsCopyWithImpl(this._self, this._then);

  final _AuthoringFacts _self;
  final $Res Function(_AuthoringFacts) _then;

/// Create a copy of AuthoringFacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resources = null,Object? links = null,}) {
  return _then(_AuthoringFacts(
resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringRecord>,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,
  ));
}


}

/// @nodoc
mixin _$AuthoringConflictReview {

 EditGroupId get group; Set<int> get operations; List<RealmPreparedEdit> get edits; AuthoringDocument get saved; AuthoringDocument get original; AuthoringDocument get beforeGroup; AuthoringDocument get proposal; List<skir.EditExpectation> get reviewedFacts; AuthoringConflictEvidence get evidence; List<EditorDiagnostic> get diagnostics;
/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringConflictReviewCopyWith<AuthoringConflictReview> get copyWith => _$AuthoringConflictReviewCopyWithImpl<AuthoringConflictReview>(this as AuthoringConflictReview, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringConflictReview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringConflictReview&&(identical(other.group, _this.group) || other.group == _this.group)&&const DeepCollectionEquality().equals(other.operations, _this.operations)&&const DeepCollectionEquality().equals(other.edits, _this.edits)&&(identical(other.saved, _this.saved) || other.saved == _this.saved)&&(identical(other.original, _this.original) || other.original == _this.original)&&(identical(other.beforeGroup, _this.beforeGroup) || other.beforeGroup == _this.beforeGroup)&&(identical(other.proposal, _this.proposal) || other.proposal == _this.proposal)&&const DeepCollectionEquality().equals(other.reviewedFacts, _this.reviewedFacts)&&(identical(other.evidence, _this.evidence) || other.evidence == _this.evidence)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as AuthoringConflictReview;
  return Object.hash(runtimeType,_this.group,const DeepCollectionEquality().hash(_this.operations),const DeepCollectionEquality().hash(_this.edits),_this.saved,_this.original,_this.beforeGroup,_this.proposal,const DeepCollectionEquality().hash(_this.reviewedFacts),_this.evidence,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as AuthoringConflictReview;
  return 'AuthoringConflictReview(group: ${_this.group}, operations: ${_this.operations}, edits: ${_this.edits}, saved: ${_this.saved}, original: ${_this.original}, beforeGroup: ${_this.beforeGroup}, proposal: ${_this.proposal}, reviewedFacts: ${_this.reviewedFacts}, evidence: ${_this.evidence}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $AuthoringConflictReviewCopyWith<$Res>  {
  factory $AuthoringConflictReviewCopyWith(AuthoringConflictReview value, $Res Function(AuthoringConflictReview) _then) = _$AuthoringConflictReviewCopyWithImpl;
@useResult
$Res call({
 EditGroupId group, Set<int> operations, List<RealmPreparedEdit> edits, AuthoringDocument saved, AuthoringDocument original, AuthoringDocument beforeGroup, AuthoringDocument proposal, List<skir.EditExpectation> reviewedFacts, AuthoringConflictEvidence evidence, List<EditorDiagnostic> diagnostics
});


$EditGroupIdCopyWith<$Res> get group;$AuthoringDocumentCopyWith<$Res> get saved;$AuthoringDocumentCopyWith<$Res> get original;$AuthoringDocumentCopyWith<$Res> get beforeGroup;$AuthoringDocumentCopyWith<$Res> get proposal;$AuthoringConflictEvidenceCopyWith<$Res> get evidence;

}
/// @nodoc
class _$AuthoringConflictReviewCopyWithImpl<$Res>
    implements $AuthoringConflictReviewCopyWith<$Res> {
  _$AuthoringConflictReviewCopyWithImpl(this._self, this._then);

  final AuthoringConflictReview _self;
  final $Res Function(AuthoringConflictReview) _then;

/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? operations = null,Object? edits = null,Object? saved = null,Object? original = null,Object? beforeGroup = null,Object? proposal = null,Object? reviewedFacts = null,Object? evidence = null,Object? diagnostics = null,}) {
  return _then(AuthoringConflictReview(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as EditGroupId,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,edits: null == edits ? _self.edits : edits // ignore: cast_nullable_to_non_nullable
as List<RealmPreparedEdit>,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,beforeGroup: null == beforeGroup ? _self.beforeGroup : beforeGroup // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,proposal: null == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,reviewedFacts: null == reviewedFacts ? _self.reviewedFacts : reviewedFacts // ignore: cast_nullable_to_non_nullable
as List<skir.EditExpectation>,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as AuthoringConflictEvidence,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}
/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get group {
  
  return $EditGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get saved {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.saved, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get original {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get beforeGroup {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.beforeGroup, (value) {
    return _then(_self.copyWith(beforeGroup: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get proposal {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.proposal, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringConflictEvidenceCopyWith<$Res> get evidence {
  
  return $AuthoringConflictEvidenceCopyWith<$Res>(_self.evidence, (value) {
    return _then(_self.copyWith(evidence: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringConflictReview].
extension AuthoringConflictReviewPatterns on AuthoringConflictReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringConflictReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringConflictReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringConflictReview value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringConflictReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringConflictReview value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringConflictReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditGroupId group,  Set<int> operations,  List<RealmPreparedEdit> edits,  AuthoringDocument saved,  AuthoringDocument original,  AuthoringDocument beforeGroup,  AuthoringDocument proposal,  List<skir.EditExpectation> reviewedFacts,  AuthoringConflictEvidence evidence,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringConflictReview() when $default != null:
return $default(_that.group,_that.operations,_that.edits,_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.reviewedFacts,_that.evidence,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditGroupId group,  Set<int> operations,  List<RealmPreparedEdit> edits,  AuthoringDocument saved,  AuthoringDocument original,  AuthoringDocument beforeGroup,  AuthoringDocument proposal,  List<skir.EditExpectation> reviewedFacts,  AuthoringConflictEvidence evidence,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _AuthoringConflictReview():
return $default(_that.group,_that.operations,_that.edits,_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.reviewedFacts,_that.evidence,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditGroupId group,  Set<int> operations,  List<RealmPreparedEdit> edits,  AuthoringDocument saved,  AuthoringDocument original,  AuthoringDocument beforeGroup,  AuthoringDocument proposal,  List<skir.EditExpectation> reviewedFacts,  AuthoringConflictEvidence evidence,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringConflictReview() when $default != null:
return $default(_that.group,_that.operations,_that.edits,_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.reviewedFacts,_that.evidence,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringConflictReview extends AuthoringConflictReview {
  const _AuthoringConflictReview({required this.group, required  Set<int> operations, required  List<RealmPreparedEdit> edits, required this.saved, required this.original, required this.beforeGroup, required this.proposal, required  List<skir.EditExpectation> reviewedFacts, required this.evidence,  List<EditorDiagnostic> diagnostics = const []}): _operations = operations,_edits = edits,_reviewedFacts = reviewedFacts,_diagnostics = diagnostics,super._();
  

@override final  EditGroupId group;
 final  Set<int> _operations;
@override Set<int> get operations {
  if (_operations is EqualUnmodifiableSetView) return _operations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_operations);
}

 final  List<RealmPreparedEdit> _edits;
@override List<RealmPreparedEdit> get edits {
  if (_edits is EqualUnmodifiableListView) return _edits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edits);
}

@override final  AuthoringDocument saved;
@override final  AuthoringDocument original;
@override final  AuthoringDocument beforeGroup;
@override final  AuthoringDocument proposal;
 final  List<skir.EditExpectation> _reviewedFacts;
@override List<skir.EditExpectation> get reviewedFacts {
  if (_reviewedFacts is EqualUnmodifiableListView) return _reviewedFacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviewedFacts);
}

@override final  AuthoringConflictEvidence evidence;
 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringConflictReviewCopyWith<_AuthoringConflictReview> get copyWith => __$AuthoringConflictReviewCopyWithImpl<_AuthoringConflictReview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringConflictReview&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other.operations, _operations)&&const DeepCollectionEquality().equals(other.edits, _edits)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.original, original) || other.original == original)&&(identical(other.beforeGroup, beforeGroup) || other.beforeGroup == beforeGroup)&&(identical(other.proposal, proposal) || other.proposal == proposal)&&const DeepCollectionEquality().equals(other.reviewedFacts, _reviewedFacts)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group,const DeepCollectionEquality().hash(_operations),const DeepCollectionEquality().hash(_edits),saved,original,beforeGroup,proposal,const DeepCollectionEquality().hash(_reviewedFacts),evidence,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'AuthoringConflictReview(group: $group, operations: $operations, edits: $edits, saved: $saved, original: $original, beforeGroup: $beforeGroup, proposal: $proposal, reviewedFacts: $reviewedFacts, evidence: $evidence, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$AuthoringConflictReviewCopyWith<$Res> implements $AuthoringConflictReviewCopyWith<$Res> {
  factory _$AuthoringConflictReviewCopyWith(_AuthoringConflictReview value, $Res Function(_AuthoringConflictReview) _then) = __$AuthoringConflictReviewCopyWithImpl;
@override @useResult
$Res call({
 EditGroupId group, Set<int> operations, List<RealmPreparedEdit> edits, AuthoringDocument saved, AuthoringDocument original, AuthoringDocument beforeGroup, AuthoringDocument proposal, List<skir.EditExpectation> reviewedFacts, AuthoringConflictEvidence evidence, List<EditorDiagnostic> diagnostics
});


@override $EditGroupIdCopyWith<$Res> get group;@override $AuthoringDocumentCopyWith<$Res> get saved;@override $AuthoringDocumentCopyWith<$Res> get original;@override $AuthoringDocumentCopyWith<$Res> get beforeGroup;@override $AuthoringDocumentCopyWith<$Res> get proposal;@override $AuthoringConflictEvidenceCopyWith<$Res> get evidence;

}
/// @nodoc
class __$AuthoringConflictReviewCopyWithImpl<$Res>
    implements _$AuthoringConflictReviewCopyWith<$Res> {
  __$AuthoringConflictReviewCopyWithImpl(this._self, this._then);

  final _AuthoringConflictReview _self;
  final $Res Function(_AuthoringConflictReview) _then;

/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? operations = null,Object? edits = null,Object? saved = null,Object? original = null,Object? beforeGroup = null,Object? proposal = null,Object? reviewedFacts = null,Object? evidence = null,Object? diagnostics = null,}) {
  return _then(_AuthoringConflictReview(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as EditGroupId,operations: null == operations ? _self._operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,edits: null == edits ? _self._edits : edits // ignore: cast_nullable_to_non_nullable
as List<RealmPreparedEdit>,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,beforeGroup: null == beforeGroup ? _self.beforeGroup : beforeGroup // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,proposal: null == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,reviewedFacts: null == reviewedFacts ? _self._reviewedFacts : reviewedFacts // ignore: cast_nullable_to_non_nullable
as List<skir.EditExpectation>,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as AuthoringConflictEvidence,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get group {
  
  return $EditGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get saved {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.saved, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get original {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get beforeGroup {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.beforeGroup, (value) {
    return _then(_self.copyWith(beforeGroup: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get proposal {
  
  return $AuthoringDocumentCopyWith<$Res>(_self.proposal, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}/// Create a copy of AuthoringConflictReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringConflictEvidenceCopyWith<$Res> get evidence {
  
  return $AuthoringConflictEvidenceCopyWith<$Res>(_self.evidence, (value) {
    return _then(_self.copyWith(evidence: value));
  });
}
}

/// @nodoc
mixin _$ResourceCounterpartResolution {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCounterpartResolution);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ResourceCounterpartResolution()';
}


}

/// @nodoc
class $ResourceCounterpartResolutionCopyWith<$Res>  {
$ResourceCounterpartResolutionCopyWith(ResourceCounterpartResolution _, $Res Function(ResourceCounterpartResolution) __);
}


/// Adds pattern-matching-related methods to [ResourceCounterpartResolution].
extension ResourceCounterpartResolutionPatterns on ResourceCounterpartResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResolvedResourceCounterpart value)?  resolved,TResult Function( ResourceCounterpartChoiceRequired value)?  choiceRequired,TResult Function( InvalidResourceCounterpart value)?  invalid,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResolvedResourceCounterpart() when resolved != null:
return resolved(_that);case ResourceCounterpartChoiceRequired() when choiceRequired != null:
return choiceRequired(_that);case InvalidResourceCounterpart() when invalid != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResolvedResourceCounterpart value)  resolved,required TResult Function( ResourceCounterpartChoiceRequired value)  choiceRequired,required TResult Function( InvalidResourceCounterpart value)  invalid,}){
final _that = this;
switch (_that) {
case ResolvedResourceCounterpart():
return resolved(_that);case ResourceCounterpartChoiceRequired():
return choiceRequired(_that);case InvalidResourceCounterpart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResolvedResourceCounterpart value)?  resolved,TResult? Function( ResourceCounterpartChoiceRequired value)?  choiceRequired,TResult? Function( InvalidResourceCounterpart value)?  invalid,}){
final _that = this;
switch (_that) {
case ResolvedResourceCounterpart() when resolved != null:
return resolved(_that);case ResourceCounterpartChoiceRequired() when choiceRequired != null:
return choiceRequired(_that);case InvalidResourceCounterpart() when invalid != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ValueLocation location)?  resolved,TResult Function( String message)?  choiceRequired,TResult Function( String message)?  invalid,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResolvedResourceCounterpart() when resolved != null:
return resolved(_that.location);case ResourceCounterpartChoiceRequired() when choiceRequired != null:
return choiceRequired(_that.message);case InvalidResourceCounterpart() when invalid != null:
return invalid(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ValueLocation location)  resolved,required TResult Function( String message)  choiceRequired,required TResult Function( String message)  invalid,}) {final _that = this;
switch (_that) {
case ResolvedResourceCounterpart():
return resolved(_that.location);case ResourceCounterpartChoiceRequired():
return choiceRequired(_that.message);case InvalidResourceCounterpart():
return invalid(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ValueLocation location)?  resolved,TResult? Function( String message)?  choiceRequired,TResult? Function( String message)?  invalid,}) {final _that = this;
switch (_that) {
case ResolvedResourceCounterpart() when resolved != null:
return resolved(_that.location);case ResourceCounterpartChoiceRequired() when choiceRequired != null:
return choiceRequired(_that.message);case InvalidResourceCounterpart() when invalid != null:
return invalid(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ResolvedResourceCounterpart implements ResourceCounterpartResolution {
  const ResolvedResourceCounterpart(this.location);
  

 final  skir.ValueLocation location;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedResourceCounterpartCopyWith<ResolvedResourceCounterpart> get copyWith => _$ResolvedResourceCounterpartCopyWithImpl<ResolvedResourceCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedResourceCounterpart&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode {
    return Object.hash(runtimeType,location);
}

@override
String toString() {
    return 'ResourceCounterpartResolution.resolved(location: $location)';
}


}

/// @nodoc
abstract mixin class $ResolvedResourceCounterpartCopyWith<$Res> implements $ResourceCounterpartResolutionCopyWith<$Res> {
  factory $ResolvedResourceCounterpartCopyWith(ResolvedResourceCounterpart value, $Res Function(ResolvedResourceCounterpart) _then) = _$ResolvedResourceCounterpartCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation location
});




}
/// @nodoc
class _$ResolvedResourceCounterpartCopyWithImpl<$Res>
    implements $ResolvedResourceCounterpartCopyWith<$Res> {
  _$ResolvedResourceCounterpartCopyWithImpl(this._self, this._then);

  final ResolvedResourceCounterpart _self;
  final $Res Function(ResolvedResourceCounterpart) _then;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? location = null,}) {
  return _then(ResolvedResourceCounterpart(
null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,
  ));
}


}

/// @nodoc


class ResourceCounterpartChoiceRequired implements ResourceCounterpartResolution {
  const ResourceCounterpartChoiceRequired(this.message);
  

 final  String message;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCounterpartChoiceRequiredCopyWith<ResourceCounterpartChoiceRequired> get copyWith => _$ResourceCounterpartChoiceRequiredCopyWithImpl<ResourceCounterpartChoiceRequired>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceCounterpartChoiceRequired&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ResourceCounterpartResolution.choiceRequired(message: $message)';
}


}

/// @nodoc
abstract mixin class $ResourceCounterpartChoiceRequiredCopyWith<$Res> implements $ResourceCounterpartResolutionCopyWith<$Res> {
  factory $ResourceCounterpartChoiceRequiredCopyWith(ResourceCounterpartChoiceRequired value, $Res Function(ResourceCounterpartChoiceRequired) _then) = _$ResourceCounterpartChoiceRequiredCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ResourceCounterpartChoiceRequiredCopyWithImpl<$Res>
    implements $ResourceCounterpartChoiceRequiredCopyWith<$Res> {
  _$ResourceCounterpartChoiceRequiredCopyWithImpl(this._self, this._then);

  final ResourceCounterpartChoiceRequired _self;
  final $Res Function(ResourceCounterpartChoiceRequired) _then;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ResourceCounterpartChoiceRequired(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InvalidResourceCounterpart implements ResourceCounterpartResolution {
  const InvalidResourceCounterpart(this.message);
  

 final  String message;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidResourceCounterpartCopyWith<InvalidResourceCounterpart> get copyWith => _$InvalidResourceCounterpartCopyWithImpl<InvalidResourceCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidResourceCounterpart&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ResourceCounterpartResolution.invalid(message: $message)';
}


}

/// @nodoc
abstract mixin class $InvalidResourceCounterpartCopyWith<$Res> implements $ResourceCounterpartResolutionCopyWith<$Res> {
  factory $InvalidResourceCounterpartCopyWith(InvalidResourceCounterpart value, $Res Function(InvalidResourceCounterpart) _then) = _$InvalidResourceCounterpartCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$InvalidResourceCounterpartCopyWithImpl<$Res>
    implements $InvalidResourceCounterpartCopyWith<$Res> {
  _$InvalidResourceCounterpartCopyWithImpl(this._self, this._then);

  final InvalidResourceCounterpart _self;
  final $Res Function(InvalidResourceCounterpart) _then;

/// Create a copy of ResourceCounterpartResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(InvalidResourceCounterpart(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
