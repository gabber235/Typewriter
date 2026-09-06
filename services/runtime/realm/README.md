# Realm

Realm is a loader managed deployment and does not expose a process entry point. The standalone and Paper loaders own
its startup, replacement, and shutdown lifecycle.

## Development

Run `./gradlew check` from this directory to verify Realm. Realm catalog routes are backed by deployment discovery snapshots. Production artifact staging and deployment selection remain intentionally incomplete.

## Database

Realm uses an embedded, persistent, versioned SurrealKV database by default:

```properties
REALM_DB_ENDPOINT_TYPE=embedded
REALM_DB_ENGINE=surrealkv
REALM_DB_PATH=database/realm
REALM_DB_NAMESPACE=typewriter
REALM_DB_DATABASE=realm
REALM_DB_AUTHENTICATION=none
```

Embedded databases always enable versioned storage. Set `REALM_DB_RETENTION` to bound retained history.
The embedded engine may be `memory`, `surrealkv`, or `rocksdb`. The pinned Java SDK currently lacks RocksDB
support, so selecting it produces an explicit startup error.

Remote HTTP and WebSocket databases remain available:

```properties
REALM_DB_ENDPOINT_TYPE=remote
REALM_DB_URL=wss://database.example.com
REALM_DB_NAMESPACE=typewriter
REALM_DB_DATABASE=realm
REALM_DB_AUTHENTICATION=database
REALM_DB_USERNAME=realm
REALM_DB_PASSWORD=secret
```

Authentication may be `none`, `root`, `namespace`, `database`, or `bearer`. Bearer authentication reads
`REALM_DB_TOKEN`.
