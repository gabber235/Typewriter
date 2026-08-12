// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_header.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HeaderActionId {

 String get namespace; String get name;
/// Create a copy of HeaderActionId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderActionIdCopyWith<HeaderActionId> get copyWith => _$HeaderActionIdCopyWithImpl<HeaderActionId>(this as HeaderActionId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderActionId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'HeaderActionId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class $HeaderActionIdCopyWith<$Res>  {
  factory $HeaderActionIdCopyWith(HeaderActionId value, $Res Function(HeaderActionId) _then) = _$HeaderActionIdCopyWithImpl;
@useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class _$HeaderActionIdCopyWithImpl<$Res>
    implements $HeaderActionIdCopyWith<$Res> {
  _$HeaderActionIdCopyWithImpl(this._self, this._then);

  final HeaderActionId _self;
  final $Res Function(HeaderActionId) _then;

/// Create a copy of HeaderActionId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_self.copyWith(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HeaderActionId].
extension HeaderActionIdPatterns on HeaderActionId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeaderActionId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeaderActionId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeaderActionId value)  $default,){
final _that = this;
switch (_that) {
case _HeaderActionId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeaderActionId value)?  $default,){
final _that = this;
switch (_that) {
case _HeaderActionId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String namespace,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeaderActionId() when $default != null:
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String namespace,  String name)  $default,) {final _that = this;
switch (_that) {
case _HeaderActionId():
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String namespace,  String name)?  $default,) {final _that = this;
switch (_that) {
case _HeaderActionId() when $default != null:
return $default(_that.namespace,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _HeaderActionId extends HeaderActionId {
  const _HeaderActionId({required this.namespace, required this.name}): assert(namespace != "", 'Header action namespace must not be empty.'),assert(name != "", 'Header action name must not be empty.'),super._();
  

@override final  String namespace;
@override final  String name;

/// Create a copy of HeaderActionId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeaderActionIdCopyWith<_HeaderActionId> get copyWith => __$HeaderActionIdCopyWithImpl<_HeaderActionId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeaderActionId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'HeaderActionId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class _$HeaderActionIdCopyWith<$Res> implements $HeaderActionIdCopyWith<$Res> {
  factory _$HeaderActionIdCopyWith(_HeaderActionId value, $Res Function(_HeaderActionId) _then) = __$HeaderActionIdCopyWithImpl;
@override @useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class __$HeaderActionIdCopyWithImpl<$Res>
    implements _$HeaderActionIdCopyWith<$Res> {
  __$HeaderActionIdCopyWithImpl(this._self, this._then);

  final _HeaderActionId _self;
  final $Res Function(_HeaderActionId) _then;

/// Create a copy of HeaderActionId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_HeaderActionId(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$HeaderActionActivation {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderActionActivation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HeaderActionActivation()';
}


}

/// @nodoc
class $HeaderActionActivationCopyWith<$Res>  {
$HeaderActionActivationCopyWith(HeaderActionActivation _, $Res Function(HeaderActionActivation) __);
}


/// Adds pattern-matching-related methods to [HeaderActionActivation].
extension HeaderActionActivationPatterns on HeaderActionActivation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvokeHeaderAction value)?  invoke,TResult Function( ReorderListItemHeaderAction value)?  reorderListItem,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvokeHeaderAction() when invoke != null:
return invoke(_that);case ReorderListItemHeaderAction() when reorderListItem != null:
return reorderListItem(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvokeHeaderAction value)  invoke,required TResult Function( ReorderListItemHeaderAction value)  reorderListItem,}){
final _that = this;
switch (_that) {
case InvokeHeaderAction():
return invoke(_that);case ReorderListItemHeaderAction():
return reorderListItem(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvokeHeaderAction value)?  invoke,TResult? Function( ReorderListItemHeaderAction value)?  reorderListItem,}){
final _that = this;
switch (_that) {
case InvokeHeaderAction() when invoke != null:
return invoke(_that);case ReorderListItemHeaderAction() when reorderListItem != null:
return reorderListItem(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EditorAction action)?  invoke,TResult Function( BindingReference source)?  reorderListItem,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvokeHeaderAction() when invoke != null:
return invoke(_that.action);case ReorderListItemHeaderAction() when reorderListItem != null:
return reorderListItem(_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EditorAction action)  invoke,required TResult Function( BindingReference source)  reorderListItem,}) {final _that = this;
switch (_that) {
case InvokeHeaderAction():
return invoke(_that.action);case ReorderListItemHeaderAction():
return reorderListItem(_that.source);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EditorAction action)?  invoke,TResult? Function( BindingReference source)?  reorderListItem,}) {final _that = this;
switch (_that) {
case InvokeHeaderAction() when invoke != null:
return invoke(_that.action);case ReorderListItemHeaderAction() when reorderListItem != null:
return reorderListItem(_that.source);case _:
  return null;

}
}

}

