// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'resource_issues.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resourceIssues)
final resourceIssuesProvider = ResourceIssuesFamily._();

final class ResourceIssuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResourceIssues>,
          AsyncValue<ResourceIssues>,
          AsyncValue<ResourceIssues>
        >
    with $Provider<AsyncValue<ResourceIssues>> {
  ResourceIssuesProvider._({
    required ResourceIssuesFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'resourceIssuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceIssuesHash();

  @override
  String toString() {
    return r'resourceIssuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<ResourceIssues>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ResourceIssues> create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return resourceIssues(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ResourceIssues> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ResourceIssues>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceIssuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceIssuesHash() => r'16fc84d91c830056fdddae710c3346db7b406d16';

final class ResourceIssuesFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<ResourceIssues>, AuthoringScope> {
  ResourceIssuesFamily._()
    : super(
        retry: null,
        name: r'resourceIssuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ResourceIssuesProvider call(AuthoringScope scope) =>
      ResourceIssuesProvider._(argument: scope, from: this);

  @override
  String toString() => r'resourceIssuesProvider';
}
