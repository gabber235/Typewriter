// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_realm_runtime.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmActionCapabilities {

 EditorRealmActionExecutor get execute; FutureOr<void> Function(PanelInstruction instruction)? get executePanelInstruction;
/// Create a copy of RealmActionCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmActionCapabilitiesCopyWith<RealmActionCapabilities> get copyWith => _$RealmActionCapabilitiesCopyWithImpl<RealmActionCapabilities>(this as RealmActionCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmActionCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmActionCapabilities&&(identical(other.execute, _this.execute) || other.execute == _this.execute)&&(identical(other.executePanelInstruction, _this.executePanelInstruction) || other.executePanelInstruction == _this.executePanelInstruction));
}


@override
int get hashCode {
  final _this = this as RealmActionCapabilities;
  return Object.hash(runtimeType,_this.execute,_this.executePanelInstruction);
}

@override
String toString() {
  final _this = this as RealmActionCapabilities;
  return 'RealmActionCapabilities(execute: ${_this.execute}, executePanelInstruction: ${_this.executePanelInstruction})';
}


}

/// @nodoc
abstract mixin class $RealmActionCapabilitiesCopyWith<$Res>  {
  factory $RealmActionCapabilitiesCopyWith(RealmActionCapabilities value, $Res Function(RealmActionCapabilities) _then) = _$RealmActionCapabilitiesCopyWithImpl;
@useResult
$Res call({
 EditorRealmActionExecutor execute, FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction
});




}
/// @nodoc
class _$RealmActionCapabilitiesCopyWithImpl<$Res>
    implements $RealmActionCapabilitiesCopyWith<$Res> {
  _$RealmActionCapabilitiesCopyWithImpl(this._self, this._then);

  final RealmActionCapabilities _self;
  final $Res Function(RealmActionCapabilities) _then;

/// Create a copy of RealmActionCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? execute = null,Object? executePanelInstruction = freezed,}) {
  return _then(RealmActionCapabilities(
execute: null == execute ? _self.execute : execute // ignore: cast_nullable_to_non_nullable
as EditorRealmActionExecutor,executePanelInstruction: freezed == executePanelInstruction ? _self.executePanelInstruction : executePanelInstruction // ignore: cast_nullable_to_non_nullable
as FutureOr<void> Function(PanelInstruction instruction)?,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmActionCapabilities].
extension RealmActionCapabilitiesPatterns on RealmActionCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmActionCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmActionCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmActionCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _RealmActionCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmActionCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _RealmActionCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorRealmActionExecutor execute,  FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmActionCapabilities() when $default != null:
return $default(_that.execute,_that.executePanelInstruction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorRealmActionExecutor execute,  FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction)  $default,) {final _that = this;
switch (_that) {
case _RealmActionCapabilities():
return $default(_that.execute,_that.executePanelInstruction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorRealmActionExecutor execute,  FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction)?  $default,) {final _that = this;
switch (_that) {
case _RealmActionCapabilities() when $default != null:
return $default(_that.execute,_that.executePanelInstruction);case _:
  return null;

}
}

}

/// @nodoc


class _RealmActionCapabilities implements RealmActionCapabilities {
  const _RealmActionCapabilities({required this.execute, this.executePanelInstruction});
  

@override final  EditorRealmActionExecutor execute;
@override final  FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction;

/// Create a copy of RealmActionCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmActionCapabilitiesCopyWith<_RealmActionCapabilities> get copyWith => __$RealmActionCapabilitiesCopyWithImpl<_RealmActionCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmActionCapabilities&&(identical(other.execute, execute) || other.execute == execute)&&(identical(other.executePanelInstruction, executePanelInstruction) || other.executePanelInstruction == executePanelInstruction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,execute,executePanelInstruction);
}

@override
String toString() {
    return 'RealmActionCapabilities(execute: $execute, executePanelInstruction: $executePanelInstruction)';
}


}

