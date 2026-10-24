// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_search_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScopeSelector {

 String get key; OwnerRoute get route;
/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopeSelectorCopyWith<ScopeSelector> get copyWith => _$ScopeSelectorCopyWithImpl<ScopeSelector>(this as ScopeSelector, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScopeSelector;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopeSelector&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.route, _this.route) || other.route == _this.route));
}


@override
int get hashCode {
  final _this = this as ScopeSelector;
  return Object.hash(runtimeType,_this.key,_this.route);
}

@override
String toString() {
  final _this = this as ScopeSelector;
  return 'ScopeSelector(key: ${_this.key}, route: ${_this.route})';
}


}

/// @nodoc
abstract mixin class $ScopeSelectorCopyWith<$Res>  {
  factory $ScopeSelectorCopyWith(ScopeSelector value, $Res Function(ScopeSelector) _then) = _$ScopeSelectorCopyWithImpl;
@useResult
$Res call({
 String key, OwnerRoute route
});


$OwnerRouteCopyWith<$Res> get route;

}
/// @nodoc
class _$ScopeSelectorCopyWithImpl<$Res>
    implements $ScopeSelectorCopyWith<$Res> {
  _$ScopeSelectorCopyWithImpl(this._self, this._then);

  final ScopeSelector _self;
  final $Res Function(ScopeSelector) _then;

/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? route = null,}) {
  return _then(ScopeSelector(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as OwnerRoute,
  ));
}
/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerRouteCopyWith<$Res> get route {
  
  return $OwnerRouteCopyWith<$Res>(_self.route, (value) {
    return _then(_self.copyWith(route: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScopeSelector].
extension ScopeSelectorPatterns on ScopeSelector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScopeSelector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScopeSelector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScopeSelector value)  $default,){
final _that = this;
switch (_that) {
case _ScopeSelector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScopeSelector value)?  $default,){
final _that = this;
switch (_that) {
case _ScopeSelector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  OwnerRoute route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScopeSelector() when $default != null:
return $default(_that.key,_that.route);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  OwnerRoute route)  $default,) {final _that = this;
switch (_that) {
case _ScopeSelector():
return $default(_that.key,_that.route);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  OwnerRoute route)?  $default,) {final _that = this;
switch (_that) {
case _ScopeSelector() when $default != null:
return $default(_that.key,_that.route);case _:
  return null;

}
}

}

/// @nodoc


class _ScopeSelector implements ScopeSelector {
  const _ScopeSelector({required this.key, required this.route});
  

@override final  String key;
@override final  OwnerRoute route;

/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopeSelectorCopyWith<_ScopeSelector> get copyWith => __$ScopeSelectorCopyWithImpl<_ScopeSelector>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopeSelector&&(identical(other.key, key) || other.key == key)&&(identical(other.route, route) || other.route == route));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,route);
}

@override
String toString() {
    return 'ScopeSelector(key: $key, route: $route)';
}


}

/// @nodoc
abstract mixin class _$ScopeSelectorCopyWith<$Res> implements $ScopeSelectorCopyWith<$Res> {
  factory _$ScopeSelectorCopyWith(_ScopeSelector value, $Res Function(_ScopeSelector) _then) = __$ScopeSelectorCopyWithImpl;
@override @useResult
$Res call({
 String key, OwnerRoute route
});


@override $OwnerRouteCopyWith<$Res> get route;

}
/// @nodoc
class __$ScopeSelectorCopyWithImpl<$Res>
    implements _$ScopeSelectorCopyWith<$Res> {
  __$ScopeSelectorCopyWithImpl(this._self, this._then);

  final _ScopeSelector _self;
  final $Res Function(_ScopeSelector) _then;

/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? route = null,}) {
  return _then(_ScopeSelector(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as OwnerRoute,
  ));
}

/// Create a copy of ScopeSelector
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerRouteCopyWith<$Res> get route {
  
  return $OwnerRouteCopyWith<$Res>(_self.route, (value) {
    return _then(_self.copyWith(route: value));
  });
}
}

