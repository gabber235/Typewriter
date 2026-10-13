// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authored_presentation_index.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoredBindingRoot {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredBindingRoot);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoredBindingRoot()';
}


}

/// @nodoc
class $AuthoredBindingRootCopyWith<$Res>  {
$AuthoredBindingRootCopyWith(AuthoredBindingRoot _, $Res Function(AuthoredBindingRoot) __);
}


/// Adds methods for matching patterns to [AuthoredBindingRoot].
extension AuthoredBindingRootPatterns on AuthoredBindingRoot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthoredResourceRoot value)?  resource,TResult Function( AuthoredLocalRoot value)?  local,TResult Function( AuthoredCollectionRoot value)?  collection,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthoredResourceRoot() when resource != null:
return resource(_that);case AuthoredLocalRoot() when local != null:
return local(_that);case AuthoredCollectionRoot() when collection != null:
return collection(_that);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthoredResourceRoot value)  resource,required TResult Function( AuthoredLocalRoot value)  local,required TResult Function( AuthoredCollectionRoot value)  collection,}){
final _that = this;
switch (_that) {
case AuthoredResourceRoot():
return resource(_that);case AuthoredLocalRoot():
return local(_that);case AuthoredCollectionRoot():
return collection(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthoredResourceRoot value)?  resource,TResult? Function( AuthoredLocalRoot value)?  local,TResult? Function( AuthoredCollectionRoot value)?  collection,}){
final _that = this;
switch (_that) {
case AuthoredResourceRoot() when resource != null:
return resource(_that);case AuthoredLocalRoot() when local != null:
return local(_that);case AuthoredCollectionRoot() when collection != null:
return collection(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ResourceId resource)?  resource,TResult Function( skir.ExpressionBindingId binding,  String? origin)?  local,TResult Function( String sourceId)?  collection,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthoredResourceRoot() when resource != null:
return resource(_that.resource);case AuthoredLocalRoot() when local != null:
return local(_that.binding,_that.origin);case AuthoredCollectionRoot() when collection != null:
return collection(_that.sourceId);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ResourceId resource)  resource,required TResult Function( skir.ExpressionBindingId binding,  String? origin)  local,required TResult Function( String sourceId)  collection,}) {final _that = this;
switch (_that) {
case AuthoredResourceRoot():
return resource(_that.resource);case AuthoredLocalRoot():
return local(_that.binding,_that.origin);case AuthoredCollectionRoot():
return collection(_that.sourceId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ResourceId resource)?  resource,TResult? Function( skir.ExpressionBindingId binding,  String? origin)?  local,TResult? Function( String sourceId)?  collection,}) {final _that = this;
switch (_that) {
case AuthoredResourceRoot() when resource != null:
return resource(_that.resource);case AuthoredLocalRoot() when local != null:
return local(_that.binding,_that.origin);case AuthoredCollectionRoot() when collection != null:
return collection(_that.sourceId);case _:
  return null;

}
}

}

/// @nodoc


class AuthoredResourceRoot implements AuthoredBindingRoot {
  const AuthoredResourceRoot(this.resource);


 final  skir.ResourceId resource;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredResourceRootCopyWith<AuthoredResourceRoot> get copyWith => _$AuthoredResourceRootCopyWithImpl<AuthoredResourceRoot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredResourceRoot&&(identical(other.resource, resource) || other.resource == resource));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource);
}

@override
String toString() {
    return 'AuthoredBindingRoot.resource(resource: $resource)';
}


}

