// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nats_authorization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerPermissionSnapshot {

 Set<String> get publish; Set<String> get subscribe;
/// Create a copy of ServerPermissionSnapshot
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerPermissionSnapshotCopyWith<ServerPermissionSnapshot> get copyWith => _$ServerPermissionSnapshotCopyWithImpl<ServerPermissionSnapshot>(this as ServerPermissionSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ServerPermissionSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerPermissionSnapshot&&const DeepCollectionEquality().equals(other.publish, _this.publish)&&const DeepCollectionEquality().equals(other.subscribe, _this.subscribe));
}


@override
int get hashCode {
  final _this = this as ServerPermissionSnapshot;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.publish),const DeepCollectionEquality().hash(_this.subscribe));
}

@override
String toString() {
  final _this = this as ServerPermissionSnapshot;
  return 'ServerPermissionSnapshot(publish: ${_this.publish}, subscribe: ${_this.subscribe})';
}


}

/// @nodoc
abstract mixin class $ServerPermissionSnapshotCopyWith<$Res>  {
  factory $ServerPermissionSnapshotCopyWith(ServerPermissionSnapshot value, $Res Function(ServerPermissionSnapshot) _then) = _$ServerPermissionSnapshotCopyWithImpl;
@useResult
$Res call({
 Set<String> publish, Set<String> subscribe
});




}
/// @nodoc
class _$ServerPermissionSnapshotCopyWithImpl<$Res>
    implements $ServerPermissionSnapshotCopyWith<$Res> {
  _$ServerPermissionSnapshotCopyWithImpl(this._self, this._then);

  final ServerPermissionSnapshot _self;
  final $Res Function(ServerPermissionSnapshot) _then;

/// Create a copy of ServerPermissionSnapshot
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publish = null,Object? subscribe = null,}) {
  return _then(ServerPermissionSnapshot(
publish: null == publish ? _self.publish : publish // ignore: cast_nullable_to_non_nullable
as Set<String>,subscribe: null == subscribe ? _self.subscribe : subscribe // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}



/// @nodoc


class _ServerPermissionSnapshot implements ServerPermissionSnapshot {
  const _ServerPermissionSnapshot({required  Set<String> publish, required  Set<String> subscribe}): _publish = publish,_subscribe = subscribe;


 final  Set<String> _publish;
@override Set<String> get publish {
  if (_publish is EqualUnmodifiableSetView) return _publish;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_publish);
}

 final  Set<String> _subscribe;
@override Set<String> get subscribe {
  if (_subscribe is EqualUnmodifiableSetView) return _subscribe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_subscribe);
}


/// Create a copy of ServerPermissionSnapshot
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerPermissionSnapshotCopyWith<_ServerPermissionSnapshot> get copyWith => __$ServerPermissionSnapshotCopyWithImpl<_ServerPermissionSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerPermissionSnapshot&&const DeepCollectionEquality().equals(other.publish, _publish)&&const DeepCollectionEquality().equals(other.subscribe, _subscribe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_publish),const DeepCollectionEquality().hash(_subscribe));
}

@override
String toString() {
    return 'ServerPermissionSnapshot._value(publish: $publish, subscribe: $subscribe)';
}


}

/// @nodoc
abstract mixin class _$ServerPermissionSnapshotCopyWith<$Res> implements $ServerPermissionSnapshotCopyWith<$Res> {
  factory _$ServerPermissionSnapshotCopyWith(_ServerPermissionSnapshot value, $Res Function(_ServerPermissionSnapshot) _then) = __$ServerPermissionSnapshotCopyWithImpl;
@override @useResult
$Res call({
 Set<String> publish, Set<String> subscribe
});




}
/// @nodoc
class __$ServerPermissionSnapshotCopyWithImpl<$Res>
    implements _$ServerPermissionSnapshotCopyWith<$Res> {
  __$ServerPermissionSnapshotCopyWithImpl(this._self, this._then);

  final _ServerPermissionSnapshot _self;
  final $Res Function(_ServerPermissionSnapshot) _then;

/// Create a copy of ServerPermissionSnapshot
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publish = null,Object? subscribe = null,}) {
  return _then(_ServerPermissionSnapshot(
publish: null == publish ? _self._publish : publish // ignore: cast_nullable_to_non_nullable
as Set<String>,subscribe: null == subscribe ? _self._subscribe : subscribe // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
