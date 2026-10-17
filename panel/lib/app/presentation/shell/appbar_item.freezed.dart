// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appbar_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppBarItemPolicy {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarItemPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppBarItemPolicy()';
}


}

/// @nodoc
class $AppBarItemPolicyCopyWith<$Res>  {
$AppBarItemPolicyCopyWith(AppBarItemPolicy _, $Res Function(AppBarItemPolicy) __);
}


/// Adds pattern-matching-related methods to [AppBarItemPolicy].
extension AppBarItemPolicyPatterns on AppBarItemPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FixedAppBarItem value)?  fixed,TResult Function( AdaptiveAppBarItem value)?  adaptive,TResult Function( ExpandedOnlyAppBarItem value)?  expandedOnly,TResult Function( CompactOnlyAppBarItem value)?  compactOnly,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FixedAppBarItem() when fixed != null:
return fixed(_that);case AdaptiveAppBarItem() when adaptive != null:
return adaptive(_that);case ExpandedOnlyAppBarItem() when expandedOnly != null:
return expandedOnly(_that);case CompactOnlyAppBarItem() when compactOnly != null:
return compactOnly(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FixedAppBarItem value)  fixed,required TResult Function( AdaptiveAppBarItem value)  adaptive,required TResult Function( ExpandedOnlyAppBarItem value)  expandedOnly,required TResult Function( CompactOnlyAppBarItem value)  compactOnly,}){
final _that = this;
switch (_that) {
case FixedAppBarItem():
return fixed(_that);case AdaptiveAppBarItem():
return adaptive(_that);case ExpandedOnlyAppBarItem():
return expandedOnly(_that);case CompactOnlyAppBarItem():
return compactOnly(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FixedAppBarItem value)?  fixed,TResult? Function( AdaptiveAppBarItem value)?  adaptive,TResult? Function( ExpandedOnlyAppBarItem value)?  expandedOnly,TResult? Function( CompactOnlyAppBarItem value)?  compactOnly,}){
final _that = this;
switch (_that) {
case FixedAppBarItem() when fixed != null:
return fixed(_that);case AdaptiveAppBarItem() when adaptive != null:
return adaptive(_that);case ExpandedOnlyAppBarItem() when expandedOnly != null:
return expandedOnly(_that);case CompactOnlyAppBarItem() when compactOnly != null:
return compactOnly(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fixed,TResult Function( int collapseOrder)?  adaptive,TResult Function( int collapseOrder)?  expandedOnly,TResult Function( int collapseOrder)?  compactOnly,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FixedAppBarItem() when fixed != null:
return fixed();case AdaptiveAppBarItem() when adaptive != null:
return adaptive(_that.collapseOrder);case ExpandedOnlyAppBarItem() when expandedOnly != null:
return expandedOnly(_that.collapseOrder);case CompactOnlyAppBarItem() when compactOnly != null:
return compactOnly(_that.collapseOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fixed,required TResult Function( int collapseOrder)  adaptive,required TResult Function( int collapseOrder)  expandedOnly,required TResult Function( int collapseOrder)  compactOnly,}) {final _that = this;
switch (_that) {
case FixedAppBarItem():
return fixed();case AdaptiveAppBarItem():
return adaptive(_that.collapseOrder);case ExpandedOnlyAppBarItem():
return expandedOnly(_that.collapseOrder);case CompactOnlyAppBarItem():
return compactOnly(_that.collapseOrder);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fixed,TResult? Function( int collapseOrder)?  adaptive,TResult? Function( int collapseOrder)?  expandedOnly,TResult? Function( int collapseOrder)?  compactOnly,}) {final _that = this;
switch (_that) {
case FixedAppBarItem() when fixed != null:
return fixed();case AdaptiveAppBarItem() when adaptive != null:
return adaptive(_that.collapseOrder);case ExpandedOnlyAppBarItem() when expandedOnly != null:
return expandedOnly(_that.collapseOrder);case CompactOnlyAppBarItem() when compactOnly != null:
return compactOnly(_that.collapseOrder);case _:
  return null;

}
}

}

/// @nodoc


class FixedAppBarItem extends AppBarItemPolicy {
  const FixedAppBarItem(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FixedAppBarItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppBarItemPolicy.fixed()';
}


}




/// @nodoc


class AdaptiveAppBarItem extends AppBarItemPolicy {
  const AdaptiveAppBarItem(this.collapseOrder): super._();
  

 final  int collapseOrder;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdaptiveAppBarItemCopyWith<AdaptiveAppBarItem> get copyWith => _$AdaptiveAppBarItemCopyWithImpl<AdaptiveAppBarItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AdaptiveAppBarItem&&(identical(other.collapseOrder, collapseOrder) || other.collapseOrder == collapseOrder));
}


