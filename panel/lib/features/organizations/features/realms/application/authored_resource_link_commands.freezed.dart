// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authored_resource_link_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoredResourceLinkPlan {

 List<AuthoredResourceLinkSlot> get slots; String? get problem;
/// Create a copy of AuthoredResourceLinkPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredResourceLinkPlanCopyWith<AuthoredResourceLinkPlan> get copyWith => _$AuthoredResourceLinkPlanCopyWithImpl<AuthoredResourceLinkPlan>(this as AuthoredResourceLinkPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredResourceLinkPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredResourceLinkPlan&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}


@override
int get hashCode {
  final _this = this as AuthoredResourceLinkPlan;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.slots),_this.problem);
}

@override
String toString() {
  final _this = this as AuthoredResourceLinkPlan;
  return 'AuthoredResourceLinkPlan(slots: ${_this.slots}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $AuthoredResourceLinkPlanCopyWith<$Res>  {
  factory $AuthoredResourceLinkPlanCopyWith(AuthoredResourceLinkPlan value, $Res Function(AuthoredResourceLinkPlan) _then) = _$AuthoredResourceLinkPlanCopyWithImpl;
@useResult
$Res call({
 List<AuthoredResourceLinkSlot> slots, String? problem
});




}
/// @nodoc
class _$AuthoredResourceLinkPlanCopyWithImpl<$Res>
    implements $AuthoredResourceLinkPlanCopyWith<$Res> {
  _$AuthoredResourceLinkPlanCopyWithImpl(this._self, this._then);

  final AuthoredResourceLinkPlan _self;
  final $Res Function(AuthoredResourceLinkPlan) _then;

/// Create a copy of AuthoredResourceLinkPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slots = null,Object? problem = freezed,}) {
  return _then(AuthoredResourceLinkPlan(
slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkSlot>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoredResourceLinkPlan].
extension AuthoredResourceLinkPlanPatterns on AuthoredResourceLinkPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredResourceLinkPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredResourceLinkPlan value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredResourceLinkPlan value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuthoredResourceLinkSlot> slots,  String? problem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan() when $default != null:
return $default(_that.slots,_that.problem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuthoredResourceLinkSlot> slots,  String? problem)  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan():
return $default(_that.slots,_that.problem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuthoredResourceLinkSlot> slots,  String? problem)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkPlan() when $default != null:
return $default(_that.slots,_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredResourceLinkPlan implements AuthoredResourceLinkPlan {
  const _AuthoredResourceLinkPlan({ List<AuthoredResourceLinkSlot> slots = const [], this.problem}): _slots = slots;


 final  List<AuthoredResourceLinkSlot> _slots;
@override@JsonKey() List<AuthoredResourceLinkSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

@override final  String? problem;

/// Create a copy of AuthoredResourceLinkPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredResourceLinkPlanCopyWith<_AuthoredResourceLinkPlan> get copyWith => __$AuthoredResourceLinkPlanCopyWithImpl<_AuthoredResourceLinkPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredResourceLinkPlan&&const DeepCollectionEquality().equals(other.slots, _slots)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_slots),problem);
}

@override
String toString() {
    return 'AuthoredResourceLinkPlan(slots: $slots, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$AuthoredResourceLinkPlanCopyWith<$Res> implements $AuthoredResourceLinkPlanCopyWith<$Res> {
  factory _$AuthoredResourceLinkPlanCopyWith(_AuthoredResourceLinkPlan value, $Res Function(_AuthoredResourceLinkPlan) _then) = __$AuthoredResourceLinkPlanCopyWithImpl;
@override @useResult
$Res call({
 List<AuthoredResourceLinkSlot> slots, String? problem
});




}
/// @nodoc
class __$AuthoredResourceLinkPlanCopyWithImpl<$Res>
    implements _$AuthoredResourceLinkPlanCopyWith<$Res> {
  __$AuthoredResourceLinkPlanCopyWithImpl(this._self, this._then);

  final _AuthoredResourceLinkPlan _self;
  final $Res Function(_AuthoredResourceLinkPlan) _then;

/// Create a copy of AuthoredResourceLinkPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slots = null,Object? problem = freezed,}) {
  return _then(_AuthoredResourceLinkPlan(
slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkSlot>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AuthoredResourceLinkSlot {

 String get key; String get label; AuthoringDocument get document; List<AuthoredResourceLinkMember> get members;
/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredResourceLinkSlotCopyWith<AuthoredResourceLinkSlot> get copyWith => _$AuthoredResourceLinkSlotCopyWithImpl<AuthoredResourceLinkSlot>(this as AuthoredResourceLinkSlot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredResourceLinkSlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredResourceLinkSlot&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.document, _this.document) || other.document == _this.document)&&const DeepCollectionEquality().equals(other.members, _this.members));
}


@override
int get hashCode {
  final _this = this as AuthoredResourceLinkSlot;
  return Object.hash(runtimeType,_this.key,_this.label,_this.document,const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as AuthoredResourceLinkSlot;
  return 'AuthoredResourceLinkSlot(key: ${_this.key}, label: ${_this.label}, document: ${_this.document}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $AuthoredResourceLinkSlotCopyWith<$Res>  {
  factory $AuthoredResourceLinkSlotCopyWith(AuthoredResourceLinkSlot value, $Res Function(AuthoredResourceLinkSlot) _then) = _$AuthoredResourceLinkSlotCopyWithImpl;
@useResult
$Res call({
 String key, String label, AuthoringDocument document, List<AuthoredResourceLinkMember> members
});


$AuthoringDocumentCopyWith<$Res> get document;

}
/// @nodoc
class _$AuthoredResourceLinkSlotCopyWithImpl<$Res>
    implements $AuthoredResourceLinkSlotCopyWith<$Res> {
  _$AuthoredResourceLinkSlotCopyWithImpl(this._self, this._then);

  final AuthoredResourceLinkSlot _self;
  final $Res Function(AuthoredResourceLinkSlot) _then;

/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? document = null,Object? members = null,}) {
  return _then(AuthoredResourceLinkSlot(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkMember>,
  ));
}
/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get document {

  return $AuthoringDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoredResourceLinkSlot].
extension AuthoredResourceLinkSlotPatterns on AuthoredResourceLinkSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredResourceLinkSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredResourceLinkSlot value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredResourceLinkSlot value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  AuthoringDocument document,  List<AuthoredResourceLinkMember> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot() when $default != null:
return $default(_that.key,_that.label,_that.document,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  AuthoringDocument document,  List<AuthoredResourceLinkMember> members)  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot():
return $default(_that.key,_that.label,_that.document,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  AuthoringDocument document,  List<AuthoredResourceLinkMember> members)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkSlot() when $default != null:
return $default(_that.key,_that.label,_that.document,_that.members);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredResourceLinkSlot implements AuthoredResourceLinkSlot {
  const _AuthoredResourceLinkSlot({required this.key, required this.label, required this.document, required  List<AuthoredResourceLinkMember> members}): _members = members;


@override final  String key;
@override final  String label;
@override final  AuthoringDocument document;
 final  List<AuthoredResourceLinkMember> _members;
@override List<AuthoredResourceLinkMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredResourceLinkSlotCopyWith<_AuthoredResourceLinkSlot> get copyWith => __$AuthoredResourceLinkSlotCopyWithImpl<_AuthoredResourceLinkSlot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredResourceLinkSlot&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other.members, _members));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,label,document,const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'AuthoredResourceLinkSlot(key: $key, label: $label, document: $document, members: $members)';
}


}

/// @nodoc
abstract mixin class _$AuthoredResourceLinkSlotCopyWith<$Res> implements $AuthoredResourceLinkSlotCopyWith<$Res> {
  factory _$AuthoredResourceLinkSlotCopyWith(_AuthoredResourceLinkSlot value, $Res Function(_AuthoredResourceLinkSlot) _then) = __$AuthoredResourceLinkSlotCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, AuthoringDocument document, List<AuthoredResourceLinkMember> members
});


