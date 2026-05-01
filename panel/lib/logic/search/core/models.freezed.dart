// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchParsedSelector implements DiagnosticableTreeMixin {

 String get selectorId; String get key; String? get value;
/// Create a copy of SearchParsedSelector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchParsedSelectorCopyWith<SearchParsedSelector> get copyWith => _$SearchParsedSelectorCopyWithImpl<SearchParsedSelector>(this as SearchParsedSelector, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchParsedSelector'))
    ..add(DiagnosticsProperty('selectorId', selectorId))..add(DiagnosticsProperty('key', key))..add(DiagnosticsProperty('value', value));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchParsedSelector&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,selectorId,key,value);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchParsedSelector(selectorId: $selectorId, key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $SearchParsedSelectorCopyWith<$Res>  {
  factory $SearchParsedSelectorCopyWith(SearchParsedSelector value, $Res Function(SearchParsedSelector) _then) = _$SearchParsedSelectorCopyWithImpl;
@useResult
$Res call({
 String selectorId, String key, String? value
});




}
/// @nodoc
class _$SearchParsedSelectorCopyWithImpl<$Res>
    implements $SearchParsedSelectorCopyWith<$Res> {
  _$SearchParsedSelectorCopyWithImpl(this._self, this._then);

  final SearchParsedSelector _self;
  final $Res Function(SearchParsedSelector) _then;

/// Create a copy of SearchParsedSelector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectorId = null,Object? key = null,Object? value = freezed,}) {
  return _then(_self.copyWith(
selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchParsedSelector].
extension SearchParsedSelectorPatterns on SearchParsedSelector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchParsedSelector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchParsedSelector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchParsedSelector value)  $default,){
final _that = this;
switch (_that) {
case _SearchParsedSelector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchParsedSelector value)?  $default,){
final _that = this;
switch (_that) {
case _SearchParsedSelector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String selectorId,  String key,  String? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchParsedSelector() when $default != null:
return $default(_that.selectorId,_that.key,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String selectorId,  String key,  String? value)  $default,) {final _that = this;
switch (_that) {
case _SearchParsedSelector():
return $default(_that.selectorId,_that.key,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String selectorId,  String key,  String? value)?  $default,) {final _that = this;
switch (_that) {
case _SearchParsedSelector() when $default != null:
return $default(_that.selectorId,_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _SearchParsedSelector with DiagnosticableTreeMixin implements SearchParsedSelector {
  const _SearchParsedSelector({required this.selectorId, required this.key, this.value});
  

@override final  String selectorId;
@override final  String key;
@override final  String? value;

/// Create a copy of SearchParsedSelector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchParsedSelectorCopyWith<_SearchParsedSelector> get copyWith => __$SearchParsedSelectorCopyWithImpl<_SearchParsedSelector>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchParsedSelector'))
    ..add(DiagnosticsProperty('selectorId', selectorId))..add(DiagnosticsProperty('key', key))..add(DiagnosticsProperty('value', value));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchParsedSelector&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,selectorId,key,value);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchParsedSelector(selectorId: $selectorId, key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$SearchParsedSelectorCopyWith<$Res> implements $SearchParsedSelectorCopyWith<$Res> {
  factory _$SearchParsedSelectorCopyWith(_SearchParsedSelector value, $Res Function(_SearchParsedSelector) _then) = __$SearchParsedSelectorCopyWithImpl;
@override @useResult
$Res call({
 String selectorId, String key, String? value
});




}
/// @nodoc
class __$SearchParsedSelectorCopyWithImpl<$Res>
    implements _$SearchParsedSelectorCopyWith<$Res> {
  __$SearchParsedSelectorCopyWithImpl(this._self, this._then);

  final _SearchParsedSelector _self;
  final $Res Function(_SearchParsedSelector) _then;

/// Create a copy of SearchParsedSelector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectorId = null,Object? key = null,Object? value = freezed,}) {
  return _then(_SearchParsedSelector(
selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SearchQueryContext implements DiagnosticableTreeMixin {

 String get normalizedQuery; List<SearchParsedSelector> get selectors; SearchSelectorExpression? get selectorExpression;
/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<SearchQueryContext> get copyWith => _$SearchQueryContextCopyWithImpl<SearchQueryContext>(this as SearchQueryContext, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchQueryContext'))
    ..add(DiagnosticsProperty('normalizedQuery', normalizedQuery))..add(DiagnosticsProperty('selectors', selectors))..add(DiagnosticsProperty('selectorExpression', selectorExpression));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchQueryContext&&(identical(other.normalizedQuery, normalizedQuery) || other.normalizedQuery == normalizedQuery)&&const DeepCollectionEquality().equals(other.selectors, selectors)&&(identical(other.selectorExpression, selectorExpression) || other.selectorExpression == selectorExpression));
}


@override
int get hashCode => Object.hash(runtimeType,normalizedQuery,const DeepCollectionEquality().hash(selectors),selectorExpression);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchQueryContext(normalizedQuery: $normalizedQuery, selectors: $selectors, selectorExpression: $selectorExpression)';
}


}

/// @nodoc
abstract mixin class $SearchQueryContextCopyWith<$Res>  {
  factory $SearchQueryContextCopyWith(SearchQueryContext value, $Res Function(SearchQueryContext) _then) = _$SearchQueryContextCopyWithImpl;
@useResult
$Res call({
 String normalizedQuery, List<SearchParsedSelector> selectors, SearchSelectorExpression? selectorExpression
});




}
/// @nodoc
class _$SearchQueryContextCopyWithImpl<$Res>
    implements $SearchQueryContextCopyWith<$Res> {
  _$SearchQueryContextCopyWithImpl(this._self, this._then);

  final SearchQueryContext _self;
  final $Res Function(SearchQueryContext) _then;

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? normalizedQuery = null,Object? selectors = null,Object? selectorExpression = freezed,}) {
  return _then(_self.copyWith(
normalizedQuery: null == normalizedQuery ? _self.normalizedQuery : normalizedQuery // ignore: cast_nullable_to_non_nullable
as String,selectors: null == selectors ? _self.selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchParsedSelector>,selectorExpression: freezed == selectorExpression ? _self.selectorExpression : selectorExpression // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchQueryContext].
extension SearchQueryContextPatterns on SearchQueryContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchQueryContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchQueryContext value)  $default,){
final _that = this;
switch (_that) {
case _SearchQueryContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchQueryContext value)?  $default,){
final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  SearchSelectorExpression? selectorExpression)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
return $default(_that.normalizedQuery,_that.selectors,_that.selectorExpression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  SearchSelectorExpression? selectorExpression)  $default,) {final _that = this;
switch (_that) {
case _SearchQueryContext():
return $default(_that.normalizedQuery,_that.selectors,_that.selectorExpression);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  SearchSelectorExpression? selectorExpression)?  $default,) {final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
return $default(_that.normalizedQuery,_that.selectors,_that.selectorExpression);case _:
  return null;

}
}

}

/// @nodoc


class _SearchQueryContext with DiagnosticableTreeMixin implements SearchQueryContext {
  const _SearchQueryContext({required this.normalizedQuery, required final  List<SearchParsedSelector> selectors, this.selectorExpression}): _selectors = selectors;
  

@override final  String normalizedQuery;
 final  List<SearchParsedSelector> _selectors;
@override List<SearchParsedSelector> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}

@override final  SearchSelectorExpression? selectorExpression;

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchQueryContextCopyWith<_SearchQueryContext> get copyWith => __$SearchQueryContextCopyWithImpl<_SearchQueryContext>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchQueryContext'))
    ..add(DiagnosticsProperty('normalizedQuery', normalizedQuery))..add(DiagnosticsProperty('selectors', selectors))..add(DiagnosticsProperty('selectorExpression', selectorExpression));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchQueryContext&&(identical(other.normalizedQuery, normalizedQuery) || other.normalizedQuery == normalizedQuery)&&const DeepCollectionEquality().equals(other._selectors, _selectors)&&(identical(other.selectorExpression, selectorExpression) || other.selectorExpression == selectorExpression));
}


@override
int get hashCode => Object.hash(runtimeType,normalizedQuery,const DeepCollectionEquality().hash(_selectors),selectorExpression);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchQueryContext(normalizedQuery: $normalizedQuery, selectors: $selectors, selectorExpression: $selectorExpression)';
}


}

/// @nodoc
abstract mixin class _$SearchQueryContextCopyWith<$Res> implements $SearchQueryContextCopyWith<$Res> {
  factory _$SearchQueryContextCopyWith(_SearchQueryContext value, $Res Function(_SearchQueryContext) _then) = __$SearchQueryContextCopyWithImpl;
@override @useResult
$Res call({
 String normalizedQuery, List<SearchParsedSelector> selectors, SearchSelectorExpression? selectorExpression
});




}
/// @nodoc
class __$SearchQueryContextCopyWithImpl<$Res>
    implements _$SearchQueryContextCopyWith<$Res> {
  __$SearchQueryContextCopyWithImpl(this._self, this._then);

  final _SearchQueryContext _self;
  final $Res Function(_SearchQueryContext) _then;

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? normalizedQuery = null,Object? selectors = null,Object? selectorExpression = freezed,}) {
  return _then(_SearchQueryContext(
normalizedQuery: null == normalizedQuery ? _self.normalizedQuery : normalizedQuery // ignore: cast_nullable_to_non_nullable
as String,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchParsedSelector>,selectorExpression: freezed == selectorExpression ? _self.selectorExpression : selectorExpression // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression?,
  ));
}


}

