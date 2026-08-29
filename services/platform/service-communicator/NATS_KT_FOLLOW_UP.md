# NATS.kt reconnect follow-up

## Scope

The communicator and registrar currently use NATS.kt 0.9.1. Registrar recreates its own pending-binding watch after observable connectivity changes and periodically re-queries status, but that is recovery for one startup workflow. It is not a general reconnect fix.

## Confirmed defects

1. NATS.kt creates a new protocol engine during reconnect without replaying existing `SUB` operations.
2. Local subscription objects can remain active while their server-side subscriptions no longer exist.
3. `maxReconnects = 0` does not produce deterministic one-shot behavior for every server-close path.
4. NATS protocol `lastError` information is not retained by the communicator adapter, so authorization rejection and authentication expiry can surface as generic disconnects or timeouts.
5. Core-NATS bound notifications remain at-most-once and have no replay.

## Current consequences

- Existing watches and routers are not reconnect-safe.
- Registrar recreates only the binding watch it owns and uses status polling to recover a lost bound event.
- After registrar reaches Ready, consumers must observe registrar connectivity generation changes and rebuild generation-bound watches and routers.
- Registrar conservatively invalidates authentication caches after failed connection attempts because it cannot classify server authentication rejection reliably.

## Upstream acceptance criteria

1. Replay every active subscription after a successful reconnect.
2. Preserve subscription IDs, unsubscribe limits, queue groups, and close ordering.
3. Prevent a subscription from reporting active when it is absent from the current protocol engine.
4. Expose typed server close, authorization rejection, authentication expiry, timeout, and permission errors.
5. Make reconnect-attempt limits deterministic for I/O failures and server closes.
6. Add integration coverage for reconnect with request inboxes, ordinary subscriptions, queue subscriptions, unsubscribe limits, and concurrent close.
7. Verify cancellation and client drain during reconnect.

After the upstream repair lands, remove registrar's reconnect-specific watch recreation where redundant, narrow cache invalidation to authentication failures, and update the communicator delivery guarantees.
