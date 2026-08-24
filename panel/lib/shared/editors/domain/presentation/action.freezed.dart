// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorAction {

 Object get action;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorAction&&const DeepCollectionEquality().equals(other.action, action));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(action));

@override
String toString() {
  return 'EditorAction(action: $action)';
}


}

/// @nodoc
class $EditorActionCopyWith<$Res>  {
$EditorActionCopyWith(EditorAction _, $Res Function(EditorAction) __);
}


/// Adds pattern-matching-related methods to [EditorAction].
extension EditorActionPatterns on EditorAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocalEditorAction value)?  local,TResult Function( RealmEditorAction value)?  realm,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocalEditorAction() when local != null:
return local(_that);case RealmEditorAction() when realm != null:
return realm(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocalEditorAction value)  local,required TResult Function( RealmEditorAction value)  realm,}){
final _that = this;
switch (_that) {
case LocalEditorAction():
return local(_that);case RealmEditorAction():
return realm(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocalEditorAction value)?  local,TResult? Function( RealmEditorAction value)?  realm,}){
final _that = this;
switch (_that) {
case LocalEditorAction() when local != null:
return local(_that);case RealmEditorAction() when realm != null:
return realm(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LocalAction action)?  local,TResult Function( RealmAction action)?  realm,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocalEditorAction() when local != null:
return local(_that.action);case RealmEditorAction() when realm != null:
return realm(_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LocalAction action)  local,required TResult Function( RealmAction action)  realm,}) {final _that = this;
switch (_that) {
case LocalEditorAction():
return local(_that.action);case RealmEditorAction():
return realm(_that.action);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LocalAction action)?  local,TResult? Function( RealmAction action)?  realm,}) {final _that = this;
switch (_that) {
case LocalEditorAction() when local != null:
return local(_that.action);case RealmEditorAction() when realm != null:
return realm(_that.action);case _:
  return null;

}
}

}

/// @nodoc


class LocalEditorAction implements EditorAction {
  const LocalEditorAction(this.action);
  

@override final  LocalAction action;

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalEditorActionCopyWith<LocalEditorAction> get copyWith => _$LocalEditorActionCopyWithImpl<LocalEditorAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalEditorAction&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'EditorAction.local(action: $action)';
}


}

/// @nodoc
abstract mixin class $LocalEditorActionCopyWith<$Res> implements $EditorActionCopyWith<$Res> {
  factory $LocalEditorActionCopyWith(LocalEditorAction value, $Res Function(LocalEditorAction) _then) = _$LocalEditorActionCopyWithImpl;
@useResult
$Res call({
 LocalAction action
});


$LocalActionCopyWith<$Res> get action;

}
/// @nodoc
class _$LocalEditorActionCopyWithImpl<$Res>
    implements $LocalEditorActionCopyWith<$Res> {
  _$LocalEditorActionCopyWithImpl(this._self, this._then);

  final LocalEditorAction _self;
  final $Res Function(LocalEditorAction) _then;

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(LocalEditorAction(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as LocalAction,
  ));
}

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalActionCopyWith<$Res> get action {
  
  return $LocalActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class RealmEditorAction implements EditorAction {
  const RealmEditorAction(this.action);
  

@override final  RealmAction action;

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorActionCopyWith<RealmEditorAction> get copyWith => _$RealmEditorActionCopyWithImpl<RealmEditorAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorAction&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'EditorAction.realm(action: $action)';
}


}

/// @nodoc
abstract mixin class $RealmEditorActionCopyWith<$Res> implements $EditorActionCopyWith<$Res> {
  factory $RealmEditorActionCopyWith(RealmEditorAction value, $Res Function(RealmEditorAction) _then) = _$RealmEditorActionCopyWithImpl;
@useResult
$Res call({
 RealmAction action
});


$RealmActionCopyWith<$Res> get action;

}
/// @nodoc
class _$RealmEditorActionCopyWithImpl<$Res>
    implements $RealmEditorActionCopyWith<$Res> {
  _$RealmEditorActionCopyWithImpl(this._self, this._then);

  final RealmEditorAction _self;
  final $Res Function(RealmEditorAction) _then;

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(RealmEditorAction(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as RealmAction,
  ));
}

/// Create a copy of EditorAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionCopyWith<$Res> get action {
  
  return $RealmActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc
mixin _$LocalAction {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalAction()';
}


}

/// @nodoc
class $LocalActionCopyWith<$Res>  {
$LocalActionCopyWith(LocalAction _, $Res Function(LocalAction) __);
}


