// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'realm_editing_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(confirmedAuthoringDocument)
final confirmedAuthoringDocumentProvider = ConfirmedAuthoringDocumentFamily._();

final class ConfirmedAuthoringDocumentProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>
        >
    with $Provider<AsyncValue<AuthoringDocument>> {
  ConfirmedAuthoringDocumentProvider._({
    required ConfirmedAuthoringDocumentFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'confirmedAuthoringDocumentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$confirmedAuthoringDocumentHash();

  @override
  String toString() {
    return r'confirmedAuthoringDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringDocument> create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return confirmedAuthoringDocument(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AuthoringDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AuthoringDocument>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConfirmedAuthoringDocumentProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$confirmedAuthoringDocumentHash() =>
    r'36c8a9b532fa136f8b65076acfec5a971df5117c';

final class ConfirmedAuthoringDocumentFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringDocument>,
          AuthoringScope
        > {
  ConfirmedAuthoringDocumentFamily._()
    : super(
        retry: null,
        name: r'confirmedAuthoringDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConfirmedAuthoringDocumentProvider call(AuthoringScope scope) =>
      ConfirmedAuthoringDocumentProvider._(argument: scope, from: this);

  @override
  String toString() => r'confirmedAuthoringDocumentProvider';
}

@ProviderFor(realmEditPersistence)
final realmEditPersistenceProvider = RealmEditPersistenceFamily._();

final class RealmEditPersistenceProvider
    extends
        $FunctionalProvider<
          RealmEditPersistence,
          RealmEditPersistence,
          RealmEditPersistence
        >
    with $Provider<RealmEditPersistence> {
  RealmEditPersistenceProvider._({
    required RealmEditPersistenceFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmEditPersistenceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEditPersistenceHash();

  @override
  String toString() {
    return r'realmEditPersistenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RealmEditPersistence> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmEditPersistence create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmEditPersistence(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmEditPersistence value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmEditPersistence>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEditPersistenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEditPersistenceHash() =>
    r'32f6e3afebacdc686a76a7875ebed6a32a9b8ba7';

final class RealmEditPersistenceFamily extends $Family
    with $FunctionalFamilyOverride<RealmEditPersistence, AuthoringScope> {
  RealmEditPersistenceFamily._()
    : super(
        retry: null,
        name: r'realmEditPersistenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  RealmEditPersistenceProvider call(AuthoringScope scope) =>
      RealmEditPersistenceProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmEditPersistenceProvider';
}

@ProviderFor(realmEditing)
final realmEditingProvider = RealmEditingFamily._();

final class RealmEditingProvider
    extends $FunctionalProvider<RealmEditing, RealmEditing, RealmEditing>
    with $Provider<RealmEditing> {
  RealmEditingProvider._({
    required RealmEditingFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmEditingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEditingHash();

  @override
  String toString() {
    return r'realmEditingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RealmEditing> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealmEditing create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmEditing(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmEditing value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmEditing>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEditingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEditingHash() => r'd2e73e6ade806d15ef58ad23bfb8ccbe82eb041e';

final class RealmEditingFamily extends $Family
    with $FunctionalFamilyOverride<RealmEditing, AuthoringScope> {
  RealmEditingFamily._()
    : super(
        retry: null,
        name: r'realmEditingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmEditingProvider call(AuthoringScope scope) =>
      RealmEditingProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmEditingProvider';
}

@ProviderFor(realmEditingState)
final realmEditingStateProvider = RealmEditingStateFamily._();

final class RealmEditingStateProvider
    extends
        $FunctionalProvider<
          EditingState<AuthoringDocument>,
          EditingState<AuthoringDocument>,
          EditingState<AuthoringDocument>
        >
    with $Provider<EditingState<AuthoringDocument>> {
  RealmEditingStateProvider._({
    required RealmEditingStateFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmEditingStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEditingStateHash();

  @override
  String toString() {
    return r'realmEditingStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EditingState<AuthoringDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EditingState<AuthoringDocument> create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmEditingState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditingState<AuthoringDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditingState<AuthoringDocument>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEditingStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEditingStateHash() => r'd254fd9264abc6f55c308b1cfe6965539af9a71d';

final class RealmEditingStateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          EditingState<AuthoringDocument>,
          AuthoringScope
        > {
  RealmEditingStateFamily._()
    : super(
        retry: null,
        name: r'realmEditingStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmEditingStateProvider call(AuthoringScope scope) =>
      RealmEditingStateProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmEditingStateProvider';
}

@ProviderFor(workingAuthoringDocument)
final workingAuthoringDocumentProvider = WorkingAuthoringDocumentFamily._();

final class WorkingAuthoringDocumentProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>
        >
    with $Provider<AsyncValue<AuthoringDocument>> {
  WorkingAuthoringDocumentProvider._({
    required WorkingAuthoringDocumentFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'workingAuthoringDocumentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingAuthoringDocumentHash();

  @override
  String toString() {
    return r'workingAuthoringDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringDocument> create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return workingAuthoringDocument(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AuthoringDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AuthoringDocument>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkingAuthoringDocumentProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingAuthoringDocumentHash() =>
    r'f1e6d141d0fba17d1c73f077aa4205e44a82e6d6';

final class WorkingAuthoringDocumentFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringDocument>,
          AuthoringScope
        > {
  WorkingAuthoringDocumentFamily._()
    : super(
        retry: null,
        name: r'workingAuthoringDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkingAuthoringDocumentProvider call(AuthoringScope scope) =>
      WorkingAuthoringDocumentProvider._(argument: scope, from: this);

  @override
  String toString() => r'workingAuthoringDocumentProvider';
}

@ProviderFor(selectedAuthoringScope)
final selectedAuthoringScopeProvider = SelectedAuthoringScopeProvider._();

final class SelectedAuthoringScopeProvider
    extends
        $FunctionalProvider<AuthoringScope?, AuthoringScope?, AuthoringScope?>
    with $Provider<AuthoringScope?> {
  SelectedAuthoringScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAuthoringScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAuthoringScopeHash();

  @$internal
  @override
  $ProviderElement<AuthoringScope?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthoringScope? create(Ref ref) {
    return selectedAuthoringScope(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringScope? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringScope?>(value),
    );
  }
}

String _$selectedAuthoringScopeHash() =>
    r'4bc0dc393f551f5fb4db3f2b3162851c076182d6';

@ProviderFor(selectedWorkingAuthoringDocument)
final selectedWorkingAuthoringDocumentProvider =
    SelectedWorkingAuthoringDocumentProvider._();

final class SelectedWorkingAuthoringDocumentProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>,
          AsyncValue<AuthoringDocument>
        >
    with $Provider<AsyncValue<AuthoringDocument>> {
  SelectedWorkingAuthoringDocumentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedWorkingAuthoringDocumentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedWorkingAuthoringDocumentHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringDocument> create(Ref ref) {
    return selectedWorkingAuthoringDocument(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AuthoringDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AuthoringDocument>>(
        value,
      ),
    );
  }
}

String _$selectedWorkingAuthoringDocumentHash() =>
    r'6a570218e4e8aa9a17ffdabd4371f973e39bbfc8';
