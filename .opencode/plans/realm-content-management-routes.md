# Realm Content Management Routes

## Overview
Implement NATS routes in the Realm service for managing Books, Pages, and Tags using TDD. This will be executed in phases with separate plans for each phase.

## Architecture

### Subject Pattern
The Realm service listens on its own service ID within its organization:
```
realm.from.$serviceId.organization.$organizationId.<entity>.<action>
```

Examples (where `$organizationId` is the org ID and `$serviceId` is the realm's service ID):
- `realm.from.svc-abc123.organization.org-xyz.book.list`
- `realm.from.svc-abc123.organization.org-xyz.page.create`
- `realm.from.svc-abc123.organization.org-xyz.tag.update`

The `$organizationId` and `$serviceId` are injected at runtime when configuring routes. This scoping ensures users can only access realms within their organization.

### Route Configuration
```kotlin
class RealmRoutes(private val serviceId: String) {
    fun configure(): NatsRouting.() -> Unit = {
        route("realm.in.$serviceId") {
            route("book") { ... }
            route("page") { ... }
            route("tag") { ... }
        }
    }
}
```

### Protobuf Integration
Add typed methods directly to `NatsContext` interface and implementation for protokt messages:
```kotlin
suspend inline fun <reified T> NatsContext.receive(): T   // deserialize from context.data
suspend inline fun <reified T> NatsContext.reply(message: T)  // serialize and send
```

Uses `protokt.v1.typewriter.api.v1.*` and `protokt.v1.typewriter.models.v1.*`.

## Phases

### Phase 1: Protobuf Extensions
- Add typed `receive<T>()` and `reply(message)` methods to `NatsContext` interface and impl
- Add tests for serialization/deserialization
- Update `RealmRoutes` to use correct subject pattern with injected serviceId
- **Status:** ✅ Completed

**Files modified:**
- `NatsContext.kt` - Added: `receive<T>(deserializer)`, `reply(T)`, `send(String, T)`, `request(T, deserializer)` 
- `NatsContextImpl.kt` - Implemented protobuf serialization/deserialization using protokt
- `TestNatsContext.kt` - Updated to implement new interface methods
- `NatsContextImplTest.kt` - Added 8 tests for protobuf operations

### Phase 2: Tag Repository & Routes
- Create `TagRepository` interface
- Implement `SurrealTagRepository` with SurrealDB queries
- Implement tag routes: list, get, create, update, delete, move, resize
- TDD: write tests first, then implementation
- **Status:** Pending

### Phase 3: Page Repository & Routes
- Create `PageRepository` interface
- Implement `SurrealPageRepository`
- Implement page routes: search, get, create, update, delete, rename, change_chapter, change_priority, bulk_change_chapters
- TDD: write tests first, then implementation
- **Status:** Pending

### Phase 4: Book Repository & Routes
- Create `BookRepository` interface
- Implement `SurrealBookRepository`
- Implement book routes: list, get, update
- TDD: write tests first, then implementation
- **Status:** Pending

### Phase 5: Integration & Polish
- Integration tests with full flow
- Error handling refinement
- Documentation updates
- **Status:** Pending

## Routes Summary

### Book Routes (3)
| Subject | Request | Response |
|---------|---------|----------|
| `book.list` | `ListBooksRequest` | `ListBooksResponse` |
| `book.get` | `GetBookRequest` | `GetBookResponse` |
| `book.update` | `UpdateBookRequest` | `UpdateBookResponse` |

### Page Routes (9)
| Subject | Request | Response |
|---------|---------|----------|
| `page.search` | `SearchPagesRequest` | `SearchPagesResponse` |
| `page.get` | `GetPageRequest` | `GetPageResponse` |
| `page.create` | `CreatePageRequest` | `CreatePageResponse` |
| `page.update` | `UpdatePageRequest` | `UpdatePageResponse` |
| `page.delete` | `DeletePageRequest` | `DeletePageResponse` |
| `page.rename` | `RenamePageRequest` | `RenamePageResponse` |
| `page.change_chapter` | `ChangePageChapterRequest` | `ChangePageChapterResponse` |
| `page.change_priority` | `ChangePagePriorityRequest` | `ChangePagePriorityResponse` |
| `page.bulk_change_chapters` | `ChangePagesChaptersRequest` | `ChangePagesChaptersResponse` |

### Tag Routes (7)
| Subject | Request | Response |
|---------|---------|----------|
| `tag.list` | `ListTagsRequest` | `ListTagsResponse` |
| `tag.get` | `GetTagRequest` | `GetTagResponse` |
| `tag.create` | `CreateTagRequest` | `CreateTagResponse` |
| `tag.update` | `UpdateTagRequest` | `UpdateTagResponse` |
| `tag.delete` | `DeleteTagRequest` | `DeleteTagResponse` |
| `tag.move` | `MoveTagRequest` | `MoveTagResponse` |
| `tag.resize` | `ResizeTagRequest` | `ResizeTagResponse` |

## Dependencies
- `protokt.v1.typewriter.api.v1.*` - Request/Response types
- `protokt.v1.typewriter.models.v1.*` - Domain models
- Existing `NatsRouting` framework from `service-communicator`
- SurrealDB client already configured in `Realm.kt`

## Technical Notes

### Protokt Serialization Pattern
```kotlin
// Serialize
ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
// Deserialize  
MessageType.deserialize(ByteArrayInputStream(bytes))
```

### Existing Context
- `NatsContext` interface: `message: Message`, `params: SubjectParams`, `reply(ByteArray)`, `send(String, ByteArray)`, `request(String, ByteArray, Duration): Message`
- `NatsContextImpl` uses `MessageBus` for publishing
- Tests use mockk for MessageBus, kotest FunSpec style