/// @nodoc
abstract mixin class _$RealmActionCapabilitiesCopyWith<$Res> implements $RealmActionCapabilitiesCopyWith<$Res> {
  factory _$RealmActionCapabilitiesCopyWith(_RealmActionCapabilities value, $Res Function(_RealmActionCapabilities) _then) = __$RealmActionCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 EditorRealmActionExecutor execute, FutureOr<void> Function(PanelInstruction instruction)? executePanelInstruction
});




}
/// @nodoc
class __$RealmActionCapabilitiesCopyWithImpl<$Res>
    implements _$RealmActionCapabilitiesCopyWith<$Res> {
  __$RealmActionCapabilitiesCopyWithImpl(this._self, this._then);

  final _RealmActionCapabilities _self;
  final $Res Function(_RealmActionCapabilities) _then;

/// Create a copy of RealmActionCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? execute = null,Object? executePanelInstruction = freezed,}) {
  return _then(_RealmActionCapabilities(
execute: null == execute ? _self.execute : execute // ignore: cast_nullable_to_non_nullable
as EditorRealmActionExecutor,executePanelInstruction: freezed == executePanelInstruction ? _self.executePanelInstruction : executePanelInstruction // ignore: cast_nullable_to_non_nullable
as FutureOr<void> Function(PanelInstruction instruction)?,
  ));
}


}

/// @nodoc
mixin _$RealmPresentationSearchCapabilities {

 RealmPresentationSearchSourceBuilder get source;
/// Create a copy of RealmPresentationSearchCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPresentationSearchCapabilitiesCopyWith<RealmPresentationSearchCapabilities> get copyWith => _$RealmPresentationSearchCapabilitiesCopyWithImpl<RealmPresentationSearchCapabilities>(this as RealmPresentationSearchCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPresentationSearchCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPresentationSearchCapabilities&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as RealmPresentationSearchCapabilities;
  return Object.hash(runtimeType,_this.source);
}

@override
String toString() {
  final _this = this as RealmPresentationSearchCapabilities;
  return 'RealmPresentationSearchCapabilities(source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $RealmPresentationSearchCapabilitiesCopyWith<$Res>  {
  factory $RealmPresentationSearchCapabilitiesCopyWith(RealmPresentationSearchCapabilities value, $Res Function(RealmPresentationSearchCapabilities) _then) = _$RealmPresentationSearchCapabilitiesCopyWithImpl;
@useResult
$Res call({
 RealmPresentationSearchSourceBuilder source
});




}
/// @nodoc
class _$RealmPresentationSearchCapabilitiesCopyWithImpl<$Res>
    implements $RealmPresentationSearchCapabilitiesCopyWith<$Res> {
  _$RealmPresentationSearchCapabilitiesCopyWithImpl(this._self, this._then);

  final RealmPresentationSearchCapabilities _self;
  final $Res Function(RealmPresentationSearchCapabilities) _then;

/// Create a copy of RealmPresentationSearchCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,}) {
  return _then(RealmPresentationSearchCapabilities(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchSourceBuilder,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmPresentationSearchCapabilities].
extension RealmPresentationSearchCapabilitiesPatterns on RealmPresentationSearchCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPresentationSearchCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPresentationSearchCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPresentationSearchCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmPresentationSearchSourceBuilder source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities() when $default != null:
return $default(_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmPresentationSearchSourceBuilder source)  $default,) {final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities():
return $default(_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmPresentationSearchSourceBuilder source)?  $default,) {final _that = this;
switch (_that) {
case _RealmPresentationSearchCapabilities() when $default != null:
return $default(_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPresentationSearchCapabilities implements RealmPresentationSearchCapabilities {
  const _RealmPresentationSearchCapabilities({required this.source});
  

@override final  RealmPresentationSearchSourceBuilder source;

/// Create a copy of RealmPresentationSearchCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPresentationSearchCapabilitiesCopyWith<_RealmPresentationSearchCapabilities> get copyWith => __$RealmPresentationSearchCapabilitiesCopyWithImpl<_RealmPresentationSearchCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPresentationSearchCapabilities&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source);
}

@override
String toString() {
    return 'RealmPresentationSearchCapabilities(source: $source)';
}


}

/// @nodoc
abstract mixin class _$RealmPresentationSearchCapabilitiesCopyWith<$Res> implements $RealmPresentationSearchCapabilitiesCopyWith<$Res> {
  factory _$RealmPresentationSearchCapabilitiesCopyWith(_RealmPresentationSearchCapabilities value, $Res Function(_RealmPresentationSearchCapabilities) _then) = __$RealmPresentationSearchCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 RealmPresentationSearchSourceBuilder source
});




}
/// @nodoc
class __$RealmPresentationSearchCapabilitiesCopyWithImpl<$Res>
    implements _$RealmPresentationSearchCapabilitiesCopyWith<$Res> {
  __$RealmPresentationSearchCapabilitiesCopyWithImpl(this._self, this._then);

  final _RealmPresentationSearchCapabilities _self;
  final $Res Function(_RealmPresentationSearchCapabilities) _then;

/// Create a copy of RealmPresentationSearchCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(_RealmPresentationSearchCapabilities(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchSourceBuilder,
  ));
}


}

