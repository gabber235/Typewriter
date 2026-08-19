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
    extends $NotifierProvider<TestSelectableData, Map<String, RecordValue>> {
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
  Override overrideWithValue(Map<String, RecordValue> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, RecordValue>>(value),
    );
  }
}

String _$testSelectableDataHash() =>
    r'a6c74fd85fd196d2feae3648ff383b7a5d75f32d';

abstract class _$TestSelectableData
    extends $Notifier<Map<String, RecordValue>> {
  Map<String, RecordValue> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, RecordValue>, Map<String, RecordValue>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, RecordValue>, Map<String, RecordValue>>,
              Map<String, RecordValue>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(testData)
final testDataProvider = TestDataFamily._();

final class TestDataProvider
    extends $FunctionalProvider<RecordValue?, RecordValue?, RecordValue?>
    with $Provider<RecordValue?> {
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
  $ProviderElement<RecordValue?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordValue? create(Ref ref) {
    final argument = this.argument as String;
    return testData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordValue? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordValue?>(value),
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

String _$testDataHash() => r'353911abb896c057dcec59f42d89199da4600e02';

final class TestDataFamily extends $Family
    with $FunctionalFamilyOverride<RecordValue?, String> {
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