/// @nodoc


class InvokeHeaderAction implements HeaderActionActivation {
  const InvokeHeaderAction(this.action);
  

 final  EditorAction action;

/// Create a copy of HeaderActionActivation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvokeHeaderActionCopyWith<InvokeHeaderAction> get copyWith => _$InvokeHeaderActionCopyWithImpl<InvokeHeaderAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvokeHeaderAction&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'HeaderActionActivation.invoke(action: $action)';
}


}

/// @nodoc
abstract mixin class $InvokeHeaderActionCopyWith<$Res> implements $HeaderActionActivationCopyWith<$Res> {
  factory $InvokeHeaderActionCopyWith(InvokeHeaderAction value, $Res Function(InvokeHeaderAction) _then) = _$InvokeHeaderActionCopyWithImpl;
@useResult
$Res call({
 EditorAction action
});


$EditorActionCopyWith<$Res> get action;

}
/// @nodoc
class _$InvokeHeaderActionCopyWithImpl<$Res>
    implements $InvokeHeaderActionCopyWith<$Res> {
  _$InvokeHeaderActionCopyWithImpl(this._self, this._then);

  final InvokeHeaderAction _self;
  final $Res Function(InvokeHeaderAction) _then;

/// Create a copy of HeaderActionActivation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(InvokeHeaderAction(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,
  ));
}

/// Create a copy of HeaderActionActivation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class ReorderListItemHeaderAction implements HeaderActionActivation {
  const ReorderListItemHeaderAction({required this.source});
  

 final  BindingReference source;

/// Create a copy of HeaderActionActivation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderListItemHeaderActionCopyWith<ReorderListItemHeaderAction> get copyWith => _$ReorderListItemHeaderActionCopyWithImpl<ReorderListItemHeaderAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderListItemHeaderAction&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'HeaderActionActivation.reorderListItem(source: $source)';
}


}

/// @nodoc
abstract mixin class $ReorderListItemHeaderActionCopyWith<$Res> implements $HeaderActionActivationCopyWith<$Res> {
  factory $ReorderListItemHeaderActionCopyWith(ReorderListItemHeaderAction value, $Res Function(ReorderListItemHeaderAction) _then) = _$ReorderListItemHeaderActionCopyWithImpl;
@useResult
$Res call({
 BindingReference source
});


$BindingReferenceCopyWith<$Res> get source;

}
/// @nodoc
class _$ReorderListItemHeaderActionCopyWithImpl<$Res>
    implements $ReorderListItemHeaderActionCopyWith<$Res> {
  _$ReorderListItemHeaderActionCopyWithImpl(this._self, this._then);

  final ReorderListItemHeaderAction _self;
  final $Res Function(ReorderListItemHeaderAction) _then;

/// Create a copy of HeaderActionActivation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(ReorderListItemHeaderAction(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BindingReference,
  ));
}

/// Create a copy of HeaderActionActivation
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
mixin _$HeaderActionConfirmation {

 TypedExpression get title; TypedExpression get message; TypedExpression get confirmationLabel;
/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderActionConfirmationCopyWith<HeaderActionConfirmation> get copyWith => _$HeaderActionConfirmationCopyWithImpl<HeaderActionConfirmation>(this as HeaderActionConfirmation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderActionConfirmation&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.confirmationLabel, confirmationLabel) || other.confirmationLabel == confirmationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,title,message,confirmationLabel);

@override
String toString() {
  return 'HeaderActionConfirmation(title: $title, message: $message, confirmationLabel: $confirmationLabel)';
}


}

