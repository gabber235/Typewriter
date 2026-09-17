// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
  final _this = this as SearchParsedSelector;
  properties
    ..add(DiagnosticsProperty('type', 'SearchParsedSelector'))
    ..add(DiagnosticsProperty('selectorId', _this.selectorId))..add(DiagnosticsProperty('key', _this.key))..add(DiagnosticsProperty('value', _this.value));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchParsedSelector;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchParsedSelector&&(identical(other.selectorId, _this.selectorId) || other.selectorId == _this.selectorId)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as SearchParsedSelector;
  return Object.hash(runtimeType,_this.selectorId,_this.key,_this.value);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchParsedSelector;
  return 'SearchParsedSelector(selectorId: ${_this.selectorId}, key: ${_this.key}, value: ${_this.value})';
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
  return _then(SearchParsedSelector(
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
  const _SearchParsedSelector({required this.selectorId, required this.key, this.value}): assert(selectorId != "", 'Selector ID must not be empty.'),assert(key != "", 'Key must not be empty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,selectorId,key,value);
}

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
mixin _$SearchSelectorExpression implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSelectorExpression'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorExpression);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSelectorExpression()';
}


}

/// @nodoc
class $SearchSelectorExpressionCopyWith<$Res>  {
$SearchSelectorExpressionCopyWith(SearchSelectorExpression _, $Res Function(SearchSelectorExpression) __);
}


/// Adds pattern-matching-related methods to [SearchSelectorExpression].
extension SearchSelectorExpressionPatterns on SearchSelectorExpression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchSelectorLeafExpression value)?  leaf,TResult Function( SearchSelectorBinaryExpression value)?  binary,TResult Function( SearchSelectorNotExpression value)?  not,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchSelectorLeafExpression() when leaf != null:
return leaf(_that);case SearchSelectorBinaryExpression() when binary != null:
return binary(_that);case SearchSelectorNotExpression() when not != null:
return not(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchSelectorLeafExpression value)  leaf,required TResult Function( SearchSelectorBinaryExpression value)  binary,required TResult Function( SearchSelectorNotExpression value)  not,}){
final _that = this;
switch (_that) {
case SearchSelectorLeafExpression():
return leaf(_that);case SearchSelectorBinaryExpression():
return binary(_that);case SearchSelectorNotExpression():
return not(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchSelectorLeafExpression value)?  leaf,TResult? Function( SearchSelectorBinaryExpression value)?  binary,TResult? Function( SearchSelectorNotExpression value)?  not,}){
final _that = this;
switch (_that) {
case SearchSelectorLeafExpression() when leaf != null:
return leaf(_that);case SearchSelectorBinaryExpression() when binary != null:
return binary(_that);case SearchSelectorNotExpression() when not != null:
return not(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SearchParsedSelector selector)?  leaf,TResult Function( SearchSelectorOperator operator,  SearchSelectorExpression left,  SearchSelectorExpression right)?  binary,TResult Function( SearchSelectorExpression expression)?  not,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchSelectorLeafExpression() when leaf != null:
return leaf(_that.selector);case SearchSelectorBinaryExpression() when binary != null:
return binary(_that.operator,_that.left,_that.right);case SearchSelectorNotExpression() when not != null:
return not(_that.expression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SearchParsedSelector selector)  leaf,required TResult Function( SearchSelectorOperator operator,  SearchSelectorExpression left,  SearchSelectorExpression right)  binary,required TResult Function( SearchSelectorExpression expression)  not,}) {final _that = this;
switch (_that) {
case SearchSelectorLeafExpression():
return leaf(_that.selector);case SearchSelectorBinaryExpression():
return binary(_that.operator,_that.left,_that.right);case SearchSelectorNotExpression():
return not(_that.expression);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SearchParsedSelector selector)?  leaf,TResult? Function( SearchSelectorOperator operator,  SearchSelectorExpression left,  SearchSelectorExpression right)?  binary,TResult? Function( SearchSelectorExpression expression)?  not,}) {final _that = this;
switch (_that) {
case SearchSelectorLeafExpression() when leaf != null:
return leaf(_that.selector);case SearchSelectorBinaryExpression() when binary != null:
return binary(_that.operator,_that.left,_that.right);case SearchSelectorNotExpression() when not != null:
return not(_that.expression);case _:
  return null;

}
}

}

/// @nodoc


class SearchSelectorLeafExpression with DiagnosticableTreeMixin implements SearchSelectorExpression {
  const SearchSelectorLeafExpression(this.selector);
  