/// @nodoc
mixin _$ReferenceAuthoringCapabilities {

 ReferenceSearchSourceBuilder get search; ReferenceResourceResolver get resolve; ReferenceCandidatePolicyRegistry get policies;
/// Create a copy of ReferenceAuthoringCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceAuthoringCapabilitiesCopyWith<ReferenceAuthoringCapabilities> get copyWith => _$ReferenceAuthoringCapabilitiesCopyWithImpl<ReferenceAuthoringCapabilities>(this as ReferenceAuthoringCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReferenceAuthoringCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceAuthoringCapabilities&&(identical(other.search, _this.search) || other.search == _this.search)&&(identical(other.resolve, _this.resolve) || other.resolve == _this.resolve)&&(identical(other.policies, _this.policies) || other.policies == _this.policies));
}


@override
int get hashCode {
  final _this = this as ReferenceAuthoringCapabilities;
  return Object.hash(runtimeType,_this.search,_this.resolve,_this.policies);
}

@override
String toString() {
  final _this = this as ReferenceAuthoringCapabilities;
  return 'ReferenceAuthoringCapabilities(search: ${_this.search}, resolve: ${_this.resolve}, policies: ${_this.policies})';
}


}

/// @nodoc
abstract mixin class $ReferenceAuthoringCapabilitiesCopyWith<$Res>  {
  factory $ReferenceAuthoringCapabilitiesCopyWith(ReferenceAuthoringCapabilities value, $Res Function(ReferenceAuthoringCapabilities) _then) = _$ReferenceAuthoringCapabilitiesCopyWithImpl;
@useResult
$Res call({
 ReferenceSearchSourceBuilder search, ReferenceResourceResolver resolve, ReferenceCandidatePolicyRegistry policies
});




}
/// @nodoc
class _$ReferenceAuthoringCapabilitiesCopyWithImpl<$Res>
    implements $ReferenceAuthoringCapabilitiesCopyWith<$Res> {
  _$ReferenceAuthoringCapabilitiesCopyWithImpl(this._self, this._then);

  final ReferenceAuthoringCapabilities _self;
  final $Res Function(ReferenceAuthoringCapabilities) _then;

/// Create a copy of ReferenceAuthoringCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? search = null,Object? resolve = null,Object? policies = null,}) {
  return _then(ReferenceAuthoringCapabilities(
search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as ReferenceSearchSourceBuilder,resolve: null == resolve ? _self.resolve : resolve // ignore: cast_nullable_to_non_nullable
as ReferenceResourceResolver,policies: null == policies ? _self.policies : policies // ignore: cast_nullable_to_non_nullable
as ReferenceCandidatePolicyRegistry,
  ));
}

}


