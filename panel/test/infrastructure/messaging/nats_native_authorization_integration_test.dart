import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _currentSeed =
    "SUAKYRHVIOREXV7EUZTBHUHL7NUMHPMAS7QMDU3GTIUWEI5LDNOXD43IZY";
const _retrySeed = "SUAL3B2PIGI63SRQWPLVEFEL6HJSIFSTU3WEJIXVT6BFNXBDUOBRXGWCXQ";
const _currentSession = "0123456789abcdef0123456789abcdef";
const _retrySession = "22222222222222222222222222222222";
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

/// Waits up to ten seconds for readiness, failing on terminal failure or
/// closure.
Future<void> _waitConnected(NatsClient client) async {
  final connected = Completer<void>();
  void accept(NatsConnectionState value) {
    if (connected.isCompleted) return;
    switch (value) {
      case NatsConnected():
        connected.complete();
      case NatsFailed(:final failure):
        connected.completeError(failure);
      case NatsClosed():
        connected.completeError(
          const NatsClientException(
            kind: NatsFailureKind.closed,
            message: "Fixture connection closed",
          ),
        );
      case NatsConnecting() || NatsReconnecting():
        break;
    }
  }

  final listener = client.connectionStateChanges.listen(accept);
  accept(client.connectionState);
  try {
    await connected.future.timeout(const Duration(seconds: 10));
  } finally {
    await listener.cancel();
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
  await _waitConnected(client);
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
      await _waitConnected(cleanupFailureClient);
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
    "native retry replaces the session and rebinds retained repositories",
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
        (_retrySeed, _retrySession),
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
      final realm = skir.recordId("realm_instance:fixture-realm");
      final organization = skir.recordId("organization:fixture-organization");
      final session = container.read(resourceSessionProvider);
      expect(session.transport.client, same(current));
      final repository = AuthoringResourceRepository(
        session,
        organization,
        realm,
      );
      addTearDown(repository.dispose);
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
        realmId: realm,
      );
      Future<void> publishChange(String generation) async {
        await admin.publish(
          eventSubject,
          skir.AuthoringChanged.serializer.toBytes(
            skir.AuthoringChanged(
              generation: skir.CatalogGeneration(value: generation),
            ),
          ),
        );
        await admin.flush();
      }

      await repository.start();
      final invalidationsBeforeInitialDelivery = invalidations;
      await publishChange("catalog:initial");
      await _waitUntil(
        "delivery on the first session",
        () =>
            changes.length == 1 ||
            invalidations > invalidationsBeforeInitialDelivery,
      );
      expect(
        invalidations,
        invalidationsBeforeInitialDelivery,
        reason: "The retained repository rejected the initial event payload",
      );
      expect(current.connectionSession, _currentSession);

      final invalidationsBeforeRetry = invalidations;
      await container.read(natsProvider.notifier).retry();
      final retried = container.read(natsProvider);
      expect(retried, same(clients.last));
      expect(retried.connectionSession, _retrySession);
      // AuthoringSession rebinds its repository when the connection is replaced.
      await repository.rebindTransport(retried);
      await _waitUntil(
        "closure of the replaced connection",
        () => current.connectionState is NatsClosed,
      );
      await _waitUntil(
        "invalidation after retained repository rebind",
        () => invalidations > invalidationsBeforeRetry,
      );
      expect(container.read(resourceSessionProvider), same(session));
      await publishChange("catalog:retried");
      await _waitUntil(
        "delivery on the rebound retained repository",
        () => changes.length == 2,
      );
      expect(changes.map((change) => change.generation.value), [
        "catalog:initial",
        "catalog:retried",
      ]);
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    "native resource routes reach every realm of the organization only",
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
      const suffixes = ["operations.resolve", "actions.prepare"];
      // A realm created after connect is reachable without a new connection.
      const reachable = [
        "service.to.fixture-realm.organization.fixture-organization.realm",
        "service.to.fixture-added-realm.organization.fixture-organization.realm",
      ];
      const denied = [
        "service.to.fixture-realm.organization.other-organization.realm",
        "service.to.fixture-realm.organization.fixture-organization.other",
      ];
      for (final prefix in [...reachable, ...denied]) {
        for (final suffix in suffixes) {
          final responder = await admin.subscribe(
            "$prefix.editor.resources.$suffix",
          );
          addTearDown(responder.unsubscribe);
          final listener = responder.messages.listen((message) {
            unawaited(admin.reply(message, message.payload));
          });
          addTearDown(listener.cancel);
        }
      }
      await admin.flush();
      final connection = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl)],
          authentication: NatsAuthentication.nkey(_currentSeed),
          requestInboxPrefix: "_INBOX.fixture-user.$_currentSession",
        ),
      );
      addTearDown(connection.close);
      for (final suffix in suffixes) {
        for (final prefix in reachable) {
          final subject = "$prefix.editor.resources.$suffix";
          final response = await connection.request(subject, const [42]);
          expect(response.payload, [42], reason: subject);
        }
        for (final prefix in denied) {
          final subject = "$prefix.editor.resources.$suffix";
          final rejection = connection.events
              .firstWhere((event) {
                if (event is! NatsServerError) return false;
                final error = event.error;
                return error is NatsPermissionException &&
                    error.operation == NatsPermissionOperation.publish &&
                    error.subject == subject;
              })
              .timeout(const Duration(seconds: 10));
          await connection.publish(subject, const [42]);
          await connection.flush();
          expect(
            await rejection,
            isA<NatsServerError>(),
            reason: "must not publish $subject",
          );
        }
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
