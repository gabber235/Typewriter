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
mixin _$HeaderItemId {

 String get namespace; String get name;
/// Create a copy of HeaderItemId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<HeaderItemId> get copyWith => _$HeaderItemIdCopyWithImpl<HeaderItemId>(this as HeaderItemId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderItemId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'HeaderItemId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class $HeaderItemIdCopyWith<$Res>  {
  factory $HeaderItemIdCopyWith(HeaderItemId value, $Res Function(HeaderItemId) _then) = _$HeaderItemIdCopyWithImpl;
@useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class _$HeaderItemIdCopyWithImpl<$Res>
    implements $HeaderItemIdCopyWith<$Res> {
  _$HeaderItemIdCopyWithImpl(this._self, this._then);

  final HeaderItemId _self;
  final $Res Function(HeaderItemId) _then;

/// Create a copy of HeaderItemId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_self.copyWith(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HeaderItemId].
extension HeaderItemIdPatterns on HeaderItemId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeaderItemId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeaderItemId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeaderItemId value)  $default,){
final _that = this;
switch (_that) {
case _HeaderItemId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeaderItemId value)?  $default,){
final _that = this;
switch (_that) {
case _HeaderItemId() when $default != null:
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
case _HeaderItemId() when $default != null:
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
case _HeaderItemId():
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
case _HeaderItemId() when $default != null:
return $default(_that.namespace,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _HeaderItemId extends HeaderItemId {
  const _HeaderItemId({required this.namespace, required this.name}): assert(namespace != "", 'Header item namespace must not be empty.'),assert(name != "", 'Header item name must not be empty.'),super._();


@override final  String namespace;
@override final  String name;

/// Create a copy of HeaderItemId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeaderItemIdCopyWith<_HeaderItemId> get copyWith => __$HeaderItemIdCopyWithImpl<_HeaderItemId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeaderItemId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'HeaderItemId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class _$HeaderItemIdCopyWith<$Res> implements $HeaderItemIdCopyWith<$Res> {
  factory _$HeaderItemIdCopyWith(_HeaderItemId value, $Res Function(_HeaderItemId) _then) = __$HeaderItemIdCopyWithImpl;
@override @useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class __$HeaderItemIdCopyWithImpl<$Res>
    implements _$HeaderItemIdCopyWith<$Res> {
  __$HeaderItemIdCopyWithImpl(this._self, this._then);

  final _HeaderItemId _self;
  final $Res Function(_HeaderItemId) _then;

/// Create a copy of HeaderItemId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_HeaderItemId(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$HeaderItemCommandId {

 HeaderItemId get itemId; HeaderItemCommand get command;
/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderItemCommandIdCopyWith<HeaderItemCommandId> get copyWith => _$HeaderItemCommandIdCopyWithImpl<HeaderItemCommandId>(this as HeaderItemCommandId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderItemCommandId&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,command);

@override
String toString() {
  return 'HeaderItemCommandId(itemId: $itemId, command: $command)';
}


}

/// @nodoc
abstract mixin class $HeaderItemCommandIdCopyWith<$Res>  {
  factory $HeaderItemCommandIdCopyWith(HeaderItemCommandId value, $Res Function(HeaderItemCommandId) _then) = _$HeaderItemCommandIdCopyWithImpl;
@useResult
$Res call({
 HeaderItemId itemId, HeaderItemCommand command
});


$HeaderItemIdCopyWith<$Res> get itemId;

}
/// @nodoc
class _$HeaderItemCommandIdCopyWithImpl<$Res>
    implements $HeaderItemCommandIdCopyWith<$Res> {
  _$HeaderItemCommandIdCopyWithImpl(this._self, this._then);

  final HeaderItemCommandId _self;
  final $Res Function(HeaderItemCommandId) _then;

/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? command = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as HeaderItemId,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as HeaderItemCommand,
  ));
}
/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get itemId {

  return $HeaderItemIdCopyWith<$Res>(_self.itemId, (value) {
    return _then(_self.copyWith(itemId: value));
  });
}
}


/// Adds pattern-matching-related methods to [HeaderItemCommandId].
extension HeaderItemCommandIdPatterns on HeaderItemCommandId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeaderItemCommandId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeaderItemCommandId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeaderItemCommandId value)  $default,){
final _that = this;
switch (_that) {
case _HeaderItemCommandId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeaderItemCommandId value)?  $default,){
final _that = this;
switch (_that) {
case _HeaderItemCommandId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HeaderItemId itemId,  HeaderItemCommand command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeaderItemCommandId() when $default != null:
return $default(_that.itemId,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HeaderItemId itemId,  HeaderItemCommand command)  $default,) {final _that = this;
switch (_that) {
case _HeaderItemCommandId():
return $default(_that.itemId,_that.command);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HeaderItemId itemId,  HeaderItemCommand command)?  $default,) {final _that = this;
switch (_that) {
case _HeaderItemCommandId() when $default != null:
return $default(_that.itemId,_that.command);case _:
  return null;

}
}

}