/// Adds pattern-matching-related methods to [LocalAction].
extension LocalActionPatterns on LocalAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SetValueAction value)?  setValue,TResult Function( InsertListItemAction value)?  insertListItem,TResult Function( RemoveListItemAction value)?  removeListItem,TResult Function( AppendListItemAction value)?  appendListItem,TResult Function( DuplicateListItemAction value)?  duplicateListItem,TResult Function( ReorderListItemAction value)?  reorderListItem,TResult Function( PutMapEntryAction value)?  putMapEntry,TResult Function( RemoveMapEntryAction value)?  removeMapEntry,TResult Function( ReplaceConcreteTypeAction value)?  replaceConcreteType,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SetValueAction() when setValue != null:
return setValue(_that);case InsertListItemAction() when insertListItem != null:
return insertListItem(_that);case RemoveListItemAction() when removeListItem != null:
return removeListItem(_that);case AppendListItemAction() when appendListItem != null:
return appendListItem(_that);case DuplicateListItemAction() when duplicateListItem != null:
return duplicateListItem(_that);case ReorderListItemAction() when reorderListItem != null:
return reorderListItem(_that);case PutMapEntryAction() when putMapEntry != null:
return putMapEntry(_that);case RemoveMapEntryAction() when removeMapEntry != null:
return removeMapEntry(_that);case ReplaceConcreteTypeAction() when replaceConcreteType != null:
return replaceConcreteType(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SetValueAction value)  setValue,required TResult Function( InsertListItemAction value)  insertListItem,required TResult Function( RemoveListItemAction value)  removeListItem,required TResult Function( AppendListItemAction value)  appendListItem,required TResult Function( DuplicateListItemAction value)  duplicateListItem,required TResult Function( ReorderListItemAction value)  reorderListItem,required TResult Function( PutMapEntryAction value)  putMapEntry,required TResult Function( RemoveMapEntryAction value)  removeMapEntry,required TResult Function( ReplaceConcreteTypeAction value)  replaceConcreteType,}){
final _that = this;
switch (_that) {
case SetValueAction():
return setValue(_that);case InsertListItemAction():
return insertListItem(_that);case RemoveListItemAction():
return removeListItem(_that);case AppendListItemAction():
return appendListItem(_that);case DuplicateListItemAction():
return duplicateListItem(_that);case ReorderListItemAction():
return reorderListItem(_that);case PutMapEntryAction():
return putMapEntry(_that);case RemoveMapEntryAction():
return removeMapEntry(_that);case ReplaceConcreteTypeAction():
return replaceConcreteType(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SetValueAction value)?  setValue,TResult? Function( InsertListItemAction value)?  insertListItem,TResult? Function( RemoveListItemAction value)?  removeListItem,TResult? Function( AppendListItemAction value)?  appendListItem,TResult? Function( DuplicateListItemAction value)?  duplicateListItem,TResult? Function( ReorderListItemAction value)?  reorderListItem,TResult? Function( PutMapEntryAction value)?  putMapEntry,TResult? Function( RemoveMapEntryAction value)?  removeMapEntry,TResult? Function( ReplaceConcreteTypeAction value)?  replaceConcreteType,}){
final _that = this;
switch (_that) {
case SetValueAction() when setValue != null:
return setValue(_that);case InsertListItemAction() when insertListItem != null:
return insertListItem(_that);case RemoveListItemAction() when removeListItem != null:
return removeListItem(_that);case AppendListItemAction() when appendListItem != null:
return appendListItem(_that);case DuplicateListItemAction() when duplicateListItem != null:
return duplicateListItem(_that);case ReorderListItemAction() when reorderListItem != null:
return reorderListItem(_that);case PutMapEntryAction() when putMapEntry != null:
return putMapEntry(_that);case RemoveMapEntryAction() when removeMapEntry != null:
return removeMapEntry(_that);case ReplaceConcreteTypeAction() when replaceConcreteType != null:
return replaceConcreteType(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BindingReference target,  TypedExpression value)?  setValue,TResult Function( BindingReference target,  TypedExpression index,  TypedExpression value)?  insertListItem,TResult Function( BindingReference target,  TypedExpression index)?  removeListItem,TResult Function( BindingReference target,  TypedExpression value)?  appendListItem,TResult Function( BindingReference source)?  duplicateListItem,TResult Function( BindingReference source,  TypedExpression newIndex)?  reorderListItem,TResult Function( BindingReference target,  TypedExpression key,  TypedExpression value)?  putMapEntry,TResult Function( BindingReference target,  TypedExpression key)?  removeMapEntry,TResult Function( BindingReference target,  ResolvedTypeRef concreteType,  TypedExpression initialValue)?  replaceConcreteType,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SetValueAction() when setValue != null:
return setValue(_that.target,_that.value);case InsertListItemAction() when insertListItem != null:
return insertListItem(_that.target,_that.index,_that.value);case RemoveListItemAction() when removeListItem != null:
return removeListItem(_that.target,_that.index);case AppendListItemAction() when appendListItem != null:
return appendListItem(_that.target,_that.value);case DuplicateListItemAction() when duplicateListItem != null:
return duplicateListItem(_that.source);case ReorderListItemAction() when reorderListItem != null:
return reorderListItem(_that.source,_that.newIndex);case PutMapEntryAction() when putMapEntry != null:
return putMapEntry(_that.target,_that.key,_that.value);case RemoveMapEntryAction() when removeMapEntry != null:
return removeMapEntry(_that.target,_that.key);case ReplaceConcreteTypeAction() when replaceConcreteType != null:
return replaceConcreteType(_that.target,_that.concreteType,_that.initialValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BindingReference target,  TypedExpression value)  setValue,required TResult Function( BindingReference target,  TypedExpression index,  TypedExpression value)  insertListItem,required TResult Function( BindingReference target,  TypedExpression index)  removeListItem,required TResult Function( BindingReference target,  TypedExpression value)  appendListItem,required TResult Function( BindingReference source)  duplicateListItem,required TResult Function( BindingReference source,  TypedExpression newIndex)  reorderListItem,required TResult Function( BindingReference target,  TypedExpression key,  TypedExpression value)  putMapEntry,required TResult Function( BindingReference target,  TypedExpression key)  removeMapEntry,required TResult Function( BindingReference target,  ResolvedTypeRef concreteType,  TypedExpression initialValue)  replaceConcreteType,}) {final _that = this;
switch (_that) {
case SetValueAction():
return setValue(_that.target,_that.value);case InsertListItemAction():
return insertListItem(_that.target,_that.index,_that.value);case RemoveListItemAction():
return removeListItem(_that.target,_that.index);case AppendListItemAction():
return appendListItem(_that.target,_that.value);case DuplicateListItemAction():
return duplicateListItem(_that.source);case ReorderListItemAction():
return reorderListItem(_that.source,_that.newIndex);case PutMapEntryAction():
return putMapEntry(_that.target,_that.key,_that.value);case RemoveMapEntryAction():
return removeMapEntry(_that.target,_that.key);case ReplaceConcreteTypeAction():
return replaceConcreteType(_that.target,_that.concreteType,_that.initialValue);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BindingReference target,  TypedExpression value)?  setValue,TResult? Function( BindingReference target,  TypedExpression index,  TypedExpression value)?  insertListItem,TResult? Function( BindingReference target,  TypedExpression index)?  removeListItem,TResult? Function( BindingReference target,  TypedExpression value)?  appendListItem,TResult? Function( BindingReference source)?  duplicateListItem,TResult? Function( BindingReference source,  TypedExpression newIndex)?  reorderListItem,TResult? Function( BindingReference target,  TypedExpression key,  TypedExpression value)?  putMapEntry,TResult? Function( BindingReference target,  TypedExpression key)?  removeMapEntry,TResult? Function( BindingReference target,  ResolvedTypeRef concreteType,  TypedExpression initialValue)?  replaceConcreteType,}) {final _that = this;
switch (_that) {
case SetValueAction() when setValue != null:
return setValue(_that.target,_that.value);case InsertListItemAction() when insertListItem != null:
return insertListItem(_that.target,_that.index,_that.value);case RemoveListItemAction() when removeListItem != null:
return removeListItem(_that.target,_that.index);case AppendListItemAction() when appendListItem != null:
return appendListItem(_that.target,_that.value);case DuplicateListItemAction() when duplicateListItem != null:
return duplicateListItem(_that.source);case ReorderListItemAction() when reorderListItem != null:
return reorderListItem(_that.source,_that.newIndex);case PutMapEntryAction() when putMapEntry != null:
return putMapEntry(_that.target,_that.key,_that.value);case RemoveMapEntryAction() when removeMapEntry != null:
return removeMapEntry(_that.target,_that.key);case ReplaceConcreteTypeAction() when replaceConcreteType != null:
return replaceConcreteType(_that.target,_that.concreteType,_that.initialValue);case _:
  return null;

}
}

}

