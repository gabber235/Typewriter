// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reference_picker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReferencePickerCandidate<T extends Object> {

 String get id; T get value; String get label; String get description; String get searchText; skir.TypeDisplay? get display; String? get disabledReason;
/// Create a copy of ReferencePickerCandidate
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferencePickerCandidateCopyWith<T, ReferencePickerCandidate<T>> get copyWith => _$ReferencePickerCandidateCopyWithImpl<T, ReferencePickerCandidate<T>>(this as ReferencePickerCandidate<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReferencePickerCandidate<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferencePickerCandidate<T>&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.value, _this.value)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.searchText, _this.searchText) || other.searchText == _this.searchText)&&(identical(other.display, _this.display) || other.display == _this.display)&&(identical(other.disabledReason, _this.disabledReason) || other.disabledReason == _this.disabledReason));
}


@override
int get hashCode {
  final _this = this as ReferencePickerCandidate<T>;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.value),_this.label,_this.description,_this.searchText,_this.display,_this.disabledReason);
}

@override
String toString() {
  final _this = this as ReferencePickerCandidate<T>;
  return 'ReferencePickerCandidate<$T>(id: ${_this.id}, value: ${_this.value}, label: ${_this.label}, description: ${_this.description}, searchText: ${_this.searchText}, display: ${_this.display}, disabledReason: ${_this.disabledReason})';
}


}

/// @nodoc
abstract mixin class $ReferencePickerCandidateCopyWith<T extends Object,$Res>  {
  factory $ReferencePickerCandidateCopyWith(ReferencePickerCandidate<T> value, $Res Function(ReferencePickerCandidate<T>) _then) = _$ReferencePickerCandidateCopyWithImpl;
@useResult
$Res call({
 String id, T value, String label, String description, String searchText, skir.TypeDisplay? display, String? disabledReason
});




}
/// @nodoc
class _$ReferencePickerCandidateCopyWithImpl<T extends Object,$Res>
    implements $ReferencePickerCandidateCopyWith<T, $Res> {
  _$ReferencePickerCandidateCopyWithImpl(this._self, this._then);

  final ReferencePickerCandidate<T> _self;
  final $Res Function(ReferencePickerCandidate<T>) _then;

/// Create a copy of ReferencePickerCandidate
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? value = null,Object? label = null,Object? description = null,Object? searchText = null,Object? display = freezed,Object? disabledReason = freezed,}) {
  return _then(ReferencePickerCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.TypeDisplay?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern matching related methods to [ReferencePickerCandidate].
extension ReferencePickerCandidatePatterns<T extends Object> on ReferencePickerCandidate<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferencePickerCandidate<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferencePickerCandidate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferencePickerCandidate<T> value)  $default,){
final _that = this;
switch (_that) {
case _ReferencePickerCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferencePickerCandidate<T> value)?  $default,){
final _that = this;
switch (_that) {
case _ReferencePickerCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  T value,  String label,  String description,  String searchText,  skir.TypeDisplay? display,  String? disabledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferencePickerCandidate() when $default != null:
return $default(_that.id,_that.value,_that.label,_that.description,_that.searchText,_that.display,_that.disabledReason);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  T value,  String label,  String description,  String searchText,  skir.TypeDisplay? display,  String? disabledReason)  $default,) {final _that = this;
switch (_that) {
case _ReferencePickerCandidate():
return $default(_that.id,_that.value,_that.label,_that.description,_that.searchText,_that.display,_that.disabledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  T value,  String label,  String description,  String searchText,  skir.TypeDisplay? display,  String? disabledReason)?  $default,) {final _that = this;
switch (_that) {
case _ReferencePickerCandidate() when $default != null:
return $default(_that.id,_that.value,_that.label,_that.description,_that.searchText,_that.display,_that.disabledReason);case _:
  return null;

}
}

}

/// @nodoc


class _ReferencePickerCandidate<T extends Object> implements ReferencePickerCandidate<T> {
  const _ReferencePickerCandidate({required this.id, required this.value, required this.label, this.description = "", this.searchText = "", this.display, this.disabledReason});


@override final  String id;
@override final  T value;
@override final  String label;
@override@JsonKey() final  String description;
@override@JsonKey() final  String searchText;
@override final  skir.TypeDisplay? display;
@override final  String? disabledReason;

/// Create a copy of ReferencePickerCandidate
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferencePickerCandidateCopyWith<T, _ReferencePickerCandidate<T>> get copyWith => __$ReferencePickerCandidateCopyWithImpl<T, _ReferencePickerCandidate<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferencePickerCandidate<T>&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&(identical(other.display, display) || other.display == display)&&(identical(other.disabledReason, disabledReason) || other.disabledReason == disabledReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(value),label,description,searchText,display,disabledReason);
}

@override
String toString() {
    return 'ReferencePickerCandidate<$T>(id: $id, value: $value, label: $label, description: $description, searchText: $searchText, display: $display, disabledReason: $disabledReason)';
}


}

/// @nodoc
abstract mixin class _$ReferencePickerCandidateCopyWith<T extends Object,$Res> implements $ReferencePickerCandidateCopyWith<T, $Res> {
  factory _$ReferencePickerCandidateCopyWith(_ReferencePickerCandidate<T> value, $Res Function(_ReferencePickerCandidate<T>) _then) = __$ReferencePickerCandidateCopyWithImpl;
@override @useResult
$Res call({
 String id, T value, String label, String description, String searchText, skir.TypeDisplay? display, String? disabledReason
});




}
/// @nodoc
class __$ReferencePickerCandidateCopyWithImpl<T extends Object,$Res>
    implements _$ReferencePickerCandidateCopyWith<T, $Res> {
  __$ReferencePickerCandidateCopyWithImpl(this._self, this._then);

  final _ReferencePickerCandidate<T> _self;
  final $Res Function(_ReferencePickerCandidate<T>) _then;

/// Create a copy of ReferencePickerCandidate
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? value = null,Object? label = null,Object? description = null,Object? searchText = null,Object? display = freezed,Object? disabledReason = freezed,}) {
  return _then(_ReferencePickerCandidate<T>(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.TypeDisplay?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
