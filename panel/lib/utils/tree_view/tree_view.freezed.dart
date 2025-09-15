// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tree_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TreeNode<T> {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TreeNode<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TreeNode<$T>()';
  }
}

/// @nodoc
class $TreeNodeCopyWith<T, $Res> {
  $TreeNodeCopyWith(TreeNode<T> _, $Res Function(TreeNode<T>) __);
}

/// Adds pattern-matching-related methods to [TreeNode].
extension TreeNodePatterns<T> on TreeNode<T> {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RootTreeNode<T> value)? root,
    TResult Function(InnerTreeNode<T> value)? inner,
    TResult Function(LeafTreeNode<T> value)? leaf,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode() when root != null:
        return root(_that);
      case InnerTreeNode() when inner != null:
        return inner(_that);
      case LeafTreeNode() when leaf != null:
        return leaf(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RootTreeNode<T> value) root,
    required TResult Function(InnerTreeNode<T> value) inner,
    required TResult Function(LeafTreeNode<T> value) leaf,
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode():
        return root(_that);
      case InnerTreeNode():
        return inner(_that);
      case LeafTreeNode():
        return leaf(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RootTreeNode<T> value)? root,
    TResult? Function(InnerTreeNode<T> value)? inner,
    TResult? Function(LeafTreeNode<T> value)? leaf,
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode() when root != null:
        return root(_that);
      case InnerTreeNode() when inner != null:
        return inner(_that);
      case LeafTreeNode() when leaf != null:
        return leaf(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<TreeNode<T>> children)? root,
    TResult Function(String name, String path, List<TreeNode<T>> children)?
        inner,
    TResult Function(T value)? leaf,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode() when root != null:
        return root(_that.children);
      case InnerTreeNode() when inner != null:
        return inner(_that.name, _that.path, _that.children);
      case LeafTreeNode() when leaf != null:
        return leaf(_that.value);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<TreeNode<T>> children) root,
    required TResult Function(
            String name, String path, List<TreeNode<T>> children)
        inner,
    required TResult Function(T value) leaf,
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode():
        return root(_that.children);
      case InnerTreeNode():
        return inner(_that.name, _that.path, _that.children);
      case LeafTreeNode():
        return leaf(_that.value);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<TreeNode<T>> children)? root,
    TResult? Function(String name, String path, List<TreeNode<T>> children)?
        inner,
    TResult? Function(T value)? leaf,
  }) {
    final _that = this;
    switch (_that) {
      case RootTreeNode() when root != null:
        return root(_that.children);
      case InnerTreeNode() when inner != null:
        return inner(_that.name, _that.path, _that.children);
      case LeafTreeNode() when leaf != null:
        return leaf(_that.value);
      case _:
        return null;
    }
  }
}

/// @nodoc

class RootTreeNode<T> implements TreeNode<T> {
  const RootTreeNode({required final List<TreeNode<T>> children})
      : _children = children;

  final List<TreeNode<T>> _children;
  List<TreeNode<T>> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RootTreeNodeCopyWith<T, RootTreeNode<T>> get copyWith =>
      _$RootTreeNodeCopyWithImpl<T, RootTreeNode<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RootTreeNode<T> &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_children));

  @override
  String toString() {
    return 'TreeNode<$T>.root(children: $children)';
  }
}

/// @nodoc
abstract mixin class $RootTreeNodeCopyWith<T, $Res>
    implements $TreeNodeCopyWith<T, $Res> {
  factory $RootTreeNodeCopyWith(
          RootTreeNode<T> value, $Res Function(RootTreeNode<T>) _then) =
      _$RootTreeNodeCopyWithImpl;
  @useResult
  $Res call({List<TreeNode<T>> children});
}

/// @nodoc
class _$RootTreeNodeCopyWithImpl<T, $Res>
    implements $RootTreeNodeCopyWith<T, $Res> {
  _$RootTreeNodeCopyWithImpl(this._self, this._then);

  final RootTreeNode<T> _self;
  final $Res Function(RootTreeNode<T>) _then;

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? children = null,
  }) {
    return _then(RootTreeNode<T>(
      children: null == children
          ? _self._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<TreeNode<T>>,
    ));
  }
}

/// @nodoc

class InnerTreeNode<T> implements TreeNode<T> {
  const InnerTreeNode(
      {required this.name,
      required this.path,
      required final List<TreeNode<T>> children})
      : _children = children;

  final String name;
  final String path;
  final List<TreeNode<T>> _children;
  List<TreeNode<T>> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InnerTreeNodeCopyWith<T, InnerTreeNode<T>> get copyWith =>
      _$InnerTreeNodeCopyWithImpl<T, InnerTreeNode<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InnerTreeNode<T> &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, name, path, const DeepCollectionEquality().hash(_children));

  @override
  String toString() {
    return 'TreeNode<$T>.inner(name: $name, path: $path, children: $children)';
  }
}