/// Adds pattern-matching-related methods to [ReferenceAuthoringCapabilities].
extension ReferenceAuthoringCapabilitiesPatterns on ReferenceAuthoringCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferenceAuthoringCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferenceAuthoringCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferenceAuthoringCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReferenceSearchSourceBuilder search,  ReferenceResourceResolver resolve,  ReferenceCandidatePolicyRegistry policies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities() when $default != null:
return $default(_that.search,_that.resolve,_that.policies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReferenceSearchSourceBuilder search,  ReferenceResourceResolver resolve,  ReferenceCandidatePolicyRegistry policies)  $default,) {final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities():
return $default(_that.search,_that.resolve,_that.policies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReferenceSearchSourceBuilder search,  ReferenceResourceResolver resolve,  ReferenceCandidatePolicyRegistry policies)?  $default,) {final _that = this;
switch (_that) {
case _ReferenceAuthoringCapabilities() when $default != null:
return $default(_that.search,_that.resolve,_that.policies);case _:
  return null;

}
}

}

/// @nodoc


class _ReferenceAuthoringCapabilities implements ReferenceAuthoringCapabilities {
  const _ReferenceAuthoringCapabilities({required this.search, required this.resolve, this.policies = const ReferenceCandidatePolicyRegistry()});
  

@override final  ReferenceSearchSourceBuilder search;
@override final  ReferenceResourceResolver resolve;
@override@JsonKey() final  ReferenceCandidatePolicyRegistry policies;

/// Create a copy of ReferenceAuthoringCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferenceAuthoringCapabilitiesCopyWith<_ReferenceAuthoringCapabilities> get copyWith => __$ReferenceAuthoringCapabilitiesCopyWithImpl<_ReferenceAuthoringCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferenceAuthoringCapabilities&&(identical(other.search, search) || other.search == search)&&(identical(other.resolve, resolve) || other.resolve == resolve)&&(identical(other.policies, policies) || other.policies == policies));
}


@override
int get hashCode {
    return Object.hash(runtimeType,search,resolve,policies);
}

@override
String toString() {
    return 'ReferenceAuthoringCapabilities(search: $search, resolve: $resolve, policies: $policies)';
}


}

/// @nodoc
abstract mixin class _$ReferenceAuthoringCapabilitiesCopyWith<$Res> implements $ReferenceAuthoringCapabilitiesCopyWith<$Res> {
  factory _$ReferenceAuthoringCapabilitiesCopyWith(_ReferenceAuthoringCapabilities value, $Res Function(_ReferenceAuthoringCapabilities) _then) = __$ReferenceAuthoringCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 ReferenceSearchSourceBuilder search, ReferenceResourceResolver resolve, ReferenceCandidatePolicyRegistry policies
});




}
/// @nodoc
class __$ReferenceAuthoringCapabilitiesCopyWithImpl<$Res>
    implements _$ReferenceAuthoringCapabilitiesCopyWith<$Res> {
  __$ReferenceAuthoringCapabilitiesCopyWithImpl(this._self, this._then);

  final _ReferenceAuthoringCapabilities _self;
  final $Res Function(_ReferenceAuthoringCapabilities) _then;

/// Create a copy of ReferenceAuthoringCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? search = null,Object? resolve = null,Object? policies = null,}) {
  return _then(_ReferenceAuthoringCapabilities(
search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as ReferenceSearchSourceBuilder,resolve: null == resolve ? _self.resolve : resolve // ignore: cast_nullable_to_non_nullable
as ReferenceResourceResolver,policies: null == policies ? _self.policies : policies // ignore: cast_nullable_to_non_nullable
as ReferenceCandidatePolicyRegistry,
  ));
}


}

