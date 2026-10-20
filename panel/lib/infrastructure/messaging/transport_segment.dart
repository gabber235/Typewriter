/// Validates caller supplied values before generated routes place them in a
/// NATS subject.
///
/// A token that contained whitespace, the `.` separator, a `*` or `>` wildcard
/// or template braces could split a subject or widen a subscription, so every
/// identity a route subject captures passes through [transportIdentity] first.
extension TransportSegment on String {
  static final _identity = RegExp(r"^[^\s.*>{}]+$");
  static final _transfer = RegExp(r"^[A-Za-z0-9_\-]{1,64}$");
  static final _session = RegExp(r"^[a-f0-9]{32}$");

  /// Whether this value can be one identity token of a subject.
  bool get isTransportIdentity => _identity.hasMatch(this);

  /// This value as a subject identity token.
  ///
  /// Throws an [ArgumentError] when it is not [isTransportIdentity].
  String get transportIdentity {
    if (!isTransportIdentity) {
      throw ArgumentError.value(this, "identity", "Invalid identity segment");
    }
    return this;
  }

  /// This value as the transfer token of a bounded watch update subject.
  ///
  /// TODO: the chunked-routes decision deletes bounded watches and this
  /// token with them.
  String get transportTransfer {
    if (!_transfer.hasMatch(this)) {
      throw ArgumentError.value(this, "transferId", "Invalid transfer segment");
    }
    return this;
  }

  /// This value as the 32 lowercase hexadecimal connection session of a
  /// persistent consumer name.
  String get transportSession {
    if (!_session.hasMatch(this)) {
      throw ArgumentError.value(
        this,
        "connectionSession",
        "Invalid connection session",
      );
    }
    return this;
  }
}