/// @nodoc
mixin _$ScopeResolution {

 ScopeSelector get selector; String get text;
/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopeResolutionCopyWith<ScopeResolution> get copyWith => _$ScopeResolutionCopyWithImpl<ScopeResolution>(this as ScopeResolution, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScopeResolution;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopeResolution&&(identical(other.selector, _this.selector) || other.selector == _this.selector)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as ScopeResolution;
  return Object.hash(runtimeType,_this.selector,_this.text);
}

@override
String toString() {
  final _this = this as ScopeResolution;
  return 'ScopeResolution(selector: ${_this.selector}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $ScopeResolutionCopyWith<$Res>  {
  factory $ScopeResolutionCopyWith(ScopeResolution value, $Res Function(ScopeResolution) _then) = _$ScopeResolutionCopyWithImpl;
@useResult
$Res call({
 ScopeSelector selector, String text
});


$ScopeSelectorCopyWith<$Res> get selector;

}
/// @nodoc
class _$ScopeResolutionCopyWithImpl<$Res>
    implements $ScopeResolutionCopyWith<$Res> {
  _$ScopeResolutionCopyWithImpl(this._self, this._then);

  final ScopeResolution _self;
  final $Res Function(ScopeResolution) _then;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selector = null,Object? text = null,}) {
  return _then(_self.copyWith(
selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as ScopeSelector,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopeSelectorCopyWith<$Res> get selector {
  
  return $ScopeSelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScopeResolution].
extension ScopeResolutionPatterns on ScopeResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ScopeMatched value)?  matched,TResult Function( ScopeAmbiguous value)?  ambiguous,TResult Function( ScopeUnmatched value)?  unmatched,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ScopeMatched() when matched != null:
return matched(_that);case ScopeAmbiguous() when ambiguous != null:
return ambiguous(_that);case ScopeUnmatched() when unmatched != null:
return unmatched(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ScopeMatched value)  matched,required TResult Function( ScopeAmbiguous value)  ambiguous,required TResult Function( ScopeUnmatched value)  unmatched,}){
final _that = this;
switch (_that) {
case ScopeMatched():
return matched(_that);case ScopeAmbiguous():
return ambiguous(_that);case ScopeUnmatched():
return unmatched(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ScopeMatched value)?  matched,TResult? Function( ScopeAmbiguous value)?  ambiguous,TResult? Function( ScopeUnmatched value)?  unmatched,}){
final _that = this;
switch (_that) {
case ScopeMatched() when matched != null:
return matched(_that);case ScopeAmbiguous() when ambiguous != null:
return ambiguous(_that);case ScopeUnmatched() when unmatched != null:
return unmatched(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ScopeSelector selector,  String text,  skir.ResourceId target)?  matched,TResult Function( ScopeSelector selector,  String text,  Set<skir.ResourceId> candidates)?  ambiguous,TResult Function( ScopeSelector selector,  String text)?  unmatched,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ScopeMatched() when matched != null:
return matched(_that.selector,_that.text,_that.target);case ScopeAmbiguous() when ambiguous != null:
return ambiguous(_that.selector,_that.text,_that.candidates);case ScopeUnmatched() when unmatched != null:
return unmatched(_that.selector,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ScopeSelector selector,  String text,  skir.ResourceId target)  matched,required TResult Function( ScopeSelector selector,  String text,  Set<skir.ResourceId> candidates)  ambiguous,required TResult Function( ScopeSelector selector,  String text)  unmatched,}) {final _that = this;
switch (_that) {
case ScopeMatched():
return matched(_that.selector,_that.text,_that.target);case ScopeAmbiguous():
return ambiguous(_that.selector,_that.text,_that.candidates);case ScopeUnmatched():
return unmatched(_that.selector,_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ScopeSelector selector,  String text,  skir.ResourceId target)?  matched,TResult? Function( ScopeSelector selector,  String text,  Set<skir.ResourceId> candidates)?  ambiguous,TResult? Function( ScopeSelector selector,  String text)?  unmatched,}) {final _that = this;
switch (_that) {
case ScopeMatched() when matched != null:
return matched(_that.selector,_that.text,_that.target);case ScopeAmbiguous() when ambiguous != null:
return ambiguous(_that.selector,_that.text,_that.candidates);case ScopeUnmatched() when unmatched != null:
return unmatched(_that.selector,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class ScopeMatched extends ScopeResolution {
  const ScopeMatched({required this.selector, required this.text, required this.target}): super._();
  

@override final  ScopeSelector selector;
@override final  String text;
 final  skir.ResourceId target;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopeMatchedCopyWith<ScopeMatched> get copyWith => _$ScopeMatchedCopyWithImpl<ScopeMatched>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopeMatched&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.text, text) || other.text == text)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selector,text,target);
}

