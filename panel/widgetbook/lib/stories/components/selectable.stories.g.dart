// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selectable.stories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(TestSelectableData)
const testSelectableDataProvider = TestSelectableDataProvider._();

final class TestSelectableDataProvider
    extends $NotifierProvider<TestSelectableData, Map<String, DynamicData>> {
  const TestSelectableDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testSelectableDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testSelectableDataHash();

  @$internal
  @override
  TestSelectableData create() => TestSelectableData();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, DynamicData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, DynamicData>>(value),
    );
  }
}

String _$testSelectableDataHash() =>
    r'bfe0ee6486ccd63deeed9148f6f494cc7e9ec998';

abstract class _$TestSelectableData
    extends $Notifier<Map<String, DynamicData>> {
  Map<String, DynamicData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<Map<String, DynamicData>, Map<String, DynamicData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, DynamicData>, Map<String, DynamicData>>,
              Map<String, DynamicData>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(testData)
const testDataProvider = TestDataFamily._();

final class TestDataProvider
    extends $FunctionalProvider<DynamicData?, DynamicData?, DynamicData?>
    with $Provider<DynamicData?> {
  const TestDataProvider._({
    required TestDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'testDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$testDataHash();

  @override
  String toString() {
    return r'testDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DynamicData?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DynamicData? create(Ref ref) {
    final argument = this.argument as String;
    return testData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DynamicData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DynamicData?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TestDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$testDataHash() => r'584e149f8e6a1220140632deff69059f8e7f9bba';

final class TestDataFamily extends $Family
    with $FunctionalFamilyOverride<DynamicData?, String> {
  const TestDataFamily._()
    : super(
        retry: null,
        name: r'testDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TestDataProvider call(String id) =>
      TestDataProvider._(argument: id, from: this);

  @override
  String toString() => r'testDataProvider';
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
