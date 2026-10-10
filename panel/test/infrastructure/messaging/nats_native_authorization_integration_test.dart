import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _currentSeed =
    "SUAKYRHVIOREXV7EUZTBHUHL7NUMHPMAS7QMDU3GTIUWEI5LDNOXD43IZY";
const _rejectedSeed =
    "SUAGJBS6P4WSOIX62RM2QTDD6DXY7NG2HQQ5NXS2YBG5YL5CZJ4VVM7IFY";
const _acceptedSeed =
    "SUAL3B2PIGI63SRQWPLVEFEL6HJSIFSTU3WEJIXVT6BFNXBDUOBRXGWCXQ";
const _currentSession = "0123456789abcdef0123456789abcdef";
const _rejectedSession = "11111111111111111111111111111111";
const _acceptedSession = "22222222222222222222222222222222";
const _stream = "TYPEWRITER_MEMBERSHIP";
const _filter = "cloud.from.user.fixture-user.organizations.changed";
const _snapshotSubject = "cloud.to.user.fixture-user.organization.watch";
const _consumer =
    "TW_WyJmaXh0dXJlLXVzZXIiLG51bGwsIjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmIiwidXNlcl9vcmdhbml6YXRpb25zX2NoYW5nZWQiXQ";

final _nativeRefProvider = Provider<Ref>((ref) => ref);

final class _FailingCleanupSubscription implements NatsSubscription {
  final _messages = StreamController<NatsMessage>.broadcast();

  @override
  Stream<NatsMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _messages.done;

  @override
  Future<void> unsubscribe() async {
    await _messages.close();
    throw Exception("Fixture cleanup failed");
  }
}

final class _NativeFixtureTelemetry implements PanelTelemetry {
  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Map<String, String> headers) operation,
  }) => operation(const {});

  @override
  Future<Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<Response> Function(Map<String, String> headers) operation,
  }) => operation(const {});
}