/// @nodoc
abstract mixin class $AuthoredResourceRootCopyWith<$Res> implements $AuthoredBindingRootCopyWith<$Res> {
  factory $AuthoredResourceRootCopyWith(AuthoredResourceRoot value, $Res Function(AuthoredResourceRoot) _then) = _$AuthoredResourceRootCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource
});




}
/// @nodoc
class _$AuthoredResourceRootCopyWithImpl<$Res>
    implements $AuthoredResourceRootCopyWith<$Res> {
  _$AuthoredResourceRootCopyWithImpl(this._self, this._then);

  final AuthoredResourceRoot _self;
  final $Res Function(AuthoredResourceRoot) _then;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? resource = null,}) {
  return _then(AuthoredResourceRoot(
null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc


class AuthoredLocalRoot implements AuthoredBindingRoot {
  const AuthoredLocalRoot(this.binding, {this.origin});


 final  skir.ExpressionBindingId binding;
 final  String? origin;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredLocalRootCopyWith<AuthoredLocalRoot> get copyWith => _$AuthoredLocalRootCopyWithImpl<AuthoredLocalRoot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredLocalRoot&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,binding,origin);
}

@override
String toString() {
    return 'AuthoredBindingRoot.local(binding: $binding, origin: $origin)';
}


}

/// @nodoc
abstract mixin class $AuthoredLocalRootCopyWith<$Res> implements $AuthoredBindingRootCopyWith<$Res> {
  factory $AuthoredLocalRootCopyWith(AuthoredLocalRoot value, $Res Function(AuthoredLocalRoot) _then) = _$AuthoredLocalRootCopyWithImpl;
@useResult
$Res call({
 skir.ExpressionBindingId binding, String? origin
});




}
/// @nodoc
class _$AuthoredLocalRootCopyWithImpl<$Res>
    implements $AuthoredLocalRootCopyWith<$Res> {
  _$AuthoredLocalRootCopyWithImpl(this._self, this._then);

  final AuthoredLocalRoot _self;
  final $Res Function(AuthoredLocalRoot) _then;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,Object? origin = freezed,}) {
  return _then(AuthoredLocalRoot(
null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as skir.ExpressionBindingId,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AuthoredCollectionRoot implements AuthoredBindingRoot {
  const AuthoredCollectionRoot(this.sourceId);


 final  String sourceId;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredCollectionRootCopyWith<AuthoredCollectionRoot> get copyWith => _$AuthoredCollectionRootCopyWithImpl<AuthoredCollectionRoot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredCollectionRoot&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sourceId);
}

@override
String toString() {
    return 'AuthoredBindingRoot.collection(sourceId: $sourceId)';
}


}

/// @nodoc
abstract mixin class $AuthoredCollectionRootCopyWith<$Res> implements $AuthoredBindingRootCopyWith<$Res> {
  factory $AuthoredCollectionRootCopyWith(AuthoredCollectionRoot value, $Res Function(AuthoredCollectionRoot) _then) = _$AuthoredCollectionRootCopyWithImpl;
@useResult
$Res call({
 String sourceId
});




}
/// @nodoc
class _$AuthoredCollectionRootCopyWithImpl<$Res>
    implements $AuthoredCollectionRootCopyWith<$Res> {
  _$AuthoredCollectionRootCopyWithImpl(this._self, this._then);

  final AuthoredCollectionRoot _self;
  final $Res Function(AuthoredCollectionRoot) _then;

/// Create a copy of AuthoredBindingRoot
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sourceId = null,}) {
  return _then(AuthoredCollectionRoot(
null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AuthoredPathStep {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredPathStep);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoredPathStep()';
}


}

/// @nodoc
class $AuthoredPathStepCopyWith<$Res>  {
$AuthoredPathStepCopyWith(AuthoredPathStep _, $Res Function(AuthoredPathStep) __);
}


/// Adds methods for matching patterns to [AuthoredPathStep].
extension AuthoredPathStepPatterns on AuthoredPathStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExactAuthoredPathStep value)?  exact,TResult Function( AnyAuthoredItem value)?  item,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExactAuthoredPathStep() when exact != null:
return exact(_that);case AnyAuthoredItem() when item != null:
return item(_that);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExactAuthoredPathStep value)  exact,required TResult Function( AnyAuthoredItem value)  item,}){
final _that = this;
switch (_that) {
case ExactAuthoredPathStep():
return exact(_that);case AnyAuthoredItem():
return item(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExactAuthoredPathStep value)?  exact,TResult? Function( AnyAuthoredItem value)?  item,}){
final _that = this;
switch (_that) {
case ExactAuthoredPathStep() when exact != null:
return exact(_that);case AnyAuthoredItem() when item != null:
return item(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PathSegment segment)?  exact,TResult Function()?  item,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExactAuthoredPathStep() when exact != null:
return exact(_that.segment);case AnyAuthoredItem() when item != null:
return item();case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PathSegment segment)  exact,required TResult Function()  item,}) {final _that = this;
switch (_that) {
case ExactAuthoredPathStep():
return exact(_that.segment);case AnyAuthoredItem():
return item();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PathSegment segment)?  exact,TResult? Function()?  item,}) {final _that = this;
switch (_that) {
case ExactAuthoredPathStep() when exact != null:
return exact(_that.segment);case AnyAuthoredItem() when item != null:
return item();case _:
  return null;

}
}

}