 final  SearchParsedSelector selector;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSelectorLeafExpressionCopyWith<SearchSelectorLeafExpression> get copyWith => _$SearchSelectorLeafExpressionCopyWithImpl<SearchSelectorLeafExpression>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSelectorExpression.leaf'))
    ..add(DiagnosticsProperty('selector', selector));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorLeafExpression&&(identical(other.selector, selector) || other.selector == selector));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selector);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSelectorExpression.leaf(selector: $selector)';
}


}

/// @nodoc
abstract mixin class $SearchSelectorLeafExpressionCopyWith<$Res> implements $SearchSelectorExpressionCopyWith<$Res> {
  factory $SearchSelectorLeafExpressionCopyWith(SearchSelectorLeafExpression value, $Res Function(SearchSelectorLeafExpression) _then) = _$SearchSelectorLeafExpressionCopyWithImpl;
@useResult
$Res call({
 SearchParsedSelector selector
});


$SearchParsedSelectorCopyWith<$Res> get selector;

}
/// @nodoc
class _$SearchSelectorLeafExpressionCopyWithImpl<$Res>
    implements $SearchSelectorLeafExpressionCopyWith<$Res> {
  _$SearchSelectorLeafExpressionCopyWithImpl(this._self, this._then);

  final SearchSelectorLeafExpression _self;
  final $Res Function(SearchSelectorLeafExpression) _then;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selector = null,}) {
  return _then(SearchSelectorLeafExpression(
null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as SearchParsedSelector,
  ));
}

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchParsedSelectorCopyWith<$Res> get selector {
  
  return $SearchParsedSelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}
}

/// @nodoc


class SearchSelectorBinaryExpression with DiagnosticableTreeMixin implements SearchSelectorExpression {
  const SearchSelectorBinaryExpression({required this.operator, required this.left, required this.right});
  

 final  SearchSelectorOperator operator;
 final  SearchSelectorExpression left;
 final  SearchSelectorExpression right;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSelectorBinaryExpressionCopyWith<SearchSelectorBinaryExpression> get copyWith => _$SearchSelectorBinaryExpressionCopyWithImpl<SearchSelectorBinaryExpression>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSelectorExpression.binary'))
    ..add(DiagnosticsProperty('operator', operator))..add(DiagnosticsProperty('left', left))..add(DiagnosticsProperty('right', right));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorBinaryExpression&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}


@override
int get hashCode {
    return Object.hash(runtimeType,operator,left,right);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSelectorExpression.binary(operator: $operator, left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class $SearchSelectorBinaryExpressionCopyWith<$Res> implements $SearchSelectorExpressionCopyWith<$Res> {
  factory $SearchSelectorBinaryExpressionCopyWith(SearchSelectorBinaryExpression value, $Res Function(SearchSelectorBinaryExpression) _then) = _$SearchSelectorBinaryExpressionCopyWithImpl;
@useResult
$Res call({
 SearchSelectorOperator operator, SearchSelectorExpression left, SearchSelectorExpression right
});


$SearchSelectorExpressionCopyWith<$Res> get left;$SearchSelectorExpressionCopyWith<$Res> get right;

}
/// @nodoc
class _$SearchSelectorBinaryExpressionCopyWithImpl<$Res>
    implements $SearchSelectorBinaryExpressionCopyWith<$Res> {
  _$SearchSelectorBinaryExpressionCopyWithImpl(this._self, this._then);

  final SearchSelectorBinaryExpression _self;
  final $Res Function(SearchSelectorBinaryExpression) _then;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operator = null,Object? left = null,Object? right = null,}) {
  return _then(SearchSelectorBinaryExpression(
operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as SearchSelectorOperator,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression,
  ));
}

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorExpressionCopyWith<$Res> get left {
  
  return $SearchSelectorExpressionCopyWith<$Res>(_self.left, (value) {
    return _then(_self.copyWith(left: value));
  });
}/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorExpressionCopyWith<$Res> get right {
  
  return $SearchSelectorExpressionCopyWith<$Res>(_self.right, (value) {
    return _then(_self.copyWith(right: value));
  });
}
}

/// @nodoc


class SearchSelectorNotExpression with DiagnosticableTreeMixin implements SearchSelectorExpression {
  const SearchSelectorNotExpression(this.expression);
  

 final  SearchSelectorExpression expression;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSelectorNotExpressionCopyWith<SearchSelectorNotExpression> get copyWith => _$SearchSelectorNotExpressionCopyWithImpl<SearchSelectorNotExpression>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSelectorExpression.not'))
    ..add(DiagnosticsProperty('expression', expression));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorNotExpression&&(identical(other.expression, expression) || other.expression == expression));
}


@override
int get hashCode {
    return Object.hash(runtimeType,expression);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSelectorExpression.not(expression: $expression)';
}


}

