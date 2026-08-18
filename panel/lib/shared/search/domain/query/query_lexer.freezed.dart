// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'query_lexer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueryLexerToken {

 String get raw; QueryRange get range; List<QueryParseIssue> get issues;
/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryLexerTokenCopyWith<QueryLexerToken> get copyWith => _$QueryLexerTokenCopyWithImpl<QueryLexerToken>(this as QueryLexerToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryLexerToken&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.issues, issues));
}


@override
int get hashCode => Object.hash(runtimeType,raw,range,const DeepCollectionEquality().hash(issues));

@override
String toString() {
  return 'QueryLexerToken(raw: $raw, range: $range, issues: $issues)';
}


}

/// @nodoc
abstract mixin class $QueryLexerTokenCopyWith<$Res>  {
  factory $QueryLexerTokenCopyWith(QueryLexerToken value, $Res Function(QueryLexerToken) _then) = _$QueryLexerTokenCopyWithImpl;
@useResult
$Res call({
 String raw, QueryRange range, List<QueryParseIssue> issues
});




}
/// @nodoc
class _$QueryLexerTokenCopyWithImpl<$Res>
    implements $QueryLexerTokenCopyWith<$Res> {
  _$QueryLexerTokenCopyWithImpl(this._self, this._then);

  final QueryLexerToken _self;
  final $Res Function(QueryLexerToken) _then;

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? raw = null,Object? range = null,Object? issues = null,}) {
  return _then(_self.copyWith(
raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as QueryRange,issues: null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<QueryParseIssue>,
  ));
}

}


/// Adds pattern-matching-related methods to [QueryLexerToken].
extension QueryLexerTokenPatterns on QueryLexerToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QueryLexerKeyValueSelectorToken value)?  keyValueSelector,TResult Function( QueryLexerOperatorToken value)?  operator,TResult Function( QueryLexerNegationToken value)?  negation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken() when keyValueSelector != null:
return keyValueSelector(_that);case QueryLexerOperatorToken() when operator != null:
return operator(_that);case QueryLexerNegationToken() when negation != null:
return negation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QueryLexerKeyValueSelectorToken value)  keyValueSelector,required TResult Function( QueryLexerOperatorToken value)  operator,required TResult Function( QueryLexerNegationToken value)  negation,}){
final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken():
return keyValueSelector(_that);case QueryLexerOperatorToken():
return operator(_that);case QueryLexerNegationToken():
return negation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QueryLexerKeyValueSelectorToken value)?  keyValueSelector,TResult? Function( QueryLexerOperatorToken value)?  operator,TResult? Function( QueryLexerNegationToken value)?  negation,}){
final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken() when keyValueSelector != null:
return keyValueSelector(_that);case QueryLexerOperatorToken() when operator != null:
return operator(_that);case QueryLexerNegationToken() when negation != null:
return negation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String selectorId,  QueryRange keyRange,  String raw,  QueryRange range,  String? value,  QueryRange? valueRange,  List<QueryParseIssue> issues)?  keyValueSelector,TResult Function( QueryLexerOperatorType type,  String raw,  QueryRange range,  QueryLexerToken left,  QueryLexerToken right,  QueryRange? operatorRange,  List<QueryParseIssue> issues)?  operator,TResult Function( QueryLexerToken token,  String raw,  QueryRange range,  QueryRange operatorRange,  List<QueryParseIssue> issues)?  negation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken() when keyValueSelector != null:
return keyValueSelector(_that.selectorId,_that.keyRange,_that.raw,_that.range,_that.value,_that.valueRange,_that.issues);case QueryLexerOperatorToken() when operator != null:
return operator(_that.type,_that.raw,_that.range,_that.left,_that.right,_that.operatorRange,_that.issues);case QueryLexerNegationToken() when negation != null:
return negation(_that.token,_that.raw,_that.range,_that.operatorRange,_that.issues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String selectorId,  QueryRange keyRange,  String raw,  QueryRange range,  String? value,  QueryRange? valueRange,  List<QueryParseIssue> issues)  keyValueSelector,required TResult Function( QueryLexerOperatorType type,  String raw,  QueryRange range,  QueryLexerToken left,  QueryLexerToken right,  QueryRange? operatorRange,  List<QueryParseIssue> issues)  operator,required TResult Function( QueryLexerToken token,  String raw,  QueryRange range,  QueryRange operatorRange,  List<QueryParseIssue> issues)  negation,}) {final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken():
return keyValueSelector(_that.selectorId,_that.keyRange,_that.raw,_that.range,_that.value,_that.valueRange,_that.issues);case QueryLexerOperatorToken():
return operator(_that.type,_that.raw,_that.range,_that.left,_that.right,_that.operatorRange,_that.issues);case QueryLexerNegationToken():
return negation(_that.token,_that.raw,_that.range,_that.operatorRange,_that.issues);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String selectorId,  QueryRange keyRange,  String raw,  QueryRange range,  String? value,  QueryRange? valueRange,  List<QueryParseIssue> issues)?  keyValueSelector,TResult? Function( QueryLexerOperatorType type,  String raw,  QueryRange range,  QueryLexerToken left,  QueryLexerToken right,  QueryRange? operatorRange,  List<QueryParseIssue> issues)?  operator,TResult? Function( QueryLexerToken token,  String raw,  QueryRange range,  QueryRange operatorRange,  List<QueryParseIssue> issues)?  negation,}) {final _that = this;
switch (_that) {
case QueryLexerKeyValueSelectorToken() when keyValueSelector != null:
return keyValueSelector(_that.selectorId,_that.keyRange,_that.raw,_that.range,_that.value,_that.valueRange,_that.issues);case QueryLexerOperatorToken() when operator != null:
return operator(_that.type,_that.raw,_that.range,_that.left,_that.right,_that.operatorRange,_that.issues);case QueryLexerNegationToken() when negation != null:
return negation(_that.token,_that.raw,_that.range,_that.operatorRange,_that.issues);case _:
  return null;

}
}

}