/// @nodoc


class ExactAuthoredPathStep implements AuthoredPathStep {
  const ExactAuthoredPathStep(this.segment);


 final  skir.PathSegment segment;

/// Create a copy of AuthoredPathStep
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExactAuthoredPathStepCopyWith<ExactAuthoredPathStep> get copyWith => _$ExactAuthoredPathStepCopyWithImpl<ExactAuthoredPathStep>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExactAuthoredPathStep&&(identical(other.segment, segment) || other.segment == segment));
}


@override
int get hashCode {
    return Object.hash(runtimeType,segment);
}

@override
String toString() {
    return 'AuthoredPathStep.exact(segment: $segment)';
}


}

/// @nodoc
abstract mixin class $ExactAuthoredPathStepCopyWith<$Res> implements $AuthoredPathStepCopyWith<$Res> {
  factory $ExactAuthoredPathStepCopyWith(ExactAuthoredPathStep value, $Res Function(ExactAuthoredPathStep) _then) = _$ExactAuthoredPathStepCopyWithImpl;
@useResult
$Res call({
 skir.PathSegment segment
});




}
/// @nodoc
class _$ExactAuthoredPathStepCopyWithImpl<$Res>
    implements $ExactAuthoredPathStepCopyWith<$Res> {
  _$ExactAuthoredPathStepCopyWithImpl(this._self, this._then);

  final ExactAuthoredPathStep _self;
  final $Res Function(ExactAuthoredPathStep) _then;

/// Create a copy of AuthoredPathStep
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? segment = null,}) {
  return _then(ExactAuthoredPathStep(
null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as skir.PathSegment,
  ));
}


}

/// @nodoc


class AnyAuthoredItem implements AuthoredPathStep {
  const AnyAuthoredItem();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AnyAuthoredItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoredPathStep.item()';
}


}




/// @nodoc
mixin _$AuthoredBindingAddress {

 AuthoredBindingRoot get root; List<AuthoredPathStep> get path;
/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<AuthoredBindingAddress> get copyWith => _$AuthoredBindingAddressCopyWithImpl<AuthoredBindingAddress>(this as AuthoredBindingAddress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredBindingAddress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredBindingAddress&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.path, _this.path));
}


@override
int get hashCode {
  final _this = this as AuthoredBindingAddress;
  return Object.hash(runtimeType,_this.root,const DeepCollectionEquality().hash(_this.path));
}

@override
String toString() {
  final _this = this as AuthoredBindingAddress;
  return 'AuthoredBindingAddress(root: ${_this.root}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $AuthoredBindingAddressCopyWith<$Res>  {
  factory $AuthoredBindingAddressCopyWith(AuthoredBindingAddress value, $Res Function(AuthoredBindingAddress) _then) = _$AuthoredBindingAddressCopyWithImpl;
@useResult
$Res call({
 AuthoredBindingRoot root, List<AuthoredPathStep> path
});


$AuthoredBindingRootCopyWith<$Res> get root;

}
/// @nodoc
class _$AuthoredBindingAddressCopyWithImpl<$Res>
    implements $AuthoredBindingAddressCopyWith<$Res> {
  _$AuthoredBindingAddressCopyWithImpl(this._self, this._then);

  final AuthoredBindingAddress _self;
  final $Res Function(AuthoredBindingAddress) _then;

/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? path = null,}) {
  return _then(AuthoredBindingAddress(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as AuthoredBindingRoot,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<AuthoredPathStep>,
  ));
}
/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingRootCopyWith<$Res> get root {

  return $AuthoredBindingRootCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}