/// @nodoc
abstract mixin class $SearchSelectorNotExpressionCopyWith<$Res> implements $SearchSelectorExpressionCopyWith<$Res> {
  factory $SearchSelectorNotExpressionCopyWith(SearchSelectorNotExpression value, $Res Function(SearchSelectorNotExpression) _then) = _$SearchSelectorNotExpressionCopyWithImpl;
@useResult
$Res call({
 SearchSelectorExpression expression
});


$SearchSelectorExpressionCopyWith<$Res> get expression;

}
/// @nodoc
class _$SearchSelectorNotExpressionCopyWithImpl<$Res>
    implements $SearchSelectorNotExpressionCopyWith<$Res> {
  _$SearchSelectorNotExpressionCopyWithImpl(this._self, this._then);

  final SearchSelectorNotExpression _self;
  final $Res Function(SearchSelectorNotExpression) _then;

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expression = null,}) {
  return _then(SearchSelectorNotExpression(
null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression,
  ));
}

/// Create a copy of SearchSelectorExpression
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorExpressionCopyWith<$Res> get expression {
  
  return $SearchSelectorExpressionCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}

/// @nodoc
mixin _$SearchQueryContext implements DiagnosticableTreeMixin {

 String get normalizedQuery; List<SearchParsedSelector> get selectors; List<String> get terms; SearchSelectorExpression? get selectorExpression;
/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<SearchQueryContext> get copyWith => _$SearchQueryContextCopyWithImpl<SearchQueryContext>(this as SearchQueryContext, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchQueryContext;
  properties
    ..add(DiagnosticsProperty('type', 'SearchQueryContext'))
    ..add(DiagnosticsProperty('normalizedQuery', _this.normalizedQuery))..add(DiagnosticsProperty('selectors', _this.selectors))..add(DiagnosticsProperty('terms', _this.terms))..add(DiagnosticsProperty('selectorExpression', _this.selectorExpression));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchQueryContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchQueryContext&&(identical(other.normalizedQuery, _this.normalizedQuery) || other.normalizedQuery == _this.normalizedQuery)&&const DeepCollectionEquality().equals(other.selectors, _this.selectors)&&const DeepCollectionEquality().equals(other.terms, _this.terms)&&(identical(other.selectorExpression, _this.selectorExpression) || other.selectorExpression == _this.selectorExpression));
}


@override
int get hashCode {
  final _this = this as SearchQueryContext;
  return Object.hash(runtimeType,_this.normalizedQuery,const DeepCollectionEquality().hash(_this.selectors),const DeepCollectionEquality().hash(_this.terms),_this.selectorExpression);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchQueryContext;
  return 'SearchQueryContext(normalizedQuery: ${_this.normalizedQuery}, selectors: ${_this.selectors}, terms: ${_this.terms}, selectorExpression: ${_this.selectorExpression})';
}


}

/// @nodoc
abstract mixin class $SearchQueryContextCopyWith<$Res>  {
  factory $SearchQueryContextCopyWith(SearchQueryContext value, $Res Function(SearchQueryContext) _then) = _$SearchQueryContextCopyWithImpl;
@useResult
$Res call({
 String normalizedQuery, List<SearchParsedSelector> selectors, List<String> terms, SearchSelectorExpression? selectorExpression
});


$SearchSelectorExpressionCopyWith<$Res>? get selectorExpression;

}
/// @nodoc
class _$SearchQueryContextCopyWithImpl<$Res>
    implements $SearchQueryContextCopyWith<$Res> {
  _$SearchQueryContextCopyWithImpl(this._self, this._then);

  final SearchQueryContext _self;
  final $Res Function(SearchQueryContext) _then;

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? normalizedQuery = null,Object? selectors = null,Object? terms = null,Object? selectorExpression = freezed,}) {
  return _then(SearchQueryContext(
normalizedQuery: null == normalizedQuery ? _self.normalizedQuery : normalizedQuery // ignore: cast_nullable_to_non_nullable
as String,selectors: null == selectors ? _self.selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchParsedSelector>,terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as List<String>,selectorExpression: freezed == selectorExpression ? _self.selectorExpression : selectorExpression // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression?,
  ));
}
/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorExpressionCopyWith<$Res>? get selectorExpression {
    if (_self.selectorExpression == null) {
    return null;
  }

  return $SearchSelectorExpressionCopyWith<$Res>(_self.selectorExpression!, (value) {
    return _then(_self.copyWith(selectorExpression: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  List<String> terms,  SearchSelectorExpression? selectorExpression)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
return $default(_that.normalizedQuery,_that.selectors,_that.terms,_that.selectorExpression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  List<String> terms,  SearchSelectorExpression? selectorExpression)  $default,) {final _that = this;
switch (_that) {
case _SearchQueryContext():
return $default(_that.normalizedQuery,_that.selectors,_that.terms,_that.selectorExpression);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String normalizedQuery,  List<SearchParsedSelector> selectors,  List<String> terms,  SearchSelectorExpression? selectorExpression)?  $default,) {final _that = this;
switch (_that) {
case _SearchQueryContext() when $default != null:
return $default(_that.normalizedQuery,_that.selectors,_that.terms,_that.selectorExpression);case _:
  return null;

}
}

}

/// @nodoc


class _SearchQueryContext with DiagnosticableTreeMixin implements SearchQueryContext {
  const _SearchQueryContext({required this.normalizedQuery, required  List<SearchParsedSelector> selectors,  List<String> terms = const <String>[], this.selectorExpression}): _selectors = selectors,_terms = terms;
  

@override final  String normalizedQuery;
 final  List<SearchParsedSelector> _selectors;
@override List<SearchParsedSelector> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}

 final  List<String> _terms;
@override@JsonKey() List<String> get terms {
  if (_terms is EqualUnmodifiableListView) return _terms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_terms);
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
    ..add(DiagnosticsProperty('normalizedQuery', normalizedQuery))..add(DiagnosticsProperty('selectors', selectors))..add(DiagnosticsProperty('terms', terms))..add(DiagnosticsProperty('selectorExpression', selectorExpression));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchQueryContext&&(identical(other.normalizedQuery, normalizedQuery) || other.normalizedQuery == normalizedQuery)&&const DeepCollectionEquality().equals(other.selectors, _selectors)&&const DeepCollectionEquality().equals(other.terms, _terms)&&(identical(other.selectorExpression, selectorExpression) || other.selectorExpression == selectorExpression));
}


