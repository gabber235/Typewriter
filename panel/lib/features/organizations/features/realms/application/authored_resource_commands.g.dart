// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authored_resource_commands.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// External capabilities. Working value edits belong to the workspace.

@ProviderFor(authoredResourceCommands)
final authoredResourceCommandsProvider = AuthoredResourceCommandsFamily._();

/// External capabilities. Working value edits belong to the workspace.

final class AuthoredResourceCommandsProvider
    extends
        $FunctionalProvider<
          AuthoredResourceCommands,
          AuthoredResourceCommands,
          AuthoredResourceCommands
        >
    with $Provider<AuthoredResourceCommands> {
  /// External capabilities. Working value edits belong to the workspace.
  AuthoredResourceCommandsProvider._({
    required AuthoredResourceCommandsFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'authoredResourceCommandsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoredResourceCommandsHash();

  @override
  String toString() {
    return r'authoredResourceCommandsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AuthoredResourceCommands> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoredResourceCommands create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return authoredResourceCommands(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoredResourceCommands value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoredResourceCommands>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoredResourceCommandsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoredResourceCommandsHash() =>
    r'9b2bcb886e8f581fbda58661b33f0ee2f8e115d4';

/// External capabilities. Working value edits belong to the workspace.

final class AuthoredResourceCommandsFamily extends $Family
    with $FunctionalFamilyOverride<AuthoredResourceCommands, AuthoringScope> {
  AuthoredResourceCommandsFamily._()
    : super(
        retry: null,
        name: r'authoredResourceCommandsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// External capabilities. Working value edits belong to the workspace.

  AuthoredResourceCommandsProvider call(AuthoringScope scope) =>
      AuthoredResourceCommandsProvider._(argument: scope, from: this);

  @override
  String toString() => r'authoredResourceCommandsProvider';
}