/// Adds methods for matching patterns to [AuthoredBindingAddress].
extension AuthoredBindingAddressPatterns on AuthoredBindingAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredBindingAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredBindingAddress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredBindingAddress value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredBindingAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredBindingAddress value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredBindingAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoredBindingRoot root,  List<AuthoredPathStep> path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredBindingAddress() when $default != null:
return $default(_that.root,_that.path);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoredBindingRoot root,  List<AuthoredPathStep> path)  $default,) {final _that = this;
switch (_that) {
case _AuthoredBindingAddress():
return $default(_that.root,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoredBindingRoot root,  List<AuthoredPathStep> path)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredBindingAddress() when $default != null:
return $default(_that.root,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredBindingAddress extends AuthoredBindingAddress {
  const _AuthoredBindingAddress({required this.root, required  List<AuthoredPathStep> path}): _path = path,super._();


@override final  AuthoredBindingRoot root;
 final  List<AuthoredPathStep> _path;
@override List<AuthoredPathStep> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}


/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredBindingAddressCopyWith<_AuthoredBindingAddress> get copyWith => __$AuthoredBindingAddressCopyWithImpl<_AuthoredBindingAddress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredBindingAddress&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.path, _path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,root,const DeepCollectionEquality().hash(_path));
}

@override
String toString() {
    return 'AuthoredBindingAddress(root: $root, path: $path)';
}


}

/// @nodoc
abstract mixin class _$AuthoredBindingAddressCopyWith<$Res> implements $AuthoredBindingAddressCopyWith<$Res> {
  factory _$AuthoredBindingAddressCopyWith(_AuthoredBindingAddress value, $Res Function(_AuthoredBindingAddress) _then) = __$AuthoredBindingAddressCopyWithImpl;
@override @useResult
$Res call({
 AuthoredBindingRoot root, List<AuthoredPathStep> path
});


@override $AuthoredBindingRootCopyWith<$Res> get root;

}
/// @nodoc
class __$AuthoredBindingAddressCopyWithImpl<$Res>
    implements _$AuthoredBindingAddressCopyWith<$Res> {
  __$AuthoredBindingAddressCopyWithImpl(this._self, this._then);

  final _AuthoredBindingAddress _self;
  final $Res Function(_AuthoredBindingAddress) _then;

/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? path = null,}) {
  return _then(_AuthoredBindingAddress(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as AuthoredBindingRoot,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<AuthoredPathStep>,
  ));
}

/// Create a copy of AuthoredBindingAddress
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingRootCopyWith<$Res> get root {

  return $AuthoredBindingRootCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

/// @nodoc
mixin _$AuthoredBindingUse {

 AuthoredBindingAddress get address; skir.PresentationId? get selectedPresentation;
/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredBindingUseCopyWith<AuthoredBindingUse> get copyWith => _$AuthoredBindingUseCopyWithImpl<AuthoredBindingUse>(this as AuthoredBindingUse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredBindingUse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredBindingUse&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.selectedPresentation, _this.selectedPresentation) || other.selectedPresentation == _this.selectedPresentation));
}


@override
int get hashCode {
  final _this = this as AuthoredBindingUse;
  return Object.hash(runtimeType,_this.address,_this.selectedPresentation);
}

@override
String toString() {
  final _this = this as AuthoredBindingUse;
  return 'AuthoredBindingUse(address: ${_this.address}, selectedPresentation: ${_this.selectedPresentation})';
}


}