/// @nodoc


class QueryLexerKeyValueSelectorToken implements QueryLexerToken, QueryLexerSelectorToken {
  const QueryLexerKeyValueSelectorToken({required this.selectorId, required this.keyRange, required this.raw, required this.range, this.value, this.valueRange, final  List<QueryParseIssue> issues = const <QueryParseIssue>[]}): assert(value != null || issues.length > 0, 'When no value is provided, an issue must be present'),_issues = issues;


 final  String selectorId;
 final  QueryRange keyRange;
@override final  String raw;
@override final  QueryRange range;
 final  String? value;
 final  QueryRange? valueRange;
 final  List<QueryParseIssue> _issues;
@override@JsonKey() List<QueryParseIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}


/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryLexerKeyValueSelectorTokenCopyWith<QueryLexerKeyValueSelectorToken> get copyWith => _$QueryLexerKeyValueSelectorTokenCopyWithImpl<QueryLexerKeyValueSelectorToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryLexerKeyValueSelectorToken&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId)&&(identical(other.keyRange, keyRange) || other.keyRange == keyRange)&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.range, range) || other.range == range)&&(identical(other.value, value) || other.value == value)&&(identical(other.valueRange, valueRange) || other.valueRange == valueRange)&&const DeepCollectionEquality().equals(other._issues, _issues));
}


@override
int get hashCode => Object.hash(runtimeType,selectorId,keyRange,raw,range,value,valueRange,const DeepCollectionEquality().hash(_issues));

@override
String toString() {
  return 'QueryLexerToken.keyValueSelector(selectorId: $selectorId, keyRange: $keyRange, raw: $raw, range: $range, value: $value, valueRange: $valueRange, issues: $issues)';
}


}