/// @nodoc
mixin _$SearchGuidance implements DiagnosticableTreeMixin {

 String get id; String get title; String? get description; SearchGuidanceVisibility get visibility; int get priority;
/// Create a copy of SearchGuidance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchGuidanceCopyWith<SearchGuidance> get copyWith => _$SearchGuidanceCopyWithImpl<SearchGuidance>(this as SearchGuidance, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchGuidance'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('visibility', visibility))..add(DiagnosticsProperty('priority', priority));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchGuidance&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,visibility,priority);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchGuidance(id: $id, title: $title, description: $description, visibility: $visibility, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $SearchGuidanceCopyWith<$Res>  {
  factory $SearchGuidanceCopyWith(SearchGuidance value, $Res Function(SearchGuidance) _then) = _$SearchGuidanceCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, SearchGuidanceVisibility visibility, int priority
});




}
/// @nodoc
class _$SearchGuidanceCopyWithImpl<$Res>
    implements $SearchGuidanceCopyWith<$Res> {
  _$SearchGuidanceCopyWithImpl(this._self, this._then);

  final SearchGuidance _self;
  final $Res Function(SearchGuidance) _then;

/// Create a copy of SearchGuidance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? visibility = null,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SearchGuidanceVisibility,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchGuidance].
extension SearchGuidancePatterns on SearchGuidance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchGuidance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchGuidance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchGuidance value)  $default,){
final _that = this;
switch (_that) {
case _SearchGuidance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchGuidance value)?  $default,){
final _that = this;
switch (_that) {
case _SearchGuidance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  SearchGuidanceVisibility visibility,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchGuidance() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  SearchGuidanceVisibility visibility,  int priority)  $default,) {final _that = this;
switch (_that) {
case _SearchGuidance():
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  SearchGuidanceVisibility visibility,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _SearchGuidance() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _SearchGuidance with DiagnosticableTreeMixin implements SearchGuidance {
  const _SearchGuidance({required this.id, required this.title, this.description, this.visibility = SearchGuidanceVisibility.emptyOnly, this.priority = 0});
  

@override final  String id;
@override final  String title;
@override final  String? description;
@override@JsonKey() final  SearchGuidanceVisibility visibility;
@override@JsonKey() final  int priority;

/// Create a copy of SearchGuidance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchGuidanceCopyWith<_SearchGuidance> get copyWith => __$SearchGuidanceCopyWithImpl<_SearchGuidance>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchGuidance'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('visibility', visibility))..add(DiagnosticsProperty('priority', priority));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchGuidance&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,visibility,priority);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchGuidance(id: $id, title: $title, description: $description, visibility: $visibility, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$SearchGuidanceCopyWith<$Res> implements $SearchGuidanceCopyWith<$Res> {
  factory _$SearchGuidanceCopyWith(_SearchGuidance value, $Res Function(_SearchGuidance) _then) = __$SearchGuidanceCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, SearchGuidanceVisibility visibility, int priority
});




}
/// @nodoc
class __$SearchGuidanceCopyWithImpl<$Res>
    implements _$SearchGuidanceCopyWith<$Res> {
  __$SearchGuidanceCopyWithImpl(this._self, this._then);

  final _SearchGuidance _self;
  final $Res Function(_SearchGuidance) _then;

/// Create a copy of SearchGuidance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? visibility = null,Object? priority = null,}) {
  return _then(_SearchGuidance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SearchGuidanceVisibility,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SearchErrorSummary implements DiagnosticableTreeMixin {

 String get id; String get message; SearchErrorSeverity get severity; String? get sourceLabel;
/// Create a copy of SearchErrorSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchErrorSummaryCopyWith<SearchErrorSummary> get copyWith => _$SearchErrorSummaryCopyWithImpl<SearchErrorSummary>(this as SearchErrorSummary, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchErrorSummary'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('severity', severity))..add(DiagnosticsProperty('sourceLabel', sourceLabel));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchErrorSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,message,severity,sourceLabel);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchErrorSummary(id: $id, message: $message, severity: $severity, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class $SearchErrorSummaryCopyWith<$Res>  {
  factory $SearchErrorSummaryCopyWith(SearchErrorSummary value, $Res Function(SearchErrorSummary) _then) = _$SearchErrorSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String message, SearchErrorSeverity severity, String? sourceLabel
});




}
/// @nodoc
class _$SearchErrorSummaryCopyWithImpl<$Res>
    implements $SearchErrorSummaryCopyWith<$Res> {
  _$SearchErrorSummaryCopyWithImpl(this._self, this._then);

  final SearchErrorSummary _self;
  final $Res Function(SearchErrorSummary) _then;

/// Create a copy of SearchErrorSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? severity = null,Object? sourceLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as SearchErrorSeverity,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchErrorSummary].
extension SearchErrorSummaryPatterns on SearchErrorSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchErrorSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchErrorSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchErrorSummary value)  $default,){
final _that = this;
switch (_that) {
case _SearchErrorSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchErrorSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SearchErrorSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String message,  SearchErrorSeverity severity,  String? sourceLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchErrorSummary() when $default != null:
return $default(_that.id,_that.message,_that.severity,_that.sourceLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String message,  SearchErrorSeverity severity,  String? sourceLabel)  $default,) {final _that = this;
switch (_that) {
case _SearchErrorSummary():
return $default(_that.id,_that.message,_that.severity,_that.sourceLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String message,  SearchErrorSeverity severity,  String? sourceLabel)?  $default,) {final _that = this;
switch (_that) {
case _SearchErrorSummary() when $default != null:
return $default(_that.id,_that.message,_that.severity,_that.sourceLabel);case _:
  return null;

}
}

}

/// @nodoc


class _SearchErrorSummary with DiagnosticableTreeMixin implements SearchErrorSummary {
  const _SearchErrorSummary({required this.id, required this.message, required this.severity, this.sourceLabel});
  

@override final  String id;
@override final  String message;
@override final  SearchErrorSeverity severity;
@override final  String? sourceLabel;

/// Create a copy of SearchErrorSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchErrorSummaryCopyWith<_SearchErrorSummary> get copyWith => __$SearchErrorSummaryCopyWithImpl<_SearchErrorSummary>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchErrorSummary'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('severity', severity))..add(DiagnosticsProperty('sourceLabel', sourceLabel));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchErrorSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,message,severity,sourceLabel);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchErrorSummary(id: $id, message: $message, severity: $severity, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class _$SearchErrorSummaryCopyWith<$Res> implements $SearchErrorSummaryCopyWith<$Res> {
  factory _$SearchErrorSummaryCopyWith(_SearchErrorSummary value, $Res Function(_SearchErrorSummary) _then) = __$SearchErrorSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String message, SearchErrorSeverity severity, String? sourceLabel
});




}
/// @nodoc
class __$SearchErrorSummaryCopyWithImpl<$Res>
    implements _$SearchErrorSummaryCopyWith<$Res> {
  __$SearchErrorSummaryCopyWithImpl(this._self, this._then);

  final _SearchErrorSummary _self;
  final $Res Function(_SearchErrorSummary) _then;

/// Create a copy of SearchErrorSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? severity = null,Object? sourceLabel = freezed,}) {
  return _then(_SearchErrorSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as SearchErrorSeverity,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SearchSourceSnapshot implements DiagnosticableTreeMixin {

 SearchSourceStatus get status; List<SearchNode> get nodes; Map<Type, SearchAction> get actions; List<SearchGuidance> get guidance; List<SearchErrorSummary> get errorSummaries;
/// Create a copy of SearchSourceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSourceSnapshotCopyWith<SearchSourceSnapshot> get copyWith => _$SearchSourceSnapshotCopyWithImpl<SearchSourceSnapshot>(this as SearchSourceSnapshot, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchSourceSnapshot'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('nodes', nodes))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('guidance', guidance))..add(DiagnosticsProperty('errorSummaries', errorSummaries));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSourceSnapshot&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.nodes, nodes)&&const DeepCollectionEquality().equals(other.actions, actions)&&const DeepCollectionEquality().equals(other.guidance, guidance)&&const DeepCollectionEquality().equals(other.errorSummaries, errorSummaries));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(nodes),const DeepCollectionEquality().hash(actions),const DeepCollectionEquality().hash(guidance),const DeepCollectionEquality().hash(errorSummaries));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchSourceSnapshot(status: $status, nodes: $nodes, actions: $actions, guidance: $guidance, errorSummaries: $errorSummaries)';
}


}

/// @nodoc
abstract mixin class $SearchSourceSnapshotCopyWith<$Res>  {
  factory $SearchSourceSnapshotCopyWith(SearchSourceSnapshot value, $Res Function(SearchSourceSnapshot) _then) = _$SearchSourceSnapshotCopyWithImpl;
@useResult
$Res call({
 SearchSourceStatus status, List<SearchNode> nodes, Map<Type, SearchAction> actions, List<SearchGuidance> guidance, List<SearchErrorSummary> errorSummaries
});




}
/// @nodoc
class _$SearchSourceSnapshotCopyWithImpl<$Res>
    implements $SearchSourceSnapshotCopyWith<$Res> {
  _$SearchSourceSnapshotCopyWithImpl(this._self, this._then);

  final SearchSourceSnapshot _self;
  final $Res Function(SearchSourceSnapshot) _then;

/// Create a copy of SearchSourceSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? nodes = null,Object? actions = null,Object? guidance = null,Object? errorSummaries = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchSourceStatus,nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<SearchNode>,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as Map<Type, SearchAction>,guidance: null == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as List<SearchGuidance>,errorSummaries: null == errorSummaries ? _self.errorSummaries : errorSummaries // ignore: cast_nullable_to_non_nullable
as List<SearchErrorSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchSourceSnapshot].
extension SearchSourceSnapshotPatterns on SearchSourceSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchSourceSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchSourceSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _SearchSourceSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchSourceSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchSourceStatus status,  List<SearchNode> nodes,  Map<Type, SearchAction> actions,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
return $default(_that.status,_that.nodes,_that.actions,_that.guidance,_that.errorSummaries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchSourceStatus status,  List<SearchNode> nodes,  Map<Type, SearchAction> actions,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries)  $default,) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot():
return $default(_that.status,_that.nodes,_that.actions,_that.guidance,_that.errorSummaries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchSourceStatus status,  List<SearchNode> nodes,  Map<Type, SearchAction> actions,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries)?  $default,) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
return $default(_that.status,_that.nodes,_that.actions,_that.guidance,_that.errorSummaries);case _:
  return null;

}
}

}

