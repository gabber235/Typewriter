// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_destination_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ElementPageSelection implements DiagnosticableTreeMixin {

 skir.RecordId get bookId; PageEntryCreationPolicy get policy;
/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementPageSelectionCopyWith<ElementPageSelection> get copyWith => _$ElementPageSelectionCopyWithImpl<ElementPageSelection>(this as ElementPageSelection, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ElementPageSelection;
  properties
    ..add(DiagnosticsProperty('type', 'ElementPageSelection'))
    ..add(DiagnosticsProperty('bookId', _this.bookId))..add(DiagnosticsProperty('policy', _this.policy));
}

@override
bool operator ==(Object other) {
  final _this = this as ElementPageSelection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementPageSelection&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.policy, _this.policy) || other.policy == _this.policy));
}


@override
int get hashCode {
  final _this = this as ElementPageSelection;
  return Object.hash(runtimeType,_this.bookId,_this.policy);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ElementPageSelection;
  return 'ElementPageSelection(bookId: ${_this.bookId}, policy: ${_this.policy})';
}


}

/// @nodoc
abstract mixin class $ElementPageSelectionCopyWith<$Res>  {
  factory $ElementPageSelectionCopyWith(ElementPageSelection value, $Res Function(ElementPageSelection) _then) = _$ElementPageSelectionCopyWithImpl;
@useResult
$Res call({
 skir.RecordId bookId, PageEntryCreationPolicy policy
});


$PageEntryCreationPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$ElementPageSelectionCopyWithImpl<$Res>
    implements $ElementPageSelectionCopyWith<$Res> {
  _$ElementPageSelectionCopyWithImpl(this._self, this._then);

  final ElementPageSelection _self;
  final $Res Function(ElementPageSelection) _then;

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookId = null,Object? policy = null,}) {
  return _then(_self.copyWith(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as PageEntryCreationPolicy,
  ));
}
/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageEntryCreationPolicyCopyWith<$Res> get policy {
  
  return $PageEntryCreationPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ElementPageSelection].
extension ElementPageSelectionPatterns on ElementPageSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExistingElementPageSelection value)?  existing,TResult Function( NewElementPageSelection value)?  create,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExistingElementPageSelection() when existing != null:
return existing(_that);case NewElementPageSelection() when create != null:
return create(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExistingElementPageSelection value)  existing,required TResult Function( NewElementPageSelection value)  create,}){
final _that = this;
switch (_that) {
case ExistingElementPageSelection():
return existing(_that);case NewElementPageSelection():
return create(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExistingElementPageSelection value)?  existing,TResult? Function( NewElementPageSelection value)?  create,}){
final _that = this;
switch (_that) {
case ExistingElementPageSelection() when existing != null:
return existing(_that);case NewElementPageSelection() when create != null:
return create(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.RecordId pageId,  skir.RecordId bookId,  PageEntryCreationPolicy policy)?  existing,TResult Function( skir.RecordId bookId,  PageCreationInput input,  PageEntryCreationPolicy policy)?  create,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExistingElementPageSelection() when existing != null:
return existing(_that.pageId,_that.bookId,_that.policy);case NewElementPageSelection() when create != null:
return create(_that.bookId,_that.input,_that.policy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.RecordId pageId,  skir.RecordId bookId,  PageEntryCreationPolicy policy)  existing,required TResult Function( skir.RecordId bookId,  PageCreationInput input,  PageEntryCreationPolicy policy)  create,}) {final _that = this;
switch (_that) {
case ExistingElementPageSelection():
return existing(_that.pageId,_that.bookId,_that.policy);case NewElementPageSelection():
return create(_that.bookId,_that.input,_that.policy);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.RecordId pageId,  skir.RecordId bookId,  PageEntryCreationPolicy policy)?  existing,TResult? Function( skir.RecordId bookId,  PageCreationInput input,  PageEntryCreationPolicy policy)?  create,}) {final _that = this;
switch (_that) {
case ExistingElementPageSelection() when existing != null:
return existing(_that.pageId,_that.bookId,_that.policy);case NewElementPageSelection() when create != null:
return create(_that.bookId,_that.input,_that.policy);case _:
  return null;

}
}

}

/// @nodoc


