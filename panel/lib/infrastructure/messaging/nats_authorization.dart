import "package:typewriter_panel/typewriter_panel.dart";

part "nats_authorization.freezed.dart";

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ServerPermissionSnapshot with _$ServerPermissionSnapshot {
  factory ServerPermissionSnapshot({
    required Set<String> publish,
    required Set<String> subscribe,
  }) => ServerPermissionSnapshot._value(
    publish: Set.unmodifiable(publish),
    subscribe: Set.unmodifiable(subscribe),
  );

  const factory ServerPermissionSnapshot._value({
    required Set<String> publish,
    required Set<String> subscribe,
  }) = _ServerPermissionSnapshot;
}

extension ServerApiPayload on Uint8List {
  Map<String, Object?> decodeServerApiResponse() {
    final decoded = jsonDecode(utf8.decode(this));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException("Server response must be an object");
    }
    if (decoded["error"] case final Map<String, dynamic> error) {
      throw NatsClientException(
        kind: error["code"] == 403
            ? NatsFailureKind.permission
            : NatsFailureKind.protocol,
        message: "Server authorization query failed",
      );
    }
    if (decoded.containsKey("error")) {
      throw const FormatException("Invalid server error response");
    }
    if (decoded["data"] case final Map<String, dynamic> data) return data;
    throw const FormatException("Server response must contain data");
  }
}

extension ServerPermissionResponse on Map<String, Object?> {
  ServerPermissionSnapshot readPermissions() {
    final value = this["permissions"];
    if (value is! Map<String, dynamic>) {
      throw const FormatException("Server permissions must be an object");
    }

    Set<String> readDirection(String key) {
      final direction = value[key];
      if (direction is! Map<String, dynamic>) {
        throw FormatException("Missing explicit $key permission scope");
      }
      final allowed = direction["allow"];
      final denied = direction["deny"];
      if (allowed is! List || allowed.any((value) => value is! String)) {
        throw FormatException("Invalid $key allow permissions");
      }
      if (denied != null && (denied is! List || denied.isNotEmpty)) {
        throw FormatException("Unexpected $key deny permissions");
      }
      final subjects = allowed.cast<String>().toSet();
      if (subjects.any((subject) => subject.split(".").contains(">"))) {
        throw FormatException("Recursive $key permissions are forbidden");
      }
      return subjects;
    }

    return ServerPermissionSnapshot(
      publish: readDirection("publish"),
      subscribe: readDirection("subscribe"),
    );
  }
}

extension NatsAuthorizationQuery on NatsClient {
  Future<ServerPermissionSnapshot> queryPermissions() async {
    await waitConnected();
    final response = await request(r"$SYS.REQ.USER.INFO", Uint8List(0));
    return response.payload.decodeServerApiResponse().readPermissions();
  }

  Future<void> waitConnected() async {
    final admitted = Completer<void>();
    void accept(NatsConnectionState value) {
      if (admitted.isCompleted) return;
      switch (value) {
        case NatsConnected():
          admitted.complete();
        case NatsFailed(:final failure):
          admitted.completeError(failure);
        case NatsClosed():
          admitted.completeError(
            const NatsClientException(
              kind: NatsFailureKind.closed,
              message: "Candidate connection closed",
            ),
          );
        case NatsConnecting() || NatsReconnecting():
          break;
      }
    }

    final listener = connectionStateChanges.listen(accept);
    accept(connectionState);
    try {
      await admitted.future.timeout(const Duration(seconds: 10));
    } finally {
      await listener.cancel();
    }
  }
}
