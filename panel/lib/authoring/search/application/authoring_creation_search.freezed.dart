// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_creation_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringCreationOption {

 skir.TypeDefinitionId get type; skir.TypeSelection get configuration; String get label; skir.TypeDisplay? get display; SearchQueryContext get query; String? get disabledReason;
/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringCreationOptionCopyWith<AuthoringCreationOption> get copyWith => _$AuthoringCreationOptionCopyWithImpl<AuthoringCreationOption>(this as AuthoringCreationOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringCreationOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringCreationOption&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.display, _this.display) || other.display == _this.display)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.disabledReason, _this.disabledReason) || other.disabledReason == _this.disabledReason));
}


@override
int get hashCode {
  final _this = this as AuthoringCreationOption;
  return Object.hash(runtimeType,_this.type,_this.configuration,_this.label,_this.display,_this.query,_this.disabledReason);
}

@override
String toString() {
  final _this = this as AuthoringCreationOption;
  return 'AuthoringCreationOption(type: ${_this.type}, configuration: ${_this.configuration}, label: ${_this.label}, display: ${_this.display}, query: ${_this.query}, disabledReason: ${_this.disabledReason})';
}


}

/// @nodoc
abstract mixin class $AuthoringCreationOptionCopyWith<$Res>  {
  factory $AuthoringCreationOptionCopyWith(AuthoringCreationOption value, $Res Function(AuthoringCreationOption) _then) = _$AuthoringCreationOptionCopyWithImpl;
@useResult
$Res call({
 skir.TypeDefinitionId type, skir.TypeSelection configuration, String label, skir.TypeDisplay? display, SearchQueryContext query, String? disabledReason
});


$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$AuthoringCreationOptionCopyWithImpl<$Res>
    implements $AuthoringCreationOptionCopyWith<$Res> {
  _$AuthoringCreationOptionCopyWithImpl(this._self, this._then);

  final AuthoringCreationOption _self;
  final $Res Function(AuthoringCreationOption) _then;

/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? configuration = null,Object? label = null,Object? display = freezed,Object? query = null,Object? disabledReason = freezed,}) {
  return _then(AuthoringCreationOption(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.TypeDisplay?,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringCreationOption].
extension AuthoringCreationOptionPatterns on AuthoringCreationOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringCreationOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringCreationOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringCreationOption value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringCreationOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringCreationOption value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringCreationOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.TypeDefinitionId type,  skir.TypeSelection configuration,  String label,  skir.TypeDisplay? display,  SearchQueryContext query,  String? disabledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringCreationOption() when $default != null:
return $default(_that.type,_that.configuration,_that.label,_that.display,_that.query,_that.disabledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.TypeDefinitionId type,  skir.TypeSelection configuration,  String label,  skir.TypeDisplay? display,  SearchQueryContext query,  String? disabledReason)  $default,) {final _that = this;
switch (_that) {
case _AuthoringCreationOption():
return $default(_that.type,_that.configuration,_that.label,_that.display,_that.query,_that.disabledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.TypeDefinitionId type,  skir.TypeSelection configuration,  String label,  skir.TypeDisplay? display,  SearchQueryContext query,  String? disabledReason)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringCreationOption() when $default != null:
return $default(_that.type,_that.configuration,_that.label,_that.display,_that.query,_that.disabledReason);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringCreationOption extends AuthoringCreationOption {
  const _AuthoringCreationOption({required this.type, required this.configuration, required this.label, this.display, this.query = SearchQueryContext.empty, this.disabledReason}): super._();
  

@override final  skir.TypeDefinitionId type;
@override final  skir.TypeSelection configuration;
@override final  String label;
@override final  skir.TypeDisplay? display;
@override@JsonKey() final  SearchQueryContext query;
@override final  String? disabledReason;

/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringCreationOptionCopyWith<_AuthoringCreationOption> get copyWith => __$AuthoringCreationOptionCopyWithImpl<_AuthoringCreationOption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringCreationOption&&(identical(other.type, type) || other.type == type)&&(identical(other.configuration, configuration) || other.configuration == configuration)&&(identical(other.label, label) || other.label == label)&&(identical(other.display, display) || other.display == display)&&(identical(other.query, query) || other.query == query)&&(identical(other.disabledReason, disabledReason) || other.disabledReason == disabledReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,configuration,label,display,query,disabledReason);
}

@override
String toString() {
    return 'AuthoringCreationOption(type: $type, configuration: $configuration, label: $label, display: $display, query: $query, disabledReason: $disabledReason)';
}


}

/// @nodoc
abstract mixin class _$AuthoringCreationOptionCopyWith<$Res> implements $AuthoringCreationOptionCopyWith<$Res> {
  factory _$AuthoringCreationOptionCopyWith(_AuthoringCreationOption value, $Res Function(_AuthoringCreationOption) _then) = __$AuthoringCreationOptionCopyWithImpl;
@override @useResult
$Res call({
 skir.TypeDefinitionId type, skir.TypeSelection configuration, String label, skir.TypeDisplay? display, SearchQueryContext query, String? disabledReason
});


@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class __$AuthoringCreationOptionCopyWithImpl<$Res>
    implements _$AuthoringCreationOptionCopyWith<$Res> {
  __$AuthoringCreationOptionCopyWithImpl(this._self, this._then);

  final _AuthoringCreationOption _self;
  final $Res Function(_AuthoringCreationOption) _then;

/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? configuration = null,Object? label = null,Object? display = freezed,Object? query = null,Object? disabledReason = freezed,}) {
  return _then(_AuthoringCreationOption(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeDefinitionId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.TypeDisplay?,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AuthoringCreationOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

// dart format on