/// @nodoc
mixin _$EditorHostCapabilities {

 RealmActionCapabilities? get realmActions; RealmPresentationSearchCapabilities? get presentationSearch; ReferenceAuthoringCapabilities? get references;
/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorHostCapabilitiesCopyWith<EditorHostCapabilities> get copyWith => _$EditorHostCapabilitiesCopyWithImpl<EditorHostCapabilities>(this as EditorHostCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorHostCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorHostCapabilities&&(identical(other.realmActions, _this.realmActions) || other.realmActions == _this.realmActions)&&(identical(other.presentationSearch, _this.presentationSearch) || other.presentationSearch == _this.presentationSearch)&&(identical(other.references, _this.references) || other.references == _this.references));
}


@override
int get hashCode {
  final _this = this as EditorHostCapabilities;
  return Object.hash(runtimeType,_this.realmActions,_this.presentationSearch,_this.references);
}

@override
String toString() {
  final _this = this as EditorHostCapabilities;
  return 'EditorHostCapabilities(realmActions: ${_this.realmActions}, presentationSearch: ${_this.presentationSearch}, references: ${_this.references})';
}


}

/// @nodoc
abstract mixin class $EditorHostCapabilitiesCopyWith<$Res>  {
  factory $EditorHostCapabilitiesCopyWith(EditorHostCapabilities value, $Res Function(EditorHostCapabilities) _then) = _$EditorHostCapabilitiesCopyWithImpl;
@useResult
$Res call({
 RealmActionCapabilities? realmActions, RealmPresentationSearchCapabilities? presentationSearch, ReferenceAuthoringCapabilities? references
});


$RealmActionCapabilitiesCopyWith<$Res>? get realmActions;$RealmPresentationSearchCapabilitiesCopyWith<$Res>? get presentationSearch;$ReferenceAuthoringCapabilitiesCopyWith<$Res>? get references;

}
/// @nodoc
class _$EditorHostCapabilitiesCopyWithImpl<$Res>
    implements $EditorHostCapabilitiesCopyWith<$Res> {
  _$EditorHostCapabilitiesCopyWithImpl(this._self, this._then);

  final EditorHostCapabilities _self;
  final $Res Function(EditorHostCapabilities) _then;

/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? realmActions = freezed,Object? presentationSearch = freezed,Object? references = freezed,}) {
  return _then(EditorHostCapabilities(
realmActions: freezed == realmActions ? _self.realmActions : realmActions // ignore: cast_nullable_to_non_nullable
as RealmActionCapabilities?,presentationSearch: freezed == presentationSearch ? _self.presentationSearch : presentationSearch // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchCapabilities?,references: freezed == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as ReferenceAuthoringCapabilities?,
  ));
}
/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionCapabilitiesCopyWith<$Res>? get realmActions {
    if (_self.realmActions == null) {
    return null;
  }

  return $RealmActionCapabilitiesCopyWith<$Res>(_self.realmActions!, (value) {
    return _then(_self.copyWith(realmActions: value));
  });
}/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPresentationSearchCapabilitiesCopyWith<$Res>? get presentationSearch {
    if (_self.presentationSearch == null) {
    return null;
  }

  return $RealmPresentationSearchCapabilitiesCopyWith<$Res>(_self.presentationSearch!, (value) {
    return _then(_self.copyWith(presentationSearch: value));
  });
}/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceAuthoringCapabilitiesCopyWith<$Res>? get references {
    if (_self.references == null) {
    return null;
  }

  return $ReferenceAuthoringCapabilitiesCopyWith<$Res>(_self.references!, (value) {
    return _then(_self.copyWith(references: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorHostCapabilities].
extension EditorHostCapabilitiesPatterns on EditorHostCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorHostCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorHostCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorHostCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _EditorHostCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorHostCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _EditorHostCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmActionCapabilities? realmActions,  RealmPresentationSearchCapabilities? presentationSearch,  ReferenceAuthoringCapabilities? references)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorHostCapabilities() when $default != null:
return $default(_that.realmActions,_that.presentationSearch,_that.references);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmActionCapabilities? realmActions,  RealmPresentationSearchCapabilities? presentationSearch,  ReferenceAuthoringCapabilities? references)  $default,) {final _that = this;
switch (_that) {
case _EditorHostCapabilities():
return $default(_that.realmActions,_that.presentationSearch,_that.references);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmActionCapabilities? realmActions,  RealmPresentationSearchCapabilities? presentationSearch,  ReferenceAuthoringCapabilities? references)?  $default,) {final _that = this;
switch (_that) {
case _EditorHostCapabilities() when $default != null:
return $default(_that.realmActions,_that.presentationSearch,_that.references);case _:
  return null;

}
}

}