/// @nodoc


class SetValueAction implements LocalAction {
  const SetValueAction({required this.target, required this.value});
  

 final  BindingReference target;
 final  TypedExpression value;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetValueActionCopyWith<SetValueAction> get copyWith => _$SetValueActionCopyWithImpl<SetValueAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetValueAction&&(identical(other.target, target) || other.target == target)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,target,value);

@override
String toString() {
  return 'LocalAction.setValue(target: $target, value: $value)';
}


}

/// @nodoc
abstract mixin class $SetValueActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $SetValueActionCopyWith(SetValueAction value, $Res Function(SetValueAction) _then) = _$SetValueActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression value
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$SetValueActionCopyWithImpl<$Res>
    implements $SetValueActionCopyWith<$Res> {
  _$SetValueActionCopyWithImpl(this._self, this._then);

  final SetValueAction _self;
  final $Res Function(SetValueAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? value = null,}) {
  return _then(SetValueAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class InsertListItemAction implements LocalAction {
  const InsertListItemAction({required this.target, required this.index, required this.value});
  

 final  BindingReference target;
 final  TypedExpression index;
 final  TypedExpression value;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsertListItemActionCopyWith<InsertListItemAction> get copyWith => _$InsertListItemActionCopyWithImpl<InsertListItemAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsertListItemAction&&(identical(other.target, target) || other.target == target)&&(identical(other.index, index) || other.index == index)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,target,index,value);

@override
String toString() {
  return 'LocalAction.insertListItem(target: $target, index: $index, value: $value)';
}


}

/// @nodoc
abstract mixin class $InsertListItemActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $InsertListItemActionCopyWith(InsertListItemAction value, $Res Function(InsertListItemAction) _then) = _$InsertListItemActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression index, TypedExpression value
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get index;$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$InsertListItemActionCopyWithImpl<$Res>
    implements $InsertListItemActionCopyWith<$Res> {
  _$InsertListItemActionCopyWithImpl(this._self, this._then);

  final InsertListItemAction _self;
  final $Res Function(InsertListItemAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? index = null,Object? value = null,}) {
  return _then(InsertListItemAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as TypedExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get index {
  
  return $TypedExpressionCopyWith<$Res>(_self.index, (value) {
    return _then(_self.copyWith(index: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class RemoveListItemAction implements LocalAction {
  const RemoveListItemAction({required this.target, required this.index});
  

 final  BindingReference target;
 final  TypedExpression index;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveListItemActionCopyWith<RemoveListItemAction> get copyWith => _$RemoveListItemActionCopyWithImpl<RemoveListItemAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveListItemAction&&(identical(other.target, target) || other.target == target)&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,target,index);

@override
String toString() {
  return 'LocalAction.removeListItem(target: $target, index: $index)';
}


}

/// @nodoc
abstract mixin class $RemoveListItemActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $RemoveListItemActionCopyWith(RemoveListItemAction value, $Res Function(RemoveListItemAction) _then) = _$RemoveListItemActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression index
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get index;

}
/// @nodoc
class _$RemoveListItemActionCopyWithImpl<$Res>
    implements $RemoveListItemActionCopyWith<$Res> {
  _$RemoveListItemActionCopyWithImpl(this._self, this._then);

  final RemoveListItemAction _self;
  final $Res Function(RemoveListItemAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? index = null,}) {
  return _then(RemoveListItemAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get index {
  
  return $TypedExpressionCopyWith<$Res>(_self.index, (value) {
    return _then(_self.copyWith(index: value));
  });
}
}

/// @nodoc


class AppendListItemAction implements LocalAction {
  const AppendListItemAction({required this.target, required this.value});
  

 final  BindingReference target;
 final  TypedExpression value;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppendListItemActionCopyWith<AppendListItemAction> get copyWith => _$AppendListItemActionCopyWithImpl<AppendListItemAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppendListItemAction&&(identical(other.target, target) || other.target == target)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,target,value);

@override
String toString() {
  return 'LocalAction.appendListItem(target: $target, value: $value)';
}


}

/// @nodoc
abstract mixin class $AppendListItemActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $AppendListItemActionCopyWith(AppendListItemAction value, $Res Function(AppendListItemAction) _then) = _$AppendListItemActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression value
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$AppendListItemActionCopyWithImpl<$Res>
    implements $AppendListItemActionCopyWith<$Res> {
  _$AppendListItemActionCopyWithImpl(this._self, this._then);

  final AppendListItemAction _self;
  final $Res Function(AppendListItemAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? value = null,}) {
  return _then(AppendListItemAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class DuplicateListItemAction implements LocalAction {
  const DuplicateListItemAction({required this.source});
  

 final  BindingReference source;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicateListItemActionCopyWith<DuplicateListItemAction> get copyWith => _$DuplicateListItemActionCopyWithImpl<DuplicateListItemAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicateListItemAction&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'LocalAction.duplicateListItem(source: $source)';
}


}

/// @nodoc
abstract mixin class $DuplicateListItemActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $DuplicateListItemActionCopyWith(DuplicateListItemAction value, $Res Function(DuplicateListItemAction) _then) = _$DuplicateListItemActionCopyWithImpl;
@useResult
$Res call({
 BindingReference source
});


$BindingReferenceCopyWith<$Res> get source;

}
/// @nodoc
class _$DuplicateListItemActionCopyWithImpl<$Res>
    implements $DuplicateListItemActionCopyWith<$Res> {
  _$DuplicateListItemActionCopyWithImpl(this._self, this._then);

  final DuplicateListItemAction _self;
  final $Res Function(DuplicateListItemAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(DuplicateListItemAction(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BindingReference,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get source {
  
  return $BindingReferenceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc


class ReorderListItemAction implements LocalAction {
  const ReorderListItemAction({required this.source, required this.newIndex});
  

 final  BindingReference source;
 final  TypedExpression newIndex;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderListItemActionCopyWith<ReorderListItemAction> get copyWith => _$ReorderListItemActionCopyWithImpl<ReorderListItemAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderListItemAction&&(identical(other.source, source) || other.source == source)&&(identical(other.newIndex, newIndex) || other.newIndex == newIndex));
}


@override
int get hashCode => Object.hash(runtimeType,source,newIndex);

@override
String toString() {
  return 'LocalAction.reorderListItem(source: $source, newIndex: $newIndex)';
}


}

/// @nodoc
abstract mixin class $ReorderListItemActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $ReorderListItemActionCopyWith(ReorderListItemAction value, $Res Function(ReorderListItemAction) _then) = _$ReorderListItemActionCopyWithImpl;
@useResult
$Res call({
 BindingReference source, TypedExpression newIndex
});


$BindingReferenceCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res> get newIndex;

}
/// @nodoc
class _$ReorderListItemActionCopyWithImpl<$Res>
    implements $ReorderListItemActionCopyWith<$Res> {
  _$ReorderListItemActionCopyWithImpl(this._self, this._then);

  final ReorderListItemAction _self;
  final $Res Function(ReorderListItemAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? newIndex = null,}) {
  return _then(ReorderListItemAction(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BindingReference,newIndex: null == newIndex ? _self.newIndex : newIndex // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get source {
  
  return $BindingReferenceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get newIndex {
  
  return $TypedExpressionCopyWith<$Res>(_self.newIndex, (value) {
    return _then(_self.copyWith(newIndex: value));
  });
}
}

/// @nodoc


class PutMapEntryAction implements LocalAction {
  const PutMapEntryAction({required this.target, required this.key, required this.value});
  

 final  BindingReference target;
 final  TypedExpression key;
 final  TypedExpression value;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PutMapEntryActionCopyWith<PutMapEntryAction> get copyWith => _$PutMapEntryActionCopyWithImpl<PutMapEntryAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PutMapEntryAction&&(identical(other.target, target) || other.target == target)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,target,key,value);

@override
String toString() {
  return 'LocalAction.putMapEntry(target: $target, key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $PutMapEntryActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $PutMapEntryActionCopyWith(PutMapEntryAction value, $Res Function(PutMapEntryAction) _then) = _$PutMapEntryActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression key, TypedExpression value
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get key;$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$PutMapEntryActionCopyWithImpl<$Res>
    implements $PutMapEntryActionCopyWith<$Res> {
  _$PutMapEntryActionCopyWithImpl(this._self, this._then);

  final PutMapEntryAction _self;
  final $Res Function(PutMapEntryAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? key = null,Object? value = null,}) {
  return _then(PutMapEntryAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class RemoveMapEntryAction implements LocalAction {
  const RemoveMapEntryAction({required this.target, required this.key});
  

 final  BindingReference target;
 final  TypedExpression key;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveMapEntryActionCopyWith<RemoveMapEntryAction> get copyWith => _$RemoveMapEntryActionCopyWithImpl<RemoveMapEntryAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveMapEntryAction&&(identical(other.target, target) || other.target == target)&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,target,key);

@override
String toString() {
  return 'LocalAction.removeMapEntry(target: $target, key: $key)';
}


}

/// @nodoc
abstract mixin class $RemoveMapEntryActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $RemoveMapEntryActionCopyWith(RemoveMapEntryAction value, $Res Function(RemoveMapEntryAction) _then) = _$RemoveMapEntryActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, TypedExpression key
});


$BindingReferenceCopyWith<$Res> get target;$TypedExpressionCopyWith<$Res> get key;

}
/// @nodoc
class _$RemoveMapEntryActionCopyWithImpl<$Res>
    implements $RemoveMapEntryActionCopyWith<$Res> {
  _$RemoveMapEntryActionCopyWithImpl(this._self, this._then);

  final RemoveMapEntryAction _self;
  final $Res Function(RemoveMapEntryAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? key = null,}) {
  return _then(RemoveMapEntryAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}

/// @nodoc


class ReplaceConcreteTypeAction implements LocalAction {
  const ReplaceConcreteTypeAction({required this.target, required this.concreteType, required this.initialValue});
  

 final  BindingReference target;
 final  ResolvedTypeRef concreteType;
 final  TypedExpression initialValue;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplaceConcreteTypeActionCopyWith<ReplaceConcreteTypeAction> get copyWith => _$ReplaceConcreteTypeActionCopyWithImpl<ReplaceConcreteTypeAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReplaceConcreteTypeAction&&(identical(other.target, target) || other.target == target)&&(identical(other.concreteType, concreteType) || other.concreteType == concreteType)&&(identical(other.initialValue, initialValue) || other.initialValue == initialValue));
}


@override
int get hashCode => Object.hash(runtimeType,target,concreteType,initialValue);

@override
String toString() {
  return 'LocalAction.replaceConcreteType(target: $target, concreteType: $concreteType, initialValue: $initialValue)';
}


}

/// @nodoc
abstract mixin class $ReplaceConcreteTypeActionCopyWith<$Res> implements $LocalActionCopyWith<$Res> {
  factory $ReplaceConcreteTypeActionCopyWith(ReplaceConcreteTypeAction value, $Res Function(ReplaceConcreteTypeAction) _then) = _$ReplaceConcreteTypeActionCopyWithImpl;
@useResult
$Res call({
 BindingReference target, ResolvedTypeRef concreteType, TypedExpression initialValue
});


$BindingReferenceCopyWith<$Res> get target;$ResolvedTypeRefCopyWith<$Res> get concreteType;$TypedExpressionCopyWith<$Res> get initialValue;

}
/// @nodoc
class _$ReplaceConcreteTypeActionCopyWithImpl<$Res>
    implements $ReplaceConcreteTypeActionCopyWith<$Res> {
  _$ReplaceConcreteTypeActionCopyWithImpl(this._self, this._then);

  final ReplaceConcreteTypeAction _self;
  final $Res Function(ReplaceConcreteTypeAction) _then;

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? concreteType = null,Object? initialValue = null,}) {
  return _then(ReplaceConcreteTypeAction(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BindingReference,concreteType: null == concreteType ? _self.concreteType : concreteType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,initialValue: null == initialValue ? _self.initialValue : initialValue // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get target {
  
  return $BindingReferenceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get concreteType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.concreteType, (value) {
    return _then(_self.copyWith(concreteType: value));
  });
}/// Create a copy of LocalAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get initialValue {
  
  return $TypedExpressionCopyWith<$Res>(_self.initialValue, (value) {
    return _then(_self.copyWith(initialValue: value));
  });
}
}

/// @nodoc
mixin _$RealmAction {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RealmAction()';
}


}

/// @nodoc
class $RealmActionCopyWith<$Res>  {
$RealmActionCopyWith(RealmAction _, $Res Function(RealmAction) __);
}


/// Adds pattern-matching-related methods to [RealmAction].
extension RealmActionPatterns on RealmAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReloadRealmAction value)?  reload,TResult Function( InvokeRealmCommandAction value)?  invokeCommand,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReloadRealmAction() when reload != null:
return reload(_that);case InvokeRealmCommandAction() when invokeCommand != null:
return invokeCommand(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReloadRealmAction value)  reload,required TResult Function( InvokeRealmCommandAction value)  invokeCommand,}){
final _that = this;
switch (_that) {
case ReloadRealmAction():
return reload(_that);case InvokeRealmCommandAction():
return invokeCommand(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReloadRealmAction value)?  reload,TResult? Function( InvokeRealmCommandAction value)?  invokeCommand,}){
final _that = this;
switch (_that) {
case ReloadRealmAction() when reload != null:
return reload(_that);case InvokeRealmCommandAction() when invokeCommand != null:
return invokeCommand(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  reload,TResult Function( CapabilityId capabilityId,  TypedExpression payload)?  invokeCommand,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReloadRealmAction() when reload != null:
return reload();case InvokeRealmCommandAction() when invokeCommand != null:
return invokeCommand(_that.capabilityId,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  reload,required TResult Function( CapabilityId capabilityId,  TypedExpression payload)  invokeCommand,}) {final _that = this;
switch (_that) {
case ReloadRealmAction():
return reload();case InvokeRealmCommandAction():
return invokeCommand(_that.capabilityId,_that.payload);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  reload,TResult? Function( CapabilityId capabilityId,  TypedExpression payload)?  invokeCommand,}) {final _that = this;
switch (_that) {
case ReloadRealmAction() when reload != null:
return reload();case InvokeRealmCommandAction() when invokeCommand != null:
return invokeCommand(_that.capabilityId,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class ReloadRealmAction implements RealmAction {
  const ReloadRealmAction();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReloadRealmAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RealmAction.reload()';
}


}




/// @nodoc


class InvokeRealmCommandAction implements RealmAction {
  const InvokeRealmCommandAction({required this.capabilityId, required this.payload});
  

 final  CapabilityId capabilityId;
 final  TypedExpression payload;

/// Create a copy of RealmAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvokeRealmCommandActionCopyWith<InvokeRealmCommandAction> get copyWith => _$InvokeRealmCommandActionCopyWithImpl<InvokeRealmCommandAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvokeRealmCommandAction&&(identical(other.capabilityId, capabilityId) || other.capabilityId == capabilityId)&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,capabilityId,payload);

@override
String toString() {
  return 'RealmAction.invokeCommand(capabilityId: $capabilityId, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $InvokeRealmCommandActionCopyWith<$Res> implements $RealmActionCopyWith<$Res> {
  factory $InvokeRealmCommandActionCopyWith(InvokeRealmCommandAction value, $Res Function(InvokeRealmCommandAction) _then) = _$InvokeRealmCommandActionCopyWithImpl;
@useResult
$Res call({
 CapabilityId capabilityId, TypedExpression payload
});


$CapabilityIdCopyWith<$Res> get capabilityId;$TypedExpressionCopyWith<$Res> get payload;

}
/// @nodoc
class _$InvokeRealmCommandActionCopyWithImpl<$Res>
    implements $InvokeRealmCommandActionCopyWith<$Res> {
  _$InvokeRealmCommandActionCopyWithImpl(this._self, this._then);

  final InvokeRealmCommandAction _self;
  final $Res Function(InvokeRealmCommandAction) _then;

/// Create a copy of RealmAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? capabilityId = null,Object? payload = null,}) {
  return _then(InvokeRealmCommandAction(
capabilityId: null == capabilityId ? _self.capabilityId : capabilityId // ignore: cast_nullable_to_non_nullable
as CapabilityId,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of RealmAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<$Res> get capabilityId {
  
  return $CapabilityIdCopyWith<$Res>(_self.capabilityId, (value) {
    return _then(_self.copyWith(capabilityId: value));
  });
}/// Create a copy of RealmAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get payload {
  
  return $TypedExpressionCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc
mixin _$TypedMutationResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedMutationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypedMutationResult()';
}


}

/// @nodoc
class $TypedMutationResultCopyWith<$Res>  {
$TypedMutationResultCopyWith(TypedMutationResult _, $Res Function(TypedMutationResult) __);
}


/// Adds pattern-matching-related methods to [TypedMutationResult].
extension TypedMutationResultPatterns on TypedMutationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MutationSuccess value)?  success,TResult Function( MutationConflict value)?  conflict,TResult Function( MutationInvalid value)?  invalid,TResult Function( MutationPermissionDenied value)?  permissionDenied,TResult Function( MutationUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that);case MutationConflict() when conflict != null:
return conflict(_that);case MutationInvalid() when invalid != null:
return invalid(_that);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case MutationUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MutationSuccess value)  success,required TResult Function( MutationConflict value)  conflict,required TResult Function( MutationInvalid value)  invalid,required TResult Function( MutationPermissionDenied value)  permissionDenied,required TResult Function( MutationUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case MutationSuccess():
return success(_that);case MutationConflict():
return conflict(_that);case MutationInvalid():
return invalid(_that);case MutationPermissionDenied():
return permissionDenied(_that);case MutationUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MutationSuccess value)?  success,TResult? Function( MutationConflict value)?  conflict,TResult? Function( MutationInvalid value)?  invalid,TResult? Function( MutationPermissionDenied value)?  permissionDenied,TResult? Function( MutationUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that);case MutationConflict() when conflict != null:
return conflict(_that);case MutationInvalid() when invalid != null:
return invalid(_that);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case MutationUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int revision,  DataValue value)?  success,TResult Function( int expectedRevision,  int actualRevision,  DataValue actualValue)?  conflict,TResult Function( List<TypeDiagnostic> diagnostics)?  invalid,TResult Function( String message)?  permissionDenied,TResult Function( List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that.revision,_that.value);case MutationConflict() when conflict != null:
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid() when invalid != null:
return invalid(_that.diagnostics);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.message);case MutationUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int revision,  DataValue value)  success,required TResult Function( int expectedRevision,  int actualRevision,  DataValue actualValue)  conflict,required TResult Function( List<TypeDiagnostic> diagnostics)  invalid,required TResult Function( String message)  permissionDenied,required TResult Function( List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case MutationSuccess():
return success(_that.revision,_that.value);case MutationConflict():
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid():
return invalid(_that.diagnostics);case MutationPermissionDenied():
return permissionDenied(_that.message);case MutationUnavailable():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int revision,  DataValue value)?  success,TResult? Function( int expectedRevision,  int actualRevision,  DataValue actualValue)?  conflict,TResult? Function( List<TypeDiagnostic> diagnostics)?  invalid,TResult? Function( String message)?  permissionDenied,TResult? Function( List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that.revision,_that.value);case MutationConflict() when conflict != null:
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid() when invalid != null:
return invalid(_that.diagnostics);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.message);case MutationUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class MutationSuccess implements TypedMutationResult {
  const MutationSuccess({required this.revision, required this.value}): assert(revision >= 0, 'Revision must not be negative.');
  

 final  int revision;
 final  DataValue value;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationSuccessCopyWith<MutationSuccess> get copyWith => _$MutationSuccessCopyWithImpl<MutationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationSuccess&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,revision,value);

@override
String toString() {
  return 'TypedMutationResult.success(revision: $revision, value: $value)';
}


}

/// @nodoc
abstract mixin class $MutationSuccessCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationSuccessCopyWith(MutationSuccess value, $Res Function(MutationSuccess) _then) = _$MutationSuccessCopyWithImpl;
@useResult
$Res call({
 int revision, DataValue value
});


$DataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$MutationSuccessCopyWithImpl<$Res>
    implements $MutationSuccessCopyWith<$Res> {
  _$MutationSuccessCopyWithImpl(this._self, this._then);

  final MutationSuccess _self;
  final $Res Function(MutationSuccess) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? revision = null,Object? value = null,}) {
  return _then(MutationSuccess(
revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of TypedMutationResult
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


class MutationConflict implements TypedMutationResult {
  const MutationConflict({required this.expectedRevision, required this.actualRevision, required this.actualValue});
  

 final  int expectedRevision;
 final  int actualRevision;
 final  DataValue actualValue;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationConflictCopyWith<MutationConflict> get copyWith => _$MutationConflictCopyWithImpl<MutationConflict>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationConflict&&(identical(other.expectedRevision, expectedRevision) || other.expectedRevision == expectedRevision)&&(identical(other.actualRevision, actualRevision) || other.actualRevision == actualRevision)&&(identical(other.actualValue, actualValue) || other.actualValue == actualValue));
}


@override
int get hashCode => Object.hash(runtimeType,expectedRevision,actualRevision,actualValue);

@override
String toString() {
  return 'TypedMutationResult.conflict(expectedRevision: $expectedRevision, actualRevision: $actualRevision, actualValue: $actualValue)';
}


}

/// @nodoc
abstract mixin class $MutationConflictCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationConflictCopyWith(MutationConflict value, $Res Function(MutationConflict) _then) = _$MutationConflictCopyWithImpl;
@useResult
$Res call({
 int expectedRevision, int actualRevision, DataValue actualValue
});


$DataValueCopyWith<$Res> get actualValue;

}
/// @nodoc
class _$MutationConflictCopyWithImpl<$Res>
    implements $MutationConflictCopyWith<$Res> {
  _$MutationConflictCopyWithImpl(this._self, this._then);

  final MutationConflict _self;
  final $Res Function(MutationConflict) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expectedRevision = null,Object? actualRevision = null,Object? actualValue = null,}) {
  return _then(MutationConflict(
expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,actualRevision: null == actualRevision ? _self.actualRevision : actualRevision // ignore: cast_nullable_to_non_nullable
as int,actualValue: null == actualValue ? _self.actualValue : actualValue // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get actualValue {
  
  return $DataValueCopyWith<$Res>(_self.actualValue, (value) {
    return _then(_self.copyWith(actualValue: value));
  });
}
}

/// @nodoc


class MutationInvalid implements TypedMutationResult {
   MutationInvalid(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationInvalidCopyWith<MutationInvalid> get copyWith => _$MutationInvalidCopyWithImpl<MutationInvalid>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationInvalid&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'TypedMutationResult.invalid(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $MutationInvalidCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationInvalidCopyWith(MutationInvalid value, $Res Function(MutationInvalid) _then) = _$MutationInvalidCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$MutationInvalidCopyWithImpl<$Res>
    implements $MutationInvalidCopyWith<$Res> {
  _$MutationInvalidCopyWithImpl(this._self, this._then);

  final MutationInvalid _self;
  final $Res Function(MutationInvalid) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(MutationInvalid(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class MutationPermissionDenied implements TypedMutationResult {
  const MutationPermissionDenied(this.message);
  

 final  String message;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationPermissionDeniedCopyWith<MutationPermissionDenied> get copyWith => _$MutationPermissionDeniedCopyWithImpl<MutationPermissionDenied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationPermissionDenied&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TypedMutationResult.permissionDenied(message: $message)';
}


}

/// @nodoc
abstract mixin class $MutationPermissionDeniedCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationPermissionDeniedCopyWith(MutationPermissionDenied value, $Res Function(MutationPermissionDenied) _then) = _$MutationPermissionDeniedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$MutationPermissionDeniedCopyWithImpl<$Res>
    implements $MutationPermissionDeniedCopyWith<$Res> {
  _$MutationPermissionDeniedCopyWithImpl(this._self, this._then);

  final MutationPermissionDenied _self;
  final $Res Function(MutationPermissionDenied) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(MutationPermissionDenied(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MutationUnavailable implements TypedMutationResult {
   MutationUnavailable(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationUnavailableCopyWith<MutationUnavailable> get copyWith => _$MutationUnavailableCopyWithImpl<MutationUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'TypedMutationResult.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $MutationUnavailableCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationUnavailableCopyWith(MutationUnavailable value, $Res Function(MutationUnavailable) _then) = _$MutationUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$MutationUnavailableCopyWithImpl<$Res>
    implements $MutationUnavailableCopyWith<$Res> {
  _$MutationUnavailableCopyWithImpl(this._self, this._then);

  final MutationUnavailable _self;
  final $Res Function(MutationUnavailable) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(MutationUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