@override $AuthoringDocumentCopyWith<$Res> get document;

}
/// @nodoc
class __$AuthoredResourceLinkSlotCopyWithImpl<$Res>
    implements _$AuthoredResourceLinkSlotCopyWith<$Res> {
  __$AuthoredResourceLinkSlotCopyWithImpl(this._self, this._then);

  final _AuthoredResourceLinkSlot _self;
  final $Res Function(_AuthoredResourceLinkSlot) _then;

/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? document = null,Object? members = null,}) {
  return _then(_AuthoredResourceLinkSlot(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkMember>,
  ));
}

/// Create a copy of AuthoredResourceLinkSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get document {

  return $AuthoringDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

/// @nodoc
mixin _$AuthoredResourceLinkMember {

 skir.ResourceId get resource; List<AuthoredResourceLinkChoice> get choices;
/// Create a copy of AuthoredResourceLinkMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredResourceLinkMemberCopyWith<AuthoredResourceLinkMember> get copyWith => _$AuthoredResourceLinkMemberCopyWithImpl<AuthoredResourceLinkMember>(this as AuthoredResourceLinkMember, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredResourceLinkMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredResourceLinkMember&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&const DeepCollectionEquality().equals(other.choices, _this.choices));
}


@override
int get hashCode {
  final _this = this as AuthoredResourceLinkMember;
  return Object.hash(runtimeType,_this.resource,const DeepCollectionEquality().hash(_this.choices));
}