@override
int get hashCode {
    return Object.hash(runtimeType,collapseOrder);
}

@override
String toString() {
    return 'AppBarItemPolicy.adaptive(collapseOrder: $collapseOrder)';
}


}

/// @nodoc
abstract mixin class $AdaptiveAppBarItemCopyWith<$Res> implements $AppBarItemPolicyCopyWith<$Res> {
  factory $AdaptiveAppBarItemCopyWith(AdaptiveAppBarItem value, $Res Function(AdaptiveAppBarItem) _then) = _$AdaptiveAppBarItemCopyWithImpl;
@useResult
$Res call({
 int collapseOrder
});




}
/// @nodoc
class _$AdaptiveAppBarItemCopyWithImpl<$Res>
    implements $AdaptiveAppBarItemCopyWith<$Res> {
  _$AdaptiveAppBarItemCopyWithImpl(this._self, this._then);

  final AdaptiveAppBarItem _self;
  final $Res Function(AdaptiveAppBarItem) _then;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? collapseOrder = null,}) {
  return _then(AdaptiveAppBarItem(
null == collapseOrder ? _self.collapseOrder : collapseOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ExpandedOnlyAppBarItem extends AppBarItemPolicy {
  const ExpandedOnlyAppBarItem(this.collapseOrder): super._();
  

 final  int collapseOrder;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpandedOnlyAppBarItemCopyWith<ExpandedOnlyAppBarItem> get copyWith => _$ExpandedOnlyAppBarItemCopyWithImpl<ExpandedOnlyAppBarItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpandedOnlyAppBarItem&&(identical(other.collapseOrder, collapseOrder) || other.collapseOrder == collapseOrder));
}


@override
int get hashCode {
    return Object.hash(runtimeType,collapseOrder);
}

@override
String toString() {
    return 'AppBarItemPolicy.expandedOnly(collapseOrder: $collapseOrder)';
}


}

/// @nodoc
abstract mixin class $ExpandedOnlyAppBarItemCopyWith<$Res> implements $AppBarItemPolicyCopyWith<$Res> {
  factory $ExpandedOnlyAppBarItemCopyWith(ExpandedOnlyAppBarItem value, $Res Function(ExpandedOnlyAppBarItem) _then) = _$ExpandedOnlyAppBarItemCopyWithImpl;
@useResult
$Res call({
 int collapseOrder
});




}
/// @nodoc
class _$ExpandedOnlyAppBarItemCopyWithImpl<$Res>
    implements $ExpandedOnlyAppBarItemCopyWith<$Res> {
  _$ExpandedOnlyAppBarItemCopyWithImpl(this._self, this._then);

  final ExpandedOnlyAppBarItem _self;
  final $Res Function(ExpandedOnlyAppBarItem) _then;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? collapseOrder = null,}) {
  return _then(ExpandedOnlyAppBarItem(
null == collapseOrder ? _self.collapseOrder : collapseOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CompactOnlyAppBarItem extends AppBarItemPolicy {
  const CompactOnlyAppBarItem(this.collapseOrder): super._();
  

 final  int collapseOrder;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompactOnlyAppBarItemCopyWith<CompactOnlyAppBarItem> get copyWith => _$CompactOnlyAppBarItemCopyWithImpl<CompactOnlyAppBarItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompactOnlyAppBarItem&&(identical(other.collapseOrder, collapseOrder) || other.collapseOrder == collapseOrder));
}


@override
int get hashCode {
    return Object.hash(runtimeType,collapseOrder);
}

@override
String toString() {
    return 'AppBarItemPolicy.compactOnly(collapseOrder: $collapseOrder)';
}


}

/// @nodoc
abstract mixin class $CompactOnlyAppBarItemCopyWith<$Res> implements $AppBarItemPolicyCopyWith<$Res> {
  factory $CompactOnlyAppBarItemCopyWith(CompactOnlyAppBarItem value, $Res Function(CompactOnlyAppBarItem) _then) = _$CompactOnlyAppBarItemCopyWithImpl;
@useResult
$Res call({
 int collapseOrder
});




}
/// @nodoc
class _$CompactOnlyAppBarItemCopyWithImpl<$Res>
    implements $CompactOnlyAppBarItemCopyWith<$Res> {
  _$CompactOnlyAppBarItemCopyWithImpl(this._self, this._then);

  final CompactOnlyAppBarItem _self;
  final $Res Function(CompactOnlyAppBarItem) _then;

/// Create a copy of AppBarItemPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? collapseOrder = null,}) {
  return _then(CompactOnlyAppBarItem(
null == collapseOrder ? _self.collapseOrder : collapseOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
