// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationNode {

 String get id; PresentationElement get element; PresentationProperties get properties; PresentationHeader? get header;
/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<PresentationNode> get copyWith => _$PresentationNodeCopyWithImpl<PresentationNode>(this as PresentationNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationNode&&(identical(other.id, id) || other.id == id)&&(identical(other.element, element) || other.element == element)&&(identical(other.properties, properties) || other.properties == properties)&&(identical(other.header, header) || other.header == header));
}


@override
int get hashCode => Object.hash(runtimeType,id,element,properties,header);

@override
String toString() {
  return 'PresentationNode(id: $id, element: $element, properties: $properties, header: $header)';
}


}

/// @nodoc
abstract mixin class $PresentationNodeCopyWith<$Res>  {
  factory $PresentationNodeCopyWith(PresentationNode value, $Res Function(PresentationNode) _then) = _$PresentationNodeCopyWithImpl;
@useResult
$Res call({
 String id, PresentationElement element, PresentationProperties properties, PresentationHeader? header
});


$PresentationElementCopyWith<$Res> get element;$PresentationPropertiesCopyWith<$Res> get properties;$PresentationHeaderCopyWith<$Res>? get header;

}
/// @nodoc
class _$PresentationNodeCopyWithImpl<$Res>
    implements $PresentationNodeCopyWith<$Res> {
  _$PresentationNodeCopyWithImpl(this._self, this._then);

  final PresentationNode _self;
  final $Res Function(PresentationNode) _then;

/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? element = null,Object? properties = null,Object? header = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,element: null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as PresentationElement,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as PresentationProperties,header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as PresentationHeader?,
  ));
}
/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationElementCopyWith<$Res> get element {
  
  return $PresentationElementCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationPropertiesCopyWith<$Res> get properties {
  
  return $PresentationPropertiesCopyWith<$Res>(_self.properties, (value) {
    return _then(_self.copyWith(properties: value));
  });
}/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationHeaderCopyWith<$Res>? get header {
    if (_self.header == null) {
    return null;
  }

  return $PresentationHeaderCopyWith<$Res>(_self.header!, (value) {
    return _then(_self.copyWith(header: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationNode].
extension PresentationNodePatterns on PresentationNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationNode value)  $default,){
final _that = this;
switch (_that) {
case _PresentationNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationNode value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PresentationElement element,  PresentationProperties properties,  PresentationHeader? header)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationNode() when $default != null:
return $default(_that.id,_that.element,_that.properties,_that.header);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PresentationElement element,  PresentationProperties properties,  PresentationHeader? header)  $default,) {final _that = this;
switch (_that) {
case _PresentationNode():
return $default(_that.id,_that.element,_that.properties,_that.header);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PresentationElement element,  PresentationProperties properties,  PresentationHeader? header)?  $default,) {final _that = this;
switch (_that) {
case _PresentationNode() when $default != null:
return $default(_that.id,_that.element,_that.properties,_that.header);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationNode implements PresentationNode {
  const _PresentationNode({required this.id, required this.element, this.properties = const PresentationProperties(), this.header}): assert(id != "", 'Presentation node ID must not be empty.');
  

@override final  String id;
@override final  PresentationElement element;
@override@JsonKey() final  PresentationProperties properties;
@override final  PresentationHeader? header;

/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationNodeCopyWith<_PresentationNode> get copyWith => __$PresentationNodeCopyWithImpl<_PresentationNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationNode&&(identical(other.id, id) || other.id == id)&&(identical(other.element, element) || other.element == element)&&(identical(other.properties, properties) || other.properties == properties)&&(identical(other.header, header) || other.header == header));
}


@override
int get hashCode => Object.hash(runtimeType,id,element,properties,header);

@override
String toString() {
  return 'PresentationNode(id: $id, element: $element, properties: $properties, header: $header)';
}


}

/// @nodoc
abstract mixin class _$PresentationNodeCopyWith<$Res> implements $PresentationNodeCopyWith<$Res> {
  factory _$PresentationNodeCopyWith(_PresentationNode value, $Res Function(_PresentationNode) _then) = __$PresentationNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, PresentationElement element, PresentationProperties properties, PresentationHeader? header
});


@override $PresentationElementCopyWith<$Res> get element;@override $PresentationPropertiesCopyWith<$Res> get properties;@override $PresentationHeaderCopyWith<$Res>? get header;

}
/// @nodoc
class __$PresentationNodeCopyWithImpl<$Res>
    implements _$PresentationNodeCopyWith<$Res> {
  __$PresentationNodeCopyWithImpl(this._self, this._then);

  final _PresentationNode _self;
  final $Res Function(_PresentationNode) _then;

/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? element = null,Object? properties = null,Object? header = freezed,}) {
  return _then(_PresentationNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,element: null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as PresentationElement,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as PresentationProperties,header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as PresentationHeader?,
  ));
}