/// @nodoc


class _HeaderItemCommandId implements HeaderItemCommandId {
  const _HeaderItemCommandId({required this.itemId, required this.command});


@override final  HeaderItemId itemId;
@override final  HeaderItemCommand command;

/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeaderItemCommandIdCopyWith<_HeaderItemCommandId> get copyWith => __$HeaderItemCommandIdCopyWithImpl<_HeaderItemCommandId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeaderItemCommandId&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,command);

@override
String toString() {
  return 'HeaderItemCommandId(itemId: $itemId, command: $command)';
}


}

/// @nodoc
abstract mixin class _$HeaderItemCommandIdCopyWith<$Res> implements $HeaderItemCommandIdCopyWith<$Res> {
  factory _$HeaderItemCommandIdCopyWith(_HeaderItemCommandId value, $Res Function(_HeaderItemCommandId) _then) = __$HeaderItemCommandIdCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId itemId, HeaderItemCommand command
});


@override $HeaderItemIdCopyWith<$Res> get itemId;

}
/// @nodoc
class __$HeaderItemCommandIdCopyWithImpl<$Res>
    implements _$HeaderItemCommandIdCopyWith<$Res> {
  __$HeaderItemCommandIdCopyWithImpl(this._self, this._then);

  final _HeaderItemCommandId _self;
  final $Res Function(_HeaderItemCommandId) _then;

/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? command = null,}) {
  return _then(_HeaderItemCommandId(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as HeaderItemId,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as HeaderItemCommand,
  ));
}

/// Create a copy of HeaderItemCommandId
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get itemId {

  return $HeaderItemIdCopyWith<$Res>(_self.itemId, (value) {
    return _then(_self.copyWith(itemId: value));
  });
}
}

/// @nodoc
mixin _$PresentationHeaderTitle {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationHeaderTitle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresentationHeaderTitle()';
}


}

/// @nodoc
class $PresentationHeaderTitleCopyWith<$Res>  {
$PresentationHeaderTitleCopyWith(PresentationHeaderTitle _, $Res Function(PresentationHeaderTitle) __);
}