/// @nodoc
abstract mixin class $AuthoredBindingUseCopyWith<$Res>  {
  factory $AuthoredBindingUseCopyWith(AuthoredBindingUse value, $Res Function(AuthoredBindingUse) _then) = _$AuthoredBindingUseCopyWithImpl;
@useResult
$Res call({
 AuthoredBindingAddress address, skir.PresentationId? selectedPresentation
});


$AuthoredBindingAddressCopyWith<$Res> get address;

}
/// @nodoc
class _$AuthoredBindingUseCopyWithImpl<$Res>
    implements $AuthoredBindingUseCopyWith<$Res> {
  _$AuthoredBindingUseCopyWithImpl(this._self, this._then);

  final AuthoredBindingUse _self;
  final $Res Function(AuthoredBindingUse) _then;

/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? address = null,Object? selectedPresentation = freezed,}) {
  return _then(AuthoredBindingUse(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,selectedPresentation: freezed == selectedPresentation ? _self.selectedPresentation : selectedPresentation // ignore: cast_nullable_to_non_nullable
as skir.PresentationId?,
  ));
}
/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds methods for matching patterns to [AuthoredBindingUse].
extension AuthoredBindingUsePatterns on AuthoredBindingUse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredBindingUse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredBindingUse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredBindingUse value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredBindingUse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredBindingUse value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredBindingUse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoredBindingAddress address,  skir.PresentationId? selectedPresentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredBindingUse() when $default != null:
return $default(_that.address,_that.selectedPresentation);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoredBindingAddress address,  skir.PresentationId? selectedPresentation)  $default,) {final _that = this;
switch (_that) {
case _AuthoredBindingUse():
return $default(_that.address,_that.selectedPresentation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoredBindingAddress address,  skir.PresentationId? selectedPresentation)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredBindingUse() when $default != null:
return $default(_that.address,_that.selectedPresentation);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredBindingUse implements AuthoredBindingUse {
  const _AuthoredBindingUse({required this.address, this.selectedPresentation});


@override final  AuthoredBindingAddress address;
@override final  skir.PresentationId? selectedPresentation;

/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredBindingUseCopyWith<_AuthoredBindingUse> get copyWith => __$AuthoredBindingUseCopyWithImpl<_AuthoredBindingUse>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredBindingUse&&(identical(other.address, address) || other.address == address)&&(identical(other.selectedPresentation, selectedPresentation) || other.selectedPresentation == selectedPresentation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,address,selectedPresentation);
}

@override
String toString() {
    return 'AuthoredBindingUse(address: $address, selectedPresentation: $selectedPresentation)';
}


}

/// @nodoc
abstract mixin class _$AuthoredBindingUseCopyWith<$Res> implements $AuthoredBindingUseCopyWith<$Res> {
  factory _$AuthoredBindingUseCopyWith(_AuthoredBindingUse value, $Res Function(_AuthoredBindingUse) _then) = __$AuthoredBindingUseCopyWithImpl;
@override @useResult
$Res call({
 AuthoredBindingAddress address, skir.PresentationId? selectedPresentation
});


@override $AuthoredBindingAddressCopyWith<$Res> get address;

}
/// @nodoc
class __$AuthoredBindingUseCopyWithImpl<$Res>
    implements _$AuthoredBindingUseCopyWith<$Res> {
  __$AuthoredBindingUseCopyWithImpl(this._self, this._then);

  final _AuthoredBindingUse _self;
  final $Res Function(_AuthoredBindingUse) _then;

/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? address = null,Object? selectedPresentation = freezed,}) {
  return _then(_AuthoredBindingUse(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,selectedPresentation: freezed == selectedPresentation ? _self.selectedPresentation : selectedPresentation // ignore: cast_nullable_to_non_nullable
as skir.PresentationId?,
  ));
}

/// Create a copy of AuthoredBindingUse
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}

/// @nodoc
mixin _$AuthoredPresentationIndex {

 List<AuthoredBindingUse> get uses;
/// Create a copy of AuthoredPresentationIndex
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<AuthoredPresentationIndex> get copyWith => _$AuthoredPresentationIndexCopyWithImpl<AuthoredPresentationIndex>(this as AuthoredPresentationIndex, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredPresentationIndex;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredPresentationIndex&&const DeepCollectionEquality().equals(other.uses, _this.uses));
}