@override
String toString() {
    return 'ScopeResolution.matched(selector: $selector, text: $text, target: $target)';
}


}

/// @nodoc
abstract mixin class $ScopeMatchedCopyWith<$Res> implements $ScopeResolutionCopyWith<$Res> {
  factory $ScopeMatchedCopyWith(ScopeMatched value, $Res Function(ScopeMatched) _then) = _$ScopeMatchedCopyWithImpl;
@override @useResult
$Res call({
 ScopeSelector selector, String text, skir.ResourceId target
});


@override $ScopeSelectorCopyWith<$Res> get selector;

}
/// @nodoc
class _$ScopeMatchedCopyWithImpl<$Res>
    implements $ScopeMatchedCopyWith<$Res> {
  _$ScopeMatchedCopyWithImpl(this._self, this._then);

  final ScopeMatched _self;
  final $Res Function(ScopeMatched) _then;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selector = null,Object? text = null,Object? target = null,}) {
  return _then(ScopeMatched(
selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as ScopeSelector,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopeSelectorCopyWith<$Res> get selector {
  
  return $ScopeSelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}
}

/// @nodoc


class ScopeAmbiguous extends ScopeResolution {
  const ScopeAmbiguous({required this.selector, required this.text, required  Set<skir.ResourceId> candidates}): _candidates = candidates,super._();
  

@override final  ScopeSelector selector;
@override final  String text;
 final  Set<skir.ResourceId> _candidates;
 Set<skir.ResourceId> get candidates {
  if (_candidates is EqualUnmodifiableSetView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_candidates);
}


/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopeAmbiguousCopyWith<ScopeAmbiguous> get copyWith => _$ScopeAmbiguousCopyWithImpl<ScopeAmbiguous>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopeAmbiguous&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.candidates, _candidates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selector,text,const DeepCollectionEquality().hash(_candidates));
}

@override
String toString() {
    return 'ScopeResolution.ambiguous(selector: $selector, text: $text, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $ScopeAmbiguousCopyWith<$Res> implements $ScopeResolutionCopyWith<$Res> {
  factory $ScopeAmbiguousCopyWith(ScopeAmbiguous value, $Res Function(ScopeAmbiguous) _then) = _$ScopeAmbiguousCopyWithImpl;
@override @useResult
$Res call({
 ScopeSelector selector, String text, Set<skir.ResourceId> candidates
});


@override $ScopeSelectorCopyWith<$Res> get selector;

}
/// @nodoc
class _$ScopeAmbiguousCopyWithImpl<$Res>
    implements $ScopeAmbiguousCopyWith<$Res> {
  _$ScopeAmbiguousCopyWithImpl(this._self, this._then);

  final ScopeAmbiguous _self;
  final $Res Function(ScopeAmbiguous) _then;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selector = null,Object? text = null,Object? candidates = null,}) {
  return _then(ScopeAmbiguous(
selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as ScopeSelector,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as Set<skir.ResourceId>,
  ));
}

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopeSelectorCopyWith<$Res> get selector {
  
  return $ScopeSelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}
}