/// Adds pattern-matching-related methods to [PresentationHeaderTitle].
extension PresentationHeaderTitlePatterns on PresentationHeaderTitle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PresentationHeaderTextTitle value)?  text,TResult Function( PresentationHeaderNodeTitle value)?  presentation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PresentationHeaderTextTitle() when text != null:
return text(_that);case PresentationHeaderNodeTitle() when presentation != null:
return presentation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PresentationHeaderTextTitle value)  text,required TResult Function( PresentationHeaderNodeTitle value)  presentation,}){
final _that = this;
switch (_that) {
case PresentationHeaderTextTitle():
return text(_that);case PresentationHeaderNodeTitle():
return presentation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PresentationHeaderTextTitle value)?  text,TResult? Function( PresentationHeaderNodeTitle value)?  presentation,}){
final _that = this;
switch (_that) {
case PresentationHeaderTextTitle() when text != null:
return text(_that);case PresentationHeaderNodeTitle() when presentation != null:
return presentation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedExpression value)?  text,TResult Function( PresentationNode node)?  presentation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PresentationHeaderTextTitle() when text != null:
return text(_that.value);case PresentationHeaderNodeTitle() when presentation != null:
return presentation(_that.node);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedExpression value)  text,required TResult Function( PresentationNode node)  presentation,}) {final _that = this;
switch (_that) {
case PresentationHeaderTextTitle():
return text(_that.value);case PresentationHeaderNodeTitle():
return presentation(_that.node);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedExpression value)?  text,TResult? Function( PresentationNode node)?  presentation,}) {final _that = this;
switch (_that) {
case PresentationHeaderTextTitle() when text != null:
return text(_that.value);case PresentationHeaderNodeTitle() when presentation != null:
return presentation(_that.node);case _:
  return null;

}
}

}

/// @nodoc


class PresentationHeaderTextTitle implements PresentationHeaderTitle {
  const PresentationHeaderTextTitle(this.value);


 final  TypedExpression value;

/// Create a copy of PresentationHeaderTitle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationHeaderTextTitleCopyWith<PresentationHeaderTextTitle> get copyWith => _$PresentationHeaderTextTitleCopyWithImpl<PresentationHeaderTextTitle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationHeaderTextTitle&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'PresentationHeaderTitle.text(value: $value)';
}


}

