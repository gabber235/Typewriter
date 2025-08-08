TypeWriter Panel — Recipe: Models (freezed + json_serializable)

Intent: Define immutable, typed data models with copyWith and JSON helpers. Include both simple data classes and union types (multiple constructors/case distinctions).

Folder placement
- lib/logic/<feature>/models/

Key guidance (project-specific)
- Freezed types must be abstract or sealed in this project.
  - Prefer abstract for simple data classes.
  - Prefer sealed for unions (multiple constructors) when you want exhaustive pattern matching.
- Always include the part files: part 'type.freezed.dart'; and part 'type.g.dart'; when using JSON.

Checklist
1) Create an abstract or sealed class annotated with @freezed/@Freezed.
2) For simple models: define a single factory constructor with required fields.
3) For unions: define multiple factory constructors; prefer explicit field names per variant.
4) Add JSON helpers via json_serializable and, for unions, specify unionKey/unionValueCase if needed.
5) Keep field types explicit and non-dynamic.
6) Run codegen and update dependents.

Scaffold: Simple data class (abstract)
```dart
// lib/logic/user/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

Scaffold: Union/sealed type with JSON (case distinction)
```dart
// lib/logic/payment/models/payment_result.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'payment_result.freezed.dart';
part 'payment_result.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class PaymentResult with _$PaymentResult {
  const factory PaymentResult.success({
    required String transactionId,
    required int amountCents,
  }) = PaymentSuccess;

  const factory PaymentResult.failure({
    required String code,
    String? message,
  }) = PaymentFailure;

  const factory PaymentResult.pending({
    required DateTime eta,
  }) = PaymentPending;

  factory PaymentResult.fromJson(Map<String, dynamic> json) =>
      _$PaymentResultFromJson(json);
}
```

Usage: pattern matching
```dart
final PaymentResult result = /* ... */;
final text = result.when(
  success: (transactionId, amountCents) => 'OK $transactionId: $amountCents',
  failure: (code, message) => 'ERR $code: ${message ?? "unknown"}',
  pending: (eta) => 'PENDING until $eta',
);

// Mapping to widgets
Widget buildStatus(PaymentResult r) => r.map(
  success: (_) => const Icon(Icons.check, color: Colors.green),
  failure: (_) => const Icon(Icons.error, color: Colors.red),
  pending: (_) => const Icon(Icons.hourglass_empty),
);
```

JSON shape for unions (with unionKey: 'type' and snake case)
- { "type": "success", "transactionId": "tx_123", "amountCents": 999 }
- { "type": "failure", "code": "card_declined", "message": "Insufficient funds" }
- { "type": "pending", "eta": "2025-08-08T09:00:00Z" }

Tips
- Use @Default(...) for default field values where appropriate.
- Prefer value types (enums) over strings for finite sets.
- For DateTime/Duration/Uri, configure converters or keep strings and wrap at the provider layer if API is stringly-typed.

Commands
- dart run build_runner build -d
- dart analyze