/// @nodoc


class ScopeUnmatched extends ScopeResolution {
  const ScopeUnmatched({required this.selector, required this.text}): super._();
  

@override final  ScopeSelector selector;
@override final  String text;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopeUnmatchedCopyWith<ScopeUnmatched> get copyWith => _$ScopeUnmatchedCopyWithImpl<ScopeUnmatched>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopeUnmatched&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selector,text);
}

@override
String toString() {
    return 'ScopeResolution.unmatched(selector: $selector, text: $text)';
}


}

/// @nodoc
abstract mixin class $ScopeUnmatchedCopyWith<$Res> implements $ScopeResolutionCopyWith<$Res> {
  factory $ScopeUnmatchedCopyWith(ScopeUnmatched value, $Res Function(ScopeUnmatched) _then) = _$ScopeUnmatchedCopyWithImpl;
@override @useResult
$Res call({
 ScopeSelector selector, String text
});


@override $ScopeSelectorCopyWith<$Res> get selector;

}
/// @nodoc
class _$ScopeUnmatchedCopyWithImpl<$Res>
    implements $ScopeUnmatchedCopyWith<$Res> {
  _$ScopeUnmatchedCopyWithImpl(this._self, this._then);

  final ScopeUnmatched _self;
  final $Res Function(ScopeUnmatched) _then;

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selector = null,Object? text = null,}) {
  return _then(ScopeUnmatched(
selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as ScopeSelector,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ScopeResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopeSelectorCopyWith<$Res> get selector {
  
  return $ScopeSelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}
}

/// @nodoc
mixin _$CreationQueryOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationQueryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CreationQueryOutcome()';
}


}

/// @nodoc
class $CreationQueryOutcomeCopyWith<$Res>  {
$CreationQueryOutcomeCopyWith(CreationQueryOutcome _, $Res Function(CreationQueryOutcome) __);
}


/// Adds pattern-matching-related methods to [CreationQueryOutcome].
extension CreationQueryOutcomePatterns on CreationQueryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreationScoped value)?  scoped,TResult Function( CreationScopeUnmatched value)?  unmatched,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreationScoped() when scoped != null:
return scoped(_that);case CreationScopeUnmatched() when unmatched != null:
return unmatched(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreationScoped value)  scoped,required TResult Function( CreationScopeUnmatched value)  unmatched,}){
final _that = this;
switch (_that) {
case CreationScoped():
return scoped(_that);case CreationScopeUnmatched():
return unmatched(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreationScoped value)?  scoped,TResult? Function( CreationScopeUnmatched value)?  unmatched,}){
final _that = this;
switch (_that) {
case CreationScoped() when scoped != null:
return scoped(_that);case CreationScopeUnmatched() when unmatched != null:
return unmatched(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CreationContext context)?  scoped,TResult Function( List<ScopeUnmatched> scopes)?  unmatched,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreationScoped() when scoped != null:
return scoped(_that.context);case CreationScopeUnmatched() when unmatched != null:
return unmatched(_that.scopes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CreationContext context)  scoped,required TResult Function( List<ScopeUnmatched> scopes)  unmatched,}) {final _that = this;
switch (_that) {
case CreationScoped():
return scoped(_that.context);case CreationScopeUnmatched():
return unmatched(_that.scopes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CreationContext context)?  scoped,TResult? Function( List<ScopeUnmatched> scopes)?  unmatched,}) {final _that = this;
switch (_that) {
case CreationScoped() when scoped != null:
return scoped(_that.context);case CreationScopeUnmatched() when unmatched != null:
return unmatched(_that.scopes);case _:
  return null;

}
}

}

/// @nodoc


class CreationScoped implements CreationQueryOutcome {
  const CreationScoped(this.context);
  

 final  CreationContext context;

/// Create a copy of CreationQueryOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationScopedCopyWith<CreationScoped> get copyWith => _$CreationScopedCopyWithImpl<CreationScoped>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationScoped&&(identical(other.context, context) || other.context == context));
}