/// @nodoc


class _SearchSourceSnapshot with DiagnosticableTreeMixin implements SearchSourceSnapshot {
  const _SearchSourceSnapshot({required this.status, required final  List<SearchNode> nodes, final  Map<Type, SearchAction> actions = const {}, final  List<SearchGuidance> guidance = const <SearchGuidance>[], final  List<SearchErrorSummary> errorSummaries = const <SearchErrorSummary>[]}): _nodes = nodes,_actions = actions,_guidance = guidance,_errorSummaries = errorSummaries;
  

@override final  SearchSourceStatus status;
 final  List<SearchNode> _nodes;
@override List<SearchNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}

 final  Map<Type, SearchAction> _actions;
@override@JsonKey() Map<Type, SearchAction> get actions {
  if (_actions is EqualUnmodifiableMapView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_actions);
}

 final  List<SearchGuidance> _guidance;
@override@JsonKey() List<SearchGuidance> get guidance {
  if (_guidance is EqualUnmodifiableListView) return _guidance;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guidance);
}

 final  List<SearchErrorSummary> _errorSummaries;
@override@JsonKey() List<SearchErrorSummary> get errorSummaries {
  if (_errorSummaries is EqualUnmodifiableListView) return _errorSummaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errorSummaries);
}


/// Create a copy of SearchSourceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchSourceSnapshotCopyWith<_SearchSourceSnapshot> get copyWith => __$SearchSourceSnapshotCopyWithImpl<_SearchSourceSnapshot>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchSourceSnapshot'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('nodes', nodes))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('guidance', guidance))..add(DiagnosticsProperty('errorSummaries', errorSummaries));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchSourceSnapshot&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&const DeepCollectionEquality().equals(other._actions, _actions)&&const DeepCollectionEquality().equals(other._guidance, _guidance)&&const DeepCollectionEquality().equals(other._errorSummaries, _errorSummaries));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_actions),const DeepCollectionEquality().hash(_guidance),const DeepCollectionEquality().hash(_errorSummaries));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchSourceSnapshot(status: $status, nodes: $nodes, actions: $actions, guidance: $guidance, errorSummaries: $errorSummaries)';
}


}

/// @nodoc
abstract mixin class _$SearchSourceSnapshotCopyWith<$Res> implements $SearchSourceSnapshotCopyWith<$Res> {
  factory _$SearchSourceSnapshotCopyWith(_SearchSourceSnapshot value, $Res Function(_SearchSourceSnapshot) _then) = __$SearchSourceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 SearchSourceStatus status, List<SearchNode> nodes, Map<Type, SearchAction> actions, List<SearchGuidance> guidance, List<SearchErrorSummary> errorSummaries
});




}
/// @nodoc
class __$SearchSourceSnapshotCopyWithImpl<$Res>
    implements _$SearchSourceSnapshotCopyWith<$Res> {
  __$SearchSourceSnapshotCopyWithImpl(this._self, this._then);

  final _SearchSourceSnapshot _self;
  final $Res Function(_SearchSourceSnapshot) _then;

/// Create a copy of SearchSourceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? nodes = null,Object? actions = null,Object? guidance = null,Object? errorSummaries = null,}) {
  return _then(_SearchSourceSnapshot(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchSourceStatus,nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<SearchNode>,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as Map<Type, SearchAction>,guidance: null == guidance ? _self._guidance : guidance // ignore: cast_nullable_to_non_nullable
as List<SearchGuidance>,errorSummaries: null == errorSummaries ? _self._errorSummaries : errorSummaries // ignore: cast_nullable_to_non_nullable
as List<SearchErrorSummary>,
  ));
}


}

/// @nodoc
mixin _$SearchNode implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchNode'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchNode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchNode()';
}


}

/// @nodoc
class $SearchNodeCopyWith<$Res>  {
$SearchNodeCopyWith(SearchNode _, $Res Function(SearchNode) __);
}