class ExistingElementPageSelection with DiagnosticableTreeMixin implements ElementPageSelection {
  const ExistingElementPageSelection({required this.pageId, required this.bookId, required this.policy});
  

 final  skir.RecordId pageId;
@override final  skir.RecordId bookId;
@override final  PageEntryCreationPolicy policy;

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExistingElementPageSelectionCopyWith<ExistingElementPageSelection> get copyWith => _$ExistingElementPageSelectionCopyWithImpl<ExistingElementPageSelection>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ElementPageSelection.existing'))
    ..add(DiagnosticsProperty('pageId', pageId))..add(DiagnosticsProperty('bookId', bookId))..add(DiagnosticsProperty('policy', policy));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExistingElementPageSelection&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.policy, policy) || other.policy == policy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pageId,bookId,policy);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ElementPageSelection.existing(pageId: $pageId, bookId: $bookId, policy: $policy)';
}


}

/// @nodoc
abstract mixin class $ExistingElementPageSelectionCopyWith<$Res> implements $ElementPageSelectionCopyWith<$Res> {
  factory $ExistingElementPageSelectionCopyWith(ExistingElementPageSelection value, $Res Function(ExistingElementPageSelection) _then) = _$ExistingElementPageSelectionCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId pageId, skir.RecordId bookId, PageEntryCreationPolicy policy
});


@override $PageEntryCreationPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$ExistingElementPageSelectionCopyWithImpl<$Res>
    implements $ExistingElementPageSelectionCopyWith<$Res> {
  _$ExistingElementPageSelectionCopyWithImpl(this._self, this._then);

  final ExistingElementPageSelection _self;
  final $Res Function(ExistingElementPageSelection) _then;

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageId = null,Object? bookId = null,Object? policy = null,}) {
  return _then(ExistingElementPageSelection(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as PageEntryCreationPolicy,
  ));
}

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageEntryCreationPolicyCopyWith<$Res> get policy {
  
  return $PageEntryCreationPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}

/// @nodoc


class NewElementPageSelection with DiagnosticableTreeMixin implements ElementPageSelection {
  const NewElementPageSelection({required this.bookId, required this.input, required this.policy});
  

@override final  skir.RecordId bookId;
 final  PageCreationInput input;
@override final  PageEntryCreationPolicy policy;

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewElementPageSelectionCopyWith<NewElementPageSelection> get copyWith => _$NewElementPageSelectionCopyWithImpl<NewElementPageSelection>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ElementPageSelection.create'))
    ..add(DiagnosticsProperty('bookId', bookId))..add(DiagnosticsProperty('input', input))..add(DiagnosticsProperty('policy', policy));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NewElementPageSelection&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.input, input) || other.input == input)&&(identical(other.policy, policy) || other.policy == policy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bookId,input,policy);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ElementPageSelection.create(bookId: $bookId, input: $input, policy: $policy)';
}


}

/// @nodoc
abstract mixin class $NewElementPageSelectionCopyWith<$Res> implements $ElementPageSelectionCopyWith<$Res> {
  factory $NewElementPageSelectionCopyWith(NewElementPageSelection value, $Res Function(NewElementPageSelection) _then) = _$NewElementPageSelectionCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId bookId, PageCreationInput input, PageEntryCreationPolicy policy
});


$PageCreationInputCopyWith<$Res> get input;@override $PageEntryCreationPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$NewElementPageSelectionCopyWithImpl<$Res>
    implements $NewElementPageSelectionCopyWith<$Res> {
  _$NewElementPageSelectionCopyWithImpl(this._self, this._then);

  final NewElementPageSelection _self;
  final $Res Function(NewElementPageSelection) _then;

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookId = null,Object? input = null,Object? policy = null,}) {
  return _then(NewElementPageSelection(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PageCreationInput,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as PageEntryCreationPolicy,
  ));
}

/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageCreationInputCopyWith<$Res> get input {
  
  return $PageCreationInputCopyWith<$Res>(_self.input, (value) {
    return _then(_self.copyWith(input: value));
  });
}/// Create a copy of ElementPageSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageEntryCreationPolicyCopyWith<$Res> get policy {
  
  return $PageEntryCreationPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}

// dart format on
