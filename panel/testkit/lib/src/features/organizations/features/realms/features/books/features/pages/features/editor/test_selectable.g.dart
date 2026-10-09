// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_selectable.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TestSelectableData)
final testSelectableDataProvider = TestSelectableDataProvider._();

final class TestSelectableDataProvider
    extends $NotifierProvider<TestSelectableData, Map<String, skir.DataValue>> {
  TestSelectableDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testSelectableDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testSelectableDataHash();

  @$internal
  @override
  TestSelectableData create() => TestSelectableData();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, skir.DataValue> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, skir.DataValue>>(value),
    );
  }
}

String _$testSelectableDataHash() =>
    r'60930a376c68203000754ca7d11c9e95c13710e3';

abstract class _$TestSelectableData
    extends $Notifier<Map<String, skir.DataValue>> {
  Map<String, skir.DataValue> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, skir.DataValue>, Map<String, skir.DataValue>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, skir.DataValue>,
                Map<String, skir.DataValue>
              >,
              Map<String, skir.DataValue>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(testData)
final testDataProvider = TestDataFamily._();

final class TestDataProvider
    extends
        $FunctionalProvider<skir.DataValue?, skir.DataValue?, skir.DataValue?>
    with $Provider<skir.DataValue?> {
  TestDataProvider._({
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
  $ProviderElement<skir.DataValue?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.DataValue? create(Ref ref) {
    final argument = this.argument as String;
    return testData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.DataValue? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.DataValue?>(value),
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

String _$testDataHash() => r'98fbfc933f91075841e1ed8093fe296c2c2f1bc6';

final class TestDataFamily extends $Family
    with $FunctionalFamilyOverride<skir.DataValue?, String> {
  TestDataFamily._()
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