/// Adds pattern-matching-related methods to [SearchNode].
extension SearchNodePatterns on SearchNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchSectionNode value)?  section,TResult Function( SearchResultNode value)?  result,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchSectionNode() when section != null:
return section(_that);case SearchResultNode() when result != null:
return result(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchSectionNode value)  section,required TResult Function( SearchResultNode value)  result,}){
final _that = this;
switch (_that) {
case SearchSectionNode():
return section(_that);case SearchResultNode():
return result(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchSectionNode value)?  section,TResult? Function( SearchResultNode value)?  result,}){
final _that = this;
switch (_that) {
case SearchSectionNode() when section != null:
return section(_that);case SearchResultNode() when result != null:
return result(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String title,  String? subtitle,  List<SearchNode> children)?  section,TResult Function( SearchResult result)?  result,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchSectionNode() when section != null:
return section(_that.id,_that.title,_that.subtitle,_that.children);case SearchResultNode() when result != null:
return result(_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String title,  String? subtitle,  List<SearchNode> children)  section,required TResult Function( SearchResult result)  result,}) {final _that = this;
switch (_that) {
case SearchSectionNode():
return section(_that.id,_that.title,_that.subtitle,_that.children);case SearchResultNode():
return result(_that.result);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String title,  String? subtitle,  List<SearchNode> children)?  section,TResult? Function( SearchResult result)?  result,}) {final _that = this;
switch (_that) {
case SearchSectionNode() when section != null:
return section(_that.id,_that.title,_that.subtitle,_that.children);case SearchResultNode() when result != null:
return result(_that.result);case _:
  return null;

}
}

}

/// @nodoc


class SearchSectionNode with DiagnosticableTreeMixin implements SearchNode {
  const SearchSectionNode({required this.id, required this.title, this.subtitle, final  List<SearchNode> children = const <SearchNode>[]}): _children = children;
  

 final  String id;
 final  String title;
 final  String? subtitle;
 final  List<SearchNode> _children;
@JsonKey() List<SearchNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of SearchNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSectionNodeCopyWith<SearchSectionNode> get copyWith => _$SearchSectionNodeCopyWithImpl<SearchSectionNode>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchNode.section'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('subtitle', subtitle))..add(DiagnosticsProperty('children', children));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSectionNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,subtitle,const DeepCollectionEquality().hash(_children));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchNode.section(id: $id, title: $title, subtitle: $subtitle, children: $children)';
}


}

/// @nodoc
abstract mixin class $SearchSectionNodeCopyWith<$Res> implements $SearchNodeCopyWith<$Res> {
  factory $SearchSectionNodeCopyWith(SearchSectionNode value, $Res Function(SearchSectionNode) _then) = _$SearchSectionNodeCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? subtitle, List<SearchNode> children
});




}
/// @nodoc
class _$SearchSectionNodeCopyWithImpl<$Res>
    implements $SearchSectionNodeCopyWith<$Res> {
  _$SearchSectionNodeCopyWithImpl(this._self, this._then);

  final SearchSectionNode _self;
  final $Res Function(SearchSectionNode) _then;

/// Create a copy of SearchNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? subtitle = freezed,Object? children = null,}) {
  return _then(SearchSectionNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<SearchNode>,
  ));
}


}

/// @nodoc


class SearchResultNode with DiagnosticableTreeMixin implements SearchNode {
  const SearchResultNode({required this.result});
  

 final  SearchResult result;

/// Create a copy of SearchNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultNodeCopyWith<SearchResultNode> get copyWith => _$SearchResultNodeCopyWithImpl<SearchResultNode>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchNode.result'))
    ..add(DiagnosticsProperty('result', result));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultNode&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchNode.result(result: $result)';
}


}

/// @nodoc
abstract mixin class $SearchResultNodeCopyWith<$Res> implements $SearchNodeCopyWith<$Res> {
  factory $SearchResultNodeCopyWith(SearchResultNode value, $Res Function(SearchResultNode) _then) = _$SearchResultNodeCopyWithImpl;
@useResult
$Res call({
 SearchResult result
});


$SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultNodeCopyWithImpl<$Res>
    implements $SearchResultNodeCopyWith<$Res> {
  _$SearchResultNodeCopyWithImpl(this._self, this._then);

  final SearchResultNode _self;
  final $Res Function(SearchResultNode) _then;

/// Create a copy of SearchNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(SearchResultNode(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,
  ));
}

/// Create a copy of SearchNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
mixin _$SearchResultType implements DiagnosticableTreeMixin {

 String get id; String get rowRendererId; String? get previewRendererId; String? get label;
/// Create a copy of SearchResultType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultTypeCopyWith<SearchResultType> get copyWith => _$SearchResultTypeCopyWithImpl<SearchResultType>(this as SearchResultType, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchResultType'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('rowRendererId', rowRendererId))..add(DiagnosticsProperty('previewRendererId', previewRendererId))..add(DiagnosticsProperty('label', label));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultType&&(identical(other.id, id) || other.id == id)&&(identical(other.rowRendererId, rowRendererId) || other.rowRendererId == rowRendererId)&&(identical(other.previewRendererId, previewRendererId) || other.previewRendererId == previewRendererId)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,id,rowRendererId,previewRendererId,label);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchResultType(id: $id, rowRendererId: $rowRendererId, previewRendererId: $previewRendererId, label: $label)';
}


}