@override
int get hashCode {
    return Object.hash(runtimeType,normalizedQuery,const DeepCollectionEquality().hash(_selectors),const DeepCollectionEquality().hash(_terms),selectorExpression);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchQueryContext(normalizedQuery: $normalizedQuery, selectors: $selectors, terms: $terms, selectorExpression: $selectorExpression)';
}


}

/// @nodoc
abstract mixin class _$SearchQueryContextCopyWith<$Res> implements $SearchQueryContextCopyWith<$Res> {
  factory _$SearchQueryContextCopyWith(_SearchQueryContext value, $Res Function(_SearchQueryContext) _then) = __$SearchQueryContextCopyWithImpl;
@override @useResult
$Res call({
 String normalizedQuery, List<SearchParsedSelector> selectors, List<String> terms, SearchSelectorExpression? selectorExpression
});


@override $SearchSelectorExpressionCopyWith<$Res>? get selectorExpression;

}
/// @nodoc
class __$SearchQueryContextCopyWithImpl<$Res>
    implements _$SearchQueryContextCopyWith<$Res> {
  __$SearchQueryContextCopyWithImpl(this._self, this._then);

  final _SearchQueryContext _self;
  final $Res Function(_SearchQueryContext) _then;

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? normalizedQuery = null,Object? selectors = null,Object? terms = null,Object? selectorExpression = freezed,}) {
  return _then(_SearchQueryContext(
normalizedQuery: null == normalizedQuery ? _self.normalizedQuery : normalizedQuery // ignore: cast_nullable_to_non_nullable
as String,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchParsedSelector>,terms: null == terms ? _self._terms : terms // ignore: cast_nullable_to_non_nullable
as List<String>,selectorExpression: freezed == selectorExpression ? _self.selectorExpression : selectorExpression // ignore: cast_nullable_to_non_nullable
as SearchSelectorExpression?,
  ));
}

/// Create a copy of SearchQueryContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorExpressionCopyWith<$Res>? get selectorExpression {
    if (_self.selectorExpression == null) {
    return null;
  }

  return $SearchSelectorExpressionCopyWith<$Res>(_self.selectorExpression!, (value) {
    return _then(_self.copyWith(selectorExpression: value));
  });
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
  final _this = this as SearchGuidance;
  properties
    ..add(DiagnosticsProperty('type', 'SearchGuidance'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('title', _this.title))..add(DiagnosticsProperty('description', _this.description))..add(DiagnosticsProperty('visibility', _this.visibility))..add(DiagnosticsProperty('priority', _this.priority));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchGuidance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchGuidance&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.priority, _this.priority) || other.priority == _this.priority));
}