/// @nodoc


class _EditorHostCapabilities implements EditorHostCapabilities {
  const _EditorHostCapabilities({this.realmActions, this.presentationSearch, this.references});
  

@override final  RealmActionCapabilities? realmActions;
@override final  RealmPresentationSearchCapabilities? presentationSearch;
@override final  ReferenceAuthoringCapabilities? references;

/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorHostCapabilitiesCopyWith<_EditorHostCapabilities> get copyWith => __$EditorHostCapabilitiesCopyWithImpl<_EditorHostCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorHostCapabilities&&(identical(other.realmActions, realmActions) || other.realmActions == realmActions)&&(identical(other.presentationSearch, presentationSearch) || other.presentationSearch == presentationSearch)&&(identical(other.references, references) || other.references == references));
}


@override
int get hashCode {
    return Object.hash(runtimeType,realmActions,presentationSearch,references);
}

@override
String toString() {
    return 'EditorHostCapabilities(realmActions: $realmActions, presentationSearch: $presentationSearch, references: $references)';
}


}

/// @nodoc
abstract mixin class _$EditorHostCapabilitiesCopyWith<$Res> implements $EditorHostCapabilitiesCopyWith<$Res> {
  factory _$EditorHostCapabilitiesCopyWith(_EditorHostCapabilities value, $Res Function(_EditorHostCapabilities) _then) = __$EditorHostCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 RealmActionCapabilities? realmActions, RealmPresentationSearchCapabilities? presentationSearch, ReferenceAuthoringCapabilities? references
});


@override $RealmActionCapabilitiesCopyWith<$Res>? get realmActions;@override $RealmPresentationSearchCapabilitiesCopyWith<$Res>? get presentationSearch;@override $ReferenceAuthoringCapabilitiesCopyWith<$Res>? get references;

}
/// @nodoc
class __$EditorHostCapabilitiesCopyWithImpl<$Res>
    implements _$EditorHostCapabilitiesCopyWith<$Res> {
  __$EditorHostCapabilitiesCopyWithImpl(this._self, this._then);

  final _EditorHostCapabilities _self;
  final $Res Function(_EditorHostCapabilities) _then;

/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realmActions = freezed,Object? presentationSearch = freezed,Object? references = freezed,}) {
  return _then(_EditorHostCapabilities(
realmActions: freezed == realmActions ? _self.realmActions : realmActions // ignore: cast_nullable_to_non_nullable
as RealmActionCapabilities?,presentationSearch: freezed == presentationSearch ? _self.presentationSearch : presentationSearch // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchCapabilities?,references: freezed == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as ReferenceAuthoringCapabilities?,
  ));
}

/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionCapabilitiesCopyWith<$Res>? get realmActions {
    if (_self.realmActions == null) {
    return null;
  }

  return $RealmActionCapabilitiesCopyWith<$Res>(_self.realmActions!, (value) {
    return _then(_self.copyWith(realmActions: value));
  });
}/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPresentationSearchCapabilitiesCopyWith<$Res>? get presentationSearch {
    if (_self.presentationSearch == null) {
    return null;
  }

  return $RealmPresentationSearchCapabilitiesCopyWith<$Res>(_self.presentationSearch!, (value) {
    return _then(_self.copyWith(presentationSearch: value));
  });
}/// Create a copy of EditorHostCapabilities
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceAuthoringCapabilitiesCopyWith<$Res>? get references {
    if (_self.references == null) {
    return null;
  }

  return $ReferenceAuthoringCapabilitiesCopyWith<$Res>(_self.references!, (value) {
    return _then(_self.copyWith(references: value));
  });
}
}

