// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'header_combination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedHeaderChain {

 PresentationHeader? get header; Set<(String, BindingReference?)> get suppressed;
/// Create a copy of ResolvedHeaderChain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedHeaderChainCopyWith<ResolvedHeaderChain> get copyWith => _$ResolvedHeaderChainCopyWithImpl<ResolvedHeaderChain>(this as ResolvedHeaderChain, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedHeaderChain&&(identical(other.header, header) || other.header == header)&&const DeepCollectionEquality().equals(other.suppressed, suppressed));
}


@override
int get hashCode => Object.hash(runtimeType,header,const DeepCollectionEquality().hash(suppressed));

@override
String toString() {
  return 'ResolvedHeaderChain(header: $header, suppressed: $suppressed)';
}


}

/// @nodoc
abstract mixin class $ResolvedHeaderChainCopyWith<$Res>  {
  factory $ResolvedHeaderChainCopyWith(ResolvedHeaderChain value, $Res Function(ResolvedHeaderChain) _then) = _$ResolvedHeaderChainCopyWithImpl;
@useResult
$Res call({
 PresentationHeader? header, Set<(String, BindingReference?)> suppressed
});


$PresentationHeaderCopyWith<$Res>? get header;

}
/// @nodoc
class _$ResolvedHeaderChainCopyWithImpl<$Res>
    implements $ResolvedHeaderChainCopyWith<$Res> {
  _$ResolvedHeaderChainCopyWithImpl(this._self, this._then);

  final ResolvedHeaderChain _self;
  final $Res Function(ResolvedHeaderChain) _then;

/// Create a copy of ResolvedHeaderChain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? header = freezed,Object? suppressed = null,}) {
  return _then(_self.copyWith(
header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as PresentationHeader?,suppressed: null == suppressed ? _self.suppressed : suppressed // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?)>,
  ));
}
/// Create a copy of ResolvedHeaderChain
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


/// Adds pattern-matching-related methods to [ResolvedHeaderChain].
extension ResolvedHeaderChainPatterns on ResolvedHeaderChain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedHeaderChain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedHeaderChain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedHeaderChain value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedHeaderChain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedHeaderChain value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedHeaderChain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationHeader? header,  Set<(String, BindingReference?)> suppressed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedHeaderChain() when $default != null:
return $default(_that.header,_that.suppressed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationHeader? header,  Set<(String, BindingReference?)> suppressed)  $default,) {final _that = this;
switch (_that) {
case _ResolvedHeaderChain():
return $default(_that.header,_that.suppressed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationHeader? header,  Set<(String, BindingReference?)> suppressed)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedHeaderChain() when $default != null:
return $default(_that.header,_that.suppressed);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedHeaderChain implements ResolvedHeaderChain {
  const _ResolvedHeaderChain({required this.header, required final  Set<(String, BindingReference?)> suppressed}): _suppressed = suppressed;
  

@override final  PresentationHeader? header;
 final  Set<(String, BindingReference?)> _suppressed;
@override Set<(String, BindingReference?)> get suppressed {
  if (_suppressed is EqualUnmodifiableSetView) return _suppressed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_suppressed);
}


/// Create a copy of ResolvedHeaderChain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedHeaderChainCopyWith<_ResolvedHeaderChain> get copyWith => __$ResolvedHeaderChainCopyWithImpl<_ResolvedHeaderChain>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedHeaderChain&&(identical(other.header, header) || other.header == header)&&const DeepCollectionEquality().equals(other._suppressed, _suppressed));
}


@override
int get hashCode => Object.hash(runtimeType,header,const DeepCollectionEquality().hash(_suppressed));

@override
String toString() {
  return 'ResolvedHeaderChain(header: $header, suppressed: $suppressed)';
}


}

/// @nodoc
abstract mixin class _$ResolvedHeaderChainCopyWith<$Res> implements $ResolvedHeaderChainCopyWith<$Res> {
  factory _$ResolvedHeaderChainCopyWith(_ResolvedHeaderChain value, $Res Function(_ResolvedHeaderChain) _then) = __$ResolvedHeaderChainCopyWithImpl;
@override @useResult
$Res call({
 PresentationHeader? header, Set<(String, BindingReference?)> suppressed
});


@override $PresentationHeaderCopyWith<$Res>? get header;

}
/// @nodoc
class __$ResolvedHeaderChainCopyWithImpl<$Res>
    implements _$ResolvedHeaderChainCopyWith<$Res> {
  __$ResolvedHeaderChainCopyWithImpl(this._self, this._then);

  final _ResolvedHeaderChain _self;
  final $Res Function(_ResolvedHeaderChain) _then;

/// Create a copy of ResolvedHeaderChain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? header = freezed,Object? suppressed = null,}) {
  return _then(_ResolvedHeaderChain(
header: freezed == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as PresentationHeader?,suppressed: null == suppressed ? _self._suppressed : suppressed // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?)>,
  ));
}

/// Create a copy of ResolvedHeaderChain
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

// dart format on