@override
int get hashCode {
  final _this = this as SearchGuidance;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.visibility,_this.priority);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchGuidance;
  return 'SearchGuidance(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, visibility: ${_this.visibility}, priority: ${_this.priority})';
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
  return _then(SearchGuidance(
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
  const _SearchGuidance({required this.id, required this.title, this.description, this.visibility = SearchGuidanceVisibility.emptyOnly, this.priority = 0}): assert(id != "", 'ID must not be empty.'),assert(title != "", 'Title must not be empty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,id,title,description,visibility,priority);
}

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
  final _this = this as SearchErrorSummary;
  properties
    ..add(DiagnosticsProperty('type', 'SearchErrorSummary'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('message', _this.message))..add(DiagnosticsProperty('severity', _this.severity))..add(DiagnosticsProperty('sourceLabel', _this.sourceLabel));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchErrorSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchErrorSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.sourceLabel, _this.sourceLabel) || other.sourceLabel == _this.sourceLabel));
}


@override
int get hashCode {
  final _this = this as SearchErrorSummary;
  return Object.hash(runtimeType,_this.id,_this.message,_this.severity,_this.sourceLabel);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchErrorSummary;
  return 'SearchErrorSummary(id: ${_this.id}, message: ${_this.message}, severity: ${_this.severity}, sourceLabel: ${_this.sourceLabel})';
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
  return _then(SearchErrorSummary(
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
  const _SearchErrorSummary({required this.id, required this.message, required this.severity, this.sourceLabel}): assert(id != "", 'ID must not be empty.'),assert(message != "", 'Message must not be empty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,id,message,severity,sourceLabel);
}

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

 SearchSourceStatus get status; List<SearchNode> get nodes; List<SearchGuidance> get guidance; List<SearchErrorSummary> get errorSummaries; List<SearchSelectorValidation> get selectorValidations;
/// Create a copy of SearchSourceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSourceSnapshotCopyWith<SearchSourceSnapshot> get copyWith => _$SearchSourceSnapshotCopyWithImpl<SearchSourceSnapshot>(this as SearchSourceSnapshot, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchSourceSnapshot;
  properties
    ..add(DiagnosticsProperty('type', 'SearchSourceSnapshot'))
    ..add(DiagnosticsProperty('status', _this.status))..add(DiagnosticsProperty('nodes', _this.nodes))..add(DiagnosticsProperty('guidance', _this.guidance))..add(DiagnosticsProperty('errorSummaries', _this.errorSummaries))..add(DiagnosticsProperty('selectorValidations', _this.selectorValidations));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchSourceSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSourceSnapshot&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.nodes, _this.nodes)&&const DeepCollectionEquality().equals(other.guidance, _this.guidance)&&const DeepCollectionEquality().equals(other.errorSummaries, _this.errorSummaries)&&const DeepCollectionEquality().equals(other.selectorValidations, _this.selectorValidations));
}


@override
int get hashCode {
  final _this = this as SearchSourceSnapshot;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.nodes),const DeepCollectionEquality().hash(_this.guidance),const DeepCollectionEquality().hash(_this.errorSummaries),const DeepCollectionEquality().hash(_this.selectorValidations));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchSourceSnapshot;
  return 'SearchSourceSnapshot(status: ${_this.status}, nodes: ${_this.nodes}, guidance: ${_this.guidance}, errorSummaries: ${_this.errorSummaries}, selectorValidations: ${_this.selectorValidations})';
}


}