/// @nodoc
abstract mixin class $HeaderActionConfirmationCopyWith<$Res>  {
  factory $HeaderActionConfirmationCopyWith(HeaderActionConfirmation value, $Res Function(HeaderActionConfirmation) _then) = _$HeaderActionConfirmationCopyWithImpl;
@useResult
$Res call({
 TypedExpression title, TypedExpression message, TypedExpression confirmationLabel
});


$TypedExpressionCopyWith<$Res> get title;$TypedExpressionCopyWith<$Res> get message;$TypedExpressionCopyWith<$Res> get confirmationLabel;

}
/// @nodoc
class _$HeaderActionConfirmationCopyWithImpl<$Res>
    implements $HeaderActionConfirmationCopyWith<$Res> {
  _$HeaderActionConfirmationCopyWithImpl(this._self, this._then);

  final HeaderActionConfirmation _self;
  final $Res Function(HeaderActionConfirmation) _then;

/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? message = null,Object? confirmationLabel = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as TypedExpression,confirmationLabel: null == confirmationLabel ? _self.confirmationLabel : confirmationLabel // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}
/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get title {
  
  return $TypedExpressionCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get message {
  
  return $TypedExpressionCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get confirmationLabel {
  
  return $TypedExpressionCopyWith<$Res>(_self.confirmationLabel, (value) {
    return _then(_self.copyWith(confirmationLabel: value));
  });
}
}


/// Adds pattern-matching-related methods to [HeaderActionConfirmation].
extension HeaderActionConfirmationPatterns on HeaderActionConfirmation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeaderActionConfirmation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeaderActionConfirmation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeaderActionConfirmation value)  $default,){
final _that = this;
switch (_that) {
case _HeaderActionConfirmation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeaderActionConfirmation value)?  $default,){
final _that = this;
switch (_that) {
case _HeaderActionConfirmation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypedExpression title,  TypedExpression message,  TypedExpression confirmationLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeaderActionConfirmation() when $default != null:
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypedExpression title,  TypedExpression message,  TypedExpression confirmationLabel)  $default,) {final _that = this;
switch (_that) {
case _HeaderActionConfirmation():
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypedExpression title,  TypedExpression message,  TypedExpression confirmationLabel)?  $default,) {final _that = this;
switch (_that) {
case _HeaderActionConfirmation() when $default != null:
return $default(_that.title,_that.message,_that.confirmationLabel);case _:
  return null;

}
}

}

/// @nodoc


class _HeaderActionConfirmation implements HeaderActionConfirmation {
  const _HeaderActionConfirmation({required this.title, required this.message, required this.confirmationLabel});
  

@override final  TypedExpression title;
@override final  TypedExpression message;
@override final  TypedExpression confirmationLabel;

/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeaderActionConfirmationCopyWith<_HeaderActionConfirmation> get copyWith => __$HeaderActionConfirmationCopyWithImpl<_HeaderActionConfirmation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeaderActionConfirmation&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.confirmationLabel, confirmationLabel) || other.confirmationLabel == confirmationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,title,message,confirmationLabel);

@override
String toString() {
  return 'HeaderActionConfirmation(title: $title, message: $message, confirmationLabel: $confirmationLabel)';
}


}