/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationElementCopyWith<$Res> get element {
  
  return $PresentationElementCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationPropertiesCopyWith<$Res> get properties {
  
  return $PresentationPropertiesCopyWith<$Res>(_self.properties, (value) {
    return _then(_self.copyWith(properties: value));
  });
}/// Create a copy of PresentationNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationHeaderCopyWith<$Res>? get header {
    if (_self.header == null) {
    return null;
  }

  return $PresentationHeaderCopyWith<$Res>(_self.header!, (value) {
    return _then(_self.copyWith(header: value));
  });
}
}

/// @nodoc
mixin _$PresentationProperties {

 TypedExpression? get enabledIf; bool get readOnly;
/// Create a copy of PresentationProperties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationPropertiesCopyWith<PresentationProperties> get copyWith => _$PresentationPropertiesCopyWithImpl<PresentationProperties>(this as PresentationProperties, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationProperties&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly));
}


@override
int get hashCode => Object.hash(runtimeType,enabledIf,readOnly);

@override
String toString() {
  return 'PresentationProperties(enabledIf: $enabledIf, readOnly: $readOnly)';
}


}

/// @nodoc
abstract mixin class $PresentationPropertiesCopyWith<$Res>  {
  factory $PresentationPropertiesCopyWith(PresentationProperties value, $Res Function(PresentationProperties) _then) = _$PresentationPropertiesCopyWithImpl;
@useResult
$Res call({
 TypedExpression? enabledIf, bool readOnly
});


$TypedExpressionCopyWith<$Res>? get enabledIf;

}
/// @nodoc
class _$PresentationPropertiesCopyWithImpl<$Res>
    implements $PresentationPropertiesCopyWith<$Res> {
  _$PresentationPropertiesCopyWithImpl(this._self, this._then);

  final PresentationProperties _self;
  final $Res Function(PresentationProperties) _then;

/// Create a copy of PresentationProperties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabledIf = freezed,Object? readOnly = null,}) {
  return _then(_self.copyWith(
enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PresentationProperties
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


/// Adds pattern-matching-related methods to [PresentationProperties].
extension PresentationPropertiesPatterns on PresentationProperties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationProperties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationProperties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationProperties value)  $default,){
final _that = this;
switch (_that) {
case _PresentationProperties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationProperties value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationProperties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypedExpression? enabledIf,  bool readOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationProperties() when $default != null:
return $default(_that.enabledIf,_that.readOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypedExpression? enabledIf,  bool readOnly)  $default,) {final _that = this;
switch (_that) {
case _PresentationProperties():
return $default(_that.enabledIf,_that.readOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypedExpression? enabledIf,  bool readOnly)?  $default,) {final _that = this;
switch (_that) {
case _PresentationProperties() when $default != null:
return $default(_that.enabledIf,_that.readOnly);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationProperties implements PresentationProperties {
  const _PresentationProperties({this.enabledIf, this.readOnly = false});
  

@override final  TypedExpression? enabledIf;
@override@JsonKey() final  bool readOnly;

/// Create a copy of PresentationProperties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationPropertiesCopyWith<_PresentationProperties> get copyWith => __$PresentationPropertiesCopyWithImpl<_PresentationProperties>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationProperties&&(identical(other.enabledIf, enabledIf) || other.enabledIf == enabledIf)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly));
}


@override
int get hashCode => Object.hash(runtimeType,enabledIf,readOnly);

@override
String toString() {
  return 'PresentationProperties(enabledIf: $enabledIf, readOnly: $readOnly)';
}


}

/// @nodoc
abstract mixin class _$PresentationPropertiesCopyWith<$Res> implements $PresentationPropertiesCopyWith<$Res> {
  factory _$PresentationPropertiesCopyWith(_PresentationProperties value, $Res Function(_PresentationProperties) _then) = __$PresentationPropertiesCopyWithImpl;
@override @useResult
$Res call({
 TypedExpression? enabledIf, bool readOnly
});


@override $TypedExpressionCopyWith<$Res>? get enabledIf;

}
/// @nodoc
class __$PresentationPropertiesCopyWithImpl<$Res>
    implements _$PresentationPropertiesCopyWith<$Res> {
  __$PresentationPropertiesCopyWithImpl(this._self, this._then);

  final _PresentationProperties _self;
  final $Res Function(_PresentationProperties) _then;

/// Create a copy of PresentationProperties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabledIf = freezed,Object? readOnly = null,}) {
  return _then(_PresentationProperties(
enabledIf: freezed == enabledIf ? _self.enabledIf : enabledIf // ignore: cast_nullable_to_non_nullable
as TypedExpression?,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PresentationProperties
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

// dart format on