/// @nodoc
abstract mixin class $SearchSourceSnapshotCopyWith<$Res>  {
  factory $SearchSourceSnapshotCopyWith(SearchSourceSnapshot value, $Res Function(SearchSourceSnapshot) _then) = _$SearchSourceSnapshotCopyWithImpl;
@useResult
$Res call({
 SearchSourceStatus status, List<SearchNode> nodes, List<SearchGuidance> guidance, List<SearchErrorSummary> errorSummaries, List<SearchSelectorValidation> selectorValidations
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
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? nodes = null,Object? guidance = null,Object? errorSummaries = null,Object? selectorValidations = null,}) {
  return _then(SearchSourceSnapshot(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchSourceStatus,nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<SearchNode>,guidance: null == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as List<SearchGuidance>,errorSummaries: null == errorSummaries ? _self.errorSummaries : errorSummaries // ignore: cast_nullable_to_non_nullable
as List<SearchErrorSummary>,selectorValidations: null == selectorValidations ? _self.selectorValidations : selectorValidations // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorValidation>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchSourceStatus status,  List<SearchNode> nodes,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries,  List<SearchSelectorValidation> selectorValidations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
return $default(_that.status,_that.nodes,_that.guidance,_that.errorSummaries,_that.selectorValidations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchSourceStatus status,  List<SearchNode> nodes,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries,  List<SearchSelectorValidation> selectorValidations)  $default,) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot():
return $default(_that.status,_that.nodes,_that.guidance,_that.errorSummaries,_that.selectorValidations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchSourceStatus status,  List<SearchNode> nodes,  List<SearchGuidance> guidance,  List<SearchErrorSummary> errorSummaries,  List<SearchSelectorValidation> selectorValidations)?  $default,) {final _that = this;
switch (_that) {
case _SearchSourceSnapshot() when $default != null:
return $default(_that.status,_that.nodes,_that.guidance,_that.errorSummaries,_that.selectorValidations);case _:
  return null;

}
}

}

/// @nodoc


class _SearchSourceSnapshot with DiagnosticableTreeMixin implements SearchSourceSnapshot {
  const _SearchSourceSnapshot({required this.status, required  List<SearchNode> nodes,  List<SearchGuidance> guidance = const <SearchGuidance>[],  List<SearchErrorSummary> errorSummaries = const <SearchErrorSummary>[],  List<SearchSelectorValidation> selectorValidations = const <SearchSelectorValidation>[]}): _nodes = nodes,_guidance = guidance,_errorSummaries = errorSummaries,_selectorValidations = selectorValidations;
  

@override final  SearchSourceStatus status;
 final  List<SearchNode> _nodes;
@override List<SearchNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
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

 final  List<SearchSelectorValidation> _selectorValidations;
@override@JsonKey() List<SearchSelectorValidation> get selectorValidations {
  if (_selectorValidations is EqualUnmodifiableListView) return _selectorValidations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectorValidations);
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
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('nodes', nodes))..add(DiagnosticsProperty('guidance', guidance))..add(DiagnosticsProperty('errorSummaries', errorSummaries))..add(DiagnosticsProperty('selectorValidations', selectorValidations));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchSourceSnapshot&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.nodes, _nodes)&&const DeepCollectionEquality().equals(other.guidance, _guidance)&&const DeepCollectionEquality().equals(other.errorSummaries, _errorSummaries)&&const DeepCollectionEquality().equals(other.selectorValidations, _selectorValidations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_guidance),const DeepCollectionEquality().hash(_errorSummaries),const DeepCollectionEquality().hash(_selectorValidations));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSourceSnapshot(status: $status, nodes: $nodes, guidance: $guidance, errorSummaries: $errorSummaries, selectorValidations: $selectorValidations)';
}


}

/// @nodoc
abstract mixin class _$SearchSourceSnapshotCopyWith<$Res> implements $SearchSourceSnapshotCopyWith<$Res> {
  factory _$SearchSourceSnapshotCopyWith(_SearchSourceSnapshot value, $Res Function(_SearchSourceSnapshot) _then) = __$SearchSourceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 SearchSourceStatus status, List<SearchNode> nodes, List<SearchGuidance> guidance, List<SearchErrorSummary> errorSummaries, List<SearchSelectorValidation> selectorValidations
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
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? nodes = null,Object? guidance = null,Object? errorSummaries = null,Object? selectorValidations = null,}) {
  return _then(_SearchSourceSnapshot(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchSourceStatus,nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<SearchNode>,guidance: null == guidance ? _self._guidance : guidance // ignore: cast_nullable_to_non_nullable
as List<SearchGuidance>,errorSummaries: null == errorSummaries ? _self._errorSummaries : errorSummaries // ignore: cast_nullable_to_non_nullable
as List<SearchErrorSummary>,selectorValidations: null == selectorValidations ? _self._selectorValidations : selectorValidations // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorValidation>,
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
  const SearchSectionNode({required this.id, required this.title, this.subtitle,  List<SearchNode> children = const <SearchNode>[]}): assert(id != "", 'ID must not be empty.'),assert(title != "", 'Title must not be empty.'),_children = children;
  

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSectionNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.children, _children));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,subtitle,const DeepCollectionEquality().hash(_children));
}

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
int get hashCode {
    return Object.hash(runtimeType,result);
}

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
  final _this = this as SearchResultType;
  properties
    ..add(DiagnosticsProperty('type', 'SearchResultType'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('rowRendererId', _this.rowRendererId))..add(DiagnosticsProperty('previewRendererId', _this.previewRendererId))..add(DiagnosticsProperty('label', _this.label));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchResultType;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultType&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.rowRendererId, _this.rowRendererId) || other.rowRendererId == _this.rowRendererId)&&(identical(other.previewRendererId, _this.previewRendererId) || other.previewRendererId == _this.previewRendererId)&&(identical(other.label, _this.label) || other.label == _this.label));
}