/// @nodoc
abstract mixin class $SearchResultTypeCopyWith<$Res>  {
  factory $SearchResultTypeCopyWith(SearchResultType value, $Res Function(SearchResultType) _then) = _$SearchResultTypeCopyWithImpl;
@useResult
$Res call({
 String id, String rowRendererId, String? previewRendererId, String? label
});




}
/// @nodoc
class _$SearchResultTypeCopyWithImpl<$Res>
    implements $SearchResultTypeCopyWith<$Res> {
  _$SearchResultTypeCopyWithImpl(this._self, this._then);

  final SearchResultType _self;
  final $Res Function(SearchResultType) _then;

/// Create a copy of SearchResultType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rowRendererId = null,Object? previewRendererId = freezed,Object? label = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rowRendererId: null == rowRendererId ? _self.rowRendererId : rowRendererId // ignore: cast_nullable_to_non_nullable
as String,previewRendererId: freezed == previewRendererId ? _self.previewRendererId : previewRendererId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResultType].
extension SearchResultTypePatterns on SearchResultType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultType value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultType value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rowRendererId,  String? previewRendererId,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultType() when $default != null:
return $default(_that.id,_that.rowRendererId,_that.previewRendererId,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rowRendererId,  String? previewRendererId,  String? label)  $default,) {final _that = this;
switch (_that) {
case _SearchResultType():
return $default(_that.id,_that.rowRendererId,_that.previewRendererId,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rowRendererId,  String? previewRendererId,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultType() when $default != null:
return $default(_that.id,_that.rowRendererId,_that.previewRendererId,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResultType with DiagnosticableTreeMixin implements SearchResultType {
  const _SearchResultType({required this.id, required this.rowRendererId, this.previewRendererId, this.label});
  

@override final  String id;
@override final  String rowRendererId;
@override final  String? previewRendererId;
@override final  String? label;

/// Create a copy of SearchResultType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultTypeCopyWith<_SearchResultType> get copyWith => __$SearchResultTypeCopyWithImpl<_SearchResultType>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchResultType'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('rowRendererId', rowRendererId))..add(DiagnosticsProperty('previewRendererId', previewRendererId))..add(DiagnosticsProperty('label', label));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultType&&(identical(other.id, id) || other.id == id)&&(identical(other.rowRendererId, rowRendererId) || other.rowRendererId == rowRendererId)&&(identical(other.previewRendererId, previewRendererId) || other.previewRendererId == previewRendererId)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,id,rowRendererId,previewRendererId,label);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchResultType(id: $id, rowRendererId: $rowRendererId, previewRendererId: $previewRendererId, label: $label)';
}


}

/// @nodoc
abstract mixin class _$SearchResultTypeCopyWith<$Res> implements $SearchResultTypeCopyWith<$Res> {
  factory _$SearchResultTypeCopyWith(_SearchResultType value, $Res Function(_SearchResultType) _then) = __$SearchResultTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String rowRendererId, String? previewRendererId, String? label
});




}
/// @nodoc
class __$SearchResultTypeCopyWithImpl<$Res>
    implements _$SearchResultTypeCopyWith<$Res> {
  __$SearchResultTypeCopyWithImpl(this._self, this._then);

  final _SearchResultType _self;
  final $Res Function(_SearchResultType) _then;

/// Create a copy of SearchResultType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rowRendererId = null,Object? previewRendererId = freezed,Object? label = freezed,}) {
  return _then(_SearchResultType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rowRendererId: null == rowRendererId ? _self.rowRendererId : rowRendererId // ignore: cast_nullable_to_non_nullable
as String,previewRendererId: freezed == previewRendererId ? _self.previewRendererId : previewRendererId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SearchResult implements DiagnosticableTreeMixin {

 String get id; SearchResultType get type; Object get payload; List<Type> get actions; String? get title; String? get subtitle; bool get isStale;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchResult'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('payload', payload))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('subtitle', subtitle))..add(DiagnosticsProperty('isStale', isStale));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&const DeepCollectionEquality().equals(other.actions, actions)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isStale, isStale) || other.isStale == isStale));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(payload),const DeepCollectionEquality().hash(actions),title,subtitle,isStale);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchResult(id: $id, type: $type, payload: $payload, actions: $actions, title: $title, subtitle: $subtitle, isStale: $isStale)';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 String id, SearchResultType type, Object payload, List<Type> actions, String? title, String? subtitle, bool isStale
});


$SearchResultTypeCopyWith<$Res> get type;

}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? actions = null,Object? title = freezed,Object? subtitle = freezed,Object? isStale = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,payload: null == payload ? _self.payload : payload ,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<Type>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultTypeCopyWith<$Res> get type {
  
  return $SearchResultTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResult].
extension SearchResultPatterns on SearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SearchResultType type,  Object payload,  List<Type> actions,  String? title,  String? subtitle,  bool isStale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.actions,_that.title,_that.subtitle,_that.isStale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SearchResultType type,  Object payload,  List<Type> actions,  String? title,  String? subtitle,  bool isStale)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.id,_that.type,_that.payload,_that.actions,_that.title,_that.subtitle,_that.isStale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SearchResultType type,  Object payload,  List<Type> actions,  String? title,  String? subtitle,  bool isStale)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.actions,_that.title,_that.subtitle,_that.isStale);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResult with DiagnosticableTreeMixin implements SearchResult {
  const _SearchResult({required this.id, required this.type, required this.payload, final  List<Type> actions = const [], this.title, this.subtitle, this.isStale = false}): _actions = actions;
  

@override final  String id;
@override final  SearchResultType type;
@override final  Object payload;
 final  List<Type> _actions;
@override@JsonKey() List<Type> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

@override final  String? title;
@override final  String? subtitle;
@override@JsonKey() final  bool isStale;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchResult'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('payload', payload))..add(DiagnosticsProperty('actions', actions))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('subtitle', subtitle))..add(DiagnosticsProperty('isStale', isStale));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&const DeepCollectionEquality().equals(other._actions, _actions)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isStale, isStale) || other.isStale == isStale));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(payload),const DeepCollectionEquality().hash(_actions),title,subtitle,isStale);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchResult(id: $id, type: $type, payload: $payload, actions: $actions, title: $title, subtitle: $subtitle, isStale: $isStale)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 String id, SearchResultType type, Object payload, List<Type> actions, String? title, String? subtitle, bool isStale
});


@override $SearchResultTypeCopyWith<$Res> get type;

}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? actions = null,Object? title = freezed,Object? subtitle = freezed,Object? isStale = null,}) {
  return _then(_SearchResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,payload: null == payload ? _self.payload : payload ,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<Type>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultTypeCopyWith<$Res> get type {
  
  return $SearchResultTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc
mixin _$SearchActionResult implements DiagnosticableTreeMixin {

 SearchActionEffect get effect;
/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionResultCopyWith<SearchActionResult> get copyWith => _$SearchActionResultCopyWithImpl<SearchActionResult>(this as SearchActionResult, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionResult'))
    ..add(DiagnosticsProperty('effect', effect));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionResult&&(identical(other.effect, effect) || other.effect == effect));
}


@override
int get hashCode => Object.hash(runtimeType,effect);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionResult(effect: $effect)';
}


}

/// @nodoc
abstract mixin class $SearchActionResultCopyWith<$Res>  {
  factory $SearchActionResultCopyWith(SearchActionResult value, $Res Function(SearchActionResult) _then) = _$SearchActionResultCopyWithImpl;
@useResult
$Res call({
 SearchActionEffect effect
});


$SearchActionEffectCopyWith<$Res> get effect;

}
/// @nodoc
class _$SearchActionResultCopyWithImpl<$Res>
    implements $SearchActionResultCopyWith<$Res> {
  _$SearchActionResultCopyWithImpl(this._self, this._then);

  final SearchActionResult _self;
  final $Res Function(SearchActionResult) _then;

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? effect = null,}) {
  return _then(_self.copyWith(
effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as SearchActionEffect,
  ));
}
/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchActionEffectCopyWith<$Res> get effect {
  
  return $SearchActionEffectCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchActionResult].
extension SearchActionResultPatterns on SearchActionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchActionResultCompleted value)?  completed,TResult Function( SearchActionResultFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchActionResultCompleted() when completed != null:
return completed(_that);case SearchActionResultFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchActionResultCompleted value)  completed,required TResult Function( SearchActionResultFailed value)  failed,}){
final _that = this;
switch (_that) {
case SearchActionResultCompleted():
return completed(_that);case SearchActionResultFailed():
return failed(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchActionResultCompleted value)?  completed,TResult? Function( SearchActionResultFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SearchActionResultCompleted() when completed != null:
return completed(_that);case SearchActionResultFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SearchActionEffect effect)?  completed,TResult Function( String message,  SearchActionEffect effect)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchActionResultCompleted() when completed != null:
return completed(_that.effect);case SearchActionResultFailed() when failed != null:
return failed(_that.message,_that.effect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SearchActionEffect effect)  completed,required TResult Function( String message,  SearchActionEffect effect)  failed,}) {final _that = this;
switch (_that) {
case SearchActionResultCompleted():
return completed(_that.effect);case SearchActionResultFailed():
return failed(_that.message,_that.effect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SearchActionEffect effect)?  completed,TResult? Function( String message,  SearchActionEffect effect)?  failed,}) {final _that = this;
switch (_that) {
case SearchActionResultCompleted() when completed != null:
return completed(_that.effect);case SearchActionResultFailed() when failed != null:
return failed(_that.message,_that.effect);case _:
  return null;

}
}

}

/// @nodoc


class SearchActionResultCompleted with DiagnosticableTreeMixin implements SearchActionResult {
  const SearchActionResultCompleted({this.effect = const SearchActionEffect.close()});
  

@override@JsonKey() final  SearchActionEffect effect;

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionResultCompletedCopyWith<SearchActionResultCompleted> get copyWith => _$SearchActionResultCompletedCopyWithImpl<SearchActionResultCompleted>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionResult.completed'))
    ..add(DiagnosticsProperty('effect', effect));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionResultCompleted&&(identical(other.effect, effect) || other.effect == effect));
}


@override
int get hashCode => Object.hash(runtimeType,effect);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionResult.completed(effect: $effect)';
}


}

/// @nodoc
abstract mixin class $SearchActionResultCompletedCopyWith<$Res> implements $SearchActionResultCopyWith<$Res> {
  factory $SearchActionResultCompletedCopyWith(SearchActionResultCompleted value, $Res Function(SearchActionResultCompleted) _then) = _$SearchActionResultCompletedCopyWithImpl;
@override @useResult
$Res call({
 SearchActionEffect effect
});


@override $SearchActionEffectCopyWith<$Res> get effect;

}
/// @nodoc
class _$SearchActionResultCompletedCopyWithImpl<$Res>
    implements $SearchActionResultCompletedCopyWith<$Res> {
  _$SearchActionResultCompletedCopyWithImpl(this._self, this._then);

  final SearchActionResultCompleted _self;
  final $Res Function(SearchActionResultCompleted) _then;

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? effect = null,}) {
  return _then(SearchActionResultCompleted(
effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as SearchActionEffect,
  ));
}

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchActionEffectCopyWith<$Res> get effect {
  
  return $SearchActionEffectCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}