/// @nodoc
abstract mixin class $InnerTreeNodeCopyWith<T, $Res>
    implements $TreeNodeCopyWith<T, $Res> {
  factory $InnerTreeNodeCopyWith(
          InnerTreeNode<T> value, $Res Function(InnerTreeNode<T>) _then) =
      _$InnerTreeNodeCopyWithImpl;
  @useResult
  $Res call({String name, String path, List<TreeNode<T>> children});
}

/// @nodoc
class _$InnerTreeNodeCopyWithImpl<T, $Res>
    implements $InnerTreeNodeCopyWith<T, $Res> {
  _$InnerTreeNodeCopyWithImpl(this._self, this._then);

  final InnerTreeNode<T> _self;
  final $Res Function(InnerTreeNode<T>) _then;

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? children = null,
  }) {
    return _then(InnerTreeNode<T>(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      children: null == children
          ? _self._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<TreeNode<T>>,
    ));
  }
}

/// @nodoc

class LeafTreeNode<T> implements TreeNode<T> {
  const LeafTreeNode({required this.value});

  final T value;

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LeafTreeNodeCopyWith<T, LeafTreeNode<T>> get copyWith =>
      _$LeafTreeNodeCopyWithImpl<T, LeafTreeNode<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LeafTreeNode<T> &&
            const DeepCollectionEquality().equals(other.value, value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(value));

  @override
  String toString() {
    return 'TreeNode<$T>.leaf(value: $value)';
  }
}

/// @nodoc
abstract mixin class $LeafTreeNodeCopyWith<T, $Res>
    implements $TreeNodeCopyWith<T, $Res> {
  factory $LeafTreeNodeCopyWith(
          LeafTreeNode<T> value, $Res Function(LeafTreeNode<T>) _then) =
      _$LeafTreeNodeCopyWithImpl;
  @useResult
  $Res call({T value});
}

/// @nodoc
class _$LeafTreeNodeCopyWithImpl<T, $Res>
    implements $LeafTreeNodeCopyWith<T, $Res> {
  _$LeafTreeNodeCopyWithImpl(this._self, this._then);

  final LeafTreeNode<T> _self;
  final $Res Function(LeafTreeNode<T>) _then;

  /// Create a copy of TreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = freezed,
  }) {
    return _then(LeafTreeNode<T>(
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as T,
    ));
  }
}

/// @nodoc
mixin _$TreeModification<T> {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _TreeModification<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return '_TreeModification<$T>()';
  }
}

/// @nodoc
class _$TreeModificationCopyWith<T, $Res> {
  _$TreeModificationCopyWith(
      _TreeModification<T> _, $Res Function(_TreeModification<T>) __);
}

/// Adds pattern-matching-related methods to [_TreeModification].
extension _TreeModificationPatterns<T> on _TreeModification<T> {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_TreeAdd<T> value)? add,
    TResult Function(_TreeUpdate<T> value)? update,
    TResult Function(_TreeRemove<T> value)? remove,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd() when add != null:
        return add(_that);
      case _TreeUpdate() when update != null:
        return update(_that);
      case _TreeRemove() when remove != null:
        return remove(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_TreeAdd<T> value) add,
    required TResult Function(_TreeUpdate<T> value) update,
    required TResult Function(_TreeRemove<T> value) remove,
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd():
        return add(_that);
      case _TreeUpdate():
        return update(_that);
      case _TreeRemove():
        return remove(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_TreeAdd<T> value)? add,
    TResult? Function(_TreeUpdate<T> value)? update,
    TResult? Function(_TreeRemove<T> value)? remove,
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd() when add != null:
        return add(_that);
      case _TreeUpdate() when update != null:
        return update(_that);
      case _TreeRemove() when remove != null:
        return remove(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TreeNode<T> node)? add,
    TResult Function(String path, TreeNode<T> node)? update,
    TResult Function(String path)? remove,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd() when add != null:
        return add(_that.node);
      case _TreeUpdate() when update != null:
        return update(_that.path, _that.node);
      case _TreeRemove() when remove != null:
        return remove(_that.path);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TreeNode<T> node) add,
    required TResult Function(String path, TreeNode<T> node) update,
    required TResult Function(String path) remove,
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd():
        return add(_that.node);
      case _TreeUpdate():
        return update(_that.path, _that.node);
      case _TreeRemove():
        return remove(_that.path);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TreeNode<T> node)? add,
    TResult? Function(String path, TreeNode<T> node)? update,
    TResult? Function(String path)? remove,
  }) {
    final _that = this;
    switch (_that) {
      case _TreeAdd() when add != null:
        return add(_that.node);
      case _TreeUpdate() when update != null:
        return update(_that.path, _that.node);
      case _TreeRemove() when remove != null:
        return remove(_that.path);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TreeAdd<T> implements _TreeModification<T> {
  const _TreeAdd({required this.node});

  final TreeNode<T> node;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TreeAddCopyWith<T, _TreeAdd<T>> get copyWith =>
      __$TreeAddCopyWithImpl<T, _TreeAdd<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TreeAdd<T> &&
            (identical(other.node, node) || other.node == node));
  }

  @override
  int get hashCode => Object.hash(runtimeType, node);

  @override
  String toString() {
    return '_TreeModification<$T>.add(node: $node)';
  }
}

