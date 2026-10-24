// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_inbox_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmInboxStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxStatus()';
}


}

/// @nodoc
class $RealmInboxStatusCopyWith<$Res>  {
$RealmInboxStatusCopyWith(RealmInboxStatus _, $Res Function(RealmInboxStatus) __);
}


/// Adds pattern-matching-related methods to [RealmInboxStatus].
extension RealmInboxStatusPatterns on RealmInboxStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QuietInboxStatus value)?  quiet,TResult Function( AttentionInboxStatus value)?  attention,TResult Function( CheckingInboxStatus value)?  checking,TResult Function( PublishingInboxStatus value)?  publishing,TResult Function( ReadyInboxStatus value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QuietInboxStatus() when quiet != null:
return quiet(_that);case AttentionInboxStatus() when attention != null:
return attention(_that);case CheckingInboxStatus() when checking != null:
return checking(_that);case PublishingInboxStatus() when publishing != null:
return publishing(_that);case ReadyInboxStatus() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QuietInboxStatus value)  quiet,required TResult Function( AttentionInboxStatus value)  attention,required TResult Function( CheckingInboxStatus value)  checking,required TResult Function( PublishingInboxStatus value)  publishing,required TResult Function( ReadyInboxStatus value)  ready,}){
final _that = this;
switch (_that) {
case QuietInboxStatus():
return quiet(_that);case AttentionInboxStatus():
return attention(_that);case CheckingInboxStatus():
return checking(_that);case PublishingInboxStatus():
return publishing(_that);case ReadyInboxStatus():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QuietInboxStatus value)?  quiet,TResult? Function( AttentionInboxStatus value)?  attention,TResult? Function( CheckingInboxStatus value)?  checking,TResult? Function( PublishingInboxStatus value)?  publishing,TResult? Function( ReadyInboxStatus value)?  ready,}){
final _that = this;
switch (_that) {
case QuietInboxStatus() when quiet != null:
return quiet(_that);case AttentionInboxStatus() when attention != null:
return attention(_that);case CheckingInboxStatus() when checking != null:
return checking(_that);case PublishingInboxStatus() when publishing != null:
return publishing(_that);case ReadyInboxStatus() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  quiet,TResult Function( int issueCount)?  attention,TResult Function()?  checking,TResult Function()?  publishing,TResult Function()?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QuietInboxStatus() when quiet != null:
return quiet();case AttentionInboxStatus() when attention != null:
return attention(_that.issueCount);case CheckingInboxStatus() when checking != null:
return checking();case PublishingInboxStatus() when publishing != null:
return publishing();case ReadyInboxStatus() when ready != null:
return ready();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  quiet,required TResult Function( int issueCount)  attention,required TResult Function()  checking,required TResult Function()  publishing,required TResult Function()  ready,}) {final _that = this;
switch (_that) {
case QuietInboxStatus():
return quiet();case AttentionInboxStatus():
return attention(_that.issueCount);case CheckingInboxStatus():
return checking();case PublishingInboxStatus():
return publishing();case ReadyInboxStatus():
return ready();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  quiet,TResult? Function( int issueCount)?  attention,TResult? Function()?  checking,TResult? Function()?  publishing,TResult? Function()?  ready,}) {final _that = this;
switch (_that) {
case QuietInboxStatus() when quiet != null:
return quiet();case AttentionInboxStatus() when attention != null:
return attention(_that.issueCount);case CheckingInboxStatus() when checking != null:
return checking();case PublishingInboxStatus() when publishing != null:
return publishing();case ReadyInboxStatus() when ready != null:
return ready();case _:
  return null;

}
}

}

/// @nodoc


class QuietInboxStatus implements RealmInboxStatus {
  const QuietInboxStatus();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is QuietInboxStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxStatus.quiet()';
}


}




/// @nodoc


class AttentionInboxStatus implements RealmInboxStatus {
  const AttentionInboxStatus(this.issueCount);
  

 final  int issueCount;

/// Create a copy of RealmInboxStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttentionInboxStatusCopyWith<AttentionInboxStatus> get copyWith => _$AttentionInboxStatusCopyWithImpl<AttentionInboxStatus>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AttentionInboxStatus&&(identical(other.issueCount, issueCount) || other.issueCount == issueCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,issueCount);
}

@override
String toString() {
    return 'RealmInboxStatus.attention(issueCount: $issueCount)';
}


}

/// @nodoc
abstract mixin class $AttentionInboxStatusCopyWith<$Res> implements $RealmInboxStatusCopyWith<$Res> {
  factory $AttentionInboxStatusCopyWith(AttentionInboxStatus value, $Res Function(AttentionInboxStatus) _then) = _$AttentionInboxStatusCopyWithImpl;
@useResult
$Res call({
 int issueCount
});




}
/// @nodoc
class _$AttentionInboxStatusCopyWithImpl<$Res>
    implements $AttentionInboxStatusCopyWith<$Res> {
  _$AttentionInboxStatusCopyWithImpl(this._self, this._then);

  final AttentionInboxStatus _self;
  final $Res Function(AttentionInboxStatus) _then;

/// Create a copy of RealmInboxStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? issueCount = null,}) {
  return _then(AttentionInboxStatus(
null == issueCount ? _self.issueCount : issueCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CheckingInboxStatus implements RealmInboxStatus {
  const CheckingInboxStatus();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckingInboxStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxStatus.checking()';
}


}




/// @nodoc


class PublishingInboxStatus implements RealmInboxStatus {
  const PublishingInboxStatus();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PublishingInboxStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxStatus.publishing()';
}


}




/// @nodoc


class ReadyInboxStatus implements RealmInboxStatus {
  const ReadyInboxStatus();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadyInboxStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxStatus.ready()';
}


}




// dart format on