/// @nodoc
abstract mixin class $PresentationHeaderTextTitleCopyWith<$Res> implements $PresentationHeaderTitleCopyWith<$Res> {
  factory $PresentationHeaderTextTitleCopyWith(PresentationHeaderTextTitle value, $Res Function(PresentationHeaderTextTitle) _then) = _$PresentationHeaderTextTitleCopyWithImpl;
@useResult
$Res call({
 TypedExpression value
});


$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$PresentationHeaderTextTitleCopyWithImpl<$Res>
    implements $PresentationHeaderTextTitleCopyWith<$Res> {
  _$PresentationHeaderTextTitleCopyWithImpl(this._self, this._then);

  final PresentationHeaderTextTitle _self;
  final $Res Function(PresentationHeaderTextTitle) _then;

/// Create a copy of PresentationHeaderTitle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(PresentationHeaderTextTitle(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of PresentationHeaderTitle
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


class PresentationHeaderNodeTitle implements PresentationHeaderTitle {
  const PresentationHeaderNodeTitle(this.node);


 final  PresentationNode node;

/// Create a copy of PresentationHeaderTitle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationHeaderNodeTitleCopyWith<PresentationHeaderNodeTitle> get copyWith => _$PresentationHeaderNodeTitleCopyWithImpl<PresentationHeaderNodeTitle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationHeaderNodeTitle&&(identical(other.node, node) || other.node == node));
}


@override
int get hashCode => Object.hash(runtimeType,node);

@override
String toString() {
  return 'PresentationHeaderTitle.presentation(node: $node)';
}


}

/// @nodoc
abstract mixin class $PresentationHeaderNodeTitleCopyWith<$Res> implements $PresentationHeaderTitleCopyWith<$Res> {
  factory $PresentationHeaderNodeTitleCopyWith(PresentationHeaderNodeTitle value, $Res Function(PresentationHeaderNodeTitle) _then) = _$PresentationHeaderNodeTitleCopyWithImpl;
@useResult
$Res call({
 PresentationNode node
});


$PresentationNodeCopyWith<$Res> get node;

}
/// @nodoc
class _$PresentationHeaderNodeTitleCopyWithImpl<$Res>
    implements $PresentationHeaderNodeTitleCopyWith<$Res> {
  _$PresentationHeaderNodeTitleCopyWithImpl(this._self, this._then);

  final PresentationHeaderNodeTitle _self;
  final $Res Function(PresentationHeaderNodeTitle) _then;

/// Create a copy of PresentationHeaderTitle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? node = null,}) {
  return _then(PresentationHeaderNodeTitle(
null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of PresentationHeaderTitle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get node {

  return $PresentationNodeCopyWith<$Res>(_self.node, (value) {
    return _then(_self.copyWith(node: value));
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
mixin _$HeaderItem {

 HeaderItemId get id; TypedExpression get label; TypedExpression? get tooltip; TypedExpression? get visibleIf; TypedExpression? get enabledIf;
/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderItemCopyWith<HeaderItem> get copyWith => _$HeaderItemCopyWithImpl<HeaderItem>(this as HeaderItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,tooltip,visibleIf,enabledIf);

@override
String toString() {
  return 'HeaderItem(id: $id, label: $label, tooltip: $tooltip, visibleIf: $visibleIf, enabledIf: $enabledIf)';
}


}

/// @nodoc
abstract mixin class $HeaderItemCopyWith<$Res>  {
  factory $HeaderItemCopyWith(HeaderItem value, $Res Function(HeaderItem) _then) = _$HeaderItemCopyWithImpl;
@useResult
$Res call({
 HeaderItemId id, TypedExpression label, TypedExpression? tooltip, TypedExpression? visibleIf, TypedExpression? enabledIf
});


$HeaderItemIdCopyWith<$Res> get id;$TypedExpressionCopyWith<$Res> get label;$TypedExpressionCopyWith<$Res>? get tooltip;$TypedExpressionCopyWith<$Res>? get visibleIf;$TypedExpressionCopyWith<$Res>? get enabledIf;

}
/// @nodoc
class _$HeaderItemCopyWithImpl<$Res>
    implements $HeaderItemCopyWith<$Res> {
  _$HeaderItemCopyWithImpl(this._self, this._then);

  final HeaderItem _self;
  final $Res Function(HeaderItem) _then;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? tooltip = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}
/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {

  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {

  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}
}


/// Adds pattern-matching-related methods to [HeaderItem].
extension HeaderItemPatterns on HeaderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HeaderButtonItem value)?  button,TResult Function( HeaderBooleanToggleItem value)?  booleanToggle,TResult Function( HeaderReorderHandleItem value)?  reorderHandle,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HeaderButtonItem() when button != null:
return button(_that);case HeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that);case HeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HeaderButtonItem value)  button,required TResult Function( HeaderBooleanToggleItem value)  booleanToggle,required TResult Function( HeaderReorderHandleItem value)  reorderHandle,}){
final _that = this;
switch (_that) {
case HeaderButtonItem():
return button(_that);case HeaderBooleanToggleItem():
return booleanToggle(_that);case HeaderReorderHandleItem():
return reorderHandle(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HeaderButtonItem value)?  button,TResult? Function( HeaderBooleanToggleItem value)?  booleanToggle,TResult? Function( HeaderReorderHandleItem value)?  reorderHandle,}){
final _that = this;
switch (_that) {
case HeaderButtonItem() when button != null:
return button(_that);case HeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that);case HeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( HeaderItemId id,  TypedExpression icon,  TypedExpression label,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)?  button,TResult Function( HeaderItemId id,  TypedExpression label,  TypedExpression checked,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionConfirmation? confirmation)?  booleanToggle,TResult Function( HeaderItemId id,  TypedExpression label,  BindingReference source,  TypedExpression? tooltip,  TypedExpression? visibleIf,  TypedExpression? enabledIf)?  reorderHandle,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HeaderButtonItem() when button != null:
return button(_that.id,_that.icon,_that.label,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case HeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that.id,_that.label,_that.checked,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.confirmation);case HeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that.id,_that.label,_that.source,_that.tooltip,_that.visibleIf,_that.enabledIf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( HeaderItemId id,  TypedExpression icon,  TypedExpression label,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)  button,required TResult Function( HeaderItemId id,  TypedExpression label,  TypedExpression checked,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionConfirmation? confirmation)  booleanToggle,required TResult Function( HeaderItemId id,  TypedExpression label,  BindingReference source,  TypedExpression? tooltip,  TypedExpression? visibleIf,  TypedExpression? enabledIf)  reorderHandle,}) {final _that = this;
switch (_that) {
case HeaderButtonItem():
return button(_that.id,_that.icon,_that.label,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case HeaderBooleanToggleItem():
return booleanToggle(_that.id,_that.label,_that.checked,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.confirmation);case HeaderReorderHandleItem():
return reorderHandle(_that.id,_that.label,_that.source,_that.tooltip,_that.visibleIf,_that.enabledIf);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( HeaderItemId id,  TypedExpression icon,  TypedExpression label,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionTone tone,  HeaderActionConfirmation? confirmation)?  button,TResult? Function( HeaderItemId id,  TypedExpression label,  TypedExpression checked,  EditorAction action,  TypedExpression? tooltip,  TypedExpression? priority,  TypedExpression? visibleIf,  TypedExpression? enabledIf,  HeaderActionPlacement placement,  HeaderActionConfirmation? confirmation)?  booleanToggle,TResult? Function( HeaderItemId id,  TypedExpression label,  BindingReference source,  TypedExpression? tooltip,  TypedExpression? visibleIf,  TypedExpression? enabledIf)?  reorderHandle,}) {final _that = this;
switch (_that) {
case HeaderButtonItem() when button != null:
return button(_that.id,_that.icon,_that.label,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.tone,_that.confirmation);case HeaderBooleanToggleItem() when booleanToggle != null:
return booleanToggle(_that.id,_that.label,_that.checked,_that.action,_that.tooltip,_that.priority,_that.visibleIf,_that.enabledIf,_that.placement,_that.confirmation);case HeaderReorderHandleItem() when reorderHandle != null:
return reorderHandle(_that.id,_that.label,_that.source,_that.tooltip,_that.visibleIf,_that.enabledIf);case _:
  return null;

}
}

}

/// @nodoc


class HeaderButtonItem implements HeaderItem {
  const HeaderButtonItem({required this.id, required this.icon, required this.label, required this.action, this.tooltip, this.priority, this.visibleIf, this.enabledIf, this.placement = HeaderActionPlacement.end, this.tone = HeaderActionTone.neutral, this.confirmation});


@override final  HeaderItemId id;
 final  TypedExpression icon;
@override final  TypedExpression label;
 final  EditorAction action;
@override final  TypedExpression? tooltip;
 final  TypedExpression? priority;
@override final  TypedExpression? visibleIf;
@override final  TypedExpression? enabledIf;
@JsonKey() final  HeaderActionPlacement placement;
@JsonKey() final  HeaderActionTone tone;
 final  HeaderActionConfirmation? confirmation;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderButtonItemCopyWith<HeaderButtonItem> get copyWith => _$HeaderButtonItemCopyWithImpl<HeaderButtonItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderButtonItem&&(identical(other.id, id) || other.id == id)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.label, label) || other.label == label)&&(identical(other.action, action) || other.action == action)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,icon,label,action,tooltip,priority,visibleIf,enabledIf,placement,tone,confirmation);

