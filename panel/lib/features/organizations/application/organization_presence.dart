import "dart:async";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/presence.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "organization_presence.freezed.dart";
part "organization_presence.g.dart";

const _heartbeatInterval = Duration(seconds: 15);
const _presenceExpiry = Duration(seconds: 45);

@freezed
abstract class PresenceSessionKey with _$PresenceSessionKey {
  const factory PresenceSessionKey(String userId, String sessionId) =
      _PresenceSessionKey;
}

@freezed
abstract class ActivePanelPresence with _$ActivePanelPresence {
  const factory ActivePanelPresence({
    required String userId,
    required wire.PanelPresence presence,
    required DateTime observedAt,
  }) = _ActivePanelPresence;
}

@riverpod
class OrganizationPresence extends _$OrganizationPresence {
  final _sessionId = uuid.v4();
  var _sequence = 0;
  wire.PageActivity _activity = wire.PageActivity.overview;
  Timer? _heartbeat;
  Timer? _expiry;
  NatsSubscription? _subscription;
  StreamSubscription<NatsMessage>? _messages;

  late String _userId;
  late String _subject;
  late NatsClient _client;

  @override
  Future<Map<PresenceSessionKey, ActivePanelPresence>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    final userId = await ref.watch(userIdProvider.future);
    if (organizationId == null || userId == null) return const {};
    _userId = userId;
    _subject =
        "typewriter.presence.organization.${organizationId.id}.user.$userId";
    _client = ref.watch(natsProvider);
    _subscription = await _client.subscribe(
      "typewriter.presence.organization.${organizationId.id}.user.*",
    );
    _messages = _subscription!.messages.listen(_onMessage);
    ref.listen(currentRouteProvider, (_, _) {
      _activity = wire.PageActivity.overview;
      unawaited(_publishActive());
    });
    _heartbeat = Timer.periodic(
      _heartbeatInterval,
      (_) => unawaited(_publishActive()),
    );
    _expiry = Timer.periodic(_heartbeatInterval, (_) => _expire());
    ref.onDispose(() {
      _heartbeat?.cancel();
      _expiry?.cancel();
      unawaited(_publishLeft());
      unawaited(_messages?.cancel());
      unawaited(_subscription?.unsubscribe());
    });
    await _publishActive();
    return const {};
  }

  void setPageActivity(wire.PageActivity activity) {
    if (_activity == activity) return;
    _activity = activity;
    unawaited(_publishActive());
  }

  Future<void> _publishActive() async {
    if (!ref.mounted) return;
    final event = wire.PresenceEvent.createActive(
      sessionId: _sessionId,
      sequence: ++_sequence,
      location: _location(ref.read(currentRouteProvider)),
    );
    await _publish(event);
  }

  Future<void> _publishLeft() =>
      _publish(wire.PresenceEvent.createLeft(sessionId: _sessionId));

  Future<void> _publish(wire.PresenceEvent event) async {
    try {
      await _client.publish(
        _subject,
        wire.PresenceEvent.serializer.toBytes(event),
      );
    } on Object {
      // Presence is deliberately best effort.
    }
  }

  void _onMessage(NatsMessage message) {
    if (!state.hasValue) return;
    final userId = _trustedUserId(message.subject);
    if (userId == null) return;
    final event = wire.PresenceEvent.serializer.fromBytes(message.payload);
    switch (event) {
      case wire.PresenceEvent_activeWrapper(:final value):
        if (userId == _userId && value.sessionId == _sessionId) return;
        final key = PresenceSessionKey(userId, value.sessionId);
        final current = state.requireValue[key];
        if (current != null && current.presence.sequence >= value.sequence) {
          return;
        }
        state = AsyncData({
          ...state.requireValue,
          key: ActivePanelPresence(
            userId: userId,
            presence: value,
            observedAt: DateTime.now(),
          ),
        });
      case wire.PresenceEvent_leftWrapper(:final value):
        final key = PresenceSessionKey(userId, value.sessionId);
        state = AsyncData(Map.of(state.requireValue)..remove(key));
      case wire.PresenceEvent_unknown():
    }
  }

  void _expire() {
    if (!state.hasValue) return;
    final oldest = DateTime.now().subtract(_presenceExpiry);
    state = AsyncData({
      for (final entry in state.requireValue.entries)
        if (entry.value.observedAt.isAfter(oldest)) entry.key: entry.value,
    });
  }

  String? _trustedUserId(String subject) {
    final tokens = subject.split(".");
    if (tokens.length != 6 ||
        tokens[0] != "typewriter" ||
        tokens[1] != "presence" ||
        tokens[2] != "organization" ||
        tokens[4] != "user") {
      return null;
    }
    return tokens[5];
  }

  wire.PresenceLocation _location(String path) {
    final segments = path
        .split("/")
        .where((value) => value.isNotEmpty)
        .toList();
    String? after(String value) {
      final index = segments.indexOf(value);
      return index >= 0 && index + 1 < segments.length
          ? segments[index + 1]
          : null;
    }

    final realm = after("realm");
    final book = after("book");
    final page = after("page");
    if (realm != null && book != null && page != null) {
      return wire.PresenceLocation.createPage(
        realmId: recordId("service:$realm"),
        bookId: recordId("book:$book"),
        pageId: recordId("page:$page"),
        activity: _activity,
      );
    }
    if (realm != null && book != null) {
      return wire.PresenceLocation.createBook(
        realmId: recordId("service:$realm"),
        bookId: recordId("book:$book"),
      );
    }
    if (realm != null && segments.contains("tags")) {
      return wire.PresenceLocation.createRealmTags(
        realmId: recordId("service:$realm"),
      );
    }
    if (realm != null && segments.contains("library")) {
      return wire.PresenceLocation.createRealmLibrary(
        realmId: recordId("service:$realm"),
      );
    }
    if (realm != null) {
      return wire.PresenceLocation.createRealm(
        realmId: recordId("service:$realm"),
      );
    }
    if (segments.contains("members")) {
      return wire.PresenceLocation.createMembers();
    }
    if (segments.contains("services")) {
      return wire.PresenceLocation.createServices();
    }
    return wire.PresenceLocation.createOrganization();
  }
}