@override
int get hashCode {
    return Object.hash(runtimeType,context);
}

@override
String toString() {
    return 'CreationQueryOutcome.scoped(context: $context)';
}


}

/// @nodoc
abstract mixin class $CreationScopedCopyWith<$Res> implements $CreationQueryOutcomeCopyWith<$Res> {
  factory $CreationScopedCopyWith(CreationScoped value, $Res Function(CreationScoped) _then) = _$CreationScopedCopyWithImpl;
@useResult
$Res call({
 CreationContext context
});


$CreationContextCopyWith<$Res> get context;

}
/// @nodoc
class _$CreationScopedCopyWithImpl<$Res>
    implements $CreationScopedCopyWith<$Res> {
  _$CreationScopedCopyWithImpl(this._self, this._then);

  final CreationScoped _self;
  final $Res Function(CreationScoped) _then;

/// Create a copy of CreationQueryOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? context = null,}) {
  return _then(CreationScoped(
null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as CreationContext,
  ));
}

/// Create a copy of CreationQueryOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreationContextCopyWith<$Res> get context {
  
  return $CreationContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

/// @nodoc


class CreationScopeUnmatched implements CreationQueryOutcome {
  const CreationScopeUnmatched( List<ScopeUnmatched> scopes): _scopes = scopes;
  

 final  List<ScopeUnmatched> _scopes;
 List<ScopeUnmatched> get scopes {
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scopes);
}


/// Create a copy of CreationQueryOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationScopeUnmatchedCopyWith<CreationScopeUnmatched> get copyWith => _$CreationScopeUnmatchedCopyWithImpl<CreationScopeUnmatched>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationScopeUnmatched&&const DeepCollectionEquality().equals(other.scopes, _scopes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_scopes));
}

@override
String toString() {
    return 'CreationQueryOutcome.unmatched(scopes: $scopes)';
}


}

/// @nodoc
abstract mixin class $CreationScopeUnmatchedCopyWith<$Res> implements $CreationQueryOutcomeCopyWith<$Res> {
  factory $CreationScopeUnmatchedCopyWith(CreationScopeUnmatched value, $Res Function(CreationScopeUnmatched) _then) = _$CreationScopeUnmatchedCopyWithImpl;
@useResult
$Res call({
 List<ScopeUnmatched> scopes
});




}
/// @nodoc
class _$CreationScopeUnmatchedCopyWithImpl<$Res>
    implements $CreationScopeUnmatchedCopyWith<$Res> {
  _$CreationScopeUnmatchedCopyWithImpl(this._self, this._then);

  final CreationScopeUnmatched _self;
  final $Res Function(CreationScopeUnmatched) _then;

/// Create a copy of CreationQueryOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? scopes = null,}) {
  return _then(CreationScopeUnmatched(
null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<ScopeUnmatched>,
  ));
}


}

/// @nodoc
mixin _$CreationReferenceConstraint {

 List<skir.EndpointId> get route; Set<skir.ResourceId> get targets;
/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationReferenceConstraintCopyWith<CreationReferenceConstraint> get copyWith => _$CreationReferenceConstraintCopyWithImpl<CreationReferenceConstraint>(this as CreationReferenceConstraint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreationReferenceConstraint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationReferenceConstraint&&const DeepCollectionEquality().equals(other.route, _this.route)&&const DeepCollectionEquality().equals(other.targets, _this.targets));
}


@override
int get hashCode {
  final _this = this as CreationReferenceConstraint;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.route),const DeepCollectionEquality().hash(_this.targets));
}

@override
String toString() {
  final _this = this as CreationReferenceConstraint;
  return 'CreationReferenceConstraint(route: ${_this.route}, targets: ${_this.targets})';
}


}

