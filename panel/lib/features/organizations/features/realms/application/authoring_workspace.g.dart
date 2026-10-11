// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_workspace.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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

/// Supplies external settlement without replacing workspace ownership.

@ProviderFor(authoringWorkspaceTransport)
final authoringWorkspaceTransportProvider =
    AuthoringWorkspaceTransportFamily._();

/// Supplies external settlement without replacing workspace ownership.

final class AuthoringWorkspaceTransportProvider
    extends
        $FunctionalProvider<
          AuthoringWorkspaceTransport,
          AuthoringWorkspaceTransport,
          AuthoringWorkspaceTransport
        >
    with $Provider<AuthoringWorkspaceTransport> {
  /// Supplies external settlement without replacing workspace ownership.
  AuthoringWorkspaceTransportProvider._({
    required AuthoringWorkspaceTransportFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'authoringWorkspaceTransportProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringWorkspaceTransportHash();

  @override
  String toString() {
    return r'authoringWorkspaceTransportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AuthoringWorkspaceTransport> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringWorkspaceTransport create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return authoringWorkspaceTransport(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringWorkspaceTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringWorkspaceTransport>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringWorkspaceTransportProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringWorkspaceTransportHash() =>
    r'9b92461c846092176335da7fc1539b16ebcb8b27';

/// Supplies external settlement without replacing workspace ownership.

final class AuthoringWorkspaceTransportFamily extends $Family
    with
        $FunctionalFamilyOverride<AuthoringWorkspaceTransport, AuthoringScope> {
  AuthoringWorkspaceTransportFamily._()
    : super(
        retry: null,
        name: r'authoringWorkspaceTransportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Supplies external settlement without replacing workspace ownership.

  AuthoringWorkspaceTransportProvider call(AuthoringScope scope) =>
      AuthoringWorkspaceTransportProvider._(argument: scope, from: this);

  @override
  String toString() => r'authoringWorkspaceTransportProvider';
}

@ProviderFor(authoringWorkspace)
final authoringWorkspaceProvider = AuthoringWorkspaceFamily._();

final class AuthoringWorkspaceProvider
    extends
        $FunctionalProvider<
          AuthoringWorkspace,
          AuthoringWorkspace,
          AuthoringWorkspace
        >
    with $Provider<AuthoringWorkspace> {
  AuthoringWorkspaceProvider._({
    required AuthoringWorkspaceFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'authoringWorkspaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringWorkspaceHash();

  @override
  String toString() {
    return r'authoringWorkspaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AuthoringWorkspace> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringWorkspace create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return authoringWorkspace(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringWorkspace value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringWorkspace>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringWorkspaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringWorkspaceHash() =>
    r'cd6bf2eda6041dde3ecba36b503b47c9560d5cf3';

final class AuthoringWorkspaceFamily extends $Family
    with $FunctionalFamilyOverride<AuthoringWorkspace, AuthoringScope> {
  AuthoringWorkspaceFamily._()
    : super(
        retry: null,
        name: r'authoringWorkspaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthoringWorkspaceProvider call(AuthoringScope scope) =>
      AuthoringWorkspaceProvider._(argument: scope, from: this);

  @override
  String toString() => r'authoringWorkspaceProvider';
}

@ProviderFor(authoringWorkspaceState)
final authoringWorkspaceStateProvider = AuthoringWorkspaceStateFamily._();

final class AuthoringWorkspaceStateProvider
    extends
        $FunctionalProvider<
          AuthoringWorkspaceState,
          AuthoringWorkspaceState,
          AuthoringWorkspaceState
        >
    with $Provider<AuthoringWorkspaceState> {
  AuthoringWorkspaceStateProvider._({
    required AuthoringWorkspaceStateFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'authoringWorkspaceStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringWorkspaceStateHash();

  @override
  String toString() {
    return r'authoringWorkspaceStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AuthoringWorkspaceState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringWorkspaceState create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return authoringWorkspaceState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringWorkspaceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringWorkspaceState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringWorkspaceStateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringWorkspaceStateHash() =>
    r'949fdccfa7a8f1eccd203f469a2e089663fd7953';

final class AuthoringWorkspaceStateFamily extends $Family
    with $FunctionalFamilyOverride<AuthoringWorkspaceState, AuthoringScope> {
  AuthoringWorkspaceStateFamily._()
    : super(
        retry: null,
        name: r'authoringWorkspaceStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthoringWorkspaceStateProvider call(AuthoringScope scope) =>
      AuthoringWorkspaceStateProvider._(argument: scope, from: this);

  @override
  String toString() => r'authoringWorkspaceStateProvider';
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
    r'8d44913c342e33c6ca6b0c8be43cf8dc0b3540f8';

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
