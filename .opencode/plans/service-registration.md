# Service Registration System - High-Level Plan

## Goal
Allow services (Realm/Engine) to register with organizations via a token-based flow. Unbound services receive a registration token, display it in console, and users enter it in the Panel to complete the binding.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              NATS Message Bus                               │
└─────────────────────────────────────────────────────────────────────────────┘
        ▲                           ▲                           ▲
        │                           │                           │
        │                           │                           │
┌───────┴───────┐           ┌───────┴───────┐           ┌───────┴───────┐
│    Service    │           │    Backend    │           │     Panel     │
│  (Realm/Eng)  │           │  (wasmCloud)  │           │   (Flutter)   │
│    Kotlin     │           │     Rust      │           │     Dart      │
└───────────────┘           └───────────────┘           └───────────────┘
```

---

## NATS Subject Translation (IMPORTANT)

WasmCloud backend lives in a different NATS account than Panel and Services. Messages must be translated between accounts:

| From | To | Send Subject | Receive Subject |
|------|----|--------------|-----------------|
| Panel/Service → Backend | `cloud.out.>` | Backend receives as `typewriter.in.>` |
| Backend → Panel/Service | `typewriter.out.>` | Panel/Service receives as `cloud.in.>` |

**Examples:**
- Panel sends to `cloud.out.user.{uid}.organization.{oid}.services.bind`
- Backend receives it as `typewriter.in.user.{uid}.organization.{oid}.services.bind`
- Backend publishes to `typewriter.out.organization.{oid}.services.list`
- Panel receives it as `cloud.in.organization.{oid}.services.list`

Internal backend-to-backend communication uses `typewriter.` subjects directly (no translation).

---

## Communication Flow

### A. Service Startup (Unbound)

```
Service                     Auth-Callout              Service-Registration
   │                             │                            │
   │ 1. NATS Connect             │                            │
   │ ─────────────────────────►  │                            │
   │                             │                            │
   │                             │ 2. Check binding status    │
   │                             │ ──────────────────────────►│
   │                             │    (typewriter.service.    │
   │                             │     binding.check)         │
   │                             │                            │
   │                             │    Query SurrealDB:        │
   │                             │    - Has organization? No  │
   │                             │    - Generate/extend token │
   │                             │                            │
   │                             │ 3. Unbound + token         │
   │                             │ ◄──────────────────────────│
   │                             │                            │
   │ 4. Connected (limited perms)│                            │
   │ ◄─────────────────────────  │                            │
   │                             │                            │
   │ 5. Request service status   │                            │
   │    (cloud.out.service.      │                            │
   │     {id}.status)            │                            │
   │ ───────────────────────────────────────────────────────► │
   │                             │                            │
   │ 6. Receive status + token   │                            │
   │ ◄─────────────────────────────────────────────────────── │
   │                             │                            │
   │ 7. Display token in console │                            │
   │ 8. Subscribe to bound event │                            │
   │    (cloud.in.service.{id}.  │                            │
   │     registration.bound)     │                            │
   │ 9. Re-query every 2min      │                            │
   │    (extends expiry by 2.5m) │                            │
```

### B. User Binds Service (Panel)

```
Panel                       Service-Registration              Service
   │                               │                            │
   │ 1. User enters token          │                            │
   │    (cloud.out.user.{uid}.     │                            │
   │     organization.{oid}.       │                            │
   │     services.bind)            │                            │
   │ ─────────────────────────────►│                            │
   │                               │                            │
   │                               │ 2. Validate token          │
   │                               │    - Find service by token │
   │                               │    - Check not expired     │
   │                               │    - Bind to organization  │
   │                               │    - Clear registration    │
   │                               │                            │
   │ 3. Success response           │                            │
   │ ◄─────────────────────────────│                            │
   │                               │                            │
   │                               │ 4. Publish bound event     │
   │                               │    (typewriter.out.service.│
   │                               │     {id}.registration.     │
   │                               │     bound)                 │
   │                               │ ──────────────────────────►│
   │                               │                            │
   │                               │                 5. Service │
   │                               │                    receives│
   │                               │                    as      │
   │                               │                    cloud.in│
   │                               │                            │
   │                               │                 6. Reconnect│
   │                               │                    to get  │
   │                               │                    full    │
   │                               │                    perms   │
```

### C. Service Startup (Already Bound)

```
Service                     Auth-Callout              Service-Registration
   │                             │                            │
   │ 1. NATS Connect             │                            │
   │ ─────────────────────────►  │                            │
   │                             │ 2. Check binding           │
   │                             │ ──────────────────────────►│
   │                             │                            │
   │                             │    Query SurrealDB:        │
   │                             │    - Has organization? Yes │
   │                             │    - Return org details    │
   │                             │                            │
   │                             │ 3. Bound (org confirmed)   │
   │                             │ ◄──────────────────────────│
   │                             │                            │
   │ 4. Full org permissions     │                            │
   │ ◄─────────────────────────  │                            │
   │                             │                            │
   │ 5. Query status (confirms)  │                            │
   │ ───────────────────────────────────────────────────────► │
   │                             │                            │
   │ 6. Bound status + org info  │                            │
   │ ◄─────────────────────────────────────────────────────── │
   │                             │                            │
   │ 7. Normal startup           │                            │