/// @nodoc
abstract mixin class $CreationReferenceConstraintCopyWith<$Res>  {
  factory $CreationReferenceConstraintCopyWith(CreationReferenceConstraint value, $Res Function(CreationReferenceConstraint) _then) = _$CreationReferenceConstraintCopyWithImpl;
@useResult
$Res call({
 List<skir.EndpointId> route, Set<skir.ResourceId> targets
});




}
/// @nodoc
class _$CreationReferenceConstraintCopyWithImpl<$Res>
    implements $CreationReferenceConstraintCopyWith<$Res> {
  _$CreationReferenceConstraintCopyWithImpl(this._self, this._then);

  final CreationReferenceConstraint _self;
  final $Res Function(CreationReferenceConstraint) _then;

/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? route = null,Object? targets = null,}) {
  return _then(CreationReferenceConstraint(
route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as List<skir.EndpointId>,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as Set<skir.ResourceId>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreationReferenceConstraint].
extension CreationReferenceConstraintPatterns on CreationReferenceConstraint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreationReferenceConstraint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreationReferenceConstraint value)  $default,){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreationReferenceConstraint value)?  $default,){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.EndpointId> route,  Set<skir.ResourceId> targets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
return $default(_that.route,_that.targets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.EndpointId> route,  Set<skir.ResourceId> targets)  $default,) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint():
return $default(_that.route,_that.targets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.EndpointId> route,  Set<skir.ResourceId> targets)?  $default,) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
return $default(_that.route,_that.targets);case _:
  return null;

}
}

}

/// @nodoc


class _CreationReferenceConstraint implements CreationReferenceConstraint {
  const _CreationReferenceConstraint({required  List<skir.EndpointId> route, required  Set<skir.ResourceId> targets}): _route = route,_targets = targets;
  

 final  List<skir.EndpointId> _route;
@override List<skir.EndpointId> get route {
  if (_route is EqualUnmodifiableListView) return _route;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_route);
}

 final  Set<skir.ResourceId> _targets;
@override Set<skir.ResourceId> get targets {
  if (_targets is EqualUnmodifiableSetView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_targets);
}


/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreationReferenceConstraintCopyWith<_CreationReferenceConstraint> get copyWith => __$CreationReferenceConstraintCopyWithImpl<_CreationReferenceConstraint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreationReferenceConstraint&&const DeepCollectionEquality().equals(other.route, _route)&&const DeepCollectionEquality().equals(other.targets, _targets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_route),const DeepCollectionEquality().hash(_targets));
}

@override
String toString() {
    return 'CreationReferenceConstraint(route: $route, targets: $targets)';
}


}

/// @nodoc
abstract mixin class _$CreationReferenceConstraintCopyWith<$Res> implements $CreationReferenceConstraintCopyWith<$Res> {
  factory _$CreationReferenceConstraintCopyWith(_CreationReferenceConstraint value, $Res Function(_CreationReferenceConstraint) _then) = __$CreationReferenceConstraintCopyWithImpl;
@override @useResult
$Res call({
 List<skir.EndpointId> route, Set<skir.ResourceId> targets
});




}
/// @nodoc
class __$CreationReferenceConstraintCopyWithImpl<$Res>
    implements _$CreationReferenceConstraintCopyWith<$Res> {
  __$CreationReferenceConstraintCopyWithImpl(this._self, this._then);

  final _CreationReferenceConstraint _self;
  final $Res Function(_CreationReferenceConstraint) _then;

/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? route = null,Object? targets = null,}) {
  return _then(_CreationReferenceConstraint(
route: null == route ? _self._route : route // ignore: cast_nullable_to_non_nullable
as List<skir.EndpointId>,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as Set<skir.ResourceId>,
  ));
}


}

/// @nodoc
mixin _$CreationContext {

 List<CreationReferenceConstraint> get constraints; List<skir.ResourceId> get preferredResources;
/// Create a copy of CreationContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationContextCopyWith<CreationContext> get copyWith => _$CreationContextCopyWithImpl<CreationContext>(this as CreationContext, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreationContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationContext&&const DeepCollectionEquality().equals(other.constraints, _this.constraints)&&const DeepCollectionEquality().equals(other.preferredResources, _this.preferredResources));
}