@override
int get hashCode {
  final _this = this as SearchResultType;
  return Object.hash(runtimeType,_this.id,_this.rowRendererId,_this.previewRendererId,_this.label);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchResultType;
  return 'SearchResultType(id: ${_this.id}, rowRendererId: ${_this.rowRendererId}, previewRendererId: ${_this.previewRendererId}, label: ${_this.label})';
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
  return _then(SearchResultType(
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
  const _SearchResultType({required this.id, required this.rowRendererId, this.previewRendererId, this.label}): assert(id != "", 'ID must not be empty.'),assert(rowRendererId != "", 'Row renderer ID must not be empty.'),assert(previewRendererId == null || previewRendererId != "", 'Preview renderer ID must be null or nonempty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,id,rowRendererId,previewRendererId,label);
}

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

 String get id; SearchResultType get type; Object get payload; String? get title; String? get subtitle; bool get isStale;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchResult;
  properties
    ..add(DiagnosticsProperty('type', 'SearchResult'))
    ..add(DiagnosticsProperty('id', _this.id))..add(DiagnosticsProperty('type', _this.type))..add(DiagnosticsProperty('payload', _this.payload))..add(DiagnosticsProperty('title', _this.title))..add(DiagnosticsProperty('subtitle', _this.subtitle))..add(DiagnosticsProperty('isStale', _this.isStale));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.isStale, _this.isStale) || other.isStale == _this.isStale));
}


@override
int get hashCode {
  final _this = this as SearchResult;
  return Object.hash(runtimeType,_this.id,_this.type,const DeepCollectionEquality().hash(_this.payload),_this.title,_this.subtitle,_this.isStale);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchResult;
  return 'SearchResult(id: ${_this.id}, type: ${_this.type}, payload: ${_this.payload}, title: ${_this.title}, subtitle: ${_this.subtitle}, isStale: ${_this.isStale})';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 String id, SearchResultType type, Object payload, String? title, String? subtitle, bool isStale
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? title = freezed,Object? subtitle = freezed,Object? isStale = null,}) {
  return _then(SearchResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,payload: null == payload ? _self.payload : payload ,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SearchResultType type,  Object payload,  String? title,  String? subtitle,  bool isStale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.title,_that.subtitle,_that.isStale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SearchResultType type,  Object payload,  String? title,  String? subtitle,  bool isStale)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.id,_that.type,_that.payload,_that.title,_that.subtitle,_that.isStale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SearchResultType type,  Object payload,  String? title,  String? subtitle,  bool isStale)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.title,_that.subtitle,_that.isStale);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResult with DiagnosticableTreeMixin implements SearchResult {
  const _SearchResult({required this.id, required this.type, required this.payload, this.title, this.subtitle, this.isStale = false}): assert(id != "", 'ID must not be empty.');
  

@override final  String id;
@override final  SearchResultType type;
@override final  Object payload;
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
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('payload', payload))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('subtitle', subtitle))..add(DiagnosticsProperty('isStale', isStale));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isStale, isStale) || other.isStale == isStale));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(payload),title,subtitle,isStale);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchResult(id: $id, type: $type, payload: $payload, title: $title, subtitle: $subtitle, isStale: $isStale)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 String id, SearchResultType type, Object payload, String? title, String? subtitle, bool isStale
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? title = freezed,Object? subtitle = freezed,Object? isStale = null,}) {
  return _then(_SearchResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,payload: null == payload ? _self.payload : payload ,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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
mixin _$SearchSurfaceEffect implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSurfaceEffect'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSurfaceEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSurfaceEffect()';
}


}

/// @nodoc
class $SearchSurfaceEffectCopyWith<$Res>  {
$SearchSurfaceEffectCopyWith(SearchSurfaceEffect _, $Res Function(SearchSurfaceEffect) __);
}


/// Adds pattern-matching-related methods to [SearchSurfaceEffect].
extension SearchSurfaceEffectPatterns on SearchSurfaceEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchSurfaceUpdateQuery value)?  updateQuery,TResult Function( SearchSurfaceRefresh value)?  refresh,TResult Function( SearchSurfaceClose value)?  close,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchSurfaceUpdateQuery() when updateQuery != null:
return updateQuery(_that);case SearchSurfaceRefresh() when refresh != null:
return refresh(_that);case SearchSurfaceClose() when close != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchSurfaceUpdateQuery value)  updateQuery,required TResult Function( SearchSurfaceRefresh value)  refresh,required TResult Function( SearchSurfaceClose value)  close,}){
final _that = this;
switch (_that) {
case SearchSurfaceUpdateQuery():
return updateQuery(_that);case SearchSurfaceRefresh():
return refresh(_that);case SearchSurfaceClose():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchSurfaceUpdateQuery value)?  updateQuery,TResult? Function( SearchSurfaceRefresh value)?  refresh,TResult? Function( SearchSurfaceClose value)?  close,}){
final _that = this;
switch (_that) {
case SearchSurfaceUpdateQuery() when updateQuery != null:
return updateQuery(_that);case SearchSurfaceRefresh() when refresh != null:
return refresh(_that);case SearchSurfaceClose() when close != null:
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
case SearchSurfaceUpdateQuery() when updateQuery != null:
return updateQuery(_that.updateQuery);case SearchSurfaceRefresh() when refresh != null:
return refresh();case SearchSurfaceClose() when close != null:
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
case SearchSurfaceUpdateQuery():
return updateQuery(_that.updateQuery);case SearchSurfaceRefresh():
return refresh();case SearchSurfaceClose():
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
case SearchSurfaceUpdateQuery() when updateQuery != null:
return updateQuery(_that.updateQuery);case SearchSurfaceRefresh() when refresh != null:
return refresh();case SearchSurfaceClose() when close != null:
return close();case _:
  return null;

}
}

}