```

---

## Key NATS Subjects

| Subject (as sent) | Subject (as received) | Purpose |
|-------------------|----------------------|---------|
| `typewriter.in.service.{id}.status` | (same) | Unified status endpoint for auth-perms and services |
| `cloud.out.service.{id}.status` | `typewriter.in.service.{id}.status` | Service queries its status (translated) |
| `cloud.out.user.{uid}.organization.{oid}.services.bind` | `typewriter.in.user...` | Panel binds service |
| `cloud.out.user.{uid}.organization.{oid}.services.list` | `typewriter.in.user...` | Panel lists services |
| `typewriter.out.service.{id}.registration.bound` | `cloud.in.service.{id}.registration.bound` | Backend notifies service |
| `typewriter.out.organization.{oid}.services.list` | `cloud.in.organization...` | Backend broadcasts list updates |

**Note:** The status endpoint is unified - both auth-permissions and services use `typewriter.in.service.{id}.status`. 
Service ID is extracted from the subject for automatic permission enforcement.

---

## Data Model (SurrealDB)

### Service Table Extensions
```
service {
  id: string
  name: string
  service_types: [ServiceType]
  ...existing fields...
  
  // NEW: Organization binding (mutually exclusive with registration)
  organization: option<record<organization>>
  
  // NEW: Registration token (mutually exclusive with organization)
  registration: option<{
    token: string (10-char uppercase A-Z0-9, regex validated)
    expires_at: datetime (must be > now() when written)
  }>
}