/// @nodoc
abstract mixin class _$TreeAddCopyWith<T, $Res>
    implements _$TreeModificationCopyWith<T, $Res> {
  factory _$TreeAddCopyWith(
          _TreeAdd<T> value, $Res Function(_TreeAdd<T>) _then) =
      __$TreeAddCopyWithImpl;
  @useResult
  $Res call({TreeNode<T> node});

  $TreeNodeCopyWith<T, $Res> get node;
}

/// @nodoc
class __$TreeAddCopyWithImpl<T, $Res> implements _$TreeAddCopyWith<T, $Res> {
  __$TreeAddCopyWithImpl(this._self, this._then);

  final _TreeAdd<T> _self;
  final $Res Function(_TreeAdd<T>) _then;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? node = null,
  }) {
    return _then(_TreeAdd<T>(
      node: null == node
          ? _self.node
          : node // ignore: cast_nullable_to_non_nullable
              as TreeNode<T>,
    ));
  }

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TreeNodeCopyWith<T, $Res> get node {
    return $TreeNodeCopyWith<T, $Res>(_self.node, (value) {
      return _then(_self.copyWith(node: value));
    });
  }
}

/// @nodoc

class _TreeUpdate<T> implements _TreeModification<T> {
  const _TreeUpdate({required this.path, required this.node});

  final String path;
  final TreeNode<T> node;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TreeUpdateCopyWith<T, _TreeUpdate<T>> get copyWith =>
      __$TreeUpdateCopyWithImpl<T, _TreeUpdate<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TreeUpdate<T> &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.node, node) || other.node == node));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, node);

  @override
  String toString() {
    return '_TreeModification<$T>.update(path: $path, node: $node)';
  }
}

/// @nodoc
abstract mixin class _$TreeUpdateCopyWith<T, $Res>
    implements _$TreeModificationCopyWith<T, $Res> {
  factory _$TreeUpdateCopyWith(
          _TreeUpdate<T> value, $Res Function(_TreeUpdate<T>) _then) =
      __$TreeUpdateCopyWithImpl;
  @useResult
  $Res call({String path, TreeNode<T> node});

  $TreeNodeCopyWith<T, $Res> get node;
}

/// @nodoc
class __$TreeUpdateCopyWithImpl<T, $Res>
    implements _$TreeUpdateCopyWith<T, $Res> {
  __$TreeUpdateCopyWithImpl(this._self, this._then);

  final _TreeUpdate<T> _self;
  final $Res Function(_TreeUpdate<T>) _then;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? path = null,
    Object? node = null,
  }) {
    return _then(_TreeUpdate<T>(
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      node: null == node
          ? _self.node
          : node // ignore: cast_nullable_to_non_nullable
              as TreeNode<T>,
    ));
  }

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TreeNodeCopyWith<T, $Res> get node {
    return $TreeNodeCopyWith<T, $Res>(_self.node, (value) {
      return _then(_self.copyWith(node: value));
    });
  }
}

/// @nodoc

class _TreeRemove<T> implements _TreeModification<T> {
  const _TreeRemove({required this.path});

  final String path;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TreeRemoveCopyWith<T, _TreeRemove<T>> get copyWith =>
      __$TreeRemoveCopyWithImpl<T, _TreeRemove<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TreeRemove<T> &&
            (identical(other.path, path) || other.path == path));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path);

  @override
  String toString() {
    return '_TreeModification<$T>.remove(path: $path)';
  }
}

/// @nodoc
abstract mixin class _$TreeRemoveCopyWith<T, $Res>
    implements _$TreeModificationCopyWith<T, $Res> {
  factory _$TreeRemoveCopyWith(
          _TreeRemove<T> value, $Res Function(_TreeRemove<T>) _then) =
      __$TreeRemoveCopyWithImpl;
  @useResult
  $Res call({String path});
}

/// @nodoc
class __$TreeRemoveCopyWithImpl<T, $Res>
    implements _$TreeRemoveCopyWith<T, $Res> {
  __$TreeRemoveCopyWithImpl(this._self, this._then);

  final _TreeRemove<T> _self;
  final $Res Function(_TreeRemove<T>) _then;

  /// Create a copy of _TreeModification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? path = null,
  }) {
    return _then(_TreeRemove<T>(
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