/// @nodoc
abstract mixin class $QueryLexerKeyValueSelectorTokenCopyWith<$Res> implements $QueryLexerTokenCopyWith<$Res> {
  factory $QueryLexerKeyValueSelectorTokenCopyWith(QueryLexerKeyValueSelectorToken value, $Res Function(QueryLexerKeyValueSelectorToken) _then) = _$QueryLexerKeyValueSelectorTokenCopyWithImpl;
@override @useResult
$Res call({
 String selectorId, QueryRange keyRange, String raw, QueryRange range, String? value, QueryRange? valueRange, List<QueryParseIssue> issues
});




}
/// @nodoc
class _$QueryLexerKeyValueSelectorTokenCopyWithImpl<$Res>
    implements $QueryLexerKeyValueSelectorTokenCopyWith<$Res> {
  _$QueryLexerKeyValueSelectorTokenCopyWithImpl(this._self, this._then);

  final QueryLexerKeyValueSelectorToken _self;
  final $Res Function(QueryLexerKeyValueSelectorToken) _then;

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectorId = null,Object? keyRange = null,Object? raw = null,Object? range = null,Object? value = freezed,Object? valueRange = freezed,Object? issues = null,}) {
  return _then(QueryLexerKeyValueSelectorToken(
selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,keyRange: null == keyRange ? _self.keyRange : keyRange // ignore: cast_nullable_to_non_nullable
as QueryRange,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as QueryRange,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,valueRange: freezed == valueRange ? _self.valueRange : valueRange // ignore: cast_nullable_to_non_nullable
as QueryRange?,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<QueryParseIssue>,
  ));
}


}

/// @nodoc


class QueryLexerOperatorToken implements QueryLexerToken {
  const QueryLexerOperatorToken({required this.type, required this.raw, required this.range, required this.left, required this.right, required this.operatorRange, final  List<QueryParseIssue> issues = const <QueryParseIssue>[]}): _issues = issues;


 final  QueryLexerOperatorType type;
@override final  String raw;
@override final  QueryRange range;
 final  QueryLexerToken left;
 final  QueryLexerToken right;
 final  QueryRange? operatorRange;
 final  List<QueryParseIssue> _issues;
@override@JsonKey() List<QueryParseIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}


/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryLexerOperatorTokenCopyWith<QueryLexerOperatorToken> get copyWith => _$QueryLexerOperatorTokenCopyWithImpl<QueryLexerOperatorToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryLexerOperatorToken&&(identical(other.type, type) || other.type == type)&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.range, range) || other.range == range)&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right)&&(identical(other.operatorRange, operatorRange) || other.operatorRange == operatorRange)&&const DeepCollectionEquality().equals(other._issues, _issues));
}


@override
int get hashCode => Object.hash(runtimeType,type,raw,range,left,right,operatorRange,const DeepCollectionEquality().hash(_issues));

@override
String toString() {
  return 'QueryLexerToken.operator(type: $type, raw: $raw, range: $range, left: $left, right: $right, operatorRange: $operatorRange, issues: $issues)';
}


}