/// @nodoc
abstract mixin class _$HeaderActionConfirmationCopyWith<$Res> implements $HeaderActionConfirmationCopyWith<$Res> {
  factory _$HeaderActionConfirmationCopyWith(_HeaderActionConfirmation value, $Res Function(_HeaderActionConfirmation) _then) = __$HeaderActionConfirmationCopyWithImpl;
@override @useResult
$Res call({
 TypedExpression title, TypedExpression message, TypedExpression confirmationLabel
});


@override $TypedExpressionCopyWith<$Res> get title;@override $TypedExpressionCopyWith<$Res> get message;@override $TypedExpressionCopyWith<$Res> get confirmationLabel;

}
/// @nodoc
class __$HeaderActionConfirmationCopyWithImpl<$Res>
    implements _$HeaderActionConfirmationCopyWith<$Res> {
  __$HeaderActionConfirmationCopyWithImpl(this._self, this._then);

  final _HeaderActionConfirmation _self;
  final $Res Function(_HeaderActionConfirmation) _then;

/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? message = null,Object? confirmationLabel = null,}) {
  return _then(_HeaderActionConfirmation(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as TypedExpression,confirmationLabel: null == confirmationLabel ? _self.confirmationLabel : confirmationLabel // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get title {
  
  return $TypedExpressionCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get message {
  
  return $TypedExpressionCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of HeaderActionConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get confirmationLabel {
  
  return $TypedExpressionCopyWith<$Res>(_self.confirmationLabel, (value) {
    return _then(_self.copyWith(confirmationLabel: value));
  });
}
}

/// @nodoc
mixin _$EditorHeaderAction {

 HeaderActionId get id; TypedExpression get icon; TypedExpression get label; HeaderActionActivation get activation; TypedExpression? get tooltip; TypedExpression? get priority; TypedExpression? get visibleIf; TypedExpression? get enabledIf; HeaderActionPlacement get placement; HeaderActionTone get tone; HeaderActionConfirmation? get confirmation;
/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorHeaderActionCopyWith<EditorHeaderAction> get copyWith => _$EditorHeaderActionCopyWithImpl<EditorHeaderAction>(this as EditorHeaderAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorHeaderAction&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,activation,tooltip,priority,visibleIf,enabledIf,placement,tone,confirmation);

@override
String toString() {
  return 'EditorHeaderAction(id: $id, icon: $icon, label: $label, activation: $activation, tooltip: $tooltip, priority: $priority, visibleIf: $visibleIf, enabledIf: $enabledIf, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class $EditorHeaderActionCopyWith<$Res>  {
  factory $EditorHeaderActionCopyWith(EditorHeaderAction value, $Res Function(EditorHeaderAction) _then) = _$EditorHeaderActionCopyWithImpl;
@useResult
$Res call({
 HeaderActionId id, TypedExpression icon, TypedExpression label, HeaderActionActivation activation, TypedExpression? tooltip, TypedExpression? priority, TypedExpression? visibleIf, TypedExpression? enabledIf, HeaderActionPlacement placement, HeaderActionTone tone, HeaderActionConfirmation? confirmation
});


$HeaderActionIdCopyWith<$Res> get id;$TypedExpressionCopyWith<$Res> get icon;$TypedExpressionCopyWith<$Res> get label;$HeaderActionActivationCopyWith<$Res> get activation;$TypedExpressionCopyWith<$Res>? get tooltip;$TypedExpressionCopyWith<$Res>? get priority;$TypedExpressionCopyWith<$Res>? get visibleIf;$TypedExpressionCopyWith<$Res>? get enabledIf;$HeaderActionConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class _$EditorHeaderActionCopyWithImpl<$Res>
    implements $EditorHeaderActionCopyWith<$Res> {
  _$EditorHeaderActionCopyWithImpl(this._self, this._then);

  final EditorHeaderAction _self;
  final $Res Function(EditorHeaderAction) _then;

/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? activation = null,Object? tooltip = freezed,Object? priority = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderActionId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as TypedExpression,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as HeaderActionActivation,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as HeaderActionConfirmation?,
  ));
}
/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionIdCopyWith<$Res> get id {
  
  return $HeaderActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get icon {
  
  return $TypedExpressionCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionActivationCopyWith<$Res> get activation {
  
  return $HeaderActionActivationCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get tooltip {
    if (_self.tooltip == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.tooltip!, (value) {
    return _then(_self.copyWith(tooltip: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get priority {
    if (_self.priority == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.priority!, (value) {
    return _then(_self.copyWith(priority: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get visibleIf {
    if (_self.visibleIf == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.visibleIf!, (value) {
    return _then(_self.copyWith(visibleIf: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get enabledIf {
    if (_self.enabledIf == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.enabledIf!, (value) {
    return _then(_self.copyWith(enabledIf: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionConfirmationCopyWith<$Res>? get confirmation {
    if (_self.confirmation == null) {
    return null;
  }

  return $HeaderActionConfirmationCopyWith<$Res>(_self.confirmation!, (value) {
    return _then(_self.copyWith(confirmation: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorHeaderAction].
extension EditorHeaderActionPatterns on EditorHeaderAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorHeaderAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorHeaderAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorHeaderAction value)  $default,){
final _that = this;
switch (_that) {
case _EditorHeaderAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorHeaderAction value)?  $default,){
final _that = this;
switch (_that) {
case _EditorHeaderAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HeaderActionId id,  TypedExpression icon,  TypedExpression label,  HeaderActionActivation activation,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorHeaderAction() when $default != null:
return $default(_that.id,_that.icon,_that.label,_that.activation,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HeaderActionId id,  TypedExpression icon,  TypedExpression label,  HeaderActionActivation activation,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)  $default,) {final _that = this;
switch (_that) {
case _EditorHeaderAction():
return $default(_that.id,_that.icon,_that.label,_that.activation,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HeaderActionId id,  TypedExpression icon,  TypedExpression label,  HeaderActionActivation activation,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)?  $default,) {final _that = this;
switch (_that) {
case _EditorHeaderAction() when $default != null:
return $default(_that.id,_that.icon,_that.label,_that.activation,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case _:
  return null;

}
}

}

/// @nodoc


class _EditorHeaderAction implements EditorHeaderAction {
  const _EditorHeaderAction({required this.id, required this.icon, required this.label, required this.activation, this.tooltip, this.priority, this.visibleIf, this.enabledIf, this.placement = HeaderActionPlacement.end, this.tone = HeaderActionTone.neutral, this.confirmation});
  

@override final  HeaderActionId id;
@override final  TypedExpression icon;
@override final  TypedExpression label;
@override final  HeaderActionActivation activation;
@override final  TypedExpression? tooltip;
@override final  TypedExpression? priority;
@override final  TypedExpression? visibleIf;
@override final  TypedExpression? enabledIf;
@override@JsonKey() final  HeaderActionPlacement placement;
@override@JsonKey() final  HeaderActionTone tone;
@override final  HeaderActionConfirmation? confirmation;

/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorHeaderActionCopyWith<_EditorHeaderAction> get copyWith => __$EditorHeaderActionCopyWithImpl<_EditorHeaderAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorHeaderAction&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,activation,tooltip,priority,visibleIf,enabledIf,placement,tone,confirmation);

@override
String toString() {
  return 'EditorHeaderAction(id: $id, icon: $icon, label: $label, activation: $activation, tooltip: $tooltip, priority: $priority, visibleIf: $visibleIf, enabledIf: $enabledIf, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class _$EditorHeaderActionCopyWith<$Res> implements $EditorHeaderActionCopyWith<$Res> {
  factory _$EditorHeaderActionCopyWith(_EditorHeaderAction value, $Res Function(_EditorHeaderAction) _then) = __$EditorHeaderActionCopyWithImpl;
@override @useResult
$Res call({
 HeaderActionId id, TypedExpression icon, TypedExpression label, HeaderActionActivation activation, TypedExpression? tooltip, TypedExpression? priority, TypedExpression? visibleIf, TypedExpression? enabledIf, HeaderActionPlacement placement, HeaderActionTone tone, HeaderActionConfirmation? confirmation
});


@override $HeaderActionIdCopyWith<$Res> get id;@override $TypedExpressionCopyWith<$Res> get icon;@override $TypedExpressionCopyWith<$Res> get label;@override $HeaderActionActivationCopyWith<$Res> get activation;@override $TypedExpressionCopyWith<$Res>? get tooltip;@override $TypedExpressionCopyWith<$Res>? get priority;@override $TypedExpressionCopyWith<$Res>? get visibleIf;@override $TypedExpressionCopyWith<$Res>? get enabledIf;@override $HeaderActionConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class __$EditorHeaderActionCopyWithImpl<$Res>
    implements _$EditorHeaderActionCopyWith<$Res> {
  __$EditorHeaderActionCopyWithImpl(this._self, this._then);

  final _EditorHeaderAction _self;
  final $Res Function(_EditorHeaderAction) _then;

/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? activation = null,Object? tooltip = freezed,Object? priority = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(_EditorHeaderAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderActionId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as TypedExpression,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as HeaderActionActivation,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as HeaderActionConfirmation?,
  ));
}

/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionIdCopyWith<$Res> get id {
  
  return $HeaderActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get icon {
  
  return $TypedExpressionCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionActivationCopyWith<$Res> get activation {
  
  return $HeaderActionActivationCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get tooltip {
    if (_self.tooltip == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.tooltip!, (value) {
    return _then(_self.copyWith(tooltip: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get priority {
    if (_self.priority == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.priority!, (value) {
    return _then(_self.copyWith(priority: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get visibleIf {
    if (_self.visibleIf == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.visibleIf!, (value) {
    return _then(_self.copyWith(visibleIf: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get enabledIf {
    if (_self.enabledIf == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.enabledIf!, (value) {
    return _then(_self.copyWith(enabledIf: value));
  });
}/// Create a copy of EditorHeaderAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderActionConfirmationCopyWith<$Res>? get confirmation {
    if (_self.confirmation == null) {
    return null;
  }

  return $HeaderActionConfirmationCopyWith<$Res>(_self.confirmation!, (value) {
    return _then(_self.copyWith(confirmation: value));
  });
}
}

/// @nodoc
mixin _$PresentationHeader {

 BindingReference? get binding; TypedExpression? get title; TypedExpression? get description; bool? get initiallyExpanded; List<EditorHeaderAction> get actions;
/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationHeaderCopyWith<PresentationHeader> get copyWith => _$PresentationHeaderCopyWithImpl<PresentationHeader>(this as PresentationHeader, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationHeader&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded)&&const DeepCollectionEquality().equals(other.actions, actions));
}


@override
int get hashCode => Object.hash(runtimeType,binding,title,description,initiallyExpanded,const DeepCollectionEquality().hash(actions));

@override
String toString() {
  return 'PresentationHeader(binding: $binding, title: $title, description: $description, initiallyExpanded: $initiallyExpanded, actions: $actions)';
}


}

/// @nodoc
abstract mixin class $PresentationHeaderCopyWith<$Res>  {
  factory $PresentationHeaderCopyWith(PresentationHeader value, $Res Function(PresentationHeader) _then) = _$PresentationHeaderCopyWithImpl;
@useResult
$Res call({
 BindingReference? binding, TypedExpression? title, TypedExpression? description, bool? initiallyExpanded, List<EditorHeaderAction> actions
});


$BindingReferenceCopyWith<$Res>? get binding;$TypedExpressionCopyWith<$Res>? get title;$TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class _$PresentationHeaderCopyWithImpl<$Res>
    implements $PresentationHeaderCopyWith<$Res> {
  _$PresentationHeaderCopyWithImpl(this._self, this._then);

  final PresentationHeader _self;
  final $Res Function(PresentationHeader) _then;

/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? binding = freezed,Object? title = freezed,Object? description = freezed,Object? initiallyExpanded = freezed,Object? actions = null,}) {
  return _then(_self.copyWith(
binding: freezed == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<EditorHeaderAction>,
  ));
}
/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res>? get binding {
    if (_self.binding == null) {
    return null;
  }

  return $BindingReferenceCopyWith<$Res>(_self.binding!, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get description {
    if (_self.description == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.description!, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationHeader].
extension PresentationHeaderPatterns on PresentationHeader {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationHeader value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationHeader value)  $default,){
final _that = this;
switch (_that) {
case _PresentationHeader():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationHeader value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingReference? binding,  TypedExpression? title,  TypedExpression? description,  bool? initiallyExpanded,  List<EditorHeaderAction> actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingReference? binding,  TypedExpression? title,  TypedExpression? description,  bool? initiallyExpanded,  List<EditorHeaderAction> actions)  $default,) {final _that = this;
switch (_that) {
case _PresentationHeader():
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingReference? binding,  TypedExpression? title,  TypedExpression? description,  bool? initiallyExpanded,  List<EditorHeaderAction> actions)?  $default,) {final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.actions);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationHeader implements PresentationHeader {
  const _PresentationHeader({this.binding, this.title, this.description, this.initiallyExpanded, final  List<EditorHeaderAction> actions = const []}): _actions = actions;
  

@override final  BindingReference? binding;
@override final  TypedExpression? title;
@override final  TypedExpression? description;
@override final  bool? initiallyExpanded;
 final  List<EditorHeaderAction> _actions;
@override@JsonKey() List<EditorHeaderAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}


/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationHeaderCopyWith<_PresentationHeader> get copyWith => __$PresentationHeaderCopyWithImpl<_PresentationHeader>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationHeader&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded)&&const DeepCollectionEquality().equals(other._actions, _actions));
}


@override
int get hashCode => Object.hash(runtimeType,binding,title,description,initiallyExpanded,const DeepCollectionEquality().hash(_actions));

@override
String toString() {
  return 'PresentationHeader(binding: $binding, title: $title, description: $description, initiallyExpanded: $initiallyExpanded, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$PresentationHeaderCopyWith<$Res> implements $PresentationHeaderCopyWith<$Res> {
  factory _$PresentationHeaderCopyWith(_PresentationHeader value, $Res Function(_PresentationHeader) _then) = __$PresentationHeaderCopyWithImpl;
@override @useResult
$Res call({
 BindingReference? binding, TypedExpression? title, TypedExpression? description, bool? initiallyExpanded, List<EditorHeaderAction> actions
});


@override $BindingReferenceCopyWith<$Res>? get binding;@override $TypedExpressionCopyWith<$Res>? get title;@override $TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class __$PresentationHeaderCopyWithImpl<$Res>
    implements _$PresentationHeaderCopyWith<$Res> {
  __$PresentationHeaderCopyWithImpl(this._self, this._then);

  final _PresentationHeader _self;
  final $Res Function(_PresentationHeader) _then;

/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? binding = freezed,Object? title = freezed,Object? description = freezed,Object? initiallyExpanded = freezed,Object? actions = null,}) {
  return _then(_PresentationHeader(
binding: freezed == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<EditorHeaderAction>,
  ));
}

/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res>? get binding {
    if (_self.binding == null) {
    return null;
  }

  return $BindingReferenceCopyWith<$Res>(_self.binding!, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.title!, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get description {
    if (_self.description == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.description!, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}

// dart format on