/// @nodoc


class SearchSurfaceUpdateQuery with DiagnosticableTreeMixin implements SearchSurfaceEffect {
  const SearchSurfaceUpdateQuery({required this.updateQuery});
  

 final  String updateQuery;

/// Create a copy of SearchSurfaceEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSurfaceUpdateQueryCopyWith<SearchSurfaceUpdateQuery> get copyWith => _$SearchSurfaceUpdateQueryCopyWithImpl<SearchSurfaceUpdateQuery>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSurfaceEffect.updateQuery'))
    ..add(DiagnosticsProperty('updateQuery', updateQuery));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSurfaceUpdateQuery&&(identical(other.updateQuery, updateQuery) || other.updateQuery == updateQuery));
}


@override
int get hashCode {
    return Object.hash(runtimeType,updateQuery);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSurfaceEffect.updateQuery(updateQuery: $updateQuery)';
}


}

/// @nodoc
abstract mixin class $SearchSurfaceUpdateQueryCopyWith<$Res> implements $SearchSurfaceEffectCopyWith<$Res> {
  factory $SearchSurfaceUpdateQueryCopyWith(SearchSurfaceUpdateQuery value, $Res Function(SearchSurfaceUpdateQuery) _then) = _$SearchSurfaceUpdateQueryCopyWithImpl;
@useResult
$Res call({
 String updateQuery
});




}
/// @nodoc
class _$SearchSurfaceUpdateQueryCopyWithImpl<$Res>
    implements $SearchSurfaceUpdateQueryCopyWith<$Res> {
  _$SearchSurfaceUpdateQueryCopyWithImpl(this._self, this._then);

  final SearchSurfaceUpdateQuery _self;
  final $Res Function(SearchSurfaceUpdateQuery) _then;

/// Create a copy of SearchSurfaceEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateQuery = null,}) {
  return _then(SearchSurfaceUpdateQuery(
updateQuery: null == updateQuery ? _self.updateQuery : updateQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SearchSurfaceRefresh with DiagnosticableTreeMixin implements SearchSurfaceEffect {
  const SearchSurfaceRefresh();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSurfaceEffect.refresh'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSurfaceRefresh);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSurfaceEffect.refresh()';
}


}




/// @nodoc


class SearchSurfaceClose with DiagnosticableTreeMixin implements SearchSurfaceEffect {
  const SearchSurfaceClose();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSurfaceEffect.close'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSurfaceClose);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSurfaceEffect.close()';
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
  final _this = this as SearchPreviewRequest;
  properties
    ..add(DiagnosticsProperty('type', 'SearchPreviewRequest'))
    ..add(DiagnosticsProperty('resultId', _this.resultId))..add(DiagnosticsProperty('queryContext', _this.queryContext));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchPreviewRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPreviewRequest&&(identical(other.resultId, _this.resultId) || other.resultId == _this.resultId)&&(identical(other.queryContext, _this.queryContext) || other.queryContext == _this.queryContext));
}


@override
int get hashCode {
  final _this = this as SearchPreviewRequest;
  return Object.hash(runtimeType,_this.resultId,_this.queryContext);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchPreviewRequest;
  return 'SearchPreviewRequest(resultId: ${_this.resultId}, queryContext: ${_this.queryContext})';
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
  return _then(SearchPreviewRequest(
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
  const _SearchPreviewRequest({required this.resultId, this.queryContext}): assert(resultId != "", 'Result ID must not be empty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,resultId,queryContext);
}

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
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(data));
}

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
  const SearchPreviewRequestResultError({required this.message}): assert(message != "", 'Message must not be empty.');
  

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
int get hashCode {
    return Object.hash(runtimeType,message);
}

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