/// @nodoc


class SearchActionResultFailed with DiagnosticableTreeMixin implements SearchActionResult {
  const SearchActionResultFailed({required this.message, this.effect = const SearchActionEffect.refresh()});
  

 final  String message;
@override@JsonKey() final  SearchActionEffect effect;

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionResultFailedCopyWith<SearchActionResultFailed> get copyWith => _$SearchActionResultFailedCopyWithImpl<SearchActionResultFailed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionResult.failed'))
    ..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('effect', effect));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionResultFailed&&(identical(other.message, message) || other.message == message)&&(identical(other.effect, effect) || other.effect == effect));
}


@override
int get hashCode => Object.hash(runtimeType,message,effect);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionResult.failed(message: $message, effect: $effect)';
}


}

/// @nodoc
abstract mixin class $SearchActionResultFailedCopyWith<$Res> implements $SearchActionResultCopyWith<$Res> {
  factory $SearchActionResultFailedCopyWith(SearchActionResultFailed value, $Res Function(SearchActionResultFailed) _then) = _$SearchActionResultFailedCopyWithImpl;
@override @useResult
$Res call({
 String message, SearchActionEffect effect
});


@override $SearchActionEffectCopyWith<$Res> get effect;

}
/// @nodoc
class _$SearchActionResultFailedCopyWithImpl<$Res>
    implements $SearchActionResultFailedCopyWith<$Res> {
  _$SearchActionResultFailedCopyWithImpl(this._self, this._then);

  final SearchActionResultFailed _self;
  final $Res Function(SearchActionResultFailed) _then;

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? effect = null,}) {
  return _then(SearchActionResultFailed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as SearchActionEffect,
  ));
}

/// Create a copy of SearchActionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchActionEffectCopyWith<$Res> get effect {
  
  return $SearchActionEffectCopyWith<$Res>(_self.effect, (value) {
    return _then(_self.copyWith(effect: value));
  });
}
}

/// @nodoc
mixin _$SearchActionEffect implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionEffect'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionEffect()';
}


}

/// @nodoc
class $SearchActionEffectCopyWith<$Res>  {
$SearchActionEffectCopyWith(SearchActionEffect _, $Res Function(SearchActionEffect) __);
}


/// Adds pattern-matching-related methods to [SearchActionEffect].
extension SearchActionEffectPatterns on SearchActionEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchActionUpdateQuery value)?  updateQuery,TResult Function( SearchActionRefresh value)?  refresh,TResult Function( SearchActionClose value)?  close,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchActionUpdateQuery() when updateQuery != null:
return updateQuery(_that);case SearchActionRefresh() when refresh != null:
return refresh(_that);case SearchActionClose() when close != null:
return close(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchActionUpdateQuery value)  updateQuery,required TResult Function( SearchActionRefresh value)  refresh,required TResult Function( SearchActionClose value)  close,}){
final _that = this;
switch (_that) {
case SearchActionUpdateQuery():
return updateQuery(_that);case SearchActionRefresh():
return refresh(_that);case SearchActionClose():
return close(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchActionUpdateQuery value)?  updateQuery,TResult? Function( SearchActionRefresh value)?  refresh,TResult? Function( SearchActionClose value)?  close,}){
final _that = this;
switch (_that) {
case SearchActionUpdateQuery() when updateQuery != null:
return updateQuery(_that);case SearchActionRefresh() when refresh != null:
return refresh(_that);case SearchActionClose() when close != null:
return close(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String updateQuery)?  updateQuery,TResult Function()?  refresh,TResult Function()?  close,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchActionUpdateQuery() when updateQuery != null:
return updateQuery(_that.updateQuery);case SearchActionRefresh() when refresh != null:
return refresh();case SearchActionClose() when close != null:
return close();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String updateQuery)  updateQuery,required TResult Function()  refresh,required TResult Function()  close,}) {final _that = this;
switch (_that) {
case SearchActionUpdateQuery():
return updateQuery(_that.updateQuery);case SearchActionRefresh():
return refresh();case SearchActionClose():
return close();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String updateQuery)?  updateQuery,TResult? Function()?  refresh,TResult? Function()?  close,}) {final _that = this;
switch (_that) {
case SearchActionUpdateQuery() when updateQuery != null:
return updateQuery(_that.updateQuery);case SearchActionRefresh() when refresh != null:
return refresh();case SearchActionClose() when close != null:
return close();case _:
  return null;

}
}

}

/// @nodoc


class SearchActionUpdateQuery with DiagnosticableTreeMixin implements SearchActionEffect {
  const SearchActionUpdateQuery({required this.updateQuery});
  

 final  String updateQuery;

/// Create a copy of SearchActionEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionUpdateQueryCopyWith<SearchActionUpdateQuery> get copyWith => _$SearchActionUpdateQueryCopyWithImpl<SearchActionUpdateQuery>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionEffect.updateQuery'))
    ..add(DiagnosticsProperty('updateQuery', updateQuery));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionUpdateQuery&&(identical(other.updateQuery, updateQuery) || other.updateQuery == updateQuery));
}


@override
int get hashCode => Object.hash(runtimeType,updateQuery);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionEffect.updateQuery(updateQuery: $updateQuery)';
}


}

/// @nodoc
abstract mixin class $SearchActionUpdateQueryCopyWith<$Res> implements $SearchActionEffectCopyWith<$Res> {
  factory $SearchActionUpdateQueryCopyWith(SearchActionUpdateQuery value, $Res Function(SearchActionUpdateQuery) _then) = _$SearchActionUpdateQueryCopyWithImpl;
@useResult
$Res call({
 String updateQuery
});




}
/// @nodoc
class _$SearchActionUpdateQueryCopyWithImpl<$Res>
    implements $SearchActionUpdateQueryCopyWith<$Res> {
  _$SearchActionUpdateQueryCopyWithImpl(this._self, this._then);

  final SearchActionUpdateQuery _self;
  final $Res Function(SearchActionUpdateQuery) _then;

/// Create a copy of SearchActionEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateQuery = null,}) {
  return _then(SearchActionUpdateQuery(
updateQuery: null == updateQuery ? _self.updateQuery : updateQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SearchActionRefresh with DiagnosticableTreeMixin implements SearchActionEffect {
  const SearchActionRefresh();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionEffect.refresh'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionRefresh);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionEffect.refresh()';
}


}




/// @nodoc


class SearchActionClose with DiagnosticableTreeMixin implements SearchActionEffect {
  const SearchActionClose();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionEffect.close'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionClose);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionEffect.close()';
}


}




/// @nodoc
mixin _$SearchActionState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionState()';
}


}

/// @nodoc
class $SearchActionStateCopyWith<$Res>  {
$SearchActionStateCopyWith(SearchActionState _, $Res Function(SearchActionState) __);
}