@override
int get hashCode {
  final _this = this as AuthoredPresentationIndex;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.uses));
}

@override
String toString() {
  final _this = this as AuthoredPresentationIndex;
  return 'AuthoredPresentationIndex(uses: ${_this.uses})';
}


}

/// @nodoc
abstract mixin class $AuthoredPresentationIndexCopyWith<$Res>  {
  factory $AuthoredPresentationIndexCopyWith(AuthoredPresentationIndex value, $Res Function(AuthoredPresentationIndex) _then) = _$AuthoredPresentationIndexCopyWithImpl;
@useResult
$Res call({
 List<AuthoredBindingUse> uses
});




}
/// @nodoc
class _$AuthoredPresentationIndexCopyWithImpl<$Res>
    implements $AuthoredPresentationIndexCopyWith<$Res> {
  _$AuthoredPresentationIndexCopyWithImpl(this._self, this._then);

  final AuthoredPresentationIndex _self;
  final $Res Function(AuthoredPresentationIndex) _then;

/// Create a copy of AuthoredPresentationIndex
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uses = null,}) {
  return _then(AuthoredPresentationIndex(
uses: null == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as List<AuthoredBindingUse>,
  ));
}

}


/// Adds methods for matching patterns to [AuthoredPresentationIndex].
extension AuthoredPresentationIndexPatterns on AuthoredPresentationIndex {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredPresentationIndex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredPresentationIndex() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredPresentationIndex value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredPresentationIndex():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredPresentationIndex value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredPresentationIndex() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuthoredBindingUse> uses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredPresentationIndex() when $default != null:
return $default(_that.uses);case _:
  return orElse();

}
}
/// A `switch` style method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuthoredBindingUse> uses)  $default,) {final _that = this;
switch (_that) {
case _AuthoredPresentationIndex():
return $default(_that.uses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuthoredBindingUse> uses)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredPresentationIndex() when $default != null:
return $default(_that.uses);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredPresentationIndex extends AuthoredPresentationIndex {
  const _AuthoredPresentationIndex({required  List<AuthoredBindingUse> uses}): _uses = uses,super._();


 final  List<AuthoredBindingUse> _uses;
@override List<AuthoredBindingUse> get uses {
  if (_uses is EqualUnmodifiableListView) return _uses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uses);
}


/// Create a copy of AuthoredPresentationIndex
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredPresentationIndexCopyWith<_AuthoredPresentationIndex> get copyWith => __$AuthoredPresentationIndexCopyWithImpl<_AuthoredPresentationIndex>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredPresentationIndex&&const DeepCollectionEquality().equals(other.uses, _uses));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_uses));
}

@override
String toString() {
    return 'AuthoredPresentationIndex(uses: $uses)';
}


}

/// @nodoc
abstract mixin class _$AuthoredPresentationIndexCopyWith<$Res> implements $AuthoredPresentationIndexCopyWith<$Res> {
  factory _$AuthoredPresentationIndexCopyWith(_AuthoredPresentationIndex value, $Res Function(_AuthoredPresentationIndex) _then) = __$AuthoredPresentationIndexCopyWithImpl;
@override @useResult
$Res call({
 List<AuthoredBindingUse> uses
});




}
/// @nodoc
class __$AuthoredPresentationIndexCopyWithImpl<$Res>
    implements _$AuthoredPresentationIndexCopyWith<$Res> {
  __$AuthoredPresentationIndexCopyWithImpl(this._self, this._then);

  final _AuthoredPresentationIndex _self;
  final $Res Function(_AuthoredPresentationIndex) _then;

/// Create a copy of AuthoredPresentationIndex
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uses = null,}) {
  return _then(_AuthoredPresentationIndex(
uses: null == uses ? _self._uses : uses // ignore: cast_nullable_to_non_nullable
as List<AuthoredBindingUse>,
  ));
}


}

// dart format on