@override
int get hashCode {
  final _this = this as CreationContext;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.constraints),const DeepCollectionEquality().hash(_this.preferredResources));
}

@override
String toString() {
  final _this = this as CreationContext;
  return 'CreationContext(constraints: ${_this.constraints}, preferredResources: ${_this.preferredResources})';
}


}

/// @nodoc
abstract mixin class $CreationContextCopyWith<$Res>  {
  factory $CreationContextCopyWith(CreationContext value, $Res Function(CreationContext) _then) = _$CreationContextCopyWithImpl;
@useResult
$Res call({
 List<CreationReferenceConstraint> constraints, List<skir.ResourceId> preferredResources
});




}
/// @nodoc
class _$CreationContextCopyWithImpl<$Res>
    implements $CreationContextCopyWith<$Res> {
  _$CreationContextCopyWithImpl(this._self, this._then);

  final CreationContext _self;
  final $Res Function(CreationContext) _then;

/// Create a copy of CreationContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? constraints = null,Object? preferredResources = null,}) {
  return _then(CreationContext(
constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<CreationReferenceConstraint>,preferredResources: null == preferredResources ? _self.preferredResources : preferredResources // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreationContext].
extension CreationContextPatterns on CreationContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreationContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreationContext value)  $default,){
final _that = this;
switch (_that) {
case _CreationContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreationContext value)?  $default,){
final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
return $default(_that.constraints,_that.preferredResources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)  $default,) {final _that = this;
switch (_that) {
case _CreationContext():
return $default(_that.constraints,_that.preferredResources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)?  $default,) {final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
return $default(_that.constraints,_that.preferredResources);case _:
  return null;

}
}

}

/// @nodoc


class _CreationContext extends CreationContext {
  const _CreationContext({ List<CreationReferenceConstraint> constraints = const [],  List<skir.ResourceId> preferredResources = const []}): _constraints = constraints,_preferredResources = preferredResources,super._();
  

 final  List<CreationReferenceConstraint> _constraints;
@override@JsonKey() List<CreationReferenceConstraint> get constraints {
  if (_constraints is EqualUnmodifiableListView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constraints);
}

 final  List<skir.ResourceId> _preferredResources;
@override@JsonKey() List<skir.ResourceId> get preferredResources {
  if (_preferredResources is EqualUnmodifiableListView) return _preferredResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredResources);
}


/// Create a copy of CreationContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreationContextCopyWith<_CreationContext> get copyWith => __$CreationContextCopyWithImpl<_CreationContext>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreationContext&&const DeepCollectionEquality().equals(other.constraints, _constraints)&&const DeepCollectionEquality().equals(other.preferredResources, _preferredResources));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_constraints),const DeepCollectionEquality().hash(_preferredResources));
}

@override
String toString() {
    return 'CreationContext(constraints: $constraints, preferredResources: $preferredResources)';
}


}

/// @nodoc
abstract mixin class _$CreationContextCopyWith<$Res> implements $CreationContextCopyWith<$Res> {
  factory _$CreationContextCopyWith(_CreationContext value, $Res Function(_CreationContext) _then) = __$CreationContextCopyWithImpl;
@override @useResult
$Res call({
 List<CreationReferenceConstraint> constraints, List<skir.ResourceId> preferredResources
});




}
/// @nodoc
class __$CreationContextCopyWithImpl<$Res>
    implements _$CreationContextCopyWith<$Res> {
  __$CreationContextCopyWithImpl(this._self, this._then);

  final _CreationContext _self;
  final $Res Function(_CreationContext) _then;

/// Create a copy of CreationContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? constraints = null,Object? preferredResources = null,}) {
  return _then(_CreationContext(
constraints: null == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<CreationReferenceConstraint>,preferredResources: null == preferredResources ? _self._preferredResources : preferredResources // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}


}

// dart format on
