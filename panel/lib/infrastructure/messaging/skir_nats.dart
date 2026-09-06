import "dart:async";
import "dart:typed_data";

import "package:riverpod/riverpod.dart";
import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/infrastructure/messaging/nats_client.dart";
import "package:typewriter_panel/infrastructure/messaging/nats_provider.dart";
import "package:typewriter_panel/infrastructure/observability/telemetry.dart";

const _requestTimeout = Duration(seconds: 10);

extension RefNatsExtension on Ref {
  Future<TResponse> requestSkir<TResponse>(
    String subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer,
  ) async {
    final telemetry = await read(panelTelemetryProvider.future);
    final client = read(natsProvider);
    final response = await telemetry.traceNats(
      subject: subject,
      payloadSize: requestBytes.length,
      operationName: "request",
      operation: (headers) => client.request(
        subject,
        requestBytes,
        headers: headers,
        timeout: _requestTimeout,
      ),
    );
    return serializer.fromBytes(response.payload);
  }

  Stream<TData> watchRequest<TData, TResponse>({
    required String subject,
    required String listenSubject,
    required Uint8List requestBytes,
    required Serializer<TResponse> serializer,
    required TData Function(TData?, TResponse) transformer,
  }) {
    final client = watch(natsProvider);
    return Stream<TData>.multi((controller) async {
      NatsSubscription? subscription;
      var active = true;
      Future<void>? unsubscribeOperation;

      Future<void> unsubscribe() => unsubscribeOperation ??= () async {
        active = false;
        await subscription?.unsubscribe();
      }();

      controller.onCancel = unsubscribe;
      onDispose(() => unawaited(unsubscribe()));

      try {
        subscription = await client.subscribe(listenSubject);
        if (!active) {
          await subscription.unsubscribe();
          return;
        }
        final telemetry = await read(panelTelemetryProvider.future);
        final initial = await telemetry.traceNats(
          subject: subject,
          payloadSize: requestBytes.length,
          operationName: "request",
          operation: (headers) => client.request(
            subject,
            requestBytes,
            headers: headers,
            timeout: _requestTimeout,
          ),
        );
        if (!active) return;

        TData? lastData;
        final initialData = transformer(
          null,
          serializer.fromBytes(initial.payload),
        );
        lastData = initialData;
        controller.add(initialData);

        await for (final message in subscription.messages) {
          if (!active) return;
          final response = transformer(
            lastData,
            serializer.fromBytes(message.payload),
          );
          lastData = response;
          controller.add(response);
        }
      } on Object catch (error, stackTrace) {
        if (active) controller.addError(error, stackTrace);
      } finally {
        await unsubscribe();
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    });
  }
}