/// @nodoc
abstract mixin class $QueryLexerOperatorTokenCopyWith<$Res> implements $QueryLexerTokenCopyWith<$Res> {
  factory $QueryLexerOperatorTokenCopyWith(QueryLexerOperatorToken value, $Res Function(QueryLexerOperatorToken) _then) = _$QueryLexerOperatorTokenCopyWithImpl;
@override @useResult
$Res call({
 QueryLexerOperatorType type, String raw, QueryRange range, QueryLexerToken left, QueryLexerToken right, QueryRange? operatorRange, List<QueryParseIssue> issues
});


$QueryLexerTokenCopyWith<$Res> get left;$QueryLexerTokenCopyWith<$Res> get right;

}
/// @nodoc
class _$QueryLexerOperatorTokenCopyWithImpl<$Res>
    implements $QueryLexerOperatorTokenCopyWith<$Res> {
  _$QueryLexerOperatorTokenCopyWithImpl(this._self, this._then);

  final QueryLexerOperatorToken _self;
  final $Res Function(QueryLexerOperatorToken) _then;

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? raw = null,Object? range = null,Object? left = null,Object? right = null,Object? operatorRange = freezed,Object? issues = null,}) {
  return _then(QueryLexerOperatorToken(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as QueryLexerOperatorType,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as QueryRange,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as QueryLexerToken,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as QueryLexerToken,operatorRange: freezed == operatorRange ? _self.operatorRange : operatorRange // ignore: cast_nullable_to_non_nullable
as QueryRange?,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<QueryParseIssue>,
  ));
}

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueryLexerTokenCopyWith<$Res> get left {

  return $QueryLexerTokenCopyWith<$Res>(_self.left, (value) {
    return _then(_self.copyWith(left: value));
  });
}/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueryLexerTokenCopyWith<$Res> get right {

  return $QueryLexerTokenCopyWith<$Res>(_self.right, (value) {
    return _then(_self.copyWith(right: value));
  });
}
}

/// @nodoc


class QueryLexerNegationToken implements QueryLexerToken {
  const QueryLexerNegationToken({required this.token, required this.raw, required this.range, required this.operatorRange, final  List<QueryParseIssue> issues = const <QueryParseIssue>[]}): _issues = issues;


 final  QueryLexerToken token;
@override final  String raw;
@override final  QueryRange range;
 final  QueryRange operatorRange;
 final  List<QueryParseIssue> _issues;
@override@JsonKey() List<QueryParseIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}


/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryLexerNegationTokenCopyWith<QueryLexerNegationToken> get copyWith => _$QueryLexerNegationTokenCopyWithImpl<QueryLexerNegationToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryLexerNegationToken&&(identical(other.token, token) || other.token == token)&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.range, range) || other.range == range)&&(identical(other.operatorRange, operatorRange) || other.operatorRange == operatorRange)&&const DeepCollectionEquality().equals(other._issues, _issues));
}


@override
int get hashCode => Object.hash(runtimeType,token,raw,range,operatorRange,const DeepCollectionEquality().hash(_issues));

@override
String toString() {
  return 'QueryLexerToken.negation(token: $token, raw: $raw, range: $range, operatorRange: $operatorRange, issues: $issues)';
}


}

/// @nodoc
abstract mixin class $QueryLexerNegationTokenCopyWith<$Res> implements $QueryLexerTokenCopyWith<$Res> {
  factory $QueryLexerNegationTokenCopyWith(QueryLexerNegationToken value, $Res Function(QueryLexerNegationToken) _then) = _$QueryLexerNegationTokenCopyWithImpl;
@override @useResult
$Res call({
 QueryLexerToken token, String raw, QueryRange range, QueryRange operatorRange, List<QueryParseIssue> issues
});


$QueryLexerTokenCopyWith<$Res> get token;

}
/// @nodoc
class _$QueryLexerNegationTokenCopyWithImpl<$Res>
    implements $QueryLexerNegationTokenCopyWith<$Res> {
  _$QueryLexerNegationTokenCopyWithImpl(this._self, this._then);

  final QueryLexerNegationToken _self;
  final $Res Function(QueryLexerNegationToken) _then;

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? raw = null,Object? range = null,Object? operatorRange = null,Object? issues = null,}) {
  return _then(QueryLexerNegationToken(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as QueryLexerToken,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as QueryRange,operatorRange: null == operatorRange ? _self.operatorRange : operatorRange // ignore: cast_nullable_to_non_nullable
as QueryRange,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<QueryParseIssue>,
  ));
}

/// Create a copy of QueryLexerToken
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueryLexerTokenCopyWith<$Res> get token {

  return $QueryLexerTokenCopyWith<$Res>(_self.token, (value) {
    return _then(_self.copyWith(token: value));
  });
}
}

// dart format on