/// Adds pattern-matching-related methods to [SearchActionState].
extension SearchActionStatePatterns on SearchActionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchActionIdle value)?  idle,TResult Function( SearchActionRunning value)?  running,TResult Function( SearchActionCompleted value)?  completed,TResult Function( SearchActionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchActionIdle() when idle != null:
return idle(_that);case SearchActionRunning() when running != null:
return running(_that);case SearchActionCompleted() when completed != null:
return completed(_that);case SearchActionFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchActionIdle value)  idle,required TResult Function( SearchActionRunning value)  running,required TResult Function( SearchActionCompleted value)  completed,required TResult Function( SearchActionFailed value)  failed,}){
final _that = this;
switch (_that) {
case SearchActionIdle():
return idle(_that);case SearchActionRunning():
return running(_that);case SearchActionCompleted():
return completed(_that);case SearchActionFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchActionIdle value)?  idle,TResult? Function( SearchActionRunning value)?  running,TResult? Function( SearchActionCompleted value)?  completed,TResult? Function( SearchActionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SearchActionIdle() when idle != null:
return idle(_that);case SearchActionRunning() when running != null:
return running(_that);case SearchActionCompleted() when completed != null:
return completed(_that);case SearchActionFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( Type action,  Set<String> resultIds)?  running,TResult Function( Type action,  Set<String> resultIds)?  completed,TResult Function( Type action,  Set<String> resultIds,  String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchActionIdle() when idle != null:
return idle();case SearchActionRunning() when running != null:
return running(_that.action,_that.resultIds);case SearchActionCompleted() when completed != null:
return completed(_that.action,_that.resultIds);case SearchActionFailed() when failed != null:
return failed(_that.action,_that.resultIds,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( Type action,  Set<String> resultIds)  running,required TResult Function( Type action,  Set<String> resultIds)  completed,required TResult Function( Type action,  Set<String> resultIds,  String message)  failed,}) {final _that = this;
switch (_that) {
case SearchActionIdle():
return idle();case SearchActionRunning():
return running(_that.action,_that.resultIds);case SearchActionCompleted():
return completed(_that.action,_that.resultIds);case SearchActionFailed():
return failed(_that.action,_that.resultIds,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( Type action,  Set<String> resultIds)?  running,TResult? Function( Type action,  Set<String> resultIds)?  completed,TResult? Function( Type action,  Set<String> resultIds,  String message)?  failed,}) {final _that = this;
switch (_that) {
case SearchActionIdle() when idle != null:
return idle();case SearchActionRunning() when running != null:
return running(_that.action,_that.resultIds);case SearchActionCompleted() when completed != null:
return completed(_that.action,_that.resultIds);case SearchActionFailed() when failed != null:
return failed(_that.action,_that.resultIds,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchActionIdle with DiagnosticableTreeMixin implements SearchActionState {
  const SearchActionIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionState.idle'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionState.idle()';
}


}




/// @nodoc


class SearchActionRunning with DiagnosticableTreeMixin implements SearchActionState {
  const SearchActionRunning({required this.action, required final  Set<String> resultIds}): _resultIds = resultIds;
  

 final  Type action;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}


/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionRunningCopyWith<SearchActionRunning> get copyWith => _$SearchActionRunningCopyWithImpl<SearchActionRunning>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionState.running'))
    ..add(DiagnosticsProperty('action', action))..add(DiagnosticsProperty('resultIds', resultIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionRunning&&(identical(other.action, action) || other.action == action)&&const DeepCollectionEquality().equals(other._resultIds, _resultIds));
}


@override
int get hashCode => Object.hash(runtimeType,action,const DeepCollectionEquality().hash(_resultIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionState.running(action: $action, resultIds: $resultIds)';
}


}

/// @nodoc
abstract mixin class $SearchActionRunningCopyWith<$Res> implements $SearchActionStateCopyWith<$Res> {
  factory $SearchActionRunningCopyWith(SearchActionRunning value, $Res Function(SearchActionRunning) _then) = _$SearchActionRunningCopyWithImpl;
@useResult
$Res call({
 Type action, Set<String> resultIds
});




}
/// @nodoc
class _$SearchActionRunningCopyWithImpl<$Res>
    implements $SearchActionRunningCopyWith<$Res> {
  _$SearchActionRunningCopyWithImpl(this._self, this._then);

  final SearchActionRunning _self;
  final $Res Function(SearchActionRunning) _then;

/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,Object? resultIds = null,}) {
  return _then(SearchActionRunning(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as Type,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class SearchActionCompleted with DiagnosticableTreeMixin implements SearchActionState {
  const SearchActionCompleted({required this.action, required final  Set<String> resultIds}): _resultIds = resultIds;
  

 final  Type action;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}


/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionCompletedCopyWith<SearchActionCompleted> get copyWith => _$SearchActionCompletedCopyWithImpl<SearchActionCompleted>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionState.completed'))
    ..add(DiagnosticsProperty('action', action))..add(DiagnosticsProperty('resultIds', resultIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionCompleted&&(identical(other.action, action) || other.action == action)&&const DeepCollectionEquality().equals(other._resultIds, _resultIds));
}


@override
int get hashCode => Object.hash(runtimeType,action,const DeepCollectionEquality().hash(_resultIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionState.completed(action: $action, resultIds: $resultIds)';
}


}

/// @nodoc
abstract mixin class $SearchActionCompletedCopyWith<$Res> implements $SearchActionStateCopyWith<$Res> {
  factory $SearchActionCompletedCopyWith(SearchActionCompleted value, $Res Function(SearchActionCompleted) _then) = _$SearchActionCompletedCopyWithImpl;
@useResult
$Res call({
 Type action, Set<String> resultIds
});




}
/// @nodoc
class _$SearchActionCompletedCopyWithImpl<$Res>
    implements $SearchActionCompletedCopyWith<$Res> {
  _$SearchActionCompletedCopyWithImpl(this._self, this._then);

  final SearchActionCompleted _self;
  final $Res Function(SearchActionCompleted) _then;

/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,Object? resultIds = null,}) {
  return _then(SearchActionCompleted(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as Type,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class SearchActionFailed with DiagnosticableTreeMixin implements SearchActionState {
  const SearchActionFailed({required this.action, required final  Set<String> resultIds, required this.message}): _resultIds = resultIds;
  

 final  Type action;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}

 final  String message;

/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActionFailedCopyWith<SearchActionFailed> get copyWith => _$SearchActionFailedCopyWithImpl<SearchActionFailed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchActionState.failed'))
    ..add(DiagnosticsProperty('action', action))..add(DiagnosticsProperty('resultIds', resultIds))..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActionFailed&&(identical(other.action, action) || other.action == action)&&const DeepCollectionEquality().equals(other._resultIds, _resultIds)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,action,const DeepCollectionEquality().hash(_resultIds),message);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchActionState.failed(action: $action, resultIds: $resultIds, message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchActionFailedCopyWith<$Res> implements $SearchActionStateCopyWith<$Res> {
  factory $SearchActionFailedCopyWith(SearchActionFailed value, $Res Function(SearchActionFailed) _then) = _$SearchActionFailedCopyWithImpl;
@useResult
$Res call({
 Type action, Set<String> resultIds, String message
});




}
/// @nodoc
class _$SearchActionFailedCopyWithImpl<$Res>
    implements $SearchActionFailedCopyWith<$Res> {
  _$SearchActionFailedCopyWithImpl(this._self, this._then);

  final SearchActionFailed _self;
  final $Res Function(SearchActionFailed) _then;

/// Create a copy of SearchActionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,Object? resultIds = null,Object? message = null,}) {
  return _then(SearchActionFailed(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as Type,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SearchPreviewRequest implements DiagnosticableTreeMixin {

 String get resultId; SearchQueryContext? get queryContext;
/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPreviewRequestCopyWith<SearchPreviewRequest> get copyWith => _$SearchPreviewRequestCopyWithImpl<SearchPreviewRequest>(this as SearchPreviewRequest, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequest'))
    ..add(DiagnosticsProperty('resultId', resultId))..add(DiagnosticsProperty('queryContext', queryContext));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPreviewRequest&&(identical(other.resultId, resultId) || other.resultId == resultId)&&(identical(other.queryContext, queryContext) || other.queryContext == queryContext));
}


@override
int get hashCode => Object.hash(runtimeType,resultId,queryContext);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchPreviewRequest(resultId: $resultId, queryContext: $queryContext)';
}


}

/// @nodoc
abstract mixin class $SearchPreviewRequestCopyWith<$Res>  {
  factory $SearchPreviewRequestCopyWith(SearchPreviewRequest value, $Res Function(SearchPreviewRequest) _then) = _$SearchPreviewRequestCopyWithImpl;
@useResult
$Res call({
 String resultId, SearchQueryContext? queryContext
});


$SearchQueryContextCopyWith<$Res>? get queryContext;

}
/// @nodoc
class _$SearchPreviewRequestCopyWithImpl<$Res>
    implements $SearchPreviewRequestCopyWith<$Res> {
  _$SearchPreviewRequestCopyWithImpl(this._self, this._then);

  final SearchPreviewRequest _self;
  final $Res Function(SearchPreviewRequest) _then;

/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resultId = null,Object? queryContext = freezed,}) {
  return _then(_self.copyWith(
resultId: null == resultId ? _self.resultId : resultId // ignore: cast_nullable_to_non_nullable
as String,queryContext: freezed == queryContext ? _self.queryContext : queryContext // ignore: cast_nullable_to_non_nullable
as SearchQueryContext?,
  ));
}
/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res>? get queryContext {
    if (_self.queryContext == null) {
    return null;
  }

  return $SearchQueryContextCopyWith<$Res>(_self.queryContext!, (value) {
    return _then(_self.copyWith(queryContext: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchPreviewRequest].
extension SearchPreviewRequestPatterns on SearchPreviewRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchPreviewRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchPreviewRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchPreviewRequest value)  $default,){
final _that = this;
switch (_that) {
case _SearchPreviewRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchPreviewRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SearchPreviewRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resultId,  SearchQueryContext? queryContext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchPreviewRequest() when $default != null:
return $default(_that.resultId,_that.queryContext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resultId,  SearchQueryContext? queryContext)  $default,) {final _that = this;
switch (_that) {
case _SearchPreviewRequest():
return $default(_that.resultId,_that.queryContext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resultId,  SearchQueryContext? queryContext)?  $default,) {final _that = this;
switch (_that) {
case _SearchPreviewRequest() when $default != null:
return $default(_that.resultId,_that.queryContext);case _:
  return null;

}
}

}

/// @nodoc


class _SearchPreviewRequest with DiagnosticableTreeMixin implements SearchPreviewRequest {
  const _SearchPreviewRequest({required this.resultId, this.queryContext});
  

@override final  String resultId;
@override final  SearchQueryContext? queryContext;

/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchPreviewRequestCopyWith<_SearchPreviewRequest> get copyWith => __$SearchPreviewRequestCopyWithImpl<_SearchPreviewRequest>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequest'))
    ..add(DiagnosticsProperty('resultId', resultId))..add(DiagnosticsProperty('queryContext', queryContext));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchPreviewRequest&&(identical(other.resultId, resultId) || other.resultId == resultId)&&(identical(other.queryContext, queryContext) || other.queryContext == queryContext));
}


@override
int get hashCode => Object.hash(runtimeType,resultId,queryContext);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchPreviewRequest(resultId: $resultId, queryContext: $queryContext)';
}


}

/// @nodoc
abstract mixin class _$SearchPreviewRequestCopyWith<$Res> implements $SearchPreviewRequestCopyWith<$Res> {
  factory _$SearchPreviewRequestCopyWith(_SearchPreviewRequest value, $Res Function(_SearchPreviewRequest) _then) = __$SearchPreviewRequestCopyWithImpl;
@override @useResult
$Res call({
 String resultId, SearchQueryContext? queryContext
});


@override $SearchQueryContextCopyWith<$Res>? get queryContext;

}
/// @nodoc
class __$SearchPreviewRequestCopyWithImpl<$Res>
    implements _$SearchPreviewRequestCopyWith<$Res> {
  __$SearchPreviewRequestCopyWithImpl(this._self, this._then);

  final _SearchPreviewRequest _self;
  final $Res Function(_SearchPreviewRequest) _then;

/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resultId = null,Object? queryContext = freezed,}) {
  return _then(_SearchPreviewRequest(
resultId: null == resultId ? _self.resultId : resultId // ignore: cast_nullable_to_non_nullable
as String,queryContext: freezed == queryContext ? _self.queryContext : queryContext // ignore: cast_nullable_to_non_nullable
as SearchQueryContext?,
  ));
}

/// Create a copy of SearchPreviewRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res>? get queryContext {
    if (_self.queryContext == null) {
    return null;
  }

  return $SearchQueryContextCopyWith<$Res>(_self.queryContext!, (value) {
    return _then(_self.copyWith(queryContext: value));
  });
}
}

/// @nodoc
mixin _$SearchPreviewRequestResult implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequestResult'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPreviewRequestResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchPreviewRequestResult()';
}


}

/// @nodoc
class $SearchPreviewRequestResultCopyWith<$Res>  {
$SearchPreviewRequestResultCopyWith(SearchPreviewRequestResult _, $Res Function(SearchPreviewRequestResult) __);
}


/// Adds pattern-matching-related methods to [SearchPreviewRequestResult].
extension SearchPreviewRequestResultPatterns on SearchPreviewRequestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchPreviewRequestResultData value)?  data,TResult Function( SearchPreviewRequestResultError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchPreviewRequestResultData() when data != null:
return data(_that);case SearchPreviewRequestResultError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchPreviewRequestResultData value)  data,required TResult Function( SearchPreviewRequestResultError value)  error,}){
final _that = this;
switch (_that) {
case SearchPreviewRequestResultData():
return data(_that);case SearchPreviewRequestResultError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchPreviewRequestResultData value)?  data,TResult? Function( SearchPreviewRequestResultError value)?  error,}){
final _that = this;
switch (_that) {
case SearchPreviewRequestResultData() when data != null:
return data(_that);case SearchPreviewRequestResultError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Object data)?  data,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchPreviewRequestResultData() when data != null:
return data(_that.data);case SearchPreviewRequestResultError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Object data)  data,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SearchPreviewRequestResultData():
return data(_that.data);case SearchPreviewRequestResultError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Object data)?  data,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SearchPreviewRequestResultData() when data != null:
return data(_that.data);case SearchPreviewRequestResultError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchPreviewRequestResultData with DiagnosticableTreeMixin implements SearchPreviewRequestResult {
  const SearchPreviewRequestResultData({required this.data});
  

 final  Object data;

/// Create a copy of SearchPreviewRequestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPreviewRequestResultDataCopyWith<SearchPreviewRequestResultData> get copyWith => _$SearchPreviewRequestResultDataCopyWithImpl<SearchPreviewRequestResultData>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequestResult.data'))
    ..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPreviewRequestResultData&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchPreviewRequestResult.data(data: $data)';
}


}