@override
String toString() {
  return 'HeaderItem.button(id: $id, icon: $icon, label: $label, action: $action, tooltip: $tooltip, priority: $priority, visibleIf: $visibleIf, enabledIf: $enabledIf, placement: $placement, tone: $tone, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class $HeaderButtonItemCopyWith<$Res> implements $HeaderItemCopyWith<$Res> {
  factory $HeaderButtonItemCopyWith(HeaderButtonItem value, $Res Function(HeaderButtonItem) _then) = _$HeaderButtonItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, TypedExpression icon, TypedExpression label, EditorAction action, TypedExpression? tooltip, TypedExpression? priority, TypedExpression? visibleIf, TypedExpression? enabledIf, HeaderActionPlacement placement, HeaderActionTone tone, HeaderActionConfirmation? confirmation
});


@override $HeaderItemIdCopyWith<$Res> get id;$TypedExpressionCopyWith<$Res> get icon;@override $TypedExpressionCopyWith<$Res> get label;$EditorActionCopyWith<$Res> get action;@override $TypedExpressionCopyWith<$Res>? get tooltip;$TypedExpressionCopyWith<$Res>? get priority;@override $TypedExpressionCopyWith<$Res>? get visibleIf;@override $TypedExpressionCopyWith<$Res>? get enabledIf;$HeaderActionConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class _$HeaderButtonItemCopyWithImpl<$Res>
    implements $HeaderButtonItemCopyWith<$Res> {
  _$HeaderButtonItemCopyWithImpl(this._self, this._then);

  final HeaderButtonItem _self;
  final $Res Function(HeaderButtonItem) _then;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? icon = null,Object? label = null,Object? action = null,Object? tooltip = freezed,Object? priority = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,Object? placement = null,Object? tone = null,Object? confirmation = freezed,}) {
  return _then(HeaderButtonItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as TypedExpression,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as HeaderActionTone,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as HeaderActionConfirmation?,
  ));
}

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {

  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get icon {

  return $TypedExpressionCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {

  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {

  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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


class HeaderBooleanToggleItem implements HeaderItem {
  const HeaderBooleanToggleItem({required this.id, required this.label, required this.checked, required this.action, this.tooltip, this.priority, this.visibleIf, this.enabledIf, this.placement = HeaderActionPlacement.end, this.confirmation});


@override final  HeaderItemId id;
@override final  TypedExpression label;
 final  TypedExpression checked;
 final  EditorAction action;
@override final  TypedExpression? tooltip;
 final  TypedExpression? priority;
@override final  TypedExpression? visibleIf;
@override final  TypedExpression? enabledIf;
@JsonKey() final  HeaderActionPlacement placement;
 final  HeaderActionConfirmation? confirmation;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderBooleanToggleItemCopyWith<HeaderBooleanToggleItem> get copyWith => _$HeaderBooleanToggleItemCopyWithImpl<HeaderBooleanToggleItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderBooleanToggleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.action, action) || other.action == action)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,checked,action,tooltip,priority,visibleIf,enabledIf,placement,confirmation);

@override
String toString() {
  return 'HeaderItem.booleanToggle(id: $id, label: $label, checked: $checked, action: $action, tooltip: $tooltip, priority: $priority, visibleIf: $visibleIf, enabledIf: $enabledIf, placement: $placement, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class $HeaderBooleanToggleItemCopyWith<$Res> implements $HeaderItemCopyWith<$Res> {
  factory $HeaderBooleanToggleItemCopyWith(HeaderBooleanToggleItem value, $Res Function(HeaderBooleanToggleItem) _then) = _$HeaderBooleanToggleItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, TypedExpression label, TypedExpression checked, EditorAction action, TypedExpression? tooltip, TypedExpression? priority, TypedExpression? visibleIf, TypedExpression? enabledIf, HeaderActionPlacement placement, HeaderActionConfirmation? confirmation
});


@override $HeaderItemIdCopyWith<$Res> get id;@override $TypedExpressionCopyWith<$Res> get label;$TypedExpressionCopyWith<$Res> get checked;$EditorActionCopyWith<$Res> get action;@override $TypedExpressionCopyWith<$Res>? get tooltip;$TypedExpressionCopyWith<$Res>? get priority;@override $TypedExpressionCopyWith<$Res>? get visibleIf;@override $TypedExpressionCopyWith<$Res>? get enabledIf;$HeaderActionConfirmationCopyWith<$Res>? get confirmation;

}
/// @nodoc
class _$HeaderBooleanToggleItemCopyWithImpl<$Res>
    implements $HeaderBooleanToggleItemCopyWith<$Res> {
  _$HeaderBooleanToggleItemCopyWithImpl(this._self, this._then);

  final HeaderBooleanToggleItem _self;
  final $Res Function(HeaderBooleanToggleItem) _then;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? checked = null,Object? action = null,Object? tooltip = freezed,Object? priority = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,Object? placement = null,Object? confirmation = freezed,}) {
  return _then(HeaderBooleanToggleItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as HeaderActionPlacement,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as HeaderActionConfirmation?,
  ));
}

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {

  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {

  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get checked {

  return $TypedExpressionCopyWith<$Res>(_self.checked, (value) {
    return _then(_self.copyWith(checked: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {

  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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


class HeaderReorderHandleItem implements HeaderItem {
  const HeaderReorderHandleItem({required this.id, required this.label, required this.source, this.tooltip, this.visibleIf, this.enabledIf});


@override final  HeaderItemId id;
@override final  TypedExpression label;
 final  BindingReference source;
@override final  TypedExpression? tooltip;
@override final  TypedExpression? visibleIf;
@override final  TypedExpression? enabledIf;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeaderReorderHandleItemCopyWith<HeaderReorderHandleItem> get copyWith => _$HeaderReorderHandleItemCopyWithImpl<HeaderReorderHandleItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderReorderHandleItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source)&&(identical(other.tooltip, tooltip) || other.tooltip == tooltip)&&(identical(other.visibleIf, visibleIf) || other.visibleIf == visibleIf)&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,source,tooltip,visibleIf,enabledIf);

@override
String toString() {
  return 'HeaderItem.reorderHandle(id: $id, label: $label, source: $source, tooltip: $tooltip, visibleIf: $visibleIf, enabledIf: $enabledIf)';
}


}

/// @nodoc
abstract mixin class $HeaderReorderHandleItemCopyWith<$Res> implements $HeaderItemCopyWith<$Res> {
  factory $HeaderReorderHandleItemCopyWith(HeaderReorderHandleItem value, $Res Function(HeaderReorderHandleItem) _then) = _$HeaderReorderHandleItemCopyWithImpl;
@override @useResult
$Res call({
 HeaderItemId id, TypedExpression label, BindingReference source, TypedExpression? tooltip, TypedExpression? visibleIf, TypedExpression? enabledIf
});


@override $HeaderItemIdCopyWith<$Res> get id;@override $TypedExpressionCopyWith<$Res> get label;$BindingReferenceCopyWith<$Res> get source;@override $TypedExpressionCopyWith<$Res>? get tooltip;@override $TypedExpressionCopyWith<$Res>? get visibleIf;@override $TypedExpressionCopyWith<$Res>? get enabledIf;

}
/// @nodoc
class _$HeaderReorderHandleItemCopyWithImpl<$Res>
    implements $HeaderReorderHandleItemCopyWith<$Res> {
  _$HeaderReorderHandleItemCopyWithImpl(this._self, this._then);

  final HeaderReorderHandleItem _self;
  final $Res Function(HeaderReorderHandleItem) _then;

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? source = null,Object? tooltip = freezed,Object? visibleIf = freezed,Object? enabledIf = freezed,}) {
  return _then(HeaderReorderHandleItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as HeaderItemId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BindingReference,tooltip: freezed == tooltip ? _self.tooltip : tooltip // ignore: cast_nullable_to_non_nullable
as TypedExpression?,visibleIf: freezed == visibleIf ? _self.visibleIf : visibleIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeaderItemIdCopyWith<$Res> get id {

  return $HeaderItemIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {

  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of HeaderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get source {

  return $BindingReferenceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}/// Create a copy of HeaderItem
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
}
}

/// @nodoc
mixin _$PresentationHeader {

 BindingReference? get binding; PresentationHeaderTitle? get title; TypedExpression? get description; bool? get initiallyExpanded; List<HeaderItem> get items;
/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationHeaderCopyWith<PresentationHeader> get copyWith => _$PresentationHeaderCopyWithImpl<PresentationHeader>(this as PresentationHeader, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationHeader&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,binding,title,description,initiallyExpanded,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'PresentationHeader(binding: $binding, title: $title, description: $description, initiallyExpanded: $initiallyExpanded, items: $items)';
}


}

/// @nodoc
abstract mixin class $PresentationHeaderCopyWith<$Res>  {
  factory $PresentationHeaderCopyWith(PresentationHeader value, $Res Function(PresentationHeader) _then) = _$PresentationHeaderCopyWithImpl;
@useResult
$Res call({
 BindingReference? binding, PresentationHeaderTitle? title, TypedExpression? description, bool? initiallyExpanded, List<HeaderItem> items
});


$BindingReferenceCopyWith<$Res>? get binding;$PresentationHeaderTitleCopyWith<$Res>? get title;$TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class _$PresentationHeaderCopyWithImpl<$Res>
    implements $PresentationHeaderCopyWith<$Res> {
  _$PresentationHeaderCopyWithImpl(this._self, this._then);

  final PresentationHeader _self;
  final $Res Function(PresentationHeader) _then;

/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? binding = freezed,Object? title = freezed,Object? description = freezed,Object? initiallyExpanded = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
binding: freezed == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as PresentationHeaderTitle?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<HeaderItem>,
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
$PresentationHeaderTitleCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $PresentationHeaderTitleCopyWith<$Res>(_self.title!, (value) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingReference? binding,  PresentationHeaderTitle? title,  TypedExpression? description,  bool? initiallyExpanded,  List<HeaderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingReference? binding,  PresentationHeaderTitle? title,  TypedExpression? description,  bool? initiallyExpanded,  List<HeaderItem> items)  $default,) {final _that = this;
switch (_that) {
case _PresentationHeader():
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingReference? binding,  PresentationHeaderTitle? title,  TypedExpression? description,  bool? initiallyExpanded,  List<HeaderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _PresentationHeader() when $default != null:
return $default(_that.binding,_that.title,_that.description,_that.initiallyExpanded,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationHeader implements PresentationHeader {
  const _PresentationHeader({this.binding, this.title, this.description, this.initiallyExpanded, final  List<HeaderItem> items = const []}): _items = items;


@override final  BindingReference? binding;
@override final  PresentationHeaderTitle? title;
@override final  TypedExpression? description;
@override final  bool? initiallyExpanded;
 final  List<HeaderItem> _items;
@override@JsonKey() List<HeaderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationHeaderCopyWith<_PresentationHeader> get copyWith => __$PresentationHeaderCopyWithImpl<_PresentationHeader>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationHeader&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,binding,title,description,initiallyExpanded,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'PresentationHeader(binding: $binding, title: $title, description: $description, initiallyExpanded: $initiallyExpanded, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PresentationHeaderCopyWith<$Res> implements $PresentationHeaderCopyWith<$Res> {
  factory _$PresentationHeaderCopyWith(_PresentationHeader value, $Res Function(_PresentationHeader) _then) = __$PresentationHeaderCopyWithImpl;
@override @useResult
$Res call({
 BindingReference? binding, PresentationHeaderTitle? title, TypedExpression? description, bool? initiallyExpanded, List<HeaderItem> items
});


@override $BindingReferenceCopyWith<$Res>? get binding;@override $PresentationHeaderTitleCopyWith<$Res>? get title;@override $TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class __$PresentationHeaderCopyWithImpl<$Res>
    implements _$PresentationHeaderCopyWith<$Res> {
  __$PresentationHeaderCopyWithImpl(this._self, this._then);

  final _PresentationHeader _self;
  final $Res Function(_PresentationHeader) _then;

/// Create a copy of PresentationHeader
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? binding = freezed,Object? title = freezed,Object? description = freezed,Object? initiallyExpanded = freezed,Object? items = null,}) {
  return _then(_PresentationHeader(
binding: freezed == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as PresentationHeaderTitle?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<HeaderItem>,
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
$PresentationHeaderTitleCopyWith<$Res>? get title {
    if (_self.title == null) {
    return null;
  }

  return $PresentationHeaderTitleCopyWith<$Res>(_self.title!, (value) {
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
