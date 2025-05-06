import "dart:async";

import "package:dart_nats/dart_nats.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/auth.dart";

part "nats.g.dart";

// The sentinel JWT is just used to make sure the user gets into the correct account on the NATS server.
// It is not actually a valid credential nor allows the user to do anything.
// That is why its safe to store it in a constant.
// TODO: Remove when nats allows for the `default_sentinel` config option.
const _natsSentinelJwt =
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJlZDI1NTE5LW5rZXkifQ.eyJqdGkiOiJUWVFNSVhCUUJNSEhOUzdWTU1RRk1OSlhBVENWS1RJRUJGTlVEQzRWNVpQUTY2NVgzMkRBIiwiaWF0IjoxNzQ1NzI4NjQ4LCJpc3MiOiJBQlU2SFRaTEpETUU3TFBHU0xBVkdNSjJXS0Y1TUlOQzZKTlRIR0JLMlFKRzJRNjVKUkU0VEFOUSIsIm5hbWUiOiJzZW50aW5lbCIsInN1YiI6IlVDRkpZSVozVkdNSzVJSElJUldPNlJIRU9ISVhJVE1QNEhZNERHSEJTMk8yRkU0SUI2TlM2RjNLIiwibmF0cyI6eyJwdWIiOnsiZGVueSI6WyJcdTAwM2UiXX0sInN1YiI6eyJkZW55IjpbIlx1MDAzZSJdfSwic3VicyI6LTEsImRhdGEiOi0xLCJwYXlsb2FkIjotMSwiaXNzdWVyX2FjY291bnQiOiJBQ05BWVZJQVZNQ0FVU0c1NUg2WUhXT0dRVlUzQUhNRVoyNFBYNVVPMkEyNkYzTUZBSVFSM0dGSyIsInR5cGUiOiJ1c2VyIiwidmVyc2lvbiI6Mn19.QYjsUBqshe5G7FNuDGg1ouxevrJ3sHAqJj0G8VCeVUhJLH3tl2v6nuS8UtICuz5g-BlId2Tg_wAjumQW5tHFAA";
const _natsSentinelSeed =
    "SUAG6J2O4ULGEZBKLVFQIDHFIZWR5PVEAROIQTE5VISCE3VCMFI2AHS25U";

@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  @override
  Client build() {
    final token = ref.watch(idTokenProvider).requireValue;
    if (token == null) {
      throw Exception("User must be authenticated before connecting to NATS");
    }

    final user = ref.watch(authUserInfoProvider).requireValue;

    final client = Client();

    final url = switch ((kIsWeb, kDebugMode)) {
      (true, true) => "ws://localhost:4223",
      (true, false) => "wss://nats.typewritermc.com:4223",
      (false, true) => "nats://localhost:4222",
      (false, false) => "tls://nats.typewritermc.com:4222",
    };

    debugPrint("nats: connecting to $url");

    client.seed = _natsSentinelSeed;

    unawaited(
      client.connect(
        Uri.parse(url),
        retry: true,
        retryCount: 0,
        connectOption: ConnectOption(
          jwt: _natsSentinelJwt,
          user: user.username ?? user.name ?? user.sub,
          pass: token,
        ),
      ),
    );

    ref.onDispose(client.close);

    return client;
  }
}

@riverpod
class NatsStatus extends _$NatsStatus {
  @override
  Status build() {
    final client = ref.watch(natsProvider);
    debugPrint("nats: status ${client.status}");
    final sub = client.statusStream.listen((status) {
      debugPrint("nats: status $status");
      state = status;
    });
    ref.onDispose(sub.cancel);
    return client.status;
  }
}