/// @nodoc
mixin _$EditorRealmRuntime {

 RealmActionCapabilities get actions; RealmPresentationSearchCapabilities get presentationSearch; ReferenceAuthoringCapabilities get references;
/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorRealmRuntimeCopyWith<EditorRealmRuntime> get copyWith => _$EditorRealmRuntimeCopyWithImpl<EditorRealmRuntime>(this as EditorRealmRuntime, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorRealmRuntime;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorRealmRuntime&&(identical(other.actions, _this.actions) || other.actions == _this.actions)&&(identical(other.presentationSearch, _this.presentationSearch) || other.presentationSearch == _this.presentationSearch)&&(identical(other.references, _this.references) || other.references == _this.references));
}


@override
int get hashCode {
  final _this = this as EditorRealmRuntime;
  return Object.hash(runtimeType,_this.actions,_this.presentationSearch,_this.references);
}

@override
String toString() {
  final _this = this as EditorRealmRuntime;
  return 'EditorRealmRuntime(actions: ${_this.actions}, presentationSearch: ${_this.presentationSearch}, references: ${_this.references})';
}


}

/// @nodoc
abstract mixin class $EditorRealmRuntimeCopyWith<$Res>  {
  factory $EditorRealmRuntimeCopyWith(EditorRealmRuntime value, $Res Function(EditorRealmRuntime) _then) = _$EditorRealmRuntimeCopyWithImpl;
@useResult
$Res call({
 RealmActionCapabilities actions, RealmPresentationSearchCapabilities presentationSearch, ReferenceAuthoringCapabilities references
});


$RealmActionCapabilitiesCopyWith<$Res> get actions;$RealmPresentationSearchCapabilitiesCopyWith<$Res> get presentationSearch;$ReferenceAuthoringCapabilitiesCopyWith<$Res> get references;

}
/// @nodoc
class _$EditorRealmRuntimeCopyWithImpl<$Res>
    implements $EditorRealmRuntimeCopyWith<$Res> {
  _$EditorRealmRuntimeCopyWithImpl(this._self, this._then);

  final EditorRealmRuntime _self;
  final $Res Function(EditorRealmRuntime) _then;

/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actions = null,Object? presentationSearch = null,Object? references = null,}) {
  return _then(EditorRealmRuntime(
actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as RealmActionCapabilities,presentationSearch: null == presentationSearch ? _self.presentationSearch : presentationSearch // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchCapabilities,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as ReferenceAuthoringCapabilities,
  ));
}
/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionCapabilitiesCopyWith<$Res> get actions {
  
  return $RealmActionCapabilitiesCopyWith<$Res>(_self.actions, (value) {
    return _then(_self.copyWith(actions: value));
  });
}/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPresentationSearchCapabilitiesCopyWith<$Res> get presentationSearch {
  
  return $RealmPresentationSearchCapabilitiesCopyWith<$Res>(_self.presentationSearch, (value) {
    return _then(_self.copyWith(presentationSearch: value));
  });
}/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceAuthoringCapabilitiesCopyWith<$Res> get references {
  
  return $ReferenceAuthoringCapabilitiesCopyWith<$Res>(_self.references, (value) {
    return _then(_self.copyWith(references: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorRealmRuntime].
extension EditorRealmRuntimePatterns on EditorRealmRuntime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorRealmRuntime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorRealmRuntime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorRealmRuntime value)  $default,){
final _that = this;
switch (_that) {
case _EditorRealmRuntime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorRealmRuntime value)?  $default,){
final _that = this;
switch (_that) {
case _EditorRealmRuntime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmActionCapabilities actions,  RealmPresentationSearchCapabilities presentationSearch,  ReferenceAuthoringCapabilities references)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorRealmRuntime() when $default != null:
return $default(_that.actions,_that.presentationSearch,_that.references);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmActionCapabilities actions,  RealmPresentationSearchCapabilities presentationSearch,  ReferenceAuthoringCapabilities references)  $default,) {final _that = this;
switch (_that) {
case _EditorRealmRuntime():
return $default(_that.actions,_that.presentationSearch,_that.references);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmActionCapabilities actions,  RealmPresentationSearchCapabilities presentationSearch,  ReferenceAuthoringCapabilities references)?  $default,) {final _that = this;
switch (_that) {
case _EditorRealmRuntime() when $default != null:
return $default(_that.actions,_that.presentationSearch,_that.references);case _:
  return null;

}
}

}