@override
String toString() {
  final _this = this as AuthoredResourceLinkMember;
  return 'AuthoredResourceLinkMember(resource: ${_this.resource}, choices: ${_this.choices})';
}


}

/// @nodoc
abstract mixin class $AuthoredResourceLinkMemberCopyWith<$Res>  {
  factory $AuthoredResourceLinkMemberCopyWith(AuthoredResourceLinkMember value, $Res Function(AuthoredResourceLinkMember) _then) = _$AuthoredResourceLinkMemberCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, List<AuthoredResourceLinkChoice> choices
});




}
/// @nodoc
class _$AuthoredResourceLinkMemberCopyWithImpl<$Res>
    implements $AuthoredResourceLinkMemberCopyWith<$Res> {
  _$AuthoredResourceLinkMemberCopyWithImpl(this._self, this._then);

  final AuthoredResourceLinkMember _self;
  final $Res Function(AuthoredResourceLinkMember) _then;

/// Create a copy of AuthoredResourceLinkMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? choices = null,}) {
  return _then(AuthoredResourceLinkMember(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkChoice>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoredResourceLinkMember].
extension AuthoredResourceLinkMemberPatterns on AuthoredResourceLinkMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredResourceLinkMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredResourceLinkMember value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredResourceLinkMember value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  List<AuthoredResourceLinkChoice> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember() when $default != null:
return $default(_that.resource,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  List<AuthoredResourceLinkChoice> choices)  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember():
return $default(_that.resource,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  List<AuthoredResourceLinkChoice> choices)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkMember() when $default != null:
return $default(_that.resource,_that.choices);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredResourceLinkMember implements AuthoredResourceLinkMember {
  const _AuthoredResourceLinkMember({required this.resource, required  List<AuthoredResourceLinkChoice> choices}): _choices = choices;


@override final  skir.ResourceId resource;
 final  List<AuthoredResourceLinkChoice> _choices;
@override List<AuthoredResourceLinkChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of AuthoredResourceLinkMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredResourceLinkMemberCopyWith<_AuthoredResourceLinkMember> get copyWith => __$AuthoredResourceLinkMemberCopyWithImpl<_AuthoredResourceLinkMember>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredResourceLinkMember&&(identical(other.resource, resource) || other.resource == resource)&&const DeepCollectionEquality().equals(other.choices, _choices));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,const DeepCollectionEquality().hash(_choices));
}

@override
String toString() {
    return 'AuthoredResourceLinkMember(resource: $resource, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$AuthoredResourceLinkMemberCopyWith<$Res> implements $AuthoredResourceLinkMemberCopyWith<$Res> {
  factory _$AuthoredResourceLinkMemberCopyWith(_AuthoredResourceLinkMember value, $Res Function(_AuthoredResourceLinkMember) _then) = __$AuthoredResourceLinkMemberCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, List<AuthoredResourceLinkChoice> choices
});




}
/// @nodoc
class __$AuthoredResourceLinkMemberCopyWithImpl<$Res>
    implements _$AuthoredResourceLinkMemberCopyWith<$Res> {
  __$AuthoredResourceLinkMemberCopyWithImpl(this._self, this._then);

  final _AuthoredResourceLinkMember _self;
  final $Res Function(_AuthoredResourceLinkMember) _then;

/// Create a copy of AuthoredResourceLinkMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? choices = null,}) {
  return _then(_AuthoredResourceLinkMember(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<AuthoredResourceLinkChoice>,
  ));
}


}

/// @nodoc
mixin _$AuthoredResourceLinkChoice {

 String get key; String get label; PortableLinkPlan get plan; PortableLinkTargetChoice get target; PortableLinkCounterpartRequest get counterpart; skir.LinkOccurrence? get disconnect;
/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoredResourceLinkChoiceCopyWith<AuthoredResourceLinkChoice> get copyWith => _$AuthoredResourceLinkChoiceCopyWithImpl<AuthoredResourceLinkChoice>(this as AuthoredResourceLinkChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoredResourceLinkChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoredResourceLinkChoice&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.counterpart, _this.counterpart) || other.counterpart == _this.counterpart)&&(identical(other.disconnect, _this.disconnect) || other.disconnect == _this.disconnect));
}


@override
int get hashCode {
  final _this = this as AuthoredResourceLinkChoice;
  return Object.hash(runtimeType,_this.key,_this.label,_this.plan,_this.target,_this.counterpart,_this.disconnect);
}