Future<void> _waitUntil(String stage, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException("Native fixture did not reach $stage");
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Future<void> _expectConsumerAbsent(JetStreamConsumerManager consumers) async {
  try {
    await consumers.info(_stream, _consumer);
    fail("Named consumer still exists");
  } on JetStreamApiException catch (error) {
    expect(error.code, 404);
  }
}

Future<NatsCoreClient> _connectClient(String serverUrl) async {
  final client = NatsCoreClient.connect(
    NatsClientConfiguration(
      url: serverUrl,
      seed: _currentSeed,
      requestInboxPrefix: "_INBOX.fixture-user.$_currentSession",
      actorId: "fixture-user",
      organizationId: null,
      connectionSession: _currentSession,
    ),
  );
  await client.waitConnected();
  return client;
}

void main() {
  final serverUrl = Platform.environment["NATS_NATIVE_URL"];
  final adminUser = Platform.environment["NATS_NATIVE_ADMIN_USER"];
  final adminPassword = Platform.environment["NATS_NATIVE_ADMIN_PASSWORD"];
  final skipReason =
      serverUrl == null || adminUser == null || adminPassword == null
      ? "Native NATS fixture environment is not set"
      : false;

  test(
    "native permissions and named consumer ownership recover exactly",
    () async {
      final admin = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl!)],
          authentication: NatsAuthentication.userPassword(
            adminUser!,
            adminPassword!,
          ),
        ),
      );
      addTearDown(admin.close);
      final jetStream = JetStreamContext(admin);
      await jetStream.streams.createOrUpdate(
        JetStreamStreamConfig(
          name: _stream,
          subjects: const [_filter],
          storage: JetStreamStorage.memory,
        ),
      );
      await jetStream.streams.purge(_stream);
      final consumers = jetStream.consumers;

      final client = await _connectClient(serverUrl);
      addTearDown(client.close);
      final permissions = await client.queryPermissions();
      expect(permissions.publish, contains(r"$SYS.REQ.USER.INFO"));
      expect(
        permissions.subscribe,
        contains("_INBOX.fixture-user.$_currentSession.*"),
      );
      expect(
        permissions.publish.followedBy(permissions.subscribe),
        everyElement(isNot(contains(">"))),
      );

      await consumers.createPull(
        _stream,
        JetStreamPullConsumerConfig(
          name: _consumer,
          durable: false,
          filters: JetStreamConsumerFilters.single(_filter),
          ackPolicy: JetStreamConsumerAckPolicy.none,
          start: const JetStreamConsumerStart.all(),
        ),
      );
      final staleReplacement = await client.subscribePersistent(
        _stream,
        _consumer,
        _filter,
      );
      await expectLater(
        client.subscribePersistent(_stream, _consumer, _filter),
        throwsStateError,
      );
      await staleReplacement.unsubscribe();
      await _expectConsumerAbsent(consumers);

      var snapshots = 0;
      final responder = await admin.subscribe(_snapshotSubject);
      final responderMessages = responder.messages.listen((message) {
        snapshots++;
        unawaited(
          admin.reply(
            message,
            skir.Duration.serializer.toBytes(
              skir.Duration(milliseconds: snapshots),
            ),
          ),
        );
      });
      addTearDown(responderMessages.cancel);
      addTearDown(responder.unsubscribe);
      await admin.flush();

      final container = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(
            AsyncData(_NativeFixtureTelemetry()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final values = <int>[];
      final projectionErrors = <Object>[];
      final projection = container
          .read(_nativeRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: _snapshotSubject,
            eventSubject: _filter,
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.persistent(
              stream: _stream,
              consumer: _consumer,
            ),
            reconciliation: const ProjectionReconciliation.latest(),
          )
          .listen(values.add, onError: projectionErrors.add);
      await _waitUntil(
        "the initial projection snapshot",
        () => values.isNotEmpty,
      );

      await consumers.delete(_stream, _consumer);
      await _waitUntil(
        "consumer deletion recovery or a diagnostic failure",
        () => snapshots >= 2 || projectionErrors.isNotEmpty,
      );
      if (projectionErrors case [final NatsClientException error, ...]) {
        fail("Consumer deletion produced ${error.cause}");
      }
      await _waitUntil(
        "a replacement snapshot after consumer deletion",
        () => snapshots >= 2 && values.length >= 2,
      );
      expect(values.take(2), [1, 2]);
      await jetStream.publish(
        _filter,
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 3)),
      );
      await _waitUntil(
        "delivery through the replacement consumer",
        () => values.contains(3),
      );
      await projection.cancel();
      await _expectConsumerAbsent(consumers);

      final closeOwned = await client.subscribePersistent(
        _stream,
        _consumer,
        _filter,
      );
      expect(closeOwned, isA<NatsSubscription>());
      await client.close();
      await _expectConsumerAbsent(consumers);

      final racing = await _connectClient(serverUrl);
      final acquisition = racing.subscribePersistent(
        _stream,
        _consumer,
        _filter,
      );
      final closing = racing.close();
      try {
        await acquisition;
      } on Object {
        // Close may win before acquisition reaches the connected boundary.
      }
      await closing;
      await _expectConsumerAbsent(consumers);

      final concreteConnection = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl)],
          authentication: NatsAuthentication.nkey(_currentSeed),
          requestInboxPrefix: "_INBOX.fixture-user.$_currentSession",
        ),
      );
      addTearDown(concreteConnection.close);
      final cleanupFailureClient = NatsCoreClient.fromConnectionFuture(
        Future.value(concreteConnection),
        configuration: const NatsClientConfiguration(
          url: "nats://native-fixture",
          seed: _currentSeed,
          requestInboxPrefix: "_INBOX.fixture-user.$_currentSession",
          actorId: "fixture-user",
          organizationId: "fixture-organization",
          connectionSession: _currentSession,
        ),
        persistentOpener: (stream, consumer, filter) async =>
            _FailingCleanupSubscription(),
      );
      await cleanupFailureClient.waitConnected();
      await cleanupFailureClient.subscribePersistent(
        _stream,
        "TW_cleanup_failure",
        _filter,
      );
      await expectLater(cleanupFailureClient.close(), throwsException);
      expect(concreteConnection.isConnected, isFalse);
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    "native permission admission preserves and then replaces the session",
    () async {
      final admin = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl!)],
          authentication: NatsAuthentication.userPassword(
            adminUser!,
            adminPassword!,
          ),
        ),
      );
      addTearDown(admin.close);
      final credentials = <(String, String)>[
        (_currentSeed, _currentSession),
        (_rejectedSeed, _rejectedSession),
        (_acceptedSeed, _acceptedSession),
      ];
      final clients = <NatsCoreClient>[];
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          accessTokenProvider.overrideWithValue(
            const AsyncData(AccessToken(token: "fixture-token")),
          ),
          authUserInfoProvider.overrideWithValue(
            const AsyncData(UserInfo(sub: "fixture-user")),
          ),
          userIdProvider.overrideWithValue(
            const AsyncData<String?>("fixture-user"),
          ),
          sentinelCredentialsProvider.overrideWithValue(
            AsyncData(
              skir.GetSentinelCredentialsResponse_Success(
                jwt: "",
                seed: _currentSeed,
              ),
            ),
          ),
          organizationIdProvider.overrideWithValue(
            skir.recordId("organization:fixture-organization"),
          ),
          natsConnectionSessionFactoryProvider.overrideWithValue(
            () => credentials.first.$2,
          ),
          natsClientFactoryProvider.overrideWithValue((configuration) {
            final credential = credentials.removeAt(0);
            expect(configuration.connectionSession, credential.$2);
            final client = NatsCoreClient.connect(
              NatsClientConfiguration(
                url: serverUrl,
                seed: credential.$1,
                requestInboxPrefix: "_INBOX.fixture-user.${credential.$2}",
                actorId: configuration.actorId,
                organizationId: configuration.organizationId,
                connectionSession: credential.$2,
              ),
            );
            clients.add(client);
            return client;
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        for (final client in clients) {
          await client.close();
        }
      });

      final current = container.read(natsProvider);
      final existingRealm = skir.recordId("realm_instance:fixture-realm");
      final addedRealm = skir.recordId("realm_instance:fixture-added-realm");
      final organization = skir.recordId("organization:fixture-organization");
      final repositories = container.read(resourceRepositoriesProvider);
      expect(repositories.transport.client, same(current));
      final repository = repositories.authoring(organization, existingRealm);
      final changes = <skir.AuthoringChanged>[];
      var invalidations = 0;
      final changesSubscription = repository.changes.listen(changes.add);
      final invalidationSubscription = repository.invalidations.listen(
        (_) => invalidations++,
      );
      addTearDown(changesSubscription.cancel);
      addTearDown(invalidationSubscription.cancel);
      final eventSubject = AuthoringChangedRouteEvent.subject(
        organizationId: organization,
        realmId: existingRealm,
      );
      await repository.start();
      final invalidationsBeforeInitialDelivery = invalidations;
      await admin.publish(
        eventSubject,
        skir.AuthoringChanged.serializer.toBytes(
          skir.AuthoringChanged(
            generation: skir.CatalogGeneration(value: "catalog:initial"),
          ),
        ),
      );
      await admin.flush();
      await _waitUntil(
        "delivery before permission admission",
        () =>
            changes.length == 1 ||
            invalidations > invalidationsBeforeInitialDelivery,
      );
      expect(
        invalidations,
        invalidationsBeforeInitialDelivery,
        reason: "The retained repository rejected the initial event payload",
      );
      await container.read(natsProvider.notifier).ensureRealmsAdmitted({
        existingRealm,
      });
      expect(current.connectionSession, _currentSession);

      await expectLater(
        container.read(natsProvider.notifier).ensureRealmsAdmitted({
          existingRealm,
          addedRealm,
        }),
        throwsA(
          isA<NatsClientException>().having(
            (error) => error.kind,
            "kind",
            NatsFailureKind.permission,
          ),
        ),
      );
      expect(container.read(natsProvider), same(current));
      expect(current.connectionState, isA<NatsConnected>());
      expect((await current.queryPermissions()).publish, isNotEmpty);
      final invalidationsBeforeCurrentDelivery = invalidations;
      await admin.publish(
        eventSubject,
        skir.AuthoringChanged.serializer.toBytes(
          skir.AuthoringChanged(
            generation: skir.CatalogGeneration(value: "catalog:current"),
          ),
        ),
      );
      await admin.flush();
      await _waitUntil(
        "delivery on the retained current repository",
        () =>
            changes.length == 2 ||
            invalidations > invalidationsBeforeCurrentDelivery,
      );
      expect(
        invalidations,
        invalidationsBeforeCurrentDelivery,
        reason: "The retained repository rejected the current event payload",
      );

      final invalidationsBeforeReplacement = invalidations;
      await container.read(natsProvider.notifier).ensureRealmsAdmitted({
        existingRealm,
        addedRealm,
      });
      final accepted = container.read(natsProvider);
      expect(accepted, same(clients.last));
      expect(accepted.connectionSession, _acceptedSession);
      await _waitUntil(
        "closure of the replaced connection",
        () => current.connectionState is NatsClosed,
      );
      await _waitUntil(
        "invalidation after retained repository rebind",
        () => invalidations > invalidationsBeforeReplacement,
      );
      expect(
        repositories.authoring(organization, existingRealm),
        same(repository),
      );
      await admin.publish(
        eventSubject,
        skir.AuthoringChanged.serializer.toBytes(
          skir.AuthoringChanged(
            generation: skir.CatalogGeneration(value: "catalog:accepted"),
          ),
        ),
      );
      await admin.flush();
      await _waitUntil(
        "delivery on the rebound retained repository",
        () => changes.length == 3,
      );
      expect(changes.map((change) => change.generation.value), [
        "catalog:initial",
        "catalog:current",
        "catalog:accepted",
      ]);
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