/// @nodoc


class _EditorRealmRuntime extends EditorRealmRuntime {
  const _EditorRealmRuntime({required this.actions, required this.presentationSearch, required this.references}): super._();
  

@override final  RealmActionCapabilities actions;
@override final  RealmPresentationSearchCapabilities presentationSearch;
@override final  ReferenceAuthoringCapabilities references;

/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorRealmRuntimeCopyWith<_EditorRealmRuntime> get copyWith => __$EditorRealmRuntimeCopyWithImpl<_EditorRealmRuntime>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorRealmRuntime&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.presentationSearch, presentationSearch) || other.presentationSearch == presentationSearch)&&(identical(other.references, references) || other.references == references));
}


@override
int get hashCode {
    return Object.hash(runtimeType,actions,presentationSearch,references);
}

@override
String toString() {
    return 'EditorRealmRuntime(actions: $actions, presentationSearch: $presentationSearch, references: $references)';
}


}

/// @nodoc
abstract mixin class _$EditorRealmRuntimeCopyWith<$Res> implements $EditorRealmRuntimeCopyWith<$Res> {
  factory _$EditorRealmRuntimeCopyWith(_EditorRealmRuntime value, $Res Function(_EditorRealmRuntime) _then) = __$EditorRealmRuntimeCopyWithImpl;
@override @useResult
$Res call({
 RealmActionCapabilities actions, RealmPresentationSearchCapabilities presentationSearch, ReferenceAuthoringCapabilities references
});


@override $RealmActionCapabilitiesCopyWith<$Res> get actions;@override $RealmPresentationSearchCapabilitiesCopyWith<$Res> get presentationSearch;@override $ReferenceAuthoringCapabilitiesCopyWith<$Res> get references;

}
/// @nodoc
class __$EditorRealmRuntimeCopyWithImpl<$Res>
    implements _$EditorRealmRuntimeCopyWith<$Res> {
  __$EditorRealmRuntimeCopyWithImpl(this._self, this._then);

  final _EditorRealmRuntime _self;
  final $Res Function(_EditorRealmRuntime) _then;

/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actions = null,Object? presentationSearch = null,Object? references = null,}) {
  return _then(_EditorRealmRuntime(
actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as RealmActionCapabilities,presentationSearch: null == presentationSearch ? _self.presentationSearch : presentationSearch // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchCapabilities,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as ReferenceAuthoringCapabilities,
  ));
}

/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionCapabilitiesCopyWith<$Res> get actions {
  
  return $RealmActionCapabilitiesCopyWith<$Res>(_self.actions, (value) {
    return _then(_self.copyWith(actions: value));
  });
}/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPresentationSearchCapabilitiesCopyWith<$Res> get presentationSearch {
  
  return $RealmPresentationSearchCapabilitiesCopyWith<$Res>(_self.presentationSearch, (value) {
    return _then(_self.copyWith(presentationSearch: value));
  });
}/// Create a copy of EditorRealmRuntime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferenceAuthoringCapabilitiesCopyWith<$Res> get references {
  
  return $ReferenceAuthoringCapabilitiesCopyWith<$Res>(_self.references, (value) {
    return _then(_self.copyWith(references: value));
  });
}
}

// dart format on