@override
String toString() {
  final _this = this as AuthoredResourceLinkChoice;
  return 'AuthoredResourceLinkChoice(key: ${_this.key}, label: ${_this.label}, plan: ${_this.plan}, target: ${_this.target}, counterpart: ${_this.counterpart}, disconnect: ${_this.disconnect})';
}


}

/// @nodoc
abstract mixin class $AuthoredResourceLinkChoiceCopyWith<$Res>  {
  factory $AuthoredResourceLinkChoiceCopyWith(AuthoredResourceLinkChoice value, $Res Function(AuthoredResourceLinkChoice) _then) = _$AuthoredResourceLinkChoiceCopyWithImpl;
@useResult
$Res call({
 String key, String label, PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart, skir.LinkOccurrence? disconnect
});


$PortableLinkPlanCopyWith<$Res> get plan;$PortableLinkTargetChoiceCopyWith<$Res> get target;$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class _$AuthoredResourceLinkChoiceCopyWithImpl<$Res>
    implements $AuthoredResourceLinkChoiceCopyWith<$Res> {
  _$AuthoredResourceLinkChoiceCopyWithImpl(this._self, this._then);

  final AuthoredResourceLinkChoice _self;
  final $Res Function(AuthoredResourceLinkChoice) _then;

/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? plan = null,Object? target = null,Object? counterpart = null,Object? disconnect = freezed,}) {
  return _then(AuthoredResourceLinkChoice(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,disconnect: freezed == disconnect ? _self.disconnect : disconnect // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,
  ));
}
/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {

  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoredResourceLinkChoice].
extension AuthoredResourceLinkChoicePatterns on AuthoredResourceLinkChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoredResourceLinkChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoredResourceLinkChoice value)  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoredResourceLinkChoice value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart,  skir.LinkOccurrence? disconnect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice() when $default != null:
return $default(_that.key,_that.label,_that.plan,_that.target,_that.counterpart,_that.disconnect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart,  skir.LinkOccurrence? disconnect)  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice():
return $default(_that.key,_that.label,_that.plan,_that.target,_that.counterpart,_that.disconnect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart,  skir.LinkOccurrence? disconnect)?  $default,) {final _that = this;
switch (_that) {
case _AuthoredResourceLinkChoice() when $default != null:
return $default(_that.key,_that.label,_that.plan,_that.target,_that.counterpart,_that.disconnect);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoredResourceLinkChoice implements AuthoredResourceLinkChoice {
  const _AuthoredResourceLinkChoice({required this.key, required this.label, required this.plan, required this.target, required this.counterpart, this.disconnect});


@override final  String key;
@override final  String label;
@override final  PortableLinkPlan plan;
@override final  PortableLinkTargetChoice target;
@override final  PortableLinkCounterpartRequest counterpart;
@override final  skir.LinkOccurrence? disconnect;

/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredResourceLinkChoiceCopyWith<_AuthoredResourceLinkChoice> get copyWith => __$AuthoredResourceLinkChoiceCopyWithImpl<_AuthoredResourceLinkChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredResourceLinkChoice&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.target, target) || other.target == target)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart)&&(identical(other.disconnect, disconnect) || other.disconnect == disconnect));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,label,plan,target,counterpart,disconnect);
}

@override
String toString() {
    return 'AuthoredResourceLinkChoice(key: $key, label: $label, plan: $plan, target: $target, counterpart: $counterpart, disconnect: $disconnect)';
}


}

/// @nodoc
abstract mixin class _$AuthoredResourceLinkChoiceCopyWith<$Res> implements $AuthoredResourceLinkChoiceCopyWith<$Res> {
  factory _$AuthoredResourceLinkChoiceCopyWith(_AuthoredResourceLinkChoice value, $Res Function(_AuthoredResourceLinkChoice) _then) = __$AuthoredResourceLinkChoiceCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart, skir.LinkOccurrence? disconnect
});


@override $PortableLinkPlanCopyWith<$Res> get plan;@override $PortableLinkTargetChoiceCopyWith<$Res> get target;@override $PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class __$AuthoredResourceLinkChoiceCopyWithImpl<$Res>
    implements _$AuthoredResourceLinkChoiceCopyWith<$Res> {
  __$AuthoredResourceLinkChoiceCopyWithImpl(this._self, this._then);

  final _AuthoredResourceLinkChoice _self;
  final $Res Function(_AuthoredResourceLinkChoice) _then;

/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? plan = null,Object? target = null,Object? counterpart = null,Object? disconnect = freezed,}) {
  return _then(_AuthoredResourceLinkChoice(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,disconnect: freezed == disconnect ? _self.disconnect : disconnect // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,
  ));
}

/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of AuthoredResourceLinkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {

  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}

// dart format on
