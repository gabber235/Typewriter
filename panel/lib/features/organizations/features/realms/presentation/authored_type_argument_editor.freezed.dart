// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authored_type_argument_editor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoredTypeUseCandidate {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredTypeUseCandidate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoredTypeUseCandidate()';
}


}

/// @nodoc
class $AuthoredTypeUseCandidateCopyWith<$Res>  {
$AuthoredTypeUseCandidateCopyWith(AuthoredTypeUseCandidate _, $Res Function(AuthoredTypeUseCandidate) __);
}


/// Adds pattern-matching-related methods to [AuthoredTypeUseCandidate].
extension AuthoredTypeUseCandidatePatterns on AuthoredTypeUseCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthoredTypeSelectionCandidate value)?  selection,TResult Function( AuthoredDirectTypeUseCandidate value)?  direct,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate() when selection != null:
return selection(_that);case AuthoredDirectTypeUseCandidate() when direct != null:
return direct(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthoredTypeSelectionCandidate value)  selection,required TResult Function( AuthoredDirectTypeUseCandidate value)  direct,}){
final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate():
return selection(_that);case AuthoredDirectTypeUseCandidate():
return direct(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthoredTypeSelectionCandidate value)?  selection,TResult? Function( AuthoredDirectTypeUseCandidate value)?  direct,}){
final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate() when selection != null:
return selection(_that);case AuthoredDirectTypeUseCandidate() when direct != null:
return direct(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( types.TypeSelection selection)?  selection,TResult Function( types.TypeUse type)?  direct,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate() when selection != null:
return selection(_that.selection);case AuthoredDirectTypeUseCandidate() when direct != null:
return direct(_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( types.TypeSelection selection)  selection,required TResult Function( types.TypeUse type)  direct,}) {final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate():
return selection(_that.selection);case AuthoredDirectTypeUseCandidate():
return direct(_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( types.TypeSelection selection)?  selection,TResult? Function( types.TypeUse type)?  direct,}) {final _that = this;
switch (_that) {
case AuthoredTypeSelectionCandidate() when selection != null:
return selection(_that.selection);case AuthoredDirectTypeUseCandidate() when direct != null:
return direct(_that.type);case _:
  return null;

}
}

}

/// @nodoc


class AuthoredTypeSelectionCandidate implements AuthoredTypeUseCandidate {
  const AuthoredTypeSelectionCandidate(this.selection);
  

 final  types.TypeSelection selection;

/// Create a copy of AuthoredTypeUseCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredTypeSelectionCandidateCopyWith<AuthoredTypeSelectionCandidate> get copyWith => _$AuthoredTypeSelectionCandidateCopyWithImpl<AuthoredTypeSelectionCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredTypeSelectionCandidate&&(identical(other.selection, selection) || other.selection == selection));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selection);
}

@override
String toString() {
    return 'AuthoredTypeUseCandidate.selection(selection: $selection)';
}


}

/// @nodoc
abstract mixin class $AuthoredTypeSelectionCandidateCopyWith<$Res> implements $AuthoredTypeUseCandidateCopyWith<$Res> {
  factory $AuthoredTypeSelectionCandidateCopyWith(AuthoredTypeSelectionCandidate value, $Res Function(AuthoredTypeSelectionCandidate) _then) = _$AuthoredTypeSelectionCandidateCopyWithImpl;
@useResult
$Res call({
 types.TypeSelection selection
});




}
/// @nodoc
class _$AuthoredTypeSelectionCandidateCopyWithImpl<$Res>
    implements $AuthoredTypeSelectionCandidateCopyWith<$Res> {
  _$AuthoredTypeSelectionCandidateCopyWithImpl(this._self, this._then);

  final AuthoredTypeSelectionCandidate _self;
  final $Res Function(AuthoredTypeSelectionCandidate) _then;

/// Create a copy of AuthoredTypeUseCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selection = null,}) {
  return _then(AuthoredTypeSelectionCandidate(
null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as types.TypeSelection,
  ));
}


}

/// @nodoc


class AuthoredDirectTypeUseCandidate implements AuthoredTypeUseCandidate {
  const AuthoredDirectTypeUseCandidate(this.type);
  

 final  types.TypeUse type;

/// Create a copy of AuthoredTypeUseCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredDirectTypeUseCandidateCopyWith<AuthoredDirectTypeUseCandidate> get copyWith => _$AuthoredDirectTypeUseCandidateCopyWithImpl<AuthoredDirectTypeUseCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredDirectTypeUseCandidate&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'AuthoredTypeUseCandidate.direct(type: $type)';
}


}

/// @nodoc
abstract mixin class $AuthoredDirectTypeUseCandidateCopyWith<$Res> implements $AuthoredTypeUseCandidateCopyWith<$Res> {
  factory $AuthoredDirectTypeUseCandidateCopyWith(AuthoredDirectTypeUseCandidate value, $Res Function(AuthoredDirectTypeUseCandidate) _then) = _$AuthoredDirectTypeUseCandidateCopyWithImpl;
@useResult
$Res call({
 types.TypeUse type
});




}
/// @nodoc
class _$AuthoredDirectTypeUseCandidateCopyWithImpl<$Res>
    implements $AuthoredDirectTypeUseCandidateCopyWith<$Res> {
  _$AuthoredDirectTypeUseCandidateCopyWithImpl(this._self, this._then);

  final AuthoredDirectTypeUseCandidate _self;
  final $Res Function(AuthoredDirectTypeUseCandidate) _then;

/// Create a copy of AuthoredTypeUseCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(AuthoredDirectTypeUseCandidate(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as types.TypeUse,
  ));
}


}

// dart format on