/// @nodoc
abstract mixin class $SearchPreviewRequestResultDataCopyWith<$Res> implements $SearchPreviewRequestResultCopyWith<$Res> {
  factory $SearchPreviewRequestResultDataCopyWith(SearchPreviewRequestResultData value, $Res Function(SearchPreviewRequestResultData) _then) = _$SearchPreviewRequestResultDataCopyWithImpl;
@useResult
$Res call({
 Object data
});




}
/// @nodoc
class _$SearchPreviewRequestResultDataCopyWithImpl<$Res>
    implements $SearchPreviewRequestResultDataCopyWith<$Res> {
  _$SearchPreviewRequestResultDataCopyWithImpl(this._self, this._then);

  final SearchPreviewRequestResultData _self;
  final $Res Function(SearchPreviewRequestResultData) _then;

/// Create a copy of SearchPreviewRequestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(SearchPreviewRequestResultData(
data: null == data ? _self.data : data ,
  ));
}


}

/// @nodoc


class SearchPreviewRequestResultError with DiagnosticableTreeMixin implements SearchPreviewRequestResult {
  const SearchPreviewRequestResultError({required this.message});
  

 final  String message;

/// Create a copy of SearchPreviewRequestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPreviewRequestResultErrorCopyWith<SearchPreviewRequestResultError> get copyWith => _$SearchPreviewRequestResultErrorCopyWithImpl<SearchPreviewRequestResultError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequestResult.error'))
    ..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPreviewRequestResultError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchPreviewRequestResult.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchPreviewRequestResultErrorCopyWith<$Res> implements $SearchPreviewRequestResultCopyWith<$Res> {
  factory $SearchPreviewRequestResultErrorCopyWith(SearchPreviewRequestResultError value, $Res Function(SearchPreviewRequestResultError) _then) = _$SearchPreviewRequestResultErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SearchPreviewRequestResultErrorCopyWithImpl<$Res>
    implements $SearchPreviewRequestResultErrorCopyWith<$Res> {
  _$SearchPreviewRequestResultErrorCopyWithImpl(this._self, this._then);

  final SearchPreviewRequestResultError _self;
  final $Res Function(SearchPreviewRequestResultError) _then;

/// Create a copy of SearchPreviewRequestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SearchPreviewRequestResultError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