Constraints:
- registration defined → organization must be NONE
- organization defined → registration must be NONE
- registration.token: regex ^[A-Z0-9]{10}$
- registration.expires_at: asserted > time::now() on write
```

---

## Token Lifecycle

1. **Generation**: When auth-permissions checks an unbound service, registration component generates 10-char uppercase alphanumeric token
2. **Storage**: Token stored in SurrealDB with 2.5-minute expiry
3. **Extension**: Each status query extends expiry by 2.5 minutes (same token kept)
4. **Refresh Display**: Service re-queries every 2 minutes, displays current token
5. **Consumption**: When user submits token in Panel, it's validated and cleared
6. **Binding**: Service receives notification via NATS, reconnects with org context for full permissions

---

## Components to Build/Modify

### New Components
1. **Backend: service-registration** - wasmCloud component for binding logic
2. **Panel: Services page** - UI for token entry and service list
3. **Kotlin: RegistrationProtocol** - Service-side registration flow

### Modified Components
1. **Backend: auth-typewriter-permissions** - Call registration service during auth
2. **Kotlin: ServiceRegistrar** - Integrate registration protocol
3. **Proto definitions** - New messages for registration API

---

## Phases

### Phase 1: Protobuf Definitions
**Goal:** Define all message types that enable communication between components.

**What to create:**
- New file `proto/api/service/registration.proto` with messages for:
  - Checking binding status (request/response with bound vs unbound states)
  - Service status query (for services to query their own status)
  - Binding a service to an organization (token validation)
  - Listing services for an organization
  - Notification when service becomes bound

**What to modify:**
- `proto/models/service.proto`: Add optional organization_id field to Service model
- `proto/api/auth.proto`: (no changes needed)

**Patterns to follow:**
- Use `oneof result { Success success = 1; Error error = 2; }` pattern for responses
- Use `snake_case` for fields, `PascalCase` for messages
- Enums start with `_UNSPECIFIED = 0`

---

### Phase 2: Backend Service Registration Component ✅ COMPLETE
**Goal:** Create a new wasmCloud Rust component that handles all registration logic.

**Completed:**
- Enhanced `dispatch_actions!` macro with template aliases (`{name}` syntax, semicolon separator)
- Created component at `backend/service/registration/` with all source files
- Implemented three handlers: `status`, `bind`, `list`
- Updated SurrealDB schema with `registration` field and mutual exclusivity asserts
- Component builds successfully with `wash build`

**Files created:**
- `backend/service/registration/src/{lib,status,bind,list,notifications,utils}.rs`
- `backend/service/registration/{Cargo.toml,build.rs,Taskfile.yml}`
- `backend/service/registration/wit/world.wit`
- `backend/service/registration/manifests/workloaddeployment.yaml`
- `backend/service/registration/infrastructure/*.tf`

**NATS subjects handled:**
- `typewriter.in.service.{id}.status` (from auth-permissions and services)
- `typewriter.in.user.{uid}.organization.{oid}.services.bind` (from panel)
- `typewriter.in.user.{uid}.organization.{oid}.services.list` (from panel)

---

### Phase 2b: Integration Tests (TODO)
**Goal:** Add integration tests for the service-registration component.

**Test categories:**

**Status Handler:**
- `test_status_unbound_service_returns_token` - Returns 10-char uppercase alphanumeric token
- `test_status_extends_existing_token` - Same token returned on repeated queries
- `test_status_bound_service_returns_org_info` - Returns org_id and org_name
- `test_status_nonexistent_service_returns_error` - Returns 404

**Bind Handler:**
- `test_bind_service_with_valid_token` - Successfully binds and returns BoundService
- `test_bind_service_with_expired_token_fails` - Returns 400 error
- `test_bind_service_with_invalid_token_fails` - Returns 400 error
- `test_bind_clears_registration_sets_organization` - Verify DB state after bind

**List Handler:**
- `test_list_returns_all_org_services` - Returns correct count
- `test_list_empty_org_returns_empty_list` - Returns empty array
- `test_list_ordered_by_name` - Services sorted alphabetically

**Required infrastructure:**
- New `ServiceBuilder` in `backend/tests/src/builders/service.rs`
- Test files in `backend/tests/tests/service/registration/`

---

### Phase 3: Auth Permissions Integration
**Goal:** Modify auth-permissions to determine service binding status and return appropriate permissions.

**What to modify:**
- `backend/auth/auth-typewriter-permissions/src/services.rs`

**Changes:**
- In `handle_service()`, make NATS request to `typewriter.in.service.{id}.status`
- If bound: Return full org-scoped permissions, add `org:{id}` tag
- If unbound: Return minimal permissions (inbox, status query, registration notification subscription)

**Permission subjects for unbound services:**
- `_INBOX.{service_id}.>` (for responses)
- `cloud.out.service.{service_id}.status` (to query status)
- `cloud.in.service.{service_id}.registration.>` (to receive bound notification)

---

### Phase 4: Kotlin Registration Protocol
**Goal:** Implement service-side logic to handle the registration flow.

**What to create in `services/libs/service-registrar/`:**
- `RegistrationState.kt`: Sealed class with Initializing, Pending(token), Bound(orgId, orgName), Failed(error) states
- `RegistrationProtocol.kt`: Class managing the registration flow

**What to modify:**
- `ServiceRegistrar.kt`: Replace TODO comments (lines 66-68) with registration protocol integration

**Behaviors:**
- On startup: Query status via `cloud.out.service.{id}.status`
- If unbound: Display token in formatted console box, subscribe to bound notification
- Every 2 minutes: Re-query status (extends token expiry by 2.5 min), redisplay token
- On bound notification: Update state, reconnect to NATS with org context

**What to create in `services/realm/`:**
- `RegisterCommand.kt`: CLI command to display current registration status/token
- Update `RealmRootCommand.kt` to include the new command

---

### Phase 5: Panel Services Page
**Goal:** Build the Flutter UI for managing services and entering registration tokens.

**What to create:**
- New route at `panel/lib/routes/organization/services/route.dart`
- Widget for token input section (Card with text field and button)
- Widget for service cards (showing name, type, last seen)
- Logic provider at `panel/lib/logic/services/services.dart`

**What to modify:**
- `panel/lib/app_router.dart`: Add services route as default child of organization route
- Sidebar: Add Services link as first/default item

**UI patterns to follow:**
- Use `PageHeading` for title and subtitle
- Use `DecoratedTextField` for input
- Use `LoadingButton.filled` for submit
- Use `.call()` extension from riverpod utils for AsyncValue handling
- Disable input during loading
- Use `showSuccessSnackBar`/`showErrorSnackBar` for feedback

**NATS communication:**
- Use `ref.requestProtoThenListen()` for list with real-time updates
- Use standard `requestProto()` for bind action
- Subjects use `cloud.out.user.{userId}.organization.{orgId}.services.{action}` pattern

---

### Phase 5b: Backend Update/Unbind Endpoints ✅ COMPLETE
**Goal:** Add update and unbind endpoints to service-registration component.

**Completed:**
- Added `UpdateServiceRequest/Response` and `UnbindServiceRequest/Response` to proto
- Created `update.rs` handler for renaming services
- Created `unbind.rs` handler for removing services from organizations
- Updated `dispatch_actions!` macro with new routes
- Added `add_organization_services_permissions()` to auth-permissions
- Updated Panel `services.dart` with real NATS calls (replacing TODOs)
- Created testkit mock (`services.mock.dart`) and widgetbook story

**Files created:**
- `backend/service/registration/src/update.rs`
- `backend/service/registration/src/unbind.rs`
- `panel/testkit/lib/src/mocks/services.mock.dart`
- `panel/widgetbook/lib/stories/routes/organizations/services/route.stories.dart`

**Files modified:**
- `proto/api/service/registration.proto`
- `backend/service/registration/src/lib.rs`
- `backend/auth/auth-typewriter-permissions/src/users.rs`
- `panel/lib/logic/services.dart`
- `panel/testkit/lib/src/mocks/mock.dart`

---

### Phase 6: Status Command Integration

**Goal:** Integrate registration status into the existing status command for Realm services.

**Note:** The current implementation creates the RegistrationProtocol object directly in ServiceRegistrar. This should be refactored to use Koin for dependency injection.

**What to modify in `services/realm/`:**
- `StatusCommand.kt`: Add registration status section showing:
  - Current registration state (Initializing, Pending, Bound, Failed)
  - If Pending: display the registration token in a formatted box
  - If Bound: show organization name and ID
  - Last status query time

**What to refactor:**
- Move RegistrationProtocol instantiation to Koin module
- Allow StatusCommand to inject and query RegistrationProtocol state

**Files to modify:**
- `services/realm/src/main/kotlin/.../commands/StatusCommand.kt`
- `services/libs/service-registrar/src/.../ServiceRegistrar.kt` (Koin refactor)
- Koin module configuration

---

### Phase 7: Service Heartbeats & Health Status

**Goal:** Track real-time online/offline status of services by implementing a heartbeat mechanism.

#### 7a: Backend Heartbeat Handler

**What to create:**
- `backend/service/registration/src/heartbeat.rs`:
  - Handle `typewriter.in.service.{id}.heartbeat` subject
  - Update `last_seen` timestamp in SurrealDB
  - No response needed (fire-and-forget)

**What to modify:**
- `backend/service/registration/src/lib.rs`: Add `mod heartbeat;` and route
- SurrealDB schema: Add `last_seen: option<datetime>` to service table
- `backend/service/registration/src/list.rs`: Return `last_seen` in Service proto

**Proto notes:**
- `last_seen` field already exists in Service proto but is currently always None

#### 7b: Kotlin Heartbeat Sender

**What to create:**
- `services/libs/service-registrar/src/.../HeartbeatSender.kt`:
  - Coroutine sending heartbeat every 30 seconds
  - Starts after bind or on startup if already bound
  - Stops on shutdown

**What to modify:**
- `services/libs/service-registrar/.../ServiceRegistrar.kt`: Integrate HeartbeatSender

#### 7c: Panel Health Status Display

**What to modify:**
- `panel/lib/logic/services.dart`: Add online status helper (online if last_seen < 2 min ago)
- `panel/lib/routes/organization/services/route.dart`: Display online/offline indicator

---

### Phase 8: Integration Tests for Registration

**Goal:** Add comprehensive test coverage for the service-registration component.

**Test infrastructure to create:**
- `backend/tests/src/builders/service.rs`: ServiceBuilder

**Test files in `backend/tests/tests/service/registration/`:**

**Status Handler:**
- `test_status_unbound_service_returns_token`
- `test_status_extends_existing_token`
- `test_status_bound_service_returns_org_info`
- `test_status_nonexistent_service_creates_record`

**Bind Handler:**
- `test_bind_service_with_valid_token`
- `test_bind_service_with_expired_token_fails`
- `test_bind_service_with_invalid_token_fails`
- `test_bind_clears_registration_sets_organization`

**List Handler:**
- `test_list_returns_all_org_services`
- `test_list_empty_org_returns_empty_list`

**Update Handler:**
- `test_update_service_name`
- `test_update_service_wrong_org_fails`

**Unbind Handler:**
- `test_unbind_service_clears_org`
- `test_unbind_service_wrong_org_fails`

**Heartbeat Handler (after Phase 7):**
- `test_heartbeat_updates_last_seen`

---

### Phase 9: Auto-Restart After Unbind (Low Priority)

**Goal:** When a service is unbound via the Panel, it should detect this and revert to the registration token display flow without requiring a manual restart.

**Current behavior:**
- Panel calls unbind → backend clears organization
- Service continues running with stale org permissions until restart
- Service doesn't know it was unbound

**What to implement:**
- Backend publishes notification when service is unbound
- Service subscribes to unbind notification
- On unbind: Service re-queries status, gets new token, displays it

**What to modify:**
- `backend/service/registration/src/unbind.rs`: Publish notification
- `backend/service/registration/src/notifications.rs`: Add `publish_unbound_notification()`
- `proto/api/service/registration.proto`: Add `ServiceUnboundNotification` message
- `services/libs/service-registrar/.../RegistrationProtocol.kt`: Handle unbind notification

**Note:** Low priority since unbinding is rare and manual restart is acceptable for now.
